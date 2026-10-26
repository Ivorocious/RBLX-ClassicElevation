"""Author the C13 terminal, depot canopy and enlarged train in an isolated Blender scene."""
import json
import math
import sys
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
sys.path.insert(0, str(OUT))
api = {"__file__": str(OUT / "build_city.py")}
exec(compile((OUT / "build_city.py").read_text().split("# Market storefronts frame")[0],
             str(OUT / "build_city.py"), "exec"), api)
api["groups"].clear()
api["components"].clear()
scene = api["scene"]
scene.name = "CityRun_C13_Terminal"
definitions = {}


def p(x, y, z):
    return x - 3500, y, z


def component(name, section="Depot", pivot=None):
    api["owner"](name, section)
    definitions[name] = dict(section=section, pivot=pivot)


def unit(suffix):
    base=api["component"].split("_Unit_")[0]
    component(base+"_Unit_"+suffix, definitions[base]["section"])


def box(mat, pos, size):
    api["box"](mat, p(*pos), size)


def beam(mat, a, b, radius=.16, sides=8):
    api["beam"](mat, p(*a), p(*b), radius, sides)


def text(body, pos, size=1.2, mat="Cream", rotation=0):
    previous=api["component"]
    component(previous+"_Lettering_"+body.replace(" ","_").replace("/","_"),"Lettering")
    api["text"](body, p(*pos), size, mat, rotation)
    api["owner"](previous)


def prism(mat, profile, z0, z1):
    n = len(profile)
    vertices = [p(x, y, z) for z in (z0, z1) for x, y in profile]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1) % n, (i+1) % n+n, i+n) for i in range(n)]
    api["geo"](mat, vertices, faces)



def gable_roof(name,x0,x1,eave,ridge,z0,z1,mat='Copper'):
    middle=(x0+x1)/2
    for side,profile in [('Left',[(x0,eave),(middle,ridge),(middle,ridge+.6),(x0,eave+.6)]),('Right',[(middle,ridge),(x1,eave),(x1,eave+.6),(middle,ridge+.6)])]:
        component(name+'_'+side,'RoofPanel')
        prism(mat,profile,z0,z1)


# The terminal kit uses broad planes and shallow inset windows instead of residential trim.
for name,col in {'Limestone':(.79,.77,.66),'PaleStone':(.94,.91,.81),'Ink':(.065,.12,.17),'TerminalGlass':(.12,.25,.30),'Copper':(.42,.27,.20),'CopperLight':(.77,.47,.24),'Gold':(.90,.66,.25)}.items():
    api['COLORS'][name]=col
    m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); api['MATS'][name]=m


def arch_window(x,y,z,w,h,axis='z'):
    previous=api["component"]
    component(previous+f"_Window_{x:.1f}_{y:.1f}_{z:.1f}_{axis}", "FacadeBay")
    # One flat arch silhouette and a shallow rim: no tessellated brick or bevel stacks.
    def transform(v):
        xx,yy,zz=v
        return (xx,yy,zz) if axis=='z' else (z+(zz-z),yy,x+(xx-x))
    rad=w/2; spring=y+h/2-rad; bottom=y-h/2
    profile=[(x-rad,bottom),(x+rad,bottom)]+[(x+rad*math.cos(i*math.pi/12),spring+rad*math.sin(i*math.pi/12)) for i in range(13)]
    verts=[p(*transform((xx,yy,z))) for xx,yy in profile]
    api['geo']('TerminalGlass',verts,[tuple(range(len(verts))),tuple(reversed(range(len(verts))))])
    for i in range(12):
        a=i*math.pi/12;b=(i+1)*math.pi/12
        beam('PaleStone',transform((x+rad*math.cos(a),spring+rad*math.sin(a),z-.09)),transform((x+rad*math.cos(b),spring+rad*math.sin(b),z-.09)),.28,4)
    for xx in (x-rad,x+rad): beam('PaleStone',transform((xx,bottom,z-.09)),transform((xx,spring,z-.09)),.28,4)
    beam('CopperLight',transform((x,bottom,z-.13)),transform((x,spring+rad-.2,z-.13)),.12,4)
    beam('CopperLight',transform((x-rad,y,z-.13)),transform((x+rad,y,z-.13)),.12,4)
    api['owner'](previous)


