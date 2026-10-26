"""Build the SC28 scenery and cannon asset kit in Blender 5.2."""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parent
helper = (ROOT / 'build_revision.py').read_text()
helper = helper.split('# Hull axis is local Y.')[0]
helper = helper.replace("palette_png(ROOT/'palette.png')", '# Keep the existing 128px palette atlas unchanged.')
exec(helper)

BUILD = 'SC_KIT_28'
TRIANGLE_TARGETS = {
    'SC_R_Stalactite28': 1500,
    'SC_R_Palm28': 1600,
    'SC_R_Horizon28': 1200,
    'SC_R_Wave28': 900,
    'SC_R_NavalCannon28': 1500,
}


def varied_stone(index, band=0):
    value = math.sin(index * 12.9898 + band * 78.233) * 43758.5453
    value = value - math.floor(value)
    if value < 0.17:
        return STONE_SHADE
    if value > 0.91:
        return CREAM
    return STONE


# Ceiling root remains at zero; Roblox Y is Blender Z.
g = Geo()
stalactite_rings = [
    (0.0, 1.48, 0.00, 0.00),
    (-0.20, 1.43, 0.02, -0.01),
    (-0.78, 1.31, 0.08, -0.01),
    (-1.52, 1.18, 0.12, 0.03),
    (-2.34, 1.04, 0.09, 0.07),
    (-3.05, 0.99, -0.01, 0.08),
    (-3.63, 0.89, -0.11, 0.09),
    (-4.34, 0.75, -0.21, 0.12),
    (-5.08, 0.59, -0.31, 0.16),
    (-5.83, 0.43, -0.39, 0.19),
    (-6.47, 0.29, -0.44, 0.21),
    (-6.86, 0.15, -0.48, 0.22),
    (-7.0, 0.055, -0.49, 0.22),
]
around = 16
verts = []
for level, (height, radius, center_x, center_y) in enumerate(stalactite_rings):
    for j in range(around):
        angle = 2 * math.pi * j / around
        uneven = (1.0 + 0.055 * math.sin(3 * angle + level * 0.71)
                  + 0.032 * math.cos(5 * angle - level * 0.43)
                  + 0.018 * math.sin(7 * angle + level * 0.19))
        r = radius * uneven
        verts.append((center_x + r * math.cos(angle),
                      center_y + r * math.sin(angle), height))
faces = [tuple(reversed(range(around)))]
colors = [STONE_SHADE]
for level in range(len(stalactite_rings) - 1):
    for j in range(around):
        faces.append((level * around + j,
                      level * around + (j + 1) % around,
                      (level + 1) * around + (j + 1) % around,
                      (level + 1) * around + j))
        colors.append(varied_stone(level * around + j, level))
faces.append(tuple((len(stalactite_rings) - 1) * around + j for j in range(around)))
colors.append(STONE_SHADE)
g.mesh(verts, faces, colors)
asset('Stalactite28', g, 'rock',
      'Ceiling pivot at Blender (0,0,0); segmented taper tip reaches Roblox Y -7. Use opaque atlas stone facets.',
      mount='ceiling', estimated_placements=25)


# Palm trunk leans gently into a crown of broad, curved, opaque fronds.
g = Geo()
trunk_sections = 17
trunk_sides = 12
trunk_height = 24.5
trunk_verts = []
for k in range(trunk_sections):
    t = k / (trunk_sections - 1)
    z = trunk_height * t
    center_x = 2.25 * t ** 1.22
    center_y = 0.62 * math.sin(math.pi * t)
    radius = 0.78 * (1 - t) ** 0.72 + 0.22
    for j in range(trunk_sides):
        angle = 2 * math.pi * j / trunk_sides
        knot = 1 + 0.035 * math.sin(4 * angle + 13 * t) + 0.018 * math.cos(7 * angle - 9 * t)
        trunk_verts.append((center_x + radius * knot * math.cos(angle),
                            center_y + radius * knot * math.sin(angle), z))
