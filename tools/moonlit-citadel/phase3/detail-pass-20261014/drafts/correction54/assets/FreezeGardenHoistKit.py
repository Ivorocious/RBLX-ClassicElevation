import hashlib
import json
from pathlib import Path

ROOT = Path.cwd()
HERE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02'
OLD = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
GARDEN = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01'

def read(path):
    return json.loads(path.read_text(encoding='utf8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

build = read(OUT / 'build-receipt.json')
roundtrip = read(HERE / 'garden-hoist-readonly-roundtrip.json')
manifest = read(OUT / 'manifest.json')
combined = read(OUT / 'combined-manifest.json')
occupied = read(OUT / 'occupied-geometry.json')
combined_occupied = read(OUT / 'combined-occupied-geometry.json')
assert build['pass'] and roundtrip['pass'] and roundtrip['fbxRoundtripPass']
assert len(manifest['export_parts']) == 6 and manifest['export_triangles'] == 3258
assert combined['export_parts'][:26] == read(OLD / 'manifest.json')['export_parts']
assert len(combined['export_parts']) == 32 and len(combined['assets']) == 10
assert combined['gardenDG01VerticesAndPartRowsExact']
assert all(combined_occupied['assets'][name] == row for name, row in read(OLD / 'occupied-geometry.json')['assets'].items())
assert sha(HERE / 'garden-final-freeze.json') == 'aa34204c4a1139247144a780a428619d5b160ac3f086e1e0493579dc3b1b2074'
garden_freeze = read(HERE / 'garden-final-freeze.json')
for path, item in garden_freeze['files'].items():
    assert sha(ROOT / path) == item['sha256'], path
for packet in (build['inputHashes'], roundtrip['inputHashes'], combined['provenance']):
    for path, digest in packet.items():
        assert sha(ROOT / path) == digest, path
for name, item in build['files'].items():
    assert sha(OUT / name) == item['sha256'], name

def topology_pass(row):
    return (row['boundary_edges'] == 0 and row['nonmanifold_edges'] == 0
            and row['zero_area_triangles'] == 0 and row['outward_island_winding']
            and row['minimum_island_volume'] > 0)

assert all(topology_pass(row) for row in roundtrip['savedPartsTopology'])
assert all(topology_pass(row['closedTopology']) and row['pass'] for row in roundtrip['fbxParts'])
files = list(OUT.iterdir()) + [HERE / name for name in (
    'GardenHoistRecipe.py', 'BuildGardenHoistKit.py', 'VerifyGardenHoistKit.py',
    'garden-hoist-readonly-roundtrip.json', 'CombineGardenHoistMetadata.py', 'FreezeGardenHoistKit.py')]
records = {str(path.relative_to(ROOT)).replace('\\', '/'):
           {'bytes': path.stat().st_size, 'sha256': sha(path)} for path in sorted(files) if path.is_file()}
report = {
    'pass': True, 'assets': 2, 'parts': 6, 'triangles': 3258,
    'combinedAssets': 10, 'combinedParts': 32, 'combinedLibraryTriangles': 12832,
    'old26PartRowsExact': True, 'old8OccupiedAssetRecordsExact': True,
    'frozenGardenDG01Preserved': True, 'gardenActualVerticesPartRowsAndOccupiedRecordExact': True,
    'source52AndSource53InputHashesPreserved': True,
    'closedManifoldNonzeroOutwardPass': True, 'gardenContourPass': True,
    'hoistCurveScope': 'Existing verified closed coils, handwheel, and timbers reused; crate/tools omitted. One noncrossing open-path closed rope tube added.',
    'fbxRoundtripPass': True,
    'roundtripMaxWorldVertexError': max(row['worldVertexSetMaxError'] for row in roundtrip['fbxParts']),
    'vertexTolerance': 0.00001, 'logicalLibrary': 'DT01',
    'nativeLibraryName': 'MoonlitCitadel_Detail_DT02Library',
    'actualRobloxBounds': {name: row['bounds'] for name, row in occupied['assets'].items()},
    'hoistMount': {'front': '+Z', 'up': '+Y', 'pivot': 'wall mount centre (0,0,0)',
                   'railsX': [-3.85, 3.85], 'railsY': [[-2.445, -1.795], [1.795, 2.445]],
                   'railsZ': [-0.10, 0.32], 'floorCrateAndToolsOmitted': True,
                   'noPlatform': True},
    'placementAuthorConfirmation': {
        'author': '/root/finish_cliffs',
        'scope': 'Reported saved Source52 actual-face measurements; final clearance and native composition remain pending.',
        'hoistMounts': {'x': 193.32, 'y': 115, 'z': [-157, -43], 'front': '-X',
                        'support': 'Twelve probes per two-rail rectangle hit the actual vertical Slate gable face with normal -X.'},
        'gardenMounts': {'gate': {'z': 96, 'baseY': -2}, 'westHigh': {'z': -62, 'baseY': 30},
                         'westMiddle': {'z': 24, 'baseY': 13}, 'westArrival': {'z': 105, 'baseY': 0},
                         'machinery': {'z': -161, 'baseY': 95},
                         'support': 'Eighteen backplate/corbel probes per garden passed the actual old wall face.'},
        'geometryRefinementNeeded': False},
    'visualInspection': {'originalPreviews': 3, 'dimensions': [1440, 960],
                         'finding': 'Garden retains supported corbels and close leaf/vine depth. Hoist has two rooted timber mount rails, triangular braces, horizontal flanged drum, handwheel and a short hanging rope; ground props are absent. No contour wedge or floating assembly is visible.',
                         'scope': 'Standalone kit only. Native map composition and final art acceptance remain pending.'},
    'sourceGuards': build['inputHashes'], 'kitProvenance': combined['provenance'],
    'files': records, 'studioTouched': False, 'liveBlenderTouched': False,
    'productionTouched': False, 'uploadedByThisAuthor': False, 'nativeImportVerified': False,
    'next': 'Root may upload this exact six-part garden+hoist FBX after inspecting originals and placement-author mount confirmation. Prove all six actual native vertex sets and importer basis. Copy eight old native R01 templates exactly into DT02Library; do not upload the old kit again.'
}
(HERE / 'garden-hoist-final-freeze.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
print(json.dumps({'pass': True, 'fbx': records[str((OUT / 'MC_GARDEN_HOIST_DG02.fbx').relative_to(ROOT)).replace('\\', '/')],
                  'manifest': sha(OUT / 'manifest.json'), 'combinedManifest': sha(OUT / 'combined-manifest.json'),
                  'occupied': sha(OUT / 'occupied-geometry.json'), 'combinedOccupied': sha(OUT / 'combined-occupied-geometry.json'),
                  'freeze': sha(HERE / 'garden-hoist-final-freeze.json')}))
