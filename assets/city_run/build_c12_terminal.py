"""Author the C12 terminal, depot canopy and enlarged train in an isolated Blender scene."""
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
scene.name = "CityRun_C12_Terminal"
definitions = {}


def p(x, y, z):
    return x - 3500, y, z


def component(name, section="Depot", pivot=None):
    api["owner"](name, section)
    definitions[name] = dict(section=section, pivot=pivot)


def box(mat, pos, size):
    api["box"](mat, p(*pos), size)


def beam(mat, a, b, radius=.16, sides=8):
    api["beam"](mat, p(*a), p(*b), radius, sides)


def text(body, pos, size=1.2, mat="Cream", rotation=0):
    api["text"](body, p(*pos), size, mat, rotation)


def prism(mat, profile, z0, z1):
    n = len(profile)
    vertices = [p(x, y, z) for z in (z0, z1) for x, y in profile]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1) % n, (i+1) % n+n, i+n) for i in range(n)]
    api["geo"](mat, vertices, faces)



# The terminal kit uses broad planes and shallow inset windows instead of residential trim.
for name,col in {'Limestone':(.79,.77,.66),'PaleStone':(.94,.91,.81),'Ink':(.065,.12,.17),'TerminalGlass':(.12,.25,.30),'Copper':(.57,.29,.15),'CopperLight':(.77,.47,.24),'Gold':(.90,.66,.25)}.items():
    api['COLORS'][name]=col
    m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); api['MATS'][name]=m


def arch_window(x,y,z,w,h,axis='z'):
    # One flat arch silhouette and a shallow rim: no tessellated brick or bevel stacks.
    def transform(v):
        xx,yy,zz=v
        return (xx,yy,zz) if axis=='z' else (z+(zz-z),yy,x+(xx-x))
    rad=w/2; spring=y+h/2-rad; bottom=y-h/2
    profile=[(x-rad,bottom),(x+rad,bottom)]+[(x+rad*math.cos(i*math.pi/12),spring+rad*math.sin(i*math.pi/12)) for i in range(13)]
    verts=[p(*transform((xx,yy,z))) for xx,yy in profile]
    api['geo']('TerminalGlass',verts,[tuple(range(len(verts)))])
    for i in range(12):
        a=i*math.pi/12;b=(i+1)*math.pi/12
        beam('PaleStone',transform((x+rad*math.cos(a),spring+rad*math.sin(a),z-.09)),transform((x+rad*math.cos(b),spring+rad*math.sin(b),z-.09)),.28,4)
    for xx in (x-rad,x+rad): beam('PaleStone',transform((xx,bottom,z-.09)),transform((xx,spring,z-.09)),.28,4)
    beam('CopperLight',transform((x,bottom,z-.13)),transform((x,spring+rad-.2,z-.13)),.12,4)
    beam('CopperLight',transform((x-rad,y,z-.13)),transform((x+rad,y,z-.13)),.12,4)


def block(name,x,z,w,d,h,roof=True):
    component(name,'Terminal')
    box('Limestone',(x,h/2,z),(w,h,d))
    for yy in (3,h-2): box('PaleStone',(x,yy,z),(w+.45,1.4,d+.45))
    box('Ink',(x,h-.5,z),(w+.5,.8,d+.5))
    if roof: box('Copper',(x,h+.15,z),(w,.4,d))
    for sx in (-1,1):
        for zz in (z-d/2+1,z+d/2-1): box('PaleStone',(x+sx*(w/2-.65),h/2,zz),(1.3,h,1.6))
    # Broad glazing only in the upper, player-visible storey.
    for sz in (-1,1):
        face=z+sz*(d/2+.03)
        for xx in range(round(x-w/2+7),round(x+w/2-4),12):
            arch_window(xx,h-15,face,7,22)
    for sx in (-1,1):
        face=x+sx*(w/2+.03)
        for zz in range(round(z-d/2+8),round(z+d/2-5),15):
            arch_window(zz,h-15,face,8,22,'x')

