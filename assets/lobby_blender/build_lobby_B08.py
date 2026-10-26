"""Build the Blender-authored lobby and its Studio-editable components."""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
REV = 'B08'
random.seed(907)
scene = bpy.data.scenes.new('Skycourt_' + REV)
bpy.context.window.scene = scene
COLORS = {
    'Stone': (.79,.70,.53), 'Cream': (.95,.86,.67), 'Pale': (.99,.94,.80),
    'Seam': (.48,.44,.35), 'Tile': (.81,.77,.67), 'FloorA': (.85,.81,.70), 'FloorB': (.83,.79,.68), 'Blue': (.025,.32,.49),
    'DeepBlue': (.045,.12,.17), 'Gold': (.88,.58,.16), 'Silver': (.55,.65,.70),
    'Bronze': (.61,.31,.13), 'Fire': (1,.36,.04), 'Flame': (1,.82,.28), 'Glow': (.12,.75,.98), 'Lamp': (1,.68,.21),
    'Wood': (.30,.16,.065), 'Soil': (.19,.17,.095), 'Leaf': (.17,.36,.055),
    'LeafLight': (.38,.58,.08), 'LeafDark': (.075,.23,.065), 'Flower': (.96,.71,.20),
}
MATS = {}
for name,col in COLORS.items():
    m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); MATS[name]=m
groups={}; zone='Foundation'; owner=None; components={}; component_counts={}

class OwnedList(list):
    def __init__(self):
        super().__init__(); self.owners=[]
    def append(self, value):
        self.owners.append(owner or zone); super().append(value)

collision=OwnedList();lights=OwnedList();tags=[];seats=OwnedList()

def component(name, floor, pivot):
    global owner
    owner=name
    components[name]={'floor':floor,'pivot':pivot}

def editable(fn):
    def wrapped(*args,**kwargs):
        global owner
        if owner is not None:return fn(*args,**kwargs)
        key=zone+'_'+fn.__name__.title()
        component_counts[key]=component_counts.get(key,0)+1
        x,y,z=args[:3]
        component(key+f'_{component_counts[key]:02d}', 'Lower' if z<10 else 'Arrival' if z<30 else 'Shops' if z<50 else 'Podium', [x,y,z])
        try:return fn(*args,**kwargs)
        finally:owner=None
    return wrapped

def geo(mat,vs,fs):
    key=(owner or zone,mat); chunks=groups.setdefault(key,[])
    if not chunks or len(chunks[-1][1])+len(fs)>4500: chunks.append(([],[]))
    v,f=chunks[-1]; n=len(v); v.extend(vs); f.extend(tuple(n+i for i in face) for face in fs)

def box(mat,c,s,b=.08,collide=False):
    x,y,z=c; a,d,h=[q/2 for q in s]; b=min(b,a*.3,d*.3,h*.3)
    rings=[]
    for zz,aa,dd in [(-h,a-b,d-b),(-h+b,a,d),(h-b,a,d),(h,a-b,d-b)]:
        k=min(b,aa*.3,dd*.3)
        rings.extend([(x+u,y+v,z+zz) for u,v in [(-aa+k,-dd),(aa-k,-dd),(aa,-dd+k),(aa,dd-k),(aa-k,dd),(-aa+k,dd),(-aa,dd-k),(-aa,-dd+k)]])
    faces=[tuple(reversed(range(8))),tuple(range(24,32))]
    for r in range(3):
        for j in range(8): faces.append((r*8+j,r*8+(j+1)%8,(r+1)*8+(j+1)%8,(r+1)*8+j))
    geo(mat,rings,faces)
    if collide: collision.append({'p':c,'s':s,'kind':'box'})

def lathe(mat,x,y,z,profile,n=20):
    vs=[(x+r*math.cos(i*math.tau/n),y+r*math.sin(i*math.tau/n),z+h) for r,h in profile for i in range(n)]
    fs=[tuple(reversed(range(n))),tuple(range((len(profile)-1)*n,len(profile)*n))]
    for j in range(len(profile)-1):
        for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    geo(mat,vs,fs)

