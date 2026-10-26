"""Render the prepared upload locally without changing the live Blender scene."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / "docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013"
scene = bpy.context.scene
for obj in scene.objects:
    obj.hide_render = True
collection = bpy.data.collections.new("ER01_ApprovalPreview")
scene.collection.children.link(collection)
data = bpy.data.cameras.new("ER01_ApprovalCamera")
camera = bpy.data.objects.new(data.name, data)
collection.objects.link(camera)
scene.camera = camera
data.type = "ORTHO"
data.clip_start, data.clip_end = .1, 10000
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.background_type = "WORLD"
scene.world.color = (.13, .17, .23)
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1500, 1000, 100
scene.render.image_settings.file_format = "PNG"
views = [
    ("prepared-fortress-kit.png", [
        ("MC_ER_Bastion", (-205, 0, 0)), ("MC_ER_SteppedWing", (-75, 0, 0)),
        ("MC_ER_ForwardGate", (110, 0, 0)), ("MC_ER_Rampart", (-200, 100, 0)),
        ("MC_ER_RaisedCourt", (-65, 110, 0)), ("MC_ER_LiftHood", (245, 90, 0)),
        ("MC_ER_MainKeepShell", (55, 115, 0))], (720, -980, 750), (15, 35, 95), 700),
    ("prepared-connected-landscape.png", [(name, (0, 0, 0)) for name in [
        "MC_EC_InnerRavine", "MC_EC_WestWoodedCliff", "MC_EC_EastPanoramaSlope",
        "MC_EC_NorthHighRidge", "MC_EC_SouthValleyRidge"]], (900, -1170, 850), (0, 0, 45), 1000),
]
for name, units, position, target, scale in views:
    copies = []
    for key, location in units:
        obj = bpy.data.objects[key].copy()
        collection.objects.link(obj)
        obj.location, obj.hide_render = location, False
        copies.append(obj)
    camera.location = position
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()
    data.ortho_scale = scale
    scene.render.filepath = str(OUT / name)
    bpy.ops.render.render(write_still=True)
    for obj in copies:
        obj.hide_render = True
