"""Build the V8 kit in a separate background Blender process."""

import bpy
import json
import math
import random
from pathlib import Path
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent
exec((BASE / "create_ascent_props.py").read_text().split("RESULT=build()")[0])
OUT = BASE / "v8"
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new("AscentV8JourneyProps")
bpy.context.window.scene = scene
COLORS.update({"Cedar": (.12, .29, .16), "RidgeRock": (.25, .31, .34)})


def fractured_column(col, name, x, y, radius, height, seed, material):
    rng = random.Random(seed)
    vertices = []
    count = 6
    for ring in range(3):
        for i in range(count):
            angle = i * math.tau / count + .12
            r = radius * (1 - ring * .1) * rng.uniform(.89, 1.08)
            z = (0, height * .64, height)[ring]
            if ring == 2:
                z += rng.uniform(-height * .09, height * .04)
            vertices.append((x + math.cos(angle) * r + ring * .18,
                             y + math.sin(angle) * r, z))
    faces = [tuple(range(count - 1, -1, -1))]
    for ring in range(2):
        for i in range(count):
            a, b = ring * count + i, ring * count + (i + 1) % count
            faces.append((a, b, b + count, a + count))
    faces.append(tuple(range(count * 2, count * 3)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    mesh.materials.append(mat(material))


def basalt_columns():
    col = collection("BasaltColumns")
    for i, (x, y, r, h) in enumerate(((-4, 1, 2.5, 13), (-1, 2, 2.8, 24),
                                      (3, 1, 2.6, 19), (5, -2, 2.0, 9), (-2, -2, 2.2, 7))):
        fractured_column(col, "column", x, y, r, h, 801 + i, "Basalt")
    return finish(col, "BasaltColumns", 24)


def ruin_abutment():
    col = collection("RuinAbutment")
    for tier in range(4):
        for i in range(3 if tier < 2 else 2):
            cube(col, "masonry", ((i - 1) * 5.8 + tier * .35, tier * .5, 2 + tier * 4.6),
                 (2.8, 3.8 - tier * .6, 2.15), "Limestone",
                 rot=(0, 0, (i - 1) * .035), bevel=.24)
    fractured_column(col, "broken_pier", 4, 1, 2.9, 24, 812, "Limestone")
    return finish(col, "RuinAbutment", 24)


def cliff_buttress():
    col = collection("CliffButtress")
    for i, (x, y, scale) in enumerate(((-7, 2, (10, 8, 19)), (3, 4, (12, 9, 25)),
                                      (12, 0, (8, 7, 15)), (-1, -5, (14, 9, 6)))):
        ico(col, "fractured_rock", (x, y, scale[2] * .78), scale, "RidgeRock", 820 + i, 2)
    return finish(col, "CliffButtress", 42)


def glacier_serac():
    col = collection("GlacierSerac")
    for i, (x, y, r, h) in enumerate(((-6, 1, 3.8, 20), (-1, 3, 4.5, 34),
                                      (5, 1, 3.8, 28), (9, 4, 2.7, 18))):
        fractured_column(col, "ice_face", x, y, r, h, 830 + i, "Ice")
        ico(col, "snow_lip", (x + .4, y, h - .3), (r * .9, r * .82, .85), "Snow", 840 + i, 1)
    return finish(col, "GlacierSerac", 35)


def snow_ridge():
    col = collection("SnowRidge")
    vertices, faces, snow = [], [], []
    for i in range(9):
        x = -24 + i * 6
        height = 12 + 6 * math.sin(i * .6) + (i % 3) * 1.3
        vertices.extend(((x, -9, 0), (x, -3, height * .65), (x, 2, height), (x, 11, 1)))
    for i in range(8):
        for j in range(3):
            a = i * 4 + j
            face = (a, a + 4, a + 5, a + 1)
            faces.append(face)
            if j == 1:
                snow.append(face)
    for material, selected, lift in (("RidgeRock", faces, 0), ("Snow", snow, .12)):
        mesh = bpy.data.meshes.new(material)
        mesh.from_pydata([(x, y, z + lift) for x, y, z in vertices], [], selected)
        mesh.update()
        obj = bpy.data.objects.new("ridge", mesh)
        col.objects.link(obj)
        mesh.materials.append(mat(material))
    return finish(col, "SnowRidge", 20)


def cedar_lite():
    col = collection("CedarLite")
    cyl_between(col, "trunk", (0, 0, 0), (1.1, .3, 22), .48, "Bark", 10)
    # Keep the V7 branch and foliage-cluster layout; simplify each foliage cluster.
    for tier in range(6):
        z, radius = 6 + tier * 2.55, 6.4 - tier * .7
        for j in range(5):
            angle = j * math.tau / 5 + tier * .87
            end = (math.cos(angle) * radius + .06 * z, math.sin(angle) * radius, z - .6)
            cyl_between(col, "branch", (.06 * z, 0, z), end, .12, "Bark", 7)
            for k in range(2):
                p = Vector(end) * (.72 + k * .19)
                p.z = z + .5 + k * .3
                ico(col, "spray", p, (radius * .37, 1.15, 1.4), "Cedar", tier * 31 + j * 5 + k, 1)
    cone(col, "tip", (1.1, .3, 22.5), 1.7, 0, 5, 10, "Cedar")
    return finish(col, "CedarLite", 24)


props = [basalt_columns(), ruin_abutment(), cliff_buttress(), glacier_serac(), snow_ridge(), cedar_lite()]
objects = [obj for col in scene.collection.children for obj in col.objects if obj.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    obj.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT / "AscentV8Props.fbx"), use_selection=True,
                         object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                         apply_unit_scale=True, bake_space_transform=False, add_leaf_bones=False)
manifest = {"props": props, "colors": {obj.name: list(obj.data.materials[0].diffuse_color[:3]) for obj in objects}}
(OUT / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

gallery = bpy.data.scenes.new("AscentV8Gallery")
gallery.world = bpy.data.worlds.new("V8World")
gallery.world.color = (.09, .11, .13)
for index, prop in enumerate(props):
    for obj in objects:
        if obj.name.startswith(prop["name"] + "__"):
            duplicate = obj.copy()
            duplicate.data = obj.data
            duplicate.matrix_world = Matrix.Translation(((index % 3 - 1) * 40, (index // 3) * 48, 0)) @ obj.matrix_world
            gallery.collection.objects.link(duplicate)
data = bpy.data.cameras.new("GalleryCamera")
camera = bpy.data.objects.new("GalleryCamera", data)
gallery.collection.objects.link(camera)
camera.location = (75, -135, 100)
camera.rotation_euler = (Vector((0, 20, 10)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type, camera.data.ortho_scale = "ORTHO", 156
gallery.camera = camera
gallery.render.engine = "BLENDER_WORKBENCH"
gallery.display.shading.light = "STUDIO"
gallery.display.shading.color_type = "MATERIAL"
gallery.display.shading.show_shadows = True
gallery.render.resolution_x, gallery.render.resolution_y = 1600, 1050
gallery.render.resolution_percentage = 100
gallery.render.filepath = str(OUT / "preview.png")
bpy.context.window.scene = gallery
bpy.ops.render.render(write_still=True)
bpy.context.window.scene = scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "AscentV8Props.blend"))
print(json.dumps({"props": props, "output": str(OUT)}))