def block(name,x,z,w,d,h,roof=True):
    component(name,'Terminal')
    box('Limestone',(x,h/2,z),(w,h,d))
    for yy in (3,h-2): box('PaleStone',(x,yy,z),(w+.45,1.4,d+.45))
    box('Ink',(x,h-.5,z),(w+.5,.8,d+.5))
    if roof:
        unit('Roof');box('Copper',(x,h+.15,z),(w,.4,d));api['owner'](name)
    for sx in (-1,1):
        for zz in (z-d/2+1,z+d/2-1): box('PaleStone',(x+sx*(w/2-.65),h/2,zz),(1.3,h,1.6))
    component(name+'_LowerBays','FacadeBay')
    for y in range(18,int(h-29),18):
        for sign in (-1,1):
            for xx in range(round(x-w/2+6),round(x+w/2-3),10):
                box('TerminalGlass',(xx,y,z+sign*(d/2+.04)),(4.4,8,.12))
                box('PaleStone',(xx,y-4.2,z+sign*(d/2+.18)),(5.4,.45,.5))
            for zz in range(round(z-d/2+7),round(z+d/2-3),12):
                box('TerminalGlass',(x+sign*(w/2+.04),y,zz),(.12,8,4.4))
                box('PaleStone',(x+sign*(w/2+.18),y-4.2,zz),(.5,.45,5.4))
    component(name,'Terminal')
    # Broad glazing in the upper, player-visible storey.
    for sz in (-1,1):
        face=z+sz*(d/2+.03)
        for xx in range(round(x-w/2+7),round(x+w/2-4),12):
            arch_window(xx,h-15,face,7,22)
    for sx in (-1,1):
        face=x+sx*(w/2+.03)
        for zz in range(round(z-d/2+8),round(z+d/2-5),15):
            arch_window(zz,h-15,face,8,22,'x')

# Bilateral shed: columns stand on the retained viaduct. The centre stays 25 studs wide.
component('C13_DepotWest','Depot')
box('Ink',(3645,87,-163),(12,26,110))
box('Limestone',(3645,37,-163),(12,74,110))
box('PaleStone',(3645,74,-163),(13,1.2,110))
for z in (-211,-181,-151,-121):
    box('TerminalGlass',(3651.05,89,z),(.13,13,21))
    for zz in (z-11,z+11): box('PaleStone',(3651.4,87,zz),(1.2,26,1.5))
    box('CopperLight',(3651.3,96,z),(.25,.3,22))
    box('Light',(3651.7,94,z),(.25,.35,4))
box('Copper',(3645,101,-163),(14,1.2,112))
component('C13_DepotCanopy','Depot')
for z in (-215,-180,-145,-110):
    for x in (3652.3,3675.1):
        box('PaleStone',(x,86.5,z),(1.3,25,1.5))
        box('Ink',(x,75,z),(2.6,2,2.6))
        beam('Ink',(x,93,z),(3665,101,z),.28,6)
    box('Ink',(3665,100.4,z),(26,1.1,1.5))
# Alternating solid roofs and bright clerestory slots avoid a blank continuous ceiling.
for z in (-200,-165,-130):
    gable_roof('C13_DepotCanopy_'+str(-z),3651,3676.5,100.5,106,z-13,z+13,'Ink')
    box('CopperLight',(3665,106.75,z),(.5,.25,27))
for x in (3651,3676.5): box('CopperLight',(x,101,-163),(.5,.6,112))
for z in (-204,-166,-128):
    box('Ink',(3665,98,z),(11,2,.3))
    text('DEPOT  /  03',(3665,98,z-.2),.9,'PaleStone',math.pi)

# Substantial Riverside portal, open through the centre of the existing CP07 route.
component('C13_RiversidePortal','Terminal')
for x in (3686,3724):
    component('C13_PortalPier_'+str(x),'Terminal')
    box('Limestone',(x,47,30),(7,94,27))
    box('PaleStone',(x,94,30),(8,1.3,28))
    box('Ink',(x,89,16.35),(5,7,.25))
    arch_window(x,88.5,16.1,3.6,7)
