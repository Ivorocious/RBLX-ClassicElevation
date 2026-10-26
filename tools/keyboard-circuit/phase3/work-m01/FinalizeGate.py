from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[4]
FOLDER = ROOT / 'docs/artifacts/keyboard-circuit/phase3'

def read(name):
    return json.loads((FOLDER / name).read_text(encoding='utf-8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def evidence(name):
    path = FOLDER / name
    return {'path': name, 'sha256': sha(path), 'bytes': path.stat().st_size}

freeze_name = 'P3-M01-source-freeze-02.json'
freeze = read(freeze_name)
freeze_sha = sha(FOLDER / freeze_name)
assert freeze_sha == 'fe236e5a23a27494a8e8ab87da81289f3ee394202cf693e4d4f6f93434a5a815'
assert freeze['count'] == len(freeze['entries']) == 114
for row in freeze['entries']:
    path = ROOT / row['path']
    assert sha(path) == row['sha256'] and path.stat().st_size == row['bytes'], row['path']

post = read('P3-M01-post-review-edit-agreement-01.json')
pre = read('P3-M01-native-source-agreement-01.json')
assert post['passed'] and post['datamodel'] == 'Edit'
assert post['candidate'] == pre['candidate'] and post['revision'] == pre['revision']
assert post['origin'] == pre['origin'] == [2222,330,-1158] and post['descendants'] == pre['descendants'] == 14893
assert post['rows'] == pre['rows'] and post['unrelated'] == pre['unrelated']
assert len(post['active']) == 1 and len(post['archived']) == 13 and post['archivedScriptsDisabled']

reviews = []
for number,role,agent in [(1,'visual','/root/kc_i09_r1_visual'),(2,'route','/root/kc_i08_r2_route'),
                          (3,'hazards','/root/kc_i08_r3_hazards'),(4,'experience','/root/kc_i09_r4_experience'),
                          (5,'engineering','/root/kc_i08_r5_engineering')]:
    name = f'reviews/M01-R{number}-{role}.json'
    review = read(name)
    score = review.get('overallScore', review.get('score'))
    reviewer = review['reviewer']
    assert (reviewer == agent or re.match(r'^R' + str(number) + r'\b', reviewer)) and review['model'] == 'gpt-6.1-sol'
    assert review.get('reasoning', review.get('reasoningEffort')) == 'high'
    assert review['candidate'] == 'Workspace.KeyboardCircuit_P3_M01_01' and review['revision'] == 'KC_P3_M01_01'
    assert review['mapRevision'] == 'KC_MAP_M01_01' and review['layout'] == 'KC_LAYOUT_P2_I09_03'
    assert review['sourceFreeze'].endswith(freeze_name) and review['sourceFreezeSha256'] == freeze_sha
    assert score >= 8.5 and not review['blockers'] and review.get('blockerCount', 0) == 0 and review['passed']
    assert review.get('decision', 'pass').lower().startswith('pass')
    reviews.append({'reviewer': f'R{number}', 'agent': agent, 'role': role, 'model': 'gpt-6.1-sol', 'reasoning': 'high',
                    'score': score, 'blockers': 0, 'json': evidence(name), 'markdown': evidence(name.replace('.json','.md')),
                    'sourceFreezeSha256': freeze_sha})

for name in ['normal','expert']:
    summary = read(f'P3-M01-{name}-two-lap-summary-01.json')
    assert summary['passed'] and summary['requiredLaps'] == 2 and summary['naturalGates'] == 10 and summary['naturalMidpoints'] == 8
    assert summary['setupCalls'] == 1 and summary['recoveries'] == 0 and summary['fixtureHoldSeconds'] == 0
    assert sha(FOLDER / summary['rawTrace']) == summary['rawSha256']
assert read('P3-M01-route-comparison-01.json')['passed']
focused = read('P3-M01-focused-native-01.json')
assert all(focused[key]['passed'] for key in ['recovery','expert','bypass','domino','heldPress','devControl'])
assert focused['readinessAudio']['feedback']['readiness']['loaded'] == 8
native = read('P3-M01-native-recovery-01.json')
assert native['roundTrip']['passed'] and native['freshSourceRebuild']['passed']
assert sha(FOLDER / 'native/KC_P3_M01_01.rbxm') == native['nativeSha256']
assert native['courseBytes'] == (FOLDER / 'native/KC_P3_M01_01.rbxm').stat().st_size == 203233
assert read('P3-M01-integration-audit-01.json')['geometryPassed']
assert read('P3-M01-integration-audit-01.json')['bodyClearancePassed']
for name in ['motion-clearance','visibility-audit','cost-audit','scope-preservation','baseline-preservation','cleanup']:
    data = read(f'P3-M01-{name}-01.json')
    assert data.get('passed', data.get('pass', False)), name
assert read('P3-M01-server-evidence-01.json')['slots']['passed']
offline = read('P3-M01-offline-geometry-01.json')
assert offline['artParts'] == 621 and offline['artCaps'] == 102 and offline['branchCount'] == 2 and offline['normalEdges'] == 25

files = [freeze_name,'P3-M01-freeze-agreement-02.json','P3-M01-REVIEW-BRIEF-01.md',
         'P3-M01-native-source-agreement-01.json','P3-M01-post-review-edit-agreement-01.json',
         'P3-M01-normal-two-lap-01.json','P3-M01-expert-two-lap-01.json',
         'P3-M01-normal-two-lap-summary-01.json','P3-M01-expert-two-lap-summary-01.json',
         'P3-M01-route-comparison-01.json','P3-M01-checkpoint-cadence-01.json',
         'P3-M01-focused-native-01.json','P3-M01-server-evidence-01.json',
         'P3-M01-integration-audit-01.json','P3-M01-motion-clearance-01.json','P3-M01-visibility-audit-01.json',
         'P3-M01-cost-audit-01.json','P3-M01-native-recovery-01.json','P3-M01-baseline-preservation-01.json',
         'P3-M01-scope-preservation-01.json','P3-M01-cleanup-01.json','P3-M01-offline-geometry-01.json','P3-M01-enter-coverage-correction-02.json','native/KC_P3_M01_01.rbxm']
result = {'passed': True, 'candidate': 'Workspace.KeyboardCircuit_P3_M01_01', 'revision': 'KC_P3_M01_01',
          'mapRevision': 'KC_MAP_M01_01','layout': 'KC_LAYOUT_P2_I09_03','requiredLaps': 2,
          'sourceFreeze': freeze_name,'sourceFreezeSha256': freeze_sha,'frozenInputs': 114,'installedSources': 23,
          'reviewers': reviews, 'evidence': [evidence(name) for name in files], 'studioMode': 'Edit',
          'activeCourses': 1, 'inertOlderCourses': 13, 'nativeSha256': native['nativeSha256'],
          'normalContinuousSeconds': read('P3-M01-normal-two-lap-summary-01.json')['continuousSeconds'],
          'expertContinuousSeconds': read('P3-M01-expert-two-lap-summary-01.json')['continuousSeconds'],
          'boundary': 'Local Phase 3 technical/artwork gate on the same frozen final candidate, five independent scores without averaging or inheritance. Owner acceptance, typical-human pacing, subjective audio/difficulty, exhaustive shortcut proof, close native rendering, real crowd/device/FPS proof and publication are separate.'}
(FOLDER / 'P3-M01-FINAL-GATE-01.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':True,'scores':[row['score'] for row in reviews],'sourceFreezeSha256':freeze_sha,'nativeSha256':native['nativeSha256']}))
