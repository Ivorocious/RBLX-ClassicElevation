from pathlib import Path
import re

root = Path(__file__).resolve().parents[4]
path = root / 'docs/artifacts/keyboard-circuit/COURSE_BRIEF.md'
text = path.read_text(encoding='utf-8')
text = text.replace('Brief R10 / layout R02 / visual reference V08.', 'Brief R11 / current I09 layout / visual reference V08.')
start = text.index('## Active Creator record')
end = text.index('Current working references:', start)
record = '''## Active Creator record

- **Task:** `keyboard-circuit` — Course Creator — Keyboard Circuit.
- **Owner amendment, October 8:** before accepting Phase 2, revise Expert routes to preserve more of the course and restore a reason to choose Normal. Add four midpoint checkpoints on existing permanent banks. Keep two laps and the Normal 4–6-minute goal. The owner explicitly prioritizes preserving the experience over the previous Expert 2–3-minute goal and permits a longer Expert time.
- **Authorized phase:** Phase 2 — Course Creation from the accepted C08 kit. Rough large surroundings remain for space, visibility and camera checks. Phase 3 and publication remain outside scope.
- **Status:** `Workspace.KeyboardCircuit_P2_I09_Experience02`, revision `KC_P2_I09_02`, layout `KC_LAYOUT_P2_I09_02`, is installed at `(22500,330,-1600)`. Normal retains sixteen encounters and eight moving mechanisms. The two optional Expert cuts retain twelve encounters, six mechanisms, both Enter sections and all four sound districts. Four new permanent midpoint saves give seven checkpoints plus the start. Native feature/support checks pass; fresh races, failure checks, native recovery and five exact-candidate reviews are being completed. Earlier I08 scores do not apply to I09.
- **Creator chat:** `01a1129b-7643-7cb2-a70a-6b84c8c9777f`, local. Root implements and tests; no helper agents.
- **Reviewers:** retain /root/kc_i08_r1_visual, /root/kc_i08_r2_route, /root/kc_i08_r3_hazards, /root/kc_i08_r4_experience and /root/kc_i08_r5_engineering where available, each gpt-6.1-sol / high. Request fresh independent I09 overall judgments. Each must score at least 8.5/10 with zero blockers on the same frozen candidate; no average or inherited score replaces an individual pass.
- **Review assignments:** R1 visual/reference fidelity; R2 route, jumps, Expert fairness and pacing; R3 hazards, contact and recovery; R4 readability, audio, accessibility and camera; R5 source, editability, integration and performance. Fix concrete failures and recheck without replacing a low-scoring judge.
- **Accepted baseline / live target:** Obby Tournament, place `85558151074819`, universe `10191126818`; primary Studio `df0bbff3-e155-4625-90f8-03fd79e1e177`. Accepted C08 and K01 remain under `ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008`. K02 reusable imports remain available. Eleven older/rejected courses are inert in that archive; the current course is the only Keyboard Circuit model in Workspace.
- **State authority:** this brief records current status. The first page of [keyboard-circuit.drawio](keyboard-circuit.drawio) is the current I09 route; subsequent R02 pages are labelled history. [route-preview.png](route-preview.png) is an authored-coordinate schematic. [spatial-preview.png](spatial-preview.png) and the eleven V08 images remain appearance/history references. Exact geometry comes from current Layout and source, not generated images.
- **Preserved history:** [pre-I09 brief and editable plan](history/I09-before-expert-revision/COURSE_BRIEF.md), [I08 final report](phase2/P2-I08-FINAL-REPORT-01.md) and its exact evidence remain unchanged. I08's four cuts skipped twelve encounters and all eight mechanisms; that design and its Expert target are superseded.
- **Permissions:** scoped source, isolated course revision, relevant native tests, recovery exports and archival of older Keyboard Circuit objects are authorized. Preserve unrelated maps, palette, accepted assets and owner edits. No computer control, helper delegation, whole-place save, publication, Phase 3, stored-player-data, economy, monetization or security changes.
- **Next action:** finish candidate-specific verification and five independent reviews, then owner playtest. Play → F6 → Keyboard Circuit — 2 Laps starts the current course; the same button restarts and Lobby exits. Technical gates do not constitute owner acceptance or typical-human pacing proof.
- **Operations:** only owned native avatar fixtures operate during isolated Play; no mouse, keyboard, focus or camera control. Studio is minimized, so a fresh rendered screenshot is unavailable. Current native/source evidence and the authored route plot are labelled accordingly. Return Studio to Edit and release all fixture input before handoff.

Ordinary movement remains WalkSpeed 16, JumpHeight 7.2, UseJumpPower false, gravity 196.2 and zoom 0.5–30. The sixteen current sources are under `tools/keyboard-circuit/phase2/work-i09/sources/`; live StudioDevService and preview are mirrored through the existing Rojo files. Original K02 meshes remain under `assets/keyboard_circuit/`. Typical ordinary caps remain 2.42×.85×2.42 studs with one shared mesh. The retained big-key shapes, single legends, held press and eight down/up clips are unchanged. Capacity remains a 20-racer planning assumption; fresh crowd/device/FPS, subjective audio and typical-human pacing proof are not established. Current course has 6977 parts and 13980 descendants; part counts do not measure FPS.

'''
text = text[:start] + record + text[end:]
text = text.replace("The owner's latest October 8 requirement is two laps in roughly 4–6 minutes for normal players and 2–3 minutes for experts, superseding the preceding three-lap requirement. These are requirements to verify, not established human results.", "The owner's latest October 8 requirement is two laps, a Normal 4–6-minute goal and experience-preserving Expert choices that may take longer than the superseded 2–3-minute target. These are design goals, not established human results.")
text = text.replace('sixteen main sequences, eight mechanisms and four marked Expert precision alternatives', 'sixteen main sequences, eight mechanisms and two marked Expert precision alternatives')
text = text.replace('Complete all sixteen main-route sequences, four Expert alternatives, four sound districts', 'Complete all sixteen main-route sequences, two Expert alternatives, four sound districts')
text = text.replace("The owner's four-cut and two-lap amendments supersede the original native R02 branch count and timing labels; current Layout controls candidate geometry.", "The current owner amendment replaces I08's four cuts with two experience-preserving cuts and adds four midpoint saves. The current editable I09 plan and Layout supersede the historical R02 branch/timing labels.")
text = text.replace('Establish moderate challenge immediately. Prove presses, slopes, continuous landings and follower-safe fallaway windows.', 'Everyone crosses O01/H02. X03 branches after H02 and replaces O02/H03 with a harder precision chain; R1 saves at the permanent H02 exit before either choice.')
text = text.replace('X01 branches after H04, replacing H05/O04 with a much harder short chain. Everyone encounters the falling keys. Prove their complete fall volume and the lift\'s supported exit.', 'Both routes play all four encounters, including foundry, lift and Enter hairpin. R2 saves on the permanent foundry exit.')
text = text.replace('X02 branches after H07, replacing O06\'s longer outer arc with precise bracket-key transfers. Everyone boards the shuttle and passes the sweep. Prove carried motion, the moving landing, camera comfort and merge visibility.', 'Everyone boards and rides H06. X02 branches after H06, replacing H07/O06 with a narrow bracket chain. R3 saves on the permanent shuttle exit.')
text = text.replace('A readable sequence of direction changes, opening gaps and a final pair of jumps. Both expert routes still reach this section. Prove the complete sequence and the connection back into the next lap.', 'Both routes play the full Domino, Shift and Double-Enter sequence. R4 saves on the permanent Domino exit. F01 and F00 complete the ordered lap.')
text = text.replace("All hit/fall outcomes return to the current section's preceding checkpoint; the entry/lap start F00 is S01's recovery point. A safe wait is not automatically another checkpoint.", "Hits and falls return to the most recent server-accepted recovery save. Four marked permanent exit banks now save R1 after H02, R2 after H04, R3 after H06 and R4 after H08. Other safe waits do not automatically save. F00 is the initial/lap-start recovery point.")
text = text.replace('Falling retries from F00. |\n| H04', 'Falling retries from R1 once reached. |\n| H04')
text = text.replace('Falling retries from CP1. |\n| H06', 'Falling retries from R2 once reached. |\n| H06')
text = text.replace('Contact retries from CP2. |', 'Contact retries from R3 once reached. |')
text = text.replace('Falling retries from CP3. |', 'Falling retries from R4 once reached. |')
a=text.index('### Much harder optional shortcuts')
b=text.index('## Capacity, timing and accessibility',a)
text=text[:a]+'''### Two optional precision shortcuts

- **X03 Stagger Cut, Creamy:** branches after H02 and R1, replaces O02/H03, then merges before CP1. Thirteen 1.7×1.7-stud caps use lateral stagger and height changes over open void. A miss returns to R1.
- **X02 Bracket Spine, Clacky:** branches after H06 and R3, replaces H07/O06, then merges before CP3. Twelve 2.2×1.45-stud caps use a different lateral/height rhythm over void. A miss returns to R3.

These twenty-five precision caps per lap are smaller than ordinary caps. Their collision contacts match their visible footprints; decorative stems cannot support the player. Purple signs identify the cuts before commitment and Normal retains broad-key choices. Thocky and Clicky have no marked shortcuts, preserving their lifts, foundry, Domino/Shift encounters and both Enter sections. Expert retains twelve of sixteen encounters and six of eight moving mechanisms. Neither cut skips a checkpoint, required main gate or sound district. Verify positive observed endpoint and whole-race savings, and real failed-jump recovery; do not assert exhaustive bypass prevention or measured human difficulty from a few automated probes.

### Start, checkpoints and racing room

F00 is the broad shared start/lap bank. Ordered main gates remain CP1 → CP2 → CP3 → F01 → F00. Recovery ordinals are F00(0), R1(1), CP1(2), R2(3), CP2(4), R3(5), CP3(6), R4(7). A grounded server-verified landing on the exact permanent midpoint bank saves recovery without advancing the required main gate or lap. Future-district and backward saves are rejected; starting the next lap resets the ordinal. F01 remains the final passing gate, without a new recovery checkpoint.

There are seven recovery checkpoints plus start, displayed as /7. The existing large start/CP bays keep twenty planned slots each; the four smaller midpoint exit banks have nine supported planned slots each. That is 116 planned placements, not twenty-racer throughput proof. Respawns stay on permanent contact, outside mechanism travel. Passing, small-bank crowd merges and precision-route queues remain owner/crowd playtest concerns.

'''+text[b:]
a=text.index('The current **two-lap targets')
b=text.index('## Phase targets and first proof',a)
text=text[:a]+'''The current **two-lap Normal target is 240–360 seconds**. The owner explicitly chose experience preservation over the earlier Expert 120–180-second target. Expert has no invented replacement numeric window; it must offer meaningful optional skill and clean observed time savings while retaining the majority of the experience.

Fresh I09 continuous two-lap movement tests and paired route-endpoint comparisons are being completed. Do not reuse I08's 290.541/123.313-second results as current I09 results. Enrollment clocks include setup and are reported separately. Automated clean traversal does not establish typical-human time, mistake distribution, controlled same-phase shortcut savings or subjective difficulty. Both routes use ordinary movement; no artificial pacing holds are allowed.

Preserve readable touch-screen views, bounded local audio and shared mesh reuse. Mechanism tuning, main-route geometry, art and audio remain unchanged from I08. New midpoint saves and Expert precision geometry require fresh candidate-specific checks. Device/FPS performance, mobile behavior and fresh twenty-racer flow remain unverified.

'''+text[b:]
text=text.replace('complete all sixteen main-route sequences, four Expert district cuts', 'complete all sixteen main-route sequences, two optional Expert cuts')
path.write_text(text,encoding='utf-8')
print('Current I09 brief and historical references aligned')
