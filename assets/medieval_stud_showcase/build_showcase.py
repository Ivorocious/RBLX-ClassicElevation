"""Rebuild the reference-inspired medieval display without touching the open Blender scene."""
import json
import math
import random
from collections import defaultdict
from pathlib import Path

import bpy
from mathutils import Vector, Matrix

OUT = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)
REV = "M02"
RNG = random.Random(4139)
SCENE = bpy.data.scenes.new("MedievalStudShowcase_" + REV)
bpy.context.window.scene = SCENE
PALETTE = {
    "WoodDark": (72, 43, 29), "Wood": (121, 77, 44), "WoodLight": (161, 111, 63),
    "WoodWarm": (144, 90, 46), "WoodEnd": (181, 134, 79),
    "IronDark": (37, 49, 63), "Iron": (65, 83, 104), "IronLight": (98, 121, 141),
    "StoneDark": (78, 93, 105), "Stone": (111, 128, 141), "StoneLight": (143, 159, 166),
    "GoldDark": (160, 127, 55), "Gold": (208, 172, 76), "GoldLight": (239, 212, 129),
    "Ivory": (234, 224, 177), "Paper": (223, 209, 163),
    "Burgundy": (110, 31, 66), "BurgundyLight": (139, 43, 84),
    "Teal": (36, 112, 115), "Silver": (180, 200, 209), "SilverLight": (225, 235, 221),
    "Hay": (190, 161, 80), "HayLight": (223, 199, 115), "HayDark": (157, 126, 61),
    "FireOrange": (245, 112, 24), "FireGold": (255, 177, 35), "FireLight": (255, 223, 97),
    "Water": (42, 85, 111), "Ink": (74, 57, 38),
}


def linear(channel):
    value = channel / 255
    return value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4


MATERIALS = {}
for name, rgb in PALETTE.items():
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = tuple(linear(c) for c in rgb) + (1,)
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = mat.diffuse_color
    shader.inputs["Roughness"].default_value = .82
    if name.startswith("Fire"):
        shader.inputs["Emission Color"].default_value = mat.diffuse_color
        shader.inputs["Emission Strength"].default_value = .6
    MATERIALS[name] = mat

GROUPS = defaultdict(lambda: [[], []])
PROPS = {}
CURRENT = None
TRANSFORM = Matrix.Identity(4)


def prop(name, position, angle=0):
    global CURRENT, TRANSFORM
    position = (position[0] * .70, position[1] * .72, position[2])
    CURRENT = name
    TRANSFORM = Matrix.Translation(Vector(position)) @ Matrix.Rotation(math.radians(angle), 4, "Z")
    PROPS[name] = {"position": position, "angle": angle, "colliders": []}


def geom(material, vertices, faces):
    vs, fs = GROUPS[(CURRENT, material)]
    offset = len(vs)
    vs.extend(tuple(TRANSFORM @ Vector(v)) for v in vertices)
    fs.extend(tuple(offset + i for i in face) for face in faces)


def box(material, center, size, rotation=None):
    x, y, z = center
    a, b, c = [v / 2 for v in size]
    vertices = [(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),
                (-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]
    if rotation is not None:
        vertices = [tuple(Vector(center) + rotation @ Vector(v)) for v in vertices]
    else:
        vertices = [(vx+x,vy+y,vz+z) for vx,vy,vz in vertices]
    geom(material, vertices, [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])


def beam(material, start, end, width, depth=None):
    delta = Vector(end) - Vector(start)
    rotation = delta.to_track_quat("Z", "Y").to_matrix()
    box(material, (Vector(start) + Vector(end)) / 2, (width, depth or width, delta.length), rotation)


def stud(material, center, width=.27, height=.07, u=(1,0,0), v=(0,1,0)):
    center, u, v = Vector(center), Vector(u), Vector(v)
    normal = u.cross(v).normalized()
    vertices = []
    for h, half in [(0,width/2),(height*.65,width/2),(height,width*.42)]:
        for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)]:
            vertices.append(tuple(center + u*a*half + v*b*half + normal*h))
    faces = [(8,9,10,11)]
    for r in [0,4]:
        for i in range(4):
            j = (i+1)%4
            faces.append((r+i,r+j,r+j+4,r+i+4))
    geom(material, vertices, faces)


def stud_grid(material, center, width, depth, pitch=.6, u=(1,0,0), v=(0,1,0)):
    nx, ny = max(0, math.floor(width / pitch)), max(0, math.floor(depth / pitch))
    for i in range(nx):
        for j in range(ny):
            p = Vector(center) + Vector(u)*(i-(nx-1)/2)*pitch + Vector(v)*(j-(ny-1)/2)*pitch
            stud(material,p,u=u,v=v)


def peg(center, material="IronDark", face="front"):
    if face == "front":
        box(material, center, (.22,.10,.22))
        box("IronLight" if material.startswith("Iron") else "GoldLight", (center[0]-.025,center[1]-.058,center[2]+.025), (.08,.02,.08))
    else:
        box(material, center, (.22,.22,.10))


def plank(center, size, direction="x", material=None, grain=True):
    material = material or RNG.choice(["Wood","WoodWarm","WoodLight"])
    box(material, center, size)
    if not grain: return
    x,y,z=center; sx,sy,sz=size
    if direction == "z":
        for _ in range(max(1,int(sz/1.5))):
            length=RNG.uniform(.35,.9)*min(sz,2)
            box("WoodDark" if RNG.random()<.6 else "WoodEnd",(x+RNG.uniform(-.3,.3)*sx,y-sy/2-.009,z+RNG.uniform(-.3,.3)*(sz-length)),(max(.045,sx*.07),.025,length))
    else:
        for _ in range(max(1,int(sx/1.8))):
            length=RNG.uniform(.4,.85)*min(sx,2.3)
            box("WoodDark" if RNG.random()<.6 else "WoodEnd",(x+RNG.uniform(-.3,.3)*(sx-length),y+RNG.uniform(-.25,.25)*sy,z+sz/2+.014),(length,max(.04,sy*.08),.028))


