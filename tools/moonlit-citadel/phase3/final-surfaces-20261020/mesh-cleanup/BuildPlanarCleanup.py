"""Subtract duplicate area only on proven exposed, same-facing source planes."""
from pathlib import Path
import hashlib
import json
import math
import bpy
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p/'default.project.json').exists())
SOURCE = ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend'
COMBINED = ROOT/'tools/moonlit-citadel/phase3/repair-20261019/final-blender/render01/MC_SOURCE55_FINAL_COMPOSITION.blend'
OUT = HERE/'proposal01'
EPS = 1e-9
AREA_EPS = 1e-8
ALL_EXACT_PLANES = False
KIT_NAME = 'MC_EXPOSED_PLANAR_UNION01'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def area(poly):
    return abs(sum(cross2(b[:2]-poly[0][:2],a[:2]-poly[0][:2]) for a,b in zip(poly[1:],poly[2:])))*.5


def cross2(a,b):
    return a[0]*b[1]-a[1]*b[0]


def half(poly,a,b,inside):
    if not poly:
        return []
    direction=b-a
    def side(p):
        return float(cross2(direction,p[:2]-a))
    result=[]
    for p,q in zip(poly,poly[1:]+poly[:1]):
        x,y=side(p),side(q)
        pi=x>=-EPS if inside else x<=EPS
        qi=y>=-EPS if inside else y<=EPS
        if pi:
            result.append(p)
        if pi!=qi and abs(x-y)>1e-16:
            result.append(p+(q-p)*(x/(x-y)))
    clean=[]
    for p in result:
        if not clean or np.linalg.norm(p[:2]-clean[-1][:2])>EPS:
            clean.append(p)
    if len(clean)>1 and np.linalg.norm(clean[0][:2]-clean[-1][:2])<=EPS:
        clean.pop()
    return clean if len(clean)>=3 and area(clean)>AREA_EPS else []


def intersection(subject,clipper):
    p=subject
    for a,b in zip(clipper,clipper[1:]+clipper[:1]):
        p=half(p,a[:2],b[:2],True)
        if not p:
            break
    return p


def subtract(subject,clipper):
    overlap=intersection(subject,clipper)
    if not overlap or area(overlap)<=AREA_EPS:
        return [subject]
    result=[]
    inside=subject
    for a,b in zip(clipper,clipper[1:]+clipper[:1]):
        outside=half(inside,a[:2],b[:2],False)
        if outside:
            result.append(outside)
        inside=half(inside,a[:2],b[:2],True)
        if not inside:
            break
    return result


def box(p):
    xy=np.array([x[:2] for x in p])
    return xy.min(axis=0),xy.max(axis=0)


def touching(a,b):
    al,ah=box(a);bl,bh=box(b)
    return bool(np.all(ah>bl+EPS) and np.all(bh>al+EPS))


def duplicate_pairs(items):
    count,total=0,0.
    for i,(p,f) in enumerate(items):
        for q,g in items[i+1:]:
            if f==g or not touching(p,q):
                continue
            overlap=intersection(p,q)
            value=area(overlap) if overlap else 0.
            if value>AREA_EPS:
                count+=1;total+=value
    return count,total


def plane(poly,mesh):
    points=np.array([mesh.vertices[v].co for v in poly.vertices],dtype=float)
    n=np.array(poly.normal,dtype=float)
    n/=np.linalg.norm(n)
    return n,float(n@points[0]),points


