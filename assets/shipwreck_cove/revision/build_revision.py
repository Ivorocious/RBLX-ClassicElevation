"""Build the supplementary Shipwreck Cove visual kit in Blender 5.2."""
import bpy
import bmesh
import hashlib
import json
import math
import struct
import zlib
from pathlib import Path

from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parent
BUILD = "SC_REV_13"
CURRENT_LAYOUT = json.loads((ROOT/'layout.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)

# Retain the phase-one 8 x 8 opaque atlas slots and add no transparent materials.
COLORS = [(164,105,59),(210,155,92),(107,65,37),(196,148,83),
          (235,211,163),(160,142,109),(55,72,76),(240,226,192),
          (161,72,62),(49,53,55),(82,86,83),(40,154,165),
          (49,180,150),(221,245,233),(76,113,57),(112,142,68),
          (217,67,41),(239,178,65),(53,79,76),(177,155,114),
          (231,187,111),(195,151,81),(127,106,76),(41,104,95)]
WOOD,LIGHT,DARK,TAN,SAND,STONE,SLATE,CREAM,SAIL,IRON,IRON_L,SEA,WAVE,FOAM,LEAF,LEAF_L,RED,GOLD,INK,ROPE,SAND_WARM,SAND_SHADE,STONE_SHADE,DEEP = range(24)

def palette_png(path):
    n=128
    raw=bytearray()
    for y in range(n):
        raw.append(0)
        for x in range(n):
            slot=(y//16)*8+x//16
            rgb=COLORS[slot] if slot<len(COLORS) else (164,105,59)
            raw.extend((*rgb,255))
    def chunk(tag,data):
        return struct.pack('>I',len(data))+tag+data+struct.pack('>I',zlib.crc32(tag+data)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))

palette_png(ROOT/'palette.png')
mat=bpy.data.materials.new('SC_RevisionOpaquePalette')
mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF')
bs.inputs['Roughness'].default_value=.87
tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(ROOT/'palette.png'))
tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])

class Geo:
    def __init__(self):
        self.v=[]; self.f=[]; self.c=[]
    def mesh(self,vs,fs,cs):
        start=len(self.v)
        self.v.extend(tuple(v) for v in vs)
        self.f.extend(tuple(start+i for i in f) for f in fs)
        self.c.extend(cs if isinstance(cs,list) else [cs]*len(fs))
    def box(self,center,size,color):
        x,y,z=center; a,b,c=(s/2 for s in size)
        vs=[(x+i*a,y+j*b,z+k*c) for k in (-1,1) for j in (-1,1) for i in (-1,1)]
        self.mesh(vs,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],color)
    def beam(self,a,b,width,depth,color):
        a,b=Vector(a),Vector(b)
        d=(b-a).normalized()
        u=d.cross(Vector((0,1,0)))
        if u.length<.01: u=d.cross(Vector((1,0,0)))
        u.normalize();v=d.cross(u).normalized()
        vs=[tuple(p+u*i*width/2+v*j*depth/2) for p in (a,b) for j in (-1,1) for i in (-1,1)]
        self.mesh(vs,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],color)
    def prism(self,poly,depth,color,axis='y'):
        n=len(poly)
        if axis=='y': vs=[(x,t,z) for t in (-depth/2,depth/2) for x,z in poly]
        else: vs=[(x,y,t) for t in (-depth/2,depth/2) for x,y in poly]
        fs=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]
        fs.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
        self.mesh(vs,fs,color)
    def rings(self,rings,n,color,axis='z',center=(0,0,0),cap=True):
        vs=[]
        for t,r in rings:
            for i in range(n):
                q=2*math.pi*i/n
                p=(r*math.cos(q),r*math.sin(q),t)
                if axis=='x':p=(t,p[0],p[1])
                if axis=='y':p=(p[0],t,p[1])
                vs.append(tuple(p[j]+center[j] for j in range(3)))
        fs=[(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i) for k in range(len(rings)-1) for i in range(n)]
        if cap: fs.extend((tuple(reversed(range(n))),tuple((len(rings)-1)*n+i for i in range(n))))
        self.mesh(vs,fs,color)

