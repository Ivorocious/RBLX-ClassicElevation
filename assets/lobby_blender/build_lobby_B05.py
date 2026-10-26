"""Build the separate Blender-authored lobby in a fresh background process."""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
REV = 'B05'
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
groups={}; zone='Foundation'; collision=[]; lights=[]; tags=[]

def geo(mat,vs,fs):
    key=(zone,mat); chunks=groups.setdefault(key,[])
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

def slab(x,y,z,w,d):
    box('Stone',(x,y,z-1.1),(w,d,2.2),.27,True)
    box('Cream',(x,y,z-.25),(w+.55,d+.55,.55),.12)
    tiles(x,y,z+.03,w-.5,d-.5)
    for xx in [x-w/2,x+w/2]:box('Pale',(xx,y,z-.05),(.75,d+.7,.45),.08)
    for yy in [y-d/2,y+d/2]:box('Pale',(x,yy,z-.05),(w+.7,.75,.45),.08)
    # Offset masonry joints on the exposed fascia.
    n=max(1,round(w/4))
    for i in range(n):box('Cream',(x-w/2+(i+.5)*w/n,y-d/2-.02,z-1.2),(w/n-.09,.25,1.25),.06)

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

def opening(x,y,z,w,h):
    for xx in [x-w/2-1,x+w/2+1]:column(xx,y,z,h)
    # Chamfered portal: stone wedges follow the two upper corners.
    box('Cream',(x,y,z+h-1),(w+4,2,2),.17,True)
    for side in [-1,1]:
        vs=[(x+side*w/2,y-1,z+h-5),(x+side*w/2,y-1,z+h-1),(x+side*(w/2-4),y-1,z+h-1)]
        vs+= [(a,y+1,c) for a,_,c in vs]
        geo('Stone',vs,[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)])

def stair(x,y,z,top,length,width):
    n=math.ceil((top-z)/.65); tread=length/n; rise=(top-z)/n
    for i in range(n):
        yy=y+(i+.5)*tread; zz=z+(i+1)*rise
        box('Stone',(x,yy,(z+zz)/2-.1),(width,tread+.05,zz-z+.2),.04)
        box('Pale',(x,yy-.08,zz-.06),(width+.16,tread+.12,.16),.035)
        collision.append({'p':[x,yy,zz-.35],'s':[width,tread+.06,.7],'kind':'box'})
    for side in [-1,1]:
        xx=x+side*(width/2+.45)
        for i in range(n):box('Cream',(xx,y+(i+.5)*tread,z+(i+1)*rise+1.45),(.85,tread+.1,2.9),.04)
        rod('Pale',(xx,y,z+3),(xx,y+length,top+3),.20,8)
        for yy,zz in [(y,z),(y+length,top)]:
            box('Cream',(xx,yy,zz+1.5),(1.7,1.7,3),.13,True);lantern(xx,yy,zz+3)

def rail(x,y,z,w):
    box('Stone',(x,y,z+.45),(w,.75,.9),.08,True)
    for xx in [x-w/2,x+w/2]:box('Cream',(xx,y,z+1.7),(1.2,1.2,3.4),.12,True)
    rod('Gold',(x-w/2,y,z+3),(x+w/2,y,z+3),.11)
    for i in range(max(2,int(w/1.5))):
        xx=x-w/2+(i+.5)*w/max(2,int(w/1.5));rod('DeepBlue',(xx,y,z+.8),(xx,y,z+2.9),.06,6)
    collision.append({'p':[x,y,z+1.8],'s':[w,.6,3.6],'kind':'box'})

# The three main terraces narrow upward; the middle slab leaves a real stair notch.
zone='Lower'; slab(0,3,0,104,72); slab(0,-34,0,18,12); rail(0,-39.4,0,16)
zone='Arrival'; slab(-31,7,18,46,62);slab(31,7,18,46,62);slab(0,13,18,16,50)
zone='Shops';slab(0,23,38,61,36);slab(-38,26,38,15,26);slab(38,26,38,15,26)
zone='Roof';slab(0,25,56,44,31)
for side in [-1,1]:
    slab(side*31,25,56,3,31);slab(side*26,11.5,56,8,4);slab(side*26,38.5,56,8,4)
