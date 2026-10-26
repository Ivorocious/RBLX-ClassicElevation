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
try:
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 sc.cycles.device='GPU'
except Exception as e:print('Cycles CPU fallback',e)
sc.cycles.samples=24
sc.render.resolution_x=1600;sc.render.resolution_y=1100
baseMat=bpy.data.materials.new('Gallery_Sand');baseMat.diffuse_color=(.34,.39,.38,1);baseMat.use_nodes=True;baseMat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.32,.34,.30,1)
bpy.ops.mesh.primitive_plane_add(size=2000,location=(0,0,-.25));floor=bpy.context.object;floor.name='GalleryFloor';floor.data.materials.append(baseMat)
textMat=bpy.data.materials.new('Gallery_Label');textMat.diffuse_color=(.1,.14,.15,1)
labels=[]
def label(body,loc,size=1.8):
 cu=bpy.data.curves.new('Caption','FONT');cu.body=body;cu.align_x='CENTER';cu.size=size;cu.extrude=0
 ob=bpy.data.objects.new('Caption',cu);sc.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(math.pi/2,0,0);ob.data.materials.append(textMat);labels.append(ob)
def view(pos,target,scale):cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale
specs=[('Architecture',['Architecture'],4,46,45,190),('Roofs',['Roofs'],4,45,33,176),('Street',['Street'],4,26,25,110),('Openings',['Openings','Landmarks'],4,36,40,157),('Industrial',['Industrial'],3,38,35,138),('Vehicles',['Vehicles'],4,38,36,145),('Skyline',['Skyline'],4,46,45,195)]
for title,families,cols,dx,dy,scale in specs:
 for ob in objects:ob.hide_render=True
 for ob in labels:ob.hide_render=True
 chosen=[ob for ob in objects if ob.get('Family') in families]
 for i,ob in enumerate(chosen):
  ob.hide_render=False;ob.location=((i%cols)*dx,(i//cols)*dy,0)
  label(ob.name.replace('V3_','').replace('_',' '),(ob.location.x,ob.location.y-ob.dimensions.y/2-3,.2),1.65)
 cx=(min(cols,len(chosen))-1)*dx/2;cy=((len(chosen)-1)//cols)*dy/2
 h=max(ob.dimensions.z for ob in chosen)
 pts=[ob.matrix_world @ Vector(c) for ob in chosen for c in ob.bound_box]
 bpy.context.view_layer.update()
 pts=[ob.matrix_world @ Vector(c) for ob in chosen for c in ob.bound_box]
 center=sum(pts,Vector())/len(pts)
 view(center+Vector((90,-160,125)),center,scale)
 inv=cam.rotation_euler.to_matrix().transposed();q=[inv@(p-center) for p in pts]
 width=max(p.x for p in q)-min(p.x for p in q);height=max(p.y for p in q)-min(p.y for p in q)
 cam.data.ortho_scale=max(width,height*1600/1100)*1.16
 sc.render.filepath=str(OUT/('kit_'+title.lower()+'.png'));bpy.ops.render.render(write_still=True)
# Close perspective verifies painted facades, opaque backs and roof grounding.
for ob in objects:ob.hide_render=True
for ob in labels:ob.hide_render=True
house=bpy.data.objects['V3_Coral_Wide'];house.hide_render=False;house.location=(0,0,0)
roof=bpy.data.objects['V3_GableRoof_Wide'];roof.hide_render=False;roof.location=(0,0,48)
aw=bpy.data.objects['V3_Awning_12'];aw.hide_render=False;aw.location=(0,-14,12)
# Back bracket at y=-10.3 abuts the shell front y=-10.
planter=bpy.data.objects['V3_Planter'];planter.hide_render=False;planter.location=(7,-12,0)
cam.data.type='PERSP';cam.data.lens=35
cam.location=(50,-85,35);cam.rotation_euler=(Vector((0,-3,25))-cam.location).to_track_quat('-Z','Y').to_euler()
sc.render.filepath=str(OUT/'kit_close_front.png');bpy.ops.render.render(write_still=True)
cam.location=(-50,85,17);cam.rotation_euler=(Vector((0,0,27))-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(OUT/'kit_close_rear.png');bpy.ops.render.render(write_still=True)

# Mounting/density studies are asset-fit fixtures, not new course geometry.
for ob in objects:ob.hide_render=True
for ob in labels:ob.hide_render=True
fixtures=[]
def instance(name,p,rot=0):
 src=bpy.data.objects[name];ob=src.copy();ob.data=src.data;sc.collection.objects.link(ob);ob.location=p;ob.rotation_euler=(0,0,rot);ob.hide_render=False;fixtures.append(ob);return ob
for theme in ('market','courtyard','construction','terminal','service_corner'):
 for ob in fixtures:ob.hide_render=True
 if theme in ('market','courtyard'):
  for side in (-1,1):
   for i in range(3):
    name=['V3_CornerCafe','V3_Ochre_Narrow','V3_Sage_Wide'][(i+(side==1))%3] if theme=='market' else ['V3_LoggiaResidence','V3_CourtyardGallery','V3_Blue_Narrow'][i]
    ob=instance(name,(side*25,i*29+8,0),-side*math.pi/2)
    # Match interchangeable roof footprints to their host shell.
    roof=instance('V3_GableRoof_Wide' if i%2==0 else 'V3_MansardRoof',(side*25,i*29+8,ob.dimensions.z),-side*math.pi/2)
    roof.scale=(ob.dimensions.x/25,ob.dimensions.y/21,1)
  if theme=='market':
   for side in (-1,1):
    for i in (0,1):instance('V3_Awning_12',(side*11.3,i*29+8,10),-side*math.pi/2)
   instance('V3_UnevenShopRow',(-18,49,0),math.pi/2);instance('V3_Crate',(-8,4,0));instance('V3_Crate',(-11,6,0));instance('V3_MarketStall',(-9,0,0));instance('V3_Sign_Market',(-11,-3,9),math.pi/2);instance('V3_MarketCar',(2,24,0));instance('V3_Planter',(10,4,0))
  else:
   instance('V3_ServiceRear',(15,58,0),math.pi/2)
   instance('V3_GardenPortal',(0,36,0));instance('V3_MuralPanel',(-14.9,19,10),-math.pi/2);instance('V3_CourtyardFountain',(0,26,0));instance('V3_Bench',(9,7,0),-math.pi/2);instance('V3_Planter',(-9,6,0));instance('V3_Tree',(-10,29,0))
  cameraPos=(0,-36,5.5);target=(0,24,21)
 elif theme=='construction':
  for side in (-1,1):instance('V3_Brick_Broad',(side*32,28,0));instance('V3_FlatRoof_Broad',(side*32,28,48));instance('V3_ServiceRear',(side*32,14.9,0))
  for x in (-12,):
   for z in (0,12):instance('V3_ScaffoldBay',(x,17,z))
  instance('V3_CraneTruss',(0,17,24));instance('V3_WaterTank',(10,2,0));instance('V3_WreckingBallSkin',(-5,17,9));instance('V3_IBeam',(-5,17,22),math.pi/2);instance('V3_Crate',(-9,1,0));instance('V3_Fence',(0,25,0))
  cameraPos=(25,-43,7);target=(0,16,15)
 elif theme=='service_corner':
  instance('V3_CornerCafe',(-16,22,0));instance('V3_GableRoof_Wide',(-16,22,36));instance('V3_ServiceRear',(19,30,0));instance('V3_UnevenShopRow',(13,15,0));instance('V3_MarketStall',(-23,6,0));instance('V3_Crate',(-18,7,0));instance('V3_Planter',(0,9,0));instance('V3_Lamp',(-2,12,0))
  cameraPos=(39,-48,11);target=(0,20,18)
 else:
  for side in (-1,1):instance('V3_Terminal_Wing',(side*19,18,0));instance('V3_GableRoof_Wide',(side*19,18,24))
  instance('V3_ClockTower',(0,24,0));roof=instance('V3_GableRoof_Narrow',(0,24,40));roof.scale=(.8,.8,1)
  instance('V3_TerminalColonnade',(0,5,0));instance('V3_BarrelRoof',(0,12,14));instance('V3_Sign_Terminal',(0,3.3,9.8))
  for side in (-1,1):instance('V3_Planter',(side*18,-1,0));instance('V3_Lamp',(side*12,-2,0))
  cameraPos=(17,-54,5.5);target=(0,16,20)
 # Human-sized marker makes scale explicit without assuming a player skin.
 markMat=bpy.data.materials.get('ScaleMarker') or bpy.data.materials.new('ScaleMarker');markMat.diffuse_color=(.8,.65,.35,1);markMat.use_nodes=True;markMat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.8,.65,.35,1)
 for side in (-1,1):instance('V3_SkylineCluster',(side*36,110,0),side*.2)
 for p,size in [((-4,-3,2.5),(1.5,.7,2.5)),((-4,-3,4.6),(1.2,1.1,1.2)),((-4.45,-3,.7),(.45,.6,1.4)),((-3.55,-3,.7),(.45,.6,1.4))]:
  bpy.ops.mesh.primitive_cube_add(size=1,location=p);ob=bpy.context.object;ob.scale=size;ob.data.materials.append(markMat);fixtures.append(ob)
 cam.location=cameraPos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.lens=29
 sc.render.filepath=str(OUT/('fit_'+theme+'.png'));bpy.ops.render.render(write_still=True)
print('V3_GALLERY_COMPLETE')

