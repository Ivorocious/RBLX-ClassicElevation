"""Grand Arcade A01. Blender 5.2; isolated scene, one Blender unit per Roblox stud."""
import bpy
import bmesh
import json
import math
import time
from pathlib import Path
from mathutils import Vector

START = time.monotonic()
OUT = Path(__file__).resolve().parent / "A01"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = "NONE"
scene.unit_settings.scale_length = 1
COLORS = {
    "Ivory": (0.94, 0.88, 0.75), "Pale": (0.99, 0.96, 0.88),
    "Stone": (0.76, 0.70, 0.59), "Floor": (0.91, 0.87, 0.78),
    "Navy": (0.025, 0.055, 0.12), "Gold": (0.88, 0.59, 0.14),
    "Silver": (0.60, 0.69, 0.73), "Bronze": (0.65, 0.36, 0.17),
    "Leaf": (0.16, 0.39, 0.15), "LeafLight": (0.37, 0.58, 0.17),
    "Wood": (0.25, 0.14, 0.055), "Lamp": (1.0, 0.79, 0.24),
}
MATS = {}
for name, color in COLORS.items():
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1)
    MATS[name] = material
objects = []
colliders = []
sections = {}
bays = []
section = "Platform"
transform = None

def mapped(v):
    if transform is None:
        return tuple(v)
    x, y, angle = transform
    c, s = math.cos(angle), math.sin(angle)
    return (x + v[0]*c - v[1]*s, y + v[0]*s + v[1]*c, v[2])

