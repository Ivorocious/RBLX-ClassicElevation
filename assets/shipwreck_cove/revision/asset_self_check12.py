"""Bounded avatar-clearance scan of SC_MAP_12 visual meshes only."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root=Path(__file__).resolve().parent
data=json.loads((root/'layout.json').read_text())
assert data['build']=='SC_MAP_12'
bpy.ops.wm.open_mainfile(filepath=str(root/'ShipwreckCove_SC_MAP_12.blend'))

names=('R_HullBow_181','R_HullMid_182','R_HullStern_183',
       'MastYard_081','MastYard_083','TornSail_082','TornSail_084',
       'CaveApproach','TideChamber','R_SeaRockFlat_199')
trees={}
for name in names:
    ob=bpy.data.objects[name]
    ob.update_tag()
    world=ob.matrix_world
    vertices=[world @ v.co for v in ob.data.vertices]
    trees[name]=BVHTree.FromPolygons(vertices,[tuple(p.vertices) for p in ob.data.polygons])

def roblox(v):return Vector((v[0],-v[2],v[1]))
def scan(path_name,points):
    hits=[]
    for seg,(a,b) in enumerate(zip(points,points[1:])):
        dist=math.hypot(b[0]-a[0],b[2]-a[2])
        count=max(1,math.ceil(dist))
        for step in range(count+1):
            t=step/count
            x=a[0]+(b[0]-a[0])*t
            floor=a[1]+(b[1]-a[1])*t
            z=a[2]+(b[2]-a[2])*t
            for height,label in ((.5,'feet'),(3,'body'),(6,'head')):
                p=roblox((x,floor+height,z))
                for name,tree in trees.items():
                    if path_name=='ship' and name.startswith(('Cave','Tide','R_Sea')):continue
                    if path_name=='cave' and name.startswith(('R_Hull','Mast','Torn')):continue
                    nearest=tree.find_nearest(p,3)
                    if nearest[0] is not None and nearest[3]<2.0:
                        loc=nearest[0]
                        hits.append(dict(segment=seg,t=round(t,2),route=[round(x,2),round(floor+height,2),round(z,2)],
                                         height=label,asset=name,distance=round(nearest[3],2),
                                         meshPoint=[round(loc.x,2),round(loc.z,2),round(-loc.y,2)]))
    return hits

ship=[[-108,13,-66]]+data['paths']['S02']+[[0,43,-100]]
cave=[[108,15,-18]]+data['paths']['S04_Entry']+data['paths']['H02']
hits={'ship':scan('ship',ship),'cave':scan('cave',cave)}
roof=[]
for a,b in zip(cave[1:],cave[2:]):
    dist=math.hypot(b[0]-a[0],b[2]-a[2])
    n=max(1,math.ceil(dist/2))
    dx=b[0]-a[0];dz=b[2]-a[2]
    length=math.hypot(dx,dz)
    nx=-dz/length if length else 0;nz=dx/length if length else 0
    for i in range(n+1):
        t=i/n
        for offset in (-5,0,5):
            x=a[0]+dx*t+nx*offset
            z=a[2]+dz*t+nz*offset
            floor=a[1]+(b[1]-a[1])*t
            p=roblox((x,floor+6,z))
            heights=[]
            for name in ('CaveApproach','TideChamber','R_SeaRockFlat_199'):
                hit=trees[name].ray_cast(p,Vector((0,0,1)),100)
                if hit[0] is not None:heights.append(hit[0].z)
            roof.append(dict(x=round(x,1),z=round(z,1),offset=offset,floor=round(floor,1),
                             roof=round(min(heights),1) if heights else None))
summary={}
for group,rows in hits.items():
    by_asset={}
    for row in rows:
        current=by_asset.get(row['asset'])
        if current is None or row['distance']<current['distance']:by_asset[row['asset']]=row
    by_segment={}
    for row in rows:
        key=f"{row['segment']}:{row['asset']}:{row['height']}"
        entry=by_segment.setdefault(key,dict(samples=0,nearest=row,first=row,last=row))
        entry['samples']+=1
        entry['last']=row
        if row['distance']<entry['nearest']['distance']:entry['nearest']=row
    summary[group]=dict(hitSamples=len(rows),nearestByAsset=list(by_asset.values()),clusters=by_segment)
print(json.dumps(summary,indent=2))
covered=[r for r in roof if r['roof'] is not None]
uncovered=[r for r in roof if r['roof'] is None]
roof_jumps=[]
for offset in (-5,0,5):
    samples=[r for r in roof if r['offset']==offset]
    for a,b in zip(samples,samples[1:]):
        if a['roof'] is not None and b['roof'] is not None:
            roof_jumps.append(dict(fromSample=a,toSample=b,heightChange=round(abs(a['roof']-b['roof']),1)))
print(json.dumps(dict(caveRoofSamples=len(roof),uncovered=uncovered[:20],uncoveredCount=len(uncovered),
                      minimumHeadroom=round(min(r['roof']-r['floor'] for r in covered),1),
                      minimumSample=min(covered,key=lambda r:r['roof']-r['floor']),
                      largestRoofJumps=sorted(roof_jumps,key=lambda r:-r['heightChange'])[:3]),indent=2))
