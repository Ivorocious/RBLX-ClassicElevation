"""Build the V3 painted city asset library in a separate background Blender process."""
from pathlib import Path
import bpy, bmesh, json, math, hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
REPORT=ROOT.parents[2]/'docs/artifacts/city-run/v3'
REPORT.mkdir(parents=True,exist_ok=True)
EXPORT=ROOT/'exports';EXPORT.mkdir(exist_ok=True)
BUILD='V3_KIT_05'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.name=BUILD
scene.unit_settings.system='NONE'
meta=json.loads((ROOT/'atlas.json').read_text()); tiles=meta['tiles']
img=bpy.data.images.load(str(ROOT/'painted_atlas.png'));img.pack()
mat=bpy.data.materials.new('V3_Shared_Painted_Atlas');mat.use_nodes=True
nodes=mat.node_tree.nodes;shader=nodes.get('Principled BSDF');shader.inputs['Roughness'].default_value=.88
tex=nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Linear'
mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
assets=[]; groups={}
class Geo:
 def __init__(self): self.v=[];self.f=[];self.uv=[]
 def add(self,vs,fs,tile):
  n=len(self.v);self.v.extend(vs)
  tx,ty,tw,th=tiles[tile];u0=(tx+6)/2048;u1=(tx+tw-6)/2048;v0=1-(ty+th-6)/1024;v1=1-(ty+6)/1024
  for f in fs:
   self.f.append(tuple(n+i for i in f));self.uv.append([(u0,v0),(u1,v0),(u1,v1),(u0,v1)] if len(f)==4 else [(u0+(u1-u0)*(.5+.46*math.cos(i*math.tau/len(f))),v0+(v1-v0)*(.5+.46*math.sin(i*math.tau/len(f)))) for i in range(len(f))])
 def box(self,p,s,tile):
  x,y,z=p;a,b,c=[v/2 for v in s]
  self.add([(x+i*a,y+j*b,z+k*c) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],tile)
 def beam(self,a,b,w,tile):
  a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,0,1)))
  if u.length<.01:u=d.cross(Vector((0,1,0)))
  u.normalize();v=d.cross(u);vs=[tuple(p+w/2*(u*i+v*j)) for p in (a,b) for i,j in [(-1,-1),(1,-1),(1,1),(-1,1)]]
  self.add(vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],tile)
 def cyl(self,p,r,h,tile,n=12,r2=None):
  x,y,z=p;r2=r if r2 is None else r2
  vs=[(x+rr*math.cos(i*math.tau/n),y+rr*math.sin(i*math.tau/n),z+zz) for zz,rr in [(0,r),(h,r2)] for i in range(n)]
  self.add(vs,[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],tile)
 def window(self,x,y,z,w,h,tile='window_teal',rot=0):
  # Opaque inset-looking artwork on a slightly separated facade plane.
  vs=[(-w/2,0,-h/2),(w/2,0,-h/2),(w/2,0,h/2),(-w/2,0,h/2)]
  self.add([(x+a*math.cos(rot),y+a*math.sin(rot),z+c) for a,b,c in vs],[(0,1,2,3)],tile)
 def gable(self,w,d,h,tile='terracotta'):
  vs=[(-w/2,-d/2,0),(w/2,-d/2,0),(0,-d/2,h),(-w/2,d/2,0),(w/2,d/2,0),(0,d/2,h)]
  self.add(vs,[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)],tile)
 def arch(self,w,h,depth,thickness,tile):
  radius=w/2;spring=h-radius;inner=radius-thickness
  for i in range(12):
   a=i*math.pi/12;b=(i+1)*math.pi/12
   q=[(rr*math.cos(t),yy,spring+rr*math.sin(t)) for yy in (-depth/2,depth/2) for rr,t in [(inner,a),(radius,a),(radius,b),(inner,b)]]
   self.add(q,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],tile)
  for x in (-radius+thickness/2,radius-thickness/2):self.box((x,0,spring/2),(thickness,depth,spring),tile)
 def blob(self,p,scale,tile):
  x,y,z=p;sx,sy,sz=scale;n=8;vs=[(x,y,z-sz)]
  for j in range(1,4):
   t=math.pi*j/4
   for i in range(n):a=i*math.tau/n;vs.append((x+sx*math.sin(t)*math.cos(a),y+sy*math.sin(t)*math.sin(a),z-sz*math.cos(t)))
  vs.append((x,y,z+sz));fs=[(0,1+(i+1)%n,1+i)for i in range(n)]
  for j in range(2):
   for i in range(n):fs.append((1+j*n+i,1+j*n+(i+1)%n,1+(j+1)*n+(i+1)%n,1+(j+1)*n+i))
  fs.extend((25,17+i,17+(i+1)%n)for i in range(n));self.add(vs,fs,tile)
 def finish(self,name,family,tier='Close',notes=''):
  mesh=bpy.data.meshes.new(name);mesh.from_pydata(self.v,[],self.f);mesh.update()
  layer=mesh.uv_layers.new(name='UVMap')
  for poly,coords in zip(mesh.polygons,self.uv):
   for li,uv in zip(poly.loop_indices,coords):layer.data[li].uv=uv
  # Keep authored outward normals on isolated opaque artwork planes.
  bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=[f for f in bm.faces if any(len(e.link_faces)>1 for e in f.edges)]);bm.to_mesh(mesh);bm.free();mesh.update()
  ob=bpy.data.objects.new(name,mesh);col=bpy.data.collections.new(name);scene.collection.children.link(col);col.objects.link(ob);ob.data.materials.append(mat)
  bpy.context.view_layer.objects.active=ob
  if family in ('Architecture','Landmarks','Roofs'):
   mod=ob.modifiers.new('Soft silhouette edges','BEVEL');mod.width=.055;mod.segments=1;mod.limit_method='ANGLE'
   bpy.ops.object.modifier_apply(modifier=mod.name);mesh=ob.data
  ob['V3AssetId']=name;ob['Family']=family;ob['Tier']=tier;ob['VisualOnly']=True;ob['Pivot']='bottom-center';ob['Build']=BUILD
  mesh.calc_loop_triangles()
  dims=list(ob.dimensions);rec={'id':name,'family':family,'tier':tier,'dimensionsBlenderXYZ':dims,'dimensionsRobloxXYZ':[dims[0],dims[2],dims[1]],'triangles':len(mesh.loop_triangles),'vertices':len(mesh.vertices),'materialSlots':1,'texture':'../painted_atlas.png','pivot':'bottom-center; Blender Z-up maps to Roblox Y-up','collision':'none; preserve existing course collision separately','notes':notes,'fbx':name+'.fbx'}
  assets.append((ob,rec));groups.setdefault(family,[]).append(ob);return ob

