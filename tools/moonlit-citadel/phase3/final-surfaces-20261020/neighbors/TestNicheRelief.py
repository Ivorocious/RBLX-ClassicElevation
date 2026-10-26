"""Exhaust all niche material triangles before the final bounded outward relief."""
import json
from pathlib import Path
import numpy as np
import ScanNeighbors as scan

OWN=Path(__file__).resolve().parent
DATA=OWN/'final-kit02-cleaned139';OUT=OWN/'niche-relief16';OUT.mkdir(exist_ok=True)
meta=json.loads((DATA/'current56-objects.json').read_text(encoding='utf8'))
npz=np.load(DATA/'current56-triangles.npz');old,oldowners,oldfaces=npz['triangles'],npz['owners'],npz['faces']
objects=[];triangles=[];owners=[];faces=[]
for row in meta['objects']:
    if '/WestHighJambNiche/'not in row['nativePath']:continue
    points=old[oldowners==row['index']].copy();fs=oldfaces[oldowners==row['index']]
    if row['nativePath'].endswith('__StoneLight'):points+=np.array((.08,0,0))
    row=dict(row,index=len(objects));row['bounds']=[points.min(axis=(0,1)).tolist(),points.max(axis=(0,1)).tolist()]
    triangles.append(points);owners.append(np.full(len(points),row['index'],np.int32));faces.append(fs);objects.append(row)
scan.OWN=OUT
scan.scan(objects,np.concatenate(triangles),np.concatenate(owners),np.concatenate(faces),scope='within-and-self')
result=json.loads((OUT/'inter-unit-candidates56.json').read_text(encoding='utf8'))
risky=[]
for pair in result['pairs']:
    if pair['a']==pair['b']:continue
    for w in pair['witnesses']:
        if w['gap']<.025 and np.dot(w['normalA'],w['normalB'])>.999:risky.append({'paths':pair['paths'],'witness':w})
(OUT/'NICHE_RELIEF16_CHECK.json').write_text(json.dumps({'pass':not risky,'candidateOutwardXFrom56':.16,'partPairs':len(result['pairs']),'risky':risky},indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':not risky,'riskyPairs':len(risky),'partPairs':len(result['pairs'])}))