def main():
    assert bpy.app.background
    OUT.mkdir(exist_ok=True)
    hashes={str(p.relative_to(ROOT)):sha(p) for p in (SOURCE,COMBINED)}
    assessment=json.loads((HERE.parent/'internal/self-surface-assessment56.json').read_text())
    current=json.loads((HERE.parent/'internal/surface-objects56.json').read_text())['objects']
    original=json.loads((ROOT/'tools/moonlit-citadel/phase3/repair-20261019/overlap/surface-objects54-bound.json').read_text())['objects']
    paths={r['path']:r for r in current}
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    targets={}
    for family in assessment['families']:
        for row in family['rows']:
            if row['minimumVisibleGap']>.0005:
                continue
            meta=original[paths[row['path']]['sourceIndex']]
            obj=bpy.data.objects[meta['name']]
            key=(family['asset'],paths[row['path']]['material'],obj.data.name)
            target=targets.setdefault(key,{'object':obj,'rows':[],'faces':set()})
            target['rows'].append(row)
            target['faces'].update(row['faces'])

    reports=[]
    prepared=[]
    geometry={}
    for (asset,material,data_name),target in targets.items():
        source=target['object'];mesh=source.data
        assert not source.modifiers and not mesh.has_custom_normals
        assert not any(p.use_smooth for p in mesh.polygons)
        mesh.calc_loop_triangles()
        groups=[]
        for face_index in (range(len(mesh.polygons)) if ALL_EXACT_PLANES else sorted(target['faces'])):
            n,d,points=plane(mesh.polygons[face_index],mesh)
            if any(np.linalg.norm(n-g['normal'])<1e-7 and abs(d-g['d'])<1e-6 for g in groups):
                continue
            members=[]
            for p in mesh.polygons:
                pn,pd,pp=plane(p,mesh)
                if np.linalg.norm(n-pn)<1e-7 and abs(d-pd)<1e-6 and np.max(abs(pp@n-d))<2e-6:
                    members.append(p.index)
            if len(members)>1:
                axis=np.eye(3)[int(np.argmin(abs(n)))]
                u=np.cross(axis,n);u/=np.linalg.norm(u);v=np.cross(n,u)
                groups.append({'normal':n,'d':d,'faces':members,'u':u,'v':v})
        old_bounds=np.array([v.co for v in mesh.vertices],dtype=float)
        uv_names=[l.name for l in mesh.uv_layers]
        new_vertices=[list(v.co) for v in mesh.vertices]
        new_polys=[];new_uv=[];new_material=[];new_source_face=[]
        changed=set();plane_reports=[]
        for group in groups:
            items=[]
            n,u,v=group['normal'],group['u'],group['v']
            for tri in mesh.loop_triangles:
                if tri.polygon_index not in group['faces']:
                    continue
                payload=[]
                for loop in tri.loops:
                    co=np.array(mesh.vertices[mesh.loops[loop].vertex_index].co,dtype=float)
                    uv=[z for layer in mesh.uv_layers for z in layer.data[loop].uv]
                    payload.append(np.array([co@u,co@v,*co,*uv]))
                assert cross2(payload[1][:2]-payload[0][:2],payload[2][:2]-payload[0][:2])>=-EPS
                items.append((payload,tri.polygon_index))
            count,overlap_area=duplicate_pairs(items)
            if not count:
                continue
            kept=[]
            for payload,face in items:
                pieces=[payload]
                for previous,_ in kept:
                    if not pieces:
                        break
                    pieces=[part for piece in pieces for part in (subtract(piece,previous) if touching(piece,previous) else [piece])]
                kept.extend((piece,face) for piece in pieces)
            post_count,post_overlap=duplicate_pairs(kept)
            assert post_count==0,(asset,material,post_count,post_overlap)
            union_area=sum(area(p)for p,_ in kept)
            old_area=sum(area(p)for p,_ in items)
            # Every kept fragment is a subset of its source triangle; every removed fragment is covered by an earlier kept fragment.
            changed.update(group['faces'])
            for piece,face in kept:
                ids=[];uv=[]
                for point in piece:
                    ids.append(len(new_vertices));new_vertices.append(point[2:5].tolist());uv.append(point[5:].tolist())
                new_polys.append(ids);new_uv.append(uv);new_material.append(mesh.polygons[face].material_index);new_source_face.append(face)
            plane_reports.append({'sourceFaces':group['faces'],'localNormal':n.tolist(),'localPlaneOffset':group['d'],
                                  'beforePositiveOverlapTrianglePairs':count,'afterPositiveOverlapTrianglePairs':post_count,
                                  'beforeSummedArea':old_area,'afterUnionArea':union_area,'redundantAreaRemoved':old_area-union_area,
                                  'pairwiseOverlapAreaBefore':overlap_area,'afterOverlapArea':post_overlap,'fragments':len(kept)})
        assert plane_reports,(asset,material)
        for p in mesh.polygons:
            if p.index in changed:
                continue
            new_polys.append(list(p.vertices));new_material.append(p.material_index)
            new_source_face.append(p.index)
            new_uv.append([[z for layer in mesh.uv_layers for z in layer.data[i].uv] for i in p.loop_indices])
        result=bpy.data.meshes.new(asset+'__'+material+'_PlanarUnion')
        result.from_pydata(new_vertices,[],new_polys)
        for mat in mesh.materials:
            result.materials.append(mat)
        for p,mi in zip(result.polygons,new_material):
            p.material_index=mi;p.use_smooth=False
        for layer_index,name in enumerate(uv_names):
            layer=result.uv_layers.new(name=name)
            for polygon,values in zip(result.polygons,new_uv):
                for loop,uv in zip(polygon.loop_indices,values):
                    layer.data[loop].uv=uv[layer_index*2:layer_index*2+2]
        result.update()
        provenance=result.attributes.new('OriginalSourcePolygon','INT','FACE')
        for value,face in zip(provenance.data,new_source_face):
            value.value=face
        result.calc_loop_triangles()
        used=np.array([result.vertices[i].co for p in result.polygons for i in p.vertices],dtype=float)
        bounds_error=float(np.max(abs(np.array([old_bounds.min(axis=0),old_bounds.max(axis=0)])-np.array([used.min(axis=0),used.max(axis=0)]))))
        assert bounds_error<2e-6,(asset,material,bounds_error)
        obj=bpy.data.objects.new(asset+'__'+material,result)
        bpy.context.scene.collection.objects.link(obj)
        obj['AssetKey']=asset;obj['MaterialKey']=material;obj['CleanupScope']='All exact same-facing overlap planes on guarded affected meshes'if ALL_EXACT_PLANES else'Same-facing exact exposed source planes only'
        prepared.append(obj)
        key=asset+'__'+material
        geometry[key+'__trianglesBlenderLocal']=np.array([[result.vertices[i].co for i in tri.vertices]for tri in result.loop_triangles],dtype=float)
        geometry[key+'__sourceFaces']=np.array([new_source_face[tri.polygon_index]for tri in result.loop_triangles],dtype=np.int32)
        geometry[key+'__polygonIndices']=np.array([tri.polygon_index for tri in result.loop_triangles],dtype=np.int32)
        geometry[key+'__originalTrianglesBlenderLocal']=np.array([[mesh.vertices[i].co for i in tri.vertices]for tri in mesh.loop_triangles],dtype=float)
        geometry[key+'__originalSourceFaces']=np.array([tri.polygon_index for tri in mesh.loop_triangles],dtype=np.int32)
        reports.append({'asset':asset,'material':material,'originalMesh':data_name,'objectName':obj.name,
                        'allowlist':[r['path']for r in target['rows']],'sourceMeshIds':sorted(set(r['sourceMeshId']for r in target['rows'])),
                        'originalVertices':len(mesh.vertices),'originalPolygons':len(mesh.polygons),'originalTriangles':len(mesh.loop_triangles),
                        'replacementVertices':len(result.vertices),'replacementPolygons':len(result.polygons),'replacementTriangles':len(result.loop_triangles),
                        'localBounds':[old_bounds.min(axis=0).tolist(),old_bounds.max(axis=0).tolist()],'referencedBoundsError':bounds_error,
                        'originalUVLayers':uv_names,'uvMethod':'Linear interpolation within retained source triangles; earlier original face wins overlapping area',
                        'customNormals':False,'allFlatShaded':True,'materialSlots':[m.name if m else None for m in mesh.materials],
                        'untouchedOriginalPolygons':len(mesh.polygons)-len(changed),'planes':plane_reports})
        print('PREPARED '+asset+'__'+material+' '+str(sum(g['beforePositiveOverlapTrianglePairs']for g in plane_reports))+' ->0',flush=True)

    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    for obj in prepared:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=prepared[0]
    scene=bpy.data.scenes.new(KIT_NAME)
    for obj in prepared:
        scene.collection.objects.link(obj)
    bpy.context.window.scene=scene
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(KIT_NAME+'.blend')),check_existing=False)
    np.savez_compressed(OUT/'cleanup-local-geometry.npz',**geometry)
    fbx_options={'use_selection':True,'object_types':{'MESH'},'axis_forward':'-Z','axis_up':'Y',
                 'apply_unit_scale':True,'apply_scale_options':'FBX_SCALE_UNITS','bake_space_transform':False,
                 'add_leaf_bones':False,'use_mesh_modifiers':False,'mesh_smooth_type':'FACE','path_mode':'AUTO'}
    bpy.ops.export_scene.fbx(filepath=str(OUT/(KIT_NAME+'.fbx')),**fbx_options)
    for obj in prepared:
        for other in prepared:
            other.select_set(other==obj)
        bpy.context.view_layer.objects.active=obj
        bpy.ops.export_scene.fbx(filepath=str(OUT/(obj.name+'.fbx')),**fbx_options)
    assert all(sha(ROOT/p)==h for p,h in hashes.items())
    report={'scope':'Guarded local replacement proposal; no Studio changes/upload or production source changes',
            'sourceHashesBeforeAndAfter':hashes,'sourceFilesUnchanged':True,'meshes':reports,'allowlistedPaths':sum(len(r['allowlist'])for r in reports),
            'surfaceProof':'Convex source triangles subtract only already retained exact-plane source triangles. This preserves each selected oriented planar union including holes. Unselected polygons copied with identical coordinates, loop UV and material index.',
            'fbxProfile':{k:sorted(v)if isinstance(v,set)else v for k,v in fbx_options.items()},
            'coordinateProfile':'Actual kit01 native import and original installed mesh proof: Roblox mesh-local XYZ=(-Blender X,Blender Z,Blender Y). Retain installed CFrame/Size; verify each new native import before integration.',
            'nativeTested':False,'studioTouched':False,'uploaded':False,'excluded':'Near but noncoincident relief/bevel/leaves, opposite-facing coincident surfaces, other materials, route/arrows/floor/veil'}
    report['allExactSameFacingPlanesOnAffectedMeshes']=ALL_EXACT_PLANES
    records=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-records.json').read_text())['editable']['records']
    def prop(record,key):
        value=record['props'].get(key,record['props'].get(key.lower()))
        return value.get('value')if isinstance(value,dict)else value
    for mesh_report in reports:
        matched=[];excluded=[]
        for path,record in records.items():
            if record['class']!='MeshPart' or prop(record,'MeshId')not in mesh_report['sourceMeshIds']:
                continue
            attrs=record['attrs']if isinstance(record['attrs'],dict)else{}
            guarded=prop(record,'Anchored')is True and all(prop(record,k)is False for k in ('CanCollide','CanQuery','CanTouch'))
            guarded=guarded and attrs.get('SourceAsset')==mesh_report['asset']and attrs.get('SourceMaterial')==mesh_report['material']
            row={'path':path,'cframe':prop(record,'CFrame'),'size':prop(record,'Size'),'flags':{k:prop(record,k)for k in ('Anchored','CanCollide','CanQuery','CanTouch','DoubleSided')}}
            (matched if guarded else excluded).append(row)
        mesh_report['allGuardedMatchingInstances']=matched
        mesh_report['excludedUnsafeOrMismatchInstances']=excluded
    report['allGuardedMatchingPaths']=sum(len(r['allGuardedMatchingInstances'])for r in reports)
    (OUT/'cleanup-proof.json').write_text(json.dumps(report,indent=2)+'\n')
    print('COMPLETE '+str(len(reports))+' meshes '+str(report['allowlistedPaths'])+' paths',flush=True)


if __name__ == '__main__':
    main()
