from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[4]
OLD = ROOT / 'tools/keyboard-circuit/phase2/work-i09-03'
NEW = Path(__file__).resolve().parent
HISTORY = ROOT / 'docs/artifacts/keyboard-circuit/phase3/history'
for folder in (NEW / 'sources', HISTORY):
    folder.mkdir(parents=True, exist_ok=True)
for source in (OLD / 'sources').glob('*.luau'):
    target = NEW / 'sources' / source.name
    if not target.exists():
        shutil.copyfile(source, target)
for name in ('Setup.client.luau', 'Driver.client.luau', 'Timing.client.luau', 'Race.client.luau', 'FocusedRecovery.client.luau', 'FocusedExpert.client.luau', 'FocusedBypass.client.luau', 'FocusedDomino.client.luau', 'FocusedHeldPress.client.luau', 'FocusedDevControl.client.luau', 'CheckRecoverySlots.server.luau', 'NativeAudit.server.luau'):
    text = (OLD / name).read_text(encoding='utf-8')
    text = text.replace('KeyboardCircuit_P2_I09_Experience03', 'KeyboardCircuit_P3_M01_01').replace('KC_P2_I09_03', 'KC_P3_M01_01')
    (NEW / name).write_text(text, encoding='utf-8')
for relative in ('src/ServerScriptService/Services/StudioDevService.luau', 'src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau', 'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau', 'docs/artifacts/keyboard-circuit/COURSE_BRIEF.md'):
    source = ROOT / relative
    target = HISTORY / source.name
    if not target.exists():
        shutil.copyfile(source, target)
print('Preserved 16 Phase 2 source bytes and four current-state files; adapted 12 isolated fixtures.')
