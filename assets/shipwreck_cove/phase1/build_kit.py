"""Author the low-poly library and three independent fit studies, not a course."""
import bpy, bmesh, json, math, struct, zlib, hashlib, sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
BUILD = 'SC_KIT_04'
STUDY_BUILD = 'SC_P1_07'
budgets = json.loads((ROOT/'budgets.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)
PALETTE = [(164,105,59),(210,155,92),(107,65,37),(196,148,83),
           (235,211,163),(160,142,109),(55,72,76),(240,226,192),
           (161,72,62),(49,53,55),(82,86,83),(40,154,165),
           (49,180,150),(221,245,233),(76,113,57),(112,142,68),
           (217,67,41),(239,178,65),(53,79,76),(177,155,114)]
W, WL, WD, EDGE, ROCK, RD, SHADOW, SAND, SAIL, IRON, IL, SEA, WATER, FOAM, LEAF, LL, RED, AMBER, INK, ROPE = range(20)

def png(path):
    n=128; raw=bytearray()
    for y in range(n):
        raw.append(0)
        for x in range(n):
            i=(y//16)*8+x//16; raw.extend((*PALETTE[i%len(PALETTE)],255))
    def chunk(k,v): return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
png(ROOT/'palette.png')
mat=bpy.data.materials.new('SC_SharedOpaquePalette');mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.88
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'palette.png'));tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
geo={};records=[];objects={}

class Geo:
    def __init__(self): self.v=[];self.f=[];self.c=[]
    def mesh(self,v,f,c):
        n=len(self.v);self.v.extend(v);self.f.extend([tuple(n+i for i in face)for face in f]);self.c.extend(c if isinstance(c,list) else [c]*len(f))
    def box(self,center,size,c):
        x,y,z=center;a,b,h=[q/2 for q in size]
        self.mesh([(x+i*a,y+j*b,z+k*h)for k in [-1,1]for j in [-1,1]for i in [-1,1]],[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],c)
    def beam(self,a,b,width,depth,c):
        a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,1,0)))
        if u.length<.01:u=d.cross(Vector((1,0,0)))
        u.normalize();v=d.cross(u).normalized()
        vs=[tuple(p+u*i*width/2+v*j*depth/2)for p in [a,b]for j in [-1,1]for i in [-1,1]]
        self.mesh(vs,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],c)
    def rings(self,rings,n,c,axis='z',center=(0,0,0),cap=True):
        vs=[]
        for t,r in rings:
            for i in range(n):
                q=2*math.pi*i/n
                p=(r*math.cos(q),r*math.sin(q),t)
                if axis=='x':p=(t,p[0],p[1])
                if axis=='y':p=(p[0],t,p[1])
                vs.append(tuple(p[j]+center[j]for j in range(3)))
        fs=[(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i)for k in range(len(rings)-1)for i in range(n)]
        if cap:fs+=[tuple(reversed(range(n))),tuple((len(rings)-1)*n+i for i in range(n))]
        self.mesh(vs,fs,c)
    def prism(self,poly,depth,c,axis='y'):
        vs=[(x,t,z)if axis=='y'else(x,z,t)for t in [-depth/2,depth/2]for x,z in poly];n=len(poly)
        fs=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]+[(i,(i+1)%n,(i+1)%n+n,i+n)for i in range(n)]
        self.mesh(vs,fs,c)

