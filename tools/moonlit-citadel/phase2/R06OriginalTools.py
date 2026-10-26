from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parents[3]
base = root / 'tools/moonlit-citadel/phase2'
output = root / 'docs/artifacts/moonlit-citadel/phase2/revision06/original_tools'
output.mkdir(exist_ok=True)
scope = '''local function isMoonlitStudioScope()
    return game:GetService("RunService"):IsStudio()
        and ((game.PlaceId == 0 and game.GameId == 0)
            or (game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177))
end
assert(isMoonlitStudioScope(), "Authorized Moonlit Studio scope only")
'''
inputs = [
    ('TrialControl.luau', 'ServerStorage/MoonlitPhase2Tools/TrialControl', 'ModuleScript'),
    ('ServerProbe.luau', 'ServerStorage/MoonlitPhase2Tools/ServerProbe', 'ModuleScript'),
    ('R06ClientProbe.luau', 'ReplicatedStorage/MoonlitPhase2Tools/R06ClientProbe', 'ModuleScript'),
    ('R06ClientSuite.luau', 'ReplicatedStorage/MoonlitPhase2Tools/R06ClientSuite', 'ModuleScript'),
    ('R06SnapshotClient.luau', 'ReplicatedStorage/MoonlitPhase2Tools/R06SnapshotClient', 'ModuleScript'),
    ('BootstrapProbe.server.luau', 'ServerScriptService/MoonlitPhase2Probe', 'Script'),
    ('R06Suite.server.luau', 'ServerScriptService/R06SuiteServer', 'Script'),
    ('R06Action.server.luau', 'ServerScriptService/R06Action', 'Script'),
    ('R06Suite.client.luau', 'StarterPlayer/StarterPlayerScripts/R06SuiteClient', 'LocalScript'),
]
rows = []
for name, target, kind in inputs:
    raw = (base / name).read_bytes()
    original = raw.decode('utf-8-sig').replace('\r\n', '\n')
    source, count = re.subn(r'game\.PlaceId\s*==\s*0\s*and\s*game\.GameId\s*==\s*0', 'isMoonlitStudioScope()', original)
    if source.startswith('--!'):
        directive, source = source.split('\n', 1)
        source = directive + '\n' + scope + source
    else:
        source = scope + source
    source = source.replace('Install only in the unpublished owned fixture', 'Install only in the authorized Moonlit Studio scope')
    path = output / name
    assert not path.exists(), 'Preserve previous diagnostic copies'
    path.write_text(source, encoding='utf-8', newline='\n')
    rows.append({'file': str(path.relative_to(root)), 'originalFile': str((base/name).relative_to(root)),
                 'originalSha256': hashlib.sha256(raw).hexdigest(), 'guardReplacements': count,
                 'instancePath': target, 'class': kind, 'source': source,
                 'sha256': hashlib.sha256(source.encode()).hexdigest()})
packet = {'candidate': 'MC_P2_C01_R06', 'kind': 'Temporary authorized original-place Studio diagnostics',
          'placeId': 85558151074819, 'gameId': 10191126818, 'creatorId': 86069177, 'sources': rows}
path = root / 'docs/artifacts/moonlit-citadel/phase2/MC_P2_R06_original_tools01.json'
assert not path.exists(), 'Preserve previous packet'
path.write_text(json.dumps(packet), encoding='utf-8')
print(json.dumps({'path': str(path), 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'sources': len(rows)}))