# Bilateral shed: columns stand on the retained viaduct. The centre stays 25 studs wide.
component('C12_DepotWest','Depot')
box('Ink',(3645,87,-163),(12,26,110))
box('Limestone',(3645,37,-163),(12,74,110))
box('PaleStone',(3645,74,-163),(13,1.2,110))
for z in (-211,-181,-151,-121):
    box('TerminalGlass',(3651.05,89,z),(.13,13,21))
    for zz in (z-11,z+11): box('PaleStone',(3651.4,87,zz),(1.2,26,1.5))
    box('CopperLight',(3651.3,96,z),(.25,.3,22))
    box('Light',(3651.7,94,z),(.25,.35,4))
box('Copper',(3645,101,-163),(14,1.2,112))
component('C12_DepotCanopy','Depot')
for z in (-215,-180,-145,-110):
    for x in (3652.3,3677.8):
        box('PaleStone',(x,86.5,z),(1.3,25,1.5))
        box('Ink',(x,75,z),(2.6,2,2.6))
        beam('Ink',(x,93,z),(3665,101,z),.28,6)
    box('Ink',(3665,100.4,z),(29,1.1,1.5))
# Alternating solid roofs and bright clerestory slots avoid a blank continuous ceiling.
for z in (-200,-165,-130):
    prism('Ink',[(3651,100.5),(3665,106),(3679,100.5),(3679,101.2),(3665,106.7),(3651,101.2)],z-13,z+13)
    box('CopperLight',(3665,106.75,z),(.5,.25,27))
for x in (3651,3679): box('CopperLight',(x,101,-163),(.5,.6,112))
for z in (-204,-166,-128):
    box('Ink',(3665,98,z),(11,2,.3))
    text('DEPOT  /  03',(3665,98,z-.2),.9,'PaleStone',math.pi)

# Substantial Riverside portal, open through the centre of the existing CP07 route.
component('C12_RiversidePortal','Terminal')
for x in (3686,3724):
    box('Limestone',(x,47,30),(7,94,27))
    box('PaleStone',(x,94,30),(8,1.3,28))
    box('Ink',(x,89,16.35),(5,7,.25))
    arch_window(x,88.5,16.1,3.6,7)
for x in (3693,3717):
    box('PaleStone',(x,48,26),(1.6,96,2))
    box('CopperLight',(x,96.8,26),(2.5,.5,2.8))
box('Ink',(3705,99,30),(47,4,30))
box('Copper',(3705,101.4,30),(49,.8,32))
box('Gold',(3705,97.3,14.7),(45,.3,.3))
text('RIVERSIDE TERMINAL',(3705,99,14.75),2,'PaleStone',math.pi)
for x in (3690,3720):
    box('Ink',(x,90.5,14),(1.2,2.8,1.2));box('Light',(x,90.5,13.33),(.6,1.5,.2))
# Deep ceiling strips provide enclosure without blocking sight of the first rising steps.
for z in (23,31,39):box('CopperLight',(3705,97,z),(23,.28,.5))

block('C12_StationBase',3775,143,150,180,75)
block('C12_MainHall',3785,137,70,120,103)
block('C12_WestWing',3718,165,35,91,103)
block('C12_NorthGallery',3751,102,35,35,108)
component('C12_HallRoof','Terminal')
# A single long ridged hall changes the roof skyline; routes remain outside its footprint.
prism('Copper',[(3752,103.5),(3785,121),(3818,103.5),(3818,104.1),(3785,121.6),(3752,104.1)],80,194)
for z in (84,106,128,150,172,190):
    beam('CopperLight',(3752,104.3,z),(3785,121.7,z),.12,4)
    beam('CopperLight',(3785,121.7,z),(3818,104.3,z),.12,4)
box('Ink',(3785,109,80),(45,5,.35))
text('RIVERSIDE',(3785,109,79.75),3,'PaleStone',math.pi)

# Peripheral terminal service blocks occupy the existing facade envelopes.
for name,x,z,w,d,h in [('EastCorner',3883,183,40,46,145),('SouthCourt',3828,274,42,35,140),('EastArcade',3889,119,42,42,134),('SouthHotel',3772,276,39,28,134),('EastArrival',3884,60,38,39,116),('TrackOffice',3796,22,46,24,118)]:
    block('C12_'+name,x,z,w,d,h)

