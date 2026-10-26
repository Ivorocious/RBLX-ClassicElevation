"""Vectorized finite first-visible-surface rays; no Studio or Blender use."""
from collections import Counter
import json
from pathlib import Path
import os
import time
import numpy as np

OWN=Path(__file__).resolve().parent
if os.environ.get('MC_NEIGHBOR_DIR'):OWN=Path(os.environ['MC_NEIGHBOR_DIR']).resolve()
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
data=json.loads((OWN/'current56-objects.json').read_text(encoding='utf8'))
objects=data['objects']
raw=json.loads((OWN/'inter-unit-candidates56.json').read_text(encoding='utf8'))
npz=np.load(OWN/'current56-triangles.npz');triangles,owners=npz['triangles'],npz['owners']
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/final/native-snapshot55.json').read_text(encoding='utf8'))['editable']['records']
ORIGIN=np.array((4000,300,2600))
eyes=[]


def prop(row,key):
    value=row['props'].get(key,row['props'].get(key.lower()))
    return value.get('value') if isinstance(value,dict) else value


for path,row in native.items():
    if row['class']!='Part' or row['attrs'].get('MCWalkable')is not True:continue
    cf=np.array(prop(row,'CFrame'));size=np.array(prop(row,'Size'));p=cf[:3]-ORIGIN;r=cf[3:].reshape(3,3)
    if r[1,1]<.98:continue
    for x,z in((0,0),(-1,-1),(-1,1),(1,-1),(1,1)):
        eyes.append({'path':path,'point':p+r[:,1]*(size[1]/2+5.5)+r[:,0]*x*max(0,size[0]/2-2)+r[:,2]*z*max(0,size[2]/2-2)})
eyes.extend({'path':'AcceptedCrownStanding','point':np.array(p)}for p in((6,155.5,-18),(-8,155.5,-30)))
eye_points=np.array([r['point'] for r in eyes])
olow=np.array([r['bounds'][0] for r in objects]);ohigh=np.array([r['bounds'][1] for r in objects])
offsets=np.cumsum([0]+[r['triangles'] for r in objects])
assert all(np.all(owners[offsets[i]:offsets[i+1]]==i)for i in range(len(objects)))
e1,e2=triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0]
double=np.array([r.get('doubleSided',False)for r in objects])[owners]
rays=0


def cast(origin,target):
    global rays
    delta=target-origin;distance=np.linalg.norm(delta);direction=delta/distance;rays+=1
    with np.errstate(divide='ignore',invalid='ignore'):
        t0=(olow-origin)/direction;t1=(ohigh-origin)/direction
    near=np.max(np.minimum(t0,t1),axis=1);far=np.min(np.maximum(t0,t1),axis=1)
    selected=np.flatnonzero((far>=np.maximum(near,0))&(near<=distance+.12))
    if not len(selected):return None
    idx=np.concatenate([np.arange(offsets[i],offsets[i+1])for i in selected])
    pvec=np.cross(direction,e2[idx]);det=np.einsum('ij,ij->i',e1[idx],pvec)
    mask=np.where(double[idx],np.abs(det)>1e-9,det>1e-9)
    idx,pvec,det=idx[mask],pvec[mask],det[mask]
    if not len(idx):return None
    tvec=origin-triangles[idx,0];u=np.einsum('ij,ij->i',tvec,pvec)/det
    mask=(u>=-1e-7)&(u<=1+1e-7);idx,tvec,det,u=idx[mask],tvec[mask],det[mask],u[mask]
    if not len(idx):return None
    qvec=np.cross(tvec,e1[idx]);v=qvec@direction/det;t=np.einsum('ij,ij->i',e2[idx],qvec)/det
    mask=(v>=-1e-7)&(u+v<=1+1e-7)&(t>.02)&(t<=distance+.12)
    if not mask.any():return None
    idx,t=idx[mask],t[mask];closest=np.argmin(t)
    return int(owners[idx[closest]]),float(t[closest]),float(distance),int(idx[closest])


visible=[];counts=Counter();start=time.monotonic()
for index,pair in enumerate(raw['pairs']):
    a,b=pair['a'],pair['b'];found=[];exposed=[];risky=0
    for witness in pair['witnesses']:
        point=np.array(witness['point']);na=np.array(witness['normalA']);nb=np.array(witness['normalB'])
        ndot=float(na@nb)
        if ndot<.999 and not(objects[a]['doubleSided']or objects[b]['doubleSided']):continue
        risky+=1
        toward=eye_points-point;dist=np.linalg.norm(toward,axis=1)
        front_a=np.ones(len(eyes),bool)if objects[a]['doubleSided'] else toward@na>.05
        front_b=np.ones(len(eyes),bool)if objects[b]['doubleSided'] else toward@nb>.05
        eligible=np.flatnonzero(front_a&front_b&(dist>.5)&(dist<260))
        for ei in eligible[np.argsort(dist[eligible])[:16]]:
            hit=cast(eye_points[ei],point)
            if hit and hit[0]in(a,b)and abs(hit[1]-hit[2])<.12:
                found.append({'eye':eye_points[ei].tolist(),'support':eyes[ei]['path'],'point':point.tolist(),'firstVisiblePath':objects[hit[0]]['nativePath'],'firstVisibleTriangle':hit[3],'witness':witness})
                break
        # A local outward eye diagnoses an exposed exterior face, not a reachable gameplay view.
        if not found:
            for step in(3,12,45):
                targeteye=point+na*step
                if ndot<.999 and not(objects[b]['doubleSided']):continue
                hit=cast(targeteye,point)
                if hit and hit[0]in(a,b)and abs(hit[1]-hit[2])<.12:
                    exposed.append({'eye':targeteye.tolist(),'point':point.tolist(),'firstVisiblePath':objects[hit[0]]['nativePath'],'witness':witness,'scope':'Diagnostic local outward eye; no route support claim'})
                    break
        if len(found)>=3:break
    if not risky:state='opposed-single-sided-internal-contact'
    elif found:state='supported-route-visible'
    elif exposed:state='locally-exposed-no-route-witness'
    else:state='no-exposed-witness'
    counts[state]+=1
    row=dict(pair,state=state,visibleWitnesses=found,exposedWitnesses=exposed[:3])
    visible.append(row)
    if index%100==0:print(json.dumps({'done':index,'rays':rays,'states':dict(counts),'seconds':time.monotonic()-start}),flush=True)
result={'scope':'Finite exact triangle witnesses ray-tested from677 supported course-height eyes and additional diagnostic outward eyes. First-visible-surface test includes native backface/double-sided flags. Same appearance can still differ in native UV or shading; not temporal native flashing proof.', 'objects':len(objects),'triangles':len(triangles),'routeEyes':len(eyes),'rays':rays,'states':dict(counts),'pairs':visible,'studioTouched':False,'blenderTouched':False}
(OWN/'inter-unit-visibility56.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in result.items()if k!='pairs'}),flush=True)