def rod(mat,a,b,r=.12,n=8):
    a,b=Vector(a),Vector(b); direction=(b-a).normalized(); u=direction.cross(Vector((0,0,1)))
    if u.length<.01:u=direction.cross(Vector((0,1,0)))
    u.normalize(); v=direction.cross(u)
    vs=[tuple(p+r*(u*math.cos(i*math.tau/n)+v*math.sin(i*math.tau/n))) for p in [a,b] for i in range(n)]
    fs=[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    geo(mat,vs,fs)

def leafball(mat,p,s,seed=0):
    x,y,z=p; sx,sy,sz=s; n=9; vs=[(x,y,z-sz)]
    for h,r in [(-.65,.67),(0,1),(.6,.74)]:
        for j in range(n):
            a=j*math.tau/n+seed; q=1+random.uniform(-.14,.14)
            vs.append((x+sx*r*math.cos(a)*q,y+sy*r*math.sin(a)*q,z+sz*h))
    vs.append((x,y,z+sz)); fs=[]
    for j in range(n):fs.append((0,1+(j+1)%n,1+j))
    for k in range(2):
        for j in range(n):fs.append((1+k*n+j,1+k*n+(j+1)%n,1+(k+1)*n+(j+1)%n,1+(k+1)*n+j))
    for j in range(n):fs.append((1+2*n+j,1+2*n+(j+1)%n,len(vs)-1))
    geo(mat,vs,fs)

def text(body,x,y,z,size=2,mat='Pale'):
    curve=bpy.data.curves.new('Lettering','FONT'); curve.body=body; curve.align_x='CENTER'; curve.align_y='CENTER'; curve.size=size; curve.extrude=.025; curve.bevel_depth=.006; curve.resolution_u=3
    o=bpy.data.objects.new('Letters',curve); scene.collection.objects.link(o); o.location=(x,y,z); o.rotation_euler=(math.pi/2,0,0)
    bpy.context.view_layer.objects.active=o; o.select_set(True); bpy.ops.object.convert(target='MESH'); o=bpy.context.object
    geo(mat,[tuple(o.matrix_world@v.co) for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons]); bpy.data.objects.remove(o,do_unlink=True)

def plaque(body,x,y,z,w,size=2):
    box('Gold',(x,y,z),(w+.35,.42,3.1),.09)
    box('DeepBlue',(x,y-.25,z),(w,.22,2.75),.07)
    text(body,x,y-.39,z,size)

def tiles(x,y,z,w,d):
    nx=max(1,round(w/4)); ny=max(1,round(d/4)); sx=w/nx; sy=d/ny
    for i in range(nx):
        for j in range(ny):box(random.choice(['Tile','FloorA','FloorB']),(x-w/2+(i+.5)*sx,y-d/2+(j+.5)*sy,z-.10),(sx-.065,sy-.065,.20),.035)

@editable
def slab(x,y,z,w,d):
    box('Stone',(x,y,z-1.1),(w,d,2.2),.27,True)
    box('Cream',(x,y,z-.25),(w+.55,d+.55,.55),.12)
    tiles(x,y,z+.03,w-.5,d-.5)
    for xx in [x-w/2,x+w/2]:box('Pale',(xx,y,z-.05),(.75,d+.7,.45),.08)
    for yy in [y-d/2,y+d/2]:box('Pale',(x,yy,z-.05),(w+.7,.75,.45),.08)
    # Offset masonry joints on the exposed fascia.
    n=max(1,round(w/4))
    for i in range(n):box('Cream',(x-w/2+(i+.5)*w/n,y-d/2-.02,z-1.2),(w/n-.09,.25,1.25),.06)

@editable
def pier(x,y,z):
    box('Cream',(x,y,z-2),(6,6,2.8),.25)
    lathe('Stone',x,y,z-6,[(1.2,0),(2.3,1),(2.6,3.5),(3.2,4.3)],8)
    lathe('Glow',x,y,z-4.1,[(2.62,0),(2.62,.27)],8)
    lathe('DeepBlue',x,y,z-7,[(.75,0),(1.3,1)],8)
    lathe('Glow',x,y,z-11,[(.05,0),(.8,2.6),(.65,3.8)],5)

def planter(x,y,z,w=4,d=4):
    if w==d and int(abs(x+y))%3==1:
        r=w*.5
        lathe('Stone',x,y,z,[(r*.75,0),(r*.9,.25),(r,1.5),(r*1.08,1.7),(r*1.08,1.9),(r*.87,1.9)],12)
        lathe('Soil',x,y,z+1.75,[(r*.86,0),(r*.86,.08)],12)
        collision.append({'p':[x,y,z+.9],'s':[w*.9,d*.9,1.8],'kind':'box'})
        return
    box('Stone',(x,y,z+.85),(w,d,1.7),.15,True)
    box('Pale',(x,y,z+1.6),(w+.35,d+.35,.45),.09)
    box('Soil',(x,y,z+1.85),(w-.35,d-.35,.1),.02)

def bush(x,y,z,s=1.4,flowers=False):
    for i in range(5):
        a=i*2.4; r=s*.4
        leafball(['Leaf','LeafLight','LeafDark'][i%3],(x+math.cos(a)*r,y+math.sin(a)*r,z+s*.55+random.random()*.4),(s*.6,s*.55,s*.65),a)
    if flowers:
        for i in range(4):
            a=i*2.2; px=x+math.cos(a)*s*.5; py=y+math.sin(a)*s*.5
            rod('LeafDark',(px,py,z),(px,py,z+s*1.4),.05,5)
            leafball('Flower',(px,py,z+s*1.4),(.24,.24,.17))

@editable
def tree(x,y,z,h=10,seed=0):
    planter(x,y,z,4.5,4.5); base=z+1.8
    variant=int(seed*10)%3
    spread=.70 if variant==1 else 1.1 if variant==2 else 1
    lean=1.0 if variant==2 else 0
    rod('Wood',(x,y,base),(x+.3,y,base+h*.72),.4,9)
    for i in range(5):
        a=i*2.4+seed; bx=x+lean+math.cos(a)*h*.19*spread; by=y+math.sin(a)*h*.18*spread; bz=base+h*(.57+.08*(i%2))
        rod('Wood',(x,y,base+h*.35),(bx,by,bz),.18,7)
        leafball(['Leaf','LeafLight','LeafDark'][i%3],(bx,by,bz+h*.1),(h*.29*spread,h*.27*spread,h*.24*(1.2 if variant==1 else 1)),a)
        leafball(['LeafLight','Leaf'][i%2],(bx+.4,by-.3,bz+h*.19),(h*.16,h*.17,h*.17),a+.3)
    bush(x,y,base,1.4)

def vine(x,y,z,length=6):
    points=[]
    for i in range(int(length*2)+1):points.append((x+math.sin(i*.62)*.35,y-.15,z-i*.5))
    for a,b in zip(points,points[1:]):rod('LeafDark',a,b,.055,5)
    for i,(xx,yy,zz) in enumerate(points):
        side=(-1)**i; leafball('LeafLight' if i%3==0 else 'Leaf',(xx+side*.3,yy-.08,zz),(.45,.18,.32),i*.3)

def lantern(x,y,z,post=True):
    if post:box('Stone',(x,y,z+.35),(1.65,1.65,.7),.13)
    base=z+.7
    box('DeepBlue',(x,y,base+.13),(1.22,1.22,.26),.04)
    box('Lamp',(x,y,base+1.1),(.77,.77,1.6),.04)
    for dx in [-.51,.51]:
        for dy in [-.51,.51]:rod('Gold',(x+dx,y+dy,base),(x+dx,y+dy,base+2),.085,6)
    lathe('Gold',x,y,base+1.9,[(.86,0),(.88,.15),(.36,.7),(.13,.8)],4)
    lights.append([x,y,base+1.1])

def banner(x,y,z,w=4,h=10):
    rod('Gold',(x-w/2-.4,y,z+.2),(x+w/2+.4,y,z+.2),.15,10)
    # A shallow billow and pointed hem, modeled cloth rather than a flat Roblox slab.
    vs=[]; rows=8
    for j in range(rows+1):
        t=j/rows
        for u in [-.5,0,.5]:vs.append((x+u*w,y-.2-math.sin(t*math.pi)*.32,z-h*t+(abs(u)*1.6 if j==rows else 0)))
    fs=[]
    for j in range(rows):
        for i in range(2):fs.append((j*3+i,j*3+i+1,(j+1)*3+i+1,(j+1)*3+i))
    geo('Blue',vs,fs); geo('Blue',[(a,b+.07,c) for a,b,c in vs],[tuple(reversed(f)) for f in fs])
    for side in [-1,1]:
        pts=[(x+side*w*.46,y-.23-math.sin(j/rows*math.pi)*.32,z-h*j/rows+(.75 if j==rows else 0)) for j in range(rows+1)]
        for a,b in zip(pts,pts[1:]):rod('Gold',a,b,.055,6)
        rod('Gold',pts[-1],(x,y-.25,z-h),.055,6)
    cy=y-.65; cz=z-h*.45
    for i in range(24):
        a=i*math.tau/24;b=(i+1)*math.tau/24
        rod('Pale',(x+math.cos(a)*w*.24,cy,cz+math.sin(a)*w*.24),(x+math.cos(b)*w*.24,cy,cz+math.sin(b)*w*.24),.04,5)
    for a in range(4):
        t=a*math.pi/2
        geo('Pale',[(x+math.sin(t)*w*.38,cy-.02,cz+math.cos(t)*w*.38),(x+math.cos(t)*w*.065,cy-.03,cz-math.sin(t)*w*.065),(x-math.cos(t)*w*.065,cy-.03,cz+math.sin(t)*w*.065)],[(0,1,2)])

def column(x,y,z,h):
    box('Pale',(x,y,z+.4),(2.7,2.7,.8),.12,True)
    box('Cream',(x,y,z+h/2),(1.65,1.65,h-1.2),.16,True)
    n=max(3,round(h/2))
    for j in range(n):box('Cream' if j%3 else 'Stone',(x,y,z+.65+(j+.5)*(h-1.3)/n),(1.84,1.84,(h-1.3)/n-.045),.09)
    for zz in [z+1,z+h-1]:box('Stone',(x,y,zz),(2.15,2.15,.42),.08)
    box('Pale',(x,y,z+h-.3),(2.8,2.8,.6),.10)

@editable
def opening(x,y,z,w,h):
    for xx in [x-w/2-1,x+w/2+1]:column(xx,y,z,h)
    # Chamfered portal: stone wedges follow the two upper corners.
    box('Cream',(x,y,z+h-1),(w+4,2,2),.17,True)
    for side in [-1,1]:
        vs=[(x+side*w/2,y-1,z+h-5),(x+side*w/2,y-1,z+h-1),(x+side*(w/2-4),y-1,z+h-1)]
        vs+= [(a,y+1,c) for a,_,c in vs]
        geo('Stone',vs,[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)])