# The existing terrace is retained at Y132. All new wing columns land on its edges.
block('C12_TerraceFoundation',3695,239,78,40,130,False)
block('C12_TowerFoundation',3695,274,38,34,132,False)
component('C12_FinishFacade','Finale')
for x in (3669,3721):
    box('Limestone',(x,79,272),(26,158,26))
    box('PaleStone',(x,158.8,272),(27,1.6,27))
    box('Ink',(x,157,272),(27,1.2,27))
    prism('Copper',[(x-14,160),(x,168),(x+14,160),(x+14,160.6),(x,168.6),(x-14,160.6)],258,286)
    for xx in (x-6.5,x+6.5):arch_window(xx,144,258.8,8,23)
    for xx in (x-12,x+12):box('PaleStone',(xx,145,258),(1.3,26,1.5))
box('PaleStone',(3695,149,263),(24,34,3))
arch_window(3695,143,261.35,12,20)
box('Ink',(3695,158.5,261.2),(18,3,.25))
text('CITY RUN',(3695,158.5,260.95),2.3,'Gold',math.pi)
component('C12_ClockTower','Finale')
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
api['cylinder']('Copper',p(3695,218,274),19,17,4,.5)
beam('Gold',(3695,226.5,274),(3695,234,274),.2,6)
# Shallow radiating crown gives a celebratory silhouette with forty simple triangles.
component('C12_FinishColonnades','Finale')
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
component('C12_Goal','Finale')
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

def rail_vehicle(name, center, length, width, top, color, cab=False, active=False, rear=False):
    x, z = center
    component(name, "Moving" if active else "Parked", [x, 89 if active else top, z])
    low = top-7.5
    wheel_y = (80.65 if active else 75.125)+1.05
    gauge = 4 if active else 4.65
    box("Iron", (x, low+1.35, z), (length-.9, 1.4, width-1.2))
    for dx in (-length*.29, length*.29):
        box("Iron", (x+dx, wheel_y+.2, z), (5.5, 1.3, gauge*2-1.2))
        for axle in (-1.4, 1.4):
            beam("Rail", (x+dx+axle, wheel_y, z-gauge),
                 (x+dx+axle, wheel_y, z+gauge), .16, 8)
            for side in (-1, 1):
                beam("Iron", (x+dx+axle, wheel_y, z+side*(gauge-.32)),
                     (x+dx+axle, wheel_y, z+side*(gauge+.32)), 1.05, 12)
                beam("Rail", (x+dx+axle, wheel_y, z+side*(gauge+.32)),
                     (x+dx+axle, wheel_y, z+side*(gauge+.38)), .46, 8)
    body_end = length/2-2.8 if cab else length/2-.25
    box(color, (x+(body_end-length/2)/2, low+4.35, z),
        (body_end+length/2, 4.8, width-.8))
    roof_end = body_end-.1 if cab else length/2-.8
    roof_start = -length/2+.8
    box("Roof", (x+(roof_start+roof_end)/2, top-.42, z), (roof_end-roof_start, .8, width-.4))
    for side in (-1, 1):
        zz = z+side*(width/2-.34)
        box("Yellow" if active else "Cream", (x-.4, low+3.25, zz), (length-1.8, .45, .12))
        for dx in range(-int(length/2)+4, int(length/2)-5, 4):
            box("Iron", (x+dx, low+5.35, zz), (3.15, 2.25, .16))
            box("Glass", (x+dx, low+5.4, zz+side*.09), (2.65, 1.8, .1))
        for dx in (-length/2+1.8, body_end-1.4):
            box("Rail", (x+dx, low+4.7, zz), (1.4, 4.7, .1))
            box("Glass", (x+dx, low+5.6, zz+side*.09), (.9, 1.9, .11))
        for dx in range(-int(length/2)+2, int(length/2)-1, 3):
            box("Rail", (x+dx, low+2.4, zz), (.13, .13, .1))
    for dx in (-7, 2):
        box("Rail", (x+dx, top-.1, z), (4.8, .2, width*.55))
        for dz in (-1.3, 0, 1.3):
            box("Iron", (x+dx, top+.01, z+dz), (4.3, .06, .4))
    for sign in (-1, 1):
        box("Iron", (x+sign*(length/2+.35), low+1.85, z), (1.1, .65, 1.3))
    if cab:
        prism(color, [(x+body_end-1, low+2), (x+length/2, low+2.4),
                      (x+length/2-.5, low+4.5), (x+body_end-.3, top-.55),
                      (x+body_end-1, top-.55)], z-width/2+.4, z+width/2-.4)
        prism("Iron", [(x+length/2-.1, low+1.55), (x+length/2+.15, low+1.6),
                       (x+length/2-.6, low+2.75), (x+length/2-1, low+2.75)],
              z-width/2+.15, z+width/2-.15)
        for side in (-1, 1):
            prism("Glass", [(x+body_end+.12, top-.8), (x+body_end+.4, top-.8),
                            (x+length/2-.6, low+4.55), (x+length/2-.8, low+4.55)],
                  z+side*1.9-1.35, z+side*1.9+1.35)
            box("Light", (x+length/2-.03, low+3.55, z+side*2.7), (.16, .65, 1.1))
            box("Yellow", (x+length/2-.05, low+2.75, z+side*2.7), (.12, .35, 1.4))
    if rear:
        box("Rail", (x-length/2-.06, low+4.2, z), (.12, 4.2, 2.9))
        box("Iron", (x-length/2-.14, low+4.2, z), (.1, 3.7, 2.4))
        box("Glass", (x-length/2-.2, low+5, z), (.12, 1.5, 1.65))
        for side in (-1, 1):
            box("Rail", (x-length/2-.2, low+3.65, z+side*1.65), (.16, 2.6, .15))
        for side in (-1, 1):
            box("Red", (x-length/2-.02, low+3.6, z+side*2.7), (.1, .5, .7))



