"""Build a small editable set of low-poly Shipwreck Cove ocean details."""
from pathlib import Path
import hashlib
import json
import math

import bpy


ROOT = Path(__file__).resolve().parent
BUILD = 'SC_WATER_30'
MODEL_ROOT = 'SC_R_Water30ModelRoot'
ASSET_DEFINITIONS = [
    {
        'name': 'SC_WaterPatch30',
        'family': 'water',
        'role': 'shallow_water_patch',
        'file': 'SC_WaterPatch30.fbx',
        'studioTint': '#287F84',
        'description': 'Broad, softly irregular, shallow water surface with gentle fixed undulation.',
        'factory': 'create_shallow_patch',
    },
    {
        'name': 'SC_WaterRipple30',
        'family': 'foam',
        'role': 'ocean_ripple_ribbon',
        'file': 'SC_WaterRipple30.fbx',
        'studioTint': '#55B9B0',
        'description': 'Long, low, curved and tapered aqua ripple ribbon.',
        'factory': 'create_ripple_ribbon',
    },
    {
        'name': 'SC_WaterFoam30',
        'family': 'foam',
        'role': 'broken_curl_foam',
        'file': 'SC_WaterFoam30.fbx',
        'studioTint': '#D9EEE5',
        'description': 'Three small, separated foam curls that sit near one edge of the ripple.',
        'factory': 'create_broken_foam',
    },
    {
        'name': 'SC_Headland30',
        'family': 'cliff',
        'role': 'continuous_headland_wall',
        'file': 'SC_Headland30.fbx',
        'studioTint': None,
        'description': 'SC revision 13 headland wall with its detached low support shelves removed and the front edge set back.',
        'factory': 'create_headland',
    },
]


def color_from_hex(hex_value):
    components = [int(hex_value[index:index + 2], 16) / 255
                  for index in (1, 3, 5)]
    return tuple(component / 12.92 if component <= 0.04045
                 else ((component + 0.055) / 1.055) ** 2.4
                 for component in components)


def create_material(name, tint, roughness):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color_from_hex(tint), 1.0)
    material.use_nodes = True
    shader = next(node for node in material.node_tree.nodes
                  if node.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*color_from_hex(tint), 1.0)
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Metallic'].default_value = 0.0
    return material


def make_mesh(name, vertices, faces, material, smooth=True):
    mesh = bpy.data.meshes.new(name + 'Mesh')
    mesh.from_pydata(vertices, [], faces)
    mesh.update(calc_edges=True)
    mesh.materials.append(material)
    uv_layer = mesh.uv_layers.new(name='UVMap')
    extent_x = max(vertex[0] for vertex in vertices) - min(vertex[0] for vertex in vertices)
    extent_y = max(vertex[1] for vertex in vertices) - min(vertex[1] for vertex in vertices)
    min_x = min(vertex[0] for vertex in vertices)
    min_y = min(vertex[1] for vertex in vertices)
    for polygon in mesh.polygons:
        polygon.use_smooth = smooth
        for loop_index in polygon.loop_indices:
            x, y, _ = vertices[mesh.loops[loop_index].vertex_index]
            uv_layer.data[loop_index].uv = (
                (x - min_x) / max(extent_x, 1e-6),
                (y - min_y) / max(extent_y, 1e-6),
            )
    return mesh


def create_shallow_patch(material):
    segment_count = 30
    ring_count = 5
    radius_x = 50.0
    radius_y = 50.0
    vertices = [(0.0, 0.0, 0.020)]
    rings = []
    for ring_index in range(1, ring_count + 1):
        radius = ring_index / ring_count
        ring = []
        for segment in range(segment_count):
            angle = 2.0 * math.pi * segment / segment_count
            outline = (1.0 + 0.034 * math.sin(3.0 * angle + 0.35)
                       + 0.020 * math.cos(5.0 * angle - 0.7)
                       + 0.010 * math.sin(8.0 * angle + 1.1))
            x = radius_x * radius * outline * math.cos(angle)
            y = radius_y * radius * outline * math.sin(angle)
            fade = 0.18 + 0.82 * (1.0 - radius)
            z = (0.020 + fade * 0.90 * (0.014 * math.sin(0.12 * x + 0.09 * y)
                                        + 0.010 * math.cos(0.07 * x - 0.12 * y)
                                        + 0.008 * math.sin(0.17 * y + 0.7)))
            ring.append(len(vertices))
            vertices.append((x, y, z))
        rings.append(ring)

    faces = []
    for segment in range(segment_count):
        faces.append((0, rings[0][segment], rings[0][(segment + 1) % segment_count]))
    for ring_index in range(1, ring_count):
        inner = rings[ring_index - 1]
        outer = rings[ring_index]
        for segment in range(segment_count):
            following = (segment + 1) % segment_count
            faces.append((inner[segment], outer[segment],
                          outer[following], inner[following]))
    return make_mesh('SC_WaterPatch30', vertices, faces, material)