@editable
def stair(x,y,z,top,length,width):
    n=math.ceil((top-z)/.65); tread=length/n; rise=(top-z)/n
    # One inset prism avoids coplanar overlaps along the stair sides.
    vs=[(xx,yy,zz) for xx in [x-width/2+.08,x+width/2-.08] for yy,zz in [(y,z-.1),(y+length,z-.1),(y+length,top-.02)]]
    geo('Stone',vs,[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)])
    for i in range(n):
        yy=y+(i+.5)*tread; zz=z+(i+1)*rise
        box('Stone',(x,yy,zz-rise/2),(width,tread,rise),.015)
        box('Pale',(x,yy-.08,zz-.06),(width+.16,tread+.12,.16),.035)
        collision.append({'p':[x,yy,(z+zz)/2-.1],'s':[width,tread+.06,zz-z+.2],'kind':'box'})
    for side in [-1,1]:
        xx=x+side*(width/2+.45)
        for i in range(n):box('Cream',(xx,y+(i+.5)*tread,z+(i+1)*rise+1.45),(.85,tread+.1,2.9),.04,True)
        rod('Pale',(xx,y,z+3),(xx,y+length,top+3),.20,8)
        for yy,zz in [(y,z),(y+length,top)]:
            box('Cream',(xx,yy,zz+1.5),(1.7,1.7,3),.13,True);lantern(xx,yy,zz+3)