def asset(name,g,family,reuse,notes,colliders=None):
    name='SC_'+name;mesh=bpy.data.meshes.new(name);mesh.from_pydata(g.v,[],g.f);mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for face,c in zip(mesh.polygons,g.c):
        for k,j in enumerate(face.loop_indices):
            angle=2*math.pi*k/len(face.loop_indices)
            uv.data[j].uv=(((c%8)*16+8+2*math.cos(angle))/128,1-((c//8)*16+8+2*math.sin(angle))/128)
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);ob.data.materials.append(mat)
    ob['Build']=BUILD;ob['Family']=family;ob['VisualOnly']=True
    mesh.calc_loop_triangles();tris=len(mesh.loop_triangles);assert tris<=budgets['perAssetTriangles'][family],(name,tris)
    lo=[min(v.co[i]for v in mesh.vertices)for i in range(3)];hi=[max(v.co[i]for v in mesh.vertices)for i in range(3)]
    rec=dict(id=name,family=family,triangles=tris,triangleCeiling=budgets['perAssetTriangles'][family],estimatedPlacements=reuse,dimensionsRobloxXYZ=[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]],centerBlender=[(lo[i]+hi[i])/2 for i in range(3)],notes=notes,colliders=colliders or [])
    records.append(rec);objects[name]=ob;geo[name]=g;return ob

def slab(name,w,d,h,family='dock',reuse=12):
    g=Geo();g.box((0,0,h/2),(w,d,h),W)
    # Broad alternating color panels are coplanar divisions, not tiny modeled grain.
    for x in [-w/3,0,w/3]:g.box((x,0,h+.015),(w/3-.06,d,.03),WL if x==0 else W)
    asset(name,g,family,reuse,'Local bottom at zero; deck faces align by their top height. No scaling across width.',[dict(center=[0,h/2,0],size=[w,h,d])])
slab('DockDeck',12,10,1.2)
slab('DockRefuge',18,16,1.2,reuse=6)
slab('ShipDeck',12,16,1.2,'deck',14)
g=Geo();g.box((0,0,5),(1.5,1.5,10),WD);asset('DockPost',g,'post',40,'Ground bottom; support deck underside. Vertical scaling 0.5-2 allowed.')
g=Geo();g.box((0,0,.8),(12,1.6,1.6),WD);asset('TimberBeam',g,'spar',24,'Beam centerline X; simple box collider only if a deliberate playable spar.')
g=Geo();g.prism([(-6,0),(6,5.3),(6,6.3),(-6,1)],8,W);asset('BoardingRamp',g,'deck',4,'Rise5.3 over12 run. Lower walking face atZ1, upper atZ6.3; mount bottom one stud below lower landing.')
g=Geo();g.box((0,0,2),(4,4,4),W)
for x in [-1.7,1.7]:g.box((x,-2.06,2),(.55,.14,4),EDGE)
for z in [.28,3.72]:g.box((0,-2.06,z),(4,.14,.55),EDGE)
g.beam((-1.45,-2.16,.6),(1.45,-2.16,3.4),.4,.16,EDGE);asset('CargoCrate',g,'crate',10,'Four-stud cargo jump or cover dressing; collision owned by simple box.')
g=Geo();g.rings([(0,1.3),(.6,1.6),(3.8,1.6),(4.4,1.3)],8,W)
for z in [.7,3.5]:g.rings([(z,1.63),(z+.2,1.63)],8,WD,cap=False)
asset('CargoBarrel',g,'barrel',8,'Eight-sided silhouette; no individual staves or metal rivets.')
g=Geo();g.box((0,0,3.5),(8,2,7),WD);g.box((0,0,7.05),(8.3,2.3,.3),EDGE)
g.box((-3.3,-2,1),(1.4,3,2),W)
asset('CannonCover',g,'cover',4,'Seven-stud solid cover with low return on waiting side; entire avatar pocket must be outside shot/impact bounds.')
g=Geo()
for x in [-10,10]:g.box((x,0,8),(2.4,2.4,16),WD)
g.box((0,0,15),(22.5,2,2),W);g.box((0,-1.12,14.8),(12,.18,1.6),SAIL)
asset('HarborGate',g,'gate',1,'17.6-stud opening, underside14. Place shared visual R0 gate after forward merge; keep functional triggers separate.')

# A thick shell follows only four large cross-section bands.
profile=[(0,0),(6,3),(10,9),(12,18)]
g=Geo()
for i,(a,b) in enumerate(zip(profile,profile[1:])):
    g.prism([a,b,(b[0]+.9,b[1]),(a[0]+.9,a[1])],16,W if i%2 else WD)
g.v=[(x,y,z-3 if z>=17 and y<0 else z) for x,y,z in g.v]
asset('HullSide',g,'hull',12,'One 16-stud half-shell bay with a sloping broken upper rail. Rotate paired placements; retain open keel/ends for joins.')
g=Geo()
for side in [-1,1]:
    for i in range(3):
        x0,z0=profile[i];x1,z1=profile[i+1]
        g.mesh([(side*x0,0,z0),(side*x1,0,z1),(side*1.1,-20,z1+3),(side*.3,-20,z0+3),
                (side*(x0+.8),0,z0),(side*(x1+.8),0,z1),(side*1.9,-20,z1+3),(side*1.1,-20,z0+3)],
               [(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(1,5,6,2),(0,3,7,4)],W if i%2 else WD)
g.beam((0,-19,3),(0,-22,25),2,1.6,WD)
asset('HullBow',g,'hull',1,'Tapered bow closes the shell end; no tiny splinters. Module join at local Y0.')
g=Geo();g.prism([(-12,18),(-10,9),(-6,3),(0,0),(6,3),(10,9),(12,18)],1.2,W)
g.box((0,-.7,16),(24,.6,1.2),WD);asset('SternTransom',g,'hull',1,'Transom closes paired half-shells; use with high stern deck, not a second complete bow.')
g=Geo()
for a,b in zip(profile,profile[1:]):g.beam((a[0],0,a[1]),(b[0],0,b[1]),2.2,2.2,WD)
g.box((12,0,18.3),(3.2,3.6,.6),WL)
asset('PlayableRib',g,'rib',9,'Chunky rib reaches keel; authored top3.2x3.6. Add simple cap collider; avoid changing its width to fake difficulty.')
g=Geo();g.box((-4.25,0,.6),(3.5,16,1.2),W);g.box((4.25,0,.6),(3.5,16,1.2),WL)
asset('BrokenDeck',g,'deck',6,'Five-stud real center gap. Separate box colliders per surviving strip; never fill hole with bounding collider.')
g=Geo();g.box((0,0,.9),(16,2.8,1.8),WD);g.box((0,0,1.84),(12,2.2,.08),WL)
asset('BrokenSpar',g,'spar',8,'16-stud supported spar; keep2.8-stud width, use separated placements for real jumps.')
g=Geo();g.beam((0,0,0),(1,0,31),1.5,1.5,WD);g.beam((-11,0,25),(13,0,27),1.1,1.1,W)
asset('MastYard',g,'mast',2,'One mast and yard, no rope strand meshes; base socket on deck.')
g=Geo();g.prism([(-11,16),(12,18),(10,4),(7,6),(6,2),(2,5),(0,0),(-2,5),(-5,3),(-7,7),(-11,5)],.12,SAIL)
asset('TornSail',g,'sail',2,'Three broad silhouette tears; thickness0.12. Separate from mast for practical fitting; no cloth simulation.')

def rock(name,w,d,h,seed,family='cliff',reuse=12):
    g=Geo();n=6;vs=[]
    for ring,z in enumerate([0,h*.72,h]):
        for i in range(n):
            a=2*math.pi*i/n;f=1 if ring<2 else .72
            vs.append((math.cos(a)*w*.5*f,math.sin(a)*d*.5*f,z+(math.sin(i*2+seed)*h*.1 if ring==1 else 0)))
    fs=[tuple(reversed(range(n))),tuple(12+i for i in range(n))]
    fs +=[(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i)for k in range(2)for i in range(n)]
    g.mesh(vs,fs,[RD,ROCK]+[ROCK if i%3 else RD for i in range(12)])
    asset(name,g,family,reuse,'Large flat facets. Uniform scaling0.75-1.5; overlap foundations under ground, retain clear playable shelf colliders.')
rock('CliffMass',28,23,32,1,reuse=20)
rock('CliffShoulder',22,20,15,2,reuse=16)
rock('GroundingRock',12,10,7,3,reuse=16)
rock('RockLedge',12,10,3,4,reuse=20)
rock('RefugeShelf',18,16,5,5,reuse=4)
g=Geo();g.prism([(-16,0),(-16,20),(-10,25),(10,25),(16,20),(16,0),(10,0),(10,14),(6,19),(-6,19),(-10,14),(-10,0)],8,ROCK)
asset('CavePortal',g,'cave',2,'20-stud opening and19-stud center roof clearance. Use three simple boundary colliders; do not cap opening.')
g=Geo();g.prism([(-18,0),(-18,5),(-10,8),(8,8),(18,4),(18,0),(10,2),(3,.5),(-5,2.5),(-12,1)],20,ROCK)
for i in range(7,len(g.c)):g.c[i]=IRON if i%2 else SHADOW
asset('CaveRoof',g,'cliff',6,'Roof underside at local Z0; maintain minimum12-stud clear height over standing surface.')
g=Geo();g.prism([(-9,0),(-9,16),(-5,22),(7,20),(9,14),(9,0)],12,SHADOW)
asset('CaveWall',g,'cliff',10,'Broad supporting cave wall, muted shaded stone; do not obstruct refuge/daylight sightline.')
g=Geo();g.box((0,0,.5),(16,12,1),ROCK);asset('SurgeCrossing',g,'cliff',1,'Flat low crossing for H02, flood cue visually distinct from ordinary water. Simple box collider.')
g=Geo();g.box((0,0,.15),(12,22,.3),WATER);asset('LocalSurge',g,'water',1,'One local solid-color water slab, moved/raised by fixture; no full-ocean simulation or permanent transparency.')
g=Geo();g.prism([(-6,0),(-4,.65),(-1,.3),(2,.8),(4,.25),(6,.5),(6,2),(-6,2)],.12,FOAM,axis='z')
asset('FoamRibbon',g,'foam',6,'One broad opaque foam silhouette, use only near local surge/impact. No particle field.')
g=Geo();g.box((0,0,.1),(100,100,.2),SEA);asset('CoveWater',g,'water',4,'Flat opaque surface; instances only where visible, no overlapping transparent ocean layers.')

g=Geo();g.rings([(-4.8,1.15),(-4.3,1.45),(-3.65,1.45),(-3.6,1.15),(2.4,.85),(3.4,.65)],8,IRON,'x',(0,0,3.1),False)
# Recessed muzzle has an inward ring and dark back, so it reads as hollow at low cost.
g.rings([(-4.8,.78),(-3.7,.78)],8,WD,'x',(0,0,3.1),False)
g.rings([(-4.8,1.15),(-4.8,.78)],8,IL,'x',(0,0,3.1),False)
g.rings([(-3.7,.78),(-3.69,0)],8,INK,'x',(0,0,3.1),False)
g.box((.2,0,1.1),(5,2.8,1.2),W)
for y in [-1.25,1.25]:
    start=len(g.v);g.prism([(-2,.4),(-1,3),(1.7,3),(2.5,.4)],.55,W)
    g.v[start:]=[(x,py+y,z)for x,py,z in g.v[start:]]
for x in [-1.6,1.6]:
    for y in [-1.7,1.7]:g.rings([(-.28,.72),(.28,.72)],6,WD,'y',(x,y,.8))
asset('Cannon',g,'cannon',2,'Eight-sided low barrel; muzzle points local-X. Local shot centerZ3.1. Base aligns with deck, body is not a route collider.')
g=Geo();g.rings([(-.8,0),(-.5,.65),(0,.8),(.5,.65),(.8,0)],8,IRON);asset('Cannonball',g,'cannon',2,'Diameter1.6. Whole sphere must clear cover and water impact; shot height3.1 above deck requires real jump test.')
g=Geo();g.box((0,0,.08),(8,1,.16),RED);asset('DangerStripe',g,'cue',8,'Red marks real hazard footprint; never use it for safe route arrows.')
g=Geo();g.box((0,0,.12),(1.1,1.1,.24),AMBER);asset('MuzzleCue',g,'cue',2,'Small local warning cue. One controller, no new PointLight; final audio scope separate.')
g=Geo()
for a,b,r in [((0,0,0),(.8,0,8),1.4),((.8,0,8),(2,0,15),1.1),((2,0,15),(3,0,20),.8)]:g.beam(a,b,r,r,W)
for i in range(5):
    q=i*2*math.pi/5;u=Vector((math.cos(q),math.sin(q),0));v=Vector((-u.y,u.x,0));base=Vector((3,0,20));
    vs=[base,base+u*4+v*2+Vector((0,0,1)),base+u*9+Vector((0,0,-2)),base+u*4-v*2+Vector((0,0,1)),base+u*4+Vector((0,0,2))]
    g.mesh([tuple(x)for x in vs],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,3,2,1)],[LEAF,LL,LEAF,LL,LEAF])
