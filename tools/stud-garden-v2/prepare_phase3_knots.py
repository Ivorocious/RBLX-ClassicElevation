"""Freeze an installer only after the approved knot upload has completed."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/artifacts/stud-garden-v2/phase3/f04'
manifest=json.loads((OUT/'manifest.json').read_text())
receipt=json.loads((OUT/'upload-receipt.json').read_text())
assert receipt['state']=='complete' and receipt['sha256']==manifest['fbxSha256']
spec=dict(manifest,assetId=receipt['assetId'])
code=(ROOT/'tools/stud-garden-v2/place_phase3_knots.luau').read_text()
code=code.replace('__SPEC__',json.dumps(spec,separators=(',',':')))
code=code.replace('__FINGERPRINT__',(ROOT/'tools/stud-garden-v2/Fingerprint.luau').read_text())
(OUT/'place-knots.luau').write_text(code)
for name in ('prepare_phase3_knots.py','place_phase3_knots.luau','Fingerprint.luau'):
    (OUT/'source'/name).write_bytes((ROOT/'tools/stud-garden-v2'/name).read_bytes())
print(json.dumps(dict(bytes=len(code.encode()),assetId=receipt['assetId'])))
