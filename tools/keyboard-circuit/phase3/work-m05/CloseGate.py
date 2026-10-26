from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
artifacts = root / 'docs/artifacts/keyboard-circuit/phase3'
freeze = artifacts / 'P3-M05-CANDIDATE-FREEZE-01.json'
freeze_hash = hashlib.sha256(freeze.read_bytes()).hexdigest()
assert freeze_hash == 'f4517e62ccf4e96788b0dfad0ea034f7582004854d18589cf2ee62d6e5f19c34'
candidate = json.loads(freeze.read_bytes())
for row in candidate['inputs']:
    data = (root / row['path']).read_bytes()
    assert len(data) == row['bytes'] and hashlib.sha256(data).hexdigest() == row['sha256'], row['path']
reviews = []
for name in ['R1', 'R2', 'R3']:
    path = artifacts / 'reviews-m05' / (name + '.json')
    review = json.loads(path.read_bytes())
    assert review['model'] == 'gpt-6.1-sol' and review['effort'] == 'high'
    assert review['revision'] == 'KC_P3_M05_01' and review['freezeSha256'] == freeze_hash
    assert review['overallScore'] >= 8.5 and review['blockers'] == []
    markdown = path.with_suffix('.md')
    assert markdown.is_file() and markdown.stat().st_size > 0
    reviews.append({'reviewer': review['reviewer'], 'score': review['overallScore'], 'blockers': 0, 'jsonSha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'markdownSha256': hashlib.sha256(markdown.read_bytes()).hexdigest()})
agreement = json.loads((artifacts / 'P3-M05-post-review-agreement-01.json').read_bytes())
assert agreement['passed'] and agreement['mode'] == 'Edit' and agreement['sourceCount'] == 17
assert agreement['removedRootsAbsent'] == 10 and agreement['checkpointCount'] == 8 and agreement['laps'] == 2
native = (artifacts / 'KC_P3_M05_01_Native.rbxm').read_bytes()
post_native = (artifacts / 'KC_P3_M05_01_PostReview.rbxm').read_bytes()
assert post_native == native, 'Native template changed after independent review'
final_check = json.loads((artifacts / 'P3-M05-final-check-01.json').read_bytes())
assert final_check['passed'] and final_check['comparedRows'] == 16750
cleanup = json.loads((artifacts / 'm05-recovery/CleanupReceipt.json').read_bytes())
assert cleanup['finished'] and cleanup['instancesRemoved'] == 1041920 and len(cleanup['removed']) == 10
result = {
    'passed': True, 'revision': 'KC_P3_M05_01', 'freezeSha256': freeze_hash,
    'frozenInputsVerified': len(candidate['inputs']), 'reviews': reviews,
    'postReviewSourcesMatched': 17, 'postReviewNativeBytesEqual': True,
    'nativeBytes': len(native), 'nativeSha256': hashlib.sha256(native).hexdigest(),
    'nativeRebuildRows': final_check['comparedRows'], 'removedOldInstances': cleanup['instancesRemoved'],
    'studioMode': 'Edit', 'computerControl': False, 'published': False,
    'limits': 'Scoped local integration/cleanup gate. Native staged progression is not continuous traversal timing. Human visible appearance/audio, pacing/difficulty, multiplayer/crowd/device/FPS and two final native lap sweeps remain unclaimed.'
}
(artifacts / 'P3-M05-FINAL-GATE-01.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result))