@editable
def rail(x,y,z,w):
    box('Stone',(x,y,z+.45),(w,.75,.9),.08,True)
    for xx in [x-w/2,x+w/2]:box('Cream',(xx,y,z+1.7),(1.2,1.2,3.4),.12,True)
    rod('Gold',(x-w/2,y,z+3),(x+w/2,y,z+3),.11)
    for i in range(max(2,int(w/1.5))):
        xx=x-w/2+(i+.5)*w/max(2,int(w/1.5));rod('DeepBlue',(xx,y,z+.8),(xx,y,z+2.9),.06,6)
    collision.append({'p':[x,y,z+1.8],'s':[w,.6,3.6],'kind':'box'})

# A deep public forecourt steps back toward a closed champion monument.
zone='Lower';slab(0,6,0,120,110)
zone='Arrival';slab(-31,19,18,46,86);slab(31,19,18,46,86);slab(0,25,18,16,74)
zone='Shops';slab(0,33,38,61,56);slab(-38,38,38,15,48);slab(38,38,38,15,48)
zone='Roof';slab(0,43,56,61,36)
zone='Stairs';stair(0,-34,0,18,22,12)
for x in [-37,37]:stair(x,-15,18,38,28,9)
for name,z,points in [('Lower',0,[(-53,-42),(53,-42),(-53,53),(53,53),(0,-46)]),('Arrival',18,[(-49,-17),(49,-17),(-48,53),(48,53)]),('Shops',38,[(-40,18),(40,18)])]:
    zone=name
    for x,y in points:pier(x,y,z)

