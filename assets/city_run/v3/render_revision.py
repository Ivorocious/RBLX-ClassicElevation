from pathlib import Path
import bpy,math,json,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
OUT=ROOT.parents[2]/'docs/artifacts/city-run/v3/round06'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_AssetKit.blend'))
sc=bpy.context.scene
obs={o.name:o for o in sc.objects if o.type=='MESH' and o.get('V3AssetId')}
for o in obs.values():o.hide_render=True
try:
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 sc.cycles.device='GPU'
except Exception:pass
sc.cycles.samples=24
sc.render.resolution_x=1500;sc.render.resolution_y=1050
mat=bpy.data.materials.new('ReviewFloor');mat.diffuse_color=(.22,.27,.25,1)
bpy.ops.mesh.primitive_plane_add(size=250,location=(0,20,-.08));floor=bpy.context.object;floor.data.materials.append(mat)
cam=sc.camera;cam.data.type='PERSP';cam.data.lens=35
clones=[]
def add(name,x,y,z,rot=0):
 o=obs[name].copy();o.data=obs[name].data;sc.collection.objects.link(o);o.hide_render=False;o.location=(x,-z,y);o.rotation_euler.z=math.radians(rot);clones.append(o);return o
def render(name,pos,target):
 cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
a=add('V3_AtelierHall',0,0,0)
render('atelier_front',(65,-95,45),(0,0,27))
render('atelier_reverse',(-63,90,41),(0,0,27))
a.hide_render=True
rows=[('V3_CornerCafe',-25,0,0,0),('V3_GableRoof_Wide',-25,36,0,0),
('V3_AtelierHall',-26,0,-34,90),('V3_UnevenShopRow',23,0,-4,-90),
('V3_Blue_Narrow',36,0,-9,-90),('V3_GableRoof_Narrow',36,60,-9,-90),
('V3_LoggiaResidence',26,0,-42,-90),('V3_MansardRoof',26,48,-42,-90),
('V3_CornerCafe',-24,0,-73,90),('V3_GableRoof_Wide',-24,36,-73,90),
('V3_SkylineCluster',0,0,-101,0),('V3_MarketStall',-15,0,14,0),
('V3_Crate',-20,0,18,0),('V3_Planter',12,0,13,0),('V3_Lamp',13,0,-20,0),
('V3_MarketCar',2,0,-29,180)]
for row in rows:add(*row)
render('market_atelier',(0,-35,5.5),(0,35,19))
render('market_atelier_reverse',(0,77,5.5),(0,-8,18))
print('REVISION_PREVIEWS_COMPLETE')
