from pathlib import Path
import hashlib
import json

base = Path('docs/artifacts/moonlit-citadel/phase2')
prior = base / 'MC_P2_R06_original_tools03.json'
raw = prior.read_bytes()
assert hashlib.sha256(raw).hexdigest() == 'bb83854da021050fde4c09177350de7546f7c381e2deda4420b48b2969a5a6df'
packet = json.loads(raw)
candidate = base / 'revision06/review_route/R06ClientProbe_hurdle_settle_candidate01.luau'
source = candidate.read_text(encoding='utf-8')
digest = hashlib.sha256(source.encode()).hexdigest()
assert digest == '9abf2a91d97f4ca53c654113133610c6c7f87f162018018e97f0f21aeb9110e5'
changes = []
for row in packet['sources']:
    row['previousSha256'] = row['sha256']
    if row['instancePath'] == 'ReplicatedStorage/MoonlitPhase2Tools/R06ClientProbe':
        changes.append({'path': row['instancePath'], 'before': row['sha256'], 'after': digest})
        row.update(source=source, sha256=digest, file=str(candidate))
assert len(changes) == 1 and len(packet['sources']) == 11
packet['parentPacketSha256'] = hashlib.sha256(raw).hexdigest()
packet['kind'] = 'Temporary original-place diagnostics with ordinary supported hurdle settling and unchanged tools03 guards'
path = base / 'MC_P2_R06_original_tools04.json'
assert not path.exists()
path.write_text(json.dumps(packet, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
receipt = {'candidate': packet['candidate'], 'packet': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
           'bytes': path.stat().st_size, 'changes': changes, 'sourceCount': 11, 'unchangedSources': 10, 'nativeProof': False}
(base / 'revision06/TOOLS04_PREPARATION.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(receipt))
