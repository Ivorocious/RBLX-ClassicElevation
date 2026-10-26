"""Freeze a self-contained native study installer from a verified asset receipt."""
import argparse
import json
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('folder',type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
m=json.loads((args.folder/'manifest.json').read_text())
bounds=json.loads((args.folder/'export-bounds.json').read_text())
receipt=json.loads((args.folder/'upload-receipt.json').read_text())
assert receipt['state']=='complete' and receipt['sha256']==m['fbxSha256']
spec={k:m[k] for k in ('candidate','meshCount','triangles','fbxSha256','studdedSourceParts')}
spec.update(id=m['candidate'].split('_')[-1],assetId=receipt['assetId'],region=m['regionRobloxXZ'],
            meshes={r['name']:dict(hex=r['hex'],bounds=bounds[r['name']]['bounds']) for r in m['meshes']})
script=(root/'tools/stud-garden-v2/place_phase3_study.luau').read_text()
script=script.replace('__SPEC__',json.dumps(spec,separators=(',',':')))
script=script.replace('__FINGERPRINT__',(root/'tools/stud-garden-v2/Fingerprint.luau').read_text())
(args.folder/'place-study.luau').write_text(script,encoding='utf-8')
print(json.dumps({'installer':str(args.folder/'place-study.luau'),'meshes':m['meshCount']}))