for i in range(3):
    rail_vehicle('ActiveTrain'+str(i),(3590+(i-1)*38,-12),36.7,11.2,89.25,'Ink',cab=i==2,active=True,rear=i==0)
    for (name,mat),chunks in api['groups'].items():
        if name!='ActiveTrain'+str(i):continue
        for vertices,_ in chunks:
            for j,(bx,by,bz) in enumerate(vertices):
                if bz>83: vertices[j]=(bx,by,83+(bz-83)*1.52)

for key, pos in (("Origin", (3500, 0, 0)), ("Right", (3510, 0, 0)),
                 ("Up", (3500, 10, 0)), ("Forward", (3500, 0, -10))):
    component("Marker"+key, "Calibration")
    box("Iron", pos, (.1, .1, .1))

meshes, objects = {}, []
for (name, material), chunks in api["groups"].items():
    for index, (vertices, faces) in enumerate(chunks):
        mesh_name = f"{name}__{material}__{index:02}"
        mesh = bpy.data.meshes.new(mesh_name)
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.append(api["MATS"][material])
        mesh.update()
        mesh.calc_loop_triangles()
        obj = bpy.data.objects.new(mesh_name, mesh)
        scene.collection.objects.link(obj)
        objects.append(obj)
        meshes[mesh_name] = dict(component=name, material=material, triangles=len(mesh.loop_triangles))
for obj in scene.objects:
    obj.select_set(False)
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT / "CityRun_C12_terminal.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = dict(revision="C12_02", components=definitions, meshes=meshes, colors=api["COLORS"])
(OUT / "manifest_C12_terminal.json").write_text(json.dumps(data, indent=2))


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


(ROOT / "src/ServerStorage/CourseBuilders/CityRun/C12Manifest.luau").write_text("--!strict\nreturn " + luau(data) + "\n")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CityRun_C12_terminal.blend"))
print(json.dumps(dict(meshes=len(meshes), components=len(definitions),
                      triangles=sum(m["triangles"] for m in meshes.values()))))
