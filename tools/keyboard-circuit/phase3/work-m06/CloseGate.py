from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
artifacts = root / 'docs/artifacts/keyboard-circuit/phase3'
freeze = artifacts / 'P3-M06-CANDIDATE-FREEZE-01.json'
freeze_hash = hashlib.sha256(freeze.read_bytes()).hexdigest()
assert freeze_hash == 'c4a93973484e4fcdd77f0f565cbb6acda4354a5b68f7da9ebe0fc151b235fa48'
candidate = json.loads(freeze.read_bytes())
for row in candidate['inputs']:
    data = (root / row['path']).read_bytes()
    assert len(data) == row['bytes'] and hashlib.sha256(data).hexdigest() == row['sha256'], row['path']
reviews = []
for name in ['R1', 'R2', 'R3']:
    path = artifacts / 'reviews-m06' / (name + '.json')
    review = json.loads(path.read_bytes())
    assert review['model'] == 'gpt-6.1-sol' and review['effort'] == 'high'
    assert review['revision'] == 'KC_P3_M06_01' and review['freezeSha256'] == freeze_hash
    assert review['overallScore'] >= 8.5 and review['blockers'] == []
    markdown = path.with_suffix('.md')
    assert markdown.is_file() and markdown.stat().st_size > 0
    reviews.append({'reviewer': review['reviewer'], 'score': review['overallScore'], 'blockers': 0, 'jsonSha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'markdownSha256': hashlib.sha256(markdown.read_bytes()).hexdigest()})
agreement = json.loads((artifacts / 'P3-M06-post-review-agreement-01.json').read_bytes())
assert agreement['passed'] and agreement['mode'] == 'Edit' and agreement['sourceCount'] == 17
assert agreement['alternateTriggers'] == 25 and agreement['checkpointCount'] == 8 and agreement['laps'] == 2
native = (artifacts / 'KC_P3_M06_01_Native.rbxm').read_bytes()
post_native = (artifacts / 'KC_P3_M06_01_PostReview.rbxm').read_bytes()
assert post_native == native, 'Native checkpoint repair changed after review'
native_test = json.loads((artifacts / 'P3-M06-native-expert-01.json').read_bytes())
assert native_test['passed'] and len(native_test['checkpoints']) == 16 and len(native_test['jumps']) == 46
assert len(native_test['recoveries']) == 2 and len(native_test['laps']) == 2
assert native_test['laps'][-1]['Status'] == 'Status: Finished' and native_test['laps'][-1]['Placement'] == 'Placement: #1'
result = {'passed': True, 'revision': 'KC_P3_M06_01', 'freezeSha256': freeze_hash, 'frozenInputsVerified': len(candidate['inputs']), 'reviews': reviews, 'postReviewSourcesMatched': 17, 'postReviewNativeBytesEqual': True, 'nativeBytes': len(native), 'nativeSha256': hashlib.sha256(native).hexdigest(), 'alternateTriggers': 25, 'nativeExpertJumps': 46, 'nativeCheckpointConfirmations': 16, 'nativeAssertedExpertRecoveries': 2, 'nativeHudFinished': True, 'studioMode': 'Edit', 'computerControl': False, 'published': False, 'limits': 'Focused checkpoint correction. Other encounter setup is staged; no full-course timing, zero-fall, human pacing/difficulty or crowd/device/FPS claim. The later observer is not a completed-results payload.'}
(artifacts / 'P3-M06-FINAL-GATE-01.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result))