def collider(center, size):
    PROPS[CURRENT]["colliders"].append({"center":center,"size":size})


def foot(x,y,w=1.1,d=1.5,z=.18):
    box("WoodDark",(x,y,z),(w,d,.36))
    box("WoodLight",(x,y,z+.23),(w*.84,d*.9,.18))
    stud_grid("Wood",(x,y,z+.32),w*.8,d*.8)


def candle(x,y,z,height=.85):
    box("GoldDark",(x,y,z+.08),(.55,.55,.16))
    box("Gold",(x,y,z+.19),(.4,.4,.12))
    box("Ivory",(x,y,z+.27+height/2),(.27,.28,height))
    box("Paper",(x-.14,y-.025,z+.25+height*.65),(.07,.16,height*.44))
    box("Ink",(x,y,z+.31+height),(.06,.06,.16))
    box("FireLight",(x,y,z+.43+height),(.13,.14,.2))


def polygon_extrude(material, polygon, y, depth):
    n=len(polygon)
    vertices=[(x,y-depth/2,z) for x,z in polygon]+[(x,y+depth/2,z) for x,z in polygon]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    geom(material,vertices,faces)


def disc_pixels(center, radius, depth, bands, grid=.24):
    x,y,z=center
    n=math.ceil(radius/grid)
    for i in range(-n,n):
        for j in range(-n,n):
            px,pz=(i+.5)*grid,(j+.5)*grid
            distance=math.hypot(px,pz)
            if distance>radius: continue
            material=next(mat for threshold,mat in bands if distance<=threshold)
            box(material,(x+px,y,z+pz),(grid+.001,depth,grid+.001))


def hoop_y(center, radius, width, material="Iron", segments=12, thickness=.14):
    x,y,z=center
    for i in range(segments):
        a=(i+.5)*math.tau/segments
        px,pz=math.sin(a)*radius,math.cos(a)*radius
        rotation=Matrix.Rotation(a,3,"Y")
        box(material,(x+px,y,z+pz),(2*radius*math.tan(math.pi/segments)+.035,width,thickness),rotation)


def barrel(x,y,z,radius=1.75,length=3.7,spigot=False):
    segments=12
    for i in range(segments):
        a=i*math.tau/segments; b=(i+1)*math.tau/segments
        vertices=[]
        for yy,rr in [(-length/2,radius*.9),(-length*.31,radius),(length*.31,radius),(length/2,radius*.9)]:
            vertices.extend([(x+math.sin(a)*rr,y+yy,z+math.cos(a)*rr),
                             (x+math.sin(b)*rr,y+yy,z+math.cos(b)*rr)])
        geom(["Wood","WoodWarm","WoodLight"][i%3],vertices,[(0,1,3,2),(2,3,5,4),(4,5,7,6)])
    for yy in [-length*.34,length*.34]:
        hoop_y((x,y+yy,z),radius+.07,.36)
        hoop_y((x,y+yy-.19,z),radius+.09,.065,"IronLight",thickness=.09)
    for yy in [-length/2,length/2]:
        disc_pixels((x,y+yy,z),radius*.9,.18,[(radius,"WoodEnd")])
        hoop_y((x,y+yy-.11,z),radius*.87,.22,"WoodLight",thickness=.20)
    for xx in [-.9,-.45,0,.45,.9]:
        maxheight=2*math.sqrt(max(.01,(radius*.78)**2-xx*xx))
        box("WoodDark",(x+xx,y-length/2-.105,z),(.055,.022,maxheight))
        box("WoodLight",(x+xx+.09,y-length/2-.12,z+.12),(.12,.035,maxheight*.75))
    if spigot:
        box("GoldDark",(x,y-length/2-.25,z-.44),(.46,.33,.46))
        box("Gold",(x,y-length/2-.58,z-.5),(.22,.58,.24))
        box("GoldLight",(x,y-length/2-.82,z-.63),(.3,.19,.38))
        box("WoodDark",(x,y-length/2-.46,z-.21),(.47,.12,.12))


def chest(name, position, size, angle=0):
    prop(name,position,angle)
    w,d,h=size
    box("WoodDark",(0,0,h*.42),(w,d,h*.84))
    for row in range(3):
        zz=.2+(row+.5)*(h*.65/3)
        plank((0,-d/2-.045,zz),(w-.12,.13,h*.65/3-.06),grain=False)
        plank((0,d/2+.045,zz),(w-.12,.13,h*.65/3-.06),grain=False)
    for i in range(5):
        yy=(i-2)*d/5
        zz=h*.81+(1-abs(i-2)/3)*h*.18
        plank((0,yy,zz),(w-.10,d/5-.035,.22))
    for xx in [-w*.37,w*.37]:
        for yy in [-d/2-.14,d/2+.14]:box("Iron",(xx,yy,h*.46),(.28,.22,h*.84))
        for i in range(5):
            yy=(i-2)*d/5;zz=h*.81+(1-abs(i-2)/3)*h*.18+.16
            box("Iron",(xx,yy,zz),(.30,d/5+.012,.16))
        for yy in [-d/2-.25,d/2+.25]:
            for zz in [.25,h*.72]:peg((xx,yy,zz))
    box("WoodEnd",(0,-d/2-.13,h*.67),(w*.72,.12,.16))
    box("GoldDark",(0,-d/2-.21,h*.56),(.55,.12,.64))
    box("Gold",(0,-d/2-.30,h*.57),(.38,.08,.45))
    box("Ink",(0,-d/2-.35,h*.55),(.11,.04,.19))
    for xx in [-w/2-.025,w/2+.025]:
        box("IronDark",(xx,0,h*.4),(.13,.8,.45))
        box("Iron",(xx*1.006,-.01,h*.42),(.17,.58,.12))
    collider((0,0,h/2),(w,d,h))