rows=[];objects={}
def asset(name,g,family,notes,mount='ground',estimated_placements=1,recalculate_normals=True):
    name='SC_R_'+name
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(g.v,[],g.f);mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for face,color in zip(mesh.polygons,g.c):
        for k,j in enumerate(face.loop_indices):
            angle=2*math.pi*k/len(face.loop_indices)
            uv.data[j].uv=(((color%8)*16+8+2*math.cos(angle))/128,
                           1-((color//8)*16+8+2*math.sin(angle))/128)
    if recalculate_normals:
        bm=bmesh.new();bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(mesh);bm.free()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    ob['Build']=BUILD;ob['Family']=family;ob['VisualOnly']=True
    mesh.calc_loop_triangles();triangles=len(mesh.loop_triangles)
    assert triangles<=1500,(name,triangles)
    lo=[min(v.co[i] for v in mesh.vertices) for i in range(3)]
    hi=[max(v.co[i] for v in mesh.vertices) for i in range(3)]
    rows.append(dict(id=name,family=family,triangles=triangles,triangleCeiling=1500,
        estimatedPlacements=estimated_placements,dimensionsRobloxXYZ=[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]],
        boundsBlender=dict(min=lo,max=hi),localPivotBlender=[0,0,0],mount=mount,notes=notes))
    objects[name]=ob

# Hull axis is local Y. Three 20-stud bays join at Y +/-10; course places bay
# origins 20 studs apart. Outer/inner strips preserve an open upper deck.
def hull(name,stations,kind):
    g=Geo();profile=[(-1,10),(-.99,8),(-.94,4.5),(-.65,1.6),(0,.5),(.65,1.6),(.94,4.5),(.99,8),(1,10)]
    broken_side=1 if kind=='bow' else -1
    broken_intervals=(-5,0) if kind in ('bow','mid') else (-10,-5)
    for (ya,wa,ha),(yb,wb,hb) in zip(stations,stations[1:]):
        for side in range(len(profile)-1):
            if side in (3,4):continue
            upper_side=(side in (5,6,7) if broken_side==1 else side in (0,1,2))
            if upper_side and ya in broken_intervals:continue
            q=[]
            for y,w,h in ((ya,wa,ha),(yb,wb,hb)):
                for index in (side,side+1):
                    px,pz=profile[index];q.append((px*w,y,pz+h))
            outer=[q[0],q[1],q[3],q[2]]
            inner=[(x*.91,y,z+.15) for x,y,z in outer]
            g.mesh(outer+inner,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(1,5,6,2),(0,3,7,4)],
                   DARK if side in (2,5) else WOOD if side in (1,6) else LIGHT)
        for sign in (-1,1):
            inner=.39*sign;outer=.65*sign
            g.mesh([(inner*wa,ya,1.75+ha),(outer*wa,ya,1.62+ha),
                    (outer*wb,yb,1.62+hb),(inner*wb,yb,1.75+hb)],
                   [(0,1,2,3)],DARK)
    for y,w,h in stations:
        for sign in (-1,1):
            if sign==broken_side and y==broken_intervals[1]:continue
            g.beam((sign*w,y,10+h),(sign*.52*w,y,2+h),.7,.7,DARK)
            g.beam((sign*w,y,10+h),(sign*w,y,12+h),.65,.7,LIGHT)
    for sign in (-1,1):
        for a,b in zip(stations,stations[1:]):
            if sign==broken_side and a[0] in broken_intervals:continue
            g.beam((sign*a[1],a[0],11+a[2]),(sign*b[1],b[0],11+b[2]),.6,.65,LIGHT)
    widths={y:(w,h) for y,w,h in stations}
    first,last=broken_intervals[0],broken_intervals[1]+5
    for y,lean in ((first,1.4),(last,-1.4)):
        w,h=widths[y]
        g.beam((broken_side*w,y,11+h),(broken_side*(w-.35),y+lean,8.8+h),.55,.55,LIGHT)
    if kind=='bow':
        for sign in (-1,1):
            g.mesh([(sign*4,-10,4),(sign*4,-10,11),(sign*.6,-14,10.2),
                    (sign*.6,-14,6.2)],[(0,1,2,3) if sign>0 else (3,2,1,0)],WOOD)
        g.beam((0,-11,1),(0,-16,12),1.7,1.8,DARK)
        g.beam((-5,-9,12),(5,-9,12),.9,.8,LIGHT)
    if kind=='stern':
        for sign in (-1,1):
            g.box((sign*10.5,6,15),(3,8,1.4),LIGHT)
            g.box((sign*10.5,6,18),(1,8,5),DARK)
            g.box((sign*10.5,10,19),(1.3,1,6),WOOD)
            g.box((sign*10.5,10.55,20),(1,.15,2),GOLD)
        g.box((0,10,22),(22,1,1.5),WOOD)
    asset(name,g,'hull',kind+' open-top split-galleon bay; mount pivot remains local origin. Open central bilge reveals sea, upper planks and rails have broken bays. Stern high deck is side galleries with central route opening.',estimated_placements=1)

hull('HullBow',[(-10,4,1),(-5,8,0),(0,10,0),(5,12,0),(10,13,0)],'bow')
hull('HullMid',[(-10,13,0),(-5,13,0),(0,13,0),(5,13,0),(10,13,0)],'mid')
hull('HullStern',[(-10,13,0),(-5,13,.4),(0,12,1),(5,11,1.4),(10,10,1.8)],'stern')

g=Geo()
g.box((0,0,.45),(22,19,.9),WOOD)
for x in (-7.2,-3.6,0,3.6,7.2):g.box((x,0,.93),(.11,18.8,.05),DARK)
asset('HullDeck',g,'deck','Deck top Z0.95; mount local origin at hull Z9.5, one per bay.',mount='hull deck',estimated_placements=3)

g=Geo()
g.box((.7,0,1.2),(5,3,1.1),WOOD)
g.beam((.2,0,1.9),(-4.8,0,3.5),2.3,2.3,IRON)
g.rings([(-5.15,1.18),(-4.75,1.18),(-4.4,.95),(-3.9,.95)],10,GOLD,'x',(0,0,3.5),False)
g.rings([(-5.18,1.18),(-5.18,.65)],10,IRON_L,'x',(0,0,3.5),False)
g.rings([(-5.18,.65),(-3.8,.65)],10,INK,'x',(0,0,3.5),False)
g.rings([(-1.1,1.03),(-.7,1.03)],10,GOLD,'x',(0,0,3.5),False)
for x in (-1.5,1.8):
    for y in (-1.8,1.8):
        g.rings([(-.38,.8),(.38,.8)],8,DARK,'y',(x,y,.83))
        g.rings([(-.39,.83),(-.39,.6)],8,GOLD,'y',(x,y,.83),False)
asset('CannonFourWheel',g,'cannon','Local muzzle faces negative X, bore center Z3.5, ground bottom near Z0. Four separate wheels.',estimated_placements=2)

def sand_terrace(name,outline,crown,placements):
    g=Geo();n=len(outline)
    # Shared ring vertices and authored winding keep this open surface facing up.
    rings=[]
    for factor,height in ((1,0),(.86,.75),(.60,crown*.70),(.28,crown)):
        rings.extend((x*factor,y*factor,height) for x,y in outline)
    faces=[];colors=[]
    for k in range(3):
        for i in range(n):
            j=(i+1)%n
            faces.append((k*n+i,k*n+j,(k+1)*n+j,(k+1)*n+i))
            colors.append((SAND_SHADE,SAND_WARM,SAND_WARM)[k])
    rings.append((0,0,crown*.93))
    faces.extend((3*n+i,3*n+(i+1)%n,4*n) for i in range(n))
    colors.extend([SAND_WARM]*n)
    g.mesh(rings,faces,colors)
    asset(name,g,'shore','Irregular rounded golden shoreline with layered edge; pivot at waterline Z0.',
          estimated_placements=placements,recalculate_normals=False)
    mesh=objects['SC_R_'+name].data
    assert all(face.normal.z>.01 for face in mesh.polygons),(name,'shore face points downward')

sand_terrace('SandIsland',[(-18,0),(-16,-6.5),(-11,-9.3),(-3,-9.5),(6,-8.8),(13,-6.3),
    (18,-1.8),(16,5.4),(10,8.6),(2,9.5),(-7,8.8),(-14,6)],4,2)
sand_terrace('SandWedge',[(-13,-1),(-12,-4.2),(-8,-5.8),(-2,-6),(6,-5.6),(12,-3.7),
    (13,0),(9,4.5),(3,6),(-5,5.8),(-11,3.7)],3,3)

g=Geo()
base=[(-9,0),(-8,-5),(-5,-8.5),(0,-8.2),(5,-8),(8,-5),
      (9,0),(8,5),(5,8.5),(0,8.2),(-5,8),(-8,5)]
top=[(-6,0),(-6,-5.5),(-3,-5.5),(0,-5.5),(3,-5.5),(6,-5.5),
     (6,0),(6,5.5),(3,5.5),(0,5.5),(-3,5.5),(-6,5.5)]
n=len(base)
lower=[(x*.99,y*.99,.18+.08*math.sin(i*1.9)) for i,(x,y) in enumerate(base)]
shoulder=[(top[i][0]*.30+base[i][0]*.70,
           top[i][1]*.30+base[i][1]*.70,2.25+.24*math.sin(i*1.6+.5))
          for i in range(n)]
vertices=[(x,y,0) for x,y in base]+lower+shoulder+[(x,y,5) for x,y in top]
faces=[];colors=[]
for ring in (0,1,2):
    for i in range(n):
        j=(i+1)%n
        faces.append((ring*n+i,ring*n+j,(ring+1)*n+j,(ring+1)*n+i))
        colors.append((SAND_SHADE if i%4 else STONE_SHADE) if ring==0 else
                      (SAND_WARM if i%3 else SAND_SHADE) if ring==1 else
                      (SAND_WARM if i%4 else SAND_SHADE))
faces.append(tuple(3*n+i for i in range(n)))
colors.append(SAND_WARM)
g.mesh(vertices,faces,colors)
asset('ShoreStep',g,'shore','Flat 12x11 crown exactly Z5; irregular dune shoulder inside the original 18x17 base at Z0. Match a 12x11 box collider at top.',
      estimated_placements=7,recalculate_normals=False)
assert all(p.normal.z>.01 for p in objects['SC_R_ShoreStep'].data.polygons)

g=Geo()
top=[(-6,0),(-6,-5),(-3,-5),(0,-5),(3,-5),(6,-5),
     (6,0),(6,5),(3,5),(0,5),(-3,5),(-6,5)]
n=len(top);vertices=[]
for ring in range(4):
    for i,(x,y) in enumerate(top):
        if ring==0:factor=.66+.025*math.sin(i*2.2);height=0
        elif ring==1:factor=.74+.02*math.sin(i*1.7);height=2.1+.25*math.sin(i*1.3)
        elif ring==2:factor=.91+.01*math.sin(i*2.1);height=7.2+.22*math.sin(i*1.5)
        else:factor=1;height=10
        vertices.append((x*factor,y*factor,height))
faces=[];colors=[]
for ring in range(3):
    for i in range(n):
        j=(i+1)%n
        faces.append((ring*n+i,ring*n+j,(ring+1)*n+j,(ring+1)*n+i))
        colors.append((STONE_SHADE if i%4 else SLATE,
                       STONE if i%3 else STONE_SHADE,
                       SAND if i%4 else STONE)[ring])
faces.append(tuple(3*n+i for i in range(n)))
colors.append(SAND)
g.mesh(vertices,faces,colors)
asset('CaveRefuge',g,'cave','Flat 12x10 crown exactly Z10, base nested inside crown footprint at Z0; scale crown to refuge collider.',
      estimated_placements=3,recalculate_normals=False)
assert rows[-1]['triangles']<=140

def rock(name,w,d,h,seed,color=STONE):
    g=Geo();n=7;vs=[]
    for k,z in enumerate((0,h*.72,h)):
        for i in range(n):
            a=math.tau*i/n
            f=(1,.93,.54)[k]*(1+.10*math.sin(seed+i*3))
            vs.append((w*.5*f*math.cos(a),d*.5*f*math.sin(a),z+(0 if k!=1 else h*.07*math.sin(i*2+seed))))
    fs=[tuple(reversed(range(n))),tuple(14+i for i in range(n))]
    fs += [(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i) for k in range(2) for i in range(n)]
    g.mesh(vs,fs,[STONE_SHADE,color]+[color if i%3 else STONE_SHADE for i in range(14)])
    asset(name,g,'rock','Faceted limestone sea rock; local bottom Z0. Sink lower ring below water or sand.',estimated_placements=6)
rock('SeaRockTall',11,10,14,2)
rock('SeaRockFlat',15,12,6,4)
rock('SeaRockSpire',8,8,18,6)

g=Geo()
for a,b in [((-9,0,0),(-8,0,14)),((9,0,0),(8,0,14)),((-8,0,14),(0,0,17)),((0,0,17),(8,0,14))]:
    g.beam(a,b,1.5,1.5,DARK)
for x in (-9,9):g.box((x,0,.7),(2.4,2.4,1.4),WOOD)
g.box((0,.15,12),(12,.18,5.5),SEA)
g.box((0,-.02,14.9),(12.4,.25,.3),GOLD)
asset('CheckpointBeacon',g,'checkpoint','Pirate timber frame: opening ~16 studs wide, banner near Z12, top Z17. Separate gameplay trigger required.',estimated_placements=2)
g=Geo();g.box((0,0,5.5),(1,1,11),DARK)
g.box((0,-.6,8),(10,.6,4),WOOD)
g.box((0,-.96,8),(8.5,.09,2.7),SAND_WARM)
g.beam((-4.8,-1,6.2),(4.8,-1,9.8),.4,.2,DARK)
asset('PirateSignboard',g,'sign','Local pole base Z0; front reads toward negative Y. Add text in Roblox if needed.',estimated_placements=3)

def plant(name,variant):
    g=Geo()
    if variant=='grass':
        for x,y,h in [(-1.7,0,3),(-.8,.4,4),(0,-.2,3.4),(.9,.3,4.2),(1.8,0,2.8)]:
            g.mesh([(x-.35,y,0),(x+.35,y,0),(x+.1,y,h)],[(0,1,2)],LEAF if x<0 else LEAF_L)
    elif variant=='shrub':
        for x,y,h in [(-2,0,3.8),(0,.6,5),(2,0,4),(-.8,-1,4.6),(1.4,-1,3.7)]:
            g.mesh([(x-1.1,y,0),(x,y,h),(x+1.1,y,0),(x,y+1.1,h*.58)],[(0,1,3),(1,2,3),(0,3,2)],
                   [LEAF,LEAF_L,LEAF])
    else:
        for a,b,w in [((0,0,0),(.4,0,6),1.2),((.4,0,6),(1.1,0,12),.95),((1.1,0,12),(1.8,0,18),.7)]:
            g.beam(a,b,w,w,WOOD)
        for i in range(9):
            q=math.tau*i/9+.025*math.sin(i*2.7);u=Vector((math.cos(q),math.sin(q),0))
            side=Vector((-u.y,u.x,0));base=Vector((1.8,0,18))
            length=10 if i==0 else 9.58 if i==5 else 9.2+.25*(i%3)
            center1=base+u*3.1+Vector((0,0,1.25+.2*(i%3)))
            center2=base+u*6.1+Vector((0,0,.15-.25*(i%2)))
            tip=base+u*length+Vector((0,0,-2.8-.35*(i%4)))
            p=[base,center1-side*1.7,center1+side*1.7,
               center2-side*1.35,center2+side*1.35,tip]
            g.mesh([tuple(v) for v in p],[(0,1,2),(1,3,4,2),(3,5,4)],[LEAF,LEAF_L,LEAF])
    asset(name,g,'vegetation','Local base Z0; visual foliage, keep clear of jumps and camera.',estimated_placements=8)
plant('GrassClump','grass')
plant('Shrub','shrub')
plant('FanPalm','palm')

# A thin forward-moving sheet breaks into one low white lip, rather than a hollow C tube.
g=Geo()
wave_profile=[(-8,0),(-6,.45),(-3,1.2),(-.2,2.55),(2.2,4.35),
              (3.65,5.65),(3.5,6.3),(2.2,6.5)]
wave_y=(-8,-6,-3,0,3,6,8)
def wave_vertex(index,along,back=False):
    x,z=wave_profile[index]
    edge=abs(along)/8
    x=x*1.525*(1-.06*edge) if x>0 else x*1.525
    if index>=5:x-=.55*edge
    if index>=4:z*=1-.17*edge**1.3
    elif index>=2:z*=1-.055*edge
    return (x-(.32 if back else 0),along,z)
count=len(wave_profile);station_count=len(wave_y)
front=[wave_vertex(i,y) for y in wave_y for i in range(count)]
back=[wave_vertex(i,y,True) for y in wave_y for i in range(count)]
wave_vertices=front+back
back_offset=len(front)
wave_faces=[];wave_colors=[]
for station in range(station_count-1):
    for i in range(count-1):
        a=station*count+i;b=(station+1)*count+i
        wave_faces.append((a,b,b+1,a+1))
        wave_colors.append(FOAM if i>=5 else WAVE if i%3 else SEA)
        wave_faces.append((back_offset+a+1,back_offset+b+1,back_offset+b,back_offset+a))
        wave_colors.append(FOAM if i>=5 else SEA)
    for i in (0,count-1):
        a=station*count+i;b=(station+1)*count+i
        wave_faces.append((a,back_offset+a,back_offset+b,b) if i==0 else
                          (b,back_offset+b,back_offset+a,a))
        wave_colors.append(SEA if i==0 else FOAM)
for end in (0,station_count-1):
    for i in range(count-1):
        a=end*count+i;b=a+1
        wave_faces.append((a,b,back_offset+b,back_offset+a) if end==0 else
                          (back_offset+a,back_offset+b,b,a))
        wave_colors.append(FOAM if i>=5 else WAVE)
g.mesh(wave_vertices,wave_faces,wave_colors)
# Three broad attached foam sheets interrupt the lip without separate floating shards.
for y0,y1 in ((-6,-3),(-1.2,1.3),(3.1,6)):
    foam=[wave_vertex(4,y0),wave_vertex(6,y0),wave_vertex(6,y1),wave_vertex(4,y1)]
    g.mesh([(x+.045,y,z) for x,y,z in foam],[(0,2,1),(0,3,2)],FOAM)
asset('CurlingWave',g,'wave','Thin advancing sloped breaker with a low tapered crest and white foam attached to the front; same local mount and travel axis.',
      estimated_placements=2,recalculate_normals=False)
g=Geo();g.prism([(-5,0),(-3,1.1),(0,1.3),(3,1),(6,1.7),(8,.7),(8,0)],16,FOAM)
asset('WaveFoamLip',g,'foam','Opaque scalloped foam band; align around the base or crest of CurlingWave.',estimated_placements=2)

# The second chamber adds a southern side connector near its eastern end.
# Keeping it separate preserves the approach chamber's continuous west wall.
def cave_chamber(name,bend=False):
    g=Geo();n=9;ys=(-18,-12,-6,0,6,12,18)
    for ya,yb in zip(ys,ys[1:]):
        for i in range(n-1):
            a=math.pi-i*math.pi/(n-1);b=math.pi-(i+1)*math.pi/(n-1)
            def point(angle,y,r):
                swell=math.sin(angle)**2
                radius=r+.65*swell*math.sin(.31*y+2.6*angle)
                rise=18+.8*math.sin(.24*y+3.1*angle)
                return (radius*math.cos(angle),y,6+rise*math.sin(angle))
            def outer_point(angle,y):
                rough=math.sin(angle)**2*(1.1+.7*math.sin(.32*y+2.3*angle))
                radius=18+rough
                x=radius*math.cos(angle);z=6+radius*math.sin(angle)
                return (x,y+.45*math.sin(angle)*math.sin(.22*y+3*angle),z)
            if bend and i>=n-3 and ya in (-6,0):continue
            if bend and i<=1 and ya in (6,12):continue
            outer=[outer_point(a,ya),outer_point(b,ya),outer_point(b,yb),outer_point(a,yb)]
            inner=[point(a,ya,16.7),point(b,ya,16.7),point(b,yb,16.7),point(a,yb,16.7)]
            def between(a,b,t):return tuple(a[k]*(1-t)+b[k]*t for k in range(3))
            bands=[]
            for ring in (outer,inner):
                for t in (.35,.70):
                    bands.extend((between(ring[0],ring[1],t),between(ring[3],ring[2],t)))
            patches=((0,8,9,3),(8,10,11,9),(10,1,2,11),
                     (4,7,13,12),(12,13,15,14),(14,15,6,5))
            colors=[]
            for face in patches:
                z=sum((outer+inner+bands)[j][2] for j in face)/len(face)
                colors.append(STONE_SHADE if z<11 else STONE if z<19 else CREAM)
            g.mesh(outer+inner+bands,list(patches)+[(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],
                   colors+[STONE,STONE,STONE,STONE])
        for side in (-1,1):
            if bend and side==1 and ya in (-6,0):continue
            if bend and side==-1 and ya in (6,12):continue
            x=side*17.5
            g.box((x,(ya+yb)/2,3),(1.4,yb-ya,6),STONE)
    for x in (-17.5,17.5):
        for y in (-18,18):
            if bend and x<0 and y>0:continue
            g.box((x,y,3),(2,2,6),STONE_SHADE)
    # Broad grounded buttresses overlap the shell but stay outside the walk corridor.
    lobes=((-1,-11,7),(1,12,7)) if bend else ((-1,-11,8),(1,-1,9),(-1,10,7))
    for index,(side,mid,half_length) in enumerate(lobes):
        inner=(14.5 if index%2 else 15.0)*side
        outer=21.0*side
        y0,y1=mid-half_length/2,mid+half_length/2
        vertices=[(inner,y0,0),(outer,y0-.7,0),(outer,y1+.7,0),(inner,y1,0),
                  (side*16.2,y0+1,12.6),(side*19.5,y0+.25,14.2),
                  (side*20.3,y1-.25,12.8),(side*16.0,y1-1,11.9)]
        faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
        g.mesh(vertices,faces,[STONE_SHADE,STONE,STONE if index%2 else STONE_SHADE,
                               STONE,CREAM if index%2 else STONE,STONE_SHADE])
    # A shallow ceiling shoulder is visibly attached to the arch on both sides.
    for side in (-1,1):
        y0,y1=(-4,3) if not bend else (-14,-7)
        vertices=[(side*7.5,y0,21.2),(side*12.2,y0-.5,18.2),
                  (side*12.4,y1+.5,18.0),(side*7.3,y1,21.4),
                  (side*7.3,y0+.6,19.9),(side*11.1,y0+.4,17.6),
                  (side*11.3,y1-.4,17.7),(side*7.0,y1-.6,20.1)]
        g.mesh(vertices,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),
                         (2,6,7,3),(3,7,4,0)],
               [STONE,STONE_SHADE,STONE,STONE,CREAM if side<0 else STONE,STONE_SHADE])
    for index,(side,y0,y1) in enumerate(((-1,-15,-8),(1,-3,5),(-1,8,15)) if not bend else
                                         ((1,-15,-8),(-1,-4,4),(1,8,15))):
        # The high cap is buried in the arch; the lower polygon makes a broad seam.
        vertices=[(side*2.2,y0,25.5),(side*8.5,y0-1,22.5),
                  (side*8.0,y1+1,22.8),(side*2.5,y1,25.2),
                  (side*2.8,y0+.7,21.7),(side*8.4,y0+.2,19.2),
                  (side*8.1,y1-.2,19.6),(side*2.5,y1-.7,22.0)]
        g.mesh(vertices,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),
                         (2,6,7,3),(3,7,4,0)],
               [STONE_SHADE,STONE,STONE,STONE_SHADE,STONE if index%2 else CREAM,STONE])
    for end in (-18,18):
        sign=-1 if end<0 else 1
        for i in (1,3,5):
            if bend and end>0 and i==1:continue
            a=math.pi-i*math.pi/(n-1)
            b=math.pi-(i+1)*math.pi/(n-1)
            pa=Vector(outer_point(a,end));pb=Vector(outer_point(b,end))
            qa=pa+Vector((0,-sign*2,.25));qb=pb+Vector((0,-sign*2,.25))
            tip=(pa+pb)/2+Vector((0,sign*1.1,1.5 if i==3 else 1.0))
            g.mesh([tuple(v) for v in (pa,pb,qa,qb,tip)],
                   [(0,1,4),(1,3,4),(3,2,4),(2,0,4),(0,2,3,1)],
                   [STONE,CREAM,STONE_SHADE,STONE,STONE])
    notes='36-stud Y tunnel, open at both ends; ceiling center Z24.'
    if bend:notes+=' Full-height +X sea opening at Y -6..6 and -X connector at Y 6..18 join the approach chamber.'
    asset(name,g,'cave',notes,estimated_placements=1)

