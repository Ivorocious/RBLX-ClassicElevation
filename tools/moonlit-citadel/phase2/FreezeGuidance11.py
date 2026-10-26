import hashlib
import json
from pathlib import Path

base = Path('docs/artifacts/moonlit-citadel/phase2')
prior = base / 'MC_P2_R06_frozen_source_map10.json'
current = base / 'MC_P2_R06_frozen_source_map11.json'
packet = json.loads(prior.read_text(encoding='utf-8-sig'))
changes = []
for row in packet['sources']:
    raw = Path(row['sourcePath']).read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    if digest == row['sha256']:
        continue
    assert row['instancePath'] == 'ServerStorage/CourseBuilders/MoonlitCitadelCourse/Wayfinding'
    source = raw.decode('utf-8-sig').replace('\r\n', '\n')
    normalized = hashlib.sha256(source.encode()).hexdigest()
    changes.append({'path': row['instancePath'], 'before': row['normalizedSha256'], 'after': normalized})
    row.update(source=source, sha256=digest, normalizedSha256=normalized)
assert len(changes) == 1 and len(packet['sources']) == 240
assert not current.exists()
encoded = json.dumps(packet, ensure_ascii=False, separators=(',', ':')).encode()
current.write_bytes(encoded)
digest = hashlib.sha256(encoded).hexdigest()
guard_path = base / 'revision06' / 'ORIGINAL_CURRENT15_EXPECTED.json'
guards = json.loads(guard_path.read_text())
old_guards = guard_path.with_name('ORIGINAL_CURRENT15_EXPECTED_BEFORE_GUIDANCE11.json')
assert not old_guards.exists()
old_guards.write_bytes(guard_path.read_bytes())
guards['mapSha256'] = digest
for row in guards['sources']:
    if row['path'] == changes[0]['path']:
        row['normalizedSha256'] = changes[0]['after']
guard_path.write_text(json.dumps(guards, indent=2))
source_row = next(row for row in packet['sources'] if row['instancePath'] == changes[0]['path'])
source_packet = base / 'MC_P2_R06_guidance11.json'
assert not source_packet.exists()
payload = {'candidate': packet['candidate'], 'source': source_row['source'], 'normalizedSha256': changes[0]['after'], 'priorNormalizedSha256': changes[0]['before']}
source_packet.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
receipt = {'candidate': packet['candidate'], 'sources': len(packet['sources']), 'path': str(current), 'sha256': digest, 'bytes': len(encoded), 'changes': changes,
           'packet': str(source_packet), 'packetSha256': hashlib.sha256(source_packet.read_bytes()).hexdigest()}
(base / 'revision06' / 'FROZEN_SOURCE_MAP11.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(receipt))