# Tall cabinet: stepped canopy, recessed display and five individually framed drawers.
prop("CandleCabinet",(-22,-1,0),-4)
for x in [-1.55,1.55]:
    for y in [-.88,.88]:foot(x,y,.75,.85)
box("WoodDark",(0,0,2.8),(3.75,2.15,5.25))
for x in [-1.9,1.9]:
    plank((x,0,2.9),(.30,2.36,5.5),"z","WoodLight")
    for y in [-.79,-.26,.27,.80]:
        box("WoodWarm" if y<0 else "Wood",(x*1.085,y,2.83),(.12,.49,4.65))
    for z in [.65,2.85,5.0]:
        box("WoodLight",(x*1.13,0,z),(.11,2.34,.17))
    stud_grid("Wood",(x*1.17,0,2.85),1.8,3.5,.6,u=(0,1,0),v=(0,0,1 if x>0 else -1))
for k in range(5):
    z=.83+k*.87
    box("WoodLight",(0,-1.21,z),(3.45,.26,.78))
    box("Wood",(0,-1.36,z),(3.09,.09,.53))
    box("WoodEnd",(0,-1.43,z+.21),(3.0,.08,.10))
    box("GoldDark",(0,-1.48,z),(.95,.12,.20))
    box("GoldLight",(0,-1.57,z+.015),(.73,.11,.14))
    for x in [-1.48,1.48]:peg((x,-1.42,z),"GoldDark")
for z in [.31,5.1]:
    plank((0,0,z),(4.32,2.6,.30),material="WoodWarm")
    box("WoodEnd",(0,-1.36,z+.06),(4.5,.18,.18))
for x in [-1.55,1.55]:plank((x,.42,6.7),(.33,1.15,2.95),"z","Wood")
box("WoodDark",(0,1.03,6.6),(3.1,.25,2.7))
plank((0,.12,5.61),(3.2,1.55,.16),material="WoodLight")
for x in [-1.16,-.38,.42,1.14]:candle(x,-.48,5.3,RNG.choice([.45,.6,.8]))
for step in range(5):
    width=4.25-step*.64
    plank((0,.4,8.02+step*.28),(width,2.1,.28),material=["Wood","WoodWarm","WoodDark"][step%3])
    box("WoodLight",(-width/2,.4,8.13+step*.28),(.22,2.22,.20))
    stud_grid("WoodWarm",(0,.4,8.18+step*.28),width-.4,1.6,.54)
for x in [-1.34,1.34]:peg((x,-.42,7.7))
box("Iron",(.96,.22,6.75),(.54,.58,.85))
box("Gold",(.96,-.10,6.75),(.3,.06,.55))
box("IronDark",(.96,.22,7.27),(.66,.68,.16))
collider((0,0,4.45),(4.0,2.5,8.9))

# Royal banner with a pixel crown and swallowtail cloth.
prop("RoyalBanner",(-17,12,0),-3)
foot(0,.25,1.8,1.9)
plank((0,.4,5.0),(.44,.48,9.3),"z","WoodWarm")
box("GoldDark",(0,.4,9.62),(.8,.8,.22))
for z,w,d in [(9.85,.4,.4),(10.23,.73,.35),(10.61,.34,.35),(10.95,.21,.24)]:
    box("Gold",(0,.4,z),(w,d,.38))
box("WoodLight",(0,.05,8.85),(5.35,.40,.38))
for x in [-2.75,2.75]:box("Gold",(x,.05,8.85),(.25,.60,.65))
for x in [-1.5,1.5]:box("Iron",(x,.025,8.88),(.38,.58,.58))
cell=.26; nx=16; nz=24
for i in range(nx):
    for j in range(nz):
        x=(i-(nx-1)/2)*cell;z=2.28+(j+.5)*cell
        if j<4 and abs(i-(nx-1)/2)<(4-j)*.6:continue
        border=i in [0,nx-1] or j==nz-1 or j==0 or (j<4 and abs(abs(i-(nx-1)/2)-(4-j)*.6)<.8)
        mat="Gold" if border else "BurgundyLight" if i%5==1 else "Burgundy"
        box(mat,(x,-.17,z),(cell+.002,.18,cell+.002))
        if not border and i%3==1 and j%3==1:stud(mat,(x,-.28,z),.14,.035,v=(0,0,1))
crown=["100010001","110111011","111111111","111111111","000000000","111111111"]
for j,row in enumerate(crown):
    for i,pixel in enumerate(row):
        if pixel=="1":box("GoldLight",((i-4)*.31,-.34,7.25-j*.31),(.315,.14,.315))
collider((0,.4,4.9),(.55,.65,9.8))

prop("BrewersBarrel",(-12,-.4,0),-4)
for xx in [-1.45,1.45]:
    for yy in [-1.42,1.42]:foot(xx,yy,.8,1.1)
    beam("WoodWarm",(xx,-1.3,.35),(xx,-1.3,2.1),.42)
    beam("WoodWarm",(xx,1.3,.35),(xx,1.3,2.1),.42)
