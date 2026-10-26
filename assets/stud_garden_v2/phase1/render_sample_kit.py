"""Render an inspection contact sheet from the saved candidate without resaving it."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
manifest=json.loads((ROOT/"SGV2_M01.json").read_text())
for index, asset in enumerate(manifest["assets"]):
    for name in asset["parts"]:
        obj=bpy.data.objects[name]
        if asset["name"]=="Calibration10":
            obj.hide_render=True
            continue
        obj.location=Vector(((index%3-1)*30,(-1 if index<3 else 1)*17,0))-Vector(asset["origin"])

bpy.ops.mesh.primitive_plane_add(size=220,location=(0,0,-0.12))
floor=bpy.context.object
mat=bpy.data.materials.new("PreviewBackdrop"); mat.diffuse_color=(0.70,0.68,0.60,1); floor.data.materials.append(mat)
bpy.ops.object.camera_add(location=(49,-80,67))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,4))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type="ORTHO"; camera.data.ortho_scale=113
bpy.context.scene.camera=camera
bpy.ops.object.light_add(type="AREA",location=(-25,-25,70))
bpy.context.object.data.energy=33000; bpy.context.object.data.shape="DISK"; bpy.context.object.data.size=65
bpy.context.scene.world.color=(0.65,0.65,0.65)
scene=bpy.context.scene
scene.render.engine="CYCLES"; scene.cycles.samples=24
scene.render.resolution_x=1500; scene.render.resolution_y=1050; scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.filepath=str(ROOT/"SGV2_M01-inspection.png")
scene.view_settings.view_transform="Standard"
bpy.ops.render.render(write_still=True)
