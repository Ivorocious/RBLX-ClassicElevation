"""Inspect the authored kit without touching the live Blender scene."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[4]
scene = bpy.context.scene
for obj in scene.objects:
    obj.hide_render = True
collection = bpy.data.collections.new("TL01_RenderSpecimens")
scene.collection.children.link(collection)
camera_data = bpy.data.cameras.new("TL01_RenderCamera")
camera = bpy.data.objects.new(camera_data.name, camera_data)
collection.objects.link(camera)
scene.camera = camera
camera_data.type = "ORTHO"
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.background_type = "WORLD"
scene.world.color = (.17, .21, .28)
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1300, 900, 100
scene.render.image_settings.file_format = "PNG"
views = [("tower-kit", [("MC_TL_GrandPinnacle", (0, 0, 0)), ("MC_TL_FlankPinnacle", (34, 0, 0)), ("MC_TL_SteppedButtress", (-32, 0, 0))], (145, -190, 175), (0, 0, 77), 255),
         ("rural-kit", [("MC_P3_Rural_Mound", (0, 0, 0)), ("MC_P3_Rural_BroadleafClump", (-6, -3, 5)), ("MC_P3_Rural_EvergreenGrove", (43, 6, 0)), ("MC_P3_Rural_HeatherFern", (2, -14, 1))], (99, -130, 88), (14, 0, 10), 100)]
for filename, units, point, target, scale in views:
    copies = []
    for name, location in units:
        original = bpy.data.objects[name]
        obj = original.copy()
        collection.objects.link(obj)
        obj.location, obj.hide_render = location, False
        copies.append(obj)
    camera.location = point
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.ortho_scale = scale
    scene.render.filepath = str(ROOT / "docs/artifacts/moonlit-citadel/phase3/tower-landscape-20261013" / (filename + ".png"))
    bpy.ops.render.render(write_still=True)
    for obj in copies:
        obj.hide_render = True
