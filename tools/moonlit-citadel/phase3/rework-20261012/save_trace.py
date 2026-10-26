"""Save bounded Moonlit JSON evidence sent through the owned terminal pipe."""
import hashlib
import json
from pathlib import Path
import re
import sys

directory = Path(__file__).resolve().parents[4] / 'docs/artifacts/moonlit-citadel/phase3/rework-20261012'
name, pieces = None, []
for line in sys.stdin:
    request = json.loads(line)
    if request.get('quit'):
        break
    if 'begin' in request:
        name = request['begin']
        assert re.fullmatch(r'rw10_[a-z0-9_]+\.json', name)
        assert not (directory / name).exists()
        pieces = []
    elif 'chunk' in request:
        assert name and sum(map(len, pieces)) < 12_000_000
        pieces.append(request['chunk'])
    elif request.get('end'):
        raw = ''.join(pieces)
        json.loads(raw)
        data = raw.encode('utf-8')
        with (directory / name).open('xb') as output:
            output.write(data)
        print(json.dumps({'file': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}), flush=True)
        name, pieces = None, []
