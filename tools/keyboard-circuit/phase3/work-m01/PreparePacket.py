from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
WORK = Path(__file__).resolve().parent
FOLDER = ROOT / 'docs/artifacts/keyboard-circuit/phase3'

def read(name):
    return json.loads((FOLDER / name).read_text(encoding='utf-8'))

def write(name, data):
    path = FOLDER / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

edit = read('P3-M01-edit-evidence-01.json')
for key, name in [('integration', 'integration-audit'), ('motion', 'motion-clearance'), ('visibility', 'visibility-audit'), ('recovery', 'native-recovery')]:
    file = FOLDER / f'P3-M01-{name}-01.json'
    if file.exists() and json.loads(file.read_text()) != edit[key]:
        history = FOLDER / 'history' / ('before-finishing-' + file.name)
        if not history.exists():
            shutil.copyfile(file, history)
    write(file.name, edit[key])

native = FOLDER / 'native/KC_P3_M01_01.rbxm'
assert native.stat().st_size == edit['recovery']['courseBytes'] == 203233
assert hashlib.sha256(native.read_bytes()).hexdigest() == edit['recovery']['nativeSha256']
assert edit['integration']['artworkParts'] == 621 and edit['integration']['parts'] == 7598
assert edit['integration']['geometryPassed'] and edit['integration']['bodyClearancePassed']
assert not edit['integration']['sourceFailures'] and edit['integration']['maximumPositionError'] == 0
assert edit['visibility']['passed'] and edit['motion']['passed']

source = read('P3-M01-native-source-agreement-01.json')
global_paths = {
    'StudioDevService': 'src/ServerScriptService/Services/StudioDevService.luau',
    'StudioDevController': 'src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau',
    'KeyboardCircuitPhase2Preview': 'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau',
}
for row in source['rows']:
    if '.SourceSnapshot.' in row['path']:
        suffix = {'ModuleScript': '.luau', 'Script': '.server.luau', 'LocalScript': '.client.luau'}[row['class']]
        path = WORK / 'sources' / (row['name'] + suffix)
    else:
        path = ROOT / global_paths[row['name']]
    raw = path.read_bytes()
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], row['path']
    row['durablePath'] = path.relative_to(ROOT).as_posix()
source['passed'] = len(source['rows']) == 23 and len(source['active']) == 1 and len(source['archived']) == 13 and source['archivedScriptsDisabled']
assert source['passed'] and source['origin'] == [2222, 330, -1158] and source['descendants'] == 14893
write('P3-M01-native-source-agreement-01.json', source)

preserved = []
for old in sorted((ROOT / 'tools/keyboard-circuit/phase2/work-i09-03/sources').glob('*.luau')):
    raw = old.read_bytes()
    assert (WORK / 'sources' / old.name).read_bytes() == raw, old.name
    preserved.append({'file': old.name, 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)})
assert len(preserved) == 16
old_globals = json.loads((ROOT / 'docs/artifacts/keyboard-circuit/phase2/P2-I09-native-source-agreement-03.json').read_text())
for row in old_globals['rows']:
    if '.SourceSnapshot.' not in row['path']:
        history = FOLDER / 'history' / Path(global_paths[row['name']]).name
        assert hashlib.sha256(history.read_bytes()).hexdigest() == row['sha256']
write('P3-M01-baseline-preservation-01.json', {'passed': True, 'unchangedSources': preserved, 'count': 16,
    'globalChange': 'Only current StudioDevService candidate name and revision change. All three preceding global files are preserved with the accepted Phase 2 hashes in phase3/history.',
    'boundary': 'Preserved original Phase 2 inputs and native export. Current StudioDevService intentionally supersedes its old global source-freeze row; the original file is recoverable from the verified history copy.'})

manifest = read('views/render-manifest.json')
supplemental = read('views/supplemental-view-manifest.json')
for index, view in enumerate(manifest['views']):
    if view['name'] == 'clacky-fins':
        manifest['views'][index] = supplemental['views'][0]
manifest['supplementalRenderer'] = 'Existing tools/stud-garden-v2/closing/render_saved_views.py used for the centered Clacky view from the saved final scene.'
manifest['limits'] += ' GUI font rasterization, stroke glyphs and material response are approximations; these images do not certify native legibility or satisfaction.'
write('views/render-manifest.json', manifest)
write('P3-M01-cleanup-01.json', {'passed': True, 'candidate': source['candidate'], 'revision': source['revision'], 'datamodel': 'Edit',
    'inputReleased': True, 'participantDetached': True, 'ownedPlayStopped': True, 'computerControlUsed': False,
    'boundary': 'Owned probe Stop and real Lobby remote verified participant removal before stopping the owned Studio Play. No owner Play session or computer control was used.'})

old_work = ROOT / 'tools/keyboard-circuit/phase2/work-i09-03'
for name in ['SummarizeRuns.py', 'CheckpointCadence.py']:
    text = (old_work / name).read_text()
    text = text.replace('keyboard-circuit/phase2', 'keyboard-circuit/phase3').replace('P2-I09-', 'P3-M01-').replace('-03.json', '-01.json')
    (WORK / name).write_text(text, encoding='utf-8')
print(json.dumps({'nativeBytes': native.stat().st_size, 'nativeSha256': edit['recovery']['nativeSha256'], 'installedSources': len(source['rows']), 'unchangedBaselineSources': len(preserved), 'parts': 7598, 'artwork': 621}))
