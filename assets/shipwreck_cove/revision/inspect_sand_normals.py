"""Inspect shore face orientation in the editable blend and exported FBX."""
import bpy
import json
from pathlib import Path

root=Path(__file__).resolve().parent
report={}
for source in ('blend','fbx'):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if source=='blend':bpy.ops.wm.open_mainfile(filepath=str(root/'ShipwreckCove_Revision04.blend'))
    else:bpy.ops.import_scene.fbx(filepath=str(root/'ShipwreckCove_Revision04.fbx'))
    report[source]={}
    for name in ('SC_R_SandIsland','SC_R_SandWedge'):
        mesh=bpy.data.objects[name].data
        normals=[p.normal.z for p in mesh.polygons]
        report[source][name]=dict(faces=len(normals),up=sum(n>.01 for n in normals),
                                  down=sum(n<-.01 for n in normals),vertical=sum(abs(n)<=.01 for n in normals),
                                  minimum=min(normals),maximum=max(normals))
        assert report[source][name]['down']==0,(source,name,report[source][name])
print(json.dumps(report))
