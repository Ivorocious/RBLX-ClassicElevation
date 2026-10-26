"""Test guarded twelve-part within-asset corrections against fresh current geometry."""
from pathlib import Path
import json
import copy
import sys
import numpy as np
import RescanInternal as scanner

HERE = Path(__file__).resolve().parent
version = sys.argv[1] if len(sys.argv)>1 else 'proposal01'
OUT = HERE / version
OUT.mkdir(exist_ok=True)
meta = json.loads((HERE/'surface-objects56.json').read_text(encoding='utf8'))
objects = meta['objects']
data = np.load(HERE/'surface-triangles56.npz')
triangles, owners, faces = data['triangles'].copy(), data['owners'], data['faces']
ops = []
for row in objects:
    p = row['path']
    delta, shift, reason = np.zeros(3), np.zeros(3), None
    if row['asset']=='MC_TL_SteppedButtress' and row['material']=='Stone' and 'GrandKeep/' in p:
        delta[0] = -.16
        if version in ('proposal02','proposal03'):
            delta[1:] = -.24
        if version == 'proposal03':
            delta[2] = -.48
        reason = 'Inset four coincident stepped buttress body side faces beneath trim'
    elif '/NorthEastRaisedCourt/' in p and row['material']=='Slate':
        delta[2] = -.16
        reason = 'Recess the court slate end faces from coincident stone ledge faces'
    elif row['asset']=='MC_AR_GalleryRoof46' and row['material']=='SlateBand' and 'Junction' in p:
        shift[0] = .08
        reason = 'Increase the roof band relief after existing +0.06 course X correction'
    elif row['asset']=='MC_WindowFrame' and row['material']=='Stone' and ('GalleryInteriorQuietLancet'in p or 'UpperKeepWarmLancet'in p):
        delta[1] = -.16
        reason = 'Recess small-scale window cap-return substrate above the dark sill'
    if reason is None:
        continue
    assert row['flags']['CanCollide'] is False and row['flags']['CanQuery'] is False and row['flags']['CanTouch'] is False
    before_size, cf = np.array(row['size']), np.array(row['cframe'])
    after_size = before_size+delta
    assert np.all(after_size>.001)
    idx = np.flatnonzero(owners==row['index'])
    relative = (triangles[idx]+scanner.ORIGIN-cf[:3])@cf[3:].reshape(3,3)
    triangles[idx] = (relative/before_size*after_size)@cf[3:].reshape(3,3).T+cf[:3]-scanner.ORIGIN+shift
    ops.append({'path':p,'asset':row['asset'],'material':row['material'],'reason':reason,
                'nativeSizeBefore':before_size.tolist(),'nativeSizeAfter':after_size.tolist(),
                'nativeCFrameBefore':cf.tolist(),'nativeCFrameAfter':(np.r_[cf[:3]+shift,cf[3:]]).tolist(),
                'nativeSizeDelta':delta.tolist(),'coursePositionDelta':shift.tolist(),
                'meshIdUnchanged':row['meshId'],'flagsUnchanged':row['flags']})
    row['size'] = after_size.tolist()
    row['cframe'][:3] = (cf[:3]+shift).tolist()
assert len(ops)==12,len(ops)
np.savez_compressed(OUT/'surface-triangles56.npz',triangles=triangles,owners=owners,faces=faces)
(OUT/'surface-objects56.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf8')
(OUT/'operations.json').write_text(json.dumps({'scope':'Twelve additional physical visual-only corrections relative to Source56; no production/native changes','operations':ops,'productionChanged':False,'studioTouched':False},indent=2)+'\n',encoding='utf8')
scanner.HERE=OUT
scanner.scan(objects,triangles,owners,faces)
