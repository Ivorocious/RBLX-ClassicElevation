import sys,json,hashlib
from pathlib import Path
r=json.loads(sys.stdin.readline())
p=Path('docs/artifacts/city-run/c18')/r['name']
assert p.parent==Path('docs/artifacts/city-run/c18') and p.suffix in ['.json','.txt']
b=r['data'].encode('utf-8');p.write_bytes(b)
print(json.dumps({'file':str(p),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}),flush=True)
