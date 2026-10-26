from pathlib import Path
import json
import shutil

root=Path(__file__).resolve().parents[4]
old=root/'tools/keyboard-circuit/phase2/work-i09'
new=root/'tools/keyboard-circuit/phase2/work-i09-03'
assert not new.exists()
(new/'sources').mkdir(parents=True)
for path in list(old.glob('*.luau'))+list(old.glob('*.py'))+list((old/'sources').glob('*.luau')):
    target=new/path.relative_to(old)
    text=path.read_text(encoding='utf-8').replace('work-i09-03/','work-i09-03/').replace('Experience03','Experience03').replace('Sources03','Sources03').replace('NativeRecovery03','NativeRecovery03').replace('KC_P2_I09_03','KC_P2_I09_03').replace('KC_LAYOUT_P2_I09_03','KC_LAYOUT_P2_I09_03')
    target.write_text(text,encoding='utf-8')
builder=new/'CreateCandidate.luau'
text=builder.read_text().replace('workspace:FindFirstChild("KeyboardCircuit_P2_I09_Experience01")','workspace:FindFirstChild("KeyboardCircuit_P2_I09_Experience03")').replace('== "KC_P2_I09_01"','== "KC_P2_I09_03"')
builder.write_text(text)
native=new/'NativeRecovery.server.luau'
native.write_text(native.read_text().replace('#preserved == 11','#preserved == 12'))
state=new/'NativeState.luau'
state.write_text(state.read_text().replace('#archived==11','#archived==12'))
freeze=new/'FreezeInputs.py'
freeze.write_text(freeze.read_text().replace('"tools/keyboard-circuit/phase2/work-i09"','"tools/keyboard-circuit/phase2/work-i09-03"').replace('P2-I09-source-freeze-03.json','P2-I09-source-freeze-03.json'))
verify=new/'VerifyFreeze.py'
verify.write_text(verify.read_text().replace('"tools/keyboard-circuit/phase2/work-i09-03/sources"','"tools/keyboard-circuit/phase2/work-i09-03/sources"').replace('P2-I09-source-freeze-03.json','P2-I09-source-freeze-03.json').replace('P2-I09-freeze-agreement-03.json','P2-I09-freeze-agreement-03.json').replace('P2-I09-native-source-agreement-03.json','P2-I09-native-source-agreement-03.json'))
history=root/'docs/artifacts/keyboard-circuit/phase2/history/I09-before-sign-fix'
(history/'reviews').mkdir(parents=True)
for path in (root/'docs/artifacts/keyboard-circuit/phase2/reviews').glob('I09-R*.*'):
    shutil.copy2(path,history/'reviews'/path.name)
for name in ('P2-I09-REVIEW-BRIEF-01.md',):
    shutil.copy2(root/'docs/artifacts/keyboard-circuit/phase2'/name,history/name)
for name in ('COURSE_BRIEF.md','keyboard-circuit.drawio','route-preview.png'):
    shutil.copy2(root/'docs/artifacts/keyboard-circuit'/name,history/name)
globals=[root/'src/ServerScriptService/Services/StudioDevService.luau',root/'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau']
for path in globals:
    target=history/'globals'/path.relative_to(root/'src')
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(path,target)
    path.write_text(path.read_text(encoding='utf-8').replace('Experience03','Experience03').replace('KC_P2_I09_03','KC_P2_I09_03'),encoding='utf-8')
print(json.dumps({'prepared':str(new),'history':str(history),'candidate':'KeyboardCircuit_P2_I09_Experience03'}))
