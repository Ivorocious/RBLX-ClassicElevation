"""Check final shelf walking vertices and forest envelopes against the preserved kit."""
import bpy, json
from pathlib import Path

task_root = Path(__file__).resolve().parent
names = ('HA_ShelfWideB', 'HA_ShelfWideC')
walking = {name: [tuple(bpy.data.objects[name].data.vertices[i].co) for i in (*range(28), 84)] for name in names}
current = json.loads((task_root / 'asset-manifest.json').read_text())
previous = json.loads((task_root / 'HA04-before-final-form-manifest.json').read_text())
old_rows = {row['name']: row for row in previous['objects']}
checks = []
for row in current['objects']:
    old = old_rows[row['name']]
    assert row['triangles'] == old['triangles']
    if row['name'] in names or row['name'].startswith('HA_Forest'):
        delta = max(abs(row[key][axis] - old[key][axis]) for key in ('bounds_min', 'bounds_max') for axis in (0, 1))
        assert delta < .00001, (row['name'], delta)
        checks.append({'name': row['name'], 'horizontalBoundDelta': delta, 'triangles': row['triangles']})
old_source = (task_root / 'HA04-before-final-form-build.py').read_text().split('for package,objs in packages.items():')[0]
exec(old_source, globals())
for name in names:
    original = [tuple(bpy.data.objects[name].data.vertices[i].co) for i in (*range(28), 84)]
    delta = max(abs(a - b) for left, right in zip(walking[name], original) for a, b in zip(left, right))
    assert delta == 0, (name, delta)
    checks.append({'name': name, 'walkingVertices': len(original), 'maxWalkingVertexDifference': delta})
report = {'candidate': 'HA_V1_04', 'passed': True, 'sourceTriangles': current['triangles'], 'checks': checks,
          'scope': 'Exact source shelf walking vertices and horizontal normalization bounds; native collision and play checks remain separate.'}
(task_root / 'form-geometry-checks.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
