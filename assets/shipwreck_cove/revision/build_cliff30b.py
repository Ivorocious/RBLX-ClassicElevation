"""Build three editable, low-poly landing ledges for Shipwreck Cove."""
from pathlib import Path
import hashlib
import json
import math

import bpy


ROOT = Path(__file__).resolve().parent
BUILD = 'SC_CLIFF_LEDGE_30B'
SOURCE_BLEND = ROOT / 'ShipwreckCove_Revision13.blend'
MODEL_ROOT = 'SC_R_CliffLedges30bModelRoot'
COLORS = {
    'stone': 5,
    'stoneShade': 22,
    'sand': 4,
    'cream': 7,
}
VARIANTS = [
    {
        'name': 'SC_CliffLedge30A',
        'height': 4.4,
        'phase': 0.35,
        'baseScale': (0.70, 0.73),
        'lowerScale': (0.78, 0.76),
        'middleScale': (0.84, 0.86),
        'upperScale': (0.93, 0.92),
        'baseOffset': (0.18, -0.10),
        'middleOffset': (-0.20, 0.13),
        'upperOffset': (0.06, -0.03),
        'notes': 'Low asymmetric ledge with a broad square landing top and a compact broken-rock base.',
    },
    {
        'name': 'SC_CliffLedge30B',
        'height': 5.1,
        'phase': 1.25,
        'baseScale': (0.74, 0.68),
        'lowerScale': (0.80, 0.77),
        'middleScale': (0.87, 0.82),
        'upperScale': (0.92, 0.93),
        'baseOffset': (-0.22, 0.16),
        'middleOffset': (0.16, -0.18),
        'upperOffset': (-0.05, 0.08),
        'notes': 'Offset limestone body with an uneven lower taper and the same full walkable top outline.',
    },
    {
        'name': 'SC_CliffLedge30C',
        'height': 5.8,
        'phase': 2.20,
        'baseScale': (0.67, 0.75),
        'lowerScale': (0.77, 0.82),
        'middleScale': (0.89, 0.84),
        'upperScale': (0.95, 0.91),
        'baseOffset': (0.10, 0.21),
        'middleOffset': (-0.17, -0.10),
        'upperOffset': (0.08, 0.04),
        'notes': 'Tallest ledge with a shifted lower silhouette, pale stone facets, and a full rectangular top.',
    },
]

OUTLINE = [
    (-1.0, -1.0), (-0.5, -1.0), (0.0, -1.0), (0.5, -1.0),
    (1.0, -1.0), (1.0, -0.5), (1.0, 0.0), (1.0, 0.5),
    (1.0, 1.0), (0.5, 1.0), (0.0, 1.0), (-0.5, 1.0),
    (-1.0, 1.0), (-1.0, 0.5), (-1.0, 0.0), (-1.0, -0.5),
]
TOP_HALF_X = 2.9
TOP_HALF_Z = 2.65
SEGMENT_COUNT = len(OUTLINE)


def append_palette_material():
    assert SOURCE_BLEND.is_file(), SOURCE_BLEND
    with bpy.data.libraries.load(str(SOURCE_BLEND), link=False) as (data_from, data_to):
        assert 'SC_RevisionOpaquePalette' in data_from.materials
        data_to.materials = ['SC_RevisionOpaquePalette']
    material = data_to.materials[0]
    assert material is not None
    assert any(node.type == 'TEX_IMAGE' and node.image is not None
               for node in material.node_tree.nodes)
    return material


def ring_point(unit_x, unit_y, scale_x, scale_y, offset_x, offset_y,
               angle_index, ring_index, phase, irregularity):
    variation = (
        0.55 * math.sin(angle_index * 3.0 + phase + ring_index * 0.57)
        + 0.29 * math.cos(angle_index * 5.0 - phase * 0.8)
        + 0.16 * math.sin(angle_index * 7.0 + phase + ring_index * 0.31)
    )
    factor = 1.0 + irregularity * variation
    shear_x = irregularity * 0.10 * math.sin(angle_index * 2.0 + phase)
    shear_y = irregularity * 0.10 * math.cos(angle_index * 3.0 - phase)
    x = unit_x * TOP_HALF_X * scale_x * factor + offset_x + shear_x
    y = unit_y * TOP_HALF_Z * scale_y * factor + offset_y + shear_y
    return (
        max(-TOP_HALF_X, min(TOP_HALF_X, x)),
        max(-TOP_HALF_Z, min(TOP_HALF_Z, y)),
    )


