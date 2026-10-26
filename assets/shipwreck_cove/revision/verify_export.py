"""Re-import the exported FBX and verify its actual evaluated mesh triangles."""
import bpy
import hashlib
import json
from pathlib import Path

root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest04.json').read_text())
expected={row['id']:row for row in manifest['assets']}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(root/'ShipwreckCove_Revision04.fbx'))
rows=[]
for ob in bpy.context.scene.objects:
    if ob.type!='MESH':continue
    mesh=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    mesh.calc_loop_triangles()
    row=dict(id=ob.name,triangles=len(mesh.loop_triangles),vertices=len(mesh.vertices),materials=len(mesh.materials))
    assert row['id'] in expected,row
    assert row['triangles']==expected[row['id']]['triangles'],row
    assert row['triangles']<=1500,row
    if row['id'] in ('SC_R_SandIsland','SC_R_SandWedge'):
        assert all(face.normal.z>.01 for face in mesh.polygons),(row['id'],'FBX sand face points downward')
    rows.append(row)
assert len(rows)==len(expected)
total=sum(row['triangles'] for row in rows)
assert total==manifest['libraryTriangles'] and total<=8000
report=dict(build=manifest['build'],method='Blender 5.2 FBX re-import, evaluated meshes, loop triangulation',
            meshes=rows,uniqueTriangles=total,libraryTriangleCeiling=8000,
            perAssetTriangleCeiling=1500,estimatedPlacedTriangles=manifest['estimatedPlacedTriangles'],files={})
for name in ('build_revision.py','ShipwreckCove_Revision04.blend','ShipwreckCove_Revision04.fbx','manifest04.json','palette.png'):
    raw=(root/name).read_bytes()
    report['files'][name]=dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
(root/'export-verification04.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k not in ('meshes','files')}))
