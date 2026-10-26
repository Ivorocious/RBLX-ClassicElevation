import hashlib
import json
from pathlib import Path

base = Path('docs/artifacts/moonlit-citadel/phase2')
prior = base / 'MC_P2_R06_frozen_source_map08b.json'
current = base / 'MC_P2_R06_frozen_source_map09.json'
packet = json.loads(prior.read_text(encoding='utf-8-sig'))
changes = []
for row in packet['sources']:
    raw = Path(row['sourcePath']).read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    if digest == row['sha256']:
        continue
    assert row['instancePath'] == 'ServerStorage/CourseBuilders/MoonlitCitadelCourse/Wayfinding'
    source = Path(row['sourcePath']).read_text(encoding='utf-8-sig')
    normalized = hashlib.sha256(source.encode()).hexdigest()
    changes.append({'path': row['instancePath'], 'before': row['normalizedSha256'], 'after': normalized})
    row.update(source=source, sha256=digest, normalizedSha256=normalized)
assert len(changes) == 1
assert not current.exists()
encoded = json.dumps(packet, ensure_ascii=False, separators=(',', ':')).encode()
current.write_bytes(encoded)
digest = hashlib.sha256(encoded).hexdigest()
guard_path = base / 'revision06' / 'ORIGINAL_CURRENT15_EXPECTED.json'
guards = json.loads(guard_path.read_text())
old_guards = base / 'revision06' / 'ORIGINAL_CURRENT15_EXPECTED_BEFORE_CUES09.json'
assert not old_guards.exists()
old_guards.write_bytes(guard_path.read_bytes())
guards['mapSha256'] = digest
for row in guards['sources']:
    if row['path'] == changes[0]['path']:
        row['normalizedSha256'] = changes[0]['after']
guard_path.write_text(json.dumps(guards, indent=2))
receipt = {'candidate': packet['candidate'], 'sources': len(packet['sources']),
           'path': str(current), 'sha256': digest, 'bytes': len(encoded), 'changes': changes}
(base / 'revision06' / 'FROZEN_SOURCE_MAP09.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(guards))
