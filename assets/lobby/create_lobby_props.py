"""Build a small human-scale lobby prop kit in a fresh Blender scene."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
SCENE_NAME = "ClassicElevationLobbyProps"

if SCENE_NAME in bpy.data.scenes:
    raise RuntimeError(f"{SCENE_NAME} already exists; use a fresh headless Blender session.")

scene = bpy.data.scenes.new(SCENE_NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = "NONE"


def material(name, color, metallic=0.0, roughness=0.55):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1.0)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return result


TROPHY_GOLD = (0.93, 0.55, 0.08)
BANNER_BLUE = (0.035, 0.25, 0.55)
BANNER_GOLD = (0.9, 0.62, 0.16)
CRYSTAL_BLUE = (0.08, 0.49, 0.93)

materials = {
    "trophyGold": material("trophyGold", TROPHY_GOLD, metallic=0.82, roughness=0.24),
    "bannerBlue": material("bannerBlue", BANNER_BLUE, roughness=0.62),
    "bannerGold": material("bannerGold", BANNER_GOLD, metallic=0.7, roughness=0.28),
    "crystalBlue": material("crystalBlue", CRYSTAL_BLUE, metallic=0.18, roughness=0.18),
}


def mesh_object(name, vertices, faces, material_key, smooth=False):
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(materials[material_key])
    mesh.update()
    for polygon in mesh.polygons:
        polygon.use_smooth = smooth
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    return obj


def add_frustum(vertices, faces, z0, z1, r0, r1, segments=20, cap_bottom=True, cap_top=True):
    start = len(vertices)
    for z, radius in ((z0, r0), (z1, r1)):
        for index in range(segments):
            angle = math.tau * index / segments
            vertices.append((math.cos(angle) * radius, math.sin(angle) * radius, z))
    for index in range(segments):
        next_index = (index + 1) % segments
        faces.append((start + index, start + next_index, start + segments + next_index, start + segments + index))
    if cap_bottom:
        center = len(vertices)
        vertices.append((0, 0, z0))
        for index in range(segments):
            faces.append((center, start + (index + 1) % segments, start + index))
    if cap_top:
        center = len(vertices)
        vertices.append((0, 0, z1))
        for index in range(segments):
            faces.append((center, start + segments + index, start + segments + (index + 1) % segments))


def add_lathe_shell(vertices, faces, profile, segments=24):
    start = len(vertices)
    for radius, z in profile:
        for index in range(segments):
            angle = math.tau * index / segments
            vertices.append((math.cos(angle) * radius, math.sin(angle) * radius, z))
    for row in range(len(profile) - 1):
        for index in range(segments):
            next_index = (index + 1) % segments
            a = start + row * segments + index
            b = start + row * segments + next_index
            c = start + (row + 1) * segments + next_index
            d = start + (row + 1) * segments + index
            faces.append((a, b, c, d))


def add_tube(vertices, faces, points, radius, sides=10):
    start = len(vertices)
    for point_index, point in enumerate(points):
        if point_index == 0:
            tangent = Vector(points[1]) - Vector(point)
        elif point_index == len(points) - 1:
            tangent = Vector(point) - Vector(points[point_index - 1])
        else:
            tangent = Vector(points[point_index + 1]) - Vector(points[point_index - 1])
        tangent.normalize()
        y_axis = Vector((0, 1, 0))
        normal = tangent.cross(y_axis).normalized()
        for side in range(sides):
            angle = math.tau * side / sides
            offset = normal * math.cos(angle) * radius + y_axis * math.sin(angle) * radius
            position = Vector(point) + offset
            vertices.append(tuple(position))
    for row in range(len(points) - 1):
        for side in range(sides):
            next_side = (side + 1) % sides
            faces.append((
                start + row * sides + side,
                start + row * sides + next_side,
                start + (row + 1) * sides + next_side,
                start + (row + 1) * sides + side,
            ))


def trophy_cup():
    vertices, faces = [], []
    add_frustum(vertices, faces, 0.0, 0.28, 0.78, 0.78, cap_top=True)
    add_frustum(vertices, faces, 0.28, 0.48, 0.62, 0.52, cap_bottom=False)
    add_frustum(vertices, faces, 0.48, 1.15, 0.27, 0.2, cap_bottom=False)
    add_lathe_shell(vertices, faces, [
        (0.20, 1.12), (0.40, 1.32), (0.66, 1.92), (0.93, 2.62), (1.08, 3.03),
        (0.94, 3.03), (0.79, 2.58), (0.53, 1.92), (0.30, 1.40), (0.20, 1.12),
    ])
    add_tube(vertices, faces, [(-0.92, 0, 2.67), (-1.42, 0, 2.55), (-1.54, 0, 2.05), (-1.28, 0, 1.72), (-0.72, 0, 1.75)], 0.085)
    add_tube(vertices, faces, [(0.92, 0, 2.67), (1.42, 0, 2.55), (1.54, 0, 2.05), (1.28, 0, 1.72), (0.72, 0, 1.75)], 0.085)
    # A separate rim ring makes the open bowl read from a normal player camera.
    add_tube(vertices, faces, [(math.cos(math.tau * i / 24) * 1.01, math.sin(math.tau * i / 24) * 1.01, 3.03) for i in range(25)], 0.06, 8)
    trophy = mesh_object("TrophyCup__TrophyGold", vertices, faces, "trophyGold", smooth=True)
    trophy.scale.z = 3.3 / trophy.dimensions.z
    bpy.context.view_layer.objects.active = trophy
    trophy.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    trophy.select_set(False)
    return trophy


def floating_crystal():
    segments = 8
    rings = [(0.0, 0.0), (0.72, 0.46), (2.25, 0.72), (3.42, 0.42), (4.0, 0.0)]
    vertices, faces = [], []
    for ring_index, (z, radius) in enumerate(rings):
        if radius == 0:
            vertices.append((0, 0, z))
        else:
            for side in range(segments):
                angle = math.tau * side / segments + (0.19 if ring_index % 2 else 0.0)
                vertices.append((math.cos(angle) * radius, math.sin(angle) * radius, z))
    bottom = 0
    first_ring = 1
    for side in range(segments):
        faces.append((bottom, first_ring + (side + 1) % segments, first_ring + side))
    second_ring = first_ring + segments
    third_ring = second_ring + segments
    for lower, upper in ((first_ring, second_ring), (second_ring, third_ring)):
        for side in range(segments):
            next_side = (side + 1) % segments
            faces.append((lower + side, lower + next_side, upper + next_side, upper + side))
    top = third_ring + segments
    for side in range(segments):
        faces.append((third_ring + side, third_ring + (side + 1) % segments, top))
    return mesh_object("FloatingCrystal__CrystalBlue", vertices, faces, "crystalBlue", smooth=False)


def hanging_banner():
    xs = (-1.6, 0.0, 1.6)
    rows = [(7.0, 0.0), (5.25, 0.10), (3.5, 0.16), (1.75, 0.11), (1.0, 0.04)]
    thickness = 0.075
    vertices, faces = [], []
    for direction in (1, -1):
        for z, curve in rows:
            for x in xs:
                vertices.append((x, curve + direction * thickness, z))
        vertices.append((0, 0.12 + direction * thickness, 0.0))
    layer_size = len(rows) * len(xs) + 1
    for layer, reverse in ((0, False), (layer_size, True)):
        for row in range(len(rows) - 1):
            for column in range(len(xs) - 1):
                a = layer + row * 3 + column
                quad = (a, a + 1, a + 4, a + 3)
                faces.append(tuple(reversed(quad)) if reverse else quad)
        tail = layer + len(rows) * 3
        last_row = layer + (len(rows) - 1) * 3
        for column in range(2):
            triangle = (last_row + column, last_row + column + 1, tail)
            faces.append(tuple(reversed(triangle)) if reverse else triangle)
    boundary = [0, 1, 2, 5, 8, 11, 14, layer_size - 1, 12, 9, 6, 3]
    for index, front in enumerate(boundary):
        back = front + layer_size
        next_front = boundary[(index + 1) % len(boundary)]
        next_back = next_front + layer_size
        faces.append((front, next_front, next_back, back))
    blue = mesh_object("HangingBanner__BannerBlue", vertices, faces, "bannerBlue", smooth=False)

    trim_vertices, trim_faces = [], []
    # The trim sits on the front cloth face, visible from the approach camera.
    add_tube(trim_vertices, trim_faces, [(-1.53, -0.18, 7.0), (0, -0.18, 7.0), (1.53, -0.18, 7.0)], 0.047, 7)
    add_tube(trim_vertices, trim_faces, [(-1.53, -0.18, 7.0), (-1.53, -0.18, 1.02), (0, -0.23, 0.06)], 0.047, 7)
    add_tube(trim_vertices, trim_faces, [(1.53, -0.18, 7.0), (1.53, -0.18, 1.02), (0, -0.23, 0.06)], 0.047, 7)
    gold = mesh_object("HangingBanner__BannerGold", trim_vertices, trim_faces, "bannerGold", smooth=True)
    return blue, gold


props = [trophy_cup(), floating_crystal(), *hanging_banner()]

# The kit is exported laid out left-to-right for easy Studio inspection. Each mesh's local origin
# is its prop's bottom centre, so it can be repositioned without a corrective vertical offset.
props[0].location = (-5.2, 0, 0)
props[1].location = (0, 0, 0)
props[2].location = (5.2, 0, 0)
props[3].location = (5.2, 0, 0)

for obj in props:
    obj.select_set(True)
bpy.context.view_layer.objects.active = props[0]
bpy.ops.export_scene.fbx(
    filepath=str(OUT / "ClassicElevationLobbyProps.fbx"),
    use_selection=True,
    object_types={"MESH"},
    axis_forward="-Z",
    axis_up="Y",
    apply_unit_scale=True,
    bake_space_transform=False,
    add_leaf_bones=False,
)

for obj in props:
    obj.data.calc_loop_triangles()

manifest = {
    "scene": SCENE_NAME,
    "authorUnits": "studs",
    "export": "ClassicElevationLobbyProps.fbx",
    "props": [
        {
            "name": "TrophyCup",
            "nominalDimensionsStuds": [3.25, 2.16, 3.3],
            "origin": "bottom center",
            "parts": ["TrophyCup__TrophyGold"],
        },
        {
            "name": "FloatingCrystal",
            "nominalDimensionsStuds": [1.44, 1.44, 4.0],
            "origin": "bottom tip",
            "parts": ["FloatingCrystal__CrystalBlue"],
        },
        {
            "name": "HangingBanner",
            "nominalDimensionsStuds": [3.2, 0.31, 7.0],
            "origin": "bottom tail center",
            "parts": ["HangingBanner__BannerBlue", "HangingBanner__BannerGold"],
        },
    ],
    "colors": {
        "TrophyCup__TrophyGold": list(TROPHY_GOLD),
        "FloatingCrystal__CrystalBlue": list(CRYSTAL_BLUE),
        "HangingBanner__BannerBlue": list(BANNER_BLUE),
        "HangingBanner__BannerGold": list(BANNER_GOLD),
    },
    "meshTriangleCounts": {obj.name: len(obj.data.loop_triangles) for obj in props},
}
(OUT / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

gallery = bpy.data.scenes.new("ClassicElevationLobbyPropsPreview")
gallery.world = bpy.data.worlds.new("LobbyPropsPreviewWorld")
gallery.world.color = (0.035, 0.052, 0.085)
for obj in props:
    copy = obj.copy()
    copy.data = obj.data.copy()
    gallery.collection.objects.link(copy)

bpy.context.window.scene = gallery
bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, -0.01))
floor = bpy.context.object
floor.name = "PreviewFloor"
floor.data.materials.append(material("PreviewFloor", (0.11, 0.14, 0.18), roughness=0.85))
camera_data = bpy.data.cameras.new("Camera")
camera = bpy.data.objects.new("Camera", camera_data)
gallery.collection.objects.link(camera)
camera.location = (10.5, -19, 9.5)
camera.rotation_euler = (Vector((0.6, 0, 2.8)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 15.0
gallery.camera = camera
gallery.render.engine = "BLENDER_WORKBENCH"
gallery.display.shading.light = "STUDIO"
gallery.display.shading.color_type = "MATERIAL"
gallery.display.shading.show_shadows = True
gallery.display.shading.show_cavity = True
gallery.render.resolution_x = 1400
gallery.render.resolution_y = 800
gallery.render.resolution_percentage = 100
gallery.render.image_settings.file_format = "PNG"
gallery.render.filepath = str(OUT / "preview.png")
bpy.ops.render.render(write_still=True)

bpy.context.window.scene = scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "ClassicElevationLobbyProps.blend"))
print(json.dumps(manifest, indent=2))
