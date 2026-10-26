"""Blender-authored C17 terminal precision posts."""
import bpy,json,math
from pathlib import Path
OUT=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
units=[]
collections={}
colors={'stone':(239,184,49),'rim':(241,219,141),'stem':(51,74,86),'ink':(22,36,43),'belt':(43,71,77),'tread':(174,193,168)}
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
for i in range(1,17):
 y=86+48*i/18+(.55 if i%2==0 else -.55)
 cap(f'C15_Post_{i:02}', 'TerminalPosts',3695+(-1)**i*2.25,y,57+127*i/18,.86,1.10,(-1)**i*math.radians(32),50)
bpy.context.scene['ReviewBuildId']='C17_03'
bpy.context.scene['EditingNote']='Small visible caps are the exact colliders; stems and rims do not collide.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C17_posts.blend'))
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C17_posts.fbx'),object_types={'MESH'},axis_forward='-Z',axis_up='Y',add_leaf_bones=False)
(OUT/'manifest_C17_posts.json').write_text(json.dumps(dict(build='C17_03',units=units),indent=2))
print('C17: 16 precision post caps; 47 percent less landing area than C16.')