asset('Palm',g,'palm',12,'Five broad leaves, three trunk segments. Soil/rock socket required; canopy away from takeoffs.')

assert len(records)<=budgets['uniqueVisualMeshCeiling']
colliders={
 'SC_CargoCrate':[dict(center=[0,2,0],size=[4,4,4])],
 'SC_CannonCover':[dict(center=[0,3.5,0],size=[8,7,2]),dict(center=[-3.3,1,2],size=[1.4,2,3])],
 'SC_PlayableRib':[dict(center=[12,18.3,0],size=[3.2,.6,3.6])],
 'SC_BrokenSpar':[dict(center=[0,.94,0],size=[16,1.88,2.8])],
 'SC_BrokenDeck':[dict(center=[x,.6,0],size=[3.5,1.2,16])for x in [-4.25,4.25]],
 'SC_BoardingRamp':[dict(center=[0,3.15,0],size=[13.12,1,8],rollDegrees=23.83)],
 'SC_RefugeShelf':[dict(center=[0,4.5,0],size=[12.8,1,9.8])],
 'SC_RockLedge':[dict(center=[0,2.5,0],size=[8.5,1,6.1])],
 'SC_SurgeCrossing':[dict(center=[0,.5,0],size=[16,1,12])],
 'SC_CaveWall':[dict(center=[0,7,0],size=[16,14,12])],
 'SC_CaveRoof':[dict(center=[0,1,0],size=[36,2,20])],
 'SC_CavePortal':[dict(center=[x,10,0],size=[6,20,8])for x in [-13,13]]+[dict(center=[0,22,0],size=[26,6,8])],
 'SC_HarborGate':[dict(center=[x,8,0],size=[2.4,16,2.4])for x in [-10,10]]+[dict(center=[0,15,0],size=[22.5,2,2])]
}
for record in records:
    if record['id'] in colliders:record['colliders']=colliders[record['id']]
