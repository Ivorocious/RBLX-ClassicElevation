from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
folder = root / 'docs/artifacts/keyboard-circuit/phase2'
def read(name):
    return json.loads((folder / name).read_text(encoding='utf-8'))

normal = read('P2-I09-normal-two-lap-summary-03.json')
expert = read('P2-I09-expert-two-lap-summary-03.json')
comparison = read('P2-I09-route-comparison-03.json')
cadence = read('P2-I09-checkpoint-cadence-03.json')
native = read('P2-I09-native-recovery-03.json')
freeze_name = 'P2-I09-source-freeze-03.json'
freeze = read(freeze_name)
freeze_sha = hashlib.sha256((folder / freeze_name).read_bytes()).hexdigest()
assert freeze['count'] == 41

text = f'''# Keyboard Circuit I09 candidate03 — strict Phase 2 review

Review `Workspace.KeyboardCircuit_P2_I09_Experience03`, revision `KC_P2_I09_03`, layout `KC_LAYOUT_P2_I09_03`. Five independent gpt-6.1-sol High reviewers judge the entire Phase 2 candidate with their assigned emphasis. Each must independently score at least 8.5/10 with zero blockers. Do not inherit or average preceding judgments. A failed candidate needs concrete findings and an honest score. Write only your own I09 review Markdown/JSON files; no helpers, gameplay edits, avatar movement, computer control or camera manipulation.

The owner reopened Phase 2 because Expert skipped too much, had too many easy cuts and removed the incentive for Normal. The owner selected four additional midpoint checkpoints and experience preservation even if Expert exceeds the preceding 2–3-minute target. Two laps and Normal 4–6 minutes remain. No replacement numeric Expert window is invented. Phase 3, publication and unrelated systems are outside scope. Owner acceptance remains pending.

## Exact source and history

- [Freeze03]({freeze_name}): **41 inputs**, SHA256 `{freeze_sha}`.
- [Local/native agreement](P2-I09-freeze-agreement-03.json), [19 installed source hashes](P2-I09-native-source-agreement-03.json), [pre-review Edit state](P2-I09-pre-review-edit-agreement-03.json).
- Sixteen canonical sources: `tools/keyboard-circuit/phase2/work-i09-03/sources/`. Historical base/I08/work-i09 sources are not current03.
- [Baseline preservation](P2-I09-baseline-source-preservation-03.json): eleven art/audio/motion sources have identical text after CRLF/LF normalization. Exact byte hashes differ and are bound in freeze03. Five gameplay-source texts differ from I08: Course, Layout, Progression, Session and preview.
- [02-to03 source delta](P2-I09-source-delta-03.json): fourteen source texts unchanged after normalization; only Course sign ink/placement and candidate identity in Course/Layout change. Gameplay geometry, mechanism tuning, movement, audio and held-press behavior remain unchanged from02.
- [Exact byte agreement correction](P2-I09-line-ending-agreement-correction-03.json): two durable Rojo files were normalized to LF without text changes. Initial failed agreements and manifests are preserved in history; fresh Edit inspection matches all nineteen current sources. No final03 review began until that agreement passed.
- [Native baseline preservation](P2-I09-native-preservation-03.json) retains original Normal/connector/bay/surrounding parts and key legends as multisets, including duplicate sibling names. Intended branch-sign relocation and recovery text changes are excluded. Additions and Expert changes are separately audited.

Candidate02 failed R1/R4: white ink on pale panels had contrast down to1.063:1, and Expert panels shielded midpoint signs. Their failed judgments remain in `history/I09-before-sign-fix/reviews/`. Candidate03 uses dark ink on pale panels, retains white ink on purple, and separates midpoint panels onto the upstream bank edge. [Current native sign checks](P2-I09-sign-visibility-03.json):24 labels, minimum5.216:1 contrast,80 eye/target records with five text-region points each, zero sign-to-sign occlusion. Eye positions include bank centers and all nine planned recovery positions. This is geometry/property proof, not a rendered screenshot or exhaustive scenery/camera check. Previous scores and traces are historical; all final03 judgments must bind this freeze.

## Experience, precision and recovery

Normal retains16 encounters/eight moving mechanisms. Expert retains12 encounters (75%), six mechanisms, both Enter sections and all four sound districts. All Thocky and Clicky encounters remain common, including foundry/lift and Domino/Shift.

| Optional cut | Departure and rejoin | Bypassed | Skill and retry |
| --- | --- | --- | --- |
| X03 Stagger Cut | H02 exit → CP1 | O02/H03 |13 caps,1.7×1.7, alternating lateral/height steps; R1 |
| X02 Bracket Spine | H06 exit → CP3 | H07/O06 |12 caps,2.2×1.45, a different lateral/height rhythm; R3 |

Twenty-five precision caps per lap are smaller than ordinary2.42×2.42 keys, over void, with matching collision footprints and noncolliding decorative stems. Single glyphs and purple Expert/clear Normal signs identify the choices before commitment.250 native support rays find their intended contacts, with separate masking checks. Four bounded early/midpoint attempts to skip a cap fail and return through real Fall to R1/R3. These probes do not establish exhaustive exploits or measured human difficulty. Failed-jump latency is not a full human retry cost. Judge whether the observed modest reward and extra precision support a useful Normal choice.

R1/R2/R3/R4 save on existing permanent H02/H04/H06/H08 exit banks. Recovery order: F00(0),R1(1),CP1(2),R2(3),CP2(4),R3(5),CP3(6),R4(7). There are seven checkpoints plus start; HUD/flags use /7. Required main gates stay CP1→CP2→CP3→F01→F00. Grounded exact-support saves are server checked and grant no main-gate/lap credit. Future/backward/duplicate saves reject; next lap and restart reset. Large start/CP bays retain20 planned slots, midpoints9 each.116 slots/1044 rays pass with1.5-stud minimum edge clearance. Placement planning does not prove20-racer capacity.

## Fresh current03 evidence

| Test | Current passing result |
| --- | --- |
| [Normal two laps](P2-I09-normal-two-lap-summary-03.json) | {normal['continuousSeconds']:.3f}s;32 encounters,42 joins,10 natural gates,8 midpoint saves,0 recoveries |
| [Expert two laps](P2-I09-expert-two-lap-summary-03.json) | {expert['continuousSeconds']:.3f}s;28 visits including cuts,30 joins,50 precision landings,10 gates,8 midpoint saves,0 recoveries |
| [Route comparison](P2-I09-route-comparison-03.json) | Four endpoint intervals faster/physically shorter; whole race saves{comparison['wholeRaceSecondsSaved']:.3f}s |
| [Save cadence](P2-I09-checkpoint-cadence-03.json) | All eight midpoint saves in each race; clean segment gaps recorded, not human retry times |
| [Actual recovery](P2-I09-focused-recovery-03.json) | Eight staged Fall returns onto exact permanent contacts, preserving required gate/lap state |
| [Precision failed skips](P2-I09-focused-expert-03.json) | Four actual ordinary jump failures, correct R1/R3 recovery and /7 HUD, no earned progress |
| [Other bypass probes](P2-I09-focused-bypass-03.json) | Four bounded direct attempts fail without F01 credit |
| [Domino](P2-I09-focused-domino-03.json) | Three arrival offsets, all four passages and exit, zero contacts/recoveries |
| [Big-key hold](P2-I09-focused-held-press-03.json) | Arrow and both joined Enter contacts depress .45, stay held and release; single Enter legend |
| [F6 lifecycle](P2-I09-focused-dev-control-03.json) | Real server action: supported entry, restart, Lobby detach and fresh start; two-lap button caption |
| [Native audit](P2-I09-native-feature-audit-03.json) |6977 parts,3005 press caps,9 special caps,8 mechanisms,2 branches,8 recovery pads |
| [Native recovery](P2-I09-native-recovery-03.json) |{native['courseBytes']} bytes reopen/fresh-source rebuild across13980 descendants, typed attributes/internal references/source bytes/visible text and ink preserved; recovery scripts inert |
| [Motion boundaries](P2-I09-motion-boundaries-03.json) |14412 samples preserve warning, crossing, boarding and motion limits |

Complete raw traces are `P2-I09-normal-two-lap-03.json` and `P2-I09-expert-two-lap-03.json`; summaries contain SHA256 hashes. Each uses one outside-clock staged F00 setup, then continuous ordinary humanoid movement, actual carrying and natural server gates. No in-route positioning, restart, recovery or artificial pacing holds. Speed16,JumpHeight7.2,gravity196.2,UseJumpPower=false. Enrollment clocks {normal['serverEnrollmentSeconds']:.3f}/{expert['serverEnrollmentSeconds']:.3f}s include setup and are separately reported. Hazard arrivals are unpaired; observed savings are not guaranteed same-phase or human results. Fixture support-settling under background Studio is disclosed in raw records, not an FPS test.

## Visuals, scope and claim boundaries

[Current coordinate schematic](native/I09-route-plan-03.png), [editable plan](../keyboard-circuit.drawio) and [current brief](../COURSE_BRIEF.md) agree with Layout. The schematic is not a Studio screenshot. V08 appearance references remain history/reference; big-key art, single legends, held pressing and eight audio clips retain their existing behavior. No new human sound audition is claimed.

Studio is minimized. Passive capture could not obtain a rendered frame; do not restore/focus it or use mouse/keyboard/camera control. Native geometry/color/visibility and owned avatar checks are available. Human pacing/fun/ASMR preference, measured human difficulty, exhaustive exploits, changed-candidate20-racer flow, mobile, latency and FPS remain unverified. Current03 technical review does not mean owner acceptance or Phase3 authorization.

Studio is Edit, owned test input released and participant detached. One current Keyboard Circuit course remains in Workspace, twelve old/rejected courses remain inert in the scoped ServerStorage archive. Other maps/palette remain unchanged: Lobby1243,GrandArcade281,SGV2_Phase3_F048015,ObstacleKit_Palette369 parts. Native model `native/KC_P2_I09_03.rbxm`, SHA256 `{native['nativeSha256']}`. Counts are not FPS gains. No whole-place save, publication, helper implementation, persistent-player-data/economy/security changes or unrelated work.

## Required independent judgment

Write `reviews/I09-Rn-role.md` and matching `.json`, with reviewer/model/reasoning, exact candidate/revision/layout, overall score, blockers, evidence checked, actionable findings, limits, decision, `sourceFreeze` and `sourceFreezeSha256`. Verify the manifest hash and relevant current inputs yourself. Bind only freeze03 above. Read the complete current traces/source/evidence needed for your emphasis; do not copy another judge or replace missing proof with an expected score. Root will fix concrete blockers and request independent re-review if necessary.
'''
(folder / 'P2-I09-REVIEW-BRIEF-03.md').write_text(text, encoding='utf-8')
print(json.dumps({'reviewPacket': 'P2-I09-REVIEW-BRIEF-03.md', 'inputs':41,'sourceFreezeSha256':freeze_sha}))
