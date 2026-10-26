"""Compare saved course objects without inferring device performance."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path


def counts(data):
    parts = data['parts']
    return {
        'parts': len(parts),
        'visibleParts': sum(p['transparency'] < .99 for p in parts),
        'colliders': sum(p['collide'] for p in parts),
        'queryParts': sum(p['query'] for p in parts),
        'touchParts': sum(p['touch'] for p in parts),
        'meshParts': sum(p['class'] == 'MeshPart' for p in parts),
        'uniqueMeshNames': len({p['name'] for p in parts if p['class'] == 'MeshPart'}),
        'materialNames': dict(Counter(p['material'] for p in parts)),
        'shapes': dict(Counter(p['shape'] for p in parts)),
        'surfaceLabels': len(data['labels']),
        'hazards': dict(Counter(p['attributes']['HazardType'] for p in parts if 'HazardType' in p['attributes'])),
    }


parser = argparse.ArgumentParser()
parser.add_argument('geometry', type=Path)
parser.add_argument('baseline', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
data = json.loads(args.geometry.read_text())
baseline = json.loads(args.baseline.read_text())
current, before = counts(data), counts(baseline)
groups = {}
for p in data['parts']:
    path = p['path'].split('.')
    key = '.'.join(path[:2]) if path[0] in ('ClosingRoute', 'ClosingScenery', 'Obstacles') else path[0]
    groups.setdefault(key, {'parts': 0, 'colliders': 0, 'visible': 0})
    groups[key]['parts'] += 1
    groups[key]['colliders'] += int(p['collide'])
    groups[key]['visible'] += int(p['transparency'] < .99)
root = Path(__file__).resolve().parents[3]
route_spec = json.loads((root / 'docs/artifacts/stud-garden-v2/closing-20261005/route-spec.json').read_text())
removed = sum(p['triangles'] for p in route_spec['removeStudBatches'])
result = {
    'candidate': data['attributes']['CandidateId'], 'geometryFingerprint': data['fingerprint'],
    'geometrySha256': hashlib.sha256(args.geometry.read_bytes()).hexdigest(),
    'counts': current, 'baseline': before,
    'change': {key: current[key] - before[key] for key in ('parts', 'visibleParts', 'colliders', 'meshParts', 'surfaceLabels')},
    'groups': groups,
    'legacyPhase3ArtTriangles': {'before': 469888, 'removedObsoleteStuds': removed, 'retained': 469888 - removed},
    'limits': [
        'Object counts are measured from the saved native archive, not from an installed closing candidate.',
        'Mesh names are source identities, not proof of unique asset IDs or draw calls.',
        'Retained Phase3 triangle count excludes older reused kit meshes and new native primitive tessellation.',
        'Native primitive triangle counts, draw calls, live memory, loading, FPS and twenty-player/device results remain unmeasured.',
        'More parts and colliders are a measurable burden indicator. This report is not a performance pass.'
    ],
}
args.output.write_text(json.dumps(result, indent=2))
print(json.dumps({k: result[k] for k in ('candidate', 'counts', 'change', 'legacyPhase3ArtTriangles')}))
