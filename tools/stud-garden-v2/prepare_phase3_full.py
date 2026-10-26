"""Freeze the full art installer; the original course is only read and cloned."""
import argparse
import hashlib
import json
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('folder',type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
m=json.loads((args.folder/'manifest.json').read_text())
c=json.loads((args.folder/'collision.json').read_text())
a=json.loads((args.folder/'static-art-audit.json').read_text())
receipt=json.loads((args.folder/'upload-receipt.json').read_text())
assert receipt['state']=='complete' and receipt['sha256']==m['fbxSha256']
assert not any(a[k] for k in ('bodyIntrusions','existingVisibleOverlaps','potentialInboundScenery'))
spec={k:m[k] for k in ('candidate','meshCount','triangles','fbxSha256','studdedSourceParts','rootSkins')}
spec.update(id=m['candidate'].split('_')[-1],assetId=receipt['assetId'],target=[10900,80,3500],
    meshes={r['name']:dict(hex=r['hex'],bounds=r['exportBoundsRoblox']) for r in m['meshes']},
    colliders=c['colliders'],collisionSha256=hashlib.sha256((args.folder/'collision.json').read_bytes()).hexdigest())
script=(root/'tools/stud-garden-v2/place_phase3_full.luau').read_text()
script=script.replace('__SPEC__',json.dumps(spec,separators=(',',':')))
script=script.replace('__FINGERPRINT__',(root/'tools/stud-garden-v2/Fingerprint.luau').read_text())
(args.folder/'place-full.luau').write_text(script,encoding='utf-8')
for name in ('prepare_phase3_full.py','place_phase3_full.luau','prepare_phase3_collision.py','audit_phase3_art.py'):
    (args.folder/'source'/name).write_bytes((root/'tools/stud-garden-v2'/name).read_bytes())
print(json.dumps({'installerBytes':len(script.encode()),'meshes':m['meshCount'],'colliders':c['count']}))