def build_ledge(variant, material):
    height = variant['height']
    phase = variant['phase']
    rings = [
        (0.0, *variant['baseScale'], *variant['baseOffset'], 0.13),
        (0.72, *variant['lowerScale'], *variant['baseOffset'], 0.10),
        (height * 0.52, *variant['middleScale'], *variant['middleOffset'], 0.075),
        (height - 0.92, *variant['upperScale'], *variant['upperOffset'], 0.045),
        (height - 0.30, 0.966, 0.962, 0.0, 0.0, 0.0),
        (height, 1.0, 1.0, 0.0, 0.0, 0.0),
    ]
    vertices = []
    ring_indexes = []
    for ring_index, (z, scale_x, scale_y, offset_x, offset_y, irregularity) in enumerate(rings):
        indexes = []
        for angle_index, (unit_x, unit_y) in enumerate(OUTLINE):
            x, y = ring_point(
                unit_x, unit_y, scale_x, scale_y, offset_x, offset_y,
                angle_index, ring_index, phase, irregularity,
            )
            indexes.append(len(vertices))
            vertices.append((x, y, z))
        ring_indexes.append(indexes)

    faces = []
    face_colors = []
    for layer in range(len(ring_indexes) - 1):
        for side in range(SEGMENT_COUNT):
            following = (side + 1) % SEGMENT_COUNT
            lower = ring_indexes[layer]
            upper = ring_indexes[layer + 1]
            faces.append((lower[side], lower[following], upper[following], upper[side]))
            if layer == 0 and (side + round(phase * 3)) % 5 == 0:
                face_colors.append(COLORS['stoneShade'])
            elif layer in (2, 3) and (side + round(phase * 2)) % 9 == 0:
                face_colors.append(COLORS['sand'])
            elif layer == 4 and (side + round(phase * 4)) % 8 == 0:
                face_colors.append(COLORS['cream'])
            else:
                face_colors.append(COLORS['stone'])

    faces.append(tuple(reversed(ring_indexes[0])))
    face_colors.append(COLORS['stoneShade'])
    faces.append(tuple(ring_indexes[-1]))
    face_colors.append(COLORS['cream'])

    mesh = bpy.data.meshes.new(variant['name'] + 'Mesh')
    mesh.from_pydata(vertices, [], faces)
    mesh.update(calc_edges=True)
    mesh.materials.append(material)
    uv_layer = mesh.uv_layers.new(name='UVMap')
    for polygon, color in zip(mesh.polygons, face_colors):
        polygon.use_smooth = False
        for corner_index, loop_index in enumerate(polygon.loop_indices):
            angle = 2.0 * math.pi * corner_index / len(polygon.loop_indices)
            uv_layer.data[loop_index].uv = (
                ((color % 8) * 16 + 8 + 2 * math.cos(angle)) / 128,
                1.0 - ((color // 8) * 16 + 8 + 2 * math.sin(angle)) / 128,
            )

    mesh.calc_loop_triangles()
    return mesh


def bounds_for_mesh(mesh):
    bounds = [
        [min(float(vertex.co[axis]) for vertex in mesh.vertices),
         max(float(vertex.co[axis]) for vertex in mesh.vertices)]
        for axis in range(3)
    ]
    dimensions = [upper - lower for lower, upper in bounds]
    center = [(lower + upper) / 2.0 for lower, upper in bounds]
    return bounds, dimensions, center


def connected_component_count(mesh):
    faces_at_vertex = [[] for _ in mesh.vertices]
    for polygon in mesh.polygons:
        for vertex_index in polygon.vertices:
            faces_at_vertex[vertex_index].append(polygon.index)
    remaining = set(range(len(mesh.polygons)))
    count = 0
    while remaining:
        count += 1
        stack = [remaining.pop()]
        while stack:
            face_index = stack.pop()
            for vertex_index in mesh.polygons[face_index].vertices:
                for adjacent in faces_at_vertex[vertex_index]:
                    if adjacent in remaining:
                        remaining.remove(adjacent)
                        stack.append(adjacent)
    return count


def watertight_edge_audit(mesh):
    edge_use_counts = {tuple(sorted(edge.vertices)): 0 for edge in mesh.edges}
    for polygon in mesh.polygons:
        for edge_key in polygon.edge_keys:
            normalized = tuple(sorted(edge_key))
            edge_use_counts[normalized] += 1
    return bool(edge_use_counts) and all(count == 2 for count in edge_use_counts.values())


def uv_tile_audit(mesh):
    uv_layer = mesh.uv_layers.active
    assert uv_layer is not None
    for polygon in mesh.polygons:
        tile_x = set()
        tile_y = set()
        for loop_index in polygon.loop_indices:
            u, v = uv_layer.data[loop_index].uv
            tile_x.add(math.floor(float(u) * 8))
            tile_y.add(math.floor((1.0 - float(v)) * 8))
        assert len(tile_x) == 1 and len(tile_y) == 1
    return {'facesChecked': len(mesh.polygons), 'allFacesStayWithinOnePaletteTile': True}


def asset_row(obj, variant):
    mesh = obj.data
    bounds, dimensions, center = bounds_for_mesh(mesh)
    top_height = variant['height']
    top_vertices = [vertex.co for vertex in mesh.vertices
                    if abs(float(vertex.co.z) - top_height) <= 1e-6]
    assert len(top_vertices) == SEGMENT_COUNT
    top_x = max(float(vertex.x) for vertex in top_vertices) - min(float(vertex.x) for vertex in top_vertices)
    top_y = max(float(vertex.y) for vertex in top_vertices) - min(float(vertex.y) for vertex in top_vertices)
    assert top_x >= 5.2 and top_y >= 4.8, (obj.name, top_x, top_y)
    assert abs(dimensions[0] - top_x) <= 1e-6 and abs(dimensions[1] - top_y) <= 1e-6
    mesh.calc_loop_triangles()
    assert connected_component_count(mesh) == 1
    assert watertight_edge_audit(mesh)
    assert 100 <= len(mesh.loop_triangles) <= 300
    return {
        'id': obj.name,
        'family': 'cliff',
        'role': 'walkable_landing_ledge_visual',
        'triangles': len(mesh.loop_triangles),
        'triangleCeiling': 300,
        'vertices': len(mesh.vertices),
        'faces': len(mesh.polygons),
        'dimensionsRobloxXYZ': [dimensions[0], dimensions[2], dimensions[1]],
        'boundsBlender': {'min': [item[0] for item in bounds], 'max': [item[1] for item in bounds]},
        'centerBlender': center,
        'centerRobloxXYZ': [center[0], center[2], -center[1]],
        'localPivotBlender': [0.0, 0.0, 0.0],
        'objectLocationBlender': [float(value) for value in obj.location],
        'mount': 'ground',
        'topY': top_height,
        'topYRoblox': top_height,
        'topFootprintRobloxXZ': [top_x, top_y],
        'flatTop': True,
        'topCoversColliderFootprintRobloxXZ': [5.2, 4.8],
        'topCornerMismatchStuds': 0.0,
        'meshComponents': 1,
        'watertight': watertight_edge_audit(mesh),
        'atlas': 'palette.png',
        'atlasUVAudit': uv_tile_audit(mesh),
        'material': mesh.materials[0].name,
        'notes': variant['notes'],
    }


def export_one(obj, filepath):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(filepath),
        use_selection=True,
        object_types={'MESH'},
        apply_unit_scale=True,
        axis_forward='-Z',
        axis_up='Y',
        path_mode='COPY',
        embed_textures=True,
        mesh_smooth_type='OFF',
        use_mesh_modifiers=False,
        bake_anim=False,
    )


def verify_exports(rows):
    verification = {}
    for row in rows:
        path = ROOT / row['sourceFile']
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(path))
        objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
        assert len(objects) == 1, (path.name, len(objects))
        obj = objects[0]
        mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles) == row['triangles'], (path.name, len(mesh.loop_triangles))
        assert len(mesh.vertices) == row['vertices'], (path.name, len(mesh.vertices))
        assert len(mesh.materials) == 1 and len(mesh.uv_layers) == 1, path.name
        assert connected_component_count(mesh) == 1, path.name
        assert watertight_edge_audit(mesh), path.name
        assert uv_tile_audit(mesh)['allFacesStayWithinOnePaletteTile'], path.name
        assert all(abs(float(value)) < 1e-5 for value in obj.location), (path.name, list(obj.location))
        textured = any(
            node.type == 'TEX_IMAGE' and node.image is not None
            for material in mesh.materials if material and material.use_nodes
            for node in material.node_tree.nodes
        )
        assert textured, (path.name, 'palette texture missing')
        verification[row['id']] = {
            'fbxReimportPassed': True,
            'triangles': len(mesh.loop_triangles),
            'vertices': len(mesh.vertices),
            'connectedComponents': 1,
            'materials': len(mesh.materials),
            'uvLayers': len(mesh.uv_layers),
            'atlasTexturePresent': textured,
            'atlasUVAudit': uv_tile_audit(mesh),
            'dimensionsBlender': [round(float(value), 5) for value in obj.dimensions],
            'locationBlender': [round(float(value), 5) for value in obj.location],
        }
        obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()
    return verification


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = 'NONE'
    bpy.context.preferences.filepaths.save_version = 0
    manifest_path = ROOT / 'manifest30b.json'
    previous_manifest = {}
    if manifest_path.is_file():
        previous_manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    previous_assets = {
        item.get('id'): item for item in previous_manifest.get('assets', [])
        if isinstance(item, dict) and item.get('id')
    }
    collection = bpy.data.collections.new(MODEL_ROOT)
    bpy.context.scene.collection.children.link(collection)
    material = append_palette_material()

    objects = []
    rows = []
    for variant in VARIANTS:
        obj = bpy.data.objects.new(variant['name'], build_ledge(variant, material))
        collection.objects.link(obj)
        obj.location = (0.0, 0.0, 0.0)
        obj['Build'] = BUILD
        obj['Family'] = 'cliff'
        obj['Role'] = 'walkable_landing_ledge_visual'
        obj['ModelRoot'] = MODEL_ROOT
        obj['VisualOnly'] = True
        obj['RecommendedCanCollide'] = False
        obj['RecommendedCanTouch'] = False
        obj['RecommendedCanQuery'] = False
        obj['MeshEditable'] = True
        obj['TopY'] = variant['height']
        obj['ColliderTopFootprintRobloxXZ'] = [5.2, 4.8]
        obj['TopCornerMismatchStuds'] = 0.0
        rows.append(asset_row(obj, variant))
        objects.append(obj)

    blend_path = ROOT / 'ShipwreckCove_CliffLedges30b.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    for obj, row in zip(objects, rows):
        row['sourceFile'] = obj.name + '.fbx'
        export_one(obj, ROOT / row['sourceFile'])

    export_verification = verify_exports(rows)
    tracked_files = [Path(__file__).name, blend_path.name]
    tracked_files.extend(row['sourceFile'] for row in rows)
    file_hashes = {}
    for filename in tracked_files:
        content = (ROOT / filename).read_bytes()
        file_hashes[filename] = {'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()}

    uploaded_assets = {}
    local_only_assets = []
    for row in rows:
        previous = previous_assets.get(row['id'], {})
        receipt_name = previous.get('uploadReceipt')
        uploaded_hash = previous.get('uploadedFbxSha256')
        current_hash = file_hashes[row['sourceFile']]['sha256']
        receipt_path = ROOT / receipt_name if isinstance(receipt_name, str) else None
        if receipt_path and receipt_path.is_file() and uploaded_hash == current_hash:
            receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
            request = receipt.get('request', {})
            creator = request.get('creationContext', {}).get('creator', {})
            asset_id = str(receipt.get('assetId', ''))
            if (receipt.get('state') == 'complete' and receipt.get('sha256') == current_hash
                    and request.get('displayName') == row['id'] and creator.get('userId') == '86069177'
                    and asset_id == str(previous.get('robloxModelAssetId', ''))):
                row['robloxModelAssetId'] = asset_id
                row['uploadReceipt'] = receipt_name
                row['uploadedFbxSha256'] = current_hash
                row['uploadStatus'] = 'complete'
                uploaded_assets[row['id']] = asset_id
                file_hashes[receipt_name] = {
                    'bytes': receipt_path.stat().st_size,
                    'sha256': hashlib.sha256(receipt_path.read_bytes()).hexdigest(),
                }
                continue
        row['uploadStatus'] = 'local_only'
        local_only_assets.append(row['id'])

    manifest = {
        'build': BUILD,
        'sourceBuild': 'SC_CAVE_KIT_26 / SC_R_CrumbleStone26 landing-stone scale review',
        'assetOrder': [row['id'] for row in rows],
        'modelRoot': MODEL_ROOT,
        'units': '1 Blender unit = 1 intended Roblox stud',
        'coordinates': 'Blender local XYZ maps to Roblox XYZ as [x, z, -y] with -Z forward and Y up FBX axes.',
        'assetCeiling': 300,
        'libraryTriangles': sum(row['triangles'] for row in rows),
        'materialCount': 1,
        'atlas': 'palette.png',
        'upload': {
            'creatorUserId': '86069177',
            'uploadedCount': len(uploaded_assets),
            'uploadedAssets': uploaded_assets,
            'localOnlyAssets': local_only_assets,
        },
        'colliderTopFootprintRobloxXZ': [5.2, 4.8],
        'topCornerMismatchStuds': 0.0,
        'assets': rows,
        'export': {
            'unitScaleApplied': True,
            'axisForward': '-Z',
            'axisUp': 'Y',
            'oneEditableMeshPerFBX': True,
            'topSurface': 'Single flat rectangular face spanning the full manifest XZ footprint.',
            'fbxTexture': 'The existing 128x128 palette atlas is embedded in each FBX.',
            'sourceToRoblox': 'Roblox XYZ = Blender XZY with Roblox Z = -Blender Y',
        },
        'fbxReimportVerification': export_verification,
        'files': file_hashes,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({
        'build': BUILD,
        'libraryTriangles': manifest['libraryTriangles'],
        'assets': [{
            'id': row['id'],
            'triangles': row['triangles'],
            'dimensionsRobloxXYZ': row['dimensionsRobloxXYZ'],
            'centerBlender': row['centerBlender'],
            'topY': row['topY'],
            'topFootprintRobloxXZ': row['topFootprintRobloxXZ'],
        } for row in rows],
        'fbxReimportPassed': all(item['fbxReimportPassed'] for item in export_verification.values()),
    }))


if __name__ == '__main__':
    main()
