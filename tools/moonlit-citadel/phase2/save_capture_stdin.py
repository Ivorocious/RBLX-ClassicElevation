import base64
import hashlib
import json
import re
import sys
from pathlib import Path

directory = Path(__file__).resolve().parents[3] / 'docs/artifacts/moonlit-citadel/phase2/repairs/MC_P2_C01_R05/views'
directory.mkdir(parents=True, exist_ok=True)
print(json.dumps({'ready': True, 'directory': str(directory)}), flush=True)
for line in sys.stdin:
    try:
        request = json.loads(line)
        name = request['name']
        if not re.fullmatch(r'[A-Za-z0-9_-]+\.(jpg|png)', name):
            raise ValueError('Invalid capture name')
        data = base64.b64decode(request['data'], validate=True)
        if not 0 < len(data) <= 8 * 1024 * 1024:
            raise ValueError('Invalid capture size')
        if not (data.startswith(b'\xff\xd8') or data.startswith(b'\x89PNG\r\n\x1a\n')):
            raise ValueError('Expected original JPEG or PNG bytes')
        path = directory / name
        if path.exists():
            if path.read_bytes() != data:
                raise ValueError('Preserve existing capture')
        else:
            with path.open('xb') as output:
                output.write(data)
        print(json.dumps({'path': str(path), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}), flush=True)
    except Exception as error:
        print(json.dumps({'error': str(error)}), flush=True)
