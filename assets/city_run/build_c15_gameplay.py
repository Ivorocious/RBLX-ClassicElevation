"""Editable C15 route surfaces, hazards and depot interior authored in Blender."""
import bpy,json,math,sys,bmesh
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent; ROOT=OUT.parents[1]
sys.path.insert(0,str(OUT));api={'__file__':str(OUT/'build_city.py')}
exec(compile((OUT/'build_city.py').read_text().split('# Market storefronts frame')[0],str(OUT/'build_city.py'),'exec'),api)
api['groups'].clear();api['components'].clear();scene=api['scene'];scene.name='CityRun_C15_PlayerRoutes'
definitions={};routes={};replacement=[]
for key,col in {'Deck':(.24,.31,.34),'Stone':(.78,.78,.70),'Ink':(.065,.12,.17),'Danger':(1,.025,.015),'Edge':(.98,.72,.16),'Copper':(.58,.36,.20),'Glass':(.10,.26,.33),'Pale':(.87,.83,.70)}.items():
 api['COLORS'][key]=col;m=bpy.data.materials.new(key);m.diffuse_color=(*col,1);api['MATS'][key]=m

def point(p):return (p[0]-3500,p[1],p[2])
def unit(name,section,role='Scenery',**extra):
 api['owner'](name,section);definitions[name]={'section':section,'role':role,**extra}
def box(mat,pos,size):api['box'](mat,point(pos),size)
def beam(mat,a,b,r=.15):api['beam'](mat,point(a),point(b),r,6)
def text(body,pos,size=1.2):api['text'](body,point(pos),size,'Pale',0)
def surface(name,section,pos,size,material='Deck',support=False):
 x,y,z=pos;w,d=size
 unit(name,section,'Surface',position=[x,y-.5,z],size=[w,1,d],top=[x,y,z])
 box(material,(x,y-.35,z),(w,.7,d));box('Ink',(x,y-.85,z),(w-.25,.3,d-.25))
 # Flat edge markings do not add raised lips to jump landings.
 for xx in (x-w/2+.14,x+w/2-.14):box('Edge',(xx,y+.015,z),(.16,.03,max(.3,d-.4)))
 if support:
  unit(name+'_Brackets',section)
  if section=='ExpertOffsets':box('Stone',(x,(64+y-1)/2,z),(.7,y-1-64,.7))
  elif section=='CornerLedges':
   for zz in (z-d*.25,z+d*.25):
    target=(max(3483.5,min(3515.5,x)),y-6,max(-300,min(-264,zz)))
    beam('Ink',(x,y-1,zz),target,.14)
  else:box('Ink',(x,(y-1)/2,z),(.9,y-1,.9))
 return {'center':[x,y,z],'size':[w,1,d],'part':'Obstacles/C15Routes/'+section+'/'+name+'/Collider'}
def hazard(name,section,pos,size,motion=None,axis='X',period=6,distance=0,phase=0):
 attrs={'HazardType':'Kill'}
 if motion:attrs.update(KitMotion=motion,WorldMotionAxis=axis,MotionPeriod=period,MotionDistance=distance,MotionPhase=phase)
 unit(name,section,'Hazard',attrs=attrs,position=list(pos),size=list(size));box('Danger',pos,size)
def gate(name,section,pos,width,direction='z',sliding=False,period=6,phase=0,difficulty='medium'):
 x,y,z=pos;span=width-(6.3 if difficulty=='easy' else 6.0)
 if sliding:span=width-(6.8 if difficulty=='easy' else 7.0)
 offset=0 if sliding else (width-span)/2*(1 if phase==0 else -1)
 sz=(span,9,.65) if direction=='z' else (.65,9,span)
 at=(x+offset,y+4.5,z) if direction=='z' else (x,y+4.5,z+offset)
 hazard(name,section,at,sz,'Slide' if sliding else None,'X' if direction=='z' else 'Z',period,3.1 if difficulty=='easy' else 3.5,phase)
 # Motion rails show the complete sweep outside the feet and head corridor.
 unit(name+'_Rail',section);box('Ink',(x,y+9.6,z),(width+.8,.3,.3) if direction=='z' else (.3,.3,width+.8))
 for sign in (-1,1):
  xx=x+sign*(width/2+.35) if direction=='z' else x;zz=z if direction=='z' else z+sign*(width/2+.35)
  box('Copper',(xx,y+4.7,zz),(.3,9.4,.3))


def rotbox(mat,pos,size,yaw):
 x,y,z=point(pos);a,b,c=[v/2 for v in size];co,si=math.cos(yaw),math.sin(yaw)
 vs=[(x+i*a*co+k*c*si,y+j*b,z-i*a*si+k*c*co) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 api['geo'](mat,vs,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])

