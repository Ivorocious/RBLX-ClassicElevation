"""Retain the first proposal and correct newly exposed planes after the full rescan."""
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
before=json.loads((OWN/'proposal01/operations.json').read_text(encoding='utf8'))
out=OWN/'proposal02';out.mkdir(exist_ok=True)
for row in before['operations']:
    path=row['path'];size=np.array(row['beforeSize']);cf=np.array(row['beforeCFrame'])
    if '/MovingCars/'in path and path.endswith('/MC_CarIronBrass__Brass'):
        row['afterSize']=(size+(0,-.16,0)).tolist()
        row['reasons'].append('Refined after fresh global rescan: horizontal-only inset keeps established front/back trim relief and avoids new stone-panel coincidences.')
    if '/GalleryExpertShortcut_LiftNeedle1_Red40/'in path and path.endswith('/MC_GuideIron__Brass'):
        row['afterCFrame'][:3]=(cf[:3]+(0,-.16,0)).tolist()
        row['reasons'].append('Refined after rescan: move all thin gold rim planes below overlapping gallery floor.')
    if any('/'+name+'/'in path for name in('CrownSouthScreenFoot1','CrownWestScreenFoot1'))and path.endswith('__StoneLight'):
        row['afterSize']=(size+(-.16,-.36,-.16)).tolist()
        row['reasons'].append('Refined after rescan: preserve positive upper screen/apron separation rather than moving top toward screen bottom.')
    if '/CrownEmblemLowerPier/'in path and path.endswith('__Stone'):
        row['afterSize']=(size+(0,0,-.36)).tolist()
        row['reasons'].append('Refined after rescan: unequal relief separates pier from both apron materials after apron inset.')
    if '/CrownWestScreenFoot1/'in path and path.endswith('__StoneDark'):
        row['afterSize']=(size+(-.40,0,0)).tolist()
        row['reasons'].append('Refined after rescan: separate opposite trim cap as well as initial end face.')
    if '/GalleryExpertApproach/BetweenBandRail2/StoneSkin/'in path:
        row['afterCFrame'][:3]=(cf[:3]+(0,.08,-.08)).tolist()
        row['reasons'].append('Refined after rescan: shared vertical edge also needs horizontal relief.')
before['candidate']='neighbors-proposal02'
(out/'operations.json').write_text(json.dumps(before,indent=2)+'\n',encoding='utf8')
print(json.dumps({'candidate':before['candidate'],'operations':len(before['operations'])}))
