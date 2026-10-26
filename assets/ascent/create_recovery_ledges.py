"""Flat playable tops with three distinct mountain support profiles."""
import bpy
import json
import math
import random
from pathlib import Path
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent
exec((BASE / "create_ascent_props.py").read_text().split("RESULT=build()")[0])
OUT = BASE / "recovery_ledges"
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new("RecoveryLedges")
bpy.context.window.scene = scene
COLORS["ColdRock"] = (.29,.35,.35)


def ledge(name, seed, spread, middle):
    col = collection(name)
    rng = random.Random(seed)
    n = 12
    outline = [(math.cos(i*math.tau/n)*rng.uniform(.86,1.13),
                math.sin(i*math.tau/n)*rng.uniform(.84,1.1)) for i in range(n)]
    xmin, xmax = min(p[0] for p in outline), max(p[0] for p in outline)
    ymin, ymax = min(p[1] for p in outline), max(p[1] for p in outline)
    outline = [((x-xmin)/(xmax-xmin)*2-1,(y-ymin)/(ymax-ymin)*2-1) for x,y in outline]
    vertices = []
    for ring, (height, scale) in enumerate(((0,spread),(.38,middle),(.73,1.08),(1,1))):
        for i, (x,y) in enumerate(outline):
            z = height*20 + (0 if ring in (0,3) else rng.uniform(-1.7,1.7))
            scale_at_point = scale if ring in (0,3) else scale*rng.uniform(.90,1.04)
            vertices.append((x*10*scale_at_point,y*8*scale_at_point,z))
    faces = [tuple(range(n-1,-1,-1)),tuple(range(3*n,4*n))]
    for ring in range(3):
        for i in range(n):
            a,b = ring*n+i,ring*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj = bpy.data.objects.new(name,mesh)
    col.objects.link(obj)
    mesh.materials.append(mat("ColdRock"))
    return finish(col,name,20)


props = [ledge("EmbeddedShelf",971,1.65,1.38),ledge("BrokenLedge",977,1.35,1.17),ledge("WeatheredSlab",983,1.12,1.04)]
objects = [o for c in scene.collection.children for o in c.objects if o.type=="MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in objects: obj.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/"RecoveryLedges.fbx"),use_selection=True,object_types={"MESH"},
    axis_forward="-Z",axis_up="Y",apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
manifest = {"props":props,"topFootprintScale":{"EmbeddedShelf":1/1.65,"BrokenLedge":1/1.35,"WeatheredSlab":1/1.12}}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
gallery = bpy.data.scenes.new("LedgeGallery")
gallery.world = bpy.data.worlds.new("LedgeWorld")
gallery.world.color = (.12,.14,.16)
for index,obj in enumerate(objects):
    duplicate = obj.copy()
    duplicate.data = obj.data
    duplicate.matrix_world = Matrix.Translation(((index-1)*55,0,0)) @ obj.matrix_world
    gallery.collection.objects.link(duplicate)
camera = bpy.data.objects.new("Camera",bpy.data.cameras.new("Camera"))
gallery.collection.objects.link(camera)
camera.location = (80,130,95)
camera.rotation_euler = (Vector((0,0,9))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 180
gallery.camera = camera
gallery.render.engine = "BLENDER_WORKBENCH"
gallery.display.shading.light = "STUDIO"
gallery.display.shading.color_type = "MATERIAL"
gallery.display.shading.show_shadows = True
gallery.display.shading.show_cavity = True
gallery.render.resolution_x,gallery.render.resolution_y,gallery.render.resolution_percentage = 1500,950,100
gallery.render.filepath = str(OUT/"preview.png")
bpy.context.window.scene = gallery
bpy.ops.render.render(write_still=True)
bpy.context.window.scene = scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"RecoveryLedges.blend"))
print(json.dumps(manifest))
