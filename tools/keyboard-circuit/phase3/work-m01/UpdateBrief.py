from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
path = ROOT / 'docs/artifacts/keyboard-circuit/COURSE_BRIEF.md'
lines = path.read_text(encoding='utf-8').splitlines()
replacements = {
 '- **Status:**': '- **Status:** Phase 2 `KC_P2_I09_03` is accepted by the owner and Ideation. Phase 3 `KC_P3_M01_01` / map `KC_MAP_M01_01` is installed around the unchanged `KC_LAYOUT_P2_I09_03` course. Five hardware landmarks, sixty individual circuit plates and eight district cases are complete. Native geometry, body clearance, scenery visibility and motion-volume checks pass; final route/focused tests and five fresh independent reviews are in progress. No Phase 3 pass is claimed until that gate closes.',
 '- **Accepted baseline / live target:**': '- **Accepted baseline / live target:** Obby Tournament, place `85558151074819`, universe `10191126818`; primary Studio `df0bbff3-e155-4625-90f8-03fd79e1e177`. Preserve the owner-moved course origin `(2222,330,-1158)`. The moved Phase 2 model is inert in `ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses`, alongside twelve prior courses. Its owner-placement native export and the original frozen Phase 2 export are preserved. Only `KeyboardCircuit_P3_M01_01` is active in Workspace; unrelated maps/palette are preserved.',
 '- **Next action:**': '- **Next action:** Finish the final decorated two-lap Normal/Expert and focused native checks, source/native export verification, and five independent overall map reviews at least 8.5 with zero blockers each. Keep Play → F6 → Keyboard Circuit — 2 Laps, restart and Lobby behavior. Phase 3 implementation and ordinary repairs remain authorized.',
 '- **Operations:**': '- **Operations:** Root builds and tests without helpers or computer control. The live Phase 2 geometry had moved by `(-20278,0,442)` while absolute recovery attributes retained the old origin. M01 preserves all accepted gameplay part poses exactly and translates only documented world-point/frame attributes and traversal markers. No owner placement is reset. Scoped artwork drafts and the prior course are retained in ServerStorage. No whole-place save or publication. Passive Edit capture shows a distant overview; close Client capture timed out in the Edit peer. Six clearly labeled offline reconstructions use actual native transforms and the existing K02 mesh source; they do not verify native lighting/GUI or human legibility.',
}
for index, line in enumerate(lines):
    for prefix, replacement in replacements.items():
        if line.startswith(prefix):
            lines[index] = replacement
text = '\n'.join(lines) + '\n'
text = text.replace('The sixteen current sources are under `tools/keyboard-circuit/phase2/work-i09-03/sources/`;', 'The twenty current map sources are under `tools/keyboard-circuit/phase3/work-m01/sources/`; sixteen accepted Phase 2 sources are preserved byte for byte;')
text = text.replace('Current course has 6977 parts and 13980 descendants; part counts do not measure FPS.', 'Current map has 7598 parts, including 621 static noncolliding artwork parts and 102 decorative K02 caps. The 3005 gameplay press targets are unchanged. Counts do not measure FPS.')
path.write_text(text, encoding='utf-8')
print('Updated the single current map record; final gate remains pending.')