for name,z,points in [('Lower',0,[(-46,-27),(46,-27),(-46,31),(46,31),(0,-31)]),('Arrival',18,[(-49,-17),(49,-17),(-48,32),(48,32)]),('Shops',38,[(-40,18),(40,18),(0,37)])]:
    zone=name
    for x,y in points:pier(x,y,z)

zone='Stairs';stair(0,-34,0,18,22,12)
for x in [-37,37]:stair(x,-15,18,38,28,9)
# Rear rooftop stairs are visible and accessible from both shop terrace sides.
for x in [-26,26]:stair(x,19,38,56,18,6)

zone='Practice';opening(0,8,18,46,20)
box('Stone',(0,39,27.5),(52,1.8,19),.17,True)
for x in [-26,26]:box('Stone',(x,25,27.5),(1.8,28,19),.15,True)
for x in [-20,0,20]:
    box('Cream',(x,37.9,27),(1.1,.45,16),.07)
    lantern(x,37.5,28,False)
plaque('PRACTICE',0,4.25,35.8,27,2.2)
for x in [-29,29]:banner(x,6.7,36,4.1,12)
for x in [-22,22]:lantern(x,10,19,False)
# One horseshoe practice route with broad start/end pads and clear landing gaps.
practice=[(-17,16,19.2,5),(-16,23,20.3,4.4),(-12,29,21.3,4.5),(-5,32,22.2,4.6),(3,32,22.8,4.6),(10,29,21.8,4.6),(16,23,20.5,4.6),(17,16,19.2,5)]
for i,(x,y,z,w) in enumerate(practice):
    box('DeepBlue',(x,y,18.5+(z-18.5)/2),(w,w,z-18.5),.18,True)
    box('Gold',(x,y,z-.08),(w+.15,w+.15,.28),.07)
    box('LeafLight' if i==0 else 'Gold' if i==7 else 'Blue',(x,y,z+.1),(w-.3,w-.3,.12),.08)
    text(str(i+1),x,y-w/2-.11,z-.65,.65,'Pale')
text('START',-17,13.35,18.65,.65)
text('FINISH',17,13.35,18.65,.6)
tags.append({'kind':'practice','points':practice})

zone='Spawn';lathe('Gold',0,-3,18.05,[(5.5,0),(5.5,.10)],48);lathe('Blue',0,-3,18.16,[(4.95,0),(4.95,.08)],48)
for i in range(8):
    a=i*math.pi/4;r=4.5 if i%2==0 else 3
    geo('Pale',[(math.sin(a)*r,-3+math.cos(a)*r,18.27),(math.sin(a+.6)*.9,-3+math.cos(a+.6)*.9,18.27),(math.sin(a-.6)*.9,-3+math.cos(a-.6)*.9,18.27)],[(0,1,2)])

zone='ShopRoom';opening(0,10,38,36,18)
box('Stone',(0,39,46.5),(42,1.5,17),.14,True)
for x in [-21,21]:box('Stone',(x,30,46.5),(1.6,20,17),.13,True)
plaque('SHOPS',0,8.5,53.6,26,2.2)
for x in [-22,22]:banner(x,8.4,54.2,3.8,10)
for x,name in [(-12,'STYLE'),(0,'TRAILS'),(12,'GEAR')]:
    box('Wood',(x,32,40.1),(8,3,4.2),.18,True);box('Cream',(x,32,42.3),(8.4,3.4,.4),.1)
    box('Gold',(x,30.42,40.2),(6,.12,2.2),.05);box('Wood',(x,30.31,40.2),(5.7,.13,1.9),.03)
    plaque(name,x,38,47,9,1)
    for j in range(3):lathe('Gold' if j%2 else 'Blue',x-2+j*2,32,42.5,[(.4,0),(.55,.6),(.2,1.4)],8)
    lantern(x,36,48,False)

