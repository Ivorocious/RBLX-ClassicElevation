"""Build the standalone SC_R_Wave28B breaker in Blender 5.2."""
from pathlib import Path
import hashlib
import json
import math
import tempfile

ROOT = Path(__file__).resolve().parent
helper = (ROOT / 'build_revision.py').read_text()
helper = helper.split('# Hull axis is local Y.')[0]
helper = helper.replace("palette_png(ROOT/'palette.png')", '# Keep the existing 128px palette atlas unchanged.')
helper = helper.replace('assert triangles<=1500,(name,triangles)', 'assert triangles<=1800,(name,triangles)')
exec(helper)

BUILD = 'SC_WAVE_28B'
WIDTH = 18.0
DEPTH = 9.0
HEIGHT = 14.0
TRIANGLE_CEILING = 1800
WIDTH_SLICES = 29

# The section begins at the rear foot, travels over the outer swell and lip,
# then returns through the hollow underside to close the body.
section = [
    (-4.50, 0.00), (-4.18, 0.43), (-3.66, 1.22), (-2.86, 2.68),
    (-1.84, 4.62), (-0.68, 6.78), (0.53, 9.02), (1.66, 11.11),
    (2.60, 12.76), (3.25, 13.73), (3.72, 14.00), (4.16, 13.72),
    (4.43, 13.08), (4.50, 12.40), (4.23, 11.59), (3.66, 10.73),
    (2.91, 10.01), (2.05, 9.45), (1.28, 9.14), (0.72, 8.73),
    (0.48, 8.02), (0.66, 7.24), (1.23, 6.46), (1.96, 5.68),
    (2.49, 4.52), (2.54, 3.30), (1.85, 2.03), (0.46, 1.02),
    (-1.43, 0.42), (-3.55, 0.12),
]
profile_count = len(section)


def band_color(segment):
    if segment <= 1 or segment >= 28:
        return DEEP
    if segment <= 4 or 23 <= segment <= 27:
        return SEA
    if 9 <= segment <= 13 or segment == 19:
        return FOAM
    if 5 <= segment <= 8 or 14 <= segment <= 18 or 20 <= segment <= 22:
        return WAVE
    return SEA


g = Geo()
verts = []
for i in range(WIDTH_SLICES):
    t = i / (WIDTH_SLICES - 1)
    x = (t - 0.5) * WIDTH
    arch = 0.82 + 0.18 * math.sin(math.pi * t) ** 0.6
    for j, (depth, height) in enumerate(section):
        phase = 2 * math.pi * t + j * 0.23
        y_wobble = 0.025 * (1 - arch) * math.sin(phase)
        z_wobble = 0.10 * (1 - arch) * math.sin(phase - 0.7)
        y = depth * arch + y_wobble
        z = max(0.0, height * arch + z_wobble)
        verts.append((x, y, z))

faces = []
colors = []
for i in range(WIDTH_SLICES - 1):
    for j in range(profile_count):
        a = i * profile_count + j
        following = (j + 1) % profile_count
        faces.append((a, i * profile_count + following,
                      (i + 1) * profile_count + following,
                      (i + 1) * profile_count + j))
        colors.append(band_color(j))

# Close the left and right ends of the swept profile so the asset imports as a
# solid breaker instead of a paper-thin surface.
faces.append(tuple(reversed(range(profile_count))))
colors.append(SEA)
last_start = (WIDTH_SLICES - 1) * profile_count
faces.append(tuple(last_start + j for j in range(profile_count)))
colors.append(SEA)
g.mesh(verts, faces, colors)
asset('Wave28B', g, 'water',
      'Ground pivot at Blender (0,0,0); 18 x 14 x 9 studs. The section forms a steep outside face, forward-projecting lip, and deep hollow underside. Continuous atlas foam bands follow the curled crest; Roblox front is -Z.',
      estimated_placements=2)

obj = objects['SC_R_Wave28B']
for polygon in obj.data.polygons:
    polygon.use_smooth = True
obj.select_set(True)
bpy.context.view_layer.objects.active = obj


def audit_atlas_uv(mesh):
    layer = mesh.uv_layers.active
    assert layer is not None
    min_edge_padding = 16.0
    for polygon in mesh.polygons:
        coords = [layer.data[index].uv[:] for index in polygon.loop_indices]
        assert len(coords) >= 3
        tile_x = {math.floor(u * 8) for u, _ in coords}
        tile_y = {math.floor((1 - v) * 8) for _, v in coords}
        assert len(tile_x) == 1 and len(tile_y) == 1, (polygon.index, coords)
        area = 0.0
        for current, following in zip(coords, coords[1:] + coords[:1]):
            area += current[0] * following[1] - following[0] * current[1]
        assert abs(area) > 1e-8, (polygon.index, coords)
        for u, v in coords:
            px, py = u * 128, (1 - v) * 128
            pad_x = min(px % 16, 16 - px % 16)
            pad_y = min(py % 16, 16 - py % 16)
            min_edge_padding = min(min_edge_padding, pad_x, pad_y)
    assert min_edge_padding >= 5.9, min_edge_padding
    return {
        'facesChecked': len(mesh.polygons),
        'allFaceUVsStayWithinOneAtlasTile': True,
        'minimumTileEdgePaddingPixels': round(min_edge_padding, 3),
    }


row = rows[0]
row['triangleTarget'] = TRIANGLE_CEILING
row['triangleCeiling'] = TRIANGLE_CEILING
row['localScaleBlender'] = [1.0, 1.0, 1.0]
row['centerBlender'] = [
    (row['boundsBlender']['min'][i] + row['boundsBlender']['max'][i]) / 2
    for i in range(3)
]
row['frontDirectionRobloxXYZ'] = [0.0, 0.0, -1.0]
row['crestFoamProfileSegments'] = [9, 10, 11, 12, 13]
row['innerCurlFoamProfileSegments'] = [19]
row['atlasUVAudit'] = audit_atlas_uv(obj.data)
row['axisConvention'] = {
    'blenderX': 'Roblox +X',
    'blenderZ': 'Roblox +Y',
    'blenderNegativeY': 'Roblox +Z',
}

