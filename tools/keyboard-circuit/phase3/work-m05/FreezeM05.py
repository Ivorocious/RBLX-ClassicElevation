from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
work = root / 'tools/keyboard-circuit/phase3/work-m05'
artifacts = root / 'docs/artifacts/keyboard-circuit/phase3'
paths = set(work.rglob('*.luau'))
paths.update([work / 'PrepareInstall.py', work / 'FreezeM05.py', work / 'InstallPacket.json', work / 'client-lifecycle-result.json'])
paths.update(path for path in artifacts.glob('P3-M05-*.json') if 'CANDIDATE-FREEZE' not in path.name and 'FINAL-GATE' not in path.name)
paths.update((artifacts / 'm05-recovery').glob('*'))
paths.update([artifacts / 'KC_P3_M05_01_Native.rbxm', artifacts / 'P3-M05-REVIEW-BRIEF-01.md', root / 'default.project.json'])
for relative in [
    'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuit.client.luau',
    'src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau',
    'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPreview.meta.json',
    'src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau',
    'src/StarterPlayer/StarterPlayerScripts/Controllers/LobbyUiController.luau',
    'src/StarterPlayer/StarterPlayerScripts/Controllers/RaceUiController.luau',
    'src/ServerScriptService/Main.server.luau',
    'src/ReplicatedStorage/Shared/RaceConstants.luau',
    'src/ReplicatedStorage/Shared/RaceTypes.luau',
]:
    paths.add(root / relative)
for name in ['StudioDevService', 'CourseService', 'CheckpointService', 'RespawnService', 'RaceService', 'PlayerRaceService', 'ResultsService', 'CourseHazardService', 'CourseMotionService', 'LobbyService']:
    paths.add(root / 'src/ServerScriptService/Services' / (name + '.luau'))
for name in ['RaceConfig', 'CourseConfig', 'CheckpointConfig', 'HazardConfig', 'LobbyConfig']:
    paths.add(root / 'src/ReplicatedStorage/Config' / (name + '.luau'))
rows = []
for path in sorted(paths):
    if not path.is_file():
        continue
    data = path.read_bytes()
    rows.append({'path': path.relative_to(root).as_posix(), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
candidate = {'revision': 'KC_P3_M05_01', 'scope': 'Brighter/Neon presentation, standard shared race/UI, approved recoverable history cleanup', 'inputs': rows}
output = artifacts / 'P3-M05-CANDIDATE-FREEZE-01.json'
data = (json.dumps(candidate, indent=2) + '\n').encode('utf-8')
output.write_bytes(data)
print(json.dumps({'inputs': len(rows), 'freezeSha256': hashlib.sha256(data).hexdigest()}))