for yy in [-1.3,1.3]:beam("WoodLight",(-1.65,yy,.95),(1.65,yy,.95),.45)
barrel(0,0,2.92,2.12,4.05,True)
collider((0,0,2.5),(4.4,4.3,5.0))

prop("ArcheryTarget",(-2,1,0),2)
for x in [-1.65,1.65]:
    foot(x,-.2,1.2,1.8)
    beam("Wood",(x,-.15,.35),(x*.7,.18,3.1),.43)
beam("WoodWarm",(0,1.75,.20),(0,.3,4.1),.48)
beam("WoodLight",(-1.75,-.18,1.28),(1.75,-.18,1.28),.33)
disc_pixels((0,.19,4.1),2.76,.44,[(2.76,"Wood")],.24)
disc_pixels((0,-.10,4.1),2.7,.18,[(.34,"Burgundy"),(.78,"Ivory"),(1.19,"Burgundy"),(1.6,"Burgundy"),(2.20,"Ivory"),(2.7,"GoldLight")],.24)
for i in range(28):
    a=i*math.tau/28
    x=round(math.sin(a)*2.52/.24)*.24;z=4.1+round(math.cos(a)*2.52/.24)*.24
    box("Gold",(x,-.24,z),(.25,.15,.25))
for xx in [-2.86,2.86]:box("GoldDark",(xx,.08,4.1),(.26,.56,.8))
collider((0,0,3.8),(5.5,.85,5.45))

# Display shields hang inside a timber frame.
prop("ShieldRack",(-5.5,11.2,0),0)
for x in [-2.55,2.55]:
    foot(x,0,1.1,1.6)
    plank((x,0,3.6),(.36,.44,6.7),"z","WoodLight")
plank((0,0,6.95),(5.85,.6,.38),material="WoodWarm")
plank((0,.12,1.4),(5.2,.36,.33),material="WoodWarm")
for x in [-2.55,2.55]:
    for z in [1.4,6.95]:peg((x,-.36,z))
for x in [-1.13,1.25]:box("IronDark",(x,-.05,6.37),(.28,.50,.70))
shield=[(-2.19,5.94),(-.35,5.94),(-.30,4.43),(-.6,3.72),(-1.28,3.10),(-1.95,3.72),(-2.24,4.43)]
polygon_extrude("Gold",shield,-.25,.26)
polygon_extrude("Burgundy",[(-2,5.72),(-.55,5.72),(-.52,4.44),(-.76,3.90),(-1.28,3.4),(-1.79,3.9),(-2.04,4.44)],-.43,.13)
box("GoldLight",(-1.28,-.54,4.89),(.23,.10,1.6))
box("GoldLight",(-1.28,-.55,5.02),(1.12,.10,.23))
disc_pixels((1.3,-.23,4.73),1.12,.25,[(.30,"GoldLight"),(.75,"Wood"),(.91,"Gold"),(1.12,"Iron")],.18)
box("WoodEnd",(1.3,-.45,4.73),(.18,.12,1.6))
for dx in [-.5,.5]:box("IronDark",(1.3+dx,-.43,4.73),(.11,.10,1.4))
collider((0,0,3.5),(5.8,.7,7))

prop("QuestBoard",(5.4,16.9,0),0)
for x in [-2.5,2.5]:
    foot(x,0,1.05,1.55)
    plank((x,0,4.5),(.48,.55,8.7),"z","WoodDark")
for i in range(9):plank(((i-4)*.57,.05,6.4),(.55,.34,3.75),"z")
for z in [4.38,8.44]:plank((0,-.14,z),(5.4,.35,.34),material="WoodLight")
for y in [-.45,.1,.65]:plank((0,y,8.76),(6.1,.57,.25),material="WoodLight")
symbols=[["00100","00100","11111","00100","00100"],
         ["01110","01110","01110","00100","00000","00100"],
         ["00100","01110","01010","11011","10001","11111"]]
for column in range(3):
    xx=(column-1)*1.53
    box("WoodDark",(xx,-.21,6.46),(1.41,.12,2.78))
    box("Paper",(xx,-.32,6.48),(1.28,.11,2.60))
    box("Ivory",(xx-.06,-.39,6.60),(1.12,.035,2.22))
    for px,pz in [(-.51,1.16),(.5,-1.15)]:peg((xx+px,-.40,6.48+pz),"GoldDark")
    for j,row in enumerate(symbols[column]):
        for i,pixel in enumerate(row):
            if pixel=="1":box("Ink",(xx+(i-2)*.145,-.433,6.9-j*.16),(.15,.032,.16))
    for i in range(2):box("WoodLight",(xx,-.438,5.76+i*.19),(.76-i*.19,.03,.055))
collider((0,0,4.5),(5.8,1.1,9))


def stone_box(center,size,rows=3,cols=3,top_studs=False):
    x,y,z=center;w,d,h=size
    box("StoneDark",center,size)
    rowh=h/rows
    for row in range(rows):
        offset=(row%2)*w/cols/2
        for k in range(cols+1):
            left=max(-w/2,-w/2+(k-1)*w/cols+offset)
            right=min(w/2,-w/2+k*w/cols+offset)
            if right-left<.04:continue
            zz=z-h/2+(row+.5)*rowh
            for yy in [y-d/2-.035,y+d/2+.035]:
                mat=RNG.choice(["Stone","Stone","StoneLight"])
                box(mat,(x+(left+right)/2,yy,zz),(right-left-.045,.10,rowh-.055))
    for xx in [x-w/2-.025,x+w/2+.025]:
        for row in range(rows):
            for k in range(max(1,round(d/.75))):
                count=max(1,round(d/.75));span=d/count
                box(RNG.choice(["Stone","StoneLight"]),(xx,y-d/2+(k+.5)*span,z-h/2+(row+.5)*rowh),(.09,span-.045,rowh-.055))
    if top_studs:stud_grid("StoneLight",(x,y,z+h/2+.01),w,d,pitch=.65)


