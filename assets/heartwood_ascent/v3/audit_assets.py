"""Verify the HA04 source meshes before the approved package uploads."""
import bpy, bmesh, json, math
from pathlib import Path
root=Path(__file__).resolve().parent
audit=[]
for obj in bpy.data.objects:
    if obj.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(obj.data)
    audit.append({'name':obj.name,'boundaryEdges':sum(e.is_boundary for e in bm.edges),
        'nonmanifoldEdges':sum(not e.is_manifold for e in bm.edges),
        'finite':all(math.isfinite(c) for v in bm.verts for c in v.co),
        'minFaceArea':min(f.calc_area() for f in bm.faces)})
    bm.free()
assert all(x['boundaryEdges']==0 and x['nonmanifoldEdges']==0 and x['finite'] and x['minFaceArea']>1e-8 for x in audit)
(root/'geometry-checks.json').write_text(json.dumps(audit,indent=2)+'\n')
print(json.dumps({'closedMeshes':len(audit),'passed':True}))
