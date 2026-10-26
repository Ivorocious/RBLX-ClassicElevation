from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "tools/keyboard-circuit/phase2/work-i07"
WORK = ROOT / "tools/keyboard-circuit/phase2/work-i08"
if WORK.exists():
    raise SystemExit("Existing two-lap inputs are frozen; use their saved build recipes instead of regenerating them.")
WORK.mkdir(exist_ok=True)
shutil.copytree(BASE / "sources", WORK / "sources", dirs_exist_ok=True)


def replace(path, before, after):
    source = path.read_text(encoding="utf-8")
    assert before in source, (path, before)
    path.write_text(source.replace(before, after), encoding="utf-8", newline="\n")


layout = WORK / "sources/Layout.luau"
replace(layout, 'KC_LAYOUT_P2_I07_06', 'KC_LAYOUT_P2_I08_01')
replace(layout, 'Owner October 8 final timing and redundant-bank pass', 'Owner October 8 two-lap course and older-build archive')
replace(layout, 'Layout.TargetLaps = 3', 'Layout.TargetLaps = 2')
replace(layout, 'Layout.PacingStatus = "Separate I07 pass; continuous timing pending"', 'Layout.PacingStatus = "Two-lap retuning; fresh continuous timing pending"\nLayout.HorizontalScale = 1.5')
replace(layout, 'Vector3.new(node[1], node[2], node[3])', 'Vector3.new(node[1] * Layout.HorizontalScale, node[2], node[3] * Layout.HorizontalScale)')
replace(layout, 'landings = 5', 'landings = 8')
replace(layout, 'landings = 7', 'landings = 10')

course = WORK / "sources/Course.luau"
replace(course, 'KC_P2_I07_06', 'KC_P2_I08_01')
replace(course, 'root:SetAttribute("CandidateRevision", "KC_P2_C01")', 'root:SetAttribute("CandidateRevision", "KC_P2_I08_01")')
replace(course, '"KEYBOARD CIRCUIT\\n3 LAPS"', '"KEYBOARD CIRCUIT\\n" .. Layout.TargetLaps .. " LAPS"')
replace(WORK / "sources/Progression.luau", 'local REQUIRED_LAPS = 3', 'local REQUIRED_LAPS = require(script.Parent.Layout).TargetLaps')
surroundings = WORK / "sources/Surroundings.luau"
replace(surroundings, 'local Surroundings = {}', 'local Layout = require(script.Parent.Layout)\nlocal Surroundings = {}')
replace(surroundings, 'CFrame.new(origin + data[2])', 'CFrame.new(origin + Vector3.new(data[2].X * Layout.HorizontalScale, data[2].Y, data[2].Z * Layout.HorizontalScale))')

preview = WORK / "sources/KeyboardCircuitPhase2Preview.client.luau"
replace(preview, 'local function updateLap()\n', 'local requiredLaps = candidate:GetAttribute("RequiredLaps")\n\tassert(type(requiredLaps) == "number" and requiredLaps >= 1 and requiredLaps % 1 == 0, "Course lap count required")\n\tlocal function updateLap()\n')
replace(preview, '"Course complete · 3 laps"', '"Course complete · " .. requiredLaps .. " laps"')
replace(preview, 'math.floor(authoredLap), 1, 3', 'math.floor(authoredLap), 1, requiredLaps')
replace(preview, '" of 3 · "', '" of " .. requiredLaps .. " · "')

fixtures = ["Setup.client.luau", "Driver.client.luau", "Timing.client.luau", "Race.client.luau", "FocusedRecovery.client.luau", "FocusedBypass.client.luau", "FocusedHeldPress.client.luau", "FocusedDevControl.client.luau", "CheckRecoverySlots.server.luau", "MotionBoundaries.luau", "NativeRecovery.server.luau", "OfflineGeometry.luau", "CompileFixtures.luau"]
for name in fixtures:
    text = (BASE / name).read_text(encoding="utf-8")
    text = text.replace('work-i07', 'work-i08').replace('KCP2I07', 'KCP2I08').replace('KeyboardCircuit_P2_I07_Final06', 'KeyboardCircuit_P2_I08_TwoLaps01').replace('KC_P2_I07_06', 'KC_P2_I08_01').replace('KC_P2_I07_DRIVER_06', 'KC_P2_I08_DRIVER_01')
    text = text.replace('KCP2I08FinalNativeRecovery06', 'KCP2I08TwoLapNativeRecovery01').replace('KCP2I08FinalNativeExport06', 'KCP2I08TwoLapNativeExport01').replace('KCP2I08FinalRecoveryReceipt06', 'KCP2I08TwoLapRecoveryReceipt01')
    text = text.replace('P2-I07-offline-geometry.json', 'P2-I08-offline-geometry-01.json').replace('I07-preview.rbxm', 'I08-preview.rbxm')
    if name == 'Race.client.luau':
        text = text.replace('options.laps or 3', 'options.laps or 2').replace('requestedLaps == 1 or requestedLaps == 3', 'requestedLaps == 1 or requestedLaps == 2').replace('one measurement lap or three complete race laps', 'one measurement lap or two complete race laps').replace('requestedLaps == 3', 'requestedLaps == 2').replace('lapNumber == 3', 'lapNumber == 2').replace('"KCPhase2Lap") == 3', '"KCPhase2Lap") == 2')
        text = text.replace('{40 * requestedLaps, 60 * requestedLaps}', '{60 * requestedLaps, 90 * requestedLaps}').replace('{80 * requestedLaps, 120 * requestedLaps}', '{120 * requestedLaps, 180 * requestedLaps}').replace('Three continuous automated laps with fifteen ordered natural server gates', 'Two continuous automated laps with ten ordered natural server gates').replace('no three-lap completion claim', 'no two-lap completion claim')
    if name == 'CompileFixtures.luau':
        text = text.replace(' "CreateCandidate.luau",', '')
    (WORK / name).write_text(text, encoding="utf-8", newline="\n")

print(f"Prepared {len(list((WORK / 'sources').glob('*.luau')))} isolated two-lap sources in {WORK}")
