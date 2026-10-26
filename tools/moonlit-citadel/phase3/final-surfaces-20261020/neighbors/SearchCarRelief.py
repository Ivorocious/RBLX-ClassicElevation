"""Search small fixed-pose trim offsets against every other recorded car triangle."""
import itertools
import json
from pathlib import Path
import numpy as np
from ScanNeighbors import clip

OWN=Path(__file__).resolve().parent
meta=json.loads((OWN/'current56-objects.json').read_text(encoding='utf8'))['objects']
npz=np.load(OWN/'current56-triangles.npz');triangles,owners=npz['triangles'],npz['owners']
arow=next(r for r in meta if '/Lower_Bay1/'in r['nativePath']and r['nativePath'].endswith('__Brass'))
brows=[r for r in meta if '/Lower_Bay1/'in r['nativePath']and r!=arow]
a=triangles[owners==arow['index']];b=triangles[np.isin(owners,[r['index']for r in brows])]
na=np.cross(a[:,1]-a[:,0],a[:,2]-a[:,0]);na/=np.linalg.norm(na,axis=1)[:,None]
nb=np.cross(b[:,1]-b[:,0],b[:,2]-b[:,0]);nb/=np.linalg.norm(nb,axis=1)[:,None]
parallel=na@nb.T>1-1e-6
alo,ahi=a.min(axis=1),a.max(axis=1);blo,bhi=b.min(axis=1),b.max(axis=1)
drop=np.argmax(abs(na),axis=1);assert np.min(np.max(abs(na),axis=1))>.999999
base=np.einsum('aj,bj->ab',na,b[:,0])-np.einsum('aj,aj->a',na,a[:,0])[:,None]
threshold=.03
rows=[]
for x,y,z in itertools.product((-.16,-.08,0,.08,.16),(-.12,-.08,0,.08,.12,.16),(-.16,-.08,0,.08,.16,.2,.24)):
    shift=np.array((x,y,z))
    near=abs(base-(na@shift)[:,None])<threshold
    overlap=np.minimum(ahi[:,None,:]+shift,bhi[None,:,:])-np.maximum(alo[:,None,:]+shift,blo[None,:,:])
    for axis in range(3):overlap[drop==axis,:,axis]=1
    valid=parallel&near&np.all(overlap>1e-6,axis=2)
    rows.append({'shift':shift.tolist(),'candidateTrianglePairs':int(valid.sum()),'cost':float(np.linalg.norm(shift)),'indices':np.argwhere(valid)})
rows.sort(key=lambda r:(r['candidateTrianglePairs'],r['cost']))
best=[]
for row in rows[:40]:
    shift=np.array(row['shift']);hits=[]
    for ai,bi in row['indices']:
        axes=[k for k in range(3)if k!=drop[ai]]
        area,centre=clip((a[ai]+shift)[:,axes],b[bi][:,axes])
        if area>.01:hits.append({'a':int(ai),'b':int(bi),'area':float(area)})
    result={k:v for k,v in row.items()if k!='indices'};result['actualPositiveOverlapPairs']=len(hits);result['summedArea']=sum(r['area']for r in hits);result['hits']=hits
    best.append(result)
best.sort(key=lambda r:(r['actualPositiveOverlapPairs'],r['summedArea'],r['cost']))
(OWN/'car-relief-search.json').write_text(json.dumps({'scope':'Same-facing exact triangles,car Brass versusall otherIron/Stone/Carveparts,no occlusion.0.03plane threshold.OriginalnativeSize retained; current56carBrassZ+0.06 baseline included.','trials':len(rows),'best':best},indent=2)+'\n',encoding='utf8')
print(json.dumps(best[:5],indent=2))
