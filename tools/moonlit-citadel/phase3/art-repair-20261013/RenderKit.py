"""Side and roof inspection of the joined gallery specimen."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[4]
for obj in bpy.context.scene.objects:
    obj.hide_render = True
collection = bpy.data.collections.new("AR01_GallerySpecimen")
bpy.context.scene.collection.children.link(collection)
for key, height in [("FoundationBay46", 0), ("GalleryBody46", 40), ("GalleryRoof46", 66)]:
    original = bpy.data.objects["MC_AR_" + key]
    obj = original.copy()
    collection.objects.link(obj)
    obj.location.z, obj.hide_render = height, False
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.cavity_type = "BOTH"
scene.display.shading.background_type = "WORLD"
scene.world.color = (.12, .17, .24)
camera_data = bpy.data.cameras.new("AR01PreviewCamera")
camera = bpy.data.objects.new("AR01PreviewCamera", camera_data)
collection.objects.link(camera)
camera.location = (92, -99, 90)
target = Vector((0, 9, 35))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type, camera_data.ortho_scale = "ORTHO", 102
scene.camera = camera
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1100, 900, 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(ROOT / "docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/ar01-gallery-specimen.png")
bpy.ops.render.render(write_still=True)
