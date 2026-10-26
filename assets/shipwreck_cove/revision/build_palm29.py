"""Split the approved Kit28 palm into reusable trunk and crown models."""
from pathlib import Path
import hashlib
import json
import math

import bpy


ROOT = Path(__file__).resolve().parent
SOURCE_BLEND = ROOT / 'ShipwreckCove_Kit28.blend'
BUILD = 'SC_PALM_29'
TRUNK_NAME = 'SC_R_PalmTrunk29'
CROWN_NAME = 'SC_R_PalmCrown29'
TRUNK_HEIGHT = 24.5
TRUNK_SCAR_COUNT = 13
TRUNK_SCAR_WIDTH = 0.10
TRUNK_SCAR_LIFT = 0.05
TRIANGLE_LIMIT = 2100

def face_components(mesh):
    faces_at_vertex = [[] for _ in mesh.vertices]
    for polygon in mesh.polygons:
        for vertex_index in polygon.vertices:
            faces_at_vertex[vertex_index].append(polygon.index)

    remaining = set(range(len(mesh.polygons)))
    components = []
    while remaining:
        pending = [remaining.pop()]
        component = []
        while pending:
            face_index = pending.pop()
            component.append(face_index)
            for vertex_index in mesh.polygons[face_index].vertices:
                for adjacent in faces_at_vertex[vertex_index]:
                    if adjacent in remaining:
                        remaining.remove(adjacent)
                        pending.append(adjacent)
        components.append(component)
    return components


def copy_faces(source_mesh, face_indexes, name, material):
    vertex_indexes = sorted({vertex_index
                             for face_index in face_indexes
                             for vertex_index in source_mesh.polygons[face_index].vertices})
    remap = {source_index: output_index
             for output_index, source_index in enumerate(vertex_indexes)}
    vertices = [tuple(source_mesh.vertices[index].co) for index in vertex_indexes]
    faces = [tuple(remap[index] for index in source_mesh.polygons[face_index].vertices)
             for face_index in face_indexes]

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    source_uv = source_mesh.uv_layers.active
    output_uv = mesh.uv_layers.new(name='UVMap')
    for output_polygon, face_index in zip(mesh.polygons, face_indexes):
        source_polygon = source_mesh.polygons[face_index]
        for output_loop, source_loop in zip(output_polygon.loop_indices,
                                            source_polygon.loop_indices):
            output_uv.data[output_loop].uv = source_uv.data[source_loop].uv
    mesh.materials.append(material)
    return mesh


