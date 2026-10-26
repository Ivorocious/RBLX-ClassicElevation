"""Build City Run in a fresh background Blender process; never reset an open scene."""
import sys, math, json, random
from pathlib import Path
import bpy
from mathutils import Vector

OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
import layout

scene=bpy.data.scenes.new("CityRun_"+layout.REVISION)
bpy.context.window.scene=scene
random.seed(908)
COLORS={
    "Brick":(.66,.26,.16),"Terracotta":(.79,.37,.23),"Plaster":(.93,.76,.48),
    "Cream":(.93,.87,.72),"Stone":(.64,.65,.61),"Roof":(.24,.30,.32),
    "Teal":(.035,.49,.48),"Coral":(.89,.24,.20),"Yellow":(.99,.66,.10),
    "Blue":(.08,.30,.58),"Iron":(.095,.14,.18),"Glass":(.16,.27,.31),
    "Wood":(.43,.26,.13),"Leaf":(.22,.42,.14),"LeafLight":(.45,.60,.19),
    "Soil":(.22,.17,.12),"Red":(.96,.055,.035),"White":(.96,.95,.85),
    "Rail":(.37,.43,.46),"Skyline":(.40,.52,.57),"Light":(1,.86,.48),
}
MATS={}
for name,col in COLORS.items():
    m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);MATS[name]=m
groups={}; component="World"; components={}; extra_colliders=[]


def owner(name,section="Scenery",pivot=(0,0,0)):
    global component
    component=name
    components[name]={"section":section,"pivot":list(pivot)}


def geo(mat,vs,fs):
    chunks=groups.setdefault((component,mat),[])
    if not chunks or len(chunks[-1][1])+len(fs)>3800:
        chunks.append(([],[]))
    v,f=chunks[-1];n=len(v)
    v.extend((x,-z,y) for x,y,z in vs)
    # Coordinate conversion has positive determinant.
    f.extend(tuple(n+i for i in face) for face in fs)


def box(mat,p,s):
    x,y,z=p;a,b,c=[v/2 for v in s]
    geo(mat,[(x+i*a,y+j*b,z+k*c) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]],
        [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])


def beam(mat,a,b,r=.18,n=6):
    a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,1,0)))
    if u.length<.001:u=d.cross(Vector((1,0,0)))
    u.normalize();v=d.cross(u)
    verts=[tuple(p+r*(u*math.cos(i*math.tau/n)+v*math.sin(i*math.tau/n))) for p in (a,b) for i in range(n)]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    geo(mat,verts,faces)


def sphere(mat,p,r,segments=16,rings=10,scale=(1,1,1)):
    verts=[]
    for j in range(rings+1):
        t=math.pi*j/rings
        for i in range(segments):
            a=math.tau*i/segments
            verts.append((p[0]+math.sin(t)*math.cos(a)*r*scale[0],p[1]+math.cos(t)*r*scale[1],p[2]+math.sin(t)*math.sin(a)*r*scale[2]))
    geo(mat,verts,[(j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i) for j in range(rings) for i in range(segments)])


def cylinder(mat,p,r,h,n=16,r2=None):
    x,y,z=p;r2=r if r2 is None else r2
    vs=[(x+rr*math.cos(i*math.tau/n),y+yy,z+rr*math.sin(i*math.tau/n)) for yy,rr in [(-h/2,r),(h/2,r2)] for i in range(n)]
    geo(mat,vs,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)])


def text(body,p,size=2,mat="Cream",rotation=0):
    curve=bpy.data.curves.new("Lettering","FONT");curve.body=body;curve.size=size
    curve.align_x="CENTER";curve.align_y="CENTER";curve.extrude=.012;curve.resolution_u=2
    obj=bpy.data.objects.new("Letters",curve);scene.collection.objects.link(obj)
    obj.location=(p[0],-p[2],p[1]);obj.rotation_euler=(math.pi/2,0,rotation)
    bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.convert(target="MESH");obj=bpy.context.object
    # Already in Blender coordinates; map back through the shared geo helper.
    verts=[obj.matrix_world@v.co for v in obj.data.vertices]
    geo(mat,[(v.x,v.z,-v.y) for v in verts],[tuple(p.vertices) for p in obj.data.polygons])
    bpy.data.objects.remove(obj,do_unlink=True)


