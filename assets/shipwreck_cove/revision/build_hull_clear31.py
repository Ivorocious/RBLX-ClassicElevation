"""Remove only disconnected inner rib cuboids; retain source bounds and remaining face UVs."""
import bpy, bmesh, json
from pathlib import Path
from collections import Counter
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
ids=['SC_R_HullBow','SC_R_HullMid','SC_R_HullStern']
with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Revision13.blend'),link=False) as (src,dst):
    dst.meshes=[n for n in src.meshes if any(n==a or n.startswith(a+'.') for a in ids)]
meshes=list(dst.meshes)
original={a['id']:a for a in json.loads((ROOT/'manifest13.json').read_text())['assets']}
def bounds(mesh):
    return dict(min=[min(v.co[k] for v in mesh.vertices) for k in range(3)],
                max=[max(v.co[k] for v in mesh.vertices) for k in range(3)])
def face_signature(mesh,poly):
    uv=mesh.uv_layers.active.data
    return (poly.material_index,tuple(sorted(tuple(round(x,6) for x in mesh.vertices[mesh.loops[i].vertex_index].co)+tuple(round(x,6) for x in uv[i].uv) for i in poly.loop_indices)))
rows=[];evidence=[];objects=[]
for old in ids:
    mesh=next(m for m in meshes if m.name==old or m.name.startswith(old+'.'))
    mesh=mesh.copy();before=bounds(mesh)
    adjacency={i:set() for i in range(len(mesh.vertices))}
    for e in mesh.edges:
        a,b=e.vertices;adjacency[a].add(b);adjacency[b].add(a)
    components=[];unseen=set(adjacency)
    while unseen:
        stack=[unseen.pop()];component=set(stack)
        while stack:
            for other in adjacency[stack.pop()]:
                if other in unseen:unseen.remove(other);component.add(other);stack.append(other)
        components.append(component)
    remove=set();records=[]
    for component in components:
        lo=[min(mesh.vertices[i].co[k] for i in component) for k in range(3)]
        hi=[max(mesh.vertices[i].co[k] for i in component) for k in range(3)]
        span=[hi[k]-lo[k] for k in range(3)]
        faces=[p for p in mesh.polygons if set(p.vertices)<=component]
        cy=(lo[1]+hi[1])/2
        if len(component)==8 and len(faces)==6 and abs(span[1]-.7)<.001 and 8.1<span[2]<8.5 and 2.5<span[0]<6.9 and min(abs(cy-y) for y in [-10,-5,0,5,10])<.001:
            remove.update(component);records.append(dict(vertices=sorted(component),bounds=dict(min=lo,max=hi),faces=len(faces)))
    assert len(records)==9,(old,len(records))
    kept=Counter(face_signature(mesh,p) for p in mesh.polygons if not any(v in remove for v in p.vertices))
    bm=bmesh.new();bm.from_mesh(mesh);bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[bm.verts[i] for i in remove],context='VERTS')
    bm.to_mesh(mesh);bm.free();mesh.update()
    assert before==bounds(mesh),(old,'bounds changed')
    assert kept==Counter(face_signature(mesh,p) for p in mesh.polygons),(old,'kept faces/UV changed')
    mesh.calc_loop_triangles()
    new=old.replace('SC_R_Hull','SC_HullClear31')
    mesh.name=new
    ob=bpy.data.objects.new(new,mesh);bpy.context.scene.collection.objects.link(ob);objects.append(ob)
    row=dict(original[old]);row.update(id=new,triangles=len(mesh.loop_triangles),vertices=len(mesh.vertices),faces=len(mesh.polygons),sourceAsset=old,sourceFile=new+'.fbx',boundsBlender=before,centerBlender=[(before['min'][k]+before['max'][k])/2 for k in range(3)],notes='Original hull shell and rails with nine disconnected inner rib cuboids removed; same local bounds and kept face UVs.')
    assert row['triangles']==original[old]['triangles']-108
    rows.append(row);evidence.append(dict(asset=new,removed=records,boundsIdentical=True,keptFacesAndUVIdentical=True))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_HullClear31.blend'))
for ob in objects:
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    bpy.ops.export_scene.fbx(filepath=str(ROOT/(ob.name+'.fbx')),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,use_mesh_modifiers=True,bake_anim=False)
(ROOT/'manifest31c.json').write_text(json.dumps(dict(build='SC_KIT_31C',assets=rows,libraryTriangles=sum(a['triangles'] for a in rows),source='ShipwreckCove_Revision13.blend',removedInnerRibs=27),indent=2))
for row in rows:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(ROOT/row['sourceFile']))
    found=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert len(found)==1
    found[0].data.calc_loop_triangles()
    assert len(found[0].data.loop_triangles)==row['triangles']
(ROOT/'hull-clear31-evidence.json').write_text(json.dumps(evidence,indent=2))
print(json.dumps(dict(assets=[dict(id=a['id'],triangles=a['triangles']) for a in rows],removed=27,boundsAndUVsPreserved=True)))