def ripple_center(t):
    x = (t - 0.5) * 16.0
    y = 0.15 + 0.35 * math.sin(math.pi * t) + 0.05 * math.sin(2.0 * math.pi * t)
    return x, y


def ripple_tangent(t):
    low = max(0.0, t - 0.001)
    high = min(1.0, t + 0.001)
    x0, y0 = ripple_center(low)
    x1, y1 = ripple_center(high)
    dx = x1 - x0
    dy = y1 - y0
    magnitude = math.hypot(dx, dy)
    return dx / magnitude, dy / magnitude


def build_ribbon(vertices, faces, stations, across_count, sample_fn):
    first_vertex = len(vertices)
    for station in range(stations):
        t = station / (stations - 1)
        for across in range(across_count + 1):
            v = across / across_count * 2.0 - 1.0
            vertices.append(sample_fn(t, v))
    for station in range(stations - 1):
        for across in range(across_count):
            a = first_vertex + station * (across_count + 1) + across
            b = a + across_count + 1
            faces.append((a, b, b + 1, a + 1))


def create_ripple_ribbon(material):
    vertices = []
    faces = []
    stations = 25
    across_count = 4

    def sample(t, v):
        x, y = ripple_center(t)
        tangent_x, tangent_y = ripple_tangent(t)
        normal_x, normal_y = -tangent_y, tangent_x
        half_width = 0.035 + 0.525 * math.sin(math.pi * t) ** 0.78
        half_width *= 1.0 + 0.06 * math.sin(5.0 * math.pi * t)
        x += normal_x * v * half_width
        y += normal_y * v * half_width
        z = (0.0175 + 1.4 * (0.009 * math.sin(math.pi * t)
                             + 0.006 * math.cos(math.pi * v)
                             + 0.0025 * math.sin(4.0 * math.pi * t + v)))
        return x, y, z

    build_ribbon(vertices, faces, stations, across_count, sample)
    return make_mesh('SC_WaterRipple30', vertices, faces, material)


def create_broken_foam(material):
    vertices = []
    faces = []
    stations = 10
    across_count = 4
    fragments = [
        {'center': 0.31, 'span': 0.105, 'offset': 0.53, 'width': 0.25, 'bend': -0.10},
        {'center': 0.51, 'span': 0.092, 'offset': -0.52, 'width': 0.22, 'bend': 0.13},
        {'center': 0.70, 'span': 0.080, 'offset': 0.48, 'width': 0.19, 'bend': -0.14},
    ]
    for fragment_index, fragment in enumerate(fragments):
        def sample(u, v, fragment=fragment, fragment_index=fragment_index):
            t = fragment['center'] + (u - 0.5) * fragment['span']
            x, y = ripple_center(t)
            tangent_x, tangent_y = ripple_tangent(t)
            normal_x, normal_y = -tangent_y, tangent_x
            taper = math.sin(math.pi * u) ** 0.58
            scallop = 0.83 + 0.17 * math.sin(4.0 * math.pi * u + fragment_index)
            half_width = 0.035 + fragment['width'] * taper * scallop
            x += normal_x * (fragment['offset'] + v * half_width)
            y += normal_y * (fragment['offset'] + v * half_width)
            x += fragment['bend'] * math.sin(math.pi * u)
            z = (0.041 + 0.009 * math.sin(math.pi * u)
                 + 0.004 * math.cos(math.pi * v))
            return x, y, z

        build_ribbon(vertices, faces, stations, across_count, sample)
    return make_mesh('SC_WaterFoam30', vertices, faces, material)


def connected_face_components(mesh):
    faces_at_vertex = [[] for _ in mesh.vertices]
    for polygon in mesh.polygons:
        for vertex_index in polygon.vertices:
            faces_at_vertex[vertex_index].append(polygon.index)

    remaining = set(range(len(mesh.polygons)))
    components = []
    while remaining:
        stack = [remaining.pop()]
        component = []
        while stack:
            face_index = stack.pop()
            component.append(face_index)
            for vertex_index in mesh.polygons[face_index].vertices:
                for adjacent in faces_at_vertex[vertex_index]:
                    if adjacent in remaining:
                        remaining.remove(adjacent)
                        stack.append(adjacent)
        components.append(component)
    return components