# Hollow well, thick stone coping, timber roof and suspended wooden bucket.
prop("RoofedWell",(16.2,18,0),0)
stone_box((0,-1.85,1.35),(6.4,.8,2.7),4,7)
stone_box((0,1.85,1.35),(6.4,.8,2.7),4,7)
for x in [-2.8,2.8]:stone_box((x,0,1.35),(.8,3.0,2.7),4,1)
for y in [-1.85,1.85]:
    stone_box((0,y,2.83),(6.8,1.04,.40),1,7,True)
for x in [-2.9,2.9]:stone_box((x,0,2.83),(1.0,2.85,.40),1,1,True)
box("Water",(0,0,.30),(4.65,2.85,.18))
for x in [-2.4,2.4]:
    plank((x,0,6.15),(.45,.55,6.4),"z","WoodWarm")
    box("WoodLight",(x-.18,-.30,6.15),(.12,.08,6.3))
    box("Iron",(x,0,5.7),(.64,.7,.34))
    beam("Wood",(x,0,7.5),(x,1.4,8.76),.30)
beam("WoodDark",(-3.3,0,9.55),(3.3,0,9.55),.4)
for x in [-3.3,3.3]:
    beam("WoodDark",(x,-2.6,7.92),(x,0,9.8),.40)
    beam("WoodDark",(x,0,9.8),(x,2.6,7.92),.40)
for side in [-1,1]:
    start=Vector((0,side*2.65,7.91)); end=Vector((0,0,9.84)); delta=end-start
    rot=delta.to_track_quat("Y","Z").to_matrix()
    for i in range(12):
        xx=(i-5.5)*.58
        mat=["WoodLight","WoodWarm","Wood"][i%3]
        box(mat,Vector((xx,0,0))+(start+end)/2,(.55,delta.length,.24),rot)
        for j in range(3):
            normal=Vector((0,side*delta.z,abs(delta.y))).normalized()
            p=start+delta*((j+.5)/3)+Vector((xx,0,0))+normal*.14
            stud(mat,p,.20,.055,u=(-side,0,0),v=tuple(delta.normalized()))
            q=start+delta*((j+.5)/3)+Vector((xx+.13,0,0))+normal*.145
            beam("WoodDark",q-delta.normalized()*.29,q+delta.normalized()*.29,.035)
        box("WoodDark",(xx,side*2.55,8.04),(.19,.14,.12))
beam("WoodLight",(-3.6,-2.62,7.85),(3.6,-2.62,7.85),.3)
box("WoodDark",(0,0,6.1),(5.0,.27,.27))
box("GoldDark",(0,0,4.96),(.105,.105,2.0))
for i in range(8):
    a=i*math.tau/8
    box(["Wood","WoodLight"][i%2],(math.sin(a)*.50,math.cos(a)*.50,3.44),(.34,.30,.9))
for z in [3.05,3.7]:
    for x,y,w,d in [(0,-.57,1.1,.12),(0,.57,1.1,.12),(-.57,0,.12,1.1),(.57,0,.12,1.1)]:box("Iron",(x,y,z),(w,d,.15))
for x in [-.47,.47]:box("IronDark",(x,0,4.03),(.10,.10,.66))
box("IronDark",(0,0,4.34),(1.03,.10,.1))
# Cantilevered lantern on the right post.
beam("WoodWarm",(2.45,0,8.76),(5.6,0,8.76),.32)
beam("WoodLight",(2.45,0,7.35),(4.1,0,8.65),.28)
box("IronDark",(5.05,0,8.22),(.25,.24,.96))
box("Iron",(5.05,0,6.85),(1.22,1.14,1.8))
for x in [-.43,0,.43]:
    box("GoldLight",(5.05+x,-.59,6.85),(.23,.045,1.22))
    box("IronDark",(5.05+x+.19,-.63,6.85),(.11,.10,1.58))
box("IronDark",(5.05,0,5.92),(1.5,1.4,.23))
box("IronDark",(5.05,0,7.80),(1.5,1.4,.22))
box("Iron",(5.05,0,8.0),(1.13,1.0,.22))
for center,size in [((0,0,1.4),(6.5,4.5,2.8)),((-2.4,0,6),(.6,.7,6.3)),((2.4,0,6),(.6,.7,6.3))]:collider(center,size)

# Octagonal tavern table with plate, tankard, loaf and candle.
prop("TavernTable",(6.8,1.2,0),0)
for z,r,h in [(.18,.95,.36),(.43,.75,.22),(1.48,.31,1.9),(2.52,1.65,.30)]:
    polygon=[(math.sin(i*math.tau/8)*r,math.cos(i*math.tau/8)*r) for i in range(8)]
    vs=[(x,y,z-h/2) for x,y in polygon]+[(x,y,z+h/2) for x,y in polygon]
    geom("Wood" if z<2 else "WoodWarm",vs,[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)])
for x in [-.9,-.3,.3,.9]:
    box("WoodDark",(x,0,2.68),(.035,2.2 if abs(x)>.5 else 3.02,.026))
