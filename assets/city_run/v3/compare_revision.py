from pathlib import Path
import bpy,json,hashlib
p=Path(__file__).resolve().parent
def meshes(path):
 bpy.ops.wm.open_mainfile(filepath=str(path))
 rows={}
 for o in bpy.context.scene.objects:
  if o.type!='MESH' or not o.get('V3AssetId'):continue
  d=sorted([sorted([tuple(round(c,5) for c in o.data.vertices[o.data.loops[li].vertex_index].co)+tuple(round(c,5) for c in o.data.uv_layers.active.data[li].uv) for li in poly.loop_indices]) for poly in o.data.polygons])
  rows[o.name]=hashlib.sha256(json.dumps(d).encode()).hexdigest()
 return rows
old=meshes(p/'previous04/CityRun_V3_AssetKit.blend')
new=meshes(p/'CityRun_V3_AssetKit.blend')
r={'unchanged':[k for k,v in old.items() if new.get(k)==v],'changed':[k for k,v in old.items() if new.get(k)!=v],'added':[k for k in new if k not in old]}
(p.parents[2]/'docs/artifacts/city-run/v3/round06/geometry-comparison.json').write_text(json.dumps(r,indent=2))
print({k:len(v) for k,v in r.items()})