def copy_headland_mesh(source_mesh, name, material):
    components = connected_face_components(source_mesh)
    components.sort(key=len, reverse=True)
    main_component = components[0]
    source_indexes = sorted({vertex_index
                             for face_index in main_component
                             for vertex_index in source_mesh.polygons[face_index].vertices})
    assert len(source_indexes) == 168, len(source_indexes)
    assert source_indexes == list(range(168)), (source_indexes[0], source_indexes[-1])
    assert len(main_component) == 162, len(main_component)
    assert len(components) == 10, [len(component) for component in components]

    source_uv = source_mesh.uv_layers.active
    assert source_uv is not None, 'The revision 13 cliff atlas UV layer is missing.'
    remap = {source_index: output_index
             for output_index, source_index in enumerate(source_indexes)}
    vertices = [source_mesh.vertices[index].co.copy() for index in source_indexes]

    # Bands 0 and 1 form the recessed front edge; their midpoint is the profile root.
    for station in range(len(vertices) // 8):
        first = source_mesh.vertices[station * 8].co
        second = source_mesh.vertices[station * 8 + 1].co
        root_x = (float(first.x) + float(second.x)) / 2.0
        root_y = (float(first.y) + float(second.y)) / 2.0
        radius = math.hypot(root_x, root_y)
        assert radius > 1.0, (station, root_x, root_y)
        outward_x = root_x / radius
        outward_y = root_y / radius
        for band in (0, 1):
            output_vertex = remap[station * 8 + band]
            vertices[output_vertex].x += outward_x * 7.0
            vertices[output_vertex].y += outward_y * 7.0

    faces = [tuple(remap[index] for index in source_mesh.polygons[face_index].vertices)
             for face_index in main_component]
    mesh = bpy.data.meshes.new(name + 'Mesh')
    mesh.from_pydata(vertices, [], faces)
    mesh.update(calc_edges=True)
    mesh.materials.append(material)
    uv_layer = mesh.uv_layers.new(name=source_uv.name)
    for output_polygon, source_face_index in zip(mesh.polygons, main_component):
        source_polygon = source_mesh.polygons[source_face_index]
        output_polygon.material_index = source_polygon.material_index
        output_polygon.use_smooth = source_polygon.use_smooth
        for output_loop, source_loop in zip(output_polygon.loop_indices,
                                            source_polygon.loop_indices):
            uv_layer.data[output_loop].uv = source_uv.data[source_loop].uv

    details = {
        'source': 'SC_R_HeadlandRidge from ShipwreckCove_Revision13.blend',
        'sourceConnectedComponents': len(components),
        'keptMainComponentVertices': len(source_indexes),
        'keptMainComponentFaces': len(main_component),
        'removedDetachedSupportComponents': len(components) - 1,
        'frontProfileBandsShiftedOutwardStuds': 7.0,
        'frontProfileBandsPerStation': [0, 1],
        'atlasImage': 'palette.png',
        'uvLayer': source_uv.name,
    }
    return mesh, details


def append_headland_mesh():
    source_path = ROOT / 'ShipwreckCove_Revision13.blend'
    assert source_path.is_file(), source_path
    with bpy.data.libraries.load(str(source_path), link=False) as (data_from, data_to):
        assert 'SC_R_HeadlandRidge' in data_from.objects, 'Revision 13 headland mesh is missing.'
        data_to.objects = ['SC_R_HeadlandRidge']
    source_obj = data_to.objects[0]
    assert source_obj is not None and source_obj.type == 'MESH'
    assert len(source_obj.data.materials) == 1, len(source_obj.data.materials)
    material = source_obj.data.materials[0]
    assert material is not None
    mesh, details = copy_headland_mesh(source_obj.data, 'SC_Headland30', material)
    bpy.data.objects.remove(source_obj, do_unlink=True)
    return mesh, details


def audit_palette_uv(mesh):
    uv_layer = mesh.uv_layers.active
    assert uv_layer is not None
    for polygon in mesh.polygons:
        tile_x = set()
        tile_y = set()
        for loop_index in polygon.loop_indices:
            u, v = uv_layer.data[loop_index].uv
            tile_x.add(math.floor(float(u) * 8))
            tile_y.add(math.floor((1.0 - float(v)) * 8))
        assert len(tile_x) == 1 and len(tile_y) == 1, (polygon.index, tile_x, tile_y)
    return {'facesChecked': len(mesh.polygons), 'allFacesStayWithinOnePaletteTile': True}


def asset_row(obj, definition):
    mesh = obj.data
    mesh.calc_loop_triangles()
    bounds = [
        [min(float(vertex.co[axis]) for vertex in mesh.vertices),
         max(float(vertex.co[axis]) for vertex in mesh.vertices)]
        for axis in range(3)
    ]
    dimensions_blender = [maximum - minimum for minimum, maximum in bounds]
    center_blender = [(minimum + maximum) / 2.0 for minimum, maximum in bounds]
    return {
        'id': obj.name,
        'family': definition['family'],
        'role': definition['role'],
        'sourceFile': definition['file'],
        'triangles': len(mesh.loop_triangles),
        'vertices': len(mesh.vertices),
        'faces': len(mesh.polygons),
        'smoothFaceCount': sum(1 for polygon in mesh.polygons if polygon.use_smooth),
        'dimensionsRobloxXYZ': [dimensions_blender[0], dimensions_blender[2], dimensions_blender[1]],
        'boundsBlender': {
            'min': [pair[0] for pair in bounds],
            'max': [pair[1] for pair in bounds],
        },
        'centerBlender': center_blender,
        'centerRobloxXYZ': [center_blender[0], center_blender[2], -center_blender[1]],
        'localPivotBlender': [0.0, 0.0, 0.0],
        'objectLocationBlender': [float(value) for value in obj.location],
        'studioTint': definition['studioTint'],
        'material': obj.data.materials[0].name,
        'usesAtlasTexture': any(node.type == 'TEX_IMAGE'
                                for node in obj.data.materials[0].node_tree.nodes)
                            if obj.data.materials[0].use_nodes else False,
        'notes': definition['description'],
    }


def export_one(obj, path):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={'MESH'},
        apply_unit_scale=True,
        axis_forward='-Z',
        axis_up='Y',
        path_mode='COPY',
        embed_textures=True,
        mesh_smooth_type='FACE',
        use_mesh_modifiers=False,
        bake_anim=False,
    )


