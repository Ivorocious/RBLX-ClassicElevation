from pathlib import Path
import bpy,json
p=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(p/'CityRun_V3_AssetKit.blend'))
rows={}
for o in bpy.context.scene.objects:
 if o.type=='MESH' and o.get('V3AssetId'):
  v=[v.co for v in o.data.vertices]; mn=[min(c[i] for c in v) for i in range(3)];mx=[max(c[i] for c in v) for i in range(3)]
  rows[o.name]={'centerBlender':[(mn[i]+mx[i])/2 for i in range(3)],'dimensions':[mx[i]-mn[i] for i in range(3)]}
(p/'bounds.json').write_text(json.dumps(rows,indent=2))