zone='Practice';opening(0,8,18,46,20)
box('Stone',(0,53,27.5),(52,1.8,19),.17,True)
for x in [-26,26]:box('Stone',(x,32,27.5),(1.8,42,19),.15,True)
plaque('PRACTICE',0,4.25,35.8,27,2.2)
for x in [-29,29]:banner(x,6.7,36,4.1,12)
practice=[(-17,16,19.2,5),(-16,23,20.3,4.4),(-12,29,21.3,4.5),(-5,32,22.2,4.6),(3,32,22.8,4.6),(10,29,21.8,4.6),(16,23,20.5,4.6),(17,16,19.2,5)]
for i,(x,y,z,w) in enumerate(practice):
    box('DeepBlue',(x,y,18+(z-18)/2),(w,w,z-18),.18,True)
    box('Gold',(x,y,z-.08),(w+.15,w+.15,.28),.07)
    box('LeafLight' if i==0 else 'Gold' if i==7 else 'Blue',(x,y,z+.1),(w-.3,w-.3,.12),.08)
    text(str(i+1),x,y-w/2-.11,z-.65,.65)
text('START',-17,13.35,18.65,.65);text('FINISH',17,13.35,18.65,.6)
tags.append({'kind':'practice','points':practice})
zone='Spawn';lathe('Gold',0,-3,18.05,[(5.5,0),(5.5,.10)],48);lathe('Blue',0,-3,18.16,[(4.95,0),(4.95,.08)],48)
for i in range(8):
    a=i*math.pi/4;r=4.5 if i%2==0 else 3
    geo('Pale',[(math.sin(a)*r,-3+math.cos(a)*r,18.27),(math.sin(a+.6)*.9,-3+math.cos(a+.6)*.9,18.27),(math.sin(a-.6)*.9,-3+math.cos(a-.6)*.9,18.27)],[(0,1,2)])

zone='ShopRoom';opening(0,27,38,42,18)
box('Stone',(0,59.5,46.5),(46,1.5,17),.14,True)
for x in [-24,24]:box('Stone',(x,44,46.5),(1.6,32,17),.13,True)
plaque('SHOPS',0,24.2,53,26,2.2)
for x in [-24,24]:banner(x,25.4,54.2,3.8,10)
for x,name in [(-14,'STYLE'),(0,'TRAILS'),(14,'GEAR')]:
    box('Wood',(x,51,40.1),(9,3,4.2),.18,True);box('Cream',(x,51,42.3),(9.4,3.4,.4),.1)
    box('Gold',(x,49.42,40.2),(7,.12,2.2),.05);box('Wood',(x,49.31,40.2),(6.7,.13,1.9),.03)
    plaque(name,x,58,47,10,1.1)
    for j in range(3):lathe('Gold' if j%2 else 'Blue',x-2+j*2,51,42.5,[(.4,0),(.55,.6),(.2,1.4)],8)
    lantern(x,57,50,False)

# Wall panels, skirting, pilasters and ceiling beams give both rooms depth.
zone='RoomDetails'
for half,y0,y1,z,h in [(25,11,52,18,19),(23,29,58,38,17)]:
    for side in [-1,1]:
        x=side*half
        for zz in [z+.7,z+5,z+h-1]:box('Cream',(x,(y0+y1)/2,zz),(.55,y1-y0,.6),.06)
        for y in range(y0+4,y1-2,10):
            box('DeepBlue',(x-side*.14,y,z+10),(.2,7,7),.07)
            for yy in [y-3.6,y+3.6]:box('Cream',(x-side*.3,yy,z+10),(.45,.45,8),.06)
            for zz in [z+6.1,z+13.9]:box('Gold',(x-side*.4,y,zz),(.22,7.4,.16),.02)
            box('Cream',(x-side*.1,y+4.3,z+h/2),(.8,.75,h-1),.09)
    for y in range(y0+3,y1,12):box('Wood',(0,y,z+h-.45),(half*2,.5,.6),.06)
    box('Cream',(0,y1,z+1.1),(half*2,1,2.2),.08)
