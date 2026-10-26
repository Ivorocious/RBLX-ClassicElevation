import sys,json,base64,ctypes
from pathlib import Path
root=Path('docs/artifacts/city-run/v3/final03');root.mkdir(parents=True,exist_ok=True)
k=ctypes.windll.kernel32;h=k.GetStdHandle(-10);m=ctypes.c_ulong()
if k.GetConsoleMode(h,ctypes.byref(m)):k.SetConsoleMode(h,m.value & ~4)
print('READY',flush=True)
for line in sys.stdin:
 if line.strip()=='END':break
 r=json.loads(line);p=root/r['name'];p.write_bytes(base64.b64decode(r['data']));print(str(p),flush=True)
