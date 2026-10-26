from pathlib import Path
import json
import numpy as np

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'docs/artifacts/stud-garden-v2/refinement-20261005/r01'
data=json.loads((OUT.parent/'owner-baseline-geometry.json').read_text())
manifest=json.loads((OUT/'botanical-manifest.json').read_text())
pieces=json.loads((OUT/'botanical-pieces.json').read_text())
origin=np.array([1563,257,-1053])
new_groups={g['name'] for g in manifest['newGroups']}
supports=[]
for p in data['parts']:
    if not p['collide'] or p['role'] not in ('Walk','Refuge') or p['transparency']>.99:continue
    if any(s in p['path'] for s in ('PlantedContext','GreatTwistingBeanstalk','Phase3Art')):continue
    rot=np.array(p['cf'][3:]).reshape(3,3)
    half=np.abs(rot)@(np.array(p['size'])/2)
    center=np.array(p['cf'][:3])-origin
    lo,hi=center-half,center+half
    if hi[1]<2.4:continue
    supports.append((p['path'],lo,hi))
hits=[]
for index,piece in enumerate(pieces):
    if piece['group'] not in new_groups:continue
    points=np.array(piece['vertices'])
    lo,hi=points.min(axis=0),points.max(axis=0)
    if hi[1]<2.4:continue
    for path,a,b in supports:
        body_lo=np.array((a[0]-.6,b[1]-.12,a[2]-.6))
        body_hi=np.array((b[0]+.6,b[1]+7.5,b[2]+.6))
        if np.all(hi>body_lo) and np.all(lo<body_hi):
            hits.append({'group':piece['group'],'sourcePiece':index,'path':path,'pieceBounds':[lo.tolist(),hi.tolist()],'supportBounds':[a.tolist(),b.tolist()]})
report={'newGroups':len(new_groups),'checkedSupportParts':len(supports),'hits':hits,'limits':'Conservative per-piece AABB body clearance screen, not native collision or movement proof.'}
(OUT/'botanical-clearance.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'newGroups':len(new_groups),'checkedSupportParts':len(supports),'hits':len(hits),'pairs':sorted({(p['group'],p['path']) for p in hits})},indent=2))
