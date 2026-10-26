from pathlib import Path
import hashlib
import html
import json
import re
import shutil

root = Path('docs/artifacts/stud-garden-v2/closing-20261005')
scores = {'ART': 8.7, 'ROUTE': 8.7, 'MOVEMENT': 8.6}
for name in ['NATIVE_PREVIEW.html', 'NATIVE_VALIDATION.md', 'NATIVE_SUMMARY.json', 'CLOSING_STATUS.md']:
    original = root / name
    archive = original.with_name(original.stem + '_C05' + original.suffix)
    if not archive.exists():
        shutil.copy2(original, archive)
reviews = {}
for role, score in scores.items():
    path = root / f'reviews/{role}_C08_NATIVE_FINAL.md'
    body = path.read_text(encoding='utf-8')
    assert f'{score}/10' in body and '0ce5b9bd' in body and '437cc43b' in body
    reviews[role] = {'score': score, 'gatePassed': True, 'file': path.relative_to(root).as_posix(), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
old_summary = json.loads((root / 'NATIVE_SUMMARY_C05.json').read_text())
summary = {
    'candidate': 'SGV2_Closing_C08', 'nativeGeometry': '0ce5b9bd', 'nativeContent': '437cc43b',
    'origin': [1563, 257, -1053], 'parts': 7035, 'colliders': 4141, 'meshes': 417,
    'installed': True, 'publicEnabled': False, 'studioMode': 'Edit', 'httpEnabled': False,
    'changes': {'boardsRemoved': 25, 'arrowsBefore': 45, 'arrowsAfter': 8, 'paintedCheckpointNumerals': 9, 'expertMarkers': 2, 'thornMarkers': 1, 'remainingPhysicalBoards': 8, 'scaledTextLabels': 32},
    'reviews': reviews, 'requiredMinimumEach': 8.5, 'allThreeFinalReviewsComplete': True, 'allThreeMeetGate': True,
    'retainedBehaviorEvidence': {'testedCandidate': 'SGV2_Closing_C05', 'results': old_summary['nativeChecks'], 'unchangedProtectedParts': 1371, 'scope': 'Retained earlier tests, not relabeled C08 reruns; all collider differences are sign boards/posts.'},
    'freshC08Checks': ['Native archive and label roundtrip', 'Live selector load with nine checkpoints', '32 of 32 labels scaled in Play and final Edit', '19 native visual captures; two close crops excluded from gallery', 'Unrelated Lobby, GrandArcade and palette fingerprints unchanged'],
    'temporaryUnlimitedTimerRestored': True, 'testHelpersStopped': True, 'published': False, 'wholePlaceSaved': False,
    'unverified': ['complete main route and finish', 'human route comprehension and difficulty', '20 simultaneous racers', '4–5 minute main / 2–3 minute skilled targets', 'device performance', 'owner acceptance'],
    'nativeGallery': 'NATIVE_PREVIEW.html', 'validation': 'NATIVE_VALIDATION.md'
}
(root / 'NATIVE_SUMMARY.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
review_links = ', '.join(f'[{role.lower()} {score}/10](reviews/{role}_C08_NATIVE_FINAL.md)' for role, score in scores.items())
status = f'''# Stud Garden closing — ready for owner review

**Installed C08 meets all three independent review thresholds:** {review_links}. These scores apply to the same current candidate; they do not establish full gameplay or multiplayer acceptance.

Open the [current native gallery](NATIVE_PREVIEW.html), [validation and limits](NATIVE_VALIDATION.md), or [machine-readable summary](NATIVE_SUMMARY.json).

## Latest requested change

Removed 25 physical sign boards and reduced 45 floor arrows to eight small cues at choices and less obvious turns. Nine checkpoint numbers are painted directly on the existing teal frames. Only two compact EXPERT markers, one THORNS cue, one building-mounted SEEDS label, smaller START/FINISH labels and the two functional timed-hazard displays remain. The scenery now carries more of the route's identity.

The formed tool family, planted separators, enlarged cultivated district, branching pink/aqua grove, dominant beanstalk and loaded harvest market remain installed. C08 has 7,035 parts, 4,141 colliders, 417 MeshParts and no embedded scripts. Its origin stays (1563,257,-1053), geometry **0ce5b9bd**, content **437cc43b**. Public course selection remains disabled.

## Checks and limits

Native archive readback preserved the geometry and all label settings. The actual Studio selector loaded C08 with nine checkpoints; all 32 current labels scale correctly in Play and final Edit. Nineteen native screenshots were inspected; the gallery excludes two close shots that cropped the status word. All 1,371 protected gameplay parts match the earlier tested version exactly. Independent comparison confirms every collider difference is a sign board or post.

Earlier C05 evidence remains valid for the unchanged tested surfaces: 32 selected real jumps, ten thorn recoveries, nine ordered checkpoint/recovery probes, both timed encounters, connected expert/basket segments and movement through the opening district to CP2. These are retained tests, not new C08 traversal runs.

**Still unverified:** complete main-route/finish traversal, human comprehension/difficulty, twenty simultaneous racers, device performance and the 4–5 minute main / 2–3 minute skilled targets. Independent review scores do not replace those tests or owner acceptance.

Studio is back in Edit. The temporary camera/HUD inspection and unlimited timer were restored; test helpers and backup receivers are stopped. Lobby, Grand Arcade and obstacle palette fingerprints match their earlier records. No publishing or whole-place save was performed.

## Recovery and history

- [Current C08 native archive](c08-native/sgv2-closing-c08-native.rbxm) and [install receipt](c08-native/native-install-receipt.json).
- [C06 recovery before sign reduction](c07-native/sgv2-c06-before-wayfinding-reduction.rbxm) and [exact reduction receipt](c07-native/native-install-receipt.json).
- [Protected gameplay comparison](c08-native/protected-geometry-result.json), [runtime check](c08-native/native-runtime-check.json) and [final Edit/preservation check](c08-native/native-final-edit.json).
- [Historical C05 status](CLOSING_STATUS_C05.md) and [detailed earlier physics record](NATIVE_VALIDATION_C05.md).
'''
(root / 'CLOSING_STATUS.md').write_text(status, encoding='utf-8')
validation = status.replace('# Stud Garden closing — ready for owner review', '# C08 native validation and evidence boundaries') + '''
## Label-layout correction

Native testing established that setting TextWrapped=false also disables TextScaled. The final native correction sets wrapping before scaling; all 28 minimal labels plus four unchanged timed-status faces retain correct scaling after export, reload and Play. C07's unsuccessful layout remains archived; only C08 receives the final scores.

## Manual follow-up tests

Use the existing Studio developer selector to load Stud Garden V2. Run the complete main route and both expert branches with normal controls, verify the ordered finish and moving camera, then test twenty racers and target devices. Check the two choice floors and both timed waits with the normal HUD visible. Treat timing as a measurement to collect, not a passed target.
'''
(root / 'NATIVE_VALIDATION.md').write_text(validation, encoding='utf-8')
old_html = (root / 'NATIVE_PREVIEW_C05.html').read_text(encoding='utf-8')
style = re.search(r'<style>(.*?)</style>', old_html, re.S).group(1)
manifest = json.loads((root / 'c08-native/views/capture-manifest.json').read_text())
cards = []
for view in manifest['views']:
    name = view['file']
    if name.startswith(('09-', '10-')):
        continue
    path = root / 'c08-native/views' / name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == view['sha256']
    title = name.rsplit('.', 1)[0][3:].replace('-', ' ').capitalize()
    link = path.relative_to(root).as_posix()
    cards.append(f'<figure><a href="{link}"><img src="{link}" alt="{html.escape(title)}" loading="lazy"></a><figcaption><div><h2>{html.escape(title)}</h2></div></figcaption></figure>')
gallery = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Stud Garden C08 — fewer signs</title><style>{style}</style></head><body><header><div class="eyebrow">Stud Garden / Current native Studio views</div><h1>Let the garden lead.</h1><span class="status">C08 · ART 8.7 · ROUTE 8.7 · MOVEMENT 8.6</span><p>25 boards removed. 45 arrows reduced to eight small cues. Painted checkpoint numbers, compact expert markers and useful live hazard signals remain. All three independent reviews pass the 8.5 threshold.</p><nav><a href="CLOSING_STATUS.md">Changes and limits</a><a href="NATIVE_VALIDATION.md">Evidence</a><a href="NATIVE_PREVIEW_C05.html">Historical C05</a></nav></header><main><div class="grid">{''.join(cards)}</div></main><footer><p>Actual C08 Play views, geometry0ce5b9bd/content437cc43b. The HUD was temporarily hidden for inspection. No scene or label changes were made in Play. Full-route completion, twenty-player behavior, target times, device performance and human acceptance remain unverified. Studio returned to Edit; no publishing or whole-place save.</p></footer></body></html>'''
(root / 'NATIVE_PREVIEW.html').write_text(gallery, encoding='utf-8')
state_file = root.parent / 'CURRENT_STATE.md'
state = state_file.read_text(encoding='utf-8')
boundary = state.index('## October 5 direct approval')
state_file.write_text('# Stud Garden V2 — current closing candidate\n\n' + status.replace('# Stud Garden closing — ready for owner review', '## October 5 — C08 ready for owner review').replace('](c08-native/', '](closing-20261005/c08-native/').replace('](c07-native/', '](closing-20261005/c07-native/').replace('](reviews/', '](closing-20261005/reviews/').replace('](NATIVE_', '](closing-20261005/NATIVE_').replace('](CLOSING_', '](closing-20261005/CLOSING_') + '\n## Historical installation and earlier directions\n\n' + state[boundary:], encoding='utf-8')
hold_file = root / 'INSTALLATION_HOLD.md'
hold = hold_file.read_text(encoding='utf-8')
if not hold.startswith('# Historical'):
    hold_file.write_text('# Historical approval holds — resolved\n\nThe owner subsequently directed “Make it hit 8.5 first before i review,” then explicitly requested removing or significantly reducing signs and arrows. C06 repair and C07/C08 reduction/layout work are installed and verified. There is no pending installation approval. See [current status](CLOSING_STATUS.md). The text below is preserved rejection history, not current instructions.\n\n' + hold, encoding='utf-8')
proposal_file = root / 'c06-native/REPAIR_PROPOSAL.json'
proposal = json.loads(proposal_file.read_text())
proposal.update(installed=True, status='Installed following direct owner instruction; superseded by C08 minimal wayfinding', currentCandidate='SGV2_Closing_C08')
proposal_file.write_text(json.dumps(proposal, indent=2) + '\n', encoding='utf-8')
offline_file = root / 'CLOSING_PREVIEW.html'
offline = offline_file.read_text(encoding='utf-8').replace('C05 OFFLINE DESIGN VIEWS · NOW INSTALLED; NATIVE SIGN REPAIR PENDING', 'HISTORICAL C05 DESIGN VIEWS · CURRENT C08 HAS REDUCED SIGNS').replace('C05 is now installed. Native testing found a sign-scaling defect; see the native evidence and exact remaining repair.', 'Current C08 has substantially fewer signs and arrows and passes all three independent reviews; see the native gallery.')
offline_file.write_text(offline, encoding='utf-8')
print('Current C08 summary, gallery and handoff saved; historical C05 records retained.')