zone='RoomInsets'
for x in [-17,0,17]:
    y=51.9;z=21;r=4.3;h=12
    outline=[(x-r,y,z),(x+r,y,z),(x+r,y,z+h-r)]
    for i in range(1,13):
        a=i*math.pi/12;outline.append((x+r*math.cos(a),y,z+h-r+r*math.sin(a)))
    geo('DeepBlue',outline,[tuple(range(len(outline)))])
    for side in [-1,1]:box('Cream',(x+side*(r+.3),y-.08,z+(h-r)/2),(.6,.5,h-r),.07)
    for i in range(12):
        a=i*math.pi/12;b=(i+1)*math.pi/12
        ring=[(x+rr*math.cos(t),yy,z+h-r+rr*math.sin(t)) for yy in [y-.33,y+.1] for rr,t in [(r,a),(r,b),(r+.6,b),(r+.6,a)]]
        geo('Cream' if i%3 else 'Stone',ring,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
    text('JUMP' if x<0 else 'FLOW' if x==0 else 'LAND',x,y-.4,z+6,1.2)
    lantern(x,50.8,31,False)

zone='Monument'
for x,h,mat,num in [(-19,17,'Silver','2'),(0,25,'Gold','1'),(19,13,'Bronze','3')]:
    box('Stone',(x,43,57),(18,17,2),.24,True)
    box(mat,(x,43,58+h/2),(17,15,h),.32,True)
    box('Pale',(x,43,58+h),(18,16,.6),.15)
    text(num,x,35.35,62,5.5)
    for dx in [-7,7]:box('Cream',(x+dx,35.36,58+h/2),(.45,.3,h-1),.06)
    # Winner avatars stand above these markers; the trophy sits at each outer shoulder.
    tags.append({'kind':'podium','rank':num,'p':[x,43,58+h+.4],'scale':2.8 if num=='1' else 2.3,'panel':[x,35.2,58+h*.56]})
    q=2.5 if num=='1' else 2
    tx=x+(6 if x>=0 else -6)
    lathe(mat,tx,47,58+h+.3,[(r*q,hh*q) for r,hh in [(.7,0),(.7,.35),(.25,.5),(.25,1.1),(1.05,1.7),(1.3,2.7),(1.3,2.9),(1.08,2.9),(.9,1.9),(.15,1.4)]],24)
    for side in [-1,1]:
        pts=[(tx+side*(.85+.85*math.sin(t*math.pi))*q,47,58+h+(2.5-t*1.1)*q) for t in [0,.2,.4,.6,.8,1]]
        for a,b in zip(pts,pts[1:]):rod(mat,a,b,.13*q,8)
plaque('HALL OF CHAMPIONS',0,25.1,59,40,2.0)
# Only the lower rear stays enclosed; side barriers close the public routes.
zone='RearFacade'
for z,h,w in [(0,18,120)]:
    component('Lower_RearWall','Lower',[0,62,0])
    box('Stone',(0,62,z+h/2),(w,2,h),.2,True)
    for zz in [z+1,z+h-1]:box('Cream',(0,60.9,zz),(w,.5,1.3),.12)
    for x in range(-int(w/2)+4,int(w/2),12):
        box('Cream',(x,60.7,z+h/2),(1.25,.7,h-1.3),.10)
    # Rear detail is shallow, with no duplicate furnishing or lights.
    for x in [-w/2+2,w/2-2]:box('Cream',(x,63.1,z+h/2),(2,.4,h),.10)
    box('Cream',(0,63.1,z+h-.6),(w,.4,1.2),.10)
    for x in range(-int(w/2)+4,int(w/2),12):
        box('Cream',(x,63.2,z+h/2),(1,.4,h-1.4),.08)
    box('Stone',(0,63.3,z+2),(w-.8,.3,.7),.06)
    for x in [-w*.28,w*.28]:
        box('Stone',(x,63.3,z+h*.53),(w*.27,.25,h*.53),.12)
        box('Cream',(x,63.48,z+h*.53),(w*.27-.5,.16,h*.53-.5),.08)
owner=None
zone='SideBarriers'
for side in [-1,1]:
    component('Arrival_StairBackWall_'+str(side),'Arrival',[side*34.5,14,18])
    box('Stone',(side*34.5,14,28),(17,1.4,20),.14,True)
    for xx in [26.5,34.5,42.5]:box('Cream',(side*xx,13.2,28),(1,.35,19),.08)
    for zz in [19,37]:box('Cream',(side*34.5,13.15,zz),(17,.4,.8),.08)
    component('Arrival_InvisibleBarrier_'+str(side),'Arrival',[side*48.5,14,18])
    collision.append({'p':[side*48.5,14,28],'s':[13,.8,20],'kind':'barrier'})
    component('Shops_InvisibleBarrier_'+str(side),'Shops',[side*34.8,48.5,38])
    collision.append({'p':[side*34.8,48.5,47],'s':[22,.8,18],'kind':'barrier'})
owner=None
zone='SideWallTrim'
for side in [-1,1]:
    for x,y,z,h,d in [(26.95,33,18,19,36),(24.85,44,38,17,28)]:
        component('SideWallTrim_'+str(z)+'_'+str(side),'Arrival' if z==18 else 'Shops',[side*x,y,z])
        for zz in [z+1,z+h-1]:box('Cream',(side*x,y,zz),(.3,d,.7),.07)
        for yy in [y-d*.32,y+d*.32]:
            box('Cream',(side*x,yy,z+h/2),(.35,.7,h-1),.07)
        box('Cream',(side*(x+.12),y,z+h*.55),(.3,9.7,6.7),.08)
        box('DeepBlue',(side*(x+.36),y,z+h*.55),(.12,9,6),.03)
        for yy in [y-4.7,y+4.7]:box('Gold',(side*(x+.48),yy,z+h*.55),(.12,.18,6.4),.02)
        for zz in [z+h*.55-3.2,z+h*.55+3.2]:box('Gold',(side*(x+.48),y,zz),(.12,9.4,.18),.02)

owner=None
zone='Boards'
for x,title in [(-29,'MOST WINS'),(29,'BEST TIMES')]:
    component('Lower_Board_'+('Wins' if x<0 else 'Times'),'Lower',[x,25,0])
    box('Stone',(x,25,7.5),(25,2,15),.23,True)
    box('Gold',(x,23.88,8),(23,.32,12.4),.1)
    box('DeepBlue',(x,23.67,8),(22.5,.18,11.9),.05)
    text(title,x,23.55,12.8,1.4)
    for i in range(5):
        text(str(i+1)+'     - - - - - -',x,23.55,10.1-i*1.7,.85)
        box('Silver',(x,23.55,9.45-i*1.7),(19,.035,.035),.01)
    for dx in [-13,13]:column(x+dx,25,0,16)
    lantern(x,23,14,False)
owner=None
for x in [-49,49]:
    component('Lower_EntryColumn_'+str(x),'Lower',[x,8,0]);column(x,8,0,18)
component('Lower_RecordsSign','Lower',[0,7,14])
plaque('RECORDS',0,7,14,18,1.5)

owner=None
zone='Gardens'
for x,y,z,h in [(-49,-12,18,10),(49,-12,18,11),(-47,43,18,9),(47,43,18,10),(-39,40,38,9),(39,40,38,10),(-51,-39,0,10),(51,-39,0,11)]:tree(x,y,z,h,random.random()*5)
for z,coords in [(0,[(-46,15),(46,15)]),(18,[(-23,-12),(23,-12),(-48,14),(48,14)]),(38,[(-23,23),(23,23)])]:
    for i,(x,y) in enumerate(coords):
        component('Planter_'+str(z)+'_'+str(i),'Lower' if z==0 else 'Arrival' if z==18 else 'Shops',[x,y,z])
        planter(x,y,z,3.2,3.2);bush(x,y,z+1.8,1.2+(i%2)*.2,i%2==0)
owner=None
for z,y,coords in [(0,-49,[-48,48]),(18,-24,[-30,30]),(38,5,[-23,23]),(56,25,[-27,27])]:
    for x in coords:
        component('Vine_'+str(z)+'_'+str(x),'Lower' if z==0 else 'Arrival' if z==18 else 'Shops' if z==38 else 'Podium',[x,y,z])
        bush(x,y+.8,z+.1,1.1);vine(x,y,z,5)
owner=None
zone='Furniture'
for x,y,z in [(-29,-32,0),(29,-32,0),(-27,-17,18),(27,-17,18),(-14,17,38),(14,17,38)]:
    component('Bench_'+str(z)+'_'+str(x),'Lower' if z==0 else 'Arrival' if z==18 else 'Shops',[x,y,z])
    box('DeepBlue',(x,y,z+1.7),(8,2.5,.5),.14,True)
    box('Wood',(x,y+1.05,z+2.8),(8,.35,2),.12,True)
    for zz in [z+2.1,z+2.7,z+3.3]:box('Gold',(x,y+.83,zz),(7.6,.10,.05),.01)
    for dx in [-3,3]:box('Stone',(x+dx,y,z+.8),(.65,2.2,1.6),.08,True)
    for dx in [-2.1,2.1]:seats.append([x+dx,y-.15,z+2.03])
owner=None
for x,y,z in [(-48,-47,0),(48,-47,0),(-50,21,18),(50,21,18),(-42,23,38),(42,23,38)]:
    component('Lamp_'+str(z)+'_'+str(x),'Lower' if z==0 else 'Arrival' if z==18 else 'Shops',[x,y,z]);lantern(x,y,z)
owner=None

zone='Guardrails'
rail(0,-48.5,0,118)
for side in [-1,1]:
    rail(side*31,-23.4,18,45)
    # Connect front corners to every exposed side edge.
    for z,xe,y0,y1 in [(0,59,-48.5,61),(18,53.5,-23.4,61),(38,45,14,61),(56,30,25,61)]:
        x=side*xe
        component('SideGuard_'+str(z)+'_'+str(side),'Lower' if z==0 else 'Arrival' if z==18 else 'Shops' if z==38 else 'Podium',[x,(y0+y1)/2,z])
        box('Stone',(x,(y0+y1)/2,z+.45),(.75,y1-y0,.9),.08,True)
        rod('Gold',(x,y0,z+3.5),(x,y1,z+3.5),.12)
        for j in range(int((y1-y0)/1.6)+1):
            y=y0+j*(y1-y0)/int((y1-y0)/1.6)
            rod('DeepBlue',(x,y,z+.8),(x,y,z+3.5),.065,6)
        collision.append({'p':[x,(y0+y1)/2,z+2],'s':[.7,y1-y0,4],'kind':'box'})
    owner=None
    # Upper stair landing perimeter turns around the setback in the slab.
    rail(side*43.8,14,38,2.4)
    component('Shops_LandingReturn_'+str(side),'Shops',[side*30.5,9.8,38])
    box('Cream',(side*30.5,9.8,39.7),(.8,8.4,3.4),.10,True)
owner=None
rail(0,25.4,56,60)
rail(0,5.6,38,60)
# Low-floor support rhythm frames the recessed records hall.
zone='LowerHall'
for x in [-56,56]:
    component('Lower_HallWall_'+str(x),'Lower',[x,38,0])
    box('Stone',(x,38,8.5),(1.6,47,17),.12,True)
    for y in [20,37,53]:column(x,y,0,18)
for x in [-20,20]:
    component('Lower_Banner_'+str(x),'Lower',[x,8,16]);banner(x,8,16,3.5,11)
owner=None

# Four hidden calibration points preserve the Blender axes through asset import.
zone='Calibration'
for key,c in [('Origin',(0,0,0)),('Right',(10,0,0)),('Forward',(0,-10,0)),('Up',(0,0,10))]:
    oldzone=zone;zone='Marker'+key;box('DeepBlue',c,(.12,.12,.12),.01);zone=oldzone

objects=[]; meshinfo={}
for (section,mat),chunks in groups.items():
    for i,(vs,fs) in enumerate(chunks):
        name=f'{section}__{mat}__{i:02d}'
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.materials.append(MATS[mat]);mesh.update();mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles)<20000,(name,len(mesh.loop_triangles))
        obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj);objects.append(obj)
        meshinfo[name]={'triangles':len(mesh.loop_triangles),'material':mat,'section':section}
