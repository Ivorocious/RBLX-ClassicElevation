"""Save tool-returned native captures without putting image bytes in shell code."""
import base64
import argparse
import ctypes
import hashlib
import json
import sys
from pathlib import Path

root=Path(__file__).resolve().parents[3]
parser=argparse.ArgumentParser()
parser.add_argument('--directory',default='docs/artifacts/stud-garden-v2/closing-20261005/calibration/native')
args=parser.parse_args()
output=(root/args.directory).resolve()
assert output.is_relative_to(root)
output.mkdir(parents=True,exist_ok=True)
try:
    kernel=ctypes.windll.kernel32
    handle=kernel.GetStdHandle(-10)
    mode=ctypes.c_ulong()
    if kernel.GetConsoleMode(handle,ctypes.byref(mode)):
        kernel.SetConsoleMode(handle,mode.value & ~4)
except Exception:
    pass
print('READY',flush=True)
for line in sys.stdin:
    if line.strip()=='END':
        break
    record=json.loads(line)
    name=record['name']
    assert Path(name).name==name and name.endswith('.jpg')
    data=base64.b64decode(record['data'],validate=True)
    assert data.startswith(b'\xff\xd8')
    path=output/name
    assert not path.exists() or path.read_bytes()==data
    path.write_bytes(data)
    print(json.dumps({'file':str(path),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}),flush=True)
