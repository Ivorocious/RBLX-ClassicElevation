import bpy,bmesh,json
from pathlib import Path
bpy.ops.wm.open_mainfile(filepath=str(Path('assets/city_run/CityRun_C13_terminal.blend').resolve()))
checks=[]
for obj in bpy.context.scene.objects:
    if obj.type!='MESH' or not any(word in obj.name for word in ('Roof','Gable','Pediment','Crown')):continue
    bm=bmesh.new();bm.from_mesh(obj.data)
    bad=sum(not e.is_manifold for e in bm.edges)
    checks.append({'mesh':obj.name,'nonManifoldEdges':bad,'triangles':sum(len(f.verts)-2 for f in bm.faces)})
    bm.free()
report={'build':'C13_04','roofMeshes':len(checks),'nonManifoldEdges':sum(c['nonManifoldEdges'] for c in checks),'checks':checks}
Path('docs/artifacts/city-run/C13-roof-geometry-check.json').write_text(json.dumps(report,indent=2))
print({k:v for k,v in report.items() if k!='checks'})
assert report['nonManifoldEdges']==0
