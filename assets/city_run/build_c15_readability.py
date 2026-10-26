"""Mirror the C15_04 editable Studio guide parts and palette into Blender."""
import bpy,json,math
from pathlib import Path
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'CityRun_C15_gameplay.blend'))
d=json.loads((OUT/'manifest_C15_gameplay.json').read_text())
col=bpy.data.collections.new('C15_04_EditableLandingGuides');bpy.context.scene.collection.children.link(col)
def mat(name,rgb):
 m=bpy.data.materials.new(name);m.diffuse_color=(*[v/255 for v in rgb],1);return m
pale=mat('GuidePale',(241,219,141));dark=mat('LaneEdge',(57,69,72));arrow=mat('TurnArrow',(27,64,77))
top=mat('PostTop',(207,180,128));stem=mat('PostStem',(51,74,86));red=mat('HazardRed',(234,48,34));tiles=[mat('LaneAmber',(179,145,64)),mat('LaneCream',(228,203,132))]
for ob in list(bpy.context.scene.objects):
 if ob.type!='MESH':continue
 name=ob.name
 material=None
 if name.startswith('C15_Post_'):
  if '__Copper__' in name:material=top
  elif '__Ink__' in name:material=stem
 if name.startswith('C15_Crumble_') and '__Edge__' in name:material=tiles[int(name.split('__')[0].split('_')[-1])%2]
 if '__Danger__' in name:material=red
 if material:ob.data.materials.clear();ob.data.materials.append(material)
def box(name,p,s,m,yaw=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(p[0]-3500,-p[2],p[1]))
 ob=bpy.context.object;ob.name=name;ob.scale=(s[0],s[2],s[1]);ob.rotation_euler.z=yaw
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for c in list(ob.users_collection):c.objects.unlink(ob)
 col.objects.link(ob);ob.data.materials.append(m)
for name,c in d['components'].items():
 if c['role'] not in ('Surface','Crumble'):continue
 x,y,z=c['position'];w,_,depth=c['size']
 if c['section'] in ('TerminalPosts','CornerLedges'):
  for sign in (-1,1):
   box(name+f'_OutlineSide{sign}',(x+sign*(w/2-.055),y+.545,z),(.11,.04,depth),pale)
   box(name+f'_OutlineEnd{sign}',(x,y+.545,z+sign*(depth/2-.055)),(w,.04,.11),pale)
 if c['role']=='Crumble':
  for sign in (-1,1):box(name+f'_LaneEdge{sign}',(x+sign*2.27,y+.545,z),(.12,.04,7.5),dark)
for name,direction in [('C15_Corner_07','X'),('C15_Corner_14','Z'),('C15_Zigzag_00','X')]:
 c=d['components'][name];x,y,z=c['position'];base=-math.pi/2 if direction=='X' else math.pi
 for sign in (-1,1):
  # The native cue is aligned from the collision frame.
  ox,oz=sign*.27*math.cos(base),-sign*.27*math.sin(base)
  box(name+f'_TurnArrow{sign}',(x+ox,y+.58,z+oz),(.14,.05,.85),arrow,base+sign*math.pi/4)
bpy.context.scene['ReviewBuildId']='C15_04'
bpy.context.scene['EditingNote']='Guide parts mirror C15Readability.luau. Geometry-only export; use patch chain for collision and motion.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C15_reviewed.blend'))
tri=0
for ob in bpy.context.scene.objects:
 if ob.type=='MESH':ob.data.calc_loop_triangles();tri+=len(ob.data.loop_triangles)
print(json.dumps({'build':'C15_04','guide_objects':len(col.objects),'triangles':tri}))