def railing(a,b,height=3,collide=True):
    beam("Iron",(a[0],a[1]+height,a[2]),(b[0],b[1]+height,b[2]),.12)
    d=Vector(b)-Vector(a);count=max(1,round(d.length/4))
    for i in range(count+1):
        p=Vector(a)+d*i/count;beam("Iron",p,p+Vector((0,height,0)),.1)
    if collide:
        extra_colliders.append({"name":component+"Guard","p":[(a[0]+b[0])/2,a[1]+height/2,(a[2]+b[2])/2],
            "size":[abs(d.x)+.25,height,abs(d.z)+.25],"owner":component})


def building(name,x,z,w,d,h,color="Brick",base=0,detail=True):
    owner(name,"Scenery",(x,base,z))
    box(color,(x,base+h/2,z),(w,h,d))
    box("Stone",(x,base+1,z),(w+.5,2,d+.5))
    box("Cream",(x,base+h-.8,z),(w+1.2,1.4,d+1.2))
    box("Roof",(x,base+h+.05,z),(w-.8,.3,d-.8))
    from city_details import facade
    facade(globals(),name,x,z,w,d,h,base,detail)
    if not detail:return
    floors=max(1,int(h/11))
    for f in range(floors):
        y=base+6+f*11
        if y+3>base+h:continue
        for sx in (-1,1):
            for j in range(max(1,int(d/9))):
                zz=z-d/2+4.5+j*9
                box("Cream",(x+sx*(w/2+.12),y,zz),(.35,6,4))
                box("Glass",(x+sx*(w/2+.32),y+.15,zz),(.10,5,3.2))
                box("Iron",(x+sx*(w/2+.42),y+.15,zz),(.06,.18,3.3))
        for sz in (-1,1):
            for j in range(max(1,int(w/9))):
                xx=x-w/2+4.5+j*9
                box("Cream",(xx,y,z+sz*(d/2+.12)),(4,6,.35))
                box("Glass",(xx,y+.15,z+sz*(d/2+.32)),(3.2,5,.10))
                box("Iron",(xx,y+.15,z+sz*(d/2+.42)),(.18,5,.06))
    # Broad floor bands carry the brick identity without individual brick geometry.
    for y in range(12,int(h),22):
        box("Terracotta",(x,base+y,z),(w+.25,.4,d+.25))


def planter(p,w=7):
    x,y,z=p
    box("Terracotta",(x,y+.8,z),(w,1.6,3.5));box("Soil",(x,y+1.62,z),(w-.5,.12,3))
    for i in range(3):sphere("Leaf" if i%2 else "LeafLight",(x+(i-1)*w/3,y+2.5,z),1.4,7,4, (1, .8, .8))


def tank(name,x,y,z):
    owner(name,"Roof",(x,y,z))
    for dx in (-4,4):
        for dz in (-4,4):beam("Iron",(x+dx,y,z+dz),(x+dx*.8,y+11,z+dz*.8),.28)
    for dz in (-4,4):
        beam("Iron",(x-4,y,z+dz),(x+3.2,y+11,z+dz*.8),.14)
        beam("Iron",(x+4,y,z+dz),(x-3.2,y+11,z+dz*.8),.14)
    cylinder("Wood",(x,y+17,z),6,13,20)
    for yy in (11,14,20,23):cylinder("Iron",(x,y+yy,z),6.12,.3,20)
    cylinder("Roof",(x,y+24.7,z),6.6,3.3,20,.4)
    for i in range(20):
        a=i*math.tau/20;beam("Terracotta",(x+6.03*math.cos(a),y+11,z+6.03*math.sin(a)),(x+6.03*math.cos(a),y+23,z+6.03*math.sin(a)),.05,4)


