from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parents[3]
label = sys.argv[1]
assert label.isalnum()
base = root / 'docs/artifacts/moonlit-citadel/phase2'
receipt = json.loads((base / f'MC_P2_C01_R06_recovery{label}_recovery_receipt.json').read_text())
rows = []
for entry in receipt['sources']:
    data = (root / entry['sourcePath']).read_bytes()
    assert hashlib.sha256(data).hexdigest() == entry['sha256']
    source = data.decode('utf-8-sig').replace('\r\n', '\n')
    rows.append({**entry, 'source': source, 'bytes': len(source.encode()),
                 'normalizedSha256': hashlib.sha256(source.encode()).hexdigest()})
output = base / f'MC_P2_R06_frozen_source_map{label}.json'
assert not output.exists()
output.write_text(json.dumps({'candidate': 'MC_P2_C01_R06', 'sources': rows}), encoding='utf-8')
print(json.dumps({'sources': len(rows), 'path': str(output), 'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}))