def mesh(name, material, vertices, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata([mapped(v) for v in vertices], [], faces)
    data.materials.append(MATS[material])
    data.update()
    data.validate()
    normals = bmesh.new()
    normals.from_mesh(data)
    bmesh.ops.recalc_face_normals(normals, faces=list(normals.faces))
    normals.to_mesh(data)
    normals.free()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj["Section"], obj["Material"] = section, material
    objects.append(obj)
    return obj

def box(name, mat, p, size, collide=False):
    x, y, z = p
    a, b, c = (v/2 for v in size)
    vs = [(x+dx*a,y+dy*b,z+dz*c) for dx,dy,dz in [
        (-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
        (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    obj = mesh(name, mat, vs, [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    if collide:
        colliders.append({"name": name, "section": section, "p": mapped(p),
            "s": size, "angle": transform[2] if transform else 0})
    return obj

def extrude(name, mat, polygon, depth, front):
    n = len(polygon)
    vs = [(x, front, z) for x,z in polygon] + [(x,front+depth,z) for x,z in polygon]
    faces = [tuple(range(n)), tuple(range(n*2-1,n-1,-1))]
    faces += [(i,i+n,(i+1)%n+n,(i+1)%n) for i in range(n)]
    return mesh(name, mat, vs, faces)

def arch(name, mat, inner, outer, spring, depth, front, segments=36):
    polygon = [(outer*math.cos(i*math.pi/segments),spring+outer*math.sin(i*math.pi/segments)) for i in range(segments+1)]
    polygon += [(inner*math.cos(i*math.pi/segments),spring+inner*math.sin(i*math.pi/segments)) for i in range(segments,-1,-1)]
    return extrude(name,mat,polygon,depth,front)

def lathe(name, mat, p, profile, segments=24):
    x,y,z = p
    vs = [(x+r*math.cos(i*math.tau/segments),y+r*math.sin(i*math.tau/segments),z+h)
          for r,h in profile for i in range(segments)]
    faces = [tuple(range(segments-1,-1,-1))]
    faces += [(j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i)
              for j in range(len(profile)-1) for i in range(segments)]
    faces.append(tuple(range((len(profile)-1)*segments,len(profile)*segments)))
    return mesh(name,mat,vs,faces)

def slab(name, mat, z, thickness, rx, ry, segments=96):
    vs = [(rx*math.cos(i*math.tau/segments),ry*math.sin(i*math.tau/segments),h)
          for h in [z-thickness,z] for i in range(segments)]
    fs = [tuple(range(segments-1,-1,-1)),tuple(range(segments,segments*2))]
    fs += [(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,mat,vs,fs)

def extend_entrance_terminal(vertices, faces, old_angle, at_start, z, width, height, rx, ry, segments):
    side = -1 if math.cos(old_angle) < 0 else 1
    angle_delta = math.acos(9.45/rx)
    terminal_angle = math.pi+angle_delta if side < 0 else math.tau-angle_delta
    terminal_ry = 22.3/abs(math.sin(terminal_angle))
    last = list(range(4)) if at_start else list(range(segments*4, segments*4+4))
    faces = [face for face in faces if set(face) != set(last)]
    for step in range(1, 7):
        progress = step/6
        smooth = progress*progress*(3-2*progress)
        angle = old_angle+(terminal_angle-old_angle)*progress
        radius_y = ry+(terminal_ry-ry)*smooth
        end_width = width+(min(width,1.3)-width)*smooth
        following = []
        for offset, vertical in [(-end_width/2,-height/2),(end_width/2,-height/2),
                                  (-end_width/2,height/2),(end_width/2,height/2)]:
            following.append(len(vertices))
            vertices.append(((rx+offset)*math.cos(angle),(radius_y+offset)*math.sin(angle),z+vertical))
        faces.extend((last[u],last[v],following[v],following[u]) for u,v in [(0,1),(1,3),(3,2),(2,0)])
        last = following
    faces.append(tuple(last[i] for i in (0,1,3,2)))
    return faces


def curved_beam(name, mat, a, b, z, width, height, rx=50, ry=22, segments=40):
    vs=[]
    for i in range(segments+1):
        t=a+(b-a)*i/segments
        for offset,h in [(-width/2,-height/2),(width/2,-height/2),(-width/2,height/2),(width/2,height/2)]:
            vs.append(((rx+offset)*math.cos(t),(ry+offset)*math.sin(t),z+h))
    fs=[(0,2,3,1),(segments*4,segments*4+1,segments*4+3,segments*4+2)]
    for j in range(segments):
        for u,v in [(0,1),(1,3),(3,2),(2,0)]:
            fs.append((j*4+u,j*4+v,(j+1)*4+v,(j+1)*4+u))
    # Extend only the entrance ends into the existing C01 terminal posts.
    if section == "FrontWing-1":
        fs = extend_entrance_terminal(vs,fs,b,False,z,width,height,rx,ry,segments)
    elif section == "FrontWing1":
        fs = extend_entrance_terminal(vs,fs,a,True,z,width,height,rx,ry,segments)
    return mesh(name,mat,vs,[tuple(reversed(face)) for face in fs])

slab("Foundation", "Stone", -0.7, 1.8, 52, 24)
slab("EdgeIvory", "Ivory", -0.35, .35, 52.3, 24.3)
slab("EdgeGold", "Gold", -0.19, .12, 52.4, 24.4)
slab("WalkingSurface", "Floor", 0, .19, 52.3, 24.3)
for x in range(-48,49,6):
    for y in range(-18,19,6):
        if ((abs(x)+3)/51)**2+((abs(y)+3)/23)**2 < 1:
            box("FloorTile", "Pale", (x,y,.016),(5.94,5.94,.025))
for x in range(-51,52,2):
    d=24.3*math.sqrt(max(0,1-((abs(x)+1)/52.3)**2))
    colliders.append({"name":"FloorCollision","section":"Platform","p":[x,0,-.484],"s":[2,d*2,1],"angle":0})
section="Approach"
box("Causeway","Ivory",(0,-24.5,-.6),(16,17,1.2),True)
for i in range(3):
    y=-43+i*4
    top=-2.8+i*1.4
    box("EntryStep"+str(i+1),"Pale",(0,y,top-.7),(16,4,1.4),True)
    box("StepGold"+str(i+1),"Gold",(0,y-1.97,top-.06),(16,.08,.12))
for side in [-1,1]:
    box("SolidApproachWall","Ivory",(side*9,-29,1.3),(1.4,26,2.6),True)
    box("ApproachCap","Pale",(side*9,-29,2.7),(1.9,26,.25))
    box("ApproachGold","Gold",(side*9,-29,2.86),(1.65,26,.09))
section="PresenterDais"
lathe("Dais","Pale",(0,-5,0),[(7.0,0),(7.0,.30),(6.8,.45)],64)
lathe("DaisNavy","Navy",(0,-5,.455),[(6.0,0),(6.0,.04)],64)
lathe("DaisInner","Pale",(0,-5,.50),[(5.4,0),(5.4,.035)],64)
lathe("DaisGold","Gold",(0,-5,.54),[(2.3,0),(2.3,.025)],48)
colliders.append({"name":"DaisCollision","section":section,"p":[0,-5,.18],"s":[12,12,.36],"angle":0})

PANEL_WIDTH = 12.4
PANEL_HEIGHT = PANEL_WIDTH * 13.2 / 13.5
PANEL_Z, PLAQUE_Z = 14.0, 6.6
KEY_HALF_ANGLE = math.radians(6)

def bay_arch_section(name, mat, inner, outer, start, end, front, depth):
    segments = max(4, math.ceil((end-start)/math.radians(4)))
    angles = [start+(end-start)*i/segments for i in range(segments+1)]
    vertices = [(radius*math.cos(angle),y,17.5+radius*math.sin(angle))
                for y in [front,front+depth] for radius in [inner,outer] for angle in angles]
    ring = segments+1
    faces = []
    for i in range(segments):
        faces += [(i,i+1,ring+i+1,ring+i),
                  (2*ring+i,3*ring+i,3*ring+i+1,2*ring+i+1),
                  (i,2*ring+i,2*ring+i+1,i+1),
                  (ring+i,ring+i+1,3*ring+i+1,3*ring+i)]
    faces += [(0,ring,3*ring,2*ring),
              (segments,2*ring+segments,3*ring+segments,ring+segments)]
    return mesh(name,mat,vertices,[tuple(reversed(face)) for face in faces])

for i in range(5):
    t=math.radians((i-2)*12)
    x,y=90*math.sin(t),14-90+90*math.cos(t)
    transform=(x,y,-t)
    section="Bay"+str(i+1)
    sections[section]={"p":[x,y,0],"angle":-t}
    polygon=[(-7.6,0),(7.6,0),(7.6,17.5)] + [(7.6*math.cos(j*math.pi/48),17.5+7.6*math.sin(j*math.pi/48)) for j in range(1,49)]
    extrude("OpaqueBacking","Navy",polygon,.40,.90)
    for side,(start,end) in enumerate([(0,math.pi/2-KEY_HALF_ANGLE),(math.pi/2+KEY_HALF_ANGLE,math.pi)]):
        bay_arch_section("IvoryArch"+str(side),"Ivory",7.6,9.0,start,end,-.50,1.70)
        bay_arch_section("GoldReveal"+str(side),"Gold",7.6,7.78,start,end,-.70,.20)
    for side in [-1,1]:
        box("Column","Ivory",(side*8.28,.1,9),(1.42,2.0,18),True)
        box("ColumnBase","Pale",(side*8.28,0,.7),(2.35,2.6,1.4))
        box("ColumnFoot","Stone",(side*8.28,0,.12),(2.7,2.9,.24))
        box("ColumnCapital","Pale",(side*8.28,0,17.45),(2.4,2.5,.7))
    bay_arch_section("SeatedKeystone","Pale",7.6,9.12,math.pi/2-KEY_HALF_ANGLE,math.pi/2+KEY_HALF_ANGLE,-.72,1.92)
    box("PanelBacking","Navy",(0,-.64,PANEL_Z),(PANEL_WIDTH+.10,.24,PANEL_HEIGHT+.10))
    box("RacePlaque","Navy",(0,-.70,PLAQUE_Z),(PANEL_WIDTH+.12,.32,1.65))
    slots=[]
    for rank,xx,h,mat in [(2,-3.6,2.3,"Silver"),(1,0,3.4,"Gold"),(3,3.6,1.95,"Bronze")]:
        box("Podium"+str(rank),mat,(xx,-3,h/2),(3.25,3.15,h),True)
        box("PodiumFace"+str(rank),"Navy",(xx,-4.59,h/2),(2.85,.1,h-.3))
        lathe("PodiumCap"+str(rank),"Pale",(xx,-3,h),[(1.40,0),(1.40,.15)],32)
        slots.append({"rank":rank,"p":mapped((xx,-3,h+.15)),
            "panel":mapped((xx,-4.66,h/2)),"height":h-.3})
    bays.append({"index":i+1,"p":[x,y,0],"angle":-t,
        "screen":mapped((0,-.82,PANEL_Z)),"plaque":mapped((0,-.88,PLAQUE_Z)),"slots":slots})
    if i==0:
        pass
transform=None

for side in [-1,1]:
    section="FrontWing"+str(side)
    a,b=(math.radians(191),math.radians(256)) if side<0 else (math.radians(284),math.radians(349))
    curved_beam("CurvedFoot","Ivory",a,b,.25,1.7,.5)
    curved_beam("CurvedHandrail","Pale",a,b,2.7,1.3,.34)
    curved_beam("CurvedGold","Gold",a,b,2.90,1.12,.10)
    for j in range(19):
        t=a+(b-a)*j/18
        xx,yy=50*math.cos(t),22*math.sin(t)
        lathe("Baluster","Navy",(xx,yy,.5),[(.18,0),(.18,.15),(.12,.3),(.12,1.72),(.19,1.85),(.19,2.03)],12)
        colliders.append({"name":"WingCollision","section":section,"p":[xx,yy,1.7],"s":[2.6,1.1,3.0],"angle":t-math.pi/2})
    section="OuterPlanter"+str(side)
    x,y=side*40,-7
    box("PlanterBase","Stone",(x,y,.7),(5,5,1.4),True)
    box("PlanterRim","Pale",(x,y,1.4),(5.3,5.3,.3))
    box("Soil","Navy",(x,y,1.57),(4.6,4.6,.12))
    lathe("TreeTrunk","Wood",(x,y,1.65),[(.35,0),(.27,3.4)],12)
    for dx,dy,z,r,mat in [(0,0,6.2,2.8,"Leaf"),(-1.7,-.6,5.5,2.0,"LeafLight"),(1.3,.7,6,2.1,"Leaf"),(0,-.8,7.5,1.7,"LeafLight")]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=r,location=(x+dx,y+dy,z))
        o=bpy.context.object;o.name="TreeCrown";o.data.materials.append(MATS[mat]);o["Section"]=section;o["Material"]=mat;objects.append(o)
for i in range(6):
    section="Lamp"+str(i+1)
    x,y,z=([-45,0,0],[-9,-17,0],[9,-17,0],[45,0,0],[-9,-42,-2.8],[9,-42,-2.8])[i]
    box("LampPost","Ivory",(x,y,z+1.8),(2,2,3.6),True)
    box("LampBase","Gold",(x,y,z+3.8),(1.6,1.6,.3))
    box("LampGlow","Lamp",(x,y,z+4.6),(1.0,1.0,1.3))
    for dx,dy in [(-.6,-.6),(-.6,.6),(.6,-.6),(.6,.6)]:
        box("LampFrame","Navy",(x+dx,y+dy,z+4.6),(.12,.12,1.4))
    extrude("LampRoof","Gold",[(x-1,z+5.3),(x+1,z+5.3),(x,z+6.1)],1.9,y-.95)
    lathe("LampFinial","Gold",(x,y,z+6.08),[(.18,0),(.05,.24)],12)
section="Calibration"
for key,p in [("Origin",(0,0,0)),("Right",(10,0,0)),("Up",(0,0,10)),("Forward",(0,-10,0))]:
    o=box("Marker"+key,"Navy",p,(.12,.12,.12))
    o.hide_render=True

# One mesh per editable section/material; UI and avatars remain native Roblox content.
grouped={}
for o in objects:
    grouped.setdefault((o["Section"],o["Material"]),[]).append(o)
exported=[]
meshinfo={}
for (group,mat), members in grouped.items():
    bpy.ops.object.select_all(action="DESELECT")
    for o in members:o.select_set(True)
    bpy.context.view_layer.objects.active=members[0]
    bpy.ops.object.join()
    o=bpy.context.object;o.name=group+"__"+mat
    o.data.calc_loop_triangles()
    meshinfo[o.name]={"section":group,"material":mat,"triangles":len(o.data.loop_triangles)}
    assert len(o.data.loop_triangles)<20000,o.name
    exported.append(o)
# Calibration points must remain separate for importer axis/scale inspection.
calibration=[o for o in exported if o.name.startswith("Calibration__")]
if calibration:
    o=calibration[0]
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.select_all(action="DESELECT");o.select_set(True)
    bpy.ops.mesh.separate(type="LOOSE")
    exported.remove(o)
    for marker in [v for v in scene.objects if v.type=="MESH" and v.name.startswith("Calibration__")]:
        center=sum((v.co for v in marker.data.vertices),Vector())/len(marker.data.vertices)
        key="Right" if center.x>5 else "Up" if center.z>5 else "Forward" if center.y<-5 else "Origin"
        marker.name="Marker"+key+"__Navy";marker.hide_render=True;exported.append(marker)
        meshinfo[marker.name]={"section":"Calibration","material":"Navy","triangles":12}
    meshinfo.pop("Calibration__Navy", None)

manifest={"revision":"A01","colors":COLORS,"meshes":meshinfo,"bays":bays,"sections":sections,
    "colliders":colliders,"origin":[1552,374.2,-929],"presenter":[0,-5,.565],
    "units":"One Blender unit = one Roblox stud. X right; Y rear; Z up. Native transform (x,z,-y)."}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2))
def luau(v):
    if isinstance(v,dict):return "{"+",".join("["+json.dumps(k)+"]="+luau(w) for k,w in v.items())+"}"
    if isinstance(v,(list,tuple)):return "{"+",".join(luau(w) for w in v)+"}"
    if isinstance(v,str):return json.dumps(v)
    return str(v).lower()
source=OUT.parents[2]/"src/ServerStorage/CourseBuilders/GrandArcade"
source.mkdir(parents=True,exist_ok=True)
(source/"Manifest.luau").write_text("--!strict\nreturn "+luau(manifest)+"\n")
bpy.ops.object.select_all(action="DESELECT")
for o in exported:o.select_set(True)
bpy.context.view_layer.objects.active=exported[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/"GrandArcade_A01.fbx"),use_selection=True,object_types={"MESH"},axis_forward="-Z",axis_up="Y",apply_unit_scale=True,add_leaf_bones=False)
scene.world=bpy.data.worlds.new("PreviewWorld");scene.world.color=(.66,.69,.74)
camera_data=bpy.data.cameras.new("ReviewCamera");camera=bpy.data.objects.new("ReviewCamera",camera_data);scene.collection.objects.link(camera);scene.camera=camera
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.light="STUDIO";scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True;scene.display.shading.cavity_type="BOTH";scene.display.shading.background_type="WORLD"
scene.view_settings.view_transform="Standard"
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
camera_data.type="ORTHO";camera_data.ortho_scale=117
views={"front":((0,-120,48),(0,0,10)),"left":((-90,-100,54),(0,-5,9)),
       "right":((90,-100,54),(0,-5,9)),"overhead":((0,-8,150),(0,-8,0)),"rear":((-85,100,52),(0,-3,8)),
       "player":((10,-53,5.2),(0,10,10))}
for name,(position,target) in views.items():
    camera.location=position;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.type="PERSP" if name=="player" else "ORTHO";camera_data.lens=24
    scene.render.filepath=str(OUT/(name+".png"));bpy.ops.render.render(write_still=True)
camera_data.type="ORTHO";camera.location=views["front"][0];camera.rotation_euler=(Vector(views["front"][1])-camera.location).to_track_quat("-Z","Y").to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"GrandArcade_A01.blend"))
report={"meshes":len(exported),"triangles":sum(v["triangles"] for v in meshinfo.values()),"colliders":len(colliders),"bayCount":len(bays),"podiumSpots":sum(len(b["slots"]) for b in bays),"elapsedSeconds":round(time.monotonic()-START,2)}
(OUT/"build-report.json").write_text(json.dumps(report,indent=2));print("GRAND_ARCADE "+json.dumps(report))
