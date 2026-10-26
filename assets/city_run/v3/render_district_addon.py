"""Render local placement previews; these are not native Studio evidence."""
from pathlib import Path
import bpy, math
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
OUT=ROOT.parents[2]/'docs/artifacts/city-run/v3/addon01'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_AssetKit.blend'))
with bpy.data.libraries.load(str(ROOT/'district_addon01/CityRun_DistrictAddon.blend'),link=False) as (src,dst):
 dst.objects=[n for n in src.objects if n.startswith('V3_')]
for ob in dst.objects:bpy.context.scene.collection.objects.link(ob)
sc=bpy.context.scene
obs={o.name:o for o in sc.objects if o.type=='MESH' and o.get('V3AssetId')}
for o in obs.values():o.hide_render=True
try:
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 sc.cycles.device='GPU'
except Exception:pass
sc.cycles.samples=24
sc.render.resolution_x=1400;sc.render.resolution_y=1000
mat=bpy.data.materials.new('ReviewFloor');mat.diffuse_color=(.22,.27,.25,1)
bpy.ops.mesh.primitive_plane_add(size=250,location=(0,20,-.08));bpy.context.object.data.materials.append(mat)
cam=sc.camera;cam.data.type='PERSP';cam.data.lens=35
clones=[]
def add(name,x,y,z,rot=0):
 o=obs[name].copy();sc.collection.objects.link(o);o.hide_render=False;o.location=(x,-z,y);o.rotation_euler.z=math.radians(rot);clones.append(o);return o
def render(name,pos,target):
 cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)

for row in [('V3_AtelierHall',-25,0,-29,90),('V3_Brick_Broad',27,0,-29,-90),('V3_FlatRoof_Broad',27,48,-29,-90),('V3_SkylineCluster',0,0,-82),('V3_ServiceRear',13.7,0,-34,-90),('V3_LoadingFacade',12.4,0,-20,-90),('V3_WorksiteHoarding',-11,0,0,90),('V3_MaterialsStock',-10,0,11,90),('V3_MaterialsStock',9,0,-5),('V3_WaterTank',9,0,-48),('V3_CraneTruss',0,24,-25),('V3_WreckingBallSkin',-4,11,-25)]:add(*row)
bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.07,depth=4.975,location=(-4,25,25.5125))
cable=bpy.context.object;cable.name='ReviewOnlyCable';cable.data.materials.append(obs['V3_CraneTruss'].data.materials[0]);clones.append(cable)
for z in (-22,-33):
 for y in (0,12):add('V3_ScaffoldBay',-12,y,z)
render('construction',(0,-36,5.5),(0,30,17))
render('construction_reverse',(2,63,7),(0,-4,15))
for o in clones:o.hide_render=True
clones=[]
for row in [('V3_AtelierHall',-25,0,-29,90),('V3_Brick_Broad',27,0,-25,-90),('V3_FlatRoof_Broad',27,48,-25,-90),('V3_SkylineCluster',0,0,-82),('V3_ServiceRear',13.7,0,-30,-90),('V3_LoadingFacade',12.4,0,-18,-90),('V3_ServiceStock',9,0,6,90),('V3_MaterialsStock',-10,0,4,90),('V3_ServiceCanopy',0,0,-49),('V3_DeliveryVan',1,0,-54),('V3_ShopBase',17,0,-61),('V3_Lamp',-12,0,13)]:add(*row)
render('service',(0,-36,5.5),(0,32,16))
render('service_reverse',(0,72,5.5),(0,-3,15))
for o in clones:o.hide_render=True
for i,name in enumerate(['V3_LoadingFacade','V3_ServiceStock','V3_WorksiteHoarding','V3_MaterialsStock','V3_ServiceCanopy']):add(name,((i%3)-1)*30,0,-(i//3)*26)
cam.data.type='ORTHO';cam.data.ortho_scale=100
render('modules',(60,-90,75),(0,12,4))