for x in (3693,3717):
    component('C13_PortalColumn_'+str(x),'Terminal')
    box('PaleStone',(x,48,26),(1.6,96,2))
    box('CopperLight',(x,96.8,26),(2.5,.5,2.8))
component('C13_PortalBearing','Terminal')
box('PaleStone',(3705,95.85,30),(46,2.5,28))
component('C13_PortalCanopy','Terminal')
box('Ink',(3705,99,30),(47,4,30))
box('Copper',(3705,101.4,30),(49,.8,32))
box('Gold',(3705,97.3,14.7),(45,.3,.3))
text('RIVERSIDE TERMINAL',(3705,99,14.75),2,'PaleStone',math.pi)
for x in (3690,3720):
    box('Ink',(x,90.5,14),(1.2,2.8,1.2));box('Light',(x,90.5,13.33),(.6,1.5,.2))
# Deep ceiling strips provide enclosure without blocking sight of the first rising steps.
for z in (23,31,39):box('CopperLight',(3705,97,z),(23,.28,.5))

block('C13_StationBase',3775,143,150,180,75)
block('C13_MainHall',3785,137,70,120,103)
block('C13_WestWing',3720,165,32,91,103)
block('C13_NorthGallery',3737,100,24,38,94)
component('C13_GalleryLeanTo','Terminal')
prism('Copper',[(3724,94.5),(3750,102),(3750,102.6),(3724,95.1)],80,120)
for z in (80,119):
    prism('Limestone',[(3725,94),(3749,94),(3749,101.5)],z,z+1)
component('C13_HallEaveBearing','Terminal')
box('PaleStone',(3785,103.3,137),(70,1,120))
component('C13_HallRoof','Terminal')
# A single long ridged hall changes the roof skyline; routes remain outside its footprint.
gable_roof('C13_HallRoof',3749,3821,103.5,121,76,198)
for side,z in [('Front',78),('Rear',195)]:
    component('C13_HallGable_'+side,'Terminal')
    prism('Limestone',[(3750,102.8),(3820,102.8),(3785,120.8)],z,z+1.5)
    box('PaleStone',(3785,103,z+.75),(71,1.2,2))
component('C13_HallRoofSeams','Terminal')
for z in (84,106,128,150,172,190):
    beam('CopperLight',(3749,104.3,z),(3785,121.7,z),.12,4)
    beam('CopperLight',(3785,121.7,z),(3821,104.3,z),.12,4)
component('C13_HallSign','Terminal')
box('Ink',(3785,109,77.7),(45,5,.35))
text('RIVERSIDE',(3785,109,77.45),3,'PaleStone',math.pi)

# Peripheral terminal service blocks occupy the existing facade envelopes.
for name,x,z,w,d,h in [('EastCorner',3883,183,40,46,145),('SouthCourt',3828,274,42,35,140),('EastArcade',3889,119,42,42,134),('SouthHotel',3772,276,39,28,134),('EastArrival',3884,60,38,39,116),('TrackOffice',3796,22,46,24,118)]:
    block('C13_'+name,x,z,w,d,h)