cave_chamber('CaveChamber')
cave_chamber('CaveTideBend',True)

# The course-local hull sits below the playable decks and has no upper floor.
def course_vertex(x,height,z):return (x,-z,height)
underbody_stations=[(-122,8,2),(-116,9,6),(-108,12,13),(-96,15,18),
                    (-84,18,20),(-72,21,20),(-60,25,20),(-48,28,19),
                    (-36,32,18),(-24,35,17),(-12,37,15),(0,38,13),(3,38,10)]
g=Geo()
for sign in (-1,1):
    for a,b in zip(underbody_stations,underbody_stations[1:]):
        xa,ha,wa=a;xb,hb,wb=b
        profile=((1,0),(1,-5),(.83,-11),(.52,-17),(.30,-19))
        for band in range(4):
            if sign==1 and xa in (-72,-24) and band<2:continue
            fa,va=profile[band];fb,vb=profile[band+1]
            ring=[course_vertex(xa,ha+va,-100+sign*wa*fa),
                  course_vertex(xa,ha+vb,-100+sign*wa*fb),
                  course_vertex(xb,hb+vb,-100+sign*wb*fb),
                  course_vertex(xb,hb+va,-100+sign*wb*fa)]
            inner=[(x,y+(sign*.12),z) for x,y,z in ring]
            g.mesh(ring+inner,[(0,1,2,3),(4,7,6,5),(0,4,5,1),
                               (1,5,6,2),(2,6,7,3),(3,7,4,0)],
                   (TAN,WOOD,DARK,DARK)[band])
