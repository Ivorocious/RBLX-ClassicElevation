"""Screen all emitted scenery against R305 space and conservative inbound reach."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path
import numpy as np

parser=argparse.ArgumentParser()
parser.add_argument('folder',type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
data=json.loads((root/'docs/artifacts/stud-garden-v2/phase2/round3/offline-r305/geometry.json').read_text())
pieces=json.loads((args.folder/'placement-pieces.json').read_text())
origin=np.array((9200,80,3500))
launch=[];zones=[];obstacles=[]
for p in data['parts']:
    cf=np.array(p['cf']);pos=cf[:3]-origin;rot=cf[3:].reshape(3,3)
    h=np.abs(rot)@(np.array(p['size'])/2);lo,hi=pos-h,pos+h
    if p['transparency']<.99 and p['path']!='Decoration.LowGardenGround':obstacles.append((lo,hi,p['path']))
    if p['collide'] and hi[1]>2.4 and p['path']!='Decoration.LowGardenGround':
        seed=p['role'] in ('Walk','Refuge') and not any(t in p['path'] for t in ('PlantedContext','LowerVineLandmark','CandyBlossom','RaccoonBank'))
        launch.append((lo,hi,p['path'],seed))
    if p['collide'] and p['role'] in ('Walk','Refuge') and hi[1]>2.4:
        zones.append((lo+(-2.2,0,-2.2),hi+(2.2,12.5,2.2),p['path']))
for p in data['paths']:
    margin=2.3 if p['kind']=='ExpertBranch' else 4
    for i,(a,b) in enumerate(zip(p['points'],p['points'][1:])):
        zones.append((np.minimum(a,b)-(margin,0,margin),np.maximum(a,b)+(margin,12.5,margin),str(p.get('name',p['kind']))+str(i)))
lo=np.array([r[0] for r in launch]);hi=np.array([r[1] for r in launch]);reachable=np.array([r[3] for r in launch])
velocity=math.sqrt(2*196.2*7.2)
dx=np.maximum(np.maximum(lo[None,:,0]-hi[:,None,0],lo[:,None,0]-hi[None,:,0]),0)
dz=np.maximum(np.maximum(lo[None,:,2]-hi[:,None,2],lo[:,None,2]-hi[None,:,2]),0)
rise=hi[None,:,1]-hi[:,None,1]
links=(rise<=7.2)&(16*(velocity+np.sqrt(np.maximum(0,velocity**2-2*196.2*rise)))/196.2+2>=np.sqrt(dx*dx+dz*dz))
while True:
    expanded=reachable|np.any(links[reachable],axis=0)
    if np.array_equal(expanded,reachable):break
    reachable=expanded
launch=[r for r,k in zip(launch,reachable) if k];lo=lo[reachable];hi=hi[reachable]
zlo=np.array([r[0] for r in zones]);zhi=np.array([r[1] for r in zones])
olo=np.array([r[0] for r in obstacles]);ohi=np.array([r[1] for r in obstacles])
space=[];reach=[];visible=[];checked=Counter();root_faces=0
for index,p in enumerate(pieces):
    if p['detail']=='stud' or p['kind']=='root skin':continue
    v=np.array(p['vertices']);a,b=v.min(axis=0),v.max(axis=0);center=v.mean(axis=0)
    checked[p['kind']]+=1
    hits=np.where(np.all(b>zlo,axis=1)&np.all(a<zhi,axis=1))[0]
    if len(hits):space.append({'piece':index,'group':p['group'],'source':zones[int(hits[0])][2]})
    hits=np.where(np.all(b+.08>olo,axis=1)&np.all(a-.08<ohi,axis=1))[0]
    if len(hits):visible.append({'piece':index,'group':p['group'],'source':obstacles[int(hits[0])][2]})
    if b[1]<=2.4:continue
    for face in p['faces']:
        points=v[list(face)];n=np.cross(points[1]-points[0],points[2]-points[0]);norm=np.linalg.norm(n)
        if norm<1e-8:continue
        n/=norm
        if n@(points.mean(axis=0)-center)<0:n=-n
        if n[1]<.5:continue
        fa,fb=points.min(axis=0),points.max(axis=0)
        if fb[1]<=2.4:continue
        rise=fa[1]-hi[:,1]
        dx=np.maximum(np.maximum(lo[:,0]-fb[0],fa[0]-hi[:,0]),0)
        dz=np.maximum(np.maximum(lo[:,2]-fb[2],fa[2]-hi[:,2]),0)
        margin=16*(velocity+np.sqrt(np.maximum(0,velocity**2-2*196.2*rise)))/196.2+2-np.hypot(dx,dz)
        hits=np.where((rise<=7.2)&(margin>=0))[0]
        if len(hits):
            i=int(hits[np.argmax(margin[hits])]);reach.append({'piece':index,'group':p['group'],'kind':p['kind'],'source':launch[i][2],'margin':float(margin[i])})
            break
result={'candidate':json.loads((args.folder/'manifest.json').read_text())['candidate'],
    'checkedSolidPieces':dict(checked),'reachableR305LaunchParts':len(launch),'bodyIntrusions':space,
    'existingVisibleOverlaps':visible,'potentialInboundScenery':reach,'limits':[
    'Conservative axis-aligned bounds and ideal jump reach with two-stud partial contact allowance.',
    'R305 baseline collision unchanged; new visual root underbodies and decorative studs excluded.',
    'No normal-control gameplay, camera movement, hazard lifecycle, or crowd/device performance test.']}
(args.folder/'static-art-audit.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:len(result[k]) for k in ('bodyIntrusions','existingVisibleOverlaps','potentialInboundScenery')}))
print(json.dumps(reach[:12]))
