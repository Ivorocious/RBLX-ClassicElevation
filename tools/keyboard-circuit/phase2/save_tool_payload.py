import base64
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[3]
allowed = root / 'docs/artifacts/keyboard-circuit/phase2'
request = json.loads(sys.stdin.readline())
if request.pop('chunked', False):
    chunks = []
    for line in sys.stdin:
        if line.strip() == 'END_PAYLOAD':
            break
        chunks.append(line.strip())
    request['data'] = ''.join(chunks)
target = (root / request['path']).resolve()
if not target.is_relative_to(allowed.resolve()):
    raise ValueError('Phase 2 artifact path required')
if request['encoding'] == 'base64':
    content = base64.b64decode(request['data'], validate=True)
elif request['encoding'] == 'hex':
    content = bytes.fromhex(request['data'])
elif request['encoding'] == 'json':
    if isinstance(request['data'], str):
        request['data'] = json.loads(request['data'])
    content = (json.dumps(request['data'], indent=2) + '\n').encode('utf-8')
else:
    raise ValueError('Unsupported encoding')
target.parent.mkdir(parents=True, exist_ok=True)
if target.exists() and target.read_bytes() != content:
    raise FileExistsError('Existing artifact differs; use a fresh receipt name')
target.write_bytes(content)
print(json.dumps({'path': str(target), 'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()}))
