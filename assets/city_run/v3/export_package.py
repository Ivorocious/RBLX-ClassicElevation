"""Render asset evidence and export one shared-material import package."""
from pathlib import Path
import bpy,json,math
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;OUT=ROOT.parents[2]/'docs/artifacts/city-run/v3'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_AssetKit.blend'))
sc=bpy.context.scene;cam=sc.camera
objects=[o for o in sc.objects if o.type=='MESH' and o.get('V3AssetId')]
bpy.ops.object.select_all(action='DESELECT')
for ob in objects:ob.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(ROOT/'CityRun_V3_AssetKit.fbx'),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=False,axis_forward='-Z',axis_up='Y',use_triangles=True,path_mode='COPY',embed_textures=True,add_leaf_bones=False,bake_anim=False)
