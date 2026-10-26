import hashlib
import json
import re
from pathlib import Path

base = Path('docs/artifacts/moonlit-citadel/phase2')
prior = base / 'MC_P2_R06_frozen_source_map06.json'
current = base / 'MC_P2_R06_frozen_source_map08b.json'
packet = json.loads(prior.read_text(encoding='utf-8-sig'))
allowed_changes = {
    'ServerScriptService/Services/CourseService',
    'ServerStorage/CourseBuilders/ManualObstaclePhases',
}
changes = []
for row in packet['sources']:
    raw = Path(row['sourcePath']).read_bytes()
    source = Path(row['sourcePath']).read_text(encoding='utf-8-sig')
    raw_hash = hashlib.sha256(raw).hexdigest()
    normalized_hash = hashlib.sha256(source.encode()).hexdigest()
    if raw_hash != row['sha256']:
        assert row['instancePath'] in allowed_changes, row['instancePath']
        changes.append({
            'path': row['instancePath'],
            'oldRawSha256': row['sha256'],
            'rawSha256': raw_hash,
            'oldNormalizedSha256': row['normalizedSha256'],
            'normalizedSha256': normalized_hash,
        })
    row.update(source=source, sha256=raw_hash, normalizedSha256=normalized_hash)
assert {row['path'] for row in changes} == allowed_changes
assert len(packet['sources']) == 240
assert not current.exists(), 'Preserve prior frozen inputs'
encoded = json.dumps(packet, ensure_ascii=False, separators=(',', ':')).encode()
current.write_bytes(encoded)
current_hash = hashlib.sha256(encoded).hexdigest()
installer = Path('tools/moonlit-citadel/phase2/R06OriginalInstall.luau').read_text()
critical = set(re.findall(r'\["([^"]+)"\]=true', installer))
critical.add('ServerScriptService/Services/CourseService')
bindings = [
    {'path': row['instancePath'], 'normalizedSha256': row['normalizedSha256']}
    for row in packet['sources'] if row['instancePath'] in critical
]
assert len(bindings) == 15
result = {'candidate': packet['candidate'], 'mapSha256': current_hash, 'sources': bindings}
receipt = {
    'candidate': packet['candidate'], 'sources': len(packet['sources']),
    'previous': {'path': str(prior), 'sha256': hashlib.sha256(prior.read_bytes()).hexdigest()},
    'current': {'path': str(current), 'sha256': current_hash, 'bytes': len(encoded)},
    'changes': changes,
    'limits': 'Raw file hashes and normalized Source hashes are distinct. CourseService adds the reviewed Play editing handoff. ManualObstaclePhases contains a concurrent clamp-default change already present in native Studio; root did not edit it. Moonlit contains zero generic phase hazards. Earlier source maps are preserved; unused map08 had stale normalized fields and is superseded by map08b. Temporary Tools03 are separately bound.',
}
(base / 'revision06' / 'FROZEN_SOURCE_MAP08B.json').write_text(json.dumps(receipt, indent=2))
(base / 'revision06' / 'ORIGINAL_CURRENT15_EXPECTED.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result))
