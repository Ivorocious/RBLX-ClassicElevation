"""Editable C14 route surfaces, hazards and depot interior authored in Blender."""
import bpy,json,math,sys,bmesh
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent; ROOT=OUT.parents[1]
sys.path.insert(0,str(OUT));api={'__file__':str(OUT/'build_city.py')}
exec(compile((OUT/'build_city.py').read_text().split('# Market storefronts frame')[0],str(OUT/'build_city.py'),'exec'),api)
api['groups'].clear();api['components'].clear();scene=api['scene'];scene.name='CityRun_C14_PlayerRoutes'
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
 return {'center':[x,y,z],'size':[w,1,d],'part':'Obstacles/C14Routes/'+section+'/'+name+'/Collider'}
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

source=json.loads((OUT/'c14_live_input.json').read_text())['records']
old={r['path'].split('/')[-1]:r for r in source if r['path'].startswith('Course_CityRun/Obstacles/WalkingSurfaces/') and r.get('class')=='Part' and 'cf' in r}
# Easy-medium rooftops retain their rising path and spacious landing footprints.
for name,r in sorted(old.items()):
 if name.startswith('DistrictRoofs_'):
  if name.endswith('00_00') or name.endswith('04_02'):continue
  replacement.append(name);x,y,z=r['cf'][:3];w,_,d=r['size'];top=y+.5
  surface('C14_'+name,'DistrictWeaves',(x,top,z),(w,d),support=False)
  direction='x' if name.startswith(('DistrictRoofs_00','DistrictRoofs_02','DistrictRoofs_04')) else 'z'
  width=d if direction=='x' else w
  idx=int(name.split('_')[-1]);sliding=name.startswith(('DistrictRoofs_02','DistrictRoofs_03'))
  gate('C14_Gate_'+name,'DistrictWeaves',(x,top,z),width,direction,sliding,6.5,180*(idx%2),'easy')
# Medium low sweeps: retain entry route spacing; three clear timing decks.
for name,r in sorted(old.items()):
 if name.startswith('RoofMainEntry_') and not name.endswith('00_00'):
  replacement.append(name);x,y,z=r['cf'][:3];w,_,d=r['size'];surface('C14_'+name,'LowSweeps',(x,y+.5,z),(w,d),'Deck')
  if name in ('RoofMainEntry_00_01','RoofMainEntry_00_03','RoofMainEntry_02_01'):
   hazard('C14_Sweep_'+name,'LowSweeps',(x,y+1.15,z),(9.2,.55,.65),'Spin','Y',6.8)
   unit('C14_Hub_'+name,'LowSweeps');box('Copper',(x,y+.68,z),(.65,.32,.65))
# One substantial building, with narrow ledges around three outside corners.
unit('C14_CornerBuilding_Body','CornerLedges','Solid',position=[3499.5,50,-282],size=[34,100,38]);box('Plaster',(3499.5,50,-282),(34,100,38))
for yy in (6,28,50,72,98):box('Pale',(3499.5,yy,-282),(34.5,.7,38.5))
unit('C14_CornerBuilding_Roof','CornerLedges');box('Ink',(3499.5,100.3,-282),(35,.6,39));box('Copper',(3499.5,100.75,-282),(35.2,.3,39.2))
for side in (-1,1):
 for yy in (18,38,58,94):
  for zz in (-291,-282,-273):
   unit(f'C14_CornerWindow_{side}_{yy}_{zz}','CornerLedges');box('Glass',(3499.5+side*17.55,yy,zz),(.1,8,4));box('Pale',(3499.5+side*17.65,yy-4.1,zz),(.3,.35,4.5))
corner=[]
for i,z in enumerate((-257,-270,-283,-296,-303)):
 if i==0:corner.append({'center':[3480.5,82,z],'size':[56,1,11],'part':'Obstacles/WalkingSurfaces/BallA_Main/BallA_Main'})
 else:corner.append(surface(f'C14_Corner_W{i}','CornerLedges',(3480.5,82,z),(4.8,8.5 if i!=4 else 5.5),'Stone',True))
for i,x in enumerate((3491,3501.5,3512,3518.5)):
 corner.append(surface(f'C14_Corner_N{i}','CornerLedges',(x,82,-303),(6.5 if i<3 else 4.8,4.8),'Stone',True))
for i,z in enumerate((-293,-280,-267,-257)):
 if i==3:corner.append({'center':[3518.5,82,z],'size':[58,1,11],'part':'Obstacles/WalkingSurfaces/BallB_Main/BallB_Main'})
 else:corner.append(surface(f'C14_Corner_E{i}','CornerLedges',(3518.5,82,z),(4.8,8.5),'Stone',True))
routes['CornerLedges']=corner
# Very hard short offset blocks. The route stays in its existing expert corridor.
expert=[surface('C14_Expert_Start','ExpertOffsets',(3408,82,-231),(6.6,6.6),'Stone',True)]
for i in range(1,22):expert.append(surface(f'C14_Expert_{i:02}','ExpertOffsets',(3408+208*i/22,82,-231+(-1)**i*1.65),(2.6,2.6),'Stone',True))
expert.append(surface('C14_Expert_End','ExpertOffsets',(3616,82,-231),(6.6,6.6),'Stone',True));routes['ExpertOffsets']=expert
unit('C14_ExpertLowGirder','ExpertOffsets');box('Ink',(3512,63.5,-231),(211,1,7))
# Medium travelling hurdles replace the garden detour traps.
for name,r in sorted(old.items()):
 if name.startswith('RoofGarden_'):
  replacement.append(name);x,y,z=r['cf'][:3];w,_,d=r['size'];top=y+.5;surface('C14_'+name,'TravellingHurdles',(x,top,z),(w,d),'Deck')
  if name in ('RoofGarden_00_01','RoofGarden_01_01','RoofGarden_01_03','RoofGarden_02_02'):
   along='X' if name.startswith('RoofGarden_01') else 'Z'
   size=(.7,.65,d-.6) if along=='X' else (w-.6,.65,.7)
   hazard('C14_Travel_'+name,'TravellingHurdles',(x,top+.65,z),size,'Slide',along,5.8,2.4,180 if name.endswith('03') else 0)
