
"""Verify the exact C13 native backup, restored properties and frozen review geometry."""
import collections
import hashlib
import json
from pathlib import Path

root=Path(__file__).resolve().parents[1]
art=root/'docs/artifacts/city-run'
final=json.loads((art/'C13-owner-final-native-audit.json').read_text())
frozen=json.loads((art/'C13-owner-review-native-audit.json').read_text())
backup=root/'backups/city-run-owner-edits-2026-09-12-c13/city-run-c13-owner-final.rbxm'

def equivalent(a,b,key=''):
    if isinstance(a,(float,int)) and not isinstance(a,bool) and isinstance(b,(float,int)) and not isinstance(b,bool):
        return abs(a-b)<=(1/255+.00001 if key in ('color','textColor') else .002)
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(equivalent(v,b[k],k) for k,v in a.items())
    if isinstance(a,list):return len(a)==len(b) and all(equivalent(x,y,key) for x,y in zip(a,b))
    return a==b

def compare(left,right,ignore_review_metadata=False):
    pool=collections.defaultdict(list)
    for r in right:pool[r['path']].append(r)
    missing=[];changed=[]
    for r in left:
        candidates=pool[r['path']]
        def normalized(x):
            x=dict(x)
            if ignore_review_metadata and x['path']=='Course_CityRun':x.pop('attrs',None)
            return x
        match=next((i for i,c in enumerate(candidates) if equivalent(normalized(r),normalized(c))),None)
        if match is not None:candidates.pop(match)
        elif candidates:changed.append(r['path'])
        else:missing.append(r['path'])
    extra=[r['path'] for candidates in pool.values() for r in candidates]
    return {'missing':missing,'changed':changed,'extra':extra}

restoration=compare(final['original'],final['restored'])
keys=set().union(*(r.keys() for r in frozen['records']))-{'triangles'}
roots={r['path'].split('/')[0] for r in frozen['records']}
def geometry(r):return {k:v for k,v in r.items() if k in keys}
review=compare([geometry(r) for r in frozen['records']], [geometry(r) for r in final['original'] if r['path'].split('/')[0] in roots and 'cf' in r])
data=backup.read_bytes();receipt=final['receipt']
result={'build':final['build'],'roots':final['roots'],'records':len(final['original']),
    'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),
    'exactSavedBytes':final['exactSavedBytes'],
    'receiptMatches':len(data)==receipt['bytes'] and hashlib.sha256(data).hexdigest()==receipt['sha256'],
    'restoration':restoration,'reviewedGeometry':review,
    'method':'Saved bytes match serialization and receipt; native restored records include model pivots and DoubleSided windows. Duplicate paths compared as multisets. Geometry tolerance0.002, color1/255+0.00001. Frozen build compares all recorded geometry and appearance fields, excluding triangle bookkeeping, across live course and C13 archive.'}
result['passed']=result['exactSavedBytes'] and result['receiptMatches'] and not any(restoration.values()) and not any(review.values())
(art/'C13_05-final-backup-verification.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
assert result['passed']