trunk_faces = [tuple(reversed(range(trunk_sides)))]
trunk_colors = [DARK]
for k in range(trunk_sections - 1):
    for j in range(trunk_sides):
        trunk_faces.append((k * trunk_sides + j,
                            k * trunk_sides + (j + 1) % trunk_sides,
                            (k + 1) * trunk_sides + (j + 1) % trunk_sides,
                            (k + 1) * trunk_sides + j))
        trunk_colors.append(TAN if (k + j) % 5 == 0 else WOOD)
trunk_faces.append(tuple((trunk_sections - 1) * trunk_sides + j for j in range(trunk_sides)))
trunk_colors.append(DARK)
g.mesh(trunk_verts, trunk_faces, trunk_colors)

crown = (2.25, 0.0, trunk_height)
frond_count = 9
frond_steps = 12
across = [-1.0, -0.5, 0.0, 0.5, 1.0]
for index in range(frond_count):
    angle = index * 2.399963229728653 + 0.13 * math.sin(index * 1.7)
    radial = (math.cos(angle), math.sin(angle))
    side = (-radial[1], radial[0])
    length = 10.8 + (index % 4) * 0.9
    half_width = 1.25 + (index % 3) * 0.12
    lift = 3.0 + (index % 3) * 0.3
    droop = 4.8 + (index % 4) * 0.55
    leaf_verts = []
    for k in range(frond_steps + 1):
        t = k / frond_steps
        sweep = 0.55 * math.sin(math.pi * t) * (1 if index % 2 else -1)
        cx = crown[0] + radial[0] * length * t + side[0] * sweep
        cy = crown[1] + radial[1] * length * t + side[1] * sweep
        z = crown[2] + lift * math.sin(math.pi * 0.54 * t) - droop * t ** 1.82
        envelope = max(0.035, math.sin(math.pi * min(0.995, 0.04 + 0.93 * t)) ** 0.78)
        envelope *= 1 - 0.22 * t
        scallop = 1 + 0.035 * math.sin(2 * math.pi * 9 * t + index)
        for across_value in across:
            half_span = half_width * envelope * scallop
            x = cx + side[0] * half_span * across_value
            y = cy + side[1] * half_span * across_value
            ridge = 0.17 * (1 - abs(across_value)) - 0.06 * abs(across_value)
            leaf_verts.append((x, y, z + ridge))
    leaf_faces = []
    leaf_colors = []
    for k in range(frond_steps):
        for strip in range(len(across) - 1):
            a = k * len(across) + strip
            leaf_faces.append((a, a + len(across), a + len(across) + 1, a + 1))
            tint = (index + k // 4 + strip) % 5
            leaf_colors.append(LEAF_L if tint == 0 else LEAF)
    g.mesh(leaf_verts, leaf_faces, leaf_colors)

# Three fruit bodies under the crown keep the palm readable at player height.
for index in range(3):
    angle = index * (2 * math.pi / 3) + 0.42
    center = (crown[0] + 0.58 * math.cos(angle),
              crown[1] + 0.58 * math.sin(angle),
              crown[2] - 0.45 - 0.1 * (index % 2))
    fruit = Geo()
    fruit.rings([(-0.58, 0.20), (-0.43, 0.37), (0.05, 0.43), (0.43, 0.29), (0.58, 0.06)],
                8, WOOD, axis='z', center=center)
    g.mesh(fruit.v, fruit.f, fruit.c)
asset('Palm28', g, 'vegetation',
      'Ground pivot at Blender (0,0,0); curved leaning trunk to Roblox Y 24.5, nine broad drooping fronds and three coconuts.',
      estimated_placements=25, recalculate_normals=False)


# One eroded island ridge uses a sampled smooth landform, broad shoulders and rounded saddles.
g = Geo()
ridge_width = 148.0
ridge_depth = 60.0
x_steps = 41
depth_profile = [-1.0, -0.87, -0.68, -0.47, -0.26, -0.08,
                 0.10, 0.29, 0.49, 0.70, 0.88, 1.0]
depth_height = [0.0, 0.22, 0.47, 0.70, 0.87, 0.96,
                1.0, 0.94, 0.82, 0.60, 0.28, 0.0]
ridge_verts = []
for i in range(x_steps):
    u = i / (x_steps - 1)
    x = (u - 0.5) * ridge_width
    edge = max(0.0, min(1.0, math.sin(math.pi * u))) ** 0.68
    hills = (
        24 * math.exp(-((u - 0.15) / 0.12) ** 2)
        + 37 * math.exp(-((u - 0.39) / 0.17) ** 2)
        + 32 * math.exp(-((u - 0.67) / 0.18) ** 2)
        + 22 * math.exp(-((u - 0.88) / 0.105) ** 2)
        + 4.5)
    height = min(52.0, hills * edge * 1.17)
    crest_shift = 1.8 * math.sin(2 * math.pi * u * 2.1) + 0.9 * math.sin(2 * math.pi * u * 5.3)
    for cross, lift in zip(depth_profile, depth_height):
        local_irregularity = (1.0 + 0.025 * math.sin(15 * u + cross * 8)
                              + 0.018 * math.cos(21 * u - cross * 4))
        y = cross * ridge_depth * 0.5 + crest_shift * (1 - abs(cross))
        z = height * lift * local_irregularity
        ridge_verts.append((x, y, z))
ridge_faces = []
ridge_colors = []
cross_count = len(depth_profile)
for i in range(x_steps - 1):
    for band in range(cross_count - 1):
        a = i * cross_count + band
        ridge_faces.append((a, a + cross_count, a + cross_count + 1, a + 1))
        patch = math.sin(i * 1.91 + band * 8.17) * math.cos(i * 0.41 - band * 3.3)
        if band in (4, 5, 6):
            ridge_colors.append(LEAF_L if patch > 0.9 else (CREAM if patch < -0.92 else STONE))
        elif patch > 0.73:
            ridge_colors.append(STONE_SHADE)
        elif patch < -0.88:
            ridge_colors.append(CREAM)
        else:
            ridge_colors.append(STONE)
for end in (0, x_steps - 1):
    face = tuple(end * cross_count + j for j in range(cross_count))
    ridge_faces.append(face if end else tuple(reversed(face)))
    ridge_colors.append(STONE_SHADE)
g.mesh(ridge_verts, ridge_faces, ridge_colors)
asset('Horizon28', g, 'coastal_ridge',
      'Ground pivot; 148 by 60 studs, 52-stud maximum rounded limestone crest, broad eroded saddles and sparse atlas moss.',
      estimated_placements=38)


# A wider, higher curl has an opaque turquoise body and a continuous atlas foam band.
g = Geo()
wave_width = 28.0
wave_slices = 21
wave_profile = [
    (-5.0, 0.0), (-2.5, 0.3), (-0.2, 0.9), (1.4, 2.1),
    (2.55, 3.8), (3.15, 5.7), (3.15, 7.2), (2.65, 8.25),
    (1.55, 8.75), (0.42, 8.48), (-0.28, 7.75), (-0.42, 6.92),
    (0.18, 6.43), (1.15, 6.63), (1.82, 6.08), (1.92, 4.9),
    (1.28, 3.45), (-0.25, 2.05), (-2.45, 0.84), (-5.0, 0.0),
]
wave_verts = []
for i in range(wave_slices):
    t = i / (wave_slices - 1)
    x = (t - 0.5) * wave_width
    swell = 0.55 + 0.45 * math.sin(math.pi * t) ** 0.7
    for depth, height in wave_profile:
        waviness = 0.12 * math.sin(t * 4 * math.pi + height * 0.21)
        y = depth * swell + 0.15 * math.sin(math.pi * t) * (height / 8.75)
        z = max(0.0, height * swell + waviness * math.sin(math.pi * t))
        wave_verts.append((x, y, z))
wave_faces = []
wave_colors = []
profile_count = len(wave_profile)
foam_bands = {5, 6, 7, 8, 9, 10, 11}
for i in range(wave_slices - 1):
    for j in range(profile_count - 1):
        a = i * profile_count + j
        wave_faces.append((a, a + 1, a + profile_count + 1, a + profile_count))
        if j in foam_bands:
            wave_colors.append(FOAM if (i + j) % 11 != 0 else WAVE)
        elif j in (3, 4, 12, 13, 14, 15):
            wave_colors.append(WAVE if (i + j) % 5 else SEA)
        elif j in (2, 16, 17):
            wave_colors.append(SEA)
        else:
            wave_colors.append(DEEP if (i + j) % 4 else SEA)
wave_faces.extend([tuple(reversed(range(profile_count))),
                   tuple((wave_slices - 1) * profile_count + j for j in range(profile_count))])
wave_colors.extend([SEA, SEA])
g.mesh(wave_verts, wave_faces, wave_colors)
asset('Wave28', g, 'water',
      'Width 28, root Blender Z 0; front curls toward Roblox -Z, 8.75-stud crest and opaque turquoise/foam atlas.',
      estimated_placements=2)


# The level carriage stays fixed while only the -X barrel rotates upward around its Y-axis trunnion.
g = Geo()
g.box((0.7, 0, 0.9), (5.6, 3.3, 1.0), DARK)
for y in (-1.45, 1.45):
    g.box((0.5, y, 1.7), (4.8, 0.55, 1.5), WOOD)
g.rings([(-2.05, 0.33), (2.05, 0.33)], 8, IRON, 'y', (0, 0, 2.7))
for x in (-1.3, 1.8):
    for y in (-2, 2):
        g.rings([(-0.35, 0.88), (0.35, 0.88)], 10, DARK, 'y', (x, y, 0.9))
        g.rings([(-0.36, 0.89), (-0.36, 0.69)], 10, IRON_L, 'y', (x, y, 0.9), False)
g.beam((1.3, 0, 3.8), (1.6, 0, 4.45), 0.18, 0.18, ROPE)

barrel = Geo()
for profile, color in [
    ([(-5.1, 1.14), (-4.6, 1.14), (-4.2, 0.91), (-1.2, 1.2),
      (1.4, 1.05), (1.9, 0.45)], IRON),
    ([(-5.13, 1.17), (-4.74, 1.17)], GOLD),
    ([(-1.2, 1.25), (-0.8, 1.25)], IRON_L),
    ([(-5.15, 1.14), (-5.15, 0.72), (-3.5, 0.72)], INK),
]:
    barrel.rings(profile, 12, color, 'x', (0, 0, 3.1), False)
barrel.rings([(1.85, 0.46), (2.2, 0.3)], 8, IRON, 'x', (0, 0, 3.1))

elevation = math.radians(35.0)
sin_elevation = math.sin(elevation)
cos_elevation = math.cos(elevation)
trunnion_z = 2.7
raised_barrel_verts = []
for x, y, z in barrel.v:
    relative_z = z - trunnion_z
    raised_barrel_verts.append((x * cos_elevation + relative_z * sin_elevation,
                                y,
                                -x * sin_elevation + relative_z * cos_elevation + trunnion_z))
g.mesh(raised_barrel_verts, barrel.f, barrel.c)
asset('NavalCannon28', g, 'cannon',
      'Ground pivot at Blender (0,0,0); level four-wheel carriage. Barrel alone elevates 35 degrees about Blender +Y / Roblox local -Z trunnion; muzzle local Roblox (-5.15 cos35 + 0.4 sin35, 2.7 + 5.15 sin35 + 0.4 cos35, 0). Recommend root Roblox Y 7 studs instead of 13.',
      estimated_placements=4)

for row in rows:
    row['vertices'] = len(objects[row['id']].data.vertices)
    row['triangleTarget'] = TRIANGLE_TARGETS[row['id']]
    row['localScaleBlender'] = [1.0, 1.0, 1.0]
    if row['id'] == 'SC_R_NavalCannon28':
        muzzle_x = -5.15 * cos_elevation + 0.4 * sin_elevation
        muzzle_y = 0.0
        muzzle_z = trunnion_z + 5.15 * sin_elevation + 0.4 * cos_elevation
        row['muzzleLocalBlenderXYZ'] = [muzzle_x, muzzle_y, muzzle_z]
        row['muzzleLocalRobloxXYZ'] = [muzzle_x, muzzle_z, -muzzle_y]
        row['muzzleTangentAxisRoblox'] = [-cos_elevation, sin_elevation, 0.0]
        row['trunnionAxisRoblox'] = [0.0, 0.0, -1.0]
        row['barrelElevationDegrees'] = 35.0
        row['recommendedRootRobloxY'] = 7.0
        row['previousRootRobloxY'] = 13.0
        row['carriageElevationDegrees'] = 0.0
    if row['id'] == 'SC_R_Stalactite28':
        row['tipLocalRobloxXYZ'] = [-0.49, -7.0, -0.22]
    if row['id'] == 'SC_R_Palm28':
        row['crownLocalRobloxXYZ'] = [2.25, 24.5, 0.0]
        row['frondCount'] = frond_count
        row['coconutCount'] = 3
    if row['id'] == 'SC_R_Wave28':
        row['frontDirectionRoblox'] = [0.0, 0.0, -1.0]
    row['axisConvention'] = {
        'blenderX': 'Roblox +X',
        'blenderZ': 'Roblox +Y',
        'blenderNegativeY': 'Roblox +Z',
    }


def audit_atlas_uv(mesh):
    layer = mesh.uv_layers.active
    assert layer is not None
    min_edge_padding = 16.0
    for polygon in mesh.polygons:
        coords = [layer.data[loop_index].uv[:] for loop_index in polygon.loop_indices]
        assert len(coords) >= 3
        tile_x = {math.floor(u * 8) for u, _ in coords}
        tile_y = {math.floor((1 - v) * 8) for _, v in coords}
        assert len(tile_x) == 1 and len(tile_y) == 1, (polygon.index, coords)
        area = 0.0
        for current, following in zip(coords, coords[1:] + coords[:1]):
            area += current[0] * following[1] - following[0] * current[1]
        assert abs(area) > 1e-8, (polygon.index, coords)
        for u, v in coords:
            px = u * 128
            py = (1 - v) * 128
            pad_x = min(px % 16, 16 - px % 16)
            pad_y = min(py % 16, 16 - py % 16)
            min_edge_padding = min(min_edge_padding, pad_x, pad_y)
    assert min_edge_padding >= 5.9, min_edge_padding
    return {
        'facesChecked': len(mesh.polygons),
        'allFaceUVsStayWithinOneAtlasTile': True,
        'minimumTileEdgePaddingPixels': round(min_edge_padding, 3),
    }


uv_audits = {}
for asset_id, obj in objects.items():
    uv_audits[asset_id] = audit_atlas_uv(obj.data)

asset_order = [
    'SC_R_Stalactite28', 'SC_R_Palm28', 'SC_R_Horizon28',
    'SC_R_Wave28', 'SC_R_NavalCannon28',
]
for index, asset_id in enumerate(asset_order):
    objects[asset_id].location = (index * 180, 0, 0)
    row = next(row for row in rows if row['id'] == asset_id)
    row['centerBlender'] = [
        (row['boundsBlender']['min'][k] + row['boundsBlender']['max'][k]) / 2
        for k in range(3)
    ]
    row['atlasUVAudit'] = uv_audits[asset_id]

bpy.context.view_layer.update()
for obj in objects.values():
    obj.select_set(True)

manifest = {
    'build': BUILD,
    'assetOrder': asset_order,
    'assets': rows,
    'libraryTriangles': sum(row['triangles'] for row in rows),
    'placedTrianglesAtEstimatedPlacements': sum(
        row['triangles'] * row['estimatedPlacements'] for row in rows),
    'assetCeilings': TRIANGLE_TARGETS,
    'materialCount': 1,
    'atlas': 'palette.png',
    'atlasDimensions': [128, 128],
    'export': {
        'unitScaleApplied': True,
        'axisForward': '-Z',
        'axisUp': 'Y',
        'sourceToRoblox': 'Roblox XYZ = Blender XZY with Roblox Z = -Blender Y',
    },
}
assert len(rows) == len(asset_order)
for row in rows:
    assert row['triangles'] <= row['triangleTarget'], (row['id'], row['triangles'])
assert manifest['libraryTriangles'] <= 6000

blend_path = ROOT / 'ShipwreckCove_Kit28.blend'
fbx_path = ROOT / 'ShipwreckCove_Kit28.fbx'
manifest_path = ROOT / 'manifest28.json'
verification_path = ROOT / 'export-verification28.json'
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
bpy.ops.export_scene.fbx(filepath=str(fbx_path), use_selection=True,
                         object_types={'MESH'}, apply_unit_scale=True,
                         axis_forward='-Z', axis_up='Y', path_mode='COPY',
                         embed_textures=True, use_mesh_modifiers=True,
                         bake_anim=False)
manifest_path.write_text(json.dumps(manifest, indent=2))

# Re-import the FBX and compare its actual triangle counts, pivots, dimensions, and UVs.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(fbx_path))
expected = {row['id']: row for row in rows}
imported = {}
depsgraph = bpy.context.evaluated_depsgraph_get()
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH':
        continue
    mesh = obj.evaluated_get(depsgraph).to_mesh()
    mesh.calc_loop_triangles()
    row = {
        'vertices': len(mesh.vertices),
        'triangles': len(mesh.loop_triangles),
        'materials': len(mesh.materials),
        'uvLayers': len(mesh.uv_layers),
        'locationBlender': [round(float(value), 6) for value in obj.location],
        'dimensionsBlender': [round(float(value), 6) for value in obj.dimensions],
        'scale': [round(float(value), 6) for value in obj.scale],
        'atlasUVAudit': audit_atlas_uv(mesh),
    }
    assert obj.name in expected, (obj.name, sorted(expected))
    assert row['triangles'] == expected[obj.name]['triangles'], (obj.name, row, expected[obj.name])
    assert row['materials'] == 1 and row['uvLayers'] >= 1, (obj.name, row)
    assert max(abs(value - 1.0) for value in row['scale']) < 1e-5, (obj.name, row['scale'])
    imported[obj.name] = row
    obj.evaluated_get(depsgraph).to_mesh_clear()
assert set(imported) == set(expected), (set(imported), set(expected))
total = sum(row['triangles'] for row in imported.values())
assert total == manifest['libraryTriangles']

report = {
    'build': BUILD,
    'method': 'Blender 5.2 FBX re-import; evaluated meshes, per-face atlas tile padding, object scale, and loop triangles',
    'fbxReimportPassed': True,
    'uniqueTriangles': total,
    'libraryTriangleCeiling': 6000,
    'assets': imported,
    'axisConvention': manifest['export'],
    'cannonAim': {
        'muzzleLocalRobloxXYZ': expected['SC_R_NavalCannon28']['muzzleLocalRobloxXYZ'],
        'muzzleTangentAxisRoblox': expected['SC_R_NavalCannon28']['muzzleTangentAxisRoblox'],
        'trunnionAxisRoblox': expected['SC_R_NavalCannon28']['trunnionAxisRoblox'],
        'barrelElevationDegrees': 35.0,
        'recommendedRootRobloxY': 7.0,
        'carriageElevationDegrees': 0.0,
    },
    'files': {},
}
for filename in ('build_kit28.py', 'ShipwreckCove_Kit28.blend',
                 'ShipwreckCove_Kit28.fbx', 'manifest28.json', 'palette.png'):
    raw = (ROOT / filename).read_bytes()
    report['files'][filename] = {
        'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest(),
    }
verification_path.write_text(json.dumps(report, indent=2))
print(json.dumps({
    'build': BUILD,
    'uniqueTriangles': total,
    'assetTriangles': {name: row['triangles'] for name, row in imported.items()},
    'cannonMuzzleLocalRobloxXYZ': report['cannonAim']['muzzleLocalRobloxXYZ'],
    'cannonMuzzleTangentAxisRoblox': report['cannonAim']['muzzleTangentAxisRoblox'],
}))