# Medium-hard strip jumps on the turn into the depot.
strip=[]
for i,(x,z,w,d) in enumerate(((3632.3,-244,10,9),(3648.7,-244,10,9),(3665,-244,10,9),(3665,-227,10,11))):
 strip.append(surface(f'C14_Strip_{i}','DepotEntry',(x,82,z),(w,d),'Deck',True))
 direction='x' if i<3 else 'z';sz=(.65,.38,d-.4) if direction=='x' else (w-.4,.38,.65)
 hazard(f'C14_KillStrip_{i}','DepotEntry',(x,82.24,z),sz)
routes['DepotEntry']=strip
# Clean depot catwalk above the parked train bodies, with five changing side gaps.
for i,(z,depth) in enumerate(((-210,22),(-188,22),(-166,22),(-144,22),(-122,22),(-103.5,15))):
 surface(f'C14_DepotDeck_{i}','DepotSlalom',(3665,82,z),(12,depth),'Deck')
 unit(f'C14_DeckJoint_{i}','DepotSlalom');box('Copper',(3665,82.02,z-depth/2+.2),(11.6,.04,.12))
for i,z in enumerate((-198,-177,-156,-135,-114)):gate(f'C14_DepotSlalom_{i}','DepotSlalom',(3665,82,z),12,'z',True,4.8+(i%2)*.6,180*(i%2))
# High, supported canopy clears the player and trailing camera. One sign at each end.
for i,z in enumerate((-218,-182,-146,-90)):
 unit(f'C14_DepotFrame_{i}','DepotShelter')
 for x in (3651,3679):box('Pale',(x,87,z),(.8,26,.8));box('Ink',(x,74.8,z),(1.5,1.6,1.5))
 box('Ink',(3665,100,z),(29,.65,.65))
unit('C14_DepotCeiling','DepotShelter');box('Roof',(3665,101,-154),(29,1,136));box('Ink',(3665,100.3,-154),(29,.4,136))
for i,z in enumerate((-223,-86)):
 unit(f'C14_DepotSign_{i}','DepotShelter');box('Ink',(3665,96,z),(12,2.4,.25));text('DEPOT' if i==0 else 'TRANSFER',(3665,96,z-.2),1.1)
# New checkpoint before hard checker traps. Leave a full safe stopping deck.
surface('C14_DepotCheckpoint','DepotExit',(3665,82,-90),(12,12),'Deck')
# Four decks form the requested L-shaped hard checker exit, with safe edge-to-edge jumps.
checker=[]
for i,(x,z,w,d) in enumerate(((3665,-74,10,12),(3665,-58,10,12),(3680,-58,11,10),(3694,-58,11,10),(3705,-53,10,8))):
 checker.append(surface(f'C14_CheckerDeck_{i}','CheckerExit',(x,82,z),(w,d),'Deck',True))
 # Alternating two-by-three floor threats leave a deliberate zigzag of safe squares.
 along_x=i in (2,3)
 width=d if along_x else w; length=w if along_x else d
 cellw=width/2;celld=length/3
 for row in range(3):
  col=(row+(1 if i==4 else 0))%2
  across=-width/2+cellw*(col+.5);along=-length/2+celld*(row+.5)
  xx=x+along if along_x else x+across;zz=z+across if along_x else z+along
  size=(celld-.28,.16,cellw-.28) if along_x else (cellw-.28,.16,celld-.28)
  hazard(f'C14_Checker_{i}_{row}','CheckerExit',(xx,82.08,zz),size)
routes['CheckerExit']=checker
replacement+=['DepotTransfer']
replacement += [name for name in old if name.startswith(('RoofMainMiddle_','X02_','DepotAccess_','StationaryTrains_','DepotExit_')) and name!='DepotAccess_00_00']
# Signature wrecking-ball crossings keep their original platforms and runtime.
# Calibrated import and per-component material meshes retain simple edit units.
for key,pos in [('Origin',(3500,0,0)),('Right',(3510,0,0)),('Up',(3500,10,0)),('Forward',(3500,0,-10))]:unit('Marker'+key,'Calibration');box('Iron',pos,(.1,.1,.1))
collections={}
for section in set(d['section'] for d in definitions.values()):
 col=bpy.data.collections.new('C14_'+section);scene.collection.children.link(col);collections[section]=col
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
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C14_gameplay.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(val) for k,val in v.items())+'}'
 if isinstance(v,(list,tuple)):return '{'+','.join(map(lua,v))+'}'
 return json.dumps(v)
data={'revision':'C14_05','components':definitions,'meshes':meshes,'colors':api['COLORS'],'replacements':sorted(set(replacement)),'routes':routes}
(OUT/'manifest_C14_gameplay.json').write_text(json.dumps(data,indent=2));(ROOT/'src/ServerStorage/CourseBuilders/CityRun/C14Manifest.luau').write_text('--!strict\nreturn '+lua(data)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C14_gameplay.blend'))
print(json.dumps({'meshes':len(meshes),'triangles':sum(m['triangles'] for m in meshes.values()),'units':len(definitions),'replacements':len(set(replacement))}))
