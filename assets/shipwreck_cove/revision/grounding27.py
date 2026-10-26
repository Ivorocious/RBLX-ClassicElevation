"""Measure roof attachments and plant roots against actual assembled visible meshes."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ShipwreckCove_SC_MAP_27.blend'))
data=json.loads((ROOT/'layout27.json').read_text());cave=[];ground=[]
for ob in bpy.context.scene.objects:
    asset=ob.get('Asset','')
    if ob.type!='MESH':continue
    if any(s in asset for s in ['CaveMouth26','CaveVault26','CaveSurge26']):
        cave.append((ob.name,BVHTree.FromPolygons([ob.matrix_world@v.co for v in ob.data.vertices],[list(p.vertices)for p in ob.data.polygons])))
    if any(s in asset for s in ['Rock','Sand','ShoreBank','CliffMass','CaveMouth26','CaveVault26','CaveSurge26','Headland']):
        ground.append((ob.name,BVHTree.FromPolygons([ob.matrix_world@v.co for v in ob.data.vertices],[list(p.vertices)for p in ob.data.polygons])))
def cast(group,x,z,y,direction):
    hits=[]
    for name,bvh in group:
        hit,n,idx,dist=bvh.ray_cast(Vector((x,-z,y)),Vector(direction),500)
        if hit is not None:hits.append((hit.z,name))
    return hits
out={'placements':{},'falling':{},'evidence':[]}
for p in data['placements']:
    if p['name'].startswith('FixedSpike27'):
        hits=cast(cave,p['p'][0],p['p'][2],16,(0,0,1));assert hits,p['name']
        roof,support=min(hits);out['placements'][p['name']]=[p['p'][0],roof+.3,p['p'][2]]
        out['evidence'].append(dict(name=p['name'],support=support,roof=roof))
    if p['asset']=='SC_R_Palm27':
        x,y,z=p['p'];hits=cast(ground,x,z,180,(0,0,-1));assert hits,p['name']
        h,support=max(hits);out['placements'][p['name']]=[x,h-.12,z]
        out['evidence'].append(dict(name=p['name'],support=support,root=h-.12))
for d in data['falling']:
    x,y,z=d['top']
    if d['name']=='FallingSpike27_1':x=121
    if d['kind']=='stalactite':
        hits=cast(cave,x,z,16,(0,0,1));assert hits,d['name']
        h,support=min(hits);floors=[]
        for s in data['surfaces']:
            a=math.radians(s.get('yaw',0));dx=x-s['p'][0];dz=z-s['p'][2]
            lx=math.cos(a)*dx-math.sin(a)*dz;lz=math.sin(a)*dx+math.cos(a)*dz
            if abs(lx)<s['size'][0]/2 and abs(lz)<s['size'][2]/2:floors.append(s['p'][1])
        assert floors,d['name'];floor=max(floors)
        out['falling'][d['name']]=dict(top=[x,h-3.2,z],bottom=[x,floor+3.58,z])
        out['evidence'].append(dict(name=d['name'],support=support,roof=h,impactFloor=floor))
    else:
        i=d['name'].split('_')[-1];name='DropPalm27_'+i;root=out['placements'][name]
        out['falling'][d['name']]=dict(top=[x,root[1]+27,z],bottom=[x,8.88,z])
(ROOT/'grounding27.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out))


