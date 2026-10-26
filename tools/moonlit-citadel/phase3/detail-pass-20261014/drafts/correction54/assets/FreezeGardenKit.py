import hashlib
import json
from pathlib import Path

ROOT = Path.cwd()
HERE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01'
OLD = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'

def read(path):
    return json.loads(path.read_text(encoding='utf8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

build = read(OUT / 'build-receipt.json')
roundtrip = read(HERE / 'garden-readonly-roundtrip.json')
manifest = read(OUT / 'manifest.json')
combined = read(OUT / 'combined-manifest.json')
occupied = read(OUT / 'occupied-geometry.json')
combined_occupied = read(OUT / 'combined-occupied-geometry.json')
assert build['pass'] and roundtrip['pass'] and roundtrip['fbxRoundtripPass']
assert len(manifest['export_parts']) == 3
assert sum(row['triangles'] for row in manifest['export_parts']) == 1662
assert combined['export_parts'][:26] == read(OLD / 'manifest.json')['export_parts']
assert len(combined['export_parts']) == 29 and len(combined['assets']) == 9
assert all(combined_occupied['assets'][name] == data for name, data in read(OLD / 'occupied-geometry.json')['assets'].items())
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
    'GardenRecipe.py', 'BuildGardenKit.py', 'VerifyGardenKit.py',
    'garden-readonly-roundtrip.json', 'CombineKitMetadata.py', 'FreezeGardenKit.py')]
records = {str(path.relative_to(ROOT)).replace('\\', '/'):
           {'bytes': path.stat().st_size, 'sha256': sha(path)}
           for path in sorted(files) if path.is_file()}
report = {
    'pass': True, 'asset': 'MC_DG_WallGarden24', 'assets': 1, 'parts': 3,
    'triangles': 1662, 'combinedAssets': 9, 'combinedParts': 29,
    'combinedLibraryTriangles': 11236, 'old26PartRowsExact': True,
    'old8OccupiedAssetRecordsExact': True, 'sourceInputHashesPreserved': True,
    'closedManifoldNonzeroOutwardPass': True, 'contourPass': True,
    'fbxRoundtripPass': True,
    'roundtripMaxWorldVertexError': max(row['worldVertexSetMaxError'] for row in roundtrip['fbxParts']),
    'vertexTolerance': 0.00001, 'logicalLibrary': 'DT01',
    'nativeLibraryName': 'MoonlitCitadel_Detail_DT02Library',
    'actualRobloxBounds': {'low': [-12, 0, -0.10000000149011612],
                           'high': [12, 9.627996444702148, 4.269999980926514]},
    'support': {'front': '+Z', 'up': '+Y', 'pivot': 'base origin (0,0,0)',
                'corbelCentersX': [-8.65, 0, 8.65], 'corbelWidth': 2.32,
                'corbelY': [0, 5.22], 'backMountZ': -0.10,
                'backPlateBox': {'low': [-11.3, 2.65, -0.10], 'high': [11.3, 6.05, 0.26]},
                'foliageMaxY': 9.627996444702148},
    'visualInspection': {
        'originalPreviews': 3, 'dimensions': [1440, 960],
        'finding': 'Continuous stone bowl and three visible sloped corbels root the planting to the wall; broad leaf groups and hanging vines create close vertical depth. Soil is a convex sloped pocket. No black contour wedge or disconnected floating foliage is visible.',
        'scope': 'Standalone authored kit only; installed native composition and art acceptance remain pending.'},
    'sourceGuards': build['inputHashes'], 'kitProvenance': combined['provenance'],
    'files': records, 'studioTouched': False, 'liveBlenderTouched': False,
    'productionTouched': False, 'uploadedByThisAuthor': False, 'nativeImportVerified': False,
    'next': 'Root may upload this exact garden-only FBX after inspecting these originals, then verify actual native vertices and import basis. Copy the old eight native R01 templates exactly into DT02Library; combine these three new material parts without changing the old 26.'
}
(HERE / 'garden-final-freeze.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
print(json.dumps({'pass': True, 'fbx': records[str((OUT / 'MC_WALL_GARDEN_DG01.fbx').relative_to(ROOT)).replace('\\', '/')],
                  'manifest': sha(OUT / 'manifest.json'), 'combinedManifest': sha(OUT / 'combined-manifest.json'),
                  'occupied': sha(OUT / 'occupied-geometry.json'), 'combinedOccupied': sha(OUT / 'combined-occupied-geometry.json'),
                  'freeze': sha(HERE / 'garden-final-freeze.json')}))