for o in scene.objects:o.select_set(False)
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/f'Skycourt_{REV}.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
manifest={'revision':REV,'colors':COLORS,'meshes':meshinfo,'colliders':collision,'lights':lights,'tags':tags,'spawn':[0,-3,18],'seats':seats,'components':components,'colliderOwners':collision.owners,'lightOwners':lights.owners,'seatOwners':seats.owners,'authorCoordinates':'X right, Y depth, Z up; units studs'}
(OUT/f'manifest_{REV}.json').write_text(json.dumps(manifest,indent=2))
def luau(value):
    if isinstance(value,dict):return '{'+','.join('['+json.dumps(k)+']='+luau(v) for k,v in value.items())+'}'
    if isinstance(value,(list,tuple)):return '{'+','.join(luau(v) for v in value)+'}'
    if isinstance(value,str):return json.dumps(value)
    return str(value).lower()
(OUT.parents[1]/'src/ServerStorage/CourseBuilders/LobbyBuilders/BlenderManifest.luau').write_text('--!strict\nreturn '+luau(manifest)+'\n')
scene.world=bpy.data.worlds.new('Sky');scene.world.color=(.40,.56,.7)
camdata=bpy.data.cameras.new('PreviewCamera');cam=bpy.data.objects.new('PreviewCamera',camdata);scene.collection.objects.link(cam);scene.camera=cam
scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.light='STUDIO';scene.display.shading.color_type='MATERIAL';scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True;scene.display.shading.cavity_type='BOTH';scene.display.shading.background_type='WORLD';scene.view_settings.view_transform='Standard'
scene.render.resolution_x=1600;scene.render.resolution_y=1400;scene.render.resolution_percentage=100
for name,pos,look in [('front',(0,-220,88),(0,12,40)),('oblique',(145,-180,125),(0,12,38))]:
    cam.location=pos;cam.rotation_euler=(Vector(look)-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=164
    scene.render.filepath=str(OUT/f'{REV}_{name}.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'Skycourt_{REV}.blend'))
print(json.dumps({'revision':REV,'meshes':len(objects),'triangles':sum(v['triangles'] for v in meshinfo.values()),'colliders':len(collision),'bytes':(OUT/f'Skycourt_{REV}.fbx').stat().st_size}))