def crane(name,pivot):
    x,y,z=pivot;tx=x;tz=z-39
    owner(name,"Roof",(tx,0,tz))
    box("Stone",(tx,2,tz),(16,4,16))
    for dx in (-3,3):
        for dz in (-3,3):beam("Yellow",(tx+dx,4,tz+dz),(tx+dx,y+4,tz+dz),.38)
    for yy in range(5,int(y),9):
        for dz in (-3,3):
            beam("Yellow",(tx-3,yy,tz+dz),(tx+3,yy+9,tz+dz),.18)
            beam("Yellow",(tx+3,yy,tz+dz),(tx-3,yy+9,tz+dz),.18)
        for dx in (-3,3):beam("Yellow",(tx+dx,yy,tz-3),(tx+dx,yy+9,tz+3),.18)
    for dx in (-2.5,2.5):
        for yy in (y,y+5):beam("Yellow",(x+dx,yy,tz-18),(x+dx,yy,z+13),.32)
        for zz in range(int(tz-18),int(z+8),7):
            beam("Yellow",(x+dx,y,zz),(x+dx,y+5,zz+7),.17)
    box("Stone",(x,y+1,tz-15),(8,5,10))
    box("Yellow",(x+6,y-3,tz),(5,6,6));box("Glass",(x+6,y-2,tz+3.1),(4,3,.2))


def train(name,p,length=30,active=False):
    owner(name,"Moving" if active else "Rail",p)
    x,y,z=p
    box("Iron",(x,y-6,z),(length-1,2,9))
    box("Cream",(x,y-2.9,z),(length,5.2,9.6))
    box("Rail",(x,y-.1,z),(length,.8,10))
    box("Blue",(x,y-4,z+4.85),(length,1,.12))
    box("Blue",(x,y-4,z-4.85),(length,1,.12))
    for dx in range(-int(length/2)+3,int(length/2)-2,5):
        for dz in (-4.9,4.9):box("Glass",(x+dx,y-2,z+dz),(3.5,2,.12))
    for dx in (-length*.32,length*.32):
        beam("Iron",(x+dx,y-6,z-5),(x+dx,y-6,z+5),1.2,12)


