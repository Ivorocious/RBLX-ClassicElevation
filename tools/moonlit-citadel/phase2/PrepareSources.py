from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parents[3]
candidate = sys.argv[1]
assert candidate.startswith('MC_P2_') and all(c.isalnum() or c == '_' for c in candidate)
rows = []

def add(instance_path, source_path, class_name='ModuleScript'):
    path = root / source_path
    rows.append({'path': instance_path, 'file': source_path, 'className': class_name,
                 'source': path.read_text(encoding='utf-8-sig'),
                 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})

add('game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig', 'src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau')
for name in ('Layout', 'RouteBuilder', 'Runtime'):
    add('game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.' + name,
        'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/' + name + '.luau')
for name in ('MoonlitCitadelService', 'RespawnService'):
    add('game.ServerScriptService.Services.' + name, 'src/ServerScriptService/Services/' + name + '.luau')
add('game.ServerScriptService.Main', 'src/ServerScriptService/Main.server.luau', 'Script')
for name in ('Onboarding', 'Tournament', 'StudioFlight'):
    add('game.StarterPlayer.StarterPlayerScripts.' + name, 'src/StarterPlayer/StarterPlayerScripts/' + name + '.client.luau', 'LocalScript')
for name in ('ServerProbe', 'CapacityCheck', 'ContactCases', 'TrialControl', 'CapacityCases', 'BoundaryCases', 'PrivateResetCase'):
    path = 'tools/moonlit-citadel/phase2/' + name + '.luau'
    if (root / path).is_file():
        add('game.ServerStorage.MoonlitPhase2Tools.' + name, path)
add('game.ReplicatedStorage.MoonlitPhase2Tools.ClientProbe', 'tools/moonlit-citadel/phase2/ClientProbe.luau')
add('game.ReplicatedStorage.MoonlitPhase2Tools.ClientSuite', 'tools/moonlit-citadel/phase2/ClientSuite.luau')
add('game.ReplicatedStorage.MoonlitPhase2Tools.ContactCases', 'tools/moonlit-citadel/phase2/ContactCases.luau')
add('game.ReplicatedStorage.MoonlitPhase2Tools.BoundaryCases', 'tools/moonlit-citadel/phase2/BoundaryCases.luau')
add('game.ReplicatedStorage.MoonlitPhase2Tools.PrivateResetCase', 'tools/moonlit-citadel/phase2/PrivateResetCase.luau')
add('game.ServerScriptService.MoonlitPhase2Probe', 'tools/moonlit-citadel/phase2/BootstrapProbe.server.luau', 'Script')
output = root / 'docs/artifacts/moonlit-citadel/phase2' / (candidate + '_source_update.json')
assert not output.exists(), 'Keep earlier source receipts'
output.write_text(json.dumps({'candidate': candidate, 'sources': rows}, ensure_ascii=True), encoding='utf-8')
print(json.dumps({'output': str(output), 'sources': len(rows), 'bytes': output.stat().st_size}))
