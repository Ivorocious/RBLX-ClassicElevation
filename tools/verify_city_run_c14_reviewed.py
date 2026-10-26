"""Verify C14 native restore, frozen review state and signature preservation."""
import collections, hashlib, json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
art=root/'docs/artifacts/city-run'
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


frozen=json.loads((art/'C14_05-review-resume-audit.json').read_text())
before=json.loads((art/'C14-before-native-audit.json').read_text())
def signatures(records):
 prefixes=['Course_CityRun/Obstacles/Moving/'+n for n in ['BallA','BallB','BallACable','BallBCable']]
 prefixes+=['Course_CityRun/Obstacles/WalkingSurfaces/'+n for n in ['BallA_Main','BallB_Main']]
 output=[]
 for record in records:
  if any(record['path']==p or record['path'].startswith(p+'/') for p in prefixes):
   record=dict(record)
   attrs=dict(record.get('attrs') or {})
   for key in list(attrs):
    if key.startswith('C14'):attrs.pop(key)
   record['attrs']=attrs
   output.append(record)
 return output
signature=compare(signatures(before['original']),signatures(frozen['records']))
cp='Course_CityRun/Checkpoints/Checkpoint_003'
owner_cp=compare([r for r in before['original'] if r['path']==cp],[r for r in frozen['records'] if r['path']==cp])
result={'build':frozen['build'],'signaturePreservation':signature,'ownerMainCP03':owner_cp}
final_path=art/'C14_05-reviewed-final-native-audit.json'
if final_path.exists():
 final=json.loads(final_path.read_text())
 backup=root/'backups/city-run-owner-edits-2026-09-13-c14/city-run-c14-reviewed.rbxm'
 data=backup.read_bytes();receipt=final['receipt']
 result.update(roots=final['roots'],records=len(final['original']),bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),exactSavedBytes=final['exactSavedBytes'],receiptMatches=len(data)==receipt['bytes'] and hashlib.sha256(data).hexdigest()==receipt['sha256'],restoration=compare(final['original'],final['restored']),reviewedState=compare(frozen['records'],final['original'],True))
 result['backupIntegrityPassed']=result['exactSavedBytes'] and result['receiptMatches'] and not any(result['restoration'].values())
 result['courseMatchesFrozenReview']=not any(compare([r for r in frozen['records'] if r['path'].split('/')[0]=='Course_CityRun'],[r for r in final['original'] if r['path'].split('/')[0]=='Course_CityRun'],True).values())
 result['allReviewContextMatches']=not any(result['reviewedState'].values())
 attrs=next(r['attrs'] for r in final['original'] if r['path']=='Course_CityRun')
 result['reviewScores']={key:attrs.get(key) for key in ['C14GroundingScore','C14ReadabilityScore','C14CompositionScore','C14CompletenessScore']}
 result['visualAcceptanceComplete']=attrs.get('VisualReviewPassed') is True and all(isinstance(v,(int,float)) and v>8 for v in result['reviewScores'].values())
 result['sameBuild']=final['build']==frozen['build']
 result['passed']=result['backupIntegrityPassed'] and result['courseMatchesFrozenReview'] and result['allReviewContextMatches'] and result['visualAcceptanceComplete'] and result['sameBuild'] and not any(signature.values()) and not any(owner_cp.values())
 target='C14_05-reviewed-backup-verification.json'
else:
 result['passed']=not any(signature.values()) and not any(owner_cp.values())
 target='C14_05-signature-preservation.json'
result['method']='Native property multiset comparison; tolerance0.002, colors1/255. Review-only root attributes excluded from frozen comparison; C14 archive path notes excluded from original signature comparison.'
(art/target).write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
assert result['passed']
