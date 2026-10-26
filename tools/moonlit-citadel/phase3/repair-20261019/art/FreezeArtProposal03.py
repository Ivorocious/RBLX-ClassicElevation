import hashlib,json
from pathlib import Path

ROOT=Path.cwd();HERE=Path(__file__).resolve().parent;OUT=HERE/'proposal03'
output=OUT/'ART_PROPOSAL03_FREEZE.json'
assert not output.exists()
paths=[p for p in OUT.iterdir() if p.is_file() and p.suffix in ('.json','.luau','.png','.blend','.md')]
paths+=[HERE/name for name in ('PrepareArtProposal.py','PrepareArtProposal03.py','RenderArtProposal.py','RenderArtProposal03.py','CheckArtProposal.luau','CheckArtProposal03.luau','CheckArtInterface03.luau','CheckArtMounts03.py','FreezeArtProposal03.py')]
paths+=[ROOT/'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/combined-plan54.json',
        ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend',
        ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/repair_before_models.rbxm',
        ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json',
        ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01/MC_DETAIL_KIT_DT01.blend',
        ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/r01/final/combined-occupied-geometry.json']
rows=[]
for path in sorted(set(paths)):
    raw=path.read_bytes()
    rows.append({'path':path.relative_to(ROOT).as_posix(),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
for name in ('art-proposal-report.json','focused-clearance.json','interface-check.json','gallery-support-probes.json'):
    assert json.loads((OUT/name).read_text(encoding='utf8'))['pass']
report={'candidate':'MC_ART_REPAIR_20261019_A03','pass':True,'scope':'Frozen offline art proposal only',
        'source54RecoveryBound':True,'protectedVisibleObjects':717,'replacements':56,'retiredUnits':5,
        'actualWorldCost':{'units':315,'meshParts':869,'triangles':271658,'DT01Records':78},
        'protectedReserveVolumes':1604,'occupiedRows':203,'blockingConflicts':0,'headroomConflicts':0,'cameraConflicts':0,'sightConflicts':0,
        'productionEdited':False,'studioTouched':False,'liveBlenderTouched':False,'nativeInstalled':False,
        'files':rows,'fileCount':len(rows),
        'boundary':'Native source/actual surface and temporal moving-camera verification remain root work. Category counts require final integrated recount.'}
output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'path':output.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'files':len(rows)}))
