"""Re-import the delivered FBX and count its actual triangulated mesh data."""
import bpy, json, hashlib
from pathlib import Path
root=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(root/'ShipwreckCove_Kit04.fbx'))
manifest=json.loads((root/'manifest.json').read_text())
expected={r['id']:r for r in manifest['assets']}
rows=[]
for ob in bpy.context.scene.objects:
    if ob.type!='MESH':continue
    mesh=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    mesh.calc_loop_triangles()
    row=dict(id=ob.name,triangles=len(mesh.loop_triangles),materials=len(mesh.materials),vertices=len(mesh.vertices),modifiers=len(ob.modifiers))
    assert row['id'] in expected,row
    assert row['triangles']==expected[row['id']]['triangles'],row
    assert row['triangles']<=expected[row['id']]['triangleCeiling'],row
    rows.append(row)
assert len(rows)==len(expected)
report=dict(build=manifest['build'],method='Blender FBX re-import, evaluated meshes, loop triangulation',meshes=rows,uniqueTriangles=sum(r['triangles']for r in rows),estimatedPlacedTriangles=manifest['estimatedPlacedTriangles'],files={})
for name in ['ShipwreckCove_Kit04.fbx','ShipwreckCove_Kit04.blend','manifest.json','studies.json','palette.png']:
    raw=(root/name).read_bytes();report['files'][name]=dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
(root/'export-verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='meshes'}))
