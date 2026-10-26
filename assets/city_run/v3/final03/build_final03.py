"""Rebuild scenery at authored proportions; consolidate preserved terminal geometry."""
import bpy,json,math,struct,zlib
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parent
V3=ROOT.parent
BUILD='V3_FINAL_03'
rows=[]
for p in sorted(ROOT.glob('terminal-page*.json'),key=lambda p:int(p.stem.replace('terminal-page',''))):
 rows+=json.loads(p.read_text())
(ROOT/'terminal-live.json').write_text(json.dumps(rows))
bpy.ops.wm.open_mainfile(filepath=str(V3.parent/'CityRun_C13_terminal.blend'))
source={o.name:o for o in bpy.data.objects if o.type=='MESH'}
missing=sorted(set(r['n'] for r in rows)-set(source))
(ROOT/'source-match.json').write_text(json.dumps({'parts':len(rows),'missing':missing},indent=2))
if missing: raise RuntimeError('Missing original geometry: '+str(missing[:12]))
# RGB palette retains native Studio colors, with richer colors for the new residential shells.
colors=[]
def color(rgb):
 rgb=tuple(round(v*255) if isinstance(v,float) else v for v in rgb)
 if rgb not in colors: colors.append(rgb)
 return colors.index(rgb)
CREAM=color((239,229,204)); WHITE=color((248,239,217)); STONE=color((126,129,121))
INK=color((20,36,48)); GLASS=color((24,66,85)); REFLECT=color((42,91,106))
GOLD=color((190,137,48)); ROOF=color((35,39,49)); BRICK=color((169,62,41))
TEAL=color((24,110,114)); OCHRE=color((207,153,58)); CORAL=color((188,79,56))
SAGE=color((51,128,113)); BLUE=color((47,107,145))
geo={}; placements=[]; records=[]; objects=[]
def create(name,verts,faces,cols,pos,category='Architecture',label=None):
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(obj)
 uv=mesh.uv_layers.new(name='UVMap')
 for f,idx in zip(mesh.polygons,cols):
  u=((idx%16)*8+4)/128;v=1-((idx//16)*8+4)/128
  for li in f.loop_indices:uv.data[li].uv=(u,v)
 mesh.calc_loop_triangles()
 mn=[min(v.co[i] for v in mesh.vertices) for i in range(3)]
 mx=[max(v.co[i] for v in mesh.vertices) for i in range(3)]
 dims=[mx[i]-mn[i] for i in range(3)]
 record={'id':name,'dimensionsRobloxXYZ':[dims[0],dims[2],dims[1]],'centerBlender':[(a+b)/2 for a,b in zip(mn,mx)],'triangles':len(mesh.loop_triangles),'vertices':len(mesh.vertices)}
 records.append(record);objects.append(obj)
 obj['V3AssetId']=name;obj['Build']=BUILD;obj['VisualOnly']=True
 placements.append(dict(asset=name,pos=pos,size=record['dimensionsRobloxXYZ'],yaw=0,label=label or name,category=category))
 return obj
groups={}
for r in rows:groups.setdefault(r['g'],[]).append(r)
for name,parts in sorted(groups.items()):
 vs=[];fs=[];cs=[]
 world=[]
 for r in parts:
  ob=source[r['n']];mesh=ob.data
  lo=Vector([min(v.co[i] for v in mesh.vertices) for i in range(3)])
  hi=Vector([max(v.co[i] for v in mesh.vertices) for i in range(3)])
  mid=(lo+hi)/2;d=hi-lo;c=r['c'];s=r['s']
  rot=Matrix((c[3:6],c[6:9],c[9:12]));offset=Vector(c[:3])
  start=len(vs)
  for v in mesh.vertices:
   q=v.co-mid
   # FBX imported mesh axes are reversed horizontally; retain the live CFrame.
   loc=Vector((-q.x*s[0]/d.x,q.z*s[1]/d.z,q.y*s[2]/d.y))
   w=rot@loc+offset
   vs.append((w.x-3500,-w.z,w.y))
  idx=color(tuple(r['col']))
  for f in mesh.polygons:fs.append(tuple(start+i for i in f.vertices));cs.append(idx)
 x0=min(v[0] for v in vs);x1=max(v[0] for v in vs);y0=min(v[1] for v in vs);y1=max(v[1] for v in vs);z0=min(v[2] for v in vs)
 center=((x0+x1)/2,(y0+y1)/2,z0)
 local=[tuple(v[i]-center[i] for i in range(3)) for v in vs]
 create('F03_'+name,local,fs,cs,[center[0]+3500,center[2],-center[1]],label=name)
# Source objects remain in the .blend as hidden references, excluded from exports.
refs=bpy.data.collections.new('Original terminal source - not exported');bpy.context.scene.collection.children.link(refs)
for ob in list(source.values()):
 for col in list(ob.users_collection):col.objects.unlink(ob)
 refs.objects.link(ob);ob.hide_render=True;ob.hide_set(True)
class Geo:
 def __init__(self):self.v=[];self.f=[];self.c=[]
 def face(self,v,c):
  n=len(self.v);self.v+=list(v);self.f.append(tuple(range(n,n+len(v))));self.c.append(c)
 def box(self,p,s,c):
  x,y,z=p;a,b,d=[q/2 for q in s]
  vs=[(x+i*a,y+j*b,z+k*d)for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
  for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:self.face([vs[i]for i in f],c)
 def window(self,a,z,w,h,side,wall,d):
  # Each pane gets fixed proportions instead of stretched baked facade artwork.
  def quad(x0,x1,z0,z1,depth,c):
   if side==0:v=[(x0,-d/2-depth,z0),(x1,-d/2-depth,z0),(x1,-d/2-depth,z1),(x0,-d/2-depth,z1)]
   elif side==1:v=[(-x0,d/2+depth,z0),(-x1,d/2+depth,z0),(-x1,d/2+depth,z1),(-x0,d/2+depth,z1)]
   elif side==2:v=[(wall/2+depth,x0,z0),(wall/2+depth,x1,z0),(wall/2+depth,x1,z1),(wall/2+depth,x0,z1)]
   else:v=[(-wall/2-depth,-x0,z0),(-wall/2-depth,-x1,z0),(-wall/2-depth,-x1,z1),(-wall/2-depth,-x0,z1)]
   self.face(v,c)
  quad(a-w/2-.28,a+w/2+.28,z-h/2-.28,z+h/2+.28,.045,WHITE)
  quad(a-w/2,a+w/2,z-h/2,z+h/2,.055,GLASS)
  quad(a-w/2+.3,a-.12,z-h/2+.3,z+h/2-.3,.06,REFLECT)
  quad(a-.10,a+.10,z-h/2,z+h/2,.075,CREAM)
  quad(a-w/2,a+w/2,z-.1,z+.1,.08,CREAM)
 def shell(self,w,d,h,wall,roofh=2):
  body=h-roofh
  self.box((0,0,body/2),(w,d,body),wall)
  self.box((0,0,.75),(w+.15,d+.15,1.5),STONE)
  floors=max(1,round(body/15))
  step=body/floors
  for j in range(1,floors):self.box((0,0,j*step),(w+.2,d+.2,.26),CREAM)
  for side,length in enumerate([w,w,d,d]):
   n=max(1,int((length-3)/9.5));gap=length/n
   for j in range(floors):
    wh=min(9.4,step*.64);ww=min(5.4,gap*.56)
    for i in range(n):self.window((i+.5)*gap-length/2,(j+.5)*step,ww,wh,side,w,d)
  self.box((0,0,body-.2),(w+.35,d+.35,.75),WHITE)
  self.box((0,0,body+roofh/2),(w+.5,d+.5,roofh),ROOF)
  for x in (-w/2,w/2):self.box((x,0,h+.25),(.25,d+.5,.5),CREAM)
  for y in (-d/2,d/2):self.box((0,y,h+.25),(w+.5,.25,.5),CREAM)
plan=json.loads((V3/'stage2-layout.json').read_text())
old=plan['placements'];bylabel={p['label']:p for p in old}
terminal_labels={p['label'] for p in old if p['label'].startswith(('C13_','TerminalBase','MainHall'))}
skip=set(terminal_labels);keep=[];restore=set()
for i,p in enumerate(old):
 if p['label']in skip or p['label'].endswith('_roof'):continue
 if p['category']=='Architecture' and not 'Skyline' in p['asset']:
  w,h,d=p['size'];rp=bylabel.get(p['label']+'_roof')
  # Thin trim objects are kept as their original native source, not rebuilt as houses.
  if h<15 or '__'in p['label']:
   restore.add(p['label']);continue
  roofh=1.1
  g=Geo();palette={'Ochre':OCHRE,'Coral':CORAL,'Sage':SAGE,'Cream':CREAM,'Blue':BLUE,'Brick':BRICK,'Loggia':OCHRE,'Courtyard':CORAL,'Atelier':BRICK}
  c=next((v for k,v in palette.items()if k in p['asset']),TEAL)
  fullh=h+(rp['size'][1]if rp else 0)
  g.shell(w,d,fullh,c,roofh)
  create('F03_City_'+str(i),g.v,g.f,g.c,p['pos'],label=p['label'])
 else:keep.append(p)
# Close courtyard/rooftop outward sightlines with low-cost, fully grounded backing blocks.
for i,(x,z,w,d,h) in enumerate([(3180,-100,75,35,138),(3220,-205,65,38,150),(3280,-350,60,36,165),(3380,-375,65,36,158)]):
 g=Geo();g.shell(w,d,h,[BLUE,OCHRE,CORAL,TEAL][i])
 create('F03_Backdrop_'+str(i),g.v,g.f,g.c,[x,0,z],label='GapBackdrop_'+str(i))
replacement_paths=[p for p in plan['replacePaths'] if p.split('.')[-1]not in restore]
# Every terminal group represented in the source manifest is consolidated, including shallow surfaces.
replacement_paths=sorted(set(replacement_paths+[f'RaceCourse.Decoration.C13Terminal.{n}'for n in groups]))
result={'build':BUILD,'source':'Preserved V2 gameplay and live C13 visual transforms','placements':keep+placements,'replacePaths':replacement_paths,'heightCaps':plan.get('heightCaps',[]),'scope':'Scenery correction; original terminal form consolidated per building'}
(ROOT/'layout.json').write_text(json.dumps(result,indent=2))
# Tiny shared palette, including exact native terminal RGBs, keeps materials single and opaque.
assert len(colors)<256
raw=b''.join(b'\x00'+bytes(sum((list(colors[min((y//8)*16+x//8,len(colors)-1)])+[255] for x in range(128)),[]))for y in range(128))
def chunk(t,d):return struct.pack('!I',len(d))+t+d+struct.pack('!I',zlib.crc32(t+d)&0xffffffff)
(ROOT/'palette.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',128,128,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
img=bpy.data.images.load(str(ROOT/'palette.png'));img.pack()
mat=bpy.data.materials.new('City_Final_SharedPalette');mat.use_nodes=True
nodes=mat.node_tree.nodes;tex=nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
nodes.get('Principled BSDF').inputs['Roughness'].default_value=.8
for i,o in enumerate(objects):
 o.data.materials.clear();o.data.materials.append(mat)
 o.location=(i%12*180,i//12*230,0)
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.hide_set(False);o.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(ROOT/'CityRun_Final03.fbx'),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=False,axis_forward='-Z',axis_up='Y',use_triangles=True,path_mode='COPY',embed_textures=True,add_leaf_bones=False,bake_anim=False)
bpy.context.scene.name=BUILD
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CityRun_Final03_Assets.blend'))
report={'build':BUILD,'assets':records,'totalTriangles':sum(r['triangles']for r in records),'originalTerminalParts':len(rows),'terminalMeshes':len(groups),'newCityMeshes':len(objects)-len(groups),'colors':len(colors),'placements':len(result['placements']),'restoredTrimLabels':sorted(restore),'texture':'palette.png'}
(ROOT/'manifest.json').write_text(json.dumps(report,indent=2))
print('FINAL03',json.dumps({k:v for k,v in report.items()if k!='assets'}))