for i,r in enumerate(records):objects[r['id']].location=((i%8)*60,(i//8)*60,0)
bpy.context.view_layer.update()
for ob in objects.values():ob.select_set(True)
if '--studies-only' not in sys.argv:
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_Kit04.blend'))
    bpy.ops.export_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit04.fbx'),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,use_mesh_modifiers=True,bake_anim=False)
manifest=dict(build=BUILD,units='1 Blender unit = 1 intended Roblox stud; normalize by manifest after import',assets=records,uniqueMeshes=len(records),libraryTriangles=sum(r['triangles']for r in records),estimatedPlacedTriangles=sum(r['triangles']*r['estimatedPlacements']for r in records),atlas='palette.png',materialCount=1)
assert manifest['estimatedPlacedTriangles']<=budgets['placedSceneryTargetTriangles']
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2))

# Study placements use Blender Z up. They intentionally have no lap route or checkpoint integration.
for ob in list(bpy.context.scene.objects):bpy.context.scene.collection.objects.unlink(ob)
studies=[]
def place(asset,pos,yaw=0,group='dock_wreck',scale=(1,1,1),visual_only=False):
    asset='SC_'+asset;src=objects[asset];ob=bpy.data.objects.new(asset+'_'+str(len(studies)),src.data);bpy.context.collection.objects.link(ob);ob.location=pos;ob.rotation_euler.z=math.radians(yaw);ob.scale=scale
    studies.append(dict(asset=asset,pos=pos,yaw=yaw,scale=scale,group=group,visualOnly=visual_only));return ob
