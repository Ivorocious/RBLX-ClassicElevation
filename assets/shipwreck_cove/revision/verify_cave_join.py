"""Check the proposed L-shaped cave join against exported Blender geometry."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

root=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(root/'ShipwreckCove_Revision04.blend'))

def tree(name, roblox_position, yaw, roblox_scale):
    mesh=bpy.data.objects[name].data
    x,h,z=roblox_position
    sx,sy,sz=roblox_scale
    transform=(Matrix.Translation(Vector((x,-z,h))) @
               Matrix.Rotation(math.radians(yaw),4,'Z') @
               Matrix.Diagonal(Vector((sx,sz,sy,1))))
    vertices=[transform @ v.co for v in mesh.vertices]
    return BVHTree.FromPolygons(vertices,[tuple(p.vertices) for p in mesh.polygons])

approach=tree('SC_R_CaveChamber',(120,0,22),0,(1.15,1.6,1.6))
bend=tree('SC_R_CaveTideBend',(79,0,58),-90,(1.1,1.65,2.25))

def ray_clear(start,end):
    a=Vector((start[0],-start[2],start[1]))
    b=Vector((end[0],-end[2],end[1]))
    direction=b-a
    distance=direction.length
    for model in (approach,bend):
        hit=model.ray_cast(a,direction.normalized(),distance-.02)
        if hit[0] is not None:return False
    return True

camera=[121,18,28]
sight_target=[114,12,58]
center_route=[[120,17,40],[118,17,46],[115,17,52],[113,17,58],[101,17,58],[91,17,58]]
checks={'cameraSightline':ray_clear(camera,sight_target)}
roof_heights={}
for x,_,z in center_route:
    start=Vector((x,-z,10))
    heights=[]
    for model in (approach,bend):
        hit=model.ray_cast(start,Vector((0,0,1)),100)
        if hit[0] is not None:heights.append(hit[0].z)
    roof_heights[f'{x},{z}']=round(min(heights),2) if heights else None
for i,(a,b) in enumerate(zip(center_route,center_route[1:])):
    checks[f'routeSegment{i}']=ray_clear(a,b)
    dx=b[0]-a[0];dz=b[2]-a[2]
    length=math.hypot(dx,dz)
    if length:
        nx=-dz/length;nz=dx/length
        for side in (-1,1):
            offset=5*side
            aa=[a[0]+nx*offset,a[1],a[2]+nz*offset]
            bb=[b[0]+nx*offset,b[1],b[2]+nz*offset]
            checks[f'routeSegment{i}Side{side}']=ray_clear(aa,bb)
assert all(checks.values()),checks
assert all(height is not None and height>=20 for height in roof_heights.values()),roof_heights
report=dict(build='SC_REV_04',placements=[
    dict(asset='SC_R_CaveChamber',p=[120,0,22],yaw=0,scale=[1.15,1.6,1.6]),
    dict(asset='SC_R_CaveTideBend',p=[79,0,58],yaw=-90,scale=[1.1,1.65,2.25])],
    checks=checks,roofHeightsAtRoute=roof_heights,
    method='World-space BVH rays through both uncollidable visual meshes; camera sightline, center/10-stud-wide route and vertical headroom')
(root/'cave-join-verification04.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
