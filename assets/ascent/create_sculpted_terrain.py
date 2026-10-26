"""Asymmetric playable shelves and low basalt vent rims for Classic Ascent."""
import bpy
import bmesh
import json
import math
import random
from pathlib import Path
from mathutils import Vector, Matrix

BASE = Path(__file__).resolve().parent
exec((BASE / "create_ascent_props.py").read_text().split("RESULT=build()")[0])
OUT = BASE / "sculpted_terrain"
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new("SculptedTerrain")
bpy.context.window.scene = scene
COLORS.update(ShelfPath=(.34, .39, .34), ShelfRidge=(.25, .31, .29),
              ShelfTalus=(.29, .34, .32), CraterRim=(.13, .10, .085),
              CraterFloor=(.045, .035, .03))


def mesh_object(col, name, vertices, faces, material):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    mesh.materials.append(mat(material))
    return obj


col = collection("SculptedShelf")
outline = [(-8, -39), (-6, -43), (5, -42), (8, -38),
           (8, 38), (5, 43), (-6, 42), (-8, 38)]
n = len(outline)
vertices = [(x*1.08, y, 8) for x, y in outline] + [(x, y, 20) for x, y in outline]
faces = [tuple(range(n-1, -1, -1)), tuple(range(n, 2*n))]
faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
mesh_object(col, "Path", vertices, faces, "ShelfPath")


def flank(name, side, material, seed):
    rng = random.Random(seed)
    rows = [-43, -28, -12, 5, 23, 43]
    vertices = []
    for row, y in enumerate(rows):
        end = row in (0, len(rows)-1)
        if side > 0:
            profile = [(7.8, 20), (10+rng.uniform(-.5, .6), 23 if end else rng.uniform(25, 28)),
                       (13.5+rng.uniform(-.6, .6), rng.uniform(8, 13)), (18, 0)]
        else:
            profile = [(-7.8, 20), (-10.5+rng.uniform(-.8, .4), rng.uniform(14, 18)),
                       (-14.5+rng.uniform(-1, .6), rng.uniform(4, 9)), (-18, 0)]
        for column, (x, z) in enumerate(profile):
            vertices.append((x, y+(rng.uniform(-2, 2) if column>0 else 0), z))
    faces = []
    for row in range(len(rows)-1):
        for column in range(3):
            a = row*4+column
            b = a+4
            if (row+column)%2:
                faces += [(a, b, b+1), (a, b+1, a+1)]
            else:
                faces += [(a, b, a+1), (a+1, b, b+1)]
    bottom = len(vertices)
    vertices += [(side*7.8, y, 0) for y in rows]
    for row in range(len(rows)-1):
        a, b = row*4, (row+1)*4
        faces += [(a, bottom+row, bottom+row+1, b),
                  (a+3, b+3, bottom+row+1, bottom+row)]
    faces += [(0, 1, 2, 3, bottom),
              (20, bottom+5, 23, 22, 21)]
    return mesh_object(col, name, vertices, faces, material)


flank("UpwardRidge", 1, "ShelfRidge", 1061)
flank("BrokenDownhill", -1, "ShelfTalus", 1063)
shelf = finish(col, "SculptedShelf", 28)

vent = collection("VentCrater")
rng = random.Random(1071)
n = 14
vertices = []
for radius, height in [(3.5, .05), (2.9, .8), (2.15, .18)]:
    for i in range(n):
        angle = i*math.tau/n
        r = radius*rng.uniform(.94, 1.06)
        vertices.append((math.cos(angle)*r, math.sin(angle)*r,
                         height+(rng.uniform(-.12, .06) if height>.2 else 0)))
faces = []
for ring in range(2):
    for i in range(n):
        a, b = ring*n+i, ring*n+(i+1)%n
        faces.append((a, b, b+n, a+n))
mesh_object(vent, "Rim", vertices, faces, "CraterRim")
floor = [(math.cos(i*math.tau/n)*2.28, math.sin(i*math.tau/n)*2.28, 0) for i in range(n)]
mesh_object(vent, "DarkFloor", floor, [tuple(range(n))], "CraterFloor")
crater = finish(vent, "VentCrater", .8)

objects = [o for c in scene.collection.children for o in c.objects if o.type=="MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    if obj.name.startswith("SculptedShelf"):
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(obj.data)
        bm.free()
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath=str(OUT/"SculptedTerrain.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                        apply_unit_scale=True, bake_space_transform=False, add_leaf_bones=False)
manifest = {"props":[shelf, crater], "parts":{o.name:list(o.data.materials[0].diffuse_color[:3]) for o in objects}}
(OUT/"manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
gallery = bpy.data.scenes.new("SculptedTerrainGallery")
gallery.world = bpy.data.worlds.new("SculptedTerrainWorld")
gallery.world.color = (.12, .14, .16)
for obj in objects:
    duplicate = obj.copy()
    duplicate.data = obj.data
    if obj.name.startswith("VentCrater"):
        duplicate.matrix_world = Matrix.Translation((-28, -25, 0)) @ Matrix.Scale(2.5, 4) @ obj.matrix_world
    gallery.collection.objects.link(duplicate)
camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
gallery.collection.objects.link(camera)
camera.location = (-90, -110, 100)
camera.rotation_euler = (Vector((0, 0, 10))-camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 135
gallery.camera = camera
gallery.render.engine = "BLENDER_WORKBENCH"
gallery.display.shading.light = "STUDIO"
gallery.display.shading.color_type = "MATERIAL"
gallery.display.shading.show_shadows = True
gallery.display.shading.show_cavity = True
gallery.render.resolution_x, gallery.render.resolution_y, gallery.render.resolution_percentage = 1600, 1100, 100
gallery.render.filepath = str(OUT/"preview.png")
bpy.context.window.scene = gallery
bpy.ops.render.render(write_still=True)
bpy.context.window.scene = scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"SculptedTerrain.blend"))
print(json.dumps(manifest))
