from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
WORK = Path(__file__).resolve().parent
FOLDER = ROOT / 'docs/artifacts/keyboard-circuit/phase3'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

files = set((WORK / 'sources').glob('*.luau'))
for suffix in ['*.luau', '*.py', '*.cjs']:
    files.update(WORK.glob(suffix))
files.discard(WORK / 'FinalizeGate.py')
files.add(WORK / 'ClackyView.json')
for name in ['StudioDevService.luau', 'StudioDevController.luau', 'KeyboardCircuitPhase2Preview.client.luau', 'COURSE_BRIEF.md']:
    files.add(FOLDER / 'history' / name)
for name in ['src/ServerScriptService/Services/StudioDevService.luau',
             'src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau',
             'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau',
             'docs/artifacts/keyboard-circuit/PHASE3_START.md', 'docs/COURSE_WORKFLOW_V3.md',
             'tools/stud-garden-v2/closing/render_saved_views.py']:
    files.add(ROOT / name)
files.update((ROOT / 'assets/keyboard_circuit/K02').glob('*'))
for path in FOLDER.glob('P3-M01-*'):
    if path.is_file() and path.suffix in ['.json', '.md'] and not any(s in path.name for s in ['source-freeze', 'freeze-agreement', 'FINAL-GATE', 'FINAL-REPORT', 'post-review']):
        files.add(path)
files.add(FOLDER / 'KC_P3_M01_01_Offline.blend')
files.update((FOLDER / 'views').glob('*'))
files.update((FOLDER / 'native').glob('*'))
for name in ['phase3-a-v06.png', 'phase3-b-v01.png', 'phase3-c-v01.png', 'phase3-d-v02.png', 'keyboard-circuit.drawio']:
    path = ROOT / 'docs/artifacts/keyboard-circuit' / name
    if path.suffix == '.png':
        path = path.parent / 'images' / path.name
    files.add(path)
files.update((ROOT / 'docs/artifacts/keyboard-circuit/phase2/native').glob('*I09*'))
files.add(FOLDER / 'P3-M01-review-time-brief-01.md')

entries = []
for path in sorted(files):
    assert path.is_file(), path
    entries.append({'path': path.relative_to(ROOT).as_posix(), 'sha256': sha(path), 'bytes': path.stat().st_size})
result = {'candidate': 'KeyboardCircuit_P3_M01_01', 'revision': 'KC_P3_M01_01', 'mapRevision': 'KC_MAP_M01_01',
          'layout': 'KC_LAYOUT_P2_I09_03', 'baseCourseRevision': 'KC_P2_I09_03', 'origin': [2222,330,-1158], 'requiredLaps': 2,
          'count': len(entries), 'entries': entries,
          'boundary': 'Exact review-time map sources, fixtures, native/evidence/view inputs, original mesh source, prior global copies and baseline recovery. Mutable live brief copied at review time; subsequent gate/report and reviewer judgments are outside this immutable input freeze.'}
freeze = FOLDER / (sys.argv[1] if len(sys.argv)>1 else 'P3-M01-source-freeze-01.json')
assert not freeze.exists(), 'Do not silently replace a reviewed freeze; preserve history and use a fresh identifier.'
freeze.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
assert all(sha(ROOT/row['path']) == row['sha256'] and (ROOT/row['path']).stat().st_size == row['bytes'] for row in entries)
agreement = {'passed': True, 'count': len(entries), 'revision': result['revision'], 'sourceFreeze': freeze.name, 'sourceFreezeSha256': sha(freeze)}
(FOLDER / freeze.name.replace('source-freeze','freeze-agreement')).write_text(json.dumps(agreement,indent=2)+'\n',encoding='utf-8')
print(json.dumps(agreement))
