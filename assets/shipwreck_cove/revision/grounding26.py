"""Ground plant roots on actual assembled meshes and check cave jump headroom."""
import bpy,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ShipwreckCove_SC_CAVE_26.blend'))
data=json.loads((ROOT/'layout.json').read_text())
byname={p['name']:p for p in data['placements']}
solids=[];cave=[]
for ob in bpy.context.scene.objects:
    asset=ob.get('Asset','')
    if not any(s in asset for s in ['Rock','Sand','ShoreBank','CliffMass','Headland','CaveMouth26','CaveVault26','CaveSurge26']):continue
    mesh=ob.data;vertices=[ob.matrix_world@v.co for v in mesh.vertices]
    bvh=BVHTree.FromPolygons(vertices,[list(p.vertices)for p in mesh.polygons])
    solids.append((ob.name,bvh))
    if any(s in asset for s in ['CaveMouth26','CaveVault26','CaveSurge26']):cave.append((ob.name,bvh))
adjustments=[];headroom=[]
for p in data['placements']:
    if p['asset']=='SC_R_HangingVine25':
        x,y,z=p['p'];hits=[]
        for name,bvh in cave:
            hit,normal,idx,d=bvh.ray_cast(Vector((x,-z,12)),Vector((0,0,1)),100)
            if hit is not None:hits.append((hit.z,name))
        if hits:
            height,support=min(hits);adjustments.append(dict(name=p['name'],oldY=y,y=round(height+.1,3),support=support))
    if p['asset']!='SC_R_FanPalm' or p['name'] not in ['BeachPalm4','BeachPalm5','LeaningPalm3']:continue
    x,y,z=p['p'];point=Vector((x,-z,300));hits=[]
    for name,bvh in solids:
        hit,normal,idx,d=bvh.ray_cast(point,Vector((0,0,-1)),320)
        if hit is not None and normal.z>.2:hits.append((hit.z,name))
    if hits:
        height,support=max(hits)
        adjustments.append(dict(name=p['name'],oldY=y,y=round(height-.12,3),support=support))
for p in data['surfaces']:
    if not p['name'].startswith('Cave26Stone'):continue
    x,y,z=p['p'];hits=[]
    for name,bvh in cave:
        hit,normal,idx,d=bvh.ray_cast(Vector((x,-z,y+.1)),Vector((0,0,1)),100)
        if hit is not None:hits.append(hit.z-y)
    headroom.append(dict(name=p['name'],clearance=round(min(hits),2)if hits else None))
(ROOT/'grounding26.json').write_text(json.dumps(dict(adjustments=adjustments,headroom=headroom),indent=2))
print(json.dumps(dict(plants=len(adjustments),headroomMinimum=min(r['clearance']for r in headroom if r['clearance']is not None),uncovered=[r['name']for r in headroom if r['clearance']is None])))