for x,h,w in underbody_stations[2:-1]:
    g.beam(course_vertex(x,h-19,-100),course_vertex(x+3,h-19,-100),1.3,1.4,DARK)
for band in range(2):
    a,b=((1,0),(1,-5)) if band==0 else ((1,-5),(.83,-11))
    g.mesh([course_vertex(3,38+a[1],-100-10*a[0]),
            course_vertex(3,38+a[1],-100+10*a[0]),
            course_vertex(3,38+b[1],-100+10*b[0]),
            course_vertex(3,38+b[1],-100-10*b[0])],[(0,1,2,3)],WOOD if band==0 else DARK)

rib_anchors=[]
for place in CURRENT_LAYOUT['placements']:
    if not place['name'].startswith('Rib') or place['asset']!='SC_PlayableRib':continue
    x,base_height,base_z=place['p']
    for a,b in zip(underbody_stations,underbody_stations[1:]):
        if a[0]<=x<=b[0]:
            t=(x-a[0])/(b[0]-a[0]);height=a[1]*(1-t)+b[1]*t;width=a[2]*(1-t)+b[2]*t
            break
    anchor_height=min(height-11,base_height+11)
    anchor=course_vertex(x,anchor_height,-100+width)
    elbow=course_vertex(x+.7*(1 if int(place['name'][-2:])%2 else -1),base_height+7,base_z-5)
    foot=course_vertex(x,base_height+1.5,base_z)
    g.beam(anchor,elbow,1.45,1.45,WOOD)
    g.beam(elbow,foot,1.35,1.35,DARK)
    rib_anchors.append(dict(name=place['name'],base=[x,base_height,base_z],
                            anchorHeight=round(anchor_height,2),tipClearance=round(base_height+18.6-anchor_height,2)))
