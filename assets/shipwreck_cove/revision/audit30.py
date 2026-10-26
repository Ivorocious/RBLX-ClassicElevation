"""Record scope, resource cost, and the exact source used by the reviewers."""
import hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
revision=Path(__file__).parent
old=json.loads((revision/'layout29.json').read_text())
new=json.loads((revision/'layout30.json').read_text())
for field in ('origin','falling','surges','shots','hazards','checkpoints','gate','arrowSurfaces'):
    assert old.get(field)==new.get(field),f'Unexpected out-of-scope change: {field}'
names=[p['name'] for p in new['surfaces']]
assert len(names)==len(set(names))
for a,b in new['links']:
    assert a in names and b in names,(a,b)
ocean=[p for p in new['placements'] if p.get('ocean')]
for p in ocean:
    assert 0<=p['ocean']['amplitude']<=.2
    assert p['p'][1]+p['ocean']['amplitude']< -1.5
oldp={p['section']+'/'+p['name']:p for p in old['placements']}
newp={p['section']+'/'+p['name']:p for p in new['placements']}
changed=[k for k,p in newp.items() if oldp.get(k)!=p]
removed=sorted(set(oldp)-set(newp))
files=list((ROOT/'src/ServerStorage/CourseBuilders/ShipwreckCove').glob('*.luau'))
files += [ROOT/'src/StarterPlayer/StarterPlayerScripts/ShipwreckOcean.client.luau',ROOT/'src/ReplicatedStorage/Config/ShipwreckConfig.luau']
result=dict(build='SC30_CANDIDATE_04',resource=new['resource'],oceanPieces=len(ocean),
    changedPlacements=changed,removedPlacements=removed,
    unchangedHazardAndCheckpointDefinitions=True,
    sourceHashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)})
out=ROOT/'docs/artifacts/shipwreck-cove/review30';out.mkdir(parents=True,exist_ok=True)
(out/'source-audit.json').write_text(json.dumps(result,indent=2))
print({k:v for k,v in result.items() if k not in ('sourceHashes','changedPlacements','removedPlacements')})
print('Changed placements',len(changed),'Removed',len(removed))
