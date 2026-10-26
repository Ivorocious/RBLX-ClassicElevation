"""Focused layout invariants; these do not replace Studio movement tests."""
import json, math
from pathlib import Path
r=Path(__file__).resolve().parent;d=json.loads((r/'layout28.json').read_text())
s={p['name']:p for p in d['surfaces']}
errors=[]
for a,b in d['links']:
    if a not in s or b not in s:errors.append(['missing link',a,b])
assert not errors,errors
assert len(d['checkpoints'])==6
assert not d['signs']
assert not any(h['section']=='S04_Shore' for h in d['hazards'])
assert len(d['surges'])==2
assert not any(h['kind']=='stalactite' and h['top'][0]<100 for h in d['falling'])
coverage=[]
for shot in d['shots']:
    start,end=shot['start'],shot['finish'];arc=shot['arcHeight']
    slope=(end[1]-start[1]+4*arc)/abs(end[0]-start[0])
    assert abs(math.degrees(math.atan(slope))-35)<.01
    row=[]
    for name,p in s.items():
        if name.startswith(('BatteryCluster','BatteryDeck')) and abs(p['p'][2]-start[2])<3:
            t=(p['p'][0]-start[0])/(end[0]-start[0])
            y=start[1]+(end[1]-start[1])*t+4*arc*t*(1-t)
            row.append(dict(platform=name,heightAboveLanding=round(y-p['p'][1],3)))
    coverage.append(dict(shot=shot['name'],elevation=35,platforms=row))
out=dict(build=d['build'],resource=d['resource'],checkpointCount=5,falling=len(d['falling']),shots=coverage,
         caveArrowPolicy='No arrows on S04_Entry/Cave surfaces',claims='Analytic layout checks only; real contact and jump tests still required')
(r/'checks28.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
