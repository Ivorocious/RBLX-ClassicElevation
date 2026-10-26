"""Consistent isolated art previews; these do not establish Studio appearance."""
import bpy, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=16
scene.render.resolution_x=1200;scene.render.resolution_y=1400;scene.render.resolution_percentage=100
if not scene.world: scene.world=bpy.data.worlds.new('PreviewWorld')
scene.world.color=(.35,.42,.5)
scene.view_settings.view_transform='AgX'
sun_data=bpy.data.lights.new('PreviewSun','SUN');sun_data.energy=3;sun_data.angle=math.radians(12)
sun=bpy.data.objects.new('PreviewSun',sun_data);scene.collection.objects.link(sun);sun.rotation_euler=(.6,-.5,-.7)
camera_data=bpy.data.cameras.new('PreviewCamera');camera=bpy.data.objects.new('PreviewCamera',camera_data);scene.collection.objects.link(camera)
scene.camera=camera;camera.location=(-510,-690,310)
target=Vector((0,0,210));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type='ORTHO';camera_data.ortho_scale=540
for name,objs in [('tree',[o for o in bpy.data.objects if o.name.startswith(('HA_Trunk','HA_Bough','HA_Canopy','HA_Crown','HA_Root'))]),
                  ('flowers',[o for o in bpy.data.objects if o.name.startswith('HA_Bloom') or o.name=='HA_Sanctuary'])]:
    for obj in bpy.data.objects:
        if obj.type=='MESH': obj.hide_render=obj not in objs
    if name=='tree':
        sanctuary=bpy.data.objects['HA_Sanctuary'];sanctuary.hide_render=False;sanctuary.location=(-106,-28,162)
    if name=='flowers':
        scene.render.resolution_x=1400;scene.render.resolution_y=900
        for i,obj in enumerate(objs):obj.location.x=(i-1)*47
        camera.location=(0,-100,72);camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.ortho_scale=150
    scene.render.filepath=str(ROOT/('preview-'+name+'.png'));bpy.ops.render.render(write_still=True)