# Shorter offset landings tighten the existing expert route.
expert=[surface('C15_Expert_Start','ExpertOffsets',(3408,82,-231),(6.6,6.6),'Stone',True)]
for i in range(1,22):expert.append(surface(f'C15_Expert_{i:02}','ExpertOffsets',(3408+208*i/22,82,-231+(-1)**i*1.85),(2.15,2.15),'Stone',True))
expert.append(surface('C15_Expert_End','ExpertOffsets',(3616,82,-231),(6.6,6.6),'Stone',True));routes['ExpertOffsets']=expert
unit('C15_ExpertLowGirder','ExpertOffsets');box('Ink',(3512,63.5,-231),(211,1,7))
# Keep the ball crossing decks; add low jump bars away from the swing center.
for k,(x,period) in enumerate(((3440,7),(3476,7.5),(3520,7.5),(3560,7))):
 hazard(f'C15_CrossingHurdle_{k}','BallApproaches',(x,82.6,-257),(.7,.7,10.4))
 unit(f'C15_CrossingFeet_{k}','BallApproaches')
 for z in (-261.8,-252.2):box('Copper',(x,82.2,z),(1,.4,1))
# Ledges crest around the far corner, with raised endpoints clear of the wooden decks.
path=[]
for i in range(9):path.append((3480.5,-263-i*5))
for i in range(1,8):path.append((3480.5+38*i/7,-303))
for i in range(1,9):path.append((3518.5,-303+5*i))
corner=[]
for i,(x,z) in enumerate(path):
 y=83+11*math.sin(math.pi*i/(len(path)-1))
 corner.append(surface(f'C15_Corner_{i:02}','CornerLedges',(x,y,z),(4,4),'Stone',True))
routes['CornerLedges']=corner
# Ascending steel posts form the terminal's hardest shortcut, without layered skins.
posts=[]
for i in range(1,17):
 t=i/18;x=3695+(-1)**i*1.15;y=86+48*t;z=57+127*t
 name=f'C15_Post_{i:02}';posts.append(surface(name,'TerminalPosts',(x,y,z),(1.6,1.6),'Copper'))
 unit(name+'_Stem','TerminalPosts');box('Ink',(x,(50+y-1)/2,z),(1.2,y-1-50,1.2));box('Pale',(x,y-1.4,z),(1.65,.3,1.65))
routes['TerminalPosts']=posts
# Broad enough to walk, narrow enough to demand balance; alternating diagonal beams.
zig=[]
for i in range(10):
 t=i/9;zig.append((3714+116*t,86.7+8.3*t,57+(-1)**i*3.3))
for i,(a,b) in enumerate(zip(zig,zig[1:])):
 v=Vector(b)-Vector(a);length=math.hypot(v.x,v.z);yaw=math.atan2(-v.z,v.x)
 # Small rises are discrete at joints; each beam has a horizontal top.
 y=(a[1]+b[1])/2;x=(a[0]+b[0])/2;z=(a[2]+b[2])/2
 name=f'C15_Zigzag_{i:02}';unit(name,'ZigzagBeams','Surface',position=[x,y-.5,z],size=[length+1,1,3.2],yaw=yaw,top=[x,y,z])
 start=len(api['groups'])
 # Generate directly rotated cuboid vertices through the shared box helper.
 rotbox('Ink',(x,y-.5,z),(length+1,1,3.2),yaw)
 rotbox('Edge',(x,y+.015,z),(length+.7,.03,.18),yaw)
 routes.setdefault('ZigzagBeams',[]).append({'center':[x,y,z],'size':[length+1,1,3.2],'yaw':yaw,'part':'Obstacles/C15Routes/ZigzagBeams/'+name+'/Collider'})
# Four tile lanes with generous time to cross and three low rotors.
for row in range(13):
 z=77+row*10.5;y=96+9*row/12
 for lane in range(4):
  x=3833.5+(lane-1.5)*5.2;name=f'C15_Crumble_{row:02}_{lane}'
  surface(name,'CrumbleRotors',(x,y,z),(4.7,7.7),'Edge')
  definitions[name]['role']='Crumble';definitions[name]['attrs']={'HazardType':'Crumble','CrumbleDelay':.95,'CrumbleResetTime':3.5}
 if row in (3,7,11):
  hazard(f'C15_Rotor_{row}','CrumbleRotors',(3833.5,y+.7,z),(18,.6,.65),'Spin','Y',7.5,0,row*19)
  unit(f'C15_RotorHub_{row}','CrumbleRotors');box('Copper',(3833.5,y-1.8,z),(1.3,4,1.3))
