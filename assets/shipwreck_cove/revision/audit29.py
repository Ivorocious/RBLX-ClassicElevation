"""Check authored beach drop reach and record the reviewed source fingerprint."""
import hashlib, json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
data=json.loads((Path(__file__).parent/'layout29.json').read_text())
coconuts=[h for h in data['falling'] if h['kind']=='coconut']
samples=[]
for s in data['surfaces']:
    if not s['name'].startswith(('S04_Shore_','ShoreWalk')):continue
    yaw=math.radians(s['yaw']);c,sn=math.cos(yaw),math.sin(yaw)
    for i in range(13):
        for j in range(9):
            x=s['size'][0]*(i/12-.5);z=s['size'][2]*(j/8-.5)
            world=(s['p'][0]+c*x+sn*z,s['p'][2]-sn*x+c*z)
            margin=max(h['spread']+h['radius']-math.dist(world,(h['bottom'][0],h['bottom'][2])) for h in coconuts)
            samples.append(dict(surface=s['name'],point=world,margin=margin))
missing=[s for s in samples if s['margin']<0]
files=list((ROOT/'src/ServerStorage/CourseBuilders/ShipwreckCove').glob('*.luau'))
files += [ROOT/'src/ReplicatedStorage/Config/ShipwreckConfig.luau',ROOT/'src/ReplicatedStorage/Shared/ShipwreckHazards.luau',ROOT/'src/ServerScriptService/Services/CourseService.luau']
hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
result=dict(build='SC29_CANDIDATE_05',coconuts=len(coconuts),samples=len(samples),uncovered=missing,minimumReachMargin=min(s['margin'] for s in samples),method='Two-dimensional possible drop reach only, not observed random hit frequency. Checkpoint refuge and shore entry are excluded.',resource=data['resource'],sourceHashes=hashes)
(ROOT/'docs/artifacts/shipwreck-cove/review29/audit-c05.json').write_text(json.dumps(result,indent=2))
print({k:v for k,v in result.items() if k not in ('sourceHashes','uncovered')})
print('Uncovered samples:',len(missing))
assert not missing, missing[:3]
