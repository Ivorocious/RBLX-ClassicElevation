"""Ground new side palms against the existing editable shore mesh."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ShipwreckCove_SC_MAP_28.blend'))
trees=[]
for obj in bpy.context.scene.objects:
    if obj.type!='MESH' or obj.get('Asset') not in ('SC_R_ShoreBank','SC_R_SandIsland','SC_R_SandWedge'):continue
    mesh=obj.data
    trees.append(BVHTree.FromPolygons([obj.matrix_world@v.co for v in mesh.vertices],[list(p.vertices) for p in mesh.polygons]))
assert trees
result={}
line=[(0,85),(-8,95),(-27,103),(-46,112),(-66,121),(-85,129),(-95,133)]
lengths=[math.dist(a,b) for a,b in zip(line,line[1:])]
for i in range(10):
    t=(i+.5)/10;side=-1 if i%2 else 1
    distance=t*sum(lengths)
    for a,b,length in zip(line,line[1:],lengths):
        if distance<=length:
            u=distance/length;dx,dz=b[0]-a[0],b[1]-a[1]
            offset=side*(8.2+0.6*(i%3))
            x=a[0]+dx*u+dz/length*offset
            z=a[1]+dz*u-dx/length*offset
            break
        distance-=length
    heights=[]
    for dx,dz in [(0,0),(.5,0),(-.5,0),(0,.5),(0,-.5)]:
        hits=[tree.ray_cast(Vector((x+dx,-z-dz,80)),Vector((0,0,-1)),100)[0] for tree in trees]
        hits=[p.z for p in hits if p is not None]
        assert hits,(i,x,z)
        heights.append(max(hits))
    result[f'GrovePalm29_{i}']=[x,min(heights)-.12,z]
(ROOT/'grounding29.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
