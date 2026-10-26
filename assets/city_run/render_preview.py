"""Player-height Blender previews for upload review; final reviews must use Studio."""
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector

OUT=Path(__file__).resolve().parent
revision = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'C03'
bpy.ops.wm.open_mainfile(filepath=str(OUT/f"CityRun_{revision}.blend"))
scene=bpy.data.scenes[f"CityRun_{revision}"];bpy.context.window.scene=scene
scene.render.engine="CYCLES";scene.cycles.samples=16
scene.cycles.use_denoising=True
scene.render.resolution_x=1440;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.use_nodes=True
scene.world.node_tree.nodes["Background"].inputs["Color"].default_value=(.58,.74,.9,1)
scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value=.8
sun_data=bpy.data.lights.new("PreviewSun","SUN");sun_data.energy=2.2;sun_data.angle=.08
sun=bpy.data.objects.new("PreviewSun",sun_data);scene.collection.objects.link(sun);sun.rotation_euler=(.5,-.5,-.7)
for material in bpy.data.materials:
    color=material.diffuse_color
    material.use_nodes=True
    bsdf=material.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value=color
        bsdf.inputs["Roughness"].default_value=.78
scene.view_settings.view_transform="AgX"
cam=scene.camera;cam.data.type="PERSP";cam.data.lens=24;cam.data.clip_end=5000
views=[
    ("market",(-170,20,245),(-170,20,160)),
    ("roof",(-91,88,-246),(-15,90,-249)),
    ("station",(195,137,184),(195,155,274)),
]
if sys.argv[-1]=='approaches':
    views=[('courtyard',(-116,35,80),(-150,37,52)),
           ('station_split',(205,92,40),(205,96,85)),
           ('rail',(205,88,-48),(205,90,12))]
elif sys.argv[-1]=='gate':
    scene.render.engine='BLENDER_WORKBENCH'
    views=[('court_gate',(-150,35,80),(-130,45,20)),
           ('station_gate',(205,92,57),(200,105,120)),
           ('market_gate',(-170,18,205),(-170,18,150)),
           ('finish_gate',(195,138,184),(195,154,274))]
for name,p,target in views:
    cam.location=(p[0],-p[2],p[1]);q=Vector((target[0],-target[2],target[1]))
    cam.rotation_euler=(q-cam.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str(OUT/(revision+"_player_"+name+".png"));bpy.ops.render.render(write_still=True)
