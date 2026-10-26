import sys,json,base64
from pathlib import Path
root=Path('docs/artifacts/city-run/c16')
root.mkdir(parents=True,exist_ok=True)
for line in sys.stdin:
 r=json.loads(line);name=r['name']
 if '/' in name or '\\' in name or name.startswith('.'):raise ValueError('Invalid name')
 data=base64.b64decode(r['data'])
 p=root/name
 if p.exists() and p.read_bytes()!=data:raise ValueError('Different existing file')
 p.write_bytes(data);print(json.dumps({'saved':str(p.resolve()),'bytes':len(data)}),flush=True)
