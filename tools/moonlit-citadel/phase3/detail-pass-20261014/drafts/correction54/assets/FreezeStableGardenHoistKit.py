import hashlib
import json
from pathlib import Path

ROOT = Path.cwd()
HERE = Path(__file__).resolve().parent
ORIGINAL = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02'
OUT = ORIGINAL / 'r01/final'
OLD = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'

def read(path): return json.loads(path.read_text(encoding='utf8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

build = read(OUT/'build-receipt.json')
proof = read(HERE/'dg02-r01-exact-triangle-roundtrip.json')
manifest = read(OUT/'manifest.json')
combined = read(OUT/'combined-manifest.json')
old_manifest = read(ORIGINAL/'manifest.json')
occupied = read(OUT/'occupied-geometry.json')
old_occupied = read(ORIGINAL/'occupied-geometry.json')
original_freeze = read(HERE/'garden-hoist-final-freeze.json')
assert sha(HERE/'garden-hoist-final-freeze.json') == '13f81397232fb54d6fe8b45e5aec8df2c69b6ebefa43270bf9b92c32cb2193f4'
assert build['pass'] and proof['pass'] and proof['allSixFbxTriangleSurfacesAndWindingExact']
assert manifest['part_count'] == 6 and manifest['export_triangles'] == 3258
assert combined['export_parts'][:26] == read(OLD/'manifest.json')['export_parts']
assert len(combined['export_parts']) == 32 and combined['export_triangles'] == 12832
assert all(row['verticesExact'] and row['triangleSurfacesAndWindingExact'] for row in proof['fourUntouchedGeometryRecordsExact'])
assert all(occupied['assets'][name]['bounds'] == row['bounds'] for name,row in old_occupied['assets'].items())
original_rows = {row['name']:row for row in old_manifest['export_parts']}
bound_deltas = []
for row in manifest['export_parts']:
    before = original_rows[row['name']]
    if row['name'].endswith(('__Iron','__Brass')):
        bound_deltas.append({'name':row['name'], 'maxCentreDifference':max(abs(a-b) for a,b in zip(row['roblox_center'],before['roblox_center'])),
                             'maxSizeDifference':max(abs(a-b) for a,b in zip(row['roblox_size'],before['roblox_size'])),
                             'trianglesBefore':before['triangles'], 'trianglesAfter':row['triangles']})
    else:
        assert row == before
for packet in (build['inputHashes'], proof['inputHashes'], combined['provenance']):
    for path,digest in packet.items(): assert sha(ROOT/path)==digest,path
for path,row in original_freeze['files'].items(): assert sha(ROOT/path)==row['sha256'],path
for name,row in build['files'].items(): assert sha(OUT/name)==row['sha256'],name
paths = list(OUT.iterdir())+[HERE/name for name in (
    'StableGardenHoistRecipe.py','BuildExactTriangleGardenHoistKit.py','VerifyExactTriangleGardenHoistKit.py',
    'dg02-r01-exact-triangle-roundtrip.json','CombineStableGardenHoistMetadata.py','FreezeStableGardenHoistKit.py',
    'dg02-native-iron-surface-investigation.json')]
records = {str(path.relative_to(ROOT)).replace('\\','/'): {'bytes':path.stat().st_size,'sha256':sha(path)}
           for path in sorted(paths) if path.is_file()}
report = {'pass':True, 'variant':'DG02_R01', 'assets':2,'parts':6,'triangles':3258,
          'combinedAssets':10,'combinedParts':32,'combinedLibraryTriangles':12832,
          'repair':'Only the closed Iron handwheel and six Brass coils use fixed axial torus frames. Every export material face is an explicit existing loop triangle.',
          'originalDG02FilesAndFreezePreserved':True,'originalUploadUnused':115705002232578,
          'fourUntouchedPartsVerticesAndTriangleSurfacesExact':True,'fourUntouchedPartRowsExact':True,
          'allWholeAssetBoundsExact':True,'allSupportSeatsAndPlacedTriangleCostsUnchanged':True,
          'repairedMaterialBoundDeltas':bound_deltas,
          'allSixFbxOrientedTriangleSurfacesExact':True,'closedManifoldNonzeroOutwardPass':True,
          'contourAndContinuousFramePass':True,'roundtripMaxVertexError':max(row['worldVertexMaxError'] for row in proof['fbxParts']),
          'old26R01RowsExact':True,'logicalLibrary':'DT01','nativeLibraryName':'MoonlitCitadel_Detail_DT02Library',
          'visualInspection': {'originalPreviews':3,'dimensions':[1440,960],
                               'finding':'Stable round handwheel and rope coils retain the supported hoist style; garden and timber supports remain visually exact. Original previews inspected.',
                               'scope':'Standalone kit, not installed native appearance.'},
          'sourceGuards':build['inputHashes'],'provenance':combined['provenance'],'files':records,
          'nativeImportVerified':False,'studioTouched':False,'uploadedByThisAuthor':False,
          'boundary':'Root must verify all six actual native vertex sets and oriented triangle surfaces before AxisVerified or map installation. Old eight R01 native templates remain exact.'}
(HERE/'dg02-r01-final-freeze.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':True,'fbx':records[str((OUT/'MC_GARDEN_HOIST_DG02_R01.fbx').relative_to(ROOT)).replace('\\','/')],
                  'manifest':sha(OUT/'manifest.json'),'combinedManifest':sha(OUT/'combined-manifest.json'),
                  'occupied':sha(OUT/'occupied-geometry.json'),'combinedOccupied':sha(OUT/'combined-occupied-geometry.json'),
                  'authoredGeometry':sha(OUT/'authored-geometry.json'),'triangleProof':sha(HERE/'dg02-r01-exact-triangle-roundtrip.json'),
                  'freeze':sha(HERE/'dg02-r01-final-freeze.json')}))