# Close service streets frame the expert climb. Short rear roofs keep the clock crown visible.
for name,x,z,w,d,h in [
 ('ExpertService01',3660,116,28,30,121),('ExpertService02',3660,148,28,30,135),
 ('ExpertService03',3660,181,28,32,145),('ExpertService04',3660,207,28,18,134),
 ('ExpertBack01',3619,124,42,40,135),('ExpertBack02',3619,167,42,40,148),
 ('ExpertBack03',3619,210,42,40,141),
 ('EastLink01',3886,89,40,18,112),('EastLink02',3886,150,40,20,122),
 ('EastReturn',3871,231,56,38,132),('SouthLink01',3799,276,15,28,123),
 ('SouthLink02',3743,276,17,28,126)]:
    block('C13_'+name,x,z,w,d,h)
    if name in ('ExpertService02','ExpertBack01','EastLink02'):
        gable_roof('C13_'+name+'_RoofSlope',x-w/2-.3,x+w/2+.3,h+.35,h+5,z-d/2-.3,z+d/2+.3)
        for side,zz in [('Front',z-d/2),('Rear',z+d/2-.5)]:
            component('C13_'+name+'_Pediment_'+side,'FacadeBay')
            prism('Limestone',[(x-w/2,h),(x+w/2,h),(x,h+4.95)],zz,zz+.5)
    component('C13_'+name+'_RoofVent','RoofDetail')
    vent_h=h+(5 if name in ('ExpertService02','ExpertBack01','EastLink02') else 0)
    box('Ink',(x,vent_h+1.2,z),(7,2,4))
    box('PaleStone',(x,vent_h+2.4,z),(8,.4,5))
    for zz in (-1,0,1):box('CopperLight',(x,vent_h+2.65,z+zz),(6,.1,.13))
    if name.startswith('ExpertService'):
        component('C13_'+name+'_ServiceBalcony','FacadeBay')
        box('Ink',(x+w/2+.8,h-27,z),(1.6,.8,12))
        box('CopperLight',(x+w/2+1.6,h-25.4,z),(.18,2.8,12))
        for dz in (-5,0,5):box('Ink',(x+w/2+1.6,h-25.4,z+dz),(.2,2.8,.2))
        box('Limestone',(x+w/2+.65,h-26,z),(1.1,1.1,6))
        for dz in (-2,0,2):api['sphere']('Leaf',p(x+w/2+.7,h-24.8,z+dz),1.2,6,3,(.65,.7,1))

# The existing terrace is retained at Y132. All new wing columns land on its edges.
block('C13_TerraceFoundation',3695,239,78,40,131.7,False)
block('C13_TowerFoundation',3695,274,38,34,132,False)
component('C13_FinishFacade','Finale')
for x in (3669,3721):
    component('C13_FinishWing_'+str(x),'Finale')
    box('Limestone',(x,79,272),(26,158,26))
    box('PaleStone',(x,158.8,272),(27,1.6,27))
    box('Ink',(x,157,272),(27,1.2,27))
    unit('Soffit');box('Ink',(x,159.8,272),(28,.5,28))
    component('C13_FinishWing_'+str(x)+'_Unit_Roof','RoofPanel')
    gable_roof('C13_FinishWing_'+str(x)+'_Roof',x-14,x+14,160,168,258,286)
    for side,z in [('Front',258.5),('Rear',284.5)]:
        component('C13_FinishWing_'+str(x)+'_Gable_'+side,'Finale')
        prism('PaleStone',[(x-13,159.5),(x+13,159.5),(x,168)],z,z+1)
    component('C13_FinishWing_'+str(x)+'_Facade','Finale')
    for xx in (x-6.5,x+6.5):arch_window(xx,144,258.8,8,23)
    for xx in (x-12,x+12):box('PaleStone',(xx,145,258),(1.3,26,1.5))
box('PaleStone',(3695,149,263),(24,34,3))
arch_window(3695,143,261.35,12,20)
box('Ink',(3695,158.5,261.2),(18,3,.25))
text('CITY RUN',(3695,158.5,260.95),2.3,'Gold',math.pi)
component('C13_ClockTower','Finale')
box('Limestone',(3695,171,274),(23,78,22))
for y in (163,184,202,209):box('PaleStone',(3695,y,274),(25,1.2,24))
for x in (3684,3706):box('PaleStone',(x,173,262.5),(1.5,75,1))
for z in (262.35,285.65):
    beam('Gold',(3695,193,z-.15),(3695,193,z+.15),8.3,32)
    beam('PaleStone',(3695,193,z-.22),(3695,193,z+.22),7.7,32)
    for i in range(12):
        a=i*math.tau/12;xx=3695+6.7*math.sin(a);yy=193+6.7*math.cos(a)
        box('Ink',(xx,yy,z+(-.3 if z<274 else .3)),(.4,1,.12))
    face=z+(-.4 if z<274 else .4)
    beam('Ink',(3695,193,face),(3691,198,face),.2,6)
    beam('Ink',(3695,193,face),(3700,196,face),.16,6)
