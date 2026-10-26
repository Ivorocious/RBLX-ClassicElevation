"""Blender-authored C16 precision caps and conveyor tread geometry."""
import bpy,json,math
from pathlib import Path
OUT=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
units=[]
collections={}
colors={'stone':(207,180,128),'rim':(241,219,141),'stem':(51,74,86),'ink':(22,36,43),'belt':(43,71,77),'tread':(174,193,168)}
materials={}
for k,rgb in colors.items():
 m=bpy.data.materials.new(k);m.diffuse_color=(*[v/255 for v in rgb],1);materials[k]=m
def box(unit,name,pos,size,mat,yaw=0,collide=False,**extra):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0]-3500,-pos[2],pos[1]))
 ob=bpy.context.object;ob.name=unit['name']+'_'+name
 if unit['name'] not in collections:
  collection=bpy.data.collections.new(unit['name']);bpy.context.scene.collection.children.link(collection);collections[unit['name']]=collection
 for current in list(ob.users_collection):current.objects.unlink(ob)
 collections[unit['name']].objects.link(ob)

 ob.scale=(size[0],size[2],size[1]);ob.rotation_euler.z=yaw
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 ob.data.materials.append(materials[mat]);ob['StudioUnit']=unit['name'];ob['StudioPart']=name
 rec=dict(name=name,position=pos,size=size,yaw=yaw,color=colors[mat],collide=collide,**extra);unit['parts'].append(rec)
def cap(name,section,x,y,z,w,d,yaw,base):
 u=dict(name=name,section=section,parts=[]);units.append(u)
 box(u,'Collider',[x,y-.28,z],[w,.56,d],'stone',yaw,True)
 # Recessed slender shaft cannot catch a missed jump at the sides.
 box(u,'Stem',[x,(base+y-.56)/2,z],[min(w*.6,.75),y-.56-base,min(d*.6,.75)],'stem')
 for sign in (-1,1):
  for edge in ('X','Z'):
   lx=sign*(w/2-.04) if edge=='X' else 0
   lz=sign*(d/2-.04) if edge=='Z' else 0
   px=x+lx*math.cos(yaw)+lz*math.sin(yaw);pz=z-lx*math.sin(yaw)+lz*math.cos(yaw)
   box(u,'Rim'+edge+str(sign),[px,y+.012,pz],[.08,.024,d] if edge=='X' else [w,.024,.08],'rim',yaw)
for i in range(1,22):
 cap(f'C15_Expert_{i:02}','ExpertOffsets',3408+208*i/22,82+(.55 if i%2==0 else -.55),-231+(-1)**i*2.85,1.5,1.5,(-1)**i*math.radians(22),64)
for i in range(1,17):
 # Alternating short and tall rises preserve the finish elevation.
 y=86+48*i/18+(.55 if i%2==0 else -.55)
 cap(f'C15_Post_{i:02}','TerminalPosts',3695+(-1)**i*2.25,y,57+127*i/18,1.12,1.6,(-1)**i*math.radians(32),50)
for i in range(9):
 x=3714+116*(i+.5)/9;y=86.7+8.3*(i+.5)/9
 dz=-(-1)**i*6.6;dx=116/9;yaw=math.atan2(-dz,dx);length=math.hypot(dx,dz)+1
 u=dict(name=f'C15_Zigzag_{i:02}',section='ZigzagBeams',parts=[],speed=-3.5);units.append(u)
 box(u,'Collider',[x,y-.5,57],[length,1,3.2],'belt',yaw,True)
 for sign in (-1,1):
  lx=0;lz=sign*1.48
  box(u,'Edge'+str(sign),[x+lz*math.sin(yaw),y+.012,57+lz*math.cos(yaw)],[length,.024,.12],'rim',yaw)
 for k in range(7):
  lx=-length/2+.7+k*2
  box(u,'Tread'+str(k),[x+lx*math.cos(yaw),y+.028,57-lx*math.sin(yaw)],[.22,.04,2.66],'tread',yaw,tread=True)

u=dict(name='C15_SwingFrame_StationMain_04_02',section='SwingingBars',parts=[]);units.append(u)
x,y,z=3711.666748046875,129.6666717529297,184
for sign in (-1,1):box(u,'Upright'+str(sign),[x+sign*4.1,y+5,z],[.25,10,.25],'ink')
box(u,'Crossbar',[x,y+10,z],[8.45,.3,.3],'stone')
box(u,'Suspension',[x,y+5.65,z],[.12,8.3,.12],'ink')

bpy.context.scene['ReviewBuildId']='C16_02'
bpy.context.scene['EditingNote']='One native box per Blender box. manifest_C16.json is shared by the Studio patch. Dimensions remain editable.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C16_precision.blend'))
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C16_precision.fbx'),object_types={'MESH'},axis_forward='-Z',axis_up='Y',add_leaf_bones=False)
data=dict(build='C16_02',units=units,triangles=len(bpy.context.scene.objects)*12)
(OUT/'manifest_C16.json').write_text(json.dumps(data,indent=2))
print(json.dumps({'units':len(units),'parts':len(bpy.context.scene.objects),'triangles':data['triangles']}))