def shell(name,w,d,h,col,window='window_teal',terminal=False):
 g=Geo();g.box((0,0,h/2),(w,d,h),col)
 for z in (1,h-1):g.box((0,0,z),(w+.7,d+.7,.9),'cream')
 g.box((0,0,h-.35),(w+1.1,d+1.1,.7),'cream')
 g.box((0,-d/2-.13,1),(w,.25,2),'stone')
 for z in range(12,int(h),12):g.box((0,0,z),(w+.3,d+.3,.35),'cream')
 for z in range(7,int(h)-2,12):
  for x in range(-int(w)//2+4,int(w)//2,8):
   for sign in (-1,1):
    pane='arch_glass' if terminal else window
    if z==7 and sign==-1:pane='shop_glass' if abs(x)<5 else 'arch_glass'
    g.window(x,sign*(d/2+.045),z,5.8,10 if z==7 else 8,pane,0 if sign==-1 else math.pi)
    if z>7:g.box((x,sign*(d/2+.24),z-4.2),(6,.5,.3),'cream')
  for y in range(-int(d)//2+4,int(d)//2,8):
   for sign in (-1,1):g.window(sign*(w/2+.045),y,z,5.8,8,window,math.pi/2 if sign==1 else -math.pi/2)
 return g.finish(name,'Architecture','Mid','Closed opaque four-sided shell; facade art visible from falls. No route collision.')
for name,w,d,h,col,win in [('Ochre_Narrow',16,16,48,'ochre','window_brown'),('Coral_Wide',24,20,48,'coral','window_teal'),('Sage_Wide',24,20,60,'sage','window_plain'),('Cream_Tall',24,24,72,'cream','window_teal'),('Blue_Narrow',16,20,60,'sky','window_brown'),('Brick_Broad',32,24,48,'brick','window_plain')]:shell('V3_'+name,w,d,h,col,win)
shell('V3_Terminal_Wing',24,20,24,'cream','window_plain',True)
for name,w,d in [('Narrow',16,16),('Wide',24,20),('Broad',32,24)]:
 g=Geo();g.box((0,0,.5),(w+1,d+1,1),'slate')
 for y in (-d/2,d/2):g.box((0,y,1.5),(w+1,.7,2),'cream')
 for x in (-w/2,w/2):g.box((x,0,1.5),(.7,d+1,2),'cream')
 g.finish('V3_FlatRoof_'+name,'Roofs','Mid','Closed roof deck with parapet, no hollow roof opening.')
for name,w,d in [('Narrow',17,17),('Wide',25,21)]:
 g=Geo();g.gable(w,d,5);g.box((0,0,.25),(w+.6,d+.6,.5),'cream');g.beam((0,-d/2,5),(0,d/2,5),.4,'terracotta');g.finish('V3_GableRoof_'+name,'Roofs','Mid')
g=Geo();g.box((0,0,.5),(24,20,1),'slate');g.box((0,0,1.3),(18,15,1.6),'terracotta');g.box((0,0,2.6),(13,10,1),'terracotta');g.finish('V3_SteppedRoof','Roofs','Mid')
for name,tile in [('Market','sign_market'),('Depot','sign_depot'),('Terminal','sign_terminal'),('Courtyard','sign_courtyard')]:
 g=Geo();g.box((0,0,2),(12,.55,4),'wood');g.window(0,-.3,2,11.7,3.8,tile);g.finish('V3_Sign_'+name,'Street')
for w in (12,24):
 g=Geo();g.box((0,0,2.5),(w,8,.55),'stripes_teal' if w==12 else 'stripes_cream');g.box((0,-3.8,1.9),(w,.35,1.1),'teal' if w==12 else 'gold')
 for x in (-w/2+1,w/2-1):g.beam((x,3.7,0),(x,-3.7,2.2),.38,'wood');g.box((x,3.7,1.4),(.45,.45,2.8),'wood')
 g.finish('V3_Awning_'+str(w),'Street','Close','Visual skin only; fit below existing platform surface in Pass2.')
g=Geo();g.box((0,0,3),(8,5,6),'wood_plank');g.box((0,0,6.3),(8.7,5.5,.6),'cream');g.box((0,0,9),(9,6,.45),'stripes_cream')
for x in (-3.5,3.5):g.box((x,2,7.3),(.4,.4,4),'wood')
g.finish('V3_MarketStall','Street')
g=Geo();g.box((0,0,2),(4,4,4),'wood_plank');g.beam((-1.8,-2.04,.3),(1.8,-2.04,3.7),.3,'wood');g.finish('V3_Crate','Street')
g=Geo();g.box((0,0,2),(10,3,.6),'wood_plank');g.box((0,1.3,3.1),(10,.5,2),'wood')
for x in (-3.5,3.5):g.box((x,0,.9),(.6,2.6,1.8),'iron')
g.finish('V3_Bench','Street')
g=Geo();g.box((0,0,1.2),(8,3,2.4),'terracotta');g.box((0,0,2.2),(7.4,2.5,.4),'wood');g.blob((-2,0,3.2),(1.8,1.3,1.3),'leaf');g.blob((1.5,0,3.4),(2,1.3,1.6),'leaflight');g.finish('V3_Planter','Street')
g=Geo();g.cyl((0,0,0),.6,10,'wood',7,.35)
for p,r,h,tile in [((0,0,8),4,6,'leaf'),((-2,0,9),3,4,'leaflight'),((1.8,0,11),3.1,5,'leaf')]:g.blob((p[0],p[1],p[2]+h*.25),(r,r*.8,h*.6),tile)
g.finish('V3_Tree','Street','Close','Solid foliage volumes, no alpha cards or individual leaves.')
g=Geo();g.cyl((0,0,0),.5,.8,'iron',8);g.cyl((0,0,.8),.18,10,'iron',8);g.beam((0,0,10.6),(1.8,0,11.2),.22,'iron');g.box((1.8,0,10.4),(1.3,1.3,1.7),'gold');g.box((1.8,0,11.35),(1.7,1.7,.3),'iron');g.finish('V3_Lamp','Street','Close','Painted warm lamp; no real light emitter required.')
for name,w in [('Short',8),('Long',16)]:
 g=Geo();g.box((0,0,1.7),(w,3,.65),'cream');
 for x in (-w/2+1,w/2-1):g.beam((x,1.2,0),(x,-1.1,1.4),.55,'stone')
 g.finish('V3_Ledge_'+name,'Openings','Close','Bracketed scenery module. Never substitute for fixed gameplay collider.')
g=Geo();g.box((0,0,1.2),(12,5,.7),'cream')
for x in (-5,5):g.beam((x,2.2,0),(x,-2,1),.5,'stone')
for x in (-5.7,0,5.7):g.box((x,-2.2,2.6),(.18,.18,2.8),'iron')
g.box((0,-2.2,4),(12,.2,.2),'iron');g.finish('V3_Balcony','Openings')
g=Geo();g.box((0,0,6),(24,1,12),'cream');
for x in (-8,0,8):g.window(x,-.56,6,5.7,8,'window_teal')
g.finish('V3_FacadeStrip','Openings','Mid')
g=Geo();g.box((0,0,6),(24,1,12),'sage');g.window(0,-.56,6,23,11,'mural');g.finish('V3_MuralPanel','Openings')
g=Geo();g.box((0,0,6),(16,1,12),'ochre');g.window(0,-.56,5.5,13,10,'shop_glass');g.box((0,-1,11.3),(16,2,.7),'cream');g.finish('V3_Shopfront','Openings')
g=Geo();g.arch(16,20,3,2,'cream');g.box((0,0,20),(18,3.5,1.5),'cream');g.finish('V3_ArchPortal','Landmarks','Close','Clear opening 12 studs wide; visual opening, not collision authority.')
g=Geo();
for x in (-9,0,9):
 sub=Geo();sub.arch(9,12,3,1.2,'cream');g.add([(a+x,b,c)for a,b,c in sub.v],sub.f,'cream')
g.box((0,0,12.5),(28,4,1),'cream');g.finish('V3_Arcade','Landmarks')
g=Geo();g.box((0,0,20),(12,12,40),'cream')
for z in (1,13,27,39):g.box((0,0,z),(13,13,.85),'stone')
for sign in (-1,1):g.window(0,sign*6.05,18,5.5,12,'arch_glass',0 if sign==-1 else math.pi);g.window(0,sign*6.06,32,9,9,'clock',0 if sign==-1 else math.pi)
g.finish('V3_ClockTower','Landmarks','Close','Tower body with opaque faces; add closed roof module separately.')
g=Geo();g.box((0,0,.5),(24,12,1),'slate');g.box((0,0,11),(26,14,.7),'metal_panel')
for x in (-10,10):
 for y in (-4,4):g.box((x,y,5.5),(.6,.6,11),'cream');g.beam((x,y,8),(x*.6,y,10.5),.35,'wood')
g.finish('V3_DepotCanopy','Industrial')
g=Geo();
for x in (-5,5):
 for y in (-5,5):g.box((x,y,6),(.3,.3,12),'gold')
for z in (1,6,11):
 for y in (-5,5):g.box((0,y,z),(10,.3,.3),'gold')
 for x in (-5,5):g.box((x,0,z),(.3,10,.3),'gold')
for y in (-5,5):g.beam((-5,y,1),(5,y,11),.25,'gold')
g.finish('V3_ScaffoldBay','Industrial')
g=Geo();
for y in (-2,2):
 for z in (0,4):g.beam((-12,y,z),(12,y,z),.3,'gold')
 for i in range(6):g.beam((-12+4*i,y,0),(-8+4*i,y,4),.24,'gold');g.beam((-12+4*i,y,4),(-8+4*i,y,0),.24,'gold')
g.finish('V3_CraneTruss','Industrial','Mid')
g=Geo();g.box((0,0,1),(16,.35,2),'iron');g.box((0,0,.15),(16,2,.3),'iron');g.box((0,0,1.85),(16,2,.3),'iron');g.finish('V3_IBeam','Industrial')
g=Geo();
for x in (-12,12):g.box((x,0,8),(.6,.6,16),'iron')
g.box((0,0,15),(25,1,1.5),'iron');g.box((0,-.7,13.5),(10,.6,3),'slate');g.window(0,-1.02,13.5,9.8,2.8,'sign_depot');g.finish('V3_SignalGantry','Industrial')
g=Geo();
for x in (-3,3):
 for y in (-3,3):g.box((x,y,3),(.4,.4,6),'iron')
g.cyl((0,0,5),4,7,'wood_plank',12);g.cyl((0,0,12),4.2,1,'slate',12,3.4)
for z in (6,10.5):g.cyl((0,0,z),4.05,.25,'iron',12)
g.finish('V3_WaterTank','Industrial')
g=Geo();g.box((0,0,3),(4,4,6),'brick');g.box((0,0,6),(4.8,4.8,.6),'stone');g.finish('V3_Chimney','Roofs')
g=Geo();
for x in (-6,-2,2,6):g.box((x,0,2),(.15,.2,4),'iron')
for z in (.5,3.8):g.box((0,0,z),(12,.2,.18),'iron')
g.finish('V3_Fence','Industrial')
g=Geo();g.box((0,0,.35),(10,24,.7),'stone')
for y in range(-11,12,3):g.box((0,y,.8),(8,1,.5),'wood')
for x in (-2.7,2.7):g.box((x,0,1.1),(.32,24,.32),'iron')
g.finish('V3_RailBed','Industrial','Mid','Decorative rail segment; train path and contact envelope unchanged.')
g=Geo();
# Lathed closed ball with shared pole vertices avoids degenerate cap triangles.
n=16;vs=[(0,0,0)]
for j in range(1,8):
 a=math.pi*j/8
 for i in range(n):vs.append((5*math.sin(a)*math.cos(i*math.tau/n),5*math.sin(a)*math.sin(i*math.tau/n),5-5*math.cos(a)))
vs.append((0,0,10));top=len(vs)-1;fs=[(0,1+(i+1)%n,1+i)for i in range(n)]
for j in range(6):
 for i in range(n):fs.append((1+j*n+i,1+j*n+(i+1)%n,1+(j+1)*n+(i+1)%n,1+(j+1)*n+i))
fs.extend((top,1+6*n+i,1+6*n+(i+1)%n)for i in range(n));g.add(vs,fs,'iron');g.beam((-.65,0,9.8),(-.65,0,11.8),.45,'iron');g.beam((.65,0,9.8),(.65,0,11.8),.45,'iron');g.beam((-.65,0,11.8),(.65,0,11.8),.45,'iron');g.finish('V3_WreckingBallSkin','Vehicles','Close','Visual shell only. Runtime hitbox/cable/pivot retained in Pass2.')
for name,col,l,w,h in [('MarketCar','coral',12,6,5),('DeliveryVan','teal',14,6,7),('TrainCar','slate',26,8,9)]:
 g=Geo();g.box((0,0,h*.4),(w,l,h*.6),col);g.add([(-w*.43,-l*.31,h*.6),(w*.43,-l*.31,h*.6),(w*.43,l*.31,h*.6),(-w*.43,l*.31,h*.6),(-w*.38,-l*.22,h),(w*.38,-l*.22,h),(w*.38,l*.22,h),(-w*.38,l*.22,h)],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],col)
 for y in (-l*.34,l*.34):
  for x in (-w*.47,w*.47):g.box((x,y,1),(1.1,2.3,2),'ink')
 for y in (-l*.311,l*.311):g.add([(-w*.34,y,h*.62),(w*.34,y,h*.62),(w*.34,y*.71,h*.97),(-w*.34,y*.71,h*.97)],[(0,1,2,3) if y<0 else (3,2,1,0)],'shop_glass')
 for y in range(-int(l*.25),int(l*.25)+1,4):
  for x in (-w*.441,w*.441):g.window(x*.92,y,h*.8,3,h*.3,'window_plain',math.pi/2 if x>0 else -math.pi/2)
 g.box((0,-l/2-.02,h*.4),(w*.9,.2,.45),'cream')
 for x in (-w*.3,w*.3):g.box((x,-l/2-.15,h*.48),(w*.16,.25,.7),'gold')
 if name=='TrainCar':g.box((0,l/2+1,h*.45),(w*.6,2,h*.6),'ink');g.box((0,-l/2-.8,1),(2,1.6,.6),'iron')
 g.box((0,-l/2-.1,h*.26),(w*.55,.22,.6),'iron');g.finish('V3_'+name,'Vehicles','Close','Visual skin only; moving actors remain runtime-owned.')
for i,(w,d,h) in enumerate([(20,16,44),(28,18,60),(16,16,72),(36,20,52)]):
 g=Geo();g.box((0,0,h/2),(w,d,h),'sky' if i%2 else 'sage');g.box((0,0,h+.5),(w+1,d+1,1),'slate');g.box((0,0,h+2),(w*.6,d*.6,3),'stone')
 if i==0:g.box((-w*.2,0,h+5),(w*.45,d*.6,6),'stone')
 elif i==1:g.cyl((0,0,h+3),4,7,'slate',8)
 elif i==2:g.box((0,0,h+6),(w*.6,d*.7,8),'sky');g.box((0,0,h+11),(w*.32,d*.4,3),'cream')
 else:
  for x in (-w*.3,w*.3):g.box((x,0,h+5),(w*.22,d*.6,6),'sage')
 for z in range(9,h-3,12):
  for x in range(-w//2+4,w//2,8):g.window(x,-d/2-.05,z,3,5,'window_plain')
 g.finish('V3_Skyline_'+str(i+1),'Skyline','Distant','Rear and sides opaque; detailed face must point toward route.')


# Alternative facade grammars and district anchors share the same texture/material.
for name,col,w in [('LoggiaResidence','cream',30),('CourtyardGallery','ochre',24)]:
 g=Geo();g.box((0,0,24),(w,20,48),col)
 for z in (1,24,47):g.box((0,0,z),(w+1,21,.8),'cream')
 for x in (-w/2+.5,0,w/2-.5):g.box((x,-10.2,24),(.65,.5,48),'cream')
 for z in (8,20,32,43):
  for x in (-w/3,0,w/3):g.window(x,-10.05,z,7,9,'arch_glass' if name=='LoggiaResidence' else 'window_brown');g.box((x,-10.4,z-4.6),(7.4,.8,.4),'cream')
  for sign in (-1,1):
   for y in (-5,5):g.window(sign*(w/2+.05),y,z,6,8,'window_plain',math.pi/2 if sign==1 else -math.pi/2)
  for x in (-w/3,0,w/3):g.window(x,10.05,z,6,8,'window_plain',math.pi)
 g.finish('V3_'+name,'Architecture','Mid','Alternative vertical-pier facade grammar.')
g=Geo();g.box((0,0,5),(24,20,10),'brick');g.box((0,0,10),(25,21,1),'cream')
for x in (-8,0,8):g.window(x,-10.08,5,6,8,'shop_glass')
g.finish('V3_ShopBase','Openings','Close','Independent grounded shop level.')
g=Geo();g.arch(18,13,3,1.5,'sage');g.box((0,0,13),(20,4,.7),'cream');g.window(0,-1.56,11.2,8,2.1,'sign_courtyard');g.finish('V3_GardenPortal','Landmarks')
g=Geo();g.cyl((0,0,0),5,.65,'stone',12);g.cyl((0,0,.65),4.5,1.1,'cream',12);g.cyl((0,0,1.8),1.2,3,'stone',10);g.cyl((0,0,4.8),2.4,.6,'cream',12);g.finish('V3_CourtyardFountain','Street','Close','Dry sculptural fountain; no transparent water or particles.')
g=Geo()
for x in (-10,-3.3,3.3,10):g.box((x,0,6),(1.2,1.5,12),'cream');g.box((x,0,.45),(1.8,2,.9),'stone');g.box((x,0,11.6),(1.8,2,.8),'stone')
g.box((0,0,12.5),(24,3,1.5),'cream');g.finish('V3_TerminalColonnade','Landmarks')
g=Geo();w=25;d=21
vs=[(-w/2,-d/2,0),(w/2,-d/2,0),(w/2,d/2,0),(-w/2,d/2,0),(-8,-6,5),(8,-6,5),(8,6,5),(-8,6,5)]
g.add(vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'slate');g.finish('V3_MansardRoof','Roofs','Mid')
g=Geo();profile=[(-12,0),(12,0)]+[(12*math.cos(i*math.pi/10),4*math.sin(i*math.pi/10))for i in range(11)]
# Deduplicate the right base corner before extruding the shallow barrel.
profile=[(-12,0)]+[(12*math.cos(i*math.pi/10),4*math.sin(i*math.pi/10))for i in range(11)]
profile=profile[:-1];n=len(profile);vs=[(x,y,z)for y in (-10,10)for x,z in profile]
g.add(vs,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n)for i in range(n)],'metal_panel');g.finish('V3_BarrelRoof','Roofs','Mid')