arch_window(3695,173,262.36,7,14)
component('C13_ClockCrown_Cornice','Finale')
box('PaleStone',(3695,210,274),(27,2,26))
box('Ink',(3695,211.1,274),(28,.4,27))
# Four sealed mansard panels and a small raised lantern replace the diamond pyramid.
rings=[(211.3,14,13.5),(220,8,7.5)]
for i,label in enumerate(['Front','East','Rear','West']):
    component('C13_ClockCrown_'+label,'RoofPanel')
    corners=[(-1,-1),(1,-1),(1,1),(-1,1)]
    a=corners[i];b=corners[(i+1)%4]
    v=[p(3695+dx*w,y,274+dz*d) for y,w,d in rings for dx,dz in (a,b)]
    api['geo']('Copper',v,[(0,1,3,2),(2,3,1,0)])
component('C13_ClockCrown_Lantern','Finale')
box('PaleStone',(3695,221.5,274),(16,3,15))
for z in (266.45,281.55):
    for x in (3690,3695,3700):box('Ink',(x,221.4,z),(2,1.8,.15))
box('Copper',(3695,223.4,274),(18,.8,17))
beam('Gold',(3695,223.8,274),(3695,231,274),.18,6)
# Shallow radiating crown gives a celebratory silhouette with forty simple triangles.
component('C13_FinishColonnades','Finale')
for x in (3669,3721):
    for xx in (x-8,x+8):
        for z in (228,241,254):
            box('PaleStone',(xx,140.5,z),(1.6,17,1.6))
            box('Limestone',(xx,132.7,z),(2.6,1.4,2.6))
            beam('CopperLight',(xx,145,z),(x,150,z),.18,6)
    box('Ink',(x,150,241),(19,1.2,29))
    box('Copper',(x,150.8,241),(20,.4,30))
    for z in (230,242,253):box('Light',(x,149.25,z),(2,.25,.7))
for x in (3658.7,3731.3):
    box('PaleStone',(x,133,243),(1.2,2,30))
    box('CopperLight',(x,134.2,243),(1.5,.35,30))
    for z in (229,243,256):
        box('Ink',(x,136,z),(.45,4,.45));box('Gold',(x,138.6,z),(1.4,1.4,1.4));box('Light',(x,138.6,z-.73),(.8,.8,.08))
component('C13_Goal','Finale')
for x in (3680,3710):
    box('PaleStone',(x,140,232),(2.6,16,2.6))
    box('Gold',(x,147.6,232),(3.6,.8,3.6))
box('Ink',(3695,150.5,232),(35,6.4,2))
box('Gold',(3695,154,232),(37,.6,3))
text('FINISH',(3695,151.5,230.9),3.2,'PaleStone',math.pi)
text('YOU MADE IT',(3695,148.5,230.9),1.15,'Gold',math.pi)
# Thin floor inlay follows the existing walking surface and does not add collision.
for z in (218,220,222,224,226,228):
    for x in (3686,3689,3692,3695,3698,3701,3704):
        if (int((x-3686)/3)+int((z-218)/2))%2==0:box('Ink',(x,132.21,z),(3,.025,2))
for x in (3683.3,3706.7):box('Gold',(x,132.23,221),(.25,.05,21))
for x in (3670,3720):
    box('Limestone',(x,133,250),(9,2,5))
    box('Ink',(x,134.04,250),(8,.1,4))
    for dx in (-2.5,0,2.5):api['sphere']('Leaf',p(x+dx,135.7,250),2.1,7,4,(1,.8,1))


