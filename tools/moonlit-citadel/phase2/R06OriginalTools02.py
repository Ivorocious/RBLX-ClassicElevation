from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[3]
base = root / 'docs/artifacts/moonlit-citadel/phase2'
previous = json.loads((base / 'MC_P2_R06_original_tools01.json').read_text())
output = base / 'revision06/original_tools02'
output.mkdir(exist_ok=True)
rows = []
for row in previous['sources']:
    row = dict(row)
    row['previousSha256'] = row['sha256']
    source = row['source']
    if row['instancePath'].endswith('/R06ClientSuite'):
        source = source.replace('local Suite = {}', 'local Gate = require(script.Parent.R06ArrivalGate)\nlocal Suite = {}')
        old = 'assert(player:GetAttribute("ArrivalOpen") == false, "Complete the actual lobby arrival before the race")'
        assert source.count(old)==1
        source = source.replace(old, 'local allowed, arrivalScope = Gate.Check(player, options.arrivalDiagnosticReceipt)\n\t\t\tassert(allowed, "Actual arrival incomplete or diagnostic-only scope unavailable")')
        source = source.replace('Probe.Start(course, packet.nodes, settings)', 'Probe.Start(course, packet.nodes, settings)\n\t\t\tProbe.Current().arrivalScope = arrivalScope')
        source = source.replace('local result = Probe.Current()', 'local result = Probe.Current()\n\t\t\t\tif result.state=="Complete" or result.state=="Failed" then result.arrivalScope.ended=Gate.Capture(player) end')
        source = source.replace('latest = report', 'report.arrivalDiagnosticReceipt=options.arrivalDiagnosticReceipt\n\tlatest = report')
    if row['instancePath'].endswith('/R06SuiteClient'):
        source = source.replace('local player = Players.LocalPlayer', 'local Gate = require(tools.R06ArrivalGate)\nlocal player = Players.LocalPlayer\nlocal arrivalDiagnosticReceipt="Original07BlockedArrival01"')
        old = 'and player:GetAttribute("ArrivalOpen") == false'
        assert source.count(old)==1
        source = source.replace(old, 'and Gate.Check(player, arrivalDiagnosticReceipt)')
        source = source.replace('goalTolerance = .25})', 'goalTolerance = .25, arrivalDiagnosticReceipt=arrivalDiagnosticReceipt})')
    row['source'] = source
    row['sha256'] = hashlib.sha256(source.encode()).hexdigest()
    path = output / Path(row['file']).name
    assert not path.exists()
    path.write_text(source, encoding='utf-8', newline='\n')
    row['file'] = str(path.relative_to(root))
    rows.append(row)
for name, target, kind in [
    ('R06ArrivalScope.server.luau','ServerScriptService/R06ArrivalScope','Script'),
    ('R06ArrivalGate.luau','ReplicatedStorage/MoonlitPhase2Tools/R06ArrivalGate','ModuleScript'),
]:
    path = root / 'tools/moonlit-citadel/phase2' / name
    source = path.read_text(encoding='utf-8')
    rows.append({'file': str(path.relative_to(root)), 'instancePath':target, 'class':kind,
                 'source':source,'sha256':hashlib.sha256(source.encode()).hexdigest()})
packet = {**{k:v for k,v in previous.items() if k!='sources'}, 'sources':rows,
          'kind':'Temporary course-only diagnostics after separately recorded actual arrival-preload failure',
          'limits':'Arrival/input/UI/camera/audio usability excluded; no arrival attribute/UI/control writes; all course race/body/finish guards retained.'}
path = base / 'MC_P2_R06_original_tools02.json'
assert not path.exists()
path.write_text(json.dumps(packet),encoding='utf-8')
print(json.dumps({'path':str(path),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'sources':len(rows)}))
