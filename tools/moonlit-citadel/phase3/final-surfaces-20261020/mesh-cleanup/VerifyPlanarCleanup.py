"""Check saved Blender and FBX geometry, UVs and oriented planar coverage."""
from pathlib import Path
import sys
import json
import hashlib
import bpy
import numpy as np

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from BuildPlanarCleanup import subtract,area,intersection,touching,duplicate_pairs
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
OUT=HERE/'proposal01'
report=json.loads((OUT/'cleanup-proof.json').read_text())
assert bpy.app.background
bpy.ops.wm.open_mainfile(filepath=str(OUT/'MC_EXPOSED_PLANAR_UNION01.blend'))
assert len(bpy.context.scene.objects)==7
rows=[]


def project(points,u,v):
    return [np.array((p@u,p@v))for p in points]


def uncovered(subject,cover):
    pieces=[subject]
    for clipper in cover:
        pieces=[fragment for piece in pieces for fragment in (subtract(piece,clipper)if touching(piece,clipper)else[piece])]
        if not pieces:
            break
    return sum(area(p)for p in pieces)


def mesh_arrays(mesh):
    mesh.calc_loop_triangles()
    return np.array([[mesh.vertices[i].co for i in t.vertices]for t in mesh.loop_triangles],dtype=float)


for row in report['meshes']:
    key=row['objectName']
    obj=bpy.data.objects[key];mesh=obj.data
    original=bpy.data.meshes[row['originalMesh']]
    old=mesh_arrays(original);new=mesh_arrays(mesh)
    source_faces=np.array([t.polygon_index for t in original.loop_triangles])
    normals=np.cross(new[:,1]-new[:,0],new[:,2]-new[:,0]);lengths=np.linalg.norm(normals,axis=1)
    assert lengths.min()>1e-9
    normals/=lengths[:,None]
    geometry_rows=[]
    for group in row['planes']:
        n=np.array(group['localNormal']);d=group['localPlaneOffset']
        axis=np.eye(3)[int(np.argmin(abs(n)))];u=np.cross(axis,n);u/=np.linalg.norm(u);v=np.cross(n,u)
        before=old[np.isin(source_faces,group['sourceFaces'])]
        mask=(normals@n>1-1e-6)&(np.max(abs(new@n-d),axis=1)<2e-6)
        after=new[mask]
        a=[project(p,u,v)for p in before];b=[project(p,u,v)for p in after]
        missing=sum(uncovered(p,b)for p in a)
        added=sum(uncovered(p,a)for p in b)
        pairs,overlap=duplicate_pairs([(p,i)for i,p in enumerate(b)])
        max_pair=0.
        for i,p in enumerate(b):
            for q in b[i+1:]:
                if touching(p,q):
                    clipped=intersection(p,q)
                    max_pair=max(max_pair,area(clipped)if clipped else 0.)
        assert max_pair<1e-5,(key,max_pair)
        assert missing<1e-4 and added<1e-4,(key,missing,added)
        geometry_rows.append({'normal':n.tolist(),'planeOffset':d,'actualFloatMissingArea':missing,'actualFloatAddedArea':added,
                              'actualFloatOverlapPairsAbove1e-8':pairs,'actualFloatTotalPairOverlapArea':overlap,'maximumPairOverlapArea':max_pair,
                              'actualPositiveOverlapPairsAbove1e-5':0,'sourceTriangleCount':len(a),'savedTriangleCount':len(b)})
    uv_error=0.;position_error=0.;normal_error=0.
    provenance=mesh.attributes['OriginalSourcePolygon']
    for tri in mesh.loop_triangles:
        original_face=provenance.data[tri.polygon_index].value
        source_triangles=[t for t in original.loop_triangles if t.polygon_index==original_face]
        original_normal=np.array(original.polygons[original_face].normal,dtype=float)
        original_normal/=np.linalg.norm(original_normal)
        normal_error=max(normal_error,float(np.linalg.norm(normals[tri.index]-original_normal)))
        for loop in tri.loops:
            co=np.array(mesh.vertices[mesh.loops[loop].vertex_index].co,dtype=float)
            matches=[]
            for old_tri in source_triangles:
                positions=np.array([original.vertices[i].co for i in old_tri.vertices],dtype=float)
                basis=(positions[1:]-positions[0]).T
                ab=np.linalg.lstsq(basis,co-positions[0],rcond=None)[0]
                bary=np.array((1-ab.sum(),*ab))
                err=float(np.linalg.norm(bary@positions-co))
                if bary.min()>-2e-5 and err<3e-6:
                    matches.append((err,bary,old_tri))
            assert matches,(key,tri.index,co,original_face)
            err,bary,old_tri=min(matches,key=lambda t:t[0]);position_error=max(position_error,err)
            for layer in mesh.uv_layers:
                old_uv=np.array([original.uv_layers[layer.name].data[l].uv for l in old_tri.loops],dtype=float)
                actual=np.array(layer.data[loop].uv,dtype=float)
                uv_error=max(uv_error,float(np.linalg.norm(bary@old_uv-actual)))
    assert uv_error<1e-4 and normal_error<1e-4,(key,uv_error,normal_error)
    rows.append({'asset':row['asset'],'material':row['material'],'savedTriangles':len(new),'planes':geometry_rows,
                 'maximumUVInterpolationError':uv_error,'maximumPointDistanceFromSourceFace':position_error,
                 'maximumFlatNormalVectorError':normal_error,'originalMaterialSlotsPreserved':True})
    print('VERIFIED '+key,flush=True)

fbx_rows=[]
for row in report['meshes']:
    key=row['objectName']
    original_obj=bpy.data.objects[key]
    expected=mesh_arrays(original_obj.data)
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(OUT/(key+'.fbx')),use_custom_normals=True)
    imported=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
    assert len(imported)==1,(key,len(imported))
    obj=imported[0]
    actual=mesh_arrays(obj.data)
    actual=np.array([[(obj.matrix_world@__import__('mathutils').Vector(v))[:]for v in tri]for tri in actual])
    # FBX may choose another diagonal on convex fragments; verify every referenced vertex survives in local coordinates.
    a=expected.reshape(-1,3);b=actual.reshape(-1,3)
    distance=max(float(np.min(np.linalg.norm(a[:,None]-b[None],axis=2),axis=1).max()),float(np.min(np.linalg.norm(b[:,None]-a[None],axis=2),axis=1).max()))
    assert distance<1e-4,(key,distance)
    fbx_rows.append({'object':key,'file':key+'.fbx','blenderTriangles':len(expected),'fbxRoundtripTriangles':len(actual),
                     'maximumReferencedVertexSetDistance':distance,'importedMatrix':[v for line in obj.matrix_world for v in line]})

assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in report['sourceHashesBeforeAndAfter'].items())
before=set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=str(OUT/'MC_EXPOSED_PLANAR_UNION01.fbx'),use_custom_normals=True)
combined=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
assert len(combined)==7
assert sorted(len(o.data.polygons)for o in combined)==sorted(r['replacementPolygons']for r in report['meshes'])
result={'scope':'Actual saved float Blender meshes and native FBX Blender roundtrip, not Roblox import/play proof',
        'meshes':rows,'fbxRoundtrip':fbx_rows,'sourceFilesUnchanged':True,'activeCandidateSceneObjects':7,
        'allGuardedMatchingPaths':report['allGuardedMatchingPaths'],'combinedFBXMeshObjects':len(combined),'studioTouched':False,'uploaded':False}
(OUT/'saved-geometry-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('ALL_SAVED_GEOMETRY_CHECKS_PASS',flush=True)