# Suspended low bars swing sideways over existing station landing platforms.
station=json.loads((OUT/'c15_live_station.json').read_text())
for r in station['parts']:
 name=r['path'].split('.')[-1]
 if r['class']!='Part' or not name.startswith(('StationMain_02','StationMain_03','StationMain_04')):continue
 if name.endswith('04_03'):continue
 x,y,z=r['cf'][:3];y+=.5;w,_,d=r['size']
 hazard('C15_Swing_'+name,'SwingingBars',(x,y+1,z),(min(10,w-.8),.7,.65),'Swing','Y',6.5,0,0)
 definitions['C15_Swing_'+name]['attrs']['MotionAngle']=65
 unit('C15_SwingFrame_'+name,'SwingingBars')
 for xx in (x-w/2-.45,x+w/2+.45):box('Ink',(xx,y+5,z),(.25,10,.25))
 box('Copper',(x,y+10,z),(w+1.2,.3,.3));beam('Ink',(x,y+1.5,z),(x,y+9.8,z),.09)
# Reuse the approved Blender coach geometry, preserving its cab and wheel detail.
with bpy.data.libraries.load(str(OUT/'CityRun_C12_terminal.blend'),link=False) as (src,dst):
 dst.objects=[n for n in src.objects if n.startswith('ActiveTrain')]
coach_objects=dst.objects
for i,source_index in enumerate((0,1,1,1,2)):
 name=f'ActiveTrain{i}';cx=3590+(i-2)*43
 unit(name,'Train','Train',pivot=[cx,89,-12])
 for ob in coach_objects:
  if not ob or not ob.name.startswith(f'ActiveTrain{source_index}__'):continue
  mat=ob.name.split('__')[1]
  if mat not in api['MATS']:
   col=tuple(ob.data.materials[0].diffuse_color[:3]);api['COLORS'][mat]=col
   m=bpy.data.materials.new(mat);m.diffuse_color=(*col,1);api['MATS'][mat]=m
  source_cx=3590+(source_index-1)*38-3500
  verts=[]
  for v in ob.data.vertices:
   q=ob.matrix_world@v.co
   verts.append((cx-3500+(q.x-source_cx)*1.1,12+(q.y-12)*1.1,80.65+(q.z-80.65)*1.1))
  faces=[tuple(poly.vertices) for poly in ob.data.polygons]
  api['groups'].setdefault((name,mat),[]).append((verts,faces))

# Calibrated import and per-component material meshes retain simple edit units.
for key,pos in [('Origin',(3500,0,0)),('Right',(3510,0,0)),('Up',(3500,10,0)),('Forward',(3500,0,-10))]:unit('Marker'+key,'Calibration');box('Iron',pos,(.1,.1,.1))
collections={}
for section in set(d['section'] for d in definitions.values()):
 col=bpy.data.collections.new('C15_'+section);scene.collection.children.link(col);collections[section]=col
meshes={};objects=[]
for (name,mat),chunks in api['groups'].items():
 for idx,(verts,faces) in enumerate(chunks):
  key=f'{name}__{mat}__{idx:02}';mesh=bpy.data.meshes.new(key);mesh.from_pydata(verts,[],faces);mesh.materials.append(api['MATS'][mat]);mesh.update();bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.calc_loop_triangles()
  ob=bpy.data.objects.new(key,mesh);collections[definitions[name]['section']].objects.link(ob);center=sum((v.co for v in mesh.vertices),Vector())/len(mesh.vertices)
  for v in mesh.vertices:v.co-=center
  ob.location=center;objects.append(ob);meshes[key]={'component':name,'material':mat,'triangles':len(mesh.loop_triangles)}
for ob in scene.objects:ob.select_set(False)
for ob in objects:ob.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C15_gameplay.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(val) for k,val in v.items())+'}'
 if isinstance(v,(list,tuple)):return '{'+','.join(map(lua,v))+'}'
 return json.dumps(v)
data={'revision':'C15_03','components':definitions,'meshes':meshes,'colors':api['COLORS'],'replacements':sorted(set(replacement)),'routes':routes}
(OUT/'manifest_C15_gameplay.json').write_text(json.dumps(data,indent=2));(ROOT/'src/ServerStorage/CourseBuilders/CityRun/C15Manifest.luau').write_text('--!strict\nreturn '+lua(data)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C15_gameplay.blend'))
print(json.dumps({'meshes':len(meshes),'triangles':sum(m['triangles'] for m in meshes.values()),'units':len(definitions),'replacements':len(set(replacement))}))
