"""Apply a staged manifest to reconstructed actual triangles and rescan new neighbors."""
import json
import os
from pathlib import Path
import sys
import numpy as np
import ScanNeighbors as scan

BASE=Path(__file__).resolve().parent
OUT=BASE/sys.argv[1]
DATA=BASE/sys.argv[2]if len(sys.argv)>2 else BASE
manifest=json.loads((OUT/'operations.json').read_text(encoding='utf8'))
meta=json.loads((DATA/'current56-objects.json').read_text(encoding='utf8'))
npz=np.load(DATA/'current56-triangles.npz');triangles,owners,faces=npz['triangles'],npz['owners'],npz['faces']
objects=meta['objects'];mapping={o['nativePath']:o for o in objects}
ops=manifest['operations'];seen=set()
for op in ops:
    assert op['path']not in seen,op['path'];seen.add(op['path'])
    obj=mapping[op['path']];selected=owners==obj['index']
    before,after=np.array(op['beforeCFrame']),np.array(op['afterCFrame']);r=before[3:].reshape(3,3);t=after[3:].reshape(3,3)
    points=triangles[selected]
    local=(points+scan.ORIGIN-before[:3])@r
    points=(local/op['beforeSize']*op['afterSize'])@t.T+after[:3]-scan.ORIGIN
    triangles[selected]=points
    obj['bounds']=[points.min(axis=(0,1)).tolist(),points.max(axis=(0,1)).tolist()]
np.savez_compressed(OUT/'current56-triangles.npz',triangles=triangles,owners=owners,faces=faces)
(OUT/'current56-objects.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf8')
scan.OWN=OUT
scan.scan(objects,triangles,owners,faces)