def create_trunk_mesh(name, material):
    side_count = 12
    sections = [(0.0, None, 0.0)]
    for scar_index in range(TRUNK_SCAR_COUNT):
        center_z = TRUNK_HEIGHT * (scar_index + 1) / (TRUNK_SCAR_COUNT + 1)
        half_width = TRUNK_SCAR_WIDTH / 2
        sections.extend([
            (center_z - half_width, scar_index, 0.0),
            (center_z, scar_index, TRUNK_SCAR_LIFT),
            (center_z + half_width, scar_index, 0.0),
        ])
    sections.append((TRUNK_HEIGHT, None, 0.0))
    sections.sort(key=lambda section: section[0])
    assert len(sections) == 41

    vertices = []
    for z, scar_index, scar_lift in sections:
        t = z / TRUNK_HEIGHT
        center_x = 2.25 * t ** 1.22
        center_y = 0.62 * math.sin(math.pi * t)
        base_radius = 0.78 * (1 - t) ** 0.72 + 0.22
        for side in range(side_count):
            angle = 2 * math.pi * side / side_count
            knot = (1 + 0.035 * math.sin(4 * angle + 13 * t)
                    + 0.018 * math.cos(7 * angle - 9 * t))
            scar_phase = scar_index if scar_index is not None else 0
            scar_variation = 1 + 0.04 * math.sin(3 * angle + scar_phase * 0.37)
            radius = base_radius * knot + scar_lift * scar_variation
            vertices.append((center_x + radius * math.cos(angle),
                             center_y + radius * math.sin(angle), z))

    faces = [tuple(reversed(range(side_count)))]
    face_colors = [0]
    for section in range(len(sections) - 1):
        lower_z, lower_scar, _ = sections[section]
        upper_z, upper_scar, _ = sections[section + 1]
        scar_lip = (lower_scar is not None and lower_scar == upper_scar
                    and 0 < upper_z - lower_z <= TRUNK_SCAR_WIDTH / 2 + 1e-6)
        for side in range(side_count):
            faces.append((section * side_count + side,
                          section * side_count + (side + 1) % side_count,
                          (section + 1) * side_count + (side + 1) % side_count,
                          (section + 1) * side_count + side))
            face_colors.append(3 if scar_lip else 0)
    faces.append(tuple((len(sections) - 1) * side_count + side
                       for side in range(side_count)))
    face_colors.append(0)

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    uv = mesh.uv_layers.new(name='UVMap')
    for polygon, color in zip(mesh.polygons, face_colors):
        for loop_position, loop_index in enumerate(polygon.loop_indices):
            angle = 2 * math.pi * loop_position / len(polygon.loop_indices)
            uv.data[loop_index].uv = (
                ((color % 8) * 16 + 8 + 2 * math.cos(angle)) / 128,
                1 - ((color // 8) * 16 + 8 + 2 * math.sin(angle)) / 128,
            )
    mesh.materials.append(material)
    return mesh


def bounds(mesh):
    minimum = [min(float(vertex.co[axis]) for vertex in mesh.vertices)
               for axis in range(3)]
    maximum = [max(float(vertex.co[axis]) for vertex in mesh.vertices)
               for axis in range(3)]
    return minimum, maximum


def asset_row(obj, role, notes):
    mesh = obj.data
    mesh.calc_loop_triangles()
    minimum, maximum = bounds(mesh)
    dimensions = [maximum[0] - minimum[0], maximum[2] - minimum[2],
                  maximum[1] - minimum[1]]
    center_blender = [(minimum[axis] + maximum[axis]) / 2 for axis in range(3)]
    return {
        'id': obj.name,
        'role': role,
        'triangles': len(mesh.loop_triangles),
        'vertices': len(mesh.vertices),
        'faces': len(mesh.polygons),
        'dimensionsRobloxXYZ': dimensions,
        'boundsBlender': {'min': minimum, 'max': maximum},
        'centerBlender': center_blender,
        'centerRobloxXYZ': [center_blender[0], center_blender[2], -center_blender[1]],
        'localPivotBlender': [0.0, 0.0, 0.0],
        'assemblyRootRobloxXYZ': [0.0, 0.0, 0.0],
        'objectLocationBlender': [float(value) for value in obj.location],
        'notes': notes,
    }


def audit_uv(mesh):
    layer = mesh.uv_layers.active
    assert layer is not None
    for polygon in mesh.polygons:
        coordinates = [layer.data[loop_index].uv[:] for loop_index in polygon.loop_indices]
        tile_x = {math.floor(u * 8) for u, _ in coordinates}
        tile_y = {math.floor((1 - v) * 8) for _, v in coordinates}
        assert len(tile_x) == 1 and len(tile_y) == 1, (polygon.index, coordinates)
    return {'facesChecked': len(mesh.polygons),
            'allFaceUVsStayWithinOneAtlasTile': True}


def export_one(obj, filepath):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(filepath), use_selection=True, object_types={'MESH'},
        apply_unit_scale=True, axis_forward='-Z', axis_up='Y',
        path_mode='COPY', embed_textures=True, use_mesh_modifiers=True,
        bake_anim=False,
    )


def main():
    assert SOURCE_BLEND.is_file(), SOURCE_BLEND
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE_BLEND))
    source_palm = bpy.data.objects.get('SC_R_Palm28')
    assert source_palm is not None and source_palm.type == 'MESH'
    source_mesh = source_palm.data
    material_source = source_palm.data.materials[0]

    trunk_components = []
    crown_faces = []
    for component in face_components(source_mesh):
        z_values = [source_mesh.vertices[vertex_index].co.z
                    for face_index in component
                    for vertex_index in source_mesh.polygons[face_index].vertices]
        if min(z_values) <= 1e-5:
            trunk_components.append(component)
        else:
            crown_faces.extend(component)
    assert len(trunk_components) == 1, len(trunk_components)
    assert crown_faces, 'No crown geometry was copied from the approved palm.'

    atlas_path = ROOT / 'palette.png'
    material = material_source.copy()
    material.name = 'SC_Palm29OpaquePalette'
    texture_nodes = [node for node in material.node_tree.nodes
                     if node.type == 'TEX_IMAGE']
    assert texture_nodes, 'The Kit28 palette material has no image texture node.'
    texture_nodes[0].interpolation = 'Closest'
    atlas = texture_nodes[0].image
    assert atlas is not None and atlas.size[:] == (128, 128)

    source_uv = source_mesh.uv_layers.active
    assert source_uv is not None
    trunk_faces = trunk_components[0]
    crown_color_tiles = set()
    for face_index in crown_faces:
        polygon = source_mesh.polygons[face_index]
        for loop_index in polygon.loop_indices:
            u, v = source_uv.data[loop_index].uv
            crown_color_tiles.add((math.floor(u * 8), math.floor((1 - v) * 8)))
    assert all(tile_x < 8 and tile_y < 3 for tile_x, tile_y in crown_color_tiles)

    output_objects = []
    root_collection = bpy.data.collections.new('SC_R_Palm29ModelRoot')
    bpy.context.scene.collection.children.link(root_collection)
    trunk = bpy.data.objects.new(TRUNK_NAME, create_trunk_mesh(TRUNK_NAME, material))
    crown_mesh = copy_faces(source_mesh, crown_faces, CROWN_NAME, material)
    crown = bpy.data.objects.new(CROWN_NAME, crown_mesh)
    for obj, role, pair_role in ((trunk, 'trunk', 'pairTrunk'),
                                 (crown, 'crown', 'pairCrown')):
        root_collection.objects.link(obj)
        obj.location = (0.0, 0.0, 0.0)
        obj['Build'] = BUILD
        obj['Family'] = 'vegetation'
        obj['Role'] = role
        obj['PairRole'] = pair_role
        obj['ModelRoot'] = root_collection.name
        obj['VisualOnly'] = True
        output_objects.append(obj)
    source_palm.hide_viewport = True
    source_palm.hide_render = True
    source_palm.hide_set(True)
    for obj in list(bpy.context.scene.objects):
        if obj not in output_objects:
            bpy.data.objects.remove(obj, do_unlink=True)

    rows = [
        asset_row(trunk, 'trunk',
                  'Ground pivot at the assembly root. Curved 24.5-stud trunk with 13 raised '
                  '0.10-stud bark scar rings; narrow tan lips sit over a wood atlas body.'),
        asset_row(crown, 'crown',
                  'Ground pivot at the shared assembly root; exact approved Kit28 crown '
                  'geometry, including nine fronds and three coconuts, copied without reshaping.'),
    ]
    total_triangles = sum(row['triangles'] for row in rows)
    assert total_triangles <= TRIANGLE_LIMIT, (total_triangles, TRIANGLE_LIMIT)
    assert all(row['localPivotBlender'] == [0.0, 0.0, 0.0] for row in rows)
    uv_audits = {obj.name: audit_uv(obj.data) for obj in output_objects}
    for row in rows:
        row['atlasUVAudit'] = uv_audits[row['id']]
        row['localScaleBlender'] = [1.0, 1.0, 1.0]
        row['atlas'] = atlas_path.name
    rows[0]['scarCount'] = TRUNK_SCAR_COUNT
    rows[0]['scarWidthStuds'] = TRUNK_SCAR_WIDTH
    rows[0]['scarRaisedRadiusStuds'] = TRUNK_SCAR_LIFT
    rows[0]['sidesAround'] = 12

    blend_path = ROOT / 'ShipwreckCove_Palm29.blend'
    trunk_fbx = ROOT / 'SC_R_PalmTrunk29.fbx'
    crown_fbx = ROOT / 'SC_R_PalmCrown29.fbx'
    manifest_path = ROOT / 'manifest29.json'
    verification_path = ROOT / 'export-verification29.json'
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    export_one(trunk, trunk_fbx)
    export_one(crown, crown_fbx)

    manifest = {
        'build': BUILD,
        'sourceBuild': 'SC_KIT_28',
        'sourceAsset': 'SC_R_Palm28',
        'assetOrder': [row['id'] for row in rows],
        'assembly': {
            'modelRoot': root_collection.name,
            'trunkPairRole': 'pairTrunk',
            'crownPairRole': 'pairCrown',
            'localRootBlenderXYZ': [0.0, 0.0, 0.0],
            'dimensionsRobloxXYZ': [
                max(row['boundsBlender']['max'][0] for row in rows)
                - min(row['boundsBlender']['min'][0] for row in rows),
                max(row['boundsBlender']['max'][2] for row in rows),
                max(row['boundsBlender']['max'][1] for row in rows)
                - min(row['boundsBlender']['min'][1] for row in rows),
            ],
            'centerRobloxXYZ': [
                (max(row['boundsBlender']['max'][0] for row in rows)
                 + min(row['boundsBlender']['min'][0] for row in rows)) / 2,
                max(row['boundsBlender']['max'][2] for row in rows) / 2,
                -(max(row['boundsBlender']['max'][1] for row in rows)
                  + min(row['boundsBlender']['min'][1] for row in rows)) / 2,
            ],
            'trunkTopBlenderXYZ': [2.25, 0.0, TRUNK_HEIGHT],
            'trunkTopRobloxXYZ': [2.25, TRUNK_HEIGHT, 0.0],
            'placement': 'Place both models at the same root to assemble the full palm.',
        },
        'assets': rows,
        'libraryTriangles': total_triangles,
        'triangleLimit': TRIANGLE_LIMIT,
        'materialCount': 1,
        'atlas': atlas_path.name,
        'atlasDimensions': [128, 128],
        'export': {
            'unitScaleApplied': True,
            'axisForward': '-Z',
            'axisUp': 'Y',
            'sourceToRoblox': 'Roblox XYZ = Blender XZY with Roblox Z = -Blender Y',
            'oneMeshModelPerFBX': True,
        },
        'files': [trunk_fbx.name, crown_fbx.name, blend_path.name, atlas_path.name],
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')

    imported = {}
    for path in (trunk_fbx, crown_fbx):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(path))
        imported_objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
        assert len(imported_objects) == 1, (path.name, len(imported_objects))
        obj = imported_objects[0]
        mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        mesh.calc_loop_triangles()
        expected = next(row for row in rows if row['id'] == obj.name)
        assert len(mesh.loop_triangles) == expected['triangles'], (path.name, len(mesh.loop_triangles), expected)
        assert len(mesh.uv_layers) >= 1 and len(mesh.materials) == 1, path.name
        assert all(abs(float(value)) < 1e-5 for value in obj.location), (path.name, tuple(obj.location))
        imported[obj.name] = {
            'vertices': len(mesh.vertices),
            'triangles': len(mesh.loop_triangles),
            'materials': len(mesh.materials),
            'uvLayers': len(mesh.uv_layers),
            'locationBlender': [round(float(value), 6) for value in obj.location],
            'dimensionsBlender': [round(float(value), 6) for value in obj.dimensions],
            'atlasUVAudit': audit_uv(mesh),
        }
        obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()

    assert set(imported) == {row['id'] for row in rows}, (set(imported), rows)
    assert sum(row['triangles'] for row in imported.values()) == total_triangles
    file_names = (Path(__file__).name, blend_path.name, trunk_fbx.name,
                  crown_fbx.name, manifest_path.name, atlas_path.name)
    file_hashes = {}
    for filename in file_names:
        data = (ROOT / filename).read_bytes()
        file_hashes[filename] = {
            'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest(),
        }
    verification = {
        'build': BUILD,
        'method': 'Blender FBX re-import; object count, evaluated triangles, pivots, materials, and atlas UV tiles',
        'fbxReimportPassed': True,
        'uniqueTriangles': total_triangles,
        'triangleLimit': TRIANGLE_LIMIT,
        'assets': imported,
        'files': file_hashes,
    }
    verification_path.write_text(json.dumps(verification, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({
        'build': BUILD,
        'uniqueTriangles': total_triangles,
        'assets': {name: row['triangles'] for name, row in imported.items()},
        'dimensionsRobloxXYZ': {row['id']: row['dimensionsRobloxXYZ'] for row in rows},
        'centerRobloxXYZ': {row['id']: row['centerRobloxXYZ'] for row in rows},
        'fbxReimportPassed': True,
    }))


if __name__ == '__main__':
    main()