place('CoveWater',(0,24,0),scale=(1.2,1.5,1))
for y in [-20,-8,4,16,28,40]:
    place('DockRefuge' if y in [-20,16,28,40] else 'DockDeck',(-22,y,3))
    for x in [-27,-17]:place('DockPost',(x,y,-6.8))
place('HarborGate',(-22,-24,4.23));place('CargoCrate',(-27,-18,4.23));place('CargoBarrel',(-16,18,4.23))
place('CannonCover',(-26,-6,4.23),90);place('Cannon',(-8,4,4.23));place('DockRefuge',(-6,4,3))
place('FoamRibbon',(-52.9,4,.3),scale=(.5,1,1));place('Cannonball',(-20,4,7.33));place('DangerStripe',(-22,4,4.23));place('MuzzleCue',(-12.9,4,7.33))
place('BoardingRamp',(-12,44,3.23))
for y in [44,64]:
    place('HullSide',(0,y,0))
    if y==64:place('HullSide',(0,y,0),180)
    place('ShipDeck',(0,y,8.3))
for y in [37,48,59,70]:place('PlayableRib',(0,y,0))
place('HullBow',(0,36,0));place('SternTransom',(0,72,0));place('ShipDeck',(0,64,20));place('MastYard',(0,64,21.2));place('TornSail',(0,64,30.2))
place('CliffShoulder',(-38,62,-5),scale=(1.2,1.2,1.2));place('CliffShoulder',(25,61,-1));place('GroundingRock',(9,30,-2));place('Palm',(-38,62,13));place('Palm',(25,64,14))
for y in [34,55,70]:place('CliffShoulder',(-1,y,-3),scale=(1.15,1,.72))
place('CavePortal',(46,65,0),90,visual_only=True)
place('CliffShoulder',(46,47,-2),scale=(1,1,1.2))
place('CliffMass',(46,85,-3),scale=(1,1,1.1))

