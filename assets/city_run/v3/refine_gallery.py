from pathlib import Path
p=Path('assets/city_run/v3/render_gallery.py');s=p.read_text(encoding='utf-8-sig')
s=s.replace("sc.cycles.samples=20","sc.cycles.samples=24")
s=s.replace("h=max(ob.dimensions.z for ob in chosen)\n view((cx+60,cy-150,115+h*.4),(cx,cy,h*.30),scale)","h=max(ob.dimensions.z for ob in chosen)\n pts=[ob.matrix_world @ Vector(c) for ob in chosen for c in ob.bound_box]\n bpy.context.view_layer.update()\n pts=[ob.matrix_world @ Vector(c) for ob in chosen for c in ob.bound_box]\n center=sum(pts,Vector())/len(pts)\n view(center+Vector((90,-160,125)),center,scale)\n inv=cam.rotation_euler.to_matrix().transposed();q=[inv@(p-center) for p in pts]\n width=max(p.x for p in q)-min(p.x for p in q);height=max(p.y for p in q)-min(p.y for p in q)\n cam.data.ortho_scale=max(width,height*1600/1100)*1.16")
s=s.replace("cam.data.lens=45","cam.data.lens=35").replace("cam.location=(37,-59,29)","cam.location=(50,-85,35)").replace("cam.location=(-34,45,16)","cam.location=(-50,85,17)")
s=s.replace("print('V3_GALLERY_COMPLETE')", """
# Mounting/density studies are asset-fit fixtures, not new course geometry.
for ob in objects:ob.hide_render=True
for ob in labels:ob.hide_render=True
fixtures=[]
def instance(name,p,rot=0):
 src=bpy.data.objects[name];ob=src.copy();ob.data=src.data;sc.collection.objects.link(ob);ob.location=p;ob.rotation_euler=(0,0,rot);ob.hide_render=False;fixtures.append(ob);return ob
for theme in ('market','courtyard','construction','terminal'):
 for ob in fixtures:ob.hide_render=True
 if theme in ('market','courtyard'):
  for side in (-1,1):
   for i in range(3):
    name=['V3_Coral_Wide','V3_Ochre_Narrow','V3_Sage_Wide'][(i+(side==1))%3] if theme=='market' else ['V3_LoggiaResidence','V3_CourtyardGallery','V3_Blue_Narrow'][i]
    ob=instance(name,(side*25,i*29+8,0),-side*math.pi/2)
    # Match interchangeable roof footprints to their host shell.
    roof=instance('V3_GableRoof_Wide' if i%2==0 else 'V3_MansardRoof',(side*25,i*29+8,ob.dimensions.z),-side*math.pi/2)
    roof.scale=(ob.dimensions.x/25,ob.dimensions.y/21,1)
  if theme=='market':
   for side in (-1,1):
    for i in (0,1):instance('V3_Awning_12',(side*11.3,i*29+8,10),-side*math.pi/2)
   instance('V3_MarketStall',(-9,0,0));instance('V3_Sign_Market',(-11,-3,9),math.pi/2);instance('V3_MarketCar',(2,24,0));instance('V3_Planter',(10,4,0))
  else:
   instance('V3_GardenPortal',(0,36,0));instance('V3_MuralPanel',(-14.9,19,10),-math.pi/2);instance('V3_CourtyardFountain',(0,26,0));instance('V3_Bench',(9,7,0),-math.pi/2);instance('V3_Planter',(-9,6,0));instance('V3_Tree',(-10,29,0))
  cameraPos=(0,-36,5.5);target=(0,24,21)
 elif theme=='construction':
  for side in (-1,1):instance('V3_Brick_Broad',(side*28,28,0));instance('V3_FlatRoof_Broad',(side*28,28,48))
  for x in (-12,12):
   for z in (0,12):instance('V3_ScaffoldBay',(x,17,z))
  instance('V3_CraneTruss',(0,17,24));instance('V3_WaterTank',(10,2,0));instance('V3_WreckingBallSkin',(-5,17,9));instance('V3_IBeam',(-5,17,22),math.pi/2);instance('V3_Crate',(-9,1,0));instance('V3_Fence',(0,25,0))
  cameraPos=(25,-43,7);target=(0,16,15)
 else:
  for side in (-1,1):instance('V3_Terminal_Wing',(side*19,18,0));instance('V3_GableRoof_Wide',(side*19,18,24))
  instance('V3_ClockTower',(0,24,0));roof=instance('V3_GableRoof_Narrow',(0,24,40));roof.scale=(.8,.8,1)
  instance('V3_TerminalColonnade',(0,5,0));instance('V3_BarrelRoof',(0,12,14));instance('V3_Sign_Terminal',(0,3.3,12))
  for side in (-1,1):instance('V3_Planter',(side*18,-1,0));instance('V3_Lamp',(side*12,-2,0))
  cameraPos=(17,-54,5.5);target=(0,16,20)
 # Five-and-a-half stud height marker makes scale explicit without assuming a player skin.
 markMat=bpy.data.materials.get('ScaleMarker') or bpy.data.materials.new('ScaleMarker');markMat.diffuse_color=(.8,.65,.35,1)
 for p,size in [((-4,-3,2.5),(1.5,.7,2.5)),((-4,-3,4.6),(1.2,1.1,1.2)),((-4.45,-3,.7),(.45,.6,1.4)),((-3.55,-3,.7),(.45,.6,1.4))]:
  bpy.ops.mesh.primitive_cube_add(size=1,location=p);ob=bpy.context.object;ob.scale=size;ob.data.materials.append(markMat);fixtures.append(ob)
 cam.location=cameraPos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.lens=29
 sc.render.filepath=str(OUT/('fit_'+theme+'.png'));bpy.ops.render.render(write_still=True)
print('V3_GALLERY_COMPLETE')
""")
p.write_text(s)
