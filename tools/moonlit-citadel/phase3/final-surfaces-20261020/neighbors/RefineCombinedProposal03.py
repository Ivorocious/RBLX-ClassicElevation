"""Combine only final internal03 with refined neighbor poses for the final global scan."""
import hashlib
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
before=json.loads((OWN/'proposal02/operations.json').read_text(encoding='utf8'))
internal_path=OWN.parent/'internal/proposal03/operations.json'
internal=json.loads(internal_path.read_text(encoding='utf8'))
out=OWN/'proposal03';out.mkdir(exist_ok=True)
for row in before['operations']:
    path=row['path'];size=np.array(row['beforeSize']);cf=np.array(row['beforeCFrame'])
    if '/MovingCars/'in path and path.endswith('/MC_CarIronBrass__Brass'):
        row['afterSize']=(size+(-.16,-.16,0)).tolist()
        row['reasons'].append('Second global rescan exposes side rail planes: inset X/Y only and preserve establishedZseat.')
    if '/GalleryExpertShortcut_LiftNeedle1_Red40/'in path and path.endswith('/MC_GuideIron__Brass'):
        row['afterCFrame'][:3]=(cf[:3]+(0,-.24,0)).tolist()
        row['reasons'].append('Second rescan requires entire gold base top to seat below gallery floor, not only first rim.')
    if any('/'+name+'/'in path for name in('CrownSouthScreenFoot1','CrownWestScreenFoot1'))and path.endswith('__StoneLight'):
        row['afterCFrame'][:3]=(cf[:3]+(0,-.08,0)).tolist()
        row['reasons'].append('Second rescan: lower inset apron light cap0.08 to separate from engaged pilaster tops.')
seen={r['path']for r in before['operations']}
for row in internal['operations']:
    assert row['path']not in seen,row['path'];seen.add(row['path'])
    before['operations'].append({'path':row['path'],'meshId':row['meshIdUnchanged'],'asset':row['asset'],'material':row['material'],
     'beforeSize':row['nativeSizeBefore'],'beforeCFrame':row['nativeCFrameBefore'],'afterSize':row['nativeSizeAfter'],'afterCFrame':row['nativeCFrameAfter'],
     'flags':dict(row['flagsUnchanged'],Anchored=True),'reasons':[row['reason']],'fromInternalFinal03':True})
before.update(candidate='combined-proposal03',count=len(before['operations']),internalManifestSHA256=hashlib.sha256(internal_path.read_bytes()).hexdigest(),
  internalManifestPath=str(internal_path.relative_to(ROOT)),source56FullBindingSHA256='784deaac536a2aaa75bdd53800909c517fd22d83e39349ebb413dea9c3204dcd')
(out/'operations.json').write_text(json.dumps(before,indent=2)+'\n',encoding='utf8')
print(json.dumps({'candidate':before['candidate'],'operations':len(before['operations'])}))
