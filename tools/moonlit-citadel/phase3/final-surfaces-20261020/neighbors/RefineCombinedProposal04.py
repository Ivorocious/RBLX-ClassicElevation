"""Keep complete combined03 and move car trim clear of newly exposed rear rail faces."""
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
result=json.loads((OWN/'proposal03/operations.json').read_text(encoding='utf8'))
out=OWN/'proposal04';out.mkdir(exist_ok=True)
for row in result['operations']:
    if '/MovingCars/'in row['path'] and row['path'].endswith('/MC_CarIronBrass__Brass'):
        row['afterCFrame'][:3]=(np.array(row['beforeCFrame'][:3])+(0,0,.12)).tolist()
        row['reasons'].append('Third global rescan exposes another rear rail plane: add0.12courseZ relief while retaining X/Y cap inset.')
result['candidate']='combined-proposal04'
(out/'operations.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps({'candidate':result['candidate'],'operations':len(result['operations'])}))