asset('GroundedHullUnderbody',g,'hull',
      'Place once at course (0,0,0), yaw0, scale1. Deep open-top split bow-to-stern side shell with narrow low keel and ten timber rib-root braces; visual-only, never a walking floor.',
      estimated_placements=1)
assert rows[-1]['triangles']<=1500 and all(r['tipClearance']>=6 for r in rib_anchors)

shore_route=CURRENT_LAYOUT['paths']['S04_Shore']
shore_stations=[]
for a,b in zip(shore_route,shore_route[1:]):
    shore_stations.append((a,False))
    shore_stations.append(([(a[k]+b[k])/2 for k in range(3)],True))
shore_stations.append((shore_route[-1],False))
first,second=shore_route[:2];last,previous=shore_route[-1],shore_route[-2]
shore_stations.insert(0,([first[k]+.5*(first[k]-second[k]) for k in range(3)],True))
shore_stations.insert(0,([first[k]+1.1*(first[k]-second[k]) for k in range(3)],True))
shore_stations.append(([last[k]+.5*(last[k]-previous[k]) for k in range(3)],True))
shore_stations.append(([last[k]+1.1*(last[k]-previous[k]) for k in range(3)],True))
g=Geo();bank_vertices=[]
for station,(p,is_mid) in enumerate(shore_stations):
    x,_,z=p
    before=shore_stations[max(0,station-1)][0]
    after=shore_stations[min(len(shore_stations)-1,station+1)][0]
    dx,dz=after[0]-before[0],after[2]-before[2]
    length=math.hypot(dx,dz);outward=(dz/length,-dx/length)
    profile=((-30,-4),(-22,-2.2),(-16,2.2),(-12,6.3),(-9.5,8),(0,8),
             (9.5,8),(13,6.8),(20,2.5),(30,-4))
    tip=station in (0,len(shore_stations)-1)
    for band,(distance,height) in enumerate(profile):
        waviness=0 if band in (4,5,6) else 1.15*math.sin(station*1.13+distance*.28)
        if band not in (4,5,6):height-=.45*math.sin(station*.9+band*.8)**2
        if tip:height=-4
        bank_vertices.append(course_vertex(x+outward[0]*(distance+waviness),height,
                                           z+outward[1]*(distance+waviness)))
bank_faces=[];bank_colors=[]
for station in range(len(shore_stations)-1):
    for band in range(len(profile)-1):
        a=station*len(profile)+band;b=a+len(profile)
        bank_faces.append((a,b,b+1,a+1))
        bank_colors.append((STONE_SHADE,SAND_SHADE,SAND_WARM,SAND_WARM,SAND_WARM,
                            SAND_WARM,SAND_WARM,SAND_SHADE,STONE_SHADE)[band])
g.mesh(bank_vertices,bank_faces,bank_colors)
asset('ShoreBank',g,'shore',
      'Place once at course (0,0,0), yaw0, scale1. Continuous golden return beach with a flat 19-stud crest exactly Y8 covering 12x11 caps and 12-wide connectors along S04_Shore; broad slopes reach water -4. Use simple path colliders.',
      estimated_placements=1,recalculate_normals=False)
assert all(p.normal.z>.01 for p in objects['SC_R_ShoreBank'].data.polygons)

# One course-local coastal ridge replaces the eleven repeated cliff columns.
# Blender coordinates are (course X, -course Z, course height).
ridge_route=[(20,45,-106),(34,48,-120),(50,51,-130),(67,54,-137),
             (84,55,-130),(101,53,-116),(116,49,-101),(129,44,-85),
             (134,39,-66),(127,33,-48),(119,26,-33)]
stations=[]
for i,(a,b) in enumerate(zip(ridge_route,ridge_route[1:])):
    stations.append((a,False,i))
    stations.append((tuple((a[k]+b[k])/2 for k in range(3)),True,i))
stations.append((ridge_route[-1],False,len(ridge_route)-1))
ridge=Geo();vertices=[]
for station,(p,is_mid,index) in enumerate(stations):
    x,height,z=p
    length=math.hypot(x,z)
    outward=(x/length,z/length)
    front=(min(ridge_route[index][1],ridge_route[index+1][1])-12 if is_mid
           else height-14 if index in (3,7) else height-3)
    shoulder=(height-9 if is_mid else height-11 if index in (3,7) else height-2)
    rear=height+5+1.2*math.sin(station*1.4)
    crest=height+9+2.5*math.sin(station*.82+.5)
    profile=[(-3.5,front),(3.5,front+.2),(8.5,shoulder),
             (19.5+.8*math.sin(station),rear),(24+1.4*math.sin(station*.7),crest),
             (26.5,-6),(-4.5,-6),(-4.2,8+1.2*math.sin(station*.6))]
    vertices.extend((x+outward[0]*distance,-(z+outward[1]*distance),level)
                    for distance,level in profile)
