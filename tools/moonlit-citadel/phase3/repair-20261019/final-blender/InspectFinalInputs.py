"""Read accepted art03 objects and validate native-axis operation seats offline."""
import hashlib
import json
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
BASE=ROOT/'tools/moonlit-citadel/phase3/repair-20261019'
SOURCE=BASE/'art/proposal03/MC_ART_REPAIR55_PROPOSAL.blend'
OPS=BASE/'overlap/expected-native-patch-manifest.json'
MAPPING=BASE/'overlap/surface-objects54-bound.json'
AXIS=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INV=AXIS.inverted()


def frame(values):
    return Matrix(((values[3],values[4],values[5],values[0]),(values[6],values[7],values[8],values[1]),
                   (values[9],values[10],values[11],values[2]),(0,0,0,1)))


def unit(obj):
    return obj.get('ArtRepairUnit') or obj.get('Detail54Unit') or obj.get('Source50Unit') or obj.get('NativeUnit')


def main():
    assert bpy.app.background
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()=='55f5905706c298a88063771c60f9bef11f6dddda48f5e05fa41c3afb21bbe278'
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    bpy.context.view_layer.update()
    world=[o for c in ('Final_233_World_Units','DT54_Corrected_77_Details','Oct19_Reused_Bracketed_Banners')
           for o in bpy.data.collections[c].all_objects if o.type=='MESH' and not o.hide_render]
    mapping={row['nativePath']:row['name'] for row in json.loads(MAPPING.read_text())['objects']}
    operations=json.loads(OPS.read_text())['operations']
    checks=[]
    for row in operations:
        obj=bpy.data.objects[mapping[row['path']]]
        assert not obj.hide_render,obj.name
        after=row['afterCFrame'][:]
        after[:3]=row['beforeCoursePosition']
        native=frame(after)
        points=[native.inverted()@INV@(obj.matrix_world@v.co) for v in obj.data.vertices]
        low=Vector(tuple(min(p[k]for p in points)for k in range(3)))
        high=Vector(tuple(max(p[k]for p in points)for k in range(3)))
        centre=(low+high)/2
        size=high-low
        error=max(abs(size[k]-row['beforeSize'][k])for k in range(3))
        checks.append({'path':row['path'],'object':obj.name,'sizeError':error,'centreError':max(abs(v)for v in centre)})
    summary={'artParts':len(world),'artUnits':len({unit(o)for o in world}),
             'actualArtTriangles':sum(len(p.vertices)-2 for o in world for p in o.data.polygons),
             'operations':len(checks),'maxBeforeSizeError':max(r['sizeError']for r in checks),
             'maxBeforeCentreError':max(r['centreError']for r in checks),
             'finishObjects':[{'name':o.name,'properties':dict(o.items())}for o in bpy.context.scene.objects if o.name.endswith('Finish')],
             'failingSeats':[r for r in checks if max(r['sizeError'],r['centreError'])>.005]}
    (HERE/'input-seat-inspection.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(summary),flush=True)


if __name__=='__main__':main()