# Shared endpoints need a tiny visual layer offset to avoid overlapping mesh faces.
surface_layers=[]
# Playable surfaces are a shared source for Blender and Roblox collision.
for i,s in enumerate(layout.SURFACES):
    x,y,z=s["p"];w,_,d=s["size"];style=s["style"]
    offset=0
    for px,py,pz,pw,pd,po in surface_layers:
        if abs(py-y)<.0001 and abs(px-x)<(pw+w)/2-.01 and abs(pz-z)<(pd+d)/2-.01:
            offset=max(offset,po+.025)
    surface_layers.append((x,y,z,w,d,offset))
    y+=offset
    w+=offset*.5;d+=offset*.5
    owner("Route_"+s["section"]+f"_{i//5:03}",s["section"],s["p"])
    if style=="train":
        # Route trains run north/south; geometry is created locally then rotated as a group.
        owner("Siding_"+s["name"],"Rail",s["p"])
        box("Iron",(x,y-6,z),(w-1,2,d))
        box("Cream",(x,y-3,z),(w-0.4,5,d))
        box("Rail",(x,y-.2,z),(w,.4,d))
        for zz in range(math.ceil(z-d/2+3),math.floor(z+d/2-2),5):
            for xx in (x-w/2,x+w/2):box("Glass",(xx,y-2.6,zz),(.15,2.7,3.4))
        continue
    mat="Wood" if style in ("deck","work","scaffold") else "Cream" if style in ("balcony","stone","stair","sign") else "Roof"
    box(mat,(x,y-.6,z),(w,1.2,d))
    if style in ("road","crossing"):
        continue
    if style=="awning":
        # Rigid shop canopy under the fabric gives a readable walkable top.
        accent=["Teal","Coral","Yellow"][i%3]
        box(accent,(x,y-.02,z),(w,.16,d))
        for xx in range(math.ceil(x-w/2+1),math.floor(x+w/2),3):box("Cream",(xx,y+.08,z),(.65,.06,d))
        box(accent,(x,y-.9,z+d/2),(w,1.7,.25))
    if style in ("work","scaffold","deck","sign"):
        base=0 if style=="deck" else 64 if s["section"] in ("Roof","Rail") else 76
        if style=="sign":base=y-5
        for xx in (x-w/2+.4,x+w/2-.4):
            for zz in (z-d/2+.4,z+d/2-.4):
                beam("Iron" if style!="deck" else "Wood",(xx,base,zz),(xx,y-.7,zz),.23)
        if y>base+4:
            beam("Iron",(x-w/2,base,z-d/2),(x+w/2,y-1,z-d/2),.13)
        if style in ("work","scaffold"):
            box("Coral",(x,y-.95,z+d/2),(w,.65,.25))
        if style=="sign":
            accent=["Teal","Coral","Blue"][i%3]
            box(accent,(x,y-2,z),(w,2.7,d*.7))
            # Small geometric shop badges; no planning IDs on the scenery.
            box("Yellow",(x,y-2,z+d*.36),(w*.45,.3,.1))
            # Wall-mounted arms distinguish signs from the station scaffolding.
            targetx=-104 if x>-130 else x
            targetz=z if x>-130 else (87 if z>0 else -140)
            beam("Iron",(x,y-1,z),(targetx,y-1,targetz),.23)
            beam("Iron",(x,y-1,z),(targetx,y-5,targetz),.18)
    elif style=="stair":
        base=22 if s["section"]=="Climb" else 76
        box("Stone",(x,(base+y-1)/2,z),(w*.92,y-1-base,d*.92))
    elif style=="balcony":
        # Balconies hug the courtyard walls; transverse spans have a renovation frame.
        tx=-242 if x<-200 else -104 if x>-135 else x
        tz=z if x<-200 or x>-135 else (87 if z>40 else -140 if z<-100 else z)
        beam("Iron",(x,y-1,z),(tx,y-1,tz),.3)
        beam("Iron",(x,y-1,z),(tx,y-6,tz),.22)
        if tx==x and tz==z:
            for xx in (-w/2+.6,w/2-.6):beam("Iron",(x+xx,24,z),(x+xx,y-1,z),.32)
        if w<d:
            side=-1 if x<-180 else 1
            railing((x+side*w/2,y,z-d/2),(x+side*w/2,y,z+d/2),collide=False)
    else:
        # Shared building masses carry the route; only its short roof risers are separate.
        base=60 if s["section"]=="Roof" else 76 if s["section"]=="Station" else 0
        if s["section"]=="Climb":base=24
        if s["section"]=="Station" and style=="stone":
            base=76 if y<107 else 104
        box("Brick" if i%3 else "Plaster",(x,(base+y-1.3)/2,z),(max(2,w-1.1),y-1.3-base,max(2,d-1.1)))
        box("Cream",(x,y-2,z),(w+.1,.5,d+.1))
        if y>18:
            for yy in range(int(base)+7,int(y)-4,12):
                box("Glass",(x,yy,z+d/2-.5),(min(4,w*.5),5,.15))
    # Consistent yellow landing-edge accents are physical paint, not text labels.
    if style not in ("stair","sign"):
        long_x=w>d
        if long_x:
            for xx in (-w/2+.45,w/2-.45):box("Yellow",(x+xx,y+.045,z),(.5,.08,min(d,5)))
        else:
            for zz in (-d/2+.45,d/2-.45):box("Yellow",(x,y+.045,z+zz),(min(w,5),.08,.5))
    if s.get("checkpoint") is not None:
        index=s["checkpoint"]
        box("Teal",(x,y+.04,z),(w-2,.08,2))
        for xx in (-w/2+1,w/2-1):
            beam("Teal",(x+xx,y,z+5),(x+xx,y+7,z+5),.18)
            box("Teal",(x+xx,y+6,z+5),(2.4,2,.2))
        if index not in (1,6):
            railing((x-w/2,y,z-d/2),(x-w/2,y,z+d/2),collide=False)

# Market storefronts frame the opening and leave a long, unobstructed delivery street.
for i,(x,z,w,d,h) in enumerate([(-202,250,25,36,43),(-130,246,32,35,37),(-215,203,27,28,47),
    (-127,202,29,29,50),(-227,126,30,42,53),(-72,126,28,45,55),(-70,76,28,38,61)]):
    building(f"MarketHouse{i}",x,z,w,d,h,["Brick","Plaster","Terracotta"][i%3])
    owner(f"MarketShop{i}","Market",(x,0,z))
    box("Teal" if i%2 else "Coral",(x,8,z+d/2+.2),(w-3,5,.35))
    text(["BAKERY","FRESH","CAFE","BOOKS"][i%4],(x,8,z+d/2+.42),2)
    planter((x-w/2+4,0,z+d/2+3),5)