# Native route colliders remain in Studio. Each authored visual uses their saved footprint.
for item in json.loads((OUT/'c13_route_visual_input.json').read_text()):
    name=item['name'];x,y,z=item['position'];w,_,d=item['size'];top=y+.5
    if name in ('X03_00_00','X03_01_10','StationMain_04_03'):continue
    component('C13_Surface_'+name,'RouteVisual',[x,top,z])
    if name.startswith('X03_'):
        skin_y=top-.45-(.0508041381836 if name=='X03_01_02' else 0)
        box('Ink',(x,skin_y,z),(w,.9,d))
        component('C13_Surface_'+name+'_Slab','RouteVisual',[x,top,z])
        box('PaleStone',(x,top-.08,z),(w-.3,.16,d-.3))
        component('C13_Surface_'+name+'_Edges','RouteVisual',[x,top,z])
        for dz in (-d/2+.2,d/2-.2):box('Yellow',(x,top+.035,z+dz),(w,.06,.32))
        for dz in (-d/2+.65,d/2-.65):
            for dx in (-w/2+.55,w/2-.55):box('CopperLight',(x+dx,top+.03,z+dz),(.17,.05,.17))
    else:
        base=75 if z<180 else 103
        # Taller exposed pillars need full masonry down to the terminal podium.
        if x<3736:base=75
        h=max(1,top-1.3-base)
        box('Limestone',(x,base+h/2,z),(w-1.1,h,d-1.1))
        component('C13_Surface_'+name+'_Coping','RouteVisual',[x,top,z])
        box('Ink',(x,top-1.05,z),(w-.1,.5,d-.1))
        if name!='StationMain_00_00':box('PaleStone',(x,top-.35,z),(w,.7,d))
        component('C13_Surface_'+name+'_Edges','RouteVisual',[x,top,z])
        for dx in (-w/2+.5,w/2-.5):box('Yellow',(x+dx,top+.035,z),(.25,.06,min(4,d-1)))
        if h>9:
            component('C13_Surface_'+name+'_Inset','RouteVisual')
            box('Ink',(x,top-5.2,z-d/2+.48),(min(w-3,5),5,.12))
            box('CopperLight',(x,top-5.2,z-d/2+.40),(.15,5,.1))

component('C13_FinishApproachSkirt','RouteVisual')
box('Limestone',(3695,103,195.5),(22.9,56,46))
for x in (3683.8,3706.2):box('PaleStone',(x,113,195.5),(1,35,46))
for z in (181,196,211):
    for x in (3683.5,3706.5):box('Ink',(x,115,z),(.15,18,6))
for z in (95,135,175):
    top=min(128.5,89+(z-57)*46/127)
    component('C13_ExpertPier_'+str(z),'RouteSupport')
    box('Limestone',(3701,(75+top)/2,z),(2.1,top-75,2.4))
    box('PaleStone',(3701,top,z),(3.2,.7,3.4))
component('C13_ExpertStringer','RouteSupport')
beam('Ink',(3701,84.6,57),(3701,130.6,184),.22,8)
for item in json.loads((OUT/'c13_route_visual_input.json').read_text()):
    if not item['name'].startswith('X03_') or item['name']=='X03_00_00':continue
    x,y,z=item['position'];y+=.5
    component('C13_Bracket_'+item['name'],'RouteSupport',[x,y,z])
    beam('Ink',(x-1.8,y-.9,z),(3701,y-.9,z),.19,6)
    beam('Ink',(x,y-.9,z),(3701,y-3,z),.12,6)

# Replace the protruding viaduct caps with one flush coping and separate wall bays.
component('C13_DepotDeck','Depot')
box('Ink',(3684,72.8,-154),(66,2.4,142))
for x in (3652,3717):
    segments=[(-225,-124.5),(-107.5,-83)] if x==3717 else [(-225,-83)]
    for i,(z0,z1) in enumerate(segments):
        component('C13_DepotWall_'+str(x)+'_'+str(i),'Depot')
        box('Limestone' if x==3652 else 'Brick',(x,36.5,(z0+z1)/2),(2,73,z1-z0))
        box('PaleStone',(x,73.55,(z0+z1)/2),(2.2,1.1,z1-z0))
for z in (-214,-185,-156,-127,-98):
    component('C13_DepotPier_'+str(-z),'Depot')
    box('Limestone',(3681,36,z),(4,72,4))
    for x in (3654,3714):beam('Ink',(x,56,z),(3681,72,z),.5,6)
for x in (3665,3682,3698):
    component('C13_DepotRailBed_'+str(x),'Depot')
    box('Roof',(x,74.15,-154),(12.8,.65,140))
    for z in range(-222,-84,4):box('WoodDark',(x,74.65,z),(10.8,.28,.8))
    for dx in (-4.65,4.65):box('Rail',(x+dx,74.95,-154),(.28,.35,139))

# Close the six exposed sawtooth ends of the retained east maintenance shed.
for bay in (-199,-163,-127):
    for side,z in [('Front',bay-17.3),('Rear',bay+16.7)]:
        component('C13_DepotEndcap_'+str(-bay)+'_'+side,'Depot')
        prism('Roof',[(3677.6,99.5),(3714.8,99.5),(3714.8,100.1),(3677.6,108.5)],z,z+.6)

