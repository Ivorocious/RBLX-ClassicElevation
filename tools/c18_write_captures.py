import sys, base64, io, pathlib
from PIL import Image
prefix = sys.argv[1] if len(sys.argv) > 1 else 'before'
assert prefix.replace('_', '').isalnum()
out = pathlib.Path(r'docs/artifacts/city-run/c18')
out.mkdir(parents=True, exist_ok=True)
for line in sys.stdin:
    line=line.strip()
    if line == 'C18_END': break
    name,data=line.split('|',1)
    Image.open(io.BytesIO(base64.b64decode(data))).save(out / f'{prefix}_{name}.png', format='PNG')