stud_grid("WoodLight",(0,0,2.70),2.4,2.4,.6)
candle(-.93,.12,2.74,1.02)
box("GoldDark",(.43,-.55,2.81),(.92,.72,.15))
box("GoldLight",(.43,-.55,2.92),(.72,.53,.08))
box("WoodEnd",(.61,.60,2.93),(.92,.49,.36))
for x in [.35,.65,.90]:box("Ivory",(x,.60,3.12),(.055,.40,.035))
box("Gold",(-.36,-.54,3.07),(.40,.44,.62))
box("WoodDark",(-.36,-.54,3.4),(.27,.3,.035))
for z in [2.88,3.23]:box("GoldLight",(-.67,-.53,z),(.3,.14,.13))
box("GoldLight",(-.80,-.53,3.055),(.12,.14,.4))
collider((0,0,1.4),(3.3,3.3,2.8))

prop("CandlePedestal",(14.1,1.8,0),0)
stone_box((0,0,.22),(3.45,2.8,.44),1,4,True)
stone_box((0,0,1.32),(2.7,2.22,1.9),3,3)
stone_box((0,0,2.48),(3.6,2.95,.44),1,4,True)
box("Burgundy",(.55,0,2.74),(.83,2.94,.085))
box("BurgundyLight",(.55,-1.50,2.14),(.83,.10,1.3))
box("Gold",(.22,-1.57,2.14),(.075,.06,1.23))
box("Gold",(.87,-1.57,2.14),(.075,.06,1.23))
for x,y,h in [(-1,-.7,.80),(-1,.63,1.15),(.95,.65,.70)]:candle(x,y,2.8,h)
box("StoneLight",(-.40,-1.20,1.34),(.3,.22,1.3))
box("StoneLight",(-.40,-1.20,1.55),(1.0,.22,.32))
collider((0,0,1.35),(3.5,2.9,2.7))

prop("AlchemyBench",(22.5,8.5,0),0)
for x in [-1.4,1.4]:
    for y in [-.7,.7]:plank((x,y,1.2),(.32,.36,2.4),"z","Wood")
for y in [-.67,0,.67]:plank((0,y,2.48),(3.5,.64,.25))
for x in [-1.4,1.4]:beam("WoodLight",(x,-.9,.35),(x,.9,.35),.23)
for x,y,h,col in [(-.8,.0,.7,"IronLight"),(.0,.42,1.15,"StoneLight"),(.88,.0,.6,"Teal")]:
    box(col,(x,y,2.65+h*.35),(.52,.51,h*.65))
    box(col,(x,y,2.68+h*.82),(.27,.29,h*.35))
    box("Wood",(x,y,2.72+h),(.3,.30,.13))
    box("SilverLight",(x-.18,y-.27,2.74+h*.30),(.10,.025,h*.35))
box("Paper",(.5,-.50,2.66),(1.1,.62,.055))
collider((0,0,1.3),(3.5,2.1,2.6))

# Voxel masonry and barred wooden door.
prop("StoneGate",(28.4,21.5,0),0)
for x in [-1.35,1.35]:
    stone_box((x,0,2.55),(.92,1.1,5.1),7,1)
    stone_box((x,0,5.25),(1.13,1.28,.44),1,1,True)
for i in range(5):plank(((i-2)*.42,.13,2.46),(.36,.26,4.7),"z","WoodLight")
for z in [.87,2.45,4.04]:
    box("Iron",(0,-.1,z),(2.08,.25,.25))
    for x in [-.76,.76]:peg((x,-.25,z))
box("Gold",(.62,-.29,2.23),(.21,.16,.30))
collider((0,0,2.7),(3.9,1.3,5.4))

prop("BrokenStoneWall",(31.8,1.15,0),-5)
stone_box((0,0,.20),(5.5,1.65,.40),1,6,True)
for x,h in [(-2.1,3.7),(-1.05,2.6),(0,2.05),(1.05,3.0),(2.1,4.45)]:
    stone_box((x,0,.4+h/2),(.97,1.12,h),max(3,round(h/.62)),1)
    stone_box((x,0,.52+h),(1.18,1.43,.28),1,1,True)
collider((0,0,2.4),(5.5,1.6,4.8))

prop("Catapult",(30,12.1,0),-7)
for x in [-1.2,1.2]:
    plank((x,0,.50),(.42,3.9,.45),material="WoodDark")
    for y in [-1.35,1.35]:
        box("Wood",(x*1.15,y,.51),(.45,.83,.92))
        box("Iron",(x*1.33,y,.54),(.18,.50,.54))
for y in [-1.4,1.4]:beam("WoodLight",(-1.4,y,.75),(1.4,y,.75),.35)
for x in [-.8,.8]:
    beam("WoodWarm",(x,-1.4,.75),(x,.10,3.05),.37)
    beam("WoodLight",(x,1.4,.75),(x,.10,3.05),.37)
beam("IronDark",(-1.14,.1,2.94),(1.14,.1,2.94),.28)
beam("Wood",(0,-1.52,1.42),(0,1.8,5.22),.40,.55)
box("WoodDark",(0,1.85,5.30),(1.04,.85,.36))
for x in [-.47,.47]:box("Wood",(x,1.85,5.6),(.17,.88,.5))
box("StoneDark",(0,1.85,5.67),(.65,.62,.52))
for x in [-.29,.29]:beam("GoldDark",(x,-1.35,1.4),(x,.6,3.92),.065)
collider((0,0,1.1),(3.3,4,2.2))


