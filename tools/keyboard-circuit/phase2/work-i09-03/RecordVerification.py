from pathlib import Path
import json

root = Path(__file__).resolve().parents[4]
folder = root / 'docs/artifacts/keyboard-circuit/phase2'
def read(name):
    return json.loads((folder/name).read_text(encoding='utf-8'))

n,e = [read(f'P2-I09-{route}-two-lap-summary-03.json') for route in ('normal','expert')]
c = read('P2-I09-route-comparison-03.json')
cadence = read('P2-I09-checkpoint-cadence-03.json')['runs']
def append(path,title,body):
    p = root/path
    text = p.read_text(encoding='utf-8')
    assert title not in text, 'Verification note already exists'
    p.write_text(text.rstrip()+'\n\n'+title+'\n\n'+body.strip()+'\n',encoding='utf-8')

append('docs/DECISIONS.md','## Keyboard Circuit I09 candidate03 sign and evidence correction — October 8, 2026', '''Candidate02 failed independent sign reviews: white ink on pale panels had poor contrast and Expert panels shielded checkpoint text. Candidate03 selects dark ink for pale panels, keeps white on purple and moves midpoint panels to the upstream bank edge facing across the bank. Signs remain noncolliding/nonquery. Main-route/precision geometry, motion tuning, ordinary movement, held-key behavior and audio are unchanged from02. Fourteen of sixteen source texts are identical after newline normalization; Course sign/identity and Layout identity account for the text differences. Eleven baseline art/audio/motion source texts remain identical after newline normalization. Exact byte hashes bind the current sources; no byte-identical claim is made after CRLF-to-LF preparation.

Keep seven checkpoints plus start and two optional cuts retaining12/16 encounters,6/8 moving mechanisms,both Enter sections and all four sound districts. The owner's experience-first Expert amendment remains authoritative. Current Normal target stays240–360seconds. No new Expert numeric window or guaranteed human savings is invented. Preserve candidate02 judgments/evidence in history and require all five independent current03 technical reviews on the same41-input freeze. Owner acceptance remains separate.''')

append('docs/BUGS.md','## Keyboard Circuit I09 candidate03 resolved sign failures — October 8, 2026', '''Candidate02 R1/R4 sign blockers are resolved in03:24 native label contrast checks have minimum5.216:1, and80 bank-center/recovery-position target records ×5 text-region points show zero sign-to-sign occlusion. This does not prove full scenery visibility or human camera readability. Previous failed judgments remain in history.

The first03 source-byte agreement exposed CRLF/LF differences in two durable Rojo files. They are normalized to LF without gameplay text changes. Failed agreements are retained; fresh Edit inspection matches all19 current sources against41 frozen inputs. Native serialization/reopening and fresh-source rebuilding compare text ink as well as geometry, typed attributes, internal references and source bytes. Human difficulty/pacing/audio, exhaustive shortcuts,20-racer/mobile/FPS checks remain open.''')

append('docs/PLAYTEST_NOTES.md','## Keyboard Circuit I09 candidate03 verification — October 8, 2026', f'''Current `KC_P2_I09_03` passes fresh continuous two-lap Normal in{n['continuousSeconds']:.6f}s (laps{n['lapSeconds'][0]:.6f}/{n['lapSeconds'][1]:.6f}) and Expert in{e['continuousSeconds']:.6f}s (laps{e['lapSeconds'][0]:.6f}/{e['lapSeconds'][1]:.6f}). Both have10 natural ordered gates,8 natural midpoint saves,0recoveries and1outside-clock setup, ordinary16/7.2/196.2movement, actual lift/shuttle carrying and0artificial timing holds. Enrollment clocks are{n['serverEnrollmentSeconds']:.6f}/{e['serverEnrollmentSeconds']:.6f}s including setup. Four endpoint intervals are faster/physically shorter; X03 saves5.736/5.066s and X02 saves3.999/4.464s. Whole-run saving{c['wholeRaceSecondsSaved']:.6f}s has unpaired hazard arrivals and is not guaranteed human or same-phase reward.

Seven checkpoints plus start reduce clean gaps to a maximum{cadence['normal']['maximumCleanSecondsBetweenSaves']:.3f}s Normal/{cadence['expert']['maximumCleanSecondsBetweenSaves']:.3f}s Expert in these runs. Eight deliberately staged Fall returns land on exact permanent banks without changing gate/lap state. Four precision-cap skip attempts and four direct Clicky bypass attempts fail without unearned progress. Three Domino arrival offsets, Arrow/joined-Enter hold/release, real F6 entry/restart/Lobby lifecycle and all116planned slots/1044support rays pass. Focused staged tests remain separate from continuous race clocks and full human retry cost.

Twenty-four label contrasts and400 sign text-region sightlines pass on corrected03. Native176966-byte export reopens and fresh-source rebuild agrees across13980descendants including text ink, typed attributes, sources and internal references. One current KC course remains in Workspace;12older/rejected courses and older source/recovery copies remain inert in the scoped archive. Unrelated maps/palette are preserved. Owned input is released, participant detached and Studio returned to Edit.41frozen inputs and19native sources match before final reviews. No fresh rendered screenshot is available while Studio is minimized; no computer/camera control is used. Five final independent reviews and owner acceptance are separately recorded. [Current packet](artifacts/keyboard-circuit/phase2/P2-I09-REVIEW-BRIEF-03.md).''')

tasks = root/'docs/TASKS.md'
text = tasks.read_text(encoding='utf-8')
text = text.replace('- [ ] Complete fresh continuous Normal/Expert two-lap comparison and real fall/failed-skip checks on current I09.', '- [x] Complete fresh current03 Normal/Expert two-lap comparison, eight actual Fall returns, four precision failed skips, four direct bypass probes, three Domino phases and held-key/F6 checks.')
text = text.replace('- [ ] Verify native reopening/fresh rebuilding and exact source freeze; obtain five independent current scores of at least 8.5 with zero blockers.', '- [x] Verify current03 native reopening/fresh rebuilding, exact41-input freeze and19installed source hashes; preserve resolved candidate02 sign-review failures in history.\n- [ ] Obtain five independent final current03 scores of at least8.5 with zero blockers on that exact freeze.')
tasks.write_text(text,encoding='utf-8')
print(json.dumps({'verificationNotesRecorded':True,'finalReviews':'pending','ownerAcceptance':'pending'}))
