"""Compare the twelve captured Studio Edit sources with their durable files."""
from pathlib import Path
import hashlib
import json
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--candidate', default='HA_V1_03', choices=('HA_V1_03', 'HA_V1_04'))
args = parser.parse_args()
tag = 'ha04' if args.candidate == 'HA_V1_04' else 'ha03'

root = Path(__file__).resolve().parents[1]
reference = json.loads((root / 'docs/artifacts/heartwood-ascent/v1/source-sync-HA_V1_02.json').read_text())
native = json.loads((root / f'.tools/{tag}-native-source-text.json').read_text())
rows = []
for previous in reference['sources']:
    path = previous['path']
    source = (root / path).read_text().replace('\r\n', '\n')
    captured = native['sources'].get(path)
    same = isinstance(captured, str) and source == captured.replace('\r\n', '\n')
    rows.append({'path': path, 'nativeMatch': same, 'sha256': hashlib.sha256(source.encode()).hexdigest(), 'bytes': len(source.encode())})
report = {'candidate': args.candidate, 'matched': all(x['nativeMatch'] for x in rows), 'sources': rows,
          'testStarterPresent': native.get('testStarterPresent'), 'verificationEnabled': native.get('verificationEnabled'),
          'scope': 'LF-normalized comparison with native Edit source, captured after candidate assembly'}
(root / f'docs/artifacts/heartwood-ascent/v1/source-sync-{args.candidate}.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'matched': report['matched'], 'sources': len(rows), 'failures': [x['path'] for x in rows if not x['nativeMatch']]}))
assert report['matched'], 'Wait for Rojo synchronization before freezing the candidate'