faces=[];colors=[];section_size=8
for station in range(len(stations)-1):
    for band in range(section_size):
        nxt=(band+1)%section_size
        faces.append((station*section_size+band,(station+1)*section_size+band,
                      (station+1)*section_size+nxt,station*section_size+nxt))
        colors.append((STONE if station%3 else SAND,STONE_SHADE if station%4==1 else STONE,
                       STONE,STONE if station%4 else SAND,
                       STONE_SHADE,SLATE,SLATE if station%2 else IRON_L,STONE)[band])
faces.extend((tuple(reversed(range(section_size))),
              tuple((len(stations)-1)*section_size+i for i in range(section_size))))
colors.extend((STONE_SHADE,STONE))
ridge.mesh(vertices,faces,colors)
for index,(x,height,z) in enumerate(ridge_route):
    if index in (3,7):
        continue
    length=math.hypot(x,z)
    outward=(x/length,z/length)
    rings=((height-3.1,0,5.0,5.0),
           (height-7.0,.8,4.5,4.4),
           (height-13.0,2.8,3.1,3.3))
    outline=((-1,-.72),(-.55,-1),(.55,-1),(1,-.72),
             (1,.72),(.55,1),(-.55,1),(-1,.72))
    support_vertices=[]
    for ring_index,(level,shift,half_x,half_z) in enumerate(rings):
        for vertex_index,(ox,oz) in enumerate(outline):
            if index in (8,9) and ring_index==0:
                if vertex_index==0:ox,oz=(-.72,-.76)
                if vertex_index==6:ox,oz=(-.34,.52)
                if vertex_index==7:ox,oz=(-.72,.72)
            support_vertices.append((x+outward[0]*shift+ox*half_x,
                                     -(z+outward[1]*shift+oz*half_z),level))
    support_faces=[]
    for ring in range(2):
        for side in range(8):
            nxt=(side+1)%8
            support_faces.append((ring*8+side,ring*8+nxt,(ring+1)*8+nxt,(ring+1)*8+side))
    support_faces.extend((tuple(reversed(range(8))),tuple(16+i for i in range(8))))
    support_colors=[STONE if side%3 else STONE_SHADE for ring in range(2) for side in range(8)]
    support_colors.extend((STONE,STONE_SHADE))
    ridge.mesh(support_vertices,support_faces,support_colors)
asset('HeadlandRidge',ridge,'cliff','Course-local mesh: place once at (0,0,0), yaw0, scale1. Front shelf support is below S03 pads; rear crest stays outward. Timber nodes 03/07 are deeply notched.',
      estimated_placements=1)
assert rows[-1]['triangles']<=900