# Sparse service faces and stepped shop silhouettes break the repeating residential grid.
g=Geo(); outline=[(-12,-10),(6,-10),(12,-4),(12,10),(-12,10)];n=len(outline)
g.add([(x,y,z) for z in (0,36) for x,y in outline],[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'ochre')
for z in (1,13,35):
 for i in range(n):a=outline[i];b=outline[(i+1)%n];g.beam((a[0],a[1],z),(b[0],b[1],z),.65,'cream')
for z in (7,21,30):
 for x in (-7,1):g.window(x,-10.05,z,5,8,'shop_glass' if z==7 else 'window_brown')
 for y in (1,7):g.window(12.05,y,z,4.5,8,'window_plain',math.pi/2)
 g.window(9.05,-7.05,z,6,8,'arch_glass',math.pi/4)
g.box((-2,-12,10.5),(19,4,.6),'stripes_cream');g.box((-2,-14,10),(19,.3,1),'gold')
g.window(-2,-10.08,16,14,3,'sign_market');g.finish('V3_CornerCafe','Architecture','Close','Chamfered corner, diagonal entrance and sparse upper shop floors. Closed shell.')

g=Geo();g.box((0,0,24),(24,2,48),'sage')
for x,z,w,h in [(-7,8,8,12),(5,32,9,15),(-5,43,12,7)]:g.box((x,-1.02,z),(w,.025,h),'stone' if z==32 else 'ochre')
for x,z in [(-7,24),(6,42),(-7,40)]:g.window(x,-1.06,z,4,5,'window_brown')
g.window(5,-1.06,5,6,9,'wood_plank')
for x,z in [(-7,11),(6,24)]:
 g.box((x,-1.6,z),(5,1.2,3),'slate')
 for j in range(3):g.box((x,-2.23,z-.8+j*.8),(4,.12,.18),'iron')
g.beam((10,-1.4,0),(10,-1.4,45),.3,'iron');g.beam((10,-1.4,45),(6,-1.4,45),.3,'iron');g.finish('V3_ServiceRear','Openings','Mid','Sparse rear-wall panel with broad paint repairs, two vents and a drainpipe.')

g=Geo()
for x,h,col,tile in [(-10,11,'coral','stripes_cream'),(0,15,'sage','stripes_teal'),(10,12.5,'ochre','stripes_cream')]:
 g.box((x,0,h/2),(10,8,h),col);g.box((x,0,h),(10.2,8.2,.7),'slate');g.window(x,-4.05,4.8,8,8,'shop_glass')
 g.box((x,-5.5,9.3),(9.7,3,.45),tile);g.box((x,-7,8.8),(9.7,.2,.8),'cream');g.window(x,-4.06,h-1.5,7,1.8,'sign_market')
 for xx in (x-4.5,x+4.5):g.box((xx,-4.1,4.5),(.3,.3,9),'cream')
g.finish('V3_UnevenShopRow','Street','Close','Three compact shop bays with stepped roofline, built-in awnings and opaque glazing.')

g=Geo()
for x,y,w,d,h,col in [(-12,3,15,15,41,'sky'),(1,0,12,16,62,'sage'),(11,4,13,14,49,'stone')]:
 g.box((x,y,h/2),(w,d,h),col);g.box((x,y,h+.5),(w+.7,d+.7,1),'slate')
 for z in range(9,h-4,14):g.window(x,y-d/2-.05,z,w*.65,5,'window_plain')
g.box((2,0,65),(7,10,6),'sage');g.finish('V3_SkylineCluster','Skyline','Distant','Asymmetric depth-stepped distant cluster; opaque backing, no tiny trim.')


# Broad workshop glazing contrasts with the repeated residential window grid.
g=Geo();g.box((0,0,24),(28,22,48),'brick')
g.box((0,0,.75),(29,23,1.5),'stone')
for x in (-9,0,9):
 g.window(x,-11.07,22,7,29,'arch_glass')
 g.box((x,-11.4,7.1),(7.5,.8,.5),'cream')
 g.window(x,11.07,23,6,23,'shop_glass',math.pi)
for x in (-13.3,-4.5,4.5,13.3):
 g.box((x,-11.22,24),(.65,.5,46),'stone')
for sign in (-1,1):
 for y in (-5.5,5.5):
  g.window(sign*14.07,y,23,8,24,'shop_glass',math.pi/2 if sign==1 else -math.pi/2)
for z in (4,40,47):
 g.box((0,0,z),(28.8,22.8,.65),'stone')
g.window(0,-11.08,43.5,15,3,'sign_depot')
g.box((0,0,48.2),(29,23,.8),'slate')
g.box((-6,0,51),(13,17,5),'brick')
g.box((-6,0,53.5),(14,18,.7),'slate')
g.window(-6,-8.55,51,10,3.3,'shop_glass')
g.box((5,1,49.7),(7,14,2.3),'slate')
g.finish('V3_AtelierHall','Architecture','Mid','Three oversized workshop bays and stepped roof monitor; integrated roof, no residential grid.')

# Export every unique mesh once; catalog placements are kept out of local asset pivots.
for ob,rec in assets:
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 bpy.ops.export_scene.fbx(filepath=str(EXPORT/rec['fbx']),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True,mesh_smooth_type='FACE',use_triangles=True,path_mode='COPY',embed_textures=True,add_leaf_bones=False,bake_anim=False)
 rec['fbxBytes']=(EXPORT/rec['fbx']).stat().st_size;rec['sha256']=hashlib.sha256((EXPORT/rec['fbx']).read_bytes()).hexdigest()
manifest={'build':BUILD,'scope':'Pass1 visual asset kit only; no course assembly or gameplay edits','blenderVersion':bpy.app.version_string,'units':'1 Blender unit = 1 intended Roblox stud; verify importer scale before use','atlas':{'path':'painted_atlas.png','dimensions':[2048,1024],'opaque':True,'estimatedRGBA8FullMipBytes':11184811,'note':'Uncompressed estimate, not measured Roblox texture memory'},'assets':[r for o,r in assets]}
manifest['totals']={'uniqueAssets':len(assets),'triangles':sum(r['triangles'] for o,r in assets),'maxAssetTriangles':max(r['triangles'] for o,r in assets),'materials':1,'textures':1}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2))
for index,(ob,r) in enumerate(assets):ob.location=((index%9)*44,(index//9)*90,0)
world=scene.world or bpy.data.worlds.new('World');scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.76,.81,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5
sun=bpy.data.lights.new('Sun','SUN');sun.energy=2.4;sun.color=(1.0,.86,.71);sun.angle=.14;so=bpy.data.objects.new('Sun',sun);scene.collection.objects.link(so);so.rotation_euler=(.4,-.5,-.5)
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
camdata=bpy.data.cameras.new('CatalogCamera');cam=bpy.data.objects.new('CatalogCamera',camdata);scene.collection.objects.link(cam);scene.camera=cam;camdata.type='ORTHO'
def camera(pos,target,scale):cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();camdata.ortho_scale=scale
camera((330,-420,360),(175,190,25),490)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CityRun_V3_AssetKit.blend'))
print('V3_MANIFEST',json.dumps(manifest['totals']))