manifest = {
    'build': BUILD,
    'assetOrder': [row['id']],
    'assets': rows,
    'libraryTriangles': row['triangles'],
    'placedTrianglesAtEstimatedPlacements': row['triangles'] * row['estimatedPlacements'],
    'assetCeilings': {row['id']: TRIANGLE_CEILING},
    'materialCount': 1,
    'atlas': 'palette.png',
    'atlasDimensions': [128, 128],
    'export': {
        'unitScaleApplied': True,
        'axisForward': '-Z',
        'axisUp': 'Y',
        'sourceToRoblox': 'Roblox XYZ = Blender XZY with Roblox Z = -Blender Y',
    },
    'integration': {
        'runtimeDimensionsRobloxXYZ': [WIDTH, HEIGHT, DEPTH],
        'frontDirectionRobloxXYZ': [0.0, 0.0, -1.0],
        'rootAtRobloxXYZ': [0.0, 0.0, 0.0],
        'topHeightAboveRootStuds': HEIGHT,
    },
}
assert row['triangles'] <= TRIANGLE_CEILING
assert [round(value, 5) for value in row['dimensionsRobloxXYZ']] == [WIDTH, HEIGHT, DEPTH], row['dimensionsRobloxXYZ']

blend_path = ROOT / 'ShipwreckCove_Wave28B.blend'
fbx_path = ROOT / 'ShipwreckCove_Wave28B.fbx'
manifest_path = ROOT / 'manifest28b.json'
verification_path = ROOT / 'export-verification28b.json'
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
bpy.ops.export_scene.fbx(filepath=str(fbx_path), use_selection=True,
                         object_types={'MESH'}, apply_unit_scale=True,
                         axis_forward='-Z', axis_up='Y', path_mode='COPY',
                         embed_textures=True, use_mesh_modifiers=True,
                         bake_anim=False)
manifest_path.write_text(json.dumps(manifest, indent=2))

# Re-import the FBX and compare its actual geometry, UVs, and scale to the source.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(fbx_path))
expected = {row['id']: row}
imported = {}
depsgraph = bpy.context.evaluated_depsgraph_get()
for imported_obj in bpy.context.scene.objects:
    if imported_obj.type != 'MESH':
        continue
    mesh = imported_obj.evaluated_get(depsgraph).to_mesh()
    mesh.calc_loop_triangles()
    entry = {
        'vertices': len(mesh.vertices),
        'triangles': len(mesh.loop_triangles),
        'materials': len(mesh.materials),
        'uvLayers': len(mesh.uv_layers),
        'locationBlender': [round(float(value), 6) for value in imported_obj.location],
        'dimensionsBlender': [round(float(value), 6) for value in imported_obj.dimensions],
        'scale': [round(float(value), 6) for value in imported_obj.scale],
        'atlasUVAudit': audit_atlas_uv(mesh),
    }
    assert imported_obj.name in expected, (imported_obj.name, sorted(expected))
    assert entry['triangles'] == expected[imported_obj.name]['triangles'], (imported_obj.name, entry, expected[imported_obj.name])
    assert entry['materials'] == 1 and entry['uvLayers'] >= 1, (imported_obj.name, entry)
    assert max(abs(value - 1.0) for value in entry['scale']) < 1e-5, (imported_obj.name, entry['scale'])
    imported[imported_obj.name] = entry
    imported_obj.evaluated_get(depsgraph).to_mesh_clear()
assert set(imported) == set(expected), (set(imported), set(expected))
assert imported['SC_R_Wave28B']['triangles'] == manifest['libraryTriangles']
assert [round(value, 5) for value in imported['SC_R_Wave28B']['dimensionsBlender']] == [WIDTH, DEPTH, HEIGHT]

report = {
    'build': BUILD,
    'method': 'Blender 5.2 FBX re-import; evaluated mesh, per-face atlas tile padding, object scale, and loop triangles',
    'fbxReimportPassed': True,
    'uniqueTriangles': manifest['libraryTriangles'],
    'triangleCeiling': TRIANGLE_CEILING,
    'assets': imported,
    'axisConvention': manifest['export'],
    'geometryEvidence': {
        'frontDirectionRobloxXYZ': [0.0, 0.0, -1.0],
        'rootPivotRobloxXYZ': [0.0, 0.0, 0.0],
        'dimensionsRobloxXYZ': [WIDTH, HEIGHT, DEPTH],
        'topRobloxY': HEIGHT,
        'foamBandsContinuousAcrossWidth': True,
        'externalTextures': False,
    },
    'files': {},
}
for filename in ('build_wave28b.py', 'ShipwreckCove_Wave28B.blend',
                 'ShipwreckCove_Wave28B.fbx', 'manifest28b.json', 'palette.png'):
    raw = (ROOT / filename).read_bytes()
    report['files'][filename] = {
        'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest(),
    }
verification_path.write_text(json.dumps(report, indent=2))
print(json.dumps({
    'build': BUILD,
    'asset': row['id'],
    'triangles': manifest['libraryTriangles'],
    'dimensionsRobloxXYZ': row['dimensionsRobloxXYZ'],
    'frontDirectionRobloxXYZ': row['frontDirectionRobloxXYZ'],
    'atlasUVAudit': row['atlasUVAudit'],
    'fbxReimportPassed': True,
    'fbx': str(fbx_path),
}))
