import hashlib
import json
from pathlib import Path

ROOT = Path.cwd()
OLD = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
GARDEN = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01'
NEW = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02'

def load(path):
    return json.loads(path.read_text(encoding='utf8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

old, garden, new = [load(path / 'manifest.json') for path in (OLD, GARDEN, NEW)]
new_garden = [row for row in new['export_parts'] if row['asset'] == 'MC_DG_WallGarden24']
assert new_garden == garden['export_parts']
old_vertices = load(GARDEN / 'authored-geometry.json')['parts']
new_vertices = [row for row in load(NEW / 'authored-geometry.json')['parts'] if row['asset'] == 'MC_DG_WallGarden24']
assert new_vertices == old_vertices
assert load(NEW / 'occupied-geometry.json')['assets']['MC_DG_WallGarden24'] == load(GARDEN / 'occupied-geometry.json')['assets']['MC_DG_WallGarden24']
parts = old['export_parts'] + new['export_parts']
assets = old['assets'] + new['assets']
assert len(parts) == 32 and len({row['name'] for row in parts}) == 32 and len(assets) == 10
provenance = {}
for folder, fbx in ((OLD, 'MC_DETAIL_KIT_DT01.fbx'), (GARDEN, 'MC_WALL_GARDEN_DG01.fbx'), (NEW, 'MC_GARDEN_HOIST_DG02.fbx')):
    for name in ('manifest.json', fbx, 'authored-geometry.json', 'occupied-geometry.json'):
        path = folder / name
        provenance[str(path.relative_to(ROOT)).replace('\\', '/')] = sha(path)
manifest = {'candidate': 'MC_P3_DETAILS_DT02', 'logicalLibrary': 'DT01',
            'nativeLibraryName': 'MoonlitCitadel_Detail_DT02Library',
            'axes': 'Roblox=(X,Z,-Y)', 'units': '1 Blender unit = 1 intended stud',
            'part_count': 32, 'export_triangles': sum(row['triangles'] for row in parts),
            'assets': assets, 'export_parts': parts, 'provenance': provenance,
            'old26PartRowsExact': True, 'gardenDG01VerticesAndPartRowsExact': True,
            'nativeImportVerified': False,
            'assemblyRule': 'Copy all eight verified R01 native templates unchanged; import/prove only the six new garden and wall-hoist material meshes.'}
occupied = load(OLD / 'occupied-geometry.json')['assets'] | load(NEW / 'occupied-geometry.json')['assets']
assert len(occupied) == 10
assert all(occupied[name] == row for name, row in load(OLD / 'occupied-geometry.json')['assets'].items())
(NEW / 'combined-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf8')
(NEW / 'combined-occupied-geometry.json').write_text(json.dumps({
    'axes': 'Roblox XYZ', 'logicalLibrary': 'DT01', 'nativeLibraryName': 'MoonlitCitadel_Detail_DT02Library',
    'assets': occupied, 'provenance': provenance}, indent=2) + '\n', encoding='utf8')
print(json.dumps({'parts': 32, 'assets': 10, 'triangles': manifest['export_triangles'],
                  'old26PartRowsExact': True, 'gardenDG01VerticesAndPartRowsExact': True,
                  'fbxSHA': sha(NEW / 'MC_GARDEN_HOIST_DG02.fbx')}))