def sword(x,y,z,height=3.4,grip="Teal",lean=0):
    global TRANSFORM
    previous=TRANSFORM.copy()
    TRANSFORM=TRANSFORM @ Matrix.Translation(Vector((x,y,z))) @ Matrix.Rotation(math.radians(lean),4,"Y")
    polygon_extrude("Silver",[(-.19,.24),(-.19,height*.65),(.19,height*.65),(.19,.24),(0,0)],0,.16)
    box("SilverLight",(-.065,-.10,height*.35),(.10,.055,height*.53))
    box("IronDark",(0,0,height*.7),(.79,.26,.20))
    box("Gold",(-.43,0,height*.7),(.15,.29,.28))
    box("Gold",(.43,0,height*.7),(.15,.29,.28))
    box(grip,(0,0,height*.84),(.22,.22,height*.24))
    for zz in [.77,.84,.91]:box("IronDark",(0,-.13,height*zz),(.24,.05,.045))
    box("Iron",(0,0,height*.98),(.34,.31,.26))
    TRANSFORM=previous


prop("SwordRack",(17,-8.0,0),0)
for x in [-1.65,1.65]:
    foot(x,0,1.0,1.8)
    plank((x,.24,2.4),(.36,.38,4.2),"z","WoodLight")
for z in [.63,3.13]:plank((0,.35,z),(3.65,.30,.25),material="WoodWarm")
for i,grip in enumerate(["Teal","WoodDark","Teal","Burgundy"]):sword((i-1.5)*.78,-.12,.30,3.9+(.35 if i%2 else 0),grip)
collider((0,.2,2.3),(3.8,.8,4.6))

chest("LargeChest",(25.2,-6.9,0),(4.25,2.8,2.8),0)
chest("SmallChest",(.0,-17.0,0),(2.8,1.9,1.9),-5)

prop("ArrowBundle",(31.15,-5.1,0),4)
for x,y,h in [(-.36,0,3.1),(.2,.12,3.45),(.46,-.24,3.15),(-.12,-.39,3.65),(.15,.39,3.30)]:
    plank((x,y,h/2),(.28,.32,h),"z",RNG.choice(["Wood","WoodLight"]))
for z in [.82,2.32]:
    box("GoldDark",(0,-.59,z),(1.38,.15,.30))
    box("Gold",(0,.58,z),(1.38,.15,.30))
    for x in [-.67,.67]:box("Gold",(x,0,z),(.15,1.2,.30))
collider((0,0,1.8),(1.5,1.5,3.6))

prop("HayBales",(8.4,-12.6,0),0)
for x,y,z,w,d,h in [(-1.2,0,.77,2.25,1.9,1.5),(1.15,0,.77,2.3,1.9,1.5),(0,.25,2.24,2.1,1.8,1.42)]:
    box("Hay",(x,y,z),(w,d,h))
    for i in range(8):
        xx=x+(i-3.5)*w/8
        box(RNG.choice(["HayLight","Hay","HayDark"]),(xx,y-d/2-.025,z),(w/8-.025,.065,h-.04))
        box(RNG.choice(["HayLight","Hay"]),(xx,y,z+h/2+.025),(w/8-.025,d-.05,.08))
    for xx in [x-w*.25,x+w*.25]:
        for yy in [y-d/2-.06,y+d/2+.06]:box("WoodDark",(xx,yy,z),(.15,.12,h+.10))
        box("WoodDark",(xx,y,z+h/2+.09),(.15,d+.15,.10))
    collider((x,y,z),(w,d,h))

# Anvil silhouette is built as stepped iron volumes, with an asymmetric projecting horn.
prop("Anvil",(-9.65,-15.5,0),-3)
foot(0,0,3.5,2.45)
box("WoodDark",(0,0,1.4),(1.4,1.3,2.35))
for x in [-.75,.75]:plank((x,-.04,1.5),(.30,1.38,2.4),"z","WoodLight")
for z in [.62,2.22]:box("WoodWarm",(0,-.77,z),(1.95,.20,.29))
box("IronDark",(0,0,2.73),(2.45,1.66,.33))
box("Iron",(0,0,3.12),(1.66,1.2,.55))
box("IronDark",(0,0,3.57),(1.14,.98,.38))
box("Iron",(0,0,3.98),(2.45,1.45,.52))
box("IronLight",(0,0,4.29),(2.7,1.6,.16))
for i in range(4):
    box("Iron",(-1.45-i*.28,0,4.00+i*.055),(.34,1.2-i*.22,.48-i*.08))
box("IronDark",(.80,.28,4.395),(.28,.27,.05))
for x in [-.8,.8]:peg((x,-.84,2.74))
box("IronDark",(.08,-.67,3.46),(.52,.20,1.05))
box("IronLight",(.08,-.80,3.59),(.28,.09,.60))
for x in [-.79,.84]:stud("Iron",(x,-.78,4.03),.24,.055,v=(0,0,1))
collider((-.24,0,2.2),(4.2,2.3,4.4))

# Brazier has a real open basket and a deliberately block-built flame silhouette.
prop("Brazier",(-22,-17,0),-5)
for x in [-1.1,1.1]:
    for y in [-.8,.8]:
        box("IronDark",(x,y,1.12),(.28,.29,2.24))
        box("Iron",(x,y,.20),(.48,.52,.40))
        box("IronLight",(x-.12,y-.16,.98),(.065,.055,1.5))
box("IronDark",(0,0,1.90),(2.9,2.35,.45))
for y in [-1.05,1.05]:
    box("Iron",(0,y,2.44),(3.12,.27,.36))
    box("IronLight",(0,y-.035,2.68),(3.23,.36,.16))
for x in [-1.42,1.42]:
    box("Iron",(x,0,2.44),(.28,2.35,.36))
    box("IronLight",(x,0,2.68),(.37,2.55,.16))
