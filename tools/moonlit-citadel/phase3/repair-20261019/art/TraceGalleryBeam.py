import hashlib,json,math
from pathlib import Path
import bpy
from mathutils import Matrix,Vector
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend'
AXIS=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
INV=AXIS.inverted()
assert bpy.app.background
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
graph=bpy.context.evaluated_depsgraph_get();origin=AXIS@Vector((18,66,28));rows=[]
for u in (.47,.5,.53):
    for v in (.60,.66,.72,.80,.9):
        ray=AXIS@Vector((-(u-.5)*2*1.8*math.tan(math.radians(35)),(v-.5)*2*math.tan(math.radians(35)),1))
        hit,point,normal,index,obj,frame=bpy.context.scene.ray_cast(graph,origin,ray.normalized(),distance=300)
        rows.append({'u':u,'v':v,'hit':hit,'object':obj.name if obj else None,'point':list(INV@point),
                     'attrs':{k:obj[k] for k in obj.keys() if isinstance(obj[k],(str,int,bool,float))} if obj else {}})
(HERE/'inspection54/gallery-beam-rays.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf8')
print(json.dumps(rows))