zone='Podium'
for x,y,z,w,d in [(0,27,56,28,16)]:tiles(x,y,z+.1,w,d)
for x,h,mat,num in [(-9,4.4,'Silver','2'),(0,7.2,'Gold','1'),(9,3.2,'Bronze','3')]:
    box(mat,(x,27,56+h/2),(7.5,7,h),.2,True);box('Pale',(x,27,56+h),(7.8,7.3,.25),.08)
    text(num,x,23.44,56+h/2,3.7 if num=='1' else 2.9)
    q=1.4 if num=='1' else 1.1
    lathe(mat,x,27,56+h+.13,[(r*q,h*q) for r,h in [(.7,0),(.7,.35),(.25,.5),(.25,1.1),(1.05,1.7),(1.3,2.7),(1.3,2.9),(1.08,2.9),(.9,1.9),(.15,1.4)]],24)
    for s in [-1,1]:
        pts=[(x+s*(.85+.85*math.sin(t*math.pi))*q,27,56+h+(2.5-t*1.1)*q) for t in [0,.2,.4,.6,.8,1]]
        for a,b in zip(pts,pts[1:]):rod(mat,a,b,.13,8)
    tags.append({'kind':'podium','rank':num,'p':[x,27,56+h+3.2]})
rail(0,40,56,62)
for x in [-17,17]:
    box('Stone',(x,26,57),(3,3,2),.15,True)
    lathe('Bronze',x,26,58,[(.8,0),(.55,.6),(1.4,1.1),(1.65,1.8),(1.2,1.85)],12)
    lathe('Fire',x,26,59.5,[(.85,0),(.9,.7),(.55,1.5),(.05,3.3)],7)
    lathe('Flame',x-.2,25.8,59.6,[(.45,0),(.5,.6),(.18,1.6),(.02,2.6)],6)
    lights.append([x,26,60])

zone='Boards'
for x,title in [(-26,'MOST WINS'),(26,'BEST TIMES')]:
    box('Stone',(x,-19,7),(23,2,14),.23,True)
    box('Gold',(x,-20.12,7.7),(21.4,.32,12),.1)
    box('DeepBlue',(x,-20.33,7.7),(20.9,.18,11.5),.05)
    text(title,x,-20.45,12,1.35)
    for i in range(5):
        text(str(i+1)+'     - - - - - -',x,-20.45,9.7-i*1.7,.85)
        box('Silver',(x,-20.45,9.05-i*1.7),(18,.035,.035),.01)
    for dx in [-12,12]:column(x+dx,-19,0,14)
    lantern(x-10,-20.8,11.6,False);lantern(x+10,-20.8,11.6,False)

zone='Gardens'
for x,y,z,h in [(-46,-16,18,9),(46,-16,18,10),(-47,28,18,8),(47,28,18,9),(-40,21,38,8),(40,21,38,8.8),(-16,36,56,7),(16,36,56,8),(-45,-24,0,8),(45,-24,0,9),(-45,28,0,8),(45,28,0,7.5)]:tree(x,y,z,h,random.random()*5)
for z,coords in [(0,[(-17,-26),(17,-26),(-35,-25),(35,-25),(-40,4),(40,4)]),(18,[(-20,-14),(20,-14),(-29,1),(29,1),(-48,5),(48,5)]),(38,[(-17,10),(17,10),(-10,14),(10,14)]),(56,[(-17,15),(17,15),(-30.5,23),(30.5,23)])]:
    for i,(x,y) in enumerate(coords):planter(x,y,z,3.5,3.5);bush(x,y,z+1.8,1.3+(i%3)*.2,i%2==0)