def verify_exports(rows):
    verification = {}
    for row in rows:
        path = ROOT / row['sourceFile']
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(path))
        imported = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
        assert len(imported) == 1, (path.name, len(imported))
        obj = imported[0]
        mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles) == row['triangles'], (path.name, len(mesh.loop_triangles))
        assert len(mesh.materials) == 1, (path.name, len(mesh.materials))
        assert len(mesh.uv_layers) >= 1, (path.name, len(mesh.uv_layers))
        assert sum(1 for polygon in mesh.polygons if polygon.use_smooth) == row['smoothFaceCount'], path.name
        uses_atlas = any(
            node.type == 'TEX_IMAGE' and node.image is not None
            for material in mesh.materials if material and material.use_nodes
            for node in material.node_tree.nodes
        )
        assert uses_atlas == row['usesAtlasTexture'], (path.name, uses_atlas)
        atlas_audit = audit_palette_uv(mesh) if uses_atlas else None
        assert all(abs(float(value)) < 1e-5 for value in obj.location), (path.name, tuple(obj.location))
        verification[row['id']] = {
            'fbxReimportPassed': True,
            'triangles': len(mesh.loop_triangles),
            'materials': len(mesh.materials),
            'uvLayers': len(mesh.uv_layers),
            'smoothFaceCount': sum(1 for polygon in mesh.polygons if polygon.use_smooth),
            'usesAtlasTexture': uses_atlas,
            'atlasUVAudit': atlas_audit,
            'dimensionsBlender': [round(float(value), 5) for value in obj.dimensions],
            'locationBlender': [round(float(value), 5) for value in obj.location],
        }
        obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()
    return verification


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = 'NONE'
    bpy.context.preferences.filepaths.save_version = 0
    collection = bpy.data.collections.new(MODEL_ROOT)
    bpy.context.scene.collection.children.link(collection)

    materials = {
        'SC_WaterPatch30': create_material('SC_WaterPatch30Material', '#287F84', 0.42),
        'SC_WaterRipple30': create_material('SC_WaterRipple30Material', '#55B9B0', 0.34),
        'SC_WaterFoam30': create_material('SC_WaterFoam30Material', '#D9EEE5', 0.62),
    }
    factories = {
        'create_shallow_patch': create_shallow_patch,
        'create_ripple_ribbon': create_ripple_ribbon,
        'create_broken_foam': create_broken_foam,
    }
    objects = []
    rows = []
    headland_details = None
    for definition in ASSET_DEFINITIONS:
        if definition['factory'] == 'create_headland':
            mesh, headland_details = append_headland_mesh()
        else:
            mesh = factories[definition['factory']](materials[definition['name']])
        obj = bpy.data.objects.new(definition['name'], mesh)
        collection.objects.link(obj)
        obj.location = (0.0, 0.0, 0.0)
        obj['Build'] = BUILD
        obj['Family'] = definition['family']
        obj['Role'] = definition['role']
        obj['ModelRoot'] = MODEL_ROOT
        obj['VisualOnly'] = True
        obj['RecommendedCanCollide'] = False
        obj['RecommendedCanTouch'] = False
        obj['RecommendedCanQuery'] = False
        obj['MeshEditable'] = True
        if definition['family'] in ('water', 'foam'):
            obj['RuntimeBob'] = 'Apply a subtle eased Roblox Y offset to the placed model.'
            obj['SurfaceDatumOffsetBlenderZ'] = round(
                min(float(vertex.co.z) for vertex in obj.data.vertices), 4)
        if definition['studioTint'] is not None:
            obj.data['FlatTintHex'] = definition['studioTint']
        obj.data['TriangleBudget'] = '100-300 triangles' if definition['family'] in ('water', 'foam') else 'Below 900 triangles'
        row = asset_row(obj, definition)
        if definition['family'] == 'cliff':
            row['headlandCleanup'] = headland_details
            row['atlasUVAudit'] = audit_palette_uv(obj.data)
        rows.append(row)
        objects.append(obj)

    assert all(100 <= row['triangles'] <= 300 for row in rows
               if row['family'] in ('water', 'foam')), rows
    assert all(row['localPivotBlender'] == [0.0, 0.0, 0.0] for row in rows)

    blend_path = ROOT / 'ShipwreckCove_Water30.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    for obj, definition in zip(objects, ASSET_DEFINITIONS):
        export_one(obj, ROOT / definition['file'])

    export_verification = verify_exports(rows)
    hashes = {}
    tracked_files = [Path(__file__).name, blend_path.name]
    tracked_files.extend(definition['file'] for definition in ASSET_DEFINITIONS)
    for filename in tracked_files:
        content = (ROOT / filename).read_bytes()
        hashes[filename] = {
            'bytes': len(content),
            'sha256': hashlib.sha256(content).hexdigest(),
        }

    manifest = {
        'build': BUILD,
        'sourceBuild': 'Shipwreck Cove revision 13 geometry with water presentation refresh',
        'assetOrder': [row['id'] for row in rows],
        'modelRoot': MODEL_ROOT,
        'localRootBlenderXYZ': [0.0, 0.0, 0.0],
        'assets': rows,
        'libraryTriangles': sum(row['triangles'] for row in rows),
        'triangleRangePerWaterAsset': [100, 300],
        'materialCount': len({row['material'] for row in rows}),
        'waterMaterialsUseTextures': False,
        'export': {
            'unitScaleApplied': True,
            'axisForward': '-Z',
            'axisUp': 'Y',
            'sourceToRoblox': 'Roblox XYZ = Blender XZY with Roblox Z = -Blender Y',
            'oneEditableMeshPerFBX': True,
            'surfaceOnly': True,
            'waterFacesSmoothShaded': True,
            'recommendation': 'Set imported MeshParts CanCollide, CanTouch, and CanQuery to false.',
        },
        'runtime': {
            'bob': 'Animate the placed model with a small eased Roblox Y translation; no animation is baked into the meshes.',
        'meshRelief': 'The shallow patch stays within a 0.04-stud vertical envelope; the user controller can add its own eased Y bob.',
            'foam': 'The three foam fragments are islands in their own editable mesh and may be shown or hidden independently.',
            'headland': 'The continuous original cliff wall remains one editable connected component without support shelves.',
        },
        'fbxReimportVerification': export_verification,
        'files': hashes,
    }
    (ROOT / 'manifest30.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({
        'build': BUILD,
        'libraryTriangles': manifest['libraryTriangles'],
        'assets': [{
            'id': row['id'],
            'triangles': row['triangles'],
            'dimensionsRobloxXYZ': row['dimensionsRobloxXYZ'],
            'centerBlender': row['centerBlender'],
        } for row in rows],
        'fbxReimportPassed': all(item['fbxReimportPassed'] for item in export_verification.values()),
    }))


if __name__ == '__main__':
    main()