owner("MarketStreet","Market")
box("Roof",(-160,10.7,164),(470,1,14))
for xx in range(-390,72,12):box("Cream",(xx,11.23,164),(5,.05,.3))
for z in (153,175):box("Stone",(-160,10,z),(470,3,5))
for xx in (-190,-150):
    box("Stone",(xx,13,179),(2,4,2))
    box("Stone",(xx,13,149),(2,4,2))
for zz in (173,155):
    box("Red",(-170,12.08,zz),(22,.12,1))
owner("MarketStart","Market")
for xx in (-186,-154):beam("Teal",(xx,8,246),(xx,21,246),.4)
box("Teal",(-170,21,246),(34,4,.7));text("CITY RUN",(-170,21,246.4),3,"White")

# Residential courtyard enclosing the climb, with color and a large graphic mural.
building("CourtStairBase",-187,80,86,16,23,"Brick",detail=False)
building("CourtUpperGallery",-168,-134,112,15,55,"Brick",detail=True)
owner("CourtBridgeFrames","Climb")
for z in (5,-55):
    for y in (12,24):
        beam("Iron",(-242,y,z),(-104,y,z),.6)
        for x in range(-236,-104,22):
            beam("Iron",(x,y,z),(x+22,y+10,z),.28)
    for x in (-225,-180,-135):box("Brick",(x,11,z),(5,22,7))
for i,(x,z,w,d,h) in enumerate([(-264,53,42,90,68),(-264,-68,42,105,78),(-81,14,44,65,61),
    (-82,-89,45,73,81),(-180,-158,74,30,77)]):
    building(f"CourtHouse{i}",x,z,w,d,h,["Terracotta","Brick","Plaster"][i%3])
owner("CourtyardMural","Climb")
box("Teal",(-240,38,-48),(.2,24,30))
for j in range(9):
    z=-60+j*3
    geo(["Coral","Yellow","Cream"][j%3],[(-239.8,26,z),(-239.8,46+(j%3)*3,z+2),(-239.8,30,z+6)],[(0,1,2)])
for i,p in enumerate([(-262,68,53),(-82,61,14),(-180,77,-158)]):
    owner("CourtPlanter"+str(i),"Climb",p);planter(p,10)

# Roof district city blocks and two iconic tanks.
building("DistrictBase",-183,-177,101,137,59,"Brick",detail=True)
building("RenovationNorth",0,-302,172,35,63,"Brick",detail=True)
building("RenovationEast",99,-272,44,88,63,"Plaster",detail=True)
building("RenovationWest",-88,-271,30,86,63,"Terracotta",detail=True)
owner("RenovationStructure","Roof")
for x in (-66,-20,20,66):
    for z in (-257,-231):
        box("Stone",(x,32,z),(4,64,4))
for z in (-257,-231):
    for y in (32,64):
        beam("Coral",(-90,y,z),(115,y,z),.7)
        for x in range(-86,110,24):beam("Coral",(x,y-7,z),(x+24,y,z),.25)
for i,(x,z,w,d,h) in enumerate([(-244,-254,42,52,91),(-163,-300,62,40,86),(-126,-347,54,45,76),
    (93,-349,65,43,88),(151,-297,37,60,84),(-4,-348,75,34,71)]):
    building(f"RoofHouse{i}",x,z,w,d,h,["Brick","Plaster","Terracotta"][i%3])