assert sum(row['triangles'] for row in rows)<=10000
# Library spacing is only for Blender inspection. Mesh vertex coordinates stay
# local and the manifest carries those coordinates for placement.
for index,row in enumerate(rows):
    objects[row['id']].location=((index%5)*55,(index//5)*62,0)
bpy.context.view_layer.update()
for ob in objects.values():ob.select_set(True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_Revision13.blend'))
bpy.ops.export_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Revision13.fbx'),use_selection=True,
    object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',
    path_mode='COPY',embed_textures=True,use_mesh_modifiers=True,bake_anim=False)
manifest=dict(build=BUILD,units='1 Blender unit = 1 intended Roblox stud',
    coordinates='Blender is Z-up; local (x,y,z) corresponds to Roblox (x,z,-y) under the existing -Z forward / Y up FBX export. Library object positions are only display spacing; use local mesh vertices.',
    shipAssembly='Place SC_R_HullBow, SC_R_HullMid, SC_R_HullStern origins 20 studs apart along Blender Y, in that order; bow at -20, mid at 0, stern at +20. Add HullDeck at each bay origin +Z9.5. Ship length approximately 60 studs plus bowsprit.',
    atlas='palette.png',materialCount=1,uniqueMeshes=len(rows),libraryTriangles=sum(r['triangles'] for r in rows),
    estimatedPlacedTriangles=sum(r['triangles']*r['estimatedPlacements'] for r in rows),
    uniqueTriangleCeiling=10000,assetTriangleCeiling=1500,assets=rows)
(ROOT/'manifest13.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps({k:v for k,v in manifest.items() if k!='assets'}))

# Verify the actual delivered FBX, including the one-sided shore surfaces.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Revision13.fbx'))
expected={row['id']:row for row in rows}
verified=[]
wave_directional_normals=None
for ob in bpy.context.scene.objects:
    if ob.type!='MESH':continue
    mesh=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    mesh.calc_loop_triangles()
    count=len(mesh.loop_triangles)
    assert ob.name in expected and count==expected[ob.name]['triangles'] and count<=1500
    assert len(mesh.materials)==1
    changed_assets=('SC_R_HullBow','SC_R_HullMid','SC_R_HullStern','SC_R_CaveChamber',
                    'SC_R_CaveTideBend','SC_R_CaveRefuge','SC_R_CheckpointBeacon','SC_R_ShoreStep',
                    'SC_R_SandIsland','SC_R_SandWedge','SC_R_FanPalm','SC_R_CurlingWave',
                    'SC_R_GroundedHullUnderbody','SC_R_ShoreBank')
    if ob.name in changed_assets:
        assert all(face.area>1e-5 and face.normal.length>.99 for face in mesh.polygons),(ob.name,'degenerate or invalid face normal')
    if ob.name in ('SC_R_SandIsland','SC_R_SandWedge','SC_R_ShoreStep','SC_R_ShoreBank'):
        assert all(face.normal.z>.01 for face in mesh.polygons),(ob.name,'downward shore face')
    if ob.name=='SC_R_CheckpointBeacon':
        for face in mesh.polygons:
            vertices=[mesh.vertices[index].co for index in face.vertices]
            if min(vertex.z for vertex in vertices)<3:
                assert all(abs(vertex.x)>6 for vertex in vertices),'beacon base crosses walking opening'
    if ob.name=='SC_R_ShoreStep':assert count<=100
    if ob.name=='SC_R_CurlingWave':
        caps=[face for face in mesh.polygons
              if abs(abs(face.center.y)-8)<.01 and face.area>.01]
        left=[face for face in caps if face.center.y<0]
        right=[face for face in caps if face.center.y>0]
        assert len(left)>=5 and len(right)>=5 and all(face.normal.y<-.99 for face in left)\
            and all(face.normal.y>.99 for face in right),\
            ('wave FBX thin end faces do not face outward',[(face.center.y,tuple(face.normal)) for face in caps])
        rising=[face for face in mesh.polygons
                if 2<face.center.x<5.5 and 3<face.center.z<6 and abs(face.center.y)<7 and face.area>2
                and face.normal.x>.25]
        assert rising,('wave FBX rising front has no outward face')
        assert max(vertex.co.z for vertex in mesh.vertices)<=6.51,'wave crest rose above safe refuge design height'
        wave_directional_normals=dict(endCaps=[round(min(face.normal.y for face in left),3),
                                                round(max(face.normal.y for face in right),3)],
                                      risingSideMinX=round(min(face.normal.x for face in rising),3),
                                      localPeak=round(max(vertex.co.z for vertex in mesh.vertices),3))
    if ob.name=='SC_R_CaveRefuge':
        assert count<=140
        assert all(abs(v.co.x)<=6.001 and abs(v.co.y)<=5.001 and 0<=v.co.z<=10.001 for v in mesh.vertices)
        tree=BVHTree.FromPolygons([v.co for v in mesh.vertices],[tuple(face.vertices) for face in mesh.polygons])
        for x in (-5.5,0,5.5):
            for y in (-4.5,0,4.5):
                hit=tree.ray_cast(Vector((x,y,12)),Vector((0,0,-1)),20)[0]
                assert hit is not None and abs(hit.z-10)<.001,'cave refuge crown is not flat'
    verified.append(dict(id=ob.name,triangles=count,materials=len(mesh.materials)))
assert len(verified)==len(rows) and sum(row['triangles'] for row in verified)<=10000
report=dict(build=BUILD,method='Blender 5.2 FBX re-import, evaluated triangle and face-normal checks',
            meshes=verified,uniqueTriangles=sum(row['triangles'] for row in verified),
            normals='Changed hull, cave, beacon and shore faces have nonzero area and unit normals; all shore faces point upward.',
            waveOutwardNormals=wave_directional_normals,files={})
for filename in ('build_revision.py','ShipwreckCove_Revision13.blend','ShipwreckCove_Revision13.fbx','manifest13.json','palette.png'):
    raw=(ROOT/filename).read_bytes()
    report['files'][filename]=dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
(ROOT/'export-verification13.json').write_text(json.dumps(report,indent=2))
print('FBX re-import verified',report['uniqueTriangles'],'triangles')

layout=json.loads((ROOT/'layout.json').read_text())
assert [tuple(point) for point in layout['paths']['S03']]==ridge_route,'S03 route changed since ridge authoring'
ridge_mesh=bpy.data.objects['SC_R_HeadlandRidge'].data
assert all(face.area>1e-5 and face.normal.length>.99 for face in ridge_mesh.polygons)
ridge_tree=BVHTree.FromPolygons([v.co for v in ridge_mesh.vertices],
                                [tuple(face.vertices) for face in ridge_mesh.polygons])
cube_faces=((0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5))
overlaps=[]
for surface in layout['surfaces']:
    if surface['section']!='S03' or not surface['name'].startswith('S03_'):continue
    x,top,z=surface['p'];w,h,d=surface['size']
    center=Vector((x,-z,top-h/2))
    verts=[center+Vector((i*w/2,j*d/2,k*h/2))
           for k in (-1,1) for j in (-1,1) for i in (-1,1)]
    collider=BVHTree.FromPolygons(verts,cube_faces)
    pairs=ridge_tree.overlap(collider)
    if pairs:
        overlaps.append(surface['name'])
        print('RIDGE_OVERLAP',surface['name'],[(pair[0],
              [[round(ridge_mesh.vertices[index].co.x,1),round(ridge_mesh.vertices[index].co.z,1),
                round(-ridge_mesh.vertices[index].co.y,1)] for index in ridge_mesh.polygons[pair[0]].vertices])
              for pair in pairs[:3]])
assert not overlaps,('ridge crosses walking boxes',overlaps)

corridor_clearance=[]
body_clearance=[]
head_clearance=[]
closest_corridor=None
for a,b in zip(ridge_route,ridge_route[1:]):
    dx=b[0]-a[0];dz=b[2]-a[2];distance=math.hypot(dx,dz)
    samples=max(1,math.ceil(distance/.5))
    for step in range(samples+1):
        t=step/samples
        x=a[0]+dx*t;z=a[2]+dz*t;floor=a[1]+(b[1]-a[1])*t
        for offset in (-5,-3,0,3,5):
            point=Vector((x-offset*dz/distance,-(z+offset*dx/distance),floor+.5))
            nearest=ridge_tree.find_nearest(point,10)
            if nearest[0] is not None:
                corridor_clearance.append(nearest[3])
                if closest_corridor is None or nearest[3]<closest_corridor[0]:
                    closest_corridor=(nearest[3],(round(point.x,2),round(point.z,2),round(-point.y,2)),
                                      (round(nearest[0].x,2),round(nearest[0].z,2),round(-nearest[0].y,2)))
            for height,bucket in ((3,body_clearance),(6,head_clearance)):
                p=point.copy();p.z=floor+height
                hit=ridge_tree.find_nearest(p,10)
                if hit[0] is not None:bucket.append(hit[3])
assert min(corridor_clearance)>=2,('ridge too close to jump corridor',closest_corridor)
assert min(body_clearance)>=2,('ridge too close to body corridor',min(body_clearance))
assert min(head_clearance)>=2,('ridge too close to head corridor',min(head_clearance))

grounding=[]
for i,(x,top,z) in enumerate(ridge_route):
    hit=ridge_tree.ray_cast(Vector((x,-z,top+.1)),Vector((0,0,-1)),100)[0]
    grounding.append(dict(node=i,routeTop=top,ridgeTop=round(hit.z,2) if hit else None,
                          gap=round(top-hit.z,2) if hit else None))
assert all(row['ridgeTop'] is not None for row in grounding)
ledge_undersides=[]
for index,(x,top,z) in enumerate(ridge_route):
    if index in (3,7):continue
    for ox in (-3.5,0,3.5):
        for oz in (-3.5,0,3.5):
            hit=ridge_tree.ray_cast(Vector((x+ox,-(z+oz),top-2)),Vector((0,0,-1)),100)[0]
            gap=top-3-hit.z if hit else None
            ledge_undersides.append(dict(node=index,offset=[ox,oz],
                                         gap=round(gap,3) if gap is not None else None))
assert all(row['gap'] is not None and row['gap']<=.2 for row in ledge_undersides),\
    ('unsupported ledge underside',[row for row in ledge_undersides if row['gap'] is None or row['gap']>.2])
assert all(grounding[i]['gap']>=13 for i in (3,7)),'timber spans no longer open'
raised_distances=[]
for vertex in ridge_mesh.vertices:
    x,z,level=vertex.co.x,-vertex.co.y,vertex.co.z
    nearest_distance=float('inf');nearest_route_height=None
    for a,b in zip(ridge_route,ridge_route[1:]):
        dx=b[0]-a[0];dz=b[2]-a[2]
        t=max(0,min(1,((x-a[0])*dx+(z-a[2])*dz)/(dx*dx+dz*dz)))
        distance=math.hypot(x-(a[0]+dx*t),z-(a[2]+dz*t))
        if distance<nearest_distance:
            nearest_distance=distance
            nearest_route_height=a[1]+(b[1]-a[1])*t
    if level>nearest_route_height+.5:raised_distances.append(nearest_distance)
assert min(raised_distances)>=8,('raised ridge too close to route',min(raised_distances))
fit=dict(build=BUILD,routeBuild=layout['build'],visual='SC_R_HeadlandRidge',
         walkingBoxIntersections=overlaps,corridorSamples=len(corridor_clearance),
         minimumCorridorClearance=round(min(corridor_clearance),2),
         minimumBodyClearance=round(min(body_clearance),2),
         minimumHeadClearance=round(min(head_clearance),2),
         minimumRaisedVertexDistanceFromRoute=round(min(raised_distances),2),
         grounding=grounding,ledgeUndersides=ledge_undersides)

def route_visual_scan(points,asset_ids):
    placed=[]
    for place in layout['placements']:
        if place['asset'] not in asset_ids:continue
        ob=bpy.data.objects[place['asset']]
        x,y,z=place['p'];sx,sy,sz=place['scale']
        rotation=Euler((math.radians(place.get('pitch',0)),0,math.radians(place['yaw'])),'XYZ')
        transform=(Matrix.Translation(Vector((x,-z,y))) @ rotation.to_matrix().to_4x4()
                   @ Matrix.Diagonal((sx,sz,sy,1)))
        tree=BVHTree.FromPolygons([transform @ v.co for v in ob.data.vertices],
                                  [tuple(p.vertices) for p in ob.data.polygons])
        placed.append((place['name'],tree))
    nearest={height:(float('inf'),None) for height in (.5,3,6)}
    for a,b in zip(points,points[1:]):
        steps=max(1,math.ceil(math.hypot(b[0]-a[0],b[2]-a[2])))
        for step in range(steps+1):
            t=step/steps
            x=a[0]+(b[0]-a[0])*t;y=a[1]+(b[1]-a[1])*t;z=a[2]+(b[2]-a[2])*t
            for height in nearest:
                point=Vector((x,-z,y+height))
                for name,tree in placed:
                    hit=tree.find_nearest(point,100)
                    if hit[0] is not None and hit[3]<nearest[height][0]:
                        nearest[height]=(hit[3],dict(route=[round(x,2),round(y+height,2),round(z,2)],
                                                      asset=name,meshPoint=[round(hit[0].x,2),
                                                      round(hit[0].z,2),round(-hit[0].y,2)]))
    assert all(value[0]>=2 for value in nearest.values()),('visual mesh too close to route',nearest)
    return {str(height):dict(clearance=round(value[0],2),nearest=value[1]) for height,value in nearest.items()}

fit['shipVisualRoute']=route_visual_scan([[-108,13,-66]]+layout['paths']['S02']+[[0,43,-100]],
                                        ('SC_R_HullBow','SC_R_HullMid','SC_R_HullStern'))
fit['caveVisualRoute']=route_visual_scan([[108,15,-18]]+layout['paths']['S04_Entry']+layout['paths']['H02'],
                                        ('SC_R_CaveChamber','SC_R_CaveTideBend'))
cave_roofs=[]
for place in layout['placements']:
    if place['asset'] not in ('SC_R_CaveChamber','SC_R_CaveTideBend'):continue
    ob=bpy.data.objects[place['asset']]
    x,y,z=place['p'];sx,sy,sz=place['scale']
    rotation=Euler((math.radians(place.get('pitch',0)),0,math.radians(place['yaw'])),'XYZ')
    transform=(Matrix.Translation(Vector((x,-z,y))) @ rotation.to_matrix().to_4x4()
               @ Matrix.Diagonal((sx,sz,sy,1)))
    cave_roofs.append((place['name'],BVHTree.FromPolygons(
        [transform @ vertex.co for vertex in ob.data.vertices],
        [tuple(face.vertices) for face in ob.data.polygons])))
roof_samples=[]
for x,floor,z in layout['paths']['S04_Entry'][1:]+layout['paths']['H02']:
    hits=[]
    for name,tree in cave_roofs:
        hit=tree.ray_cast(Vector((x,-z,floor+6)),Vector((0,0,1)),60)[0]
        if hit is not None:hits.append((hit.z,name))
    height,name=min(hits) if hits else (None,None)
    roof_samples.append(dict(point=[x,floor,z],roof=round(height,2) if height is not None else None,
                             headroom=round(height-floor,2) if height is not None else None,
                             chamber=name))
assert all(item['headroom'] is not None and item['headroom']>=18.8 for item in roof_samples),\
    ('cave roof missing or too low',roof_samples)
fit['caveRoofSamples']=roof_samples

def local_visual_scan(points,asset_name):
    mesh=bpy.data.objects[asset_name].data
    tree=BVHTree.FromPolygons([v.co for v in mesh.vertices],
                              [tuple(face.vertices) for face in mesh.polygons])
    nearest={height:(float('inf'),None) for height in (.5,3,6)}
    for a,b in zip(points,points[1:]):
        steps=max(1,math.ceil(math.hypot(b[0]-a[0],b[2]-a[2])))
        for step in range(steps+1):
            t=step/steps
            x=a[0]+(b[0]-a[0])*t;y=a[1]+(b[1]-a[1])*t;z=a[2]+(b[2]-a[2])*t
            for height in nearest:
                hit=tree.find_nearest(Vector((x,-z,y+height)),100)
                if hit[0] is not None and hit[3]<nearest[height][0]:
                    nearest[height]=(hit[3],[round(x,2),round(y+height,2),round(z,2)])
    assert all(v[0]>=2 for v in nearest.values()),('course-local visual crosses route',asset_name,nearest)
    return {str(k):dict(clearance=round(v[0],2),route=v[1]) for k,v in nearest.items()}

fit['underbodyMainRoute']=local_visual_scan([[-108,13,-66]]+layout['paths']['S02']+[[0,43,-100]],
                                          'SC_R_GroundedHullUnderbody')
fit['underbodyRibRoute']=local_visual_scan(layout['paths']['X01'],'SC_R_GroundedHullUnderbody')
bank_mesh=bpy.data.objects['SC_R_ShoreBank'].data
bank_tree=BVHTree.FromPolygons([v.co for v in bank_mesh.vertices],
                               [tuple(face.vertices) for face in bank_mesh.polygons])
shore_crest=[]
for index,p in enumerate(layout['paths']['S04_Shore']):
    previous=layout['paths']['S04_Shore'][max(0,index-1)]
    following=layout['paths']['S04_Shore'][min(len(layout['paths']['S04_Shore'])-1,index+1)]
    dx,dz=following[0]-previous[0],following[2]-previous[2]
    length=math.hypot(dx,dz);normal=(dz/length,-dx/length)
    for offset in (-5,0,5):
        x=p[0]+normal[0]*offset;z=p[2]+normal[1]*offset
        hit=bank_tree.ray_cast(Vector((x,-z,20)),Vector((0,0,-1)),40)[0]
        shore_crest.append(dict(node=index,offset=offset,height=round(hit.z,3) if hit else None))
for index,(a,b) in enumerate(zip(layout['paths']['S04_Shore'],layout['paths']['S04_Shore'][1:])):
    dx,dz=b[0]-a[0],b[2]-a[2];length=math.hypot(dx,dz);normal=(dz/length,-dx/length)
    for offset in (-5,0,5):
        x=(a[0]+b[0])/2+normal[0]*offset
        z=(a[2]+b[2])/2+normal[1]*offset
        hit=bank_tree.ray_cast(Vector((x,-z,20)),Vector((0,0,-1)),40)[0]
        shore_crest.append(dict(segment=index,offset=offset,height=round(hit.z,3) if hit else None))
assert all(row['height'] is not None and abs(row['height']-8)<.03 for row in shore_crest),\
    ('continuous shore crest is not flat and supported',shore_crest)
fit['shoreCrestSamples']=shore_crest
shore_collider_support=[]
for surface in layout['surfaces']:
    if surface['section']!='S04_Shore':continue
    x,top,z=surface['p'];width,_,depth=surface['size']
    yaw=math.radians(surface.get('yaw',0));c,s=math.cos(yaw),math.sin(yaw)
    for ox in (-width/2+.1,0,width/2-.1):
        for oz in (-depth/2+.1,0,depth/2-.1):
            px=x+c*ox+s*oz;pz=z-s*ox+c*oz
            hit=bank_tree.ray_cast(Vector((px,-pz,20)),Vector((0,0,-1)),40)[0]
            shore_collider_support.append(dict(name=surface['name'],offset=[ox,oz],
                height=round(hit.z,3) if hit else None))
assert all(row['height'] is not None and abs(row['height']-8)<.15 for row in shore_collider_support),\
    ('shore collider lacks flat visual support',shore_collider_support)
fit['shoreColliderSupport']=shore_collider_support
fit['ribAnchorClearances']=rib_anchors
(ROOT/'headland-fit13.json').write_text(json.dumps(fit,indent=2))
print('Headland fit',json.dumps({k:v for k,v in fit.items() if k not in ('grounding','ledgeUndersides')}))
