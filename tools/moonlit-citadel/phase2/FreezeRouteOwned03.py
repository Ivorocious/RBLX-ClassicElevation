from pathlib import Path
import hashlib
import json

base = Path('docs/artifacts/moonlit-citadel/phase2')
old = base / 'MC_P2_R06_route_commands02.json'
assert hashlib.sha256(old.read_bytes()).hexdigest() == '60b8ec3370869f7ea5c77647ecc593cec7666ac2ff77f6578ba58f2d6c269089'
packet = json.loads(old.read_text())
relay_path = base / 'revision06/review_runtime/native_relay02/MC_P2_R06_native_relay02.json'
assert hashlib.sha256(relay_path.read_bytes()).hexdigest() == '98edf728903d6841e8a27c8ecc97a7dd5b765f32071a0ad8fac0d5f5c731c2c0'
relay = json.loads(relay_path.read_text())
metadata = {Path(row['originalFile']).name: row for row in relay['sources'] if row['kind'] == 'ownership-state-metadata-only-copy'}
changes = []
for row in packet['scripts']:
    name = Path(row['path']).name
    if name not in metadata:
        continue
    new = metadata[name]
    assert row['normalizedSha256'] == new['previousSha256']
    source = Path(new['file']).read_text(encoding='utf-8')
    digest = hashlib.sha256(source.encode()).hexdigest()
    assert digest == new['sha256']
    changes.append({'target': row['target'], 'before': row['normalizedSha256'], 'after': digest})
    row.update(path=new['file'], source=source, rawSha256=digest, normalizedSha256=digest)
assert len(changes) == 3
packet['parentPacketSha256'] = hashlib.sha256(old.read_bytes()).hexdigest()
packet['metadataOnlyChanges'] = changes
out = base / 'MC_P2_R06_route_commands03.json'
assert not out.exists()
encoded = (json.dumps(packet, indent=2, ensure_ascii=False) + '\n').encode()
out.write_bytes(encoded)
source_path = Path('tools/moonlit-citadel/phase2/InstallRouteCommands.luau')
installer = source_path.read_text().replace('MC_P2_R06_route_commands02.json', 'MC_P2_R06_route_commands03.json')
destination = source_path.with_name('InstallRouteOwned03.luau')
assert not destination.exists()
destination.write_text(installer, encoding='utf-8')
receipt = {'candidate': packet['candidate'], 'packet': str(out), 'sha256': hashlib.sha256(encoded).hexdigest(), 'bytes': len(encoded), 'changes': changes,
           'installer': str(destination), 'behaviorChanges': False, 'nativeProof': False}
(base / 'revision06/ROUTE_OWNED03_PREPARATION.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(receipt))