tank("WaterTankA",-170,86,-300);tank("WaterTankB",92,88,-349)
for ball in layout.HAZARDS["balls"]:
    crane("Crane"+ball["name"],ball["pivot"])
    x,y,z=ball["pivot"];center=(x,y-ball["length"],z)
    owner(ball["name"],"Moving",center);sphere("Iron",center,ball["radius"],20,14)
    # Bands and ribs make rotation readable on a dark silhouette.
    cylinder("Yellow",(x,center[1]-3,z),6,.55,20)
    cylinder("Iron",(x,center[1]+6.5,z),.55,1.5,10)
    owner(ball["name"]+"Cable","Moving",ball["pivot"])
    beam("Iron",ball["pivot"],center,.16,8)
    owner(ball["name"]+"Warning","Roof")
    for zz in (-257,-231):
        for dx in (-9,9):box("Red",(x+dx,82.08,zz),(1,.14,10 if zz==-257 else 3.5))
owner("RoofGardenProps","Roof")
for p in [(78,84,-308),(106,84,-318),(125,82,-247)]:planter(p,7)

# Continuous viaduct, depot siding and one active line; rail geometry stays below the crossing deck.
owner("Viaduct","Rail")
box("Stone",(120,73,-12),(1140,12,24))
for x in range(-440,700,48):
    box("Stone",(x,34,-12),(9,68,16))
    box("Cream",(x,65,-12),(17,3,21))
for z in (-16,-8):box("Rail",(120,80.3,z),(1140,.65,.5))
for x in range(-445,690,4):
    if abs(x-205)>10:box("Wood",(x,79.7,-12),(1.5,.6,14))
for z in (-25,1):box("Cream",(120,78,z),(1140,1,1.5))
owner("SidingSupports","Rail")
box("Stone",(184,69,-153),(64,12,140))
for x in (162,168,202,208):box("Rail",(x,75.4,-153),(.5,.6,138))
for z in range(-215,-80,24):
    for x in (165,205):box("Stone",(x,32,z),(10,64,8))
owner("SignalGantry","Rail")
for x in (195,215):beam("Iron",(x,78,-28),(x,98,-28),.45)
beam("Iron",(195,97,-28),(215,97,-28),.55)
for x in (195,215):
    box("Iron",(x,94,-27),(2.8,5,1.2))
    sphere("Red",(x,95,-26.25),.72,10,6)
    sphere("Red",(x,92.9,-26.25),.72,10,6)
box("Iron",(205,96,-28),(13,2,.5));text("LOOK FOR TRAIN",(205,96,-27.65),.88)
for z in (-26,5):box("Red",(205,82.07,z),(16,.14,1))
owner("TrainBarrier","Moving",(205,84,-26))
box("Cream",(205,84,-26),(13,1,.8))
for x in range(199,212,3):box("Red",(x,84,-25.55),(1.5,1,.1))
for i in range(3):train("ActiveTrain"+str(i),(-461+(i-1)*38,89,-12),36,True)

# Car bodies are individually reusable; their runtime movement is in Roblox.
for i,mat in enumerate(("Coral","Teal","Yellow")):
    owner("Car"+str(i),"Moving",(-350,15,164))
    box(mat,(-350,15,164),(14,3,7))
    box(mat,(-351,17.3,164),(7,2.5,6.5))
    box("Glass",(-347.4,17.4,164),(.2,1.7,5.7))
    box("Glass",(-351,17.4,167.3),(6,1.7,.1));box("Glass",(-351,17.4,160.7),(6,1.7,.1))
    for xx in (-354,-346):beam("Iron",(xx,13.2,160.4),(xx,13.2,167.6),1.3,12)
    for zz in (161.5,166.5):box("Light",(-342.9,15,zz),(.15,.9,1.4))

# Station mass supports a stepped exterior route and the terrace above the active railway.
building("StationBase",275,143,150,180,75,"Brick",detail=True)
building("StationMainHall",285,137,70,120,103,"Brick",detail=True)
building("StationWestWing",218,165,35,91,103,"Brick",detail=True)
building("StationTerraceBase",195,239,78,40,130,"Brick",detail=False)
owner("StationScaffoldFrame","Station")
for z in range(57,185,16):
    beam("Iron",(190,76,z),(207,76,z),.35)
    beam("Iron",(191,76,z),(207,69,z),.3)
    for y in (86,98,110):
        if y < 86+(z-57)*46/127:
            beam("Iron",(191,y,z),(200,y,z),.2)
