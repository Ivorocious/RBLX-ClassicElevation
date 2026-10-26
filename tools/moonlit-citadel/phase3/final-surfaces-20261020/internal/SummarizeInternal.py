"""Bind analysis to root's current native receipt and separate exact faces from relief."""
from collections import defaultdict
from pathlib import Path
import hashlib
import json
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p/'default.project.json').exists())
BINDING = ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-binding.json'
binding = json.loads(BINDING.read_text(encoding='utf8'))
assert binding['canonicalSHA256']=='784deaac536a2aaa75bdd53800909c517fd22d83e39349ebb413dea9c3204dcd'
assert binding['visibleCanonicalSHA256']=='137111fc79d078309b1484ea735db2837ec4ca989bf8e12f5d9692c92bb33516'
j = json.loads((HERE/'internal-visible56.json').read_text(encoding='utf8'))
objects = json.loads((HERE/'surface-objects56.json').read_text(encoding='utf8'))['objects']
triangles = np.load(HERE/'surface-triangles56.npz')['triangles']
families = defaultdict(list)
for row in j['pairs']:
    if not row['finiteVisible'] or not row['samePart']:
        continue
    witness = min(row['visibleWitnesses'],key=lambda w:w['faceWitness']['gap'])
    a,b = (triangles[i] for i in witness['faceWitness']['triangleIndices'])
    equality = float(max(min(np.linalg.norm(q-v)for v in b)for q in a))
    obj = objects[row['a']]
    families[obj['asset']].append({'path':row['paths'][0],'minimumVisibleGap':witness['faceWitness']['gap'],
        'maximumVisibleGap':max(w['faceWitness']['gap']for w in row['visibleWitnesses']),
        'positiveProjectedOverlapArea':witness['faceWitness']['area'],'faces':witness['faceWitness']['faces'],
        'triangleIndices':witness['faceWitness']['triangleIndices'],'triangles':[a.tolist(),b.tolist()],
        'sameTriangleVerticesTolerance':equality,'sourceMeshId':obj['meshId'],'flags':obj['flags'],'witness':witness})
report = {'scope':'Source56 fresh supported-eye exposed self-part triangle overlaps; geometric face normals and polygon IDs only',
    'nativeBinding':binding,'nativeBindingFileSHA256':hashlib.sha256(BINDING.read_bytes()).hexdigest(),
    'uvAndCustomNormalsAvailable':False,'nativeTemporalFlashingProven':False,'families':[],
    'exactVisibleParts':0,'closeNonCoincidentVisibleParts':0}
for asset,rows in sorted(families.items()):
    exact = [r for r in rows if r['minimumVisibleGap']<.0005]
    near = [r for r in rows if r['minimumVisibleGap']>=.0005]
    report['exactVisibleParts']+=len(exact)
    report['closeNonCoincidentVisibleParts']+=len(near)
    report['families'].append({'asset':asset,'parts':len(rows),'exactParts':len(exact),'closeNonCoincidentParts':len(near),
        'minimumVisibleGap':min(r['minimumVisibleGap']for r in rows),'maximumVisibleGap':max(r['maximumVisibleGap']for r in rows),
        'exactTriangleDuplicates':sum(r['sameTriangleVerticesTolerance']<.0005 for r in exact),
        'assessment':('Distinct authored polygons positively overlap with same geometric normal. These are not shared triangle edges. Translation or scale of the complete material part preserves exact coincidences; remove duplicate polygon area by plane union/subtraction while retaining exterior silhouette.' if exact else
        'Nonzero authored relief, bevel or leaf spacing. These are not coincident triangles. A close geometric candidate alone does not prove a defect; keep intended relief unless a moving view shows instability.'),
        'rows':rows})
(HERE/'self-surface-assessment56.json').write_text(json.dumps(report,indent=2,default=lambda v:v.item()if isinstance(v,np.generic)else str(v))+'\n',encoding='utf8')
for folder in (HERE,HERE/'proposal01',HERE/'proposal02',HERE/'proposal03'):
    for name in ('surface-objects56.json','internal-candidates56.json','internal-visible56.json'):
        p=folder/name
        if not p.exists():continue
        data=json.loads(p.read_text(encoding='utf8'))
        data['live56ParityPending']=False
        data['live56Binding']=binding
        data['live56BindingPath']=str(BINDING.relative_to(ROOT))
        p.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in report.items()if k not in('families','nativeBinding')},indent=2))
print(json.dumps([(f['asset'],f['parts'],f['exactParts'],f['exactTriangleDuplicates'])for f in report['families']]))
