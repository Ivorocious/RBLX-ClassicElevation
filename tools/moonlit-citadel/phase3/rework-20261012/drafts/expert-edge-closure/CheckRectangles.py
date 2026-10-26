import json
import math
from pathlib import Path

folder = Path(__file__).parent
snapshot = json.loads(Path('docs/artifacts/moonlit-citadel/phase3/rework-20261012/rw10_final_r12_layout.json').read_text())

def polygon(part):
    c, s = part['cf'], part['size']
    return [(c[0]+a*s[0]/2*c[3]+b*s[2]/2*c[5], c[2]+a*s[0]/2*c[9]+b*s[2]/2*c[11])
            for a, b in [(-1,-1),(1,-1),(1,1),(-1,1)]]

def intersects(a, b):
    for p in [a,b]:
        for i in range(4):
            x,y = p[i]; u,v = p[(i+1)%4]
            axis = (y-v,u-x)
            pa = [axis[0]*k+axis[1]*j for k,j in a]
            pb = [axis[0]*k+axis[1]*j for k,j in b]
            if max(pa) < min(pb)-1e-8 or max(pb) < min(pa)-1e-8:
                return False
    return True

def point_segment(p, a, b):
    dx,dy=b[0]-a[0],b[1]-a[1]
    t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy)))
    return math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy)

def distance(a,b):
    if intersects(a,b): return 0
    return min(point_segment(p,q[i],q[(i+1)%4]) for pset,q in [(a,b),(b,a)] for p in pset for i in range(4))

def rectangle(x,y,z,w,d):
    return {'cf':[x,y-.5,z,1,0,0,0,1,0,0,0,1],'size':[w,1,d]}

option = {'ReturnTurn':rectangle(-106,44,-4,7,10),'ReturnBeam':rectangle(-121,46,1,14,3.2),
          'MergeTurn':rectangle(-123,48,12,7,10),'FinalRiseRail':rectangle(-114,50,22,3.6,8),
          'MergeNeedle':rectangle(-114,51,31,3.6,8)}
normal=[p for p in snapshot['parts'] if p.get('attrs',{}).get('MCWalkable') and
        (p['path'].startswith('Obstacles.ArchNormal.') or p['path'].startswith('Obstacles.SouthCloister.'))]
normal_records=[]
for name, part in option.items():
    neighbours=sorted([(distance(polygon(part),polygon(n)),n['path'],n['cf'][1]+n['size'][1]/2) for n in normal])
    normal_records.append({'expert':name,'nearestNormal':[{'distance':d,'path':path,'topY':y} for d,path,y in neighbours[:3]]})
    for n in normal:
        if n['path']=='Obstacles.ArchNormal.ArchMerge.Contact': continue
        assert distance(polygon(part),polygon(n))>0,name+' overlaps an unchanged Normal rectangle'
flat_reach=32*math.sqrt(2*196.2*7.2)/196.2
pairs=[]
for a,b in [('ReturnTurn','MergeTurn'),('ReturnTurn','FinalRiseRail'),('ReturnTurn','MergeNeedle'),('ReturnBeam','FinalRiseRail')]:
    d=distance(polygon(option[a]),polygon(option[b]))
    pairs.append({'from':a,'to':b,'rawEdgeDistance':d,'afterTwoAvatarEdgeOverhangs':d-2.120682,
                  'spareAboveFlatReachAfterOverhang':d-2.120682-flat_reach})
report={'snapshot':'rw10_final_r12_layout.json','flatIdealReach':flat_reach,'twoEdgeOverhangAllowance':2.120682,
        'blockedPairs':pairs,'normalRectangles':normal_records,'nativeProof':False}
(folder/'option-a-rectangles.json').write_text(json.dumps(report,indent=2)+'\n')
for pair in pairs: print(pair)
print('All five late Expert rectangles are separate from other unchanged native Normal polygons; MergeNeedle touches intended shared ArchMerge edge')