owner("StationArchitecture","Station")
for x,z,y in [(243,85,83),(285,108,83),(299,173,99),(333,195,99)]:
    box("Cream",(x,y/2,z),(3,y,4))
for x in (170,186,202,218):
    box("Cream",(x,106,259.5),(11,31,1))
    box("Glass",(x,106,260.1),(8,27,.25))
    box("Cream",(x,106,260.4),(.5,27,.1))
    box("Cream",(x,107,260.4),(8,.5,.1))
box("Teal",(195,126,260),(63,5,.6));text("RIVERSIDE STATION",(195,126,260.5),3)
for x in (159,231):railing((x,132,226),(x,132,257))
railing((159,132,257),(231,132,257))
for x in (164,226):planter((x,132,250),7)
owner("ClockTower","Station",(195,132,274))
box("Cream",(195,158,274),(22,52,22))
for y in (135,166,184):box("Stone",(195,y,274),(25,1.8,25))
for x in (185,205):
    for z in (264,284):box("Plaster",(x,159,z),(2.4,48,2.4))
for z in (262.7,285.3):
    beam("Iron",(195,175,z-.15),(195,175,z+.15),7.1,32)
    beam("Cream",(195,175,z-.2),(195,175,z+.2),6.6,32)
    for i in range(12):
        a=i*math.tau/12;xx=195+5.6*math.sin(a);yy=175+5.6*math.cos(a)
        box("Iron",(xx,yy,z+(.24 if z>274 else -.24)),(.35,.8,.1))
    face=z+(.3 if z>274 else -.3)
    beam("Iron",(195,175,face),(191,178,face),.15)
    beam("Iron",(195,175,face),(198,180,face),.12)
for x in (183.7,206.3):
    beam("Iron",(x-.15,175,274),(x+.15,175,274),7.1,32)
    beam("Cream",(x-.2,175,274),(x+.2,175,274),6.6,32)
    face=x+(.3 if x>195 else -.3)
    for i in range(12):
        a=i*math.tau/12
        box("Iron",(face,175+5.6*math.cos(a),274+5.6*math.sin(a)),(.1,.8,.35))
    beam("Iron",(face,175,274),(face,178,270),.15)
    beam("Iron",(face,175,274),(face,180,277),.12)
cylinder("Teal",(195,193,274),17,16,4,1)
beam("Iron",(195,200,274),(195,207,274),.22)
owner("FinishBanner","Station")
for x in (181,209):beam("Teal",(x,132,232),(x,142,232),.28)
box("Coral",(195,142,232),(30,4,.5));text("FINISH",(195,142,232.4),3,"White")
text("FINISH",(195,142,231.6),3,"White",math.pi)
for cp in (2,4,8):
    x,y,z=layout.CHECKPOINTS[cp]
    owner(f"ExpertSign{cp}","Climb" if cp==2 else "Roof" if cp==4 else "Station")
    beam("Iron",(x+9,y,z+6),(x+9,y+6,z+6),.15)
    box("Yellow",(x+9,y+6,z+6),(7,2.8,.3))
    text("EXPERT",(x+9,y+6,z+6.2),.9,"Iron")
    text("EXPERT",(x+9,y+6,z+5.8),.9,"Iron",math.pi)

# Simplified neighboring blocks form the city edge without interiors or tiny clutter.
for i,(x,z) in enumerate([(x,z) for x in (-350,-300,390,440) for z in range(-340,301,80)]):
    building(f"OuterBlock{i}",x,z,random.randint(30,45),random.randint(35,55),random.randint(45,103),["Brick","Terracotta","Plaster"][i%3],detail=(i%2==0))
for i,(x,z) in enumerate([(x,z) for x in range(-420,501,90) for z in (-420,365)]):
    building(f"DistantBlock{i}",x,z,random.randint(32,55),random.randint(36,58),random.randint(50,125),["Brick","Plaster","Terracotta","Skyline"][i%4],detail=False)
owner("Ground","Scenery")
box("Stone",(35,-3,-20),(1000,5,850))