for key, pos in (("Origin", (3500, 0, 0)), ("Right", (3510, 0, 0)),
                 ("Up", (3500, 10, 0)), ("Forward", (3500, 0, -10))):
    component("Marker"+key, "Calibration")
    box("Iron", pos, (.1, .1, .1))

definitions={k:v for k,v in definitions.items() if any(name==k for name,mat in api["groups"])}
# A building assembly moves all its independent facade and roof units together.
assembly_names=sorted([name for name in definitions if name.startswith('C13_') and any(name.endswith(tail) for tail in ('MainHall','WestWing','NorthGallery','EastCorner','SouthCourt','EastArcade','SouthHotel','EastArrival','TrackOffice','StationBase','TerraceFoundation','TowerFoundation')) or name.startswith(('C13_ExpertService','C13_ExpertBack','C13_EastLink','C13_EastReturn','C13_SouthLink')) and '_Roof' not in name and '_Window' not in name and '_Lower' not in name and '_Unit_' not in name and '_ServiceBalcony' not in name and '_Pediment' not in name],key=len,reverse=True)
for name,definition in definitions.items():
    family=next((base for base in assembly_names if name==base or name.startswith(base+'_')),None)
    if name.startswith(('C13_HallRoof','C13_HallGable','C13_HallSign','C13_HallEave')):family='C13_MainHall'
    if name.startswith('C13_GalleryLeanTo'):family='C13_NorthGallery'
    if name.startswith(('C13_Portal','C13_RiversidePortal')):family='C13_RiversidePortal'
    if name.startswith(('C13_Clock','C13_FinishWing','C13_FinishColonnades','C13_Goal')):family='C13_FinalStation'
    if name.startswith('C13_Surface_'):
        chunks=name.split('_');family='_'.join(chunks[:5])
    if not family:family='C13_'+definition['section']
    definition['assembly']=family
collections={}
for family in set(d['assembly'] for d in definitions.values()):
    collection=bpy.data.collections.new(family);scene.collection.children.link(collection);collections[family]=collection

meshes, objects = {}, []
for (name, material), chunks in api["groups"].items():
    for index, (vertices, faces) in enumerate(chunks):
        mesh_name = f"{name}__{material}__{index:02}"
        mesh = bpy.data.meshes.new(mesh_name)
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.append(api["MATS"][material])
        mesh.update()
        import bmesh
        bm=bmesh.new();bm.from_mesh(mesh)
        if definitions[name]["section"] != "Lettering":bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(mesh);bm.free()
        mesh.calc_loop_triangles()
        obj = bpy.data.objects.new(mesh_name, mesh)
        collections[definitions[name]["assembly"]].objects.link(obj)
        from mathutils import Vector
        center=sum((v.co for v in mesh.vertices),Vector())/len(mesh.vertices)
        for v in mesh.vertices:v.co-=center
        obj.location=center
        objects.append(obj)
        meshes[mesh_name] = dict(component=name, material=material, triangles=len(mesh.loop_triangles))
for obj in scene.objects:
    obj.select_set(False)
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT / "CityRun_C13_terminal.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = dict(revision="C13_05", components=definitions, meshes=meshes, colors=api["COLORS"])
(OUT / "manifest_C13_terminal.json").write_text(json.dumps(data, indent=2))


def luau(value):
    if value is None:
        return "nil"
    if isinstance(value, dict):
        return "{" + ",".join("[" + json.dumps(k) + "]=" + luau(v) for k, v in value.items()) + "}"
    if isinstance(value, (list, tuple)):
        return "{" + ",".join(map(luau, value)) + "}"
    if isinstance(value, str):
        return json.dumps(value)
    return str(value)


(ROOT / "src/ServerStorage/CourseBuilders/CityRun/C13Manifest.luau").write_text("--!strict\nreturn " + luau(data) + "\n")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CityRun_C13_terminal.blend"))
print(json.dumps(dict(meshes=len(meshes), components=len(definitions),
                      triangles=sum(m["triangles"] for m in meshes.values()))))

# Small additive import avoids re-uploading the unchanged terminal meshes.
for obj in scene.objects:obj.select_set(obj.name.startswith(('C13_DepotEndcap_','Marker')))
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C13_depot_endcaps.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
