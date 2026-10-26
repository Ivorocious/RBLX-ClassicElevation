"""Receive base64 lines from the agent tool channel and write a native model."""
from pathlib import Path
import sys,base64,hashlib,ctypes,json
p=Path(sys.argv[1]).resolve()
root=Path(__file__).resolve().parents[1]
assert root in p.parents and not p.exists()
try:
 k=ctypes.windll.kernel32;h=k.GetStdHandle(-10);m=ctypes.c_ulong()
 if k.GetConsoleMode(h,ctypes.byref(m)):k.SetConsoleMode(h,m.value & ~4)
except Exception:pass
p.parent.mkdir(parents=True,exist_ok=True)
print('READY',flush=True)
with p.open('wb') as f:
 for line in sys.stdin:
  line=line.strip()
  if line=='END':break
  if line:f.write(base64.b64decode(line,validate=True))
b=p.read_bytes();assert b.startswith(b'<roblox!')
print(json.dumps({'file':str(p),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}),flush=True)