# Hidden endpoint tunnels screen reset positions, never the visible crossing approach.
for name,x,z,y,w in [("CarEntry",-365,164,12,22),("CarExitTunnel",70,164,12,22),
    ("TrainEntry",-480,-12,82,25),("TrainExit",715,-12,82,25)]:
    owner(name,"Scenery")
    box("Brick",(x,y+12,z-w/2),(55,24,4));box("Brick",(x,y+12,z+w/2),(55,24,4))
    box("Stone",(x,y+24,z),(55,4,w+4))
    box("Iron",(x+(-26 if "Entry" in name else 26),y+10,z),(1,20,w))

from city_details import dress_sections
dress_sections(globals())

for key,p in [("Origin",(0,0,0)),("Right",(10,0,0)),("Up",(0,10,0)),("Forward",(0,0,-10))]:
    owner("Marker"+key,"Calibration",p);box("Iron",p,(.1,.1,.1))

objects=[];meshinfo={}
for (comp,mat),chunks in groups.items():
    for i,(vs,fs) in enumerate(chunks):
        name=f"{comp}__{mat}__{i:02}"
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.materials.append(MATS[mat]);mesh.update();mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles)<20000,(name,len(mesh.loop_triangles))
        obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj);objects.append(obj)
        meshinfo[name]={"triangles":len(mesh.loop_triangles),"material":mat,"component":comp}
for obj in scene.objects:obj.select_set(False)
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/f"CityRun_{layout.REVISION}.fbx"),use_selection=True,object_types={"MESH"},axis_forward="-Z",axis_up="Y",apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
data=layout.manifest();data.update(colors=COLORS,meshes=meshinfo,components=components,guards=extra_colliders)
(OUT/f"manifest_{layout.REVISION}.json").write_text(json.dumps(data,indent=2))


def luau(v):
    if isinstance(v,dict):return "{"+",".join("["+json.dumps(k)+"]="+luau(x) for k,x in v.items())+"}"
    if isinstance(v,(list,tuple)):return "{"+",".join(luau(x) for x in v)+"}"
    if isinstance(v,str):return json.dumps(v)
    if v is None:return "nil"
    return str(v).lower()


dest=OUT.parents[1]/"src/ServerStorage/CourseBuilders/CityRun"
dest.mkdir(parents=True,exist_ok=True)
(dest/"Manifest.luau").write_text("--!strict\n-- Generated by assets/city_run/build_city.py.\nreturn "+luau(data)+"\n")
(OUT.parents[1]/"src/ReplicatedStorage/Config/CityRunTuning.luau").write_text("--!strict\n-- Generated from assets/city_run/layout.py.\nreturn "+luau({"hazards":layout.HAZARDS,"movement":layout.MOVEMENT})+"\n")
scene.world=bpy.data.worlds.new("CityAfternoon");scene.world.color=(.55,.70,.8)
camdata=bpy.data.cameras.new("Preview");cam=bpy.data.objects.new("Preview",camdata);scene.collection.objects.link(cam);scene.camera=cam
camdata.clip_end=5000
scene.render.engine="BLENDER_WORKBENCH";scene.display.shading.light="STUDIO";scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True;scene.display.shading.cavity_type="BOTH"
scene.display.shading.background_type="WORLD";scene.view_settings.view_transform="Standard"
scene.render.resolution_x=1600;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
views=[("overview",(730,630,760),(0,50,-25),1050),
    ("market",(-115,46,295),(-150,30,85),220),
    ("courtyard",(-290,125,125),(-160,43,-30),260),
    ("rooftop",(-135,119,-182),(8,93,-263),260),
    ("station",(405,178,305),(208,119,110),310)]
for name,p,target,scale in views:
    cam.location=(p[0],-p[2],p[1]);q=Vector((target[0],-target[2],target[1]))
    cam.rotation_euler=(q-cam.location).to_track_quat("-Z","Y").to_euler();camdata.type="ORTHO";camdata.ortho_scale=scale
    scene.render.filepath=str(OUT/f"{layout.REVISION}_{name}.png");bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f"CityRun_{layout.REVISION}.blend"))
print(json.dumps({"revision":layout.REVISION,"meshes":len(objects),"triangles":sum(x["triangles"] for x in meshinfo.values()),"surfaces":len(layout.SURFACES)}))
