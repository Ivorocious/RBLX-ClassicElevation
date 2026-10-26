"""Recheck all within-unit triangles after the complete frozen136-part pose manifest."""
from pathlib import Path
import hashlib
import json
import numpy as np
import RescanInternal as scanner

HERE=Path(__file__).resolve().parent
MANIFEST=HERE.parent/'neighbors/FINAL_POSE136.json'
assert hashlib.sha256(MANIFEST.read_bytes()).hexdigest()=='0f5c0e39cccfc4135ea4217ab82f40681db3136220325c774df7089ffba771b9'
ops=json.loads(MANIFEST.read_text(encoding='utf8'))['operations']
meta=json.loads((HERE/'surface-objects56.json').read_text(encoding='utf8'))
data=np.load(HERE/'surface-triangles56.npz')
triangles,owners,faces=data['triangles'].copy(),data['owners'],data['faces']
objects=meta['objects'];by_path={r['path']:r for r in objects};changed=[]
for op in ops:
    row=by_path[op['path']]
    before_cf=np.array(op['beforeCFrame']);after_cf=np.array(op['afterCFrame'])
    before_size=np.array(op['beforeSize']);after_size=np.array(op['afterSize'])
    assert np.max(abs(before_cf-np.array(row['cframe'])))<.00001,row['path']
    assert np.max(abs(before_size-np.array(row['size'])))<.00001,row['path']
    idx=np.flatnonzero(owners==row['index'])
    local=(triangles[idx]+scanner.ORIGIN-before_cf[:3])@before_cf[3:].reshape(3,3)
    triangles[idx]=(local/before_size*after_size)@after_cf[3:].reshape(3,3).T+after_cf[:3]-scanner.ORIGIN
    row['cframe']=after_cf.tolist();row['size']=after_size.tolist();changed.append(row['index'])
assert len(changed)==136
meta['changedIndices']=changed
meta['poseManifestSHA256']=hashlib.sha256(MANIFEST.read_bytes()).hexdigest()
out=HERE/'combined136';out.mkdir(exist_ok=True)
(out/'surface-objects56.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf8')
np.savez_compressed(out/'surface-triangles56.npz',triangles=triangles,owners=owners,faces=faces)
scanner.HERE=out
scanner.scan(objects,triangles,owners,faces)
