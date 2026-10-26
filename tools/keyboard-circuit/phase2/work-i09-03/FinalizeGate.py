from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
folder = root / 'docs/artifacts/keyboard-circuit/phase2'
candidate = 'Workspace.KeyboardCircuit_P2_I09_Experience03'
revision = 'KC_P2_I09_03'
layout = 'KC_LAYOUT_P2_I09_03'

def read(name):
    return json.loads((folder / name).read_text(encoding='utf-8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

freeze_name = 'P2-I09-source-freeze-03.json'
freeze = read(freeze_name)
freeze_sha = sha(folder / freeze_name)
assert freeze['count'] == len(freeze['entries']) == 41
frozen = {row['path']: row for row in freeze['entries']}
assert all(sha(root / path) == row['sha256'] and (root / path).stat().st_size == row['bytes'] for path,row in frozen.items())
assert read('P2-I09-freeze-agreement-03.json')['passed']

reviews = []
for number,role,agent in [
    (1,'visual','/root/kc_i09_r1_visual'), (2,'route','/root/kc_i08_r2_route'),
    (3,'hazards','/root/kc_i08_r3_hazards'), (4,'experience','/root/kc_i09_r4_experience'),
    (5,'engineering','/root/kc_i08_r5_engineering'),
]:
    name = f'reviews/I09-R{number}-{role}.json'
    data = read(name)
    reviewed = data['candidate'] if isinstance(data['candidate'],str) else data['candidate']['path']
    reviewed_revision = data.get('revision') or data['candidate']['revision']
    score = data.get('overallScore',data.get('score'))
    assert reviewed == candidate and reviewed_revision == revision, name
    assert data.get('layout') == layout, name
    assert score >= 8.5 and not data['blockers'] and data.get('blockerCount',0) == 0, name
    assert data['sourceFreezeSha256'] == freeze_sha and data['sourceFreeze'].endswith(freeze_name), name
    assert data['model'] == 'gpt-6.1-sol' and data.get('reasoning',data.get('reasoningEffort')) == 'high', name
    reviews.append({'reviewer':f'R{number}','role':role,'agent':agent,'model':'gpt-6.1-sol','reasoning':'high',
                    'score':score,'blockers':0,'reviewFile':name,'reviewSha256':sha(folder/name),
                    'notesSha256':sha((folder/name).with_suffix('.md')),'sourceFreezeSha256':freeze_sha})

edit_name = 'P2-I09-post-review-edit-agreement-03.json'
edit = read(edit_name)
assert edit['passed'] and edit['datamodel'] == 'Edit' and edit['requiredLaps'] == 2 and edit['workspaceCourseCount'] == 1
assert edit['parts'] == 6977 and edit['descendants'] == 13980 and edit['placementOffset'] < .001
assert edit['candidate'] == candidate.removeprefix('Workspace.') and edit['revision'] == revision and edit['layout'] == layout
assert len(edit['archived']) == 12 and len(edit['rows']) == 19
assert edit['unrelatedPartCounts'] == {'Lobby':1243,'GrandArcade':281,'SGV2_Phase3_F04':8015,'ObstacleKit_Palette':369}
sources = root / 'tools/keyboard-circuit/phase2/work-i09-03/sources'
names = {p.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau'):str(p.relative_to(root)).replace('\\','/') for p in sources.glob('*.luau')}
globals = {'ServerScriptService.Services.StudioDevService':'src/ServerScriptService/Services/StudioDevService.luau',
           'StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController':'src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau',
           'StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview':'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau'}
for row in edit['rows']:
    path = globals[row['path']] if row['path'] in globals else names[row['name']]
    assert row['sha256'] == frozen[path]['sha256'] and row['bytes'] == frozen[path]['bytes']

normal,expert = [read(f'P2-I09-{route}-two-lap-summary-03.json') for route in ('normal','expert')]
for run in (normal,expert):
    assert run['passed'] and run['revision'] == revision and run['requiredLaps'] == 2
    assert run['naturalGates'] == 10 and run['naturalMidpoints'] == 8 and run['recoveries'] == 0 and run['setupCalls'] == 1 and run['fixtureHoldSeconds'] == 0
    assert sha(folder/run['rawTrace']) == run['rawSha256'] and all(run['cleanup'].values())
assert 240 <= normal['continuousSeconds'] <= 360 and 240 <= normal['serverEnrollmentSeconds'] <= 360
assert expert['targetSeconds'] is None and expert['withinPlanningTarget'] is None and expert['precisionLandings'] == 50
comparison = read('P2-I09-route-comparison-03.json')
assert comparison['passed'] and comparison['wholeRaceSecondsSaved'] > 0 and len(comparison['intervals']) == 4
assert all(row['secondsSaved'] > 0 and 0 < row['expertSampledPathStuds'] < row['normalSampledPathStuds'] for row in comparison['intervals'])

focus = {}
for name in ('recovery','expert','bypass','domino','held-press','dev-control'):
    data = read(f'P2-I09-focused-{name}-03.json')
    assert data['passed'] and data['revision'] == revision and data['candidate'] == candidate.removeprefix('Workspace.')
    focus[name] = data
falls = [row for row in focus['recovery']['results'] if row['event'] == 'fall-recovery']
assert len(falls) == 8 and {row['gate'] for row in falls} == {'F00','R1','CP1','R2','CP2','R3','CP3','R4'}
for row in falls:
    assert row['serverRecord']['reason'] == 'Fall'
    assert all(row['before'][key] == row['after'][key] for key in ('nextGate','completedLaps','recoveryGate'))
assert len(focus['expert']['tests']) == len(focus['bypass']['tests']) == 4
assert all(not row['arrived'] for row in focus['expert']['tests'] + focus['bypass']['tests'])
assert len(focus['domino']['trials']) == len(focus['held-press']['tests']) == 3
assert all(row['passed'] for row in focus['domino']['trials'])

signs = read('P2-I09-sign-visibility-03.json')
assert signs['passed'] and signs['minimumContrast'] >= 4.5 and len(signs['labels']) == 24 and len(signs['visibility']) == 80
slots = read('P2-I09-recovery-footprints-03.json')
assert slots['passed'] and slots['slotCount'] == 116 and slots['rayCount'] == 1044 and not slots['failures']
audit = read('P2-I09-native-feature-audit-03.json')
assert audit['passed'] and audit['checkpointCount'] == 7 and audit['parts'] == 6977 and audit['mechanisms'] == 8 and len(audit['branches']) == 2
assert read('P2-I09-native-preservation-03.json')['passed']
assert read('P2-I09-baseline-source-preservation-03.json')['normalizedTextIdenticalCount'] == 11
motion = read('P2-I09-motion-boundaries-03.json')
assert motion['passed'] and motion['revision'] == revision and sum(row['samples'] for row in motion['checks'].values()) == 14412
native = read('P2-I09-native-recovery-03.json')
model = folder / 'native/KC_P2_I09_03.rbxm'
assert native['roundTrip']['passed'] and native['freshSourceRebuild']['passed']
assert native['roundTrip']['leftCount'] == native['freshSourceRebuild']['rightCount'] == 13980
assert model.stat().st_size == native['courseBytes'] and sha(model) == native['nativeSha256']

scores = '/'.join(str(row['score']) for row in reviews)
report = f'''# Keyboard Circuit Phase 2 — I09 candidate03

Two optional Expert cuts now retain twelve of sixteen encounters, six of eight moving mechanisms, all four sound districts and both Enter sections. Normal remains the complete course. X03 is a staggered precision chain after H02; X02 is a narrower bracket chain after H06. Both give observed clean savings and retry from their nearby permanent midpoint banks.

Four new midpoint saves on H02/H04/H06/H08 exits give seven checkpoints plus the start. Grounded server checks save recovery without gate/lap credit; future/backward saves reject and each new lap resets. Eight deliberate falls return to the exact saved banks. All 116 planned positions and 1044 support rays pass; small-bank crowd capacity remains unverified.

Fresh automated two-lap runs complete Normal in {normal['continuousSeconds']:.3f}s and Expert in {expert['continuousSeconds']:.3f}s, with ten natural gates, eight midpoint saves and zero recoveries each. Enrollment clocks including start setup are {normal['serverEnrollmentSeconds']:.3f}/{expert['serverEnrollmentSeconds']:.3f}s. Four branch endpoint intervals are faster and physically shorter; total observed saving is {comparison['wholeRaceSecondsSaved']:.3f}s. These are clean automated results, not typical-human timings or controlled same-phase savings. The owner explicitly permits Expert to exceed the preceding 2–3-minute target to preserve experience.

Candidate02 failed strict visual reviews for pale sign ink and shielded checkpoint panels. Candidate03 fixes both: 24 native labels have at least 5.216:1 contrast, and 400 sightlines to sign text regions pass. Original judgments remain in history. Studio is minimized, so no new rendered screenshot or human listening audition is claimed. Big-key art, single legends, held pressing, audio and mechanism tuning retain their prior behavior.

All five independent Sol 6.1 High final overall reviews pass: **{scores}**, zero blockers each, on the same frozen set of 41 inputs. Nineteen installed sources agree before and after review. Native export reopening and fresh-source rebuild agree across 13980 descendants, typed attributes, internal references, sources, text and ink. Eleven baseline source texts are unchanged after line-ending normalization; exact byte hashes bind the current source.

One current Keyboard Circuit course remains in Workspace; twelve older/rejected courses and their source/recovery copies remain inert in the scoped archive. Other maps and the palette are preserved. Owned test input is released, participant detached and Studio returned to Edit. Counts do not prove an FPS gain.

Owner test: **Play → F6 → Keyboard Circuit — 2 Laps**. Choose Normal or the two purple Expert cuts. The same control restarts; Lobby exits. Judge human difficulty, shortcut reward, timing and sound preference. Phase 2 owner acceptance, 20-racer/device/FPS proof and exhaustive shortcuts remain pending. No Phase 3, whole-place save or publication.

[Detailed evidence and review packet](P2-I09-REVIEW-BRIEF-03.md) · [Final gate](P2-I09-FINAL-GATE-03.json) · [Current route schematic](native/I09-route-plan-03.png).
'''
(folder/'P2-I09-FINAL-REPORT-03.md').write_text(report,encoding='utf-8')
evidence_names = [freeze_name,'P2-I09-freeze-agreement-03.json',edit_name,normal['rawTrace'],expert['rawTrace'],
                  'P2-I09-route-comparison-03.json','P2-I09-checkpoint-cadence-03.json','P2-I09-sign-visibility-03.json',
                  'P2-I09-native-preservation-03.json','P2-I09-native-recovery-03.json','P2-I09-REVIEW-BRIEF-03.md',
                  'P2-I09-FINAL-REPORT-03.md','native/KC_P2_I09_03.rbxm']
evidence_names += [f'P2-I09-focused-{name}-03.json' for name in focus]
gate = {'passed':True,'status':'complete_technical_pass','candidate':candidate,'revision':revision,'layout':layout,'requiredLaps':2,
        'requiredIndividualScore':8.5,'reviewerCount':5,'helperAgents':0,'reviews':reviews,'allIndividualScoresPass':True,'allZeroBlockers':True,
        'sourceFreeze':freeze_name,'sourceFreezeSha256':freeze_sha,'frozenInputs':41,'nativeSources':19,'postReviewEditAgreement':edit_name,
        'normalContinuousSeconds':normal['continuousSeconds'],'expertContinuousSeconds':expert['continuousSeconds'],
        'normalServerEnrollmentSeconds':normal['serverEnrollmentSeconds'],'expertServerEnrollmentSeconds':expert['serverEnrollmentSeconds'],
        'expertNumericTarget':None,'expertPriority':'Preserve the experience; owner allows longer Expert time','observedSecondsSaved':comparison['wholeRaceSecondsSaved'],
        'retainedExpertEncounters':12,'retainedExpertMechanisms':6,'expertCuts':2,'checkpointCount':7,'midpointsAdded':4,
        'nativeExportBytes':native['courseBytes'],'nativeExportSha256':native['nativeSha256'],'activeWorkspaceKeyboardCourses':1,'archivedOlderCourses':12,
        'unrelatedPartCounts':edit['unrelatedPartCounts'],'studioMode':'Edit','ownerAcceptance':'pending','report':'P2-I09-FINAL-REPORT-03.md',
        'evidence':[{'path':name,'bytes':(folder/name).stat().st_size,'sha256':sha(folder/name)} for name in evidence_names],
        'boundary':'Five independent current03 technical judgments, no inherited or averaged scores. Fresh clean automated races and focused native checks. Human pace/fun/audio/difficulty, exhaustive shortcuts,20-racer/mobile/FPS remain unverified. No computer/camera control, publication, Phase3 or unrelated systems.'}
(folder/'P2-I09-FINAL-GATE-03.json').write_text(json.dumps(gate,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':True,'scores':[row['score'] for row in reviews],'inputs':41,'nativeSources':19,'gate':'P2-I09-FINAL-GATE-03.json'}))