for z,coords in [(0,[(-49,-33),(-35,-33),(35,-33),(49,-33)]),(18,[(-52,-24),(-30,-24),(30,-24),(52,-24)]),(38,[(-43,13),(-29,5),(29,5),(43,13)]),(56,[(-30,9.5),(-18,9.5),(18,9.5),(30,9.5)])]:
    for i,(x,y) in enumerate(coords):bush(x,y+.8,z+.1,1.1);vine(x,y,z,length=4.5+(i%3)*1.5)

zone='Furniture'
for x,y,z in [(-27,-27,0),(27,-27,0),(-29,-17,18),(29,-17,18)]:
    box('DeepBlue',(x,y,z+1.35),(6,2.2,.65),.17,True)
    box('Blue' if x<0 else 'Wood',(x,y+.85,z+2.15),(6,.4,1.6),.17,True)
    if x>0:
        for zz in [z+1.7,z+2.2,z+2.7]:box('Gold',(x,y+.61,zz),(5.6,.12,.065),.02)
    for dx in [-2.3,2.3]:box('Stone',(x+dx,y,z+.6),(.55,1.8,1.2),.07)
for x,y,z in [(-18,-33,0),(18,-33,0),(-51,-6,18),(51,-6,18),(-29,8,38),(29,8,38),(-17,20,56),(17,20,56)]:lantern(x,y,z)
for x,z,y in [(-12,14,-20.5),(12,14,-20.5),(-48,17,-5),(48,17,-5)]:banner(x,y,z,3.5,9)
for z,y,x,w in [(0,-33,-32,25),(0,-33,32,25),(18,-24,-32,22),(18,-24,32,22),(38,5,-23,12),(38,5,23,12)]:rail(x,y,z,w)

zone='Relief'
for side in [-1,1]:
    # Side panels are modeled on the exposed stair wall, clear of the walking route.
    x=side*42.05
    for y,h in [(-7,6),(0,10),(7,14)]:
        box('Stone',(x,y,18+h/2),(.18,4.2,h),.05)
        box('Cream',(x+side*.12,y,18+h/2),(.20,3.6,h-.6),.06)
        for yy in [y-1.6,y+1.6]:rod('Gold',(x+side*.24,yy,19),(x+side*.24,yy,18+h-1),.06,6)
    for y,z in [(-7,25),(0,30),(7,35)]:
        vine(x+side*.23,y,z,3.3)
    for y in [15,25,35]:
        box('Cream',(side*27,y,27),(.25,1.2,16),.10)
        box('Stone',(side*27,y,19.1),(.6,2,1.5),.12)
        box('Stone',(side*27,y,35),(.6,2,1),.12)
    # Side terrace guard rails leave a deliberate comparison-bridge opening on the west.
    for z,xedge,y0,y1 in [(0,51,-31,37),(18,53,-22,37),(38,45,14,38)]:
        xx=side*xedge
        spans=[(y0,-5),(5,y1)] if z==18 and side==1 else [(y0,y1)]
        for a,b in spans:
            box('Stone',(xx,(a+b)/2,z+.4),(.7,b-a,.8),.08,True)
            rod('Gold',(xx,a,z+3),(xx,b,z+3),.10,8)
            for j in range(int((b-a)/1.7)+1):
                yy=a+j*(b-a)/max(1,int((b-a)/1.7));rod('DeepBlue',(xx,yy,z+.8),(xx,yy,z+3),.065,6)
            collision.append({'p':[xx,(a+b)/2,z+1.8],'s':[.6,b-a,3.6],'kind':'box'})
    # Short railing separates roof stair void from the usable podium floor.
    for y in [18,26,33]:
        xx=side*22.3
        box('Cream',(xx,y,57.5),(.75,.9,3),.10,True)
    rod('Gold',(side*22.3,14,59),(side*22.3,35.5,59),.10,8)
    collision.append({'p':[side*22.3,24.75,57.5],'s':[.6,21.5,3],'kind':'box'})
