from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
work = root / 'tools/keyboard-circuit/phase3/work-m06'
artifacts = root / 'docs/artifacts/keyboard-circuit/phase3'
paths = set(work.glob('*.luau')) | {work / 'P3-M06-checkpoint-probe-01.json', work / 'FreezeM06.py'}
paths.update(path for path in artifacts.glob('P3-M06-*.json') if 'CANDIDATE-FREEZE' not in path.name and 'FINAL-GATE' not in path.name)
paths.update([artifacts / 'P3-M06-REVIEW-BRIEF-01.md', artifacts / 'M06-before-checkpoint-fix.rbxm', artifacts / 'KC_P3_M06_01_Native.rbxm', root / 'tools/keyboard-circuit/phase3/work-m05/InstallPacket.json'])
for relative in [
    'src/ServerScriptService/Services/CheckpointService.luau',
    'src/ServerScriptService/Services/CourseService.luau',
    'src/ServerScriptService/Services/RespawnService.luau',
    'src/ServerScriptService/Services/StudioDevService.luau',
    'src/ServerScriptService/Services/ResultsService.luau',
    'src/ReplicatedStorage/Shared/ForwardGate.luau',
    'src/ReplicatedStorage/Shared/RaceConstants.luau',
    'src/ReplicatedStorage/Config/CheckpointConfig.luau',
    'src/ReplicatedStorage/Config/CourseConfig.luau',
    'src/ReplicatedStorage/Config/RaceConfig.luau',
    'src/StarterPlayer/StarterPlayerScripts/Controllers/RaceUiController.luau',
]:
    paths.add(root / relative)
rows = []
for path in sorted(paths):
    data = path.read_bytes()
    rows.append({'path': path.relative_to(root).as_posix(), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
output = artifacts / 'P3-M06-CANDIDATE-FREEZE-01.json'
data = (json.dumps({'revision': 'KC_P3_M06_01', 'scope': 'Expert alternate checkpoint recognition with unchanged shared validation and original course', 'inputs': rows}, indent=2) + '\n').encode('utf-8')
output.write_bytes(data)
print(json.dumps({'inputs': len(rows), 'freezeSha256': hashlib.sha256(data).hexdigest()}))
