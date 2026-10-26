"""Save original Studio capture bytes delivered over this owned pipe."""
import base64
import hashlib
import json
from pathlib import Path
import re
import sys

if sys.platform == 'win32':
    import ctypes
    handle = ctypes.windll.kernel32.GetStdHandle(-10)
    mode = ctypes.c_ulong()
    if ctypes.windll.kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
        ctypes.windll.kernel32.SetConsoleMode(handle, mode.value & ~4)

directory = Path(__file__).resolve().parents[4] / 'docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/views'
directory.mkdir(parents=True, exist_ok=True)
print(json.dumps({'ready': True, 'directory': str(directory)}), flush=True)
pieces, pending_name = [], None
for line in sys.stdin:
    try:
        request = json.loads(line)
        if request.get('quit'):
            break
        if 'begin' in request:
            pieces, pending_name = [], request['begin']
            continue
        if 'chunk' in request:
            pieces.append(request['chunk'])
            continue
        if request.get('end'):
            request = {'name': pending_name, 'data': ''.join(pieces)}
        name = request['name']
        if not re.fullmatch(r'[a-z0-9_-]+\.(jpg|png)', name):
            raise ValueError('Invalid capture name')
        data = base64.b64decode(request['data'], validate=True)
        if not 0 < len(data) <= 8_000_000 or not (data.startswith(b'\xff\xd8') or data.startswith(b'\x89PNG\r\n\x1a\n')):
            raise ValueError('Invalid image bytes')
        target = directory / name
        with target.open('xb') as output:
            output.write(data)
        print(json.dumps({'path': str(target), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}), flush=True)
        pieces, pending_name = [], None
    except Exception as error:
        print(json.dumps({'error': str(error)}), flush=True)
