"""Use the exact car-triangle search winner; retain all other verified operations."""
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
result=json.loads((OWN/'proposal04/operations.json').read_text(encoding='utf8'))
out=OWN/'proposal05';out.mkdir(exist_ok=True)
for row in result['operations']:
    if '/MovingCars/'in row['path']and row['path'].endswith('/MC_CarIronBrass__Brass'):
        row['afterSize']=row['beforeSize'][:]
        row['afterCFrame'][:3]=(np.array(row['beforeCFrame'][:3])+(.16,.08,.08)).tolist()
        row['reasons']=['Car exact-triangle search: preserve authored trimSize and give X/Y/Z relief(0.16,0.08,0.08) from recorded56seat;0positive near-plane overlaps against entireIron/Stone/Carveassembly at0.03threshold.']
result['candidate']='combined-proposal05'
(out/'operations.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps({'candidate':result['candidate'],'operations':len(result['operations'])}))