# Distinct tall topiary, small fern beds and clustered flowers interrupt repeated round shrubs.
zone='PlantAccents'
for x,y,z in [(-23,-13,18),(23,-13,18),(-38,-26,0),(38,-26,0),(-19,13,38),(19,13,38)]:
    planter(x,y,z,2.4,2.4)
    lathe('LeafDark',x,y,z+1.85,[(.8,0),(.9,.6),(.65,1.6),(.45,2.6),(.12,3.7)],9)
    lathe('Leaf',x+.12,y-.15,z+2.0,[(.72,0),(.75,.6),(.5,1.6),(.31,2.6),(.04,3.5)],9)
for x,y,z in [(-49,-7,18),(49,-7,18),(-48,10,0),(48,10,0),(-35,32,38),(35,32,38)]:
    planter(x,y,z,3.4,5.5)
    for j in range(7):
        a=j*2.4
        root=Vector((x,y,z+1.9));end=root+Vector((math.cos(a)*1.8,math.sin(a)*2.2,1.1+(j%3)*.3))
        rod('LeafDark',root,end,.04,5)
        u=Vector((-math.sin(a),math.cos(a),0))*.45
        for t in [.25,.5,.75]:
            q=root.lerp(end,t)
            geo('LeafLight' if j%2 else 'Leaf',[tuple(q-u),tuple(q+u),tuple(q+Vector((math.cos(a)*.5,math.sin(a)*.5,.3)))],[(0,1,2)])
        leafball('Flower',tuple(end),(.20,.20,.14))
# Blender-authored access bridge; original lobby geometry remains untouched.
zone='ComparisonBridge'
slab(82,0,18,58,7)
for y in [-3.2,3.2]:
    rail(82,y,18,56)

zone='RoomInsets'
for x in [-17,0,17]:
    y=37.6;z=21;r=3.9;h=11
    outline=[(x-r,y,z),(x+r,y,z),(x+r,y,z+h-r)]
    for i in range(1,13):
        a=i*math.pi/12;outline.append((x+r*math.cos(a),y,z+h-r+r*math.sin(a)))
    geo('DeepBlue',outline,[tuple(range(len(outline)))])
    for side in [-1,1]:
        box('Cream',(x+side*(r+.3),y-.08,z+(h-r)/2),(.6,.5,h-r),.07)
    for i in range(12):
        a=i*math.pi/12;b=(i+1)*math.pi/12
        ring=[(x+rr*math.cos(t),yy,z+h-r+rr*math.sin(t)) for yy in [y-.33,y+.1] for rr,t in [(r,a),(r,b),(r+.6,b),(r+.6,a)]]
        geo('Cream' if i%3 else 'Stone',ring,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
    text('JUMP' if x<0 else 'FLOW' if x==0 else 'LAND',x,y-.1,z+6.0,1.15)
    for side in [-1,1]:box('Gold',(x+side*2,y-.12,z+3),(.08,.05,2.4),.01)
# Low podium border makes the champion blocks a contained destination.
zone='PodiumTrim'
for x in [-15,15]:box('Stone',(x,28,56.3),(.5,12,.6),.08)
box('Gold',(0,21.8,56.15),(30,.3,.25),.04)

# Three non-visible calibration points preserve the Blender axes through asset import.
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
manifest={'revision':REV,'colors':COLORS,'meshes':meshinfo,'colliders':collision,'lights':lights,'tags':tags,'spawn':[0,-3,18],'authorCoordinates':'X right, Y depth, Z up; units studs'}
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
for name,pos,look in [('front',(0,-185,64),(0,8,26)),('oblique',(117,-145,106),(0,8,24))]:
    cam.location=pos;cam.rotation_euler=(Vector(look)-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=137
    scene.render.filepath=str(OUT/f'{REV}_{name}.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'Skycourt_{REV}.blend'))
print(json.dumps({'revision':REV,'meshes':len(objects),'triangles':sum(v['triangles'] for v in meshinfo.values()),'colliders':len(collision),'bytes':(OUT/f'Skycourt_{REV}.fbx').stat().st_size}))
