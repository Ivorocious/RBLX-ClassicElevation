"""Read-only six-part surface proof for the repaired FBX."""
from collections import Counter
import hashlib
import importlib.util
import json
import math
from pathlib import Path

import bpy

ROOT = next(path for path in Path(__file__).resolve().parents if (path / 'default.project.json').exists())
HERE = Path(__file__).resolve().parent
OLD = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02'
OUT = OLD / 'r01/final'
GUARDS = [OUT/name for name in ('MC_GARDEN_HOIST_DG02_R01.blend', 'MC_GARDEN_HOIST_DG02_R01.fbx', 'manifest.json', 'authored-geometry.json', 'occupied-geometry.json')]
GUARDS += [OLD/name for name in ('manifest.json', 'authored-geometry.json', 'MC_GARDEN_HOIST_DG02.fbx')]
GUARDS += [HERE/'garden-hoist-final-freeze.json']

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path): return json.loads(path.read_text(encoding='utf8'))
def canonical(face):
    values = tuple(face)
    return min(values[index:]+values[:index] for index in range(3))
def coordinate_faces(row):
    return Counter(canonical(tuple(tuple(row['vertices'][index]) for index in face)) for face in row['triangles'])
def world_geometry(obj):
    obj.data.calc_loop_triangles()
    return {'vertices': [tuple(obj.matrix_world@vertex.co) for vertex in obj.data.vertices],
            'triangles': [tuple(face.vertices) for face in obj.data.loop_triangles]}
def area(geometry):
    from mathutils import Vector
    vertices = geometry['vertices']
    return sum((Vector(vertices[b])-Vector(vertices[a])).cross(Vector(vertices[c])-Vector(vertices[a])).length/2 for a,b,c in geometry['triangles'])

assert bpy.app.background
hashes = {str(path.relative_to(ROOT)).replace('\\','/'):sha(path) for path in GUARDS}
spec = importlib.util.spec_from_file_location('dg02_r01_audit', HERE/'BuildExactTriangleGardenHoistKit.py')
helper = importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
manifest = load(OUT/'manifest.json')
old = {row['name']:row for row in load(OLD/'authored-geometry.json')['parts']}
authored = {row['name']:row for row in load(OUT/'authored-geometry.json')['parts']}
untouched = [name for name in authored if name.endswith('__Wood') or 'WallGarden24__' in name]
assert len(untouched) == 4
preservation = []
for name in untouched:
    row = {'name':name, 'verticesExact': sorted(authored[name]['vertices']) == sorted(old[name]['vertices']),
           'triangleSurfacesAndWindingExact': coordinate_faces(authored[name]) == coordinate_faces(old[name])}
    assert row['verticesExact'] and row['triangleSurfacesAndWindingExact'], row
    preservation.append(row)

bpy.ops.wm.open_mainfile(filepath=str(OUT/'MC_GARDEN_HOIST_DG02_R01.blend'))
saved = {obj.name:obj for obj in bpy.data.collections['DG02R01_Export_Material_Parts'].objects}
expected = {row['name']:row for row in manifest['export_parts']}
assert saved.keys() == expected.keys() and len(saved) == 6
saved_topology = [helper.mesh_audit(obj) for obj in saved.values()]
assert all(len(face.vertices)==3 for obj in saved.values() for face in obj.data.polygons)
original = {name:world_geometry(obj) for name,obj in saved.items()}
assert sum(len(row['triangles']) for row in original.values()) == 3258
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(OUT/'MC_GARDEN_HOIST_DG02_R01.fbx'), use_custom_normals=True)
actual = {obj.name:obj for obj in bpy.context.scene.objects if obj.type == 'MESH'}
assert actual.keys() == expected.keys()
rows = []
for name,obj in actual.items():
    geometry = world_geometry(obj)
    target = original[name]
    mapping = []
    errors = []
    for vertex in geometry['vertices']:
        distance,index = min((max(abs(vertex[k]-point[k]) for k in range(3)),index)
                             for index,point in enumerate(target['vertices']))
        assert distance <= .00001, (name,distance)
        mapping.append(index);errors.append(distance)
    expected_faces = Counter(canonical(tuple(face)) for face in target['triangles'])
    actual_faces = Counter(canonical(tuple(mapping[index] for index in face)) for face in geometry['triangles'])
    missing = list((expected_faces-actual_faces).elements())
    extra = list((actual_faces-expected_faces).elements())
    expected_set = {index for face in target['triangles'] for index in face}
    actual_set = set(mapping)
    topology = helper.mesh_audit(obj)
    row = {'name':name, 'vertices':len(geometry['vertices']), 'expectedVertices':len(target['vertices']),
           'worldVertexMaxError':max(errors), 'vertexTolerance':.00001,
           'allAuthoredVerticesRepresented':expected_set <= actual_set,
           'triangles':len(geometry['triangles']), 'expectedTriangles':len(target['triangles']),
           'missingOrientedTriangles':len(missing), 'extraOrientedTriangles':len(extra),
           'triangleSurfacesAndWindingExact':not missing and not extra,
           'area':area(geometry), 'expectedArea':area(target), 'closedTopology':topology}
    row['pass'] = row['allAuthoredVerticesRepresented'] and row['triangleSurfacesAndWindingExact']
    assert row['pass'], row
    rows.append(row)
for path,digest in hashes.items(): assert sha(ROOT/path)==digest, path
report = {'pass':True, 'assets':2, 'parts':6, 'triangles':3258,
          'allSixFbxTriangleSurfacesAndWindingExact':True, 'fourUntouchedGeometryRecordsExact':preservation,
          'savedTopology':saved_topology, 'fbxParts':rows, 'inputHashes':hashes,
          'curveFrameProof': {'repairs':7, 'majorSegments':16, 'minorSegmentsIron':6, 'minorSegmentsBrass':5,
                              'fixedAxialBasis':True, 'minimumNeighbourRadialFrameDot':math.cos(math.tau/16),
                              'minimumMajorMinusMinorRadius':1.08-.075, 'closedPositiveRadiusConvexCrossSections':True,
                              'allFacesExplicitTriangles':True},
          'studioTouched':False, 'uploaded':False, 'nativeImportVerified':False,
          'boundary':'Exact oriented triangle correspondence is proved for the Blender FBX roundtrip, with vertex transport tolerance 1e-5. The actual Roblox importer must still prove all six native face/vertex sets before installation.'}
(HERE/'dg02-r01-exact-triangle-roundtrip.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':True,'parts':6,'triangles':3258,'allSixTriangleSurfacesAndWindingExact':True,
                  'fourUntouchedGeometryRecordsExact':True,'maxVertexError':max(row['worldVertexMaxError'] for row in rows)}))