for x in [-1.0,-.33,.33,1.0]:box("IronDark",(x,-1.19,2.22),(.27,.23,.65))
for x,y,h in [(-.87,-.1,.86),(-.47,.20,1.65),(-.03,-.35,1.4),(.4,.25,2.0),(.82,-.05,1.18)]:
    box("FireOrange",(x,y,2.65+h*.30),(.43,.54,h*.66))
    box("FireGold",(x-.04,y-.15,2.77+h*.55),(.30,.34,h*.65))
    box("FireLight",(x-.02,y-.34,2.79+h*.37),(.19,.16,h*.45))
collider((0,0,1.4),(3.3,2.6,2.8))

# Export one mesh per prop/material so Studio can keep simple editable colors.
objects=[];meshinfo={}
for (owner,material),(vertices,faces) in GROUPS.items():
    name=owner+"__"+material
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    mesh.materials.append(MATERIALS[material]);mesh.calc_loop_triangles()
    assert len(mesh.loop_triangles)<20000,(name,len(mesh.loop_triangles))
    assert all(p.area>1e-10 for p in mesh.polygons), name
    obj=bpy.data.objects.new(name,mesh);SCENE.collection.objects.link(obj);objects.append(obj)
    meshinfo[name]={"prop":owner,"material":material,"triangles":len(mesh.loop_triangles)}
for obj in SCENE.objects:obj.select_set(False)
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/("MedievalStudShowcase_"+REV+".fbx")),use_selection=True,
    object_types={"MESH"},axis_forward="-Z",axis_up="Y",apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
manifest={"revision":REV,"palette":PALETTE,"props":PROPS,"meshes":meshinfo,"units":"studs",
    "authorAxes":"X right, Y depth, Z up","geometryCount":len(objects),
    "triangles":sum(m["triangles"] for m in meshinfo.values()),"propCount":len(PROPS)}
(OUT/("manifest_"+REV+".json")).write_text(json.dumps(manifest,indent=2))

# Preview-only ground uses a repeatable square relief; Roblox gets native Plastic studs.
ground_mat=bpy.data.materials.new("PreviewStudGround");ground_mat.use_nodes=True
nodes=ground_mat.node_tree.nodes;links=ground_mat.node_tree.links
shader=nodes.get("Principled BSDF");shader.inputs["Base Color"].default_value=(.07,.40,.18,1)
shader.inputs["Roughness"].default_value=.82
tex=nodes.new("ShaderNodeTexCoord");sep=nodes.new("ShaderNodeSeparateXYZ");links.new(tex.outputs["Object"],sep.inputs[0])
parts=[]
for axis in ["X","Y"]:
    fract=nodes.new("ShaderNodeMath");fract.operation="PINGPONG";fract.inputs[1].default_value=.5;links.new(sep.outputs[axis],fract.inputs[0])
    ramp=nodes.new("ShaderNodeMapRange");ramp.interpolation_type="SMOOTHSTEP"
    ramp.inputs["From Min"].default_value=.13;ramp.inputs["From Max"].default_value=.19
    links.new(fract.outputs[0],ramp.inputs["Value"]);parts.append(ramp)
multiply=nodes.new("ShaderNodeMath");multiply.operation="MULTIPLY"
for i,part in enumerate(parts):links.new(part.outputs[0],multiply.inputs[i])
bump=nodes.new("ShaderNodeBump");bump.inputs["Strength"].default_value=.8;bump.inputs["Distance"].default_value=.12
links.new(multiply.outputs[0],bump.inputs["Height"]);links.new(bump.outputs["Normal"],shader.inputs["Normal"])
ground_mesh=bpy.data.meshes.new("PreviewGround");ground_mesh.from_pydata([(-400,-400,-.025),(400,-400,-.025),(400,400,-.025),(-400,400,-.025)],[],[(0,1,2,3)])
ground=bpy.data.objects.new("PreviewGround",ground_mesh);SCENE.collection.objects.link(ground);ground_mesh.materials.append(ground_mat)
world=bpy.data.worlds.new("PreviewSky");world.use_nodes=True;world.node_tree.nodes["Background"].inputs[0].default_value=(.52,.69,.82,1)
world.node_tree.nodes["Background"].inputs[1].default_value=.65;SCENE.world=world
sun_data=bpy.data.lights.new("PreviewSun","SUN");sun_data.energy=2.3;sun_data.angle=.10
sun=bpy.data.objects.new("PreviewSun",sun_data);SCENE.collection.objects.link(sun);sun.rotation_euler=(.55,-.48,-.52)
camera_data=bpy.data.cameras.new("PreviewCamera");camera=bpy.data.objects.new("PreviewCamera",camera_data);SCENE.collection.objects.link(camera);SCENE.camera=camera
SCENE.render.engine="CYCLES";SCENE.cycles.samples=24;SCENE.cycles.use_denoising=True
SCENE.render.resolution_x=1700;SCENE.render.resolution_y=1100;SCENE.render.resolution_percentage=100
SCENE.view_settings.view_transform="Standard"
for name,position,look,lens in [("overview",(18,-64,39),(3,2,3.5),45),
                                ("craft",(-21,-23,13),(-9,-1,4),46),
                                ("well",(25,-4,16),(11.3,11.7,4.7),48)]:
    camera.location=position;camera.rotation_euler=(Vector(look)-camera.location).to_track_quat("-Z","Y").to_euler();camera_data.lens=lens
    SCENE.render.filepath=str(OUT/(REV+"_"+name+".png"));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/("MedievalStudShowcase_"+REV+".blend")))
print(json.dumps({"revision":REV,"props":len(PROPS),"meshes":len(objects),"triangles":manifest["triangles"]}))