g='cave'
place('CoveWater',(180,0,0),group=g)
for x in [160,200]:place('RefugeShelf',(x,0,2),group=g)
place('SurgeCrossing',(180,0,3),group=g)
for x in [149,169,191,211]:place('CaveWall',(x,14,-1),group=g)
place('CaveRoof',(180,2,19),group=g,scale=(1,2,1));place('CavePortal',(145,0,0),90,group=g)
place('LocalSurge',(180,-8,3.8),group=g);place('FoamRibbon',(180,-1,4.2),group=g,scale=(1,3,1))
place('CaveWall',(180,-24,-1),180,group=g)
place('CliffShoulder',(160,-20,-1),group=g);place('CliffShoulder',(200,-20,-1),group=g)
for x in [171,189]:place('DangerStripe',(x,0,4.015),90,group=g,scale=(1,2,.15))
place('CliffShoulder',(151,-17,-1),group=g);place('GroundingRock',(210,-17,-1),group=g)
for x,yaw in [(162,25),(180,-35)]:place('CaveRoof',(x,4,19),yaw,group=g,scale=(.55,1,.65),visual_only=True)

g='ribs_spars'
for i in range(3):
    place('PlayableRib',(330,i*10,i*1.5),group=g)
    place('HullSide',(330,i*10,i*1.5),group=g)
    place('CliffShoulder',(332,i*10,-5),group=g,scale=(1,.7,.85))
for i in range(3):
    place('BrokenSpar',(355+i*18,14+i*3,12-i*1.5),yaw=15 if i%2==0 else -15,group=g)
    place('CliffShoulder',(355+i*18,14+i*3,-3-i*1.5),group=g)
place('BrokenDeck',(342,-10,18.6),group=g);place('CaveRoof',(342,-10,34),group=g)

study_stats=[]
byid={r['id']:r for r in records}
for group in budgets['studyLimits']:
    rows=[r for r in studies if r['group']==group];tri=sum(byid[r['asset']]['triangles']for r in rows)
    assert tri<=budgets['studyLimits'][group]['triangles'],(group,tri)
    study_stats.append(dict(group=group,visualPlacements=len(rows),visualTriangles=tri))
(ROOT/'studies.json').write_text(json.dumps(dict(build=STUDY_BUILD,kitBuild=BUILD,placements=studies,stats=study_stats),indent=2))
world=bpy.data.worlds.new('Study daylight');bpy.context.scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.7,.8,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
sun_data=bpy.data.lights.new('Sun','SUN');sun_data.energy=2.5;sun=bpy.data.objects.new('Sun',sun_data);bpy.context.collection.objects.link(sun);sun.rotation_euler=(.6,-.5,-.3)
camdata=bpy.data.cameras.new('StudyCamera');cam=bpy.data.objects.new('StudyCamera',camdata);bpy.context.collection.objects.link(cam);bpy.context.scene.camera=cam;camdata.lens=32
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.render.resolution_x=1400;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard';scene.render.image_settings.file_format='PNG'
def shot(n,pos,target):
    cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(ROOT/(n+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_FitStudies07.blend'))
shot('study-dock-wreck',(-78,-55,49),(-6,25,18))
shot('study-cave',(218,-27,15),(175,1,9))
shot('study-ribs-spars',(365,-35,35),(355,14,13))
print(json.dumps({'manifest':manifest,'studies':study_stats}))
