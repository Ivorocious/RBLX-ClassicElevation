"""Receive bounded screenshot chunks on stdin and save original image bytes."""
import base64
import hashlib
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[4] / 'docs/artifacts/moonlit-citadel/phase3/repair-20261019/final'
chunks = {}
for line in sys.stdin:
    row = json.loads(line)
    if row.get('quit'):
        break
    name = row['name']
    assert re.fullmatch(r'native55-[a-z0-9-]+\.jpg', name)
    chunks.setdefault(name, []).append(row['chunk'])
    assert sum(map(len, chunks[name])) < 3_000_000
    if row.get('last'):
        data = base64.b64decode(''.join(chunks.pop(name)), validate=True)
        target = root / name
        if target.exists():
            assert target.read_bytes() == data
        else:
            target.write_bytes(data)
        print(json.dumps({'name': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}), flush=True)
