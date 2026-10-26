"""Compare both saved Blender scenes and the exact nine-mesh export."""
import hashlib
import json
from pathlib import Path

import bpy
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/artifacts/stud-garden-v2/phase3'
OUT = BASE / 'f04'
manifest = json.loads((OUT / 'manifest.json').read_text())


def snapshot(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    result = {}
    for obj in bpy.context.scene.objects:
        value = dict(type=obj.type, transform=[list(row) for row in obj.matrix_world],
                     hidden=[obj.hide_render, obj.hide_viewport])
        if obj.type == 'MESH':
            geometry = dict(vertices=[list(v.co) for v in obj.data.vertices],
                            faces=[list(p.vertices) for p in obj.data.polygons],
                            materials=[m.name if m else None for m in obj.data.materials])
            value['geometrySha256'] = hashlib.sha256(json.dumps(geometry, sort_keys=True).encode()).hexdigest()
        result[obj.name] = value
    return result


before = snapshot(BASE / 'f03/SGV2_Phase3_F03.blend')
after = snapshot(OUT / 'SGV2_Phase3_F04.blend')
hidden = {name for row in manifest['meshes'] for name in row['hiddenOffline']}
assert len(hidden) == 9
changes = []
for name, value in before.items():
    expected = dict(value)
    if name in hidden:
        expected['hidden'] = [True, True]
    if after.get(name) != expected:
        changes.append(name)
added = sorted(set(after)-set(before))
assert not changes, changes
assert added == sorted(r['name'] for r in manifest['meshes'])
assert all(abs(r['originalTop']-r['replacementTop']) < .00001 for r in manifest['meshes'])
assert hashlib.sha256((OUT / 'SGV2_Phase3_F04_Knots.fbx').read_bytes()).hexdigest() == manifest['fbxSha256']

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(OUT / 'SGV2_Phase3_F04_Knots.fbx'))
bounds_errors = []
for row in manifest['meshes']:
    obj = bpy.data.objects[row['name']]
    vertices = [obj.matrix_world @ v.co for v in obj.data.vertices]
    points = np.array([(v.x, v.z, -v.y) for v in vertices])
    expected = np.array(row['exportBoundsRoblox'])
    actual = np.array((points.min(axis=0), points.max(axis=0)))
    bounds_errors.append(float(np.max(np.abs(actual-expected))))
assert max(bounds_errors) < .001
assert len(bpy.context.scene.objects) == 13
result = dict(candidate=manifest['candidate'], sourceObjects=len(before), addedMeshes=added,
    intentionalHiddenSourceObjects=sorted(hidden), unexpectedSourceChanges=changes,
    removedSourceObjects=sorted(set(before)-set(after)), fbxReimportBoundsMaximumError=max(bounds_errors),
    maximumConvexPlaneError=max(r['convexPlaneError'] for r in manifest['meshes']),
    exactCrestHeights=True, originalCylinderContainment=True, totalNewTriangles=manifest['addedTriangles'],
    uploadState='blocked_by_automatic_approval_review', nativeInstalled=False,
    limits='Offline geometry and file checks only. Native import, Hull collision, raycasts and all final reviews remain pending.')
(OUT / 'offline-checks.json').write_text(json.dumps(result, indent=2))
(OUT / 'source/audit_phase3_knots.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps(result), flush=True)
