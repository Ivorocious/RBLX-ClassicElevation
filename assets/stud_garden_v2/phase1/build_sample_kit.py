"""Original Stud Garden V2 sample meshes; isolated Blender process, units in studs."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
ROOT.mkdir(parents=True, exist_ok=True)
REVISION = "SGV2_M01"
PALETTE = {
    "terra": (0.73, 0.29, 0.15, 1), "rim": (0.90, 0.48, 0.27, 1),
    "leaf": (0.14, 0.37, 0.18, 1), "lime": (0.42, 0.65, 0.20, 1),
    "red": (0.80, 0.10, 0.16, 1), "seed": (1, 0.84, 0.48, 1),
    "orange": (0.94, 0.39, 0.065, 1), "gold": (1, 0.68, 0.07, 1),
    "brown": (0.22, 0.105, 0.04, 1), "bamboo": (0.32, 0.57, 0.12, 1),
}
MATS = {}
for name, rgba in PALETTE.items():
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = 0.48
    MATS[name] = mat

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
assets = []
current = []


def finish(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(MATS[material])
    current.append(obj)
    return obj


def block(location, size, material, bevel=0, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation:
        obj.rotation_euler = rotation
    if bevel:
        mod = obj.modifiers.new("Soft toy edges", "BEVEL")
        mod.width, mod.segments = bevel, 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
        normal = obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
        bpy.ops.object.modifier_apply(modifier=normal.name)
    return finish(obj, material)


def cylinder(location, radius, depth, material, vertices=12, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    if rotation:
        obj.rotation_euler = rotation
    return finish(obj, material)


def mesh(name, vertices, faces, material):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return finish(obj, material)


def blade(base, direction, length, width, material="leaf", rise=0.4):
    """Closed folded leaf with a raised center rib and a tapered tip."""
    axis = Vector(direction).normalized()
    side = Vector((-axis.y, axis.x, 0)).normalized()
    base = Vector(base)
    vertices = []
    for t, w, h in [(0, 0.08, 0), (0.28, 0.78, 0.34), (0.62, 1, 0.45), (1, 0.02, 0.08)]:
        center = base + axis * length * t + Vector((0, 0, h * rise))
        vertices.extend([center-side*width*w/2, center+Vector((0,0,width*0.13*w)), center+side*width*w/2])
    faces = []
    for i in range(3):
        k = i*3
        faces.extend([(k,k+3,k+4,k+1),(k+1,k+4,k+5,k+2),(k+2,k+5,k+3,k)])
    faces.extend([(0,1,2),(9,11,10)])
    return mesh("FoldedLeaf", vertices, faces, material)


def finish_asset(name, index, mount, safe_scale):
    global current
    parts=[]
    grouped={}
    for obj in current:
        grouped.setdefault(obj.data.materials[0].name,[]).append(obj)
    for material, subset in sorted(grouped.items()):
        bpy.ops.object.select_all(action="DESELECT")
        for obj in subset:
            obj.select_set(True)
        bpy.context.view_layer.objects.active=subset[0]
        bpy.ops.object.join()
        obj=bpy.context.object
        obj.name=name+"__"+material
        obj.location.x+=index*34
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        parts.append(obj)
    points=[obj.matrix_world @ Vector(p) for obj in parts for p in obj.bound_box]
    low=[min(p[i] for p in points) for i in range(3)]
    high=[max(p[i] for p in points) for i in range(3)]
    triangles=0
    for obj in parts:
        obj.data.calc_loop_triangles()
        triangles+=len(obj.data.loop_triangles)
        assert all(math.isfinite(value) for v in obj.data.vertices for value in v.co)
        assert all(poly.area > 1e-9 for poly in obj.data.polygons), obj.name
    assets.append({"name":name,"mount":mount,"origin":[index*34,0,0],"min":low,"max":high,
                   "size":[high[i]-low[i] for i in range(3)],"parts":[p.name for p in parts],
                   "triangles":triangles,"safeUniformScale":safe_scale})
    current=[]


# Pot is a hollow revolved profile, with separate rim material and no square soil corners.
profile=[(7.5,0),(7.8,0.4),(10.3,5.5),(12,5.5),(12,6.4),(6,6.4),(6,5.5),(5.7,2.7),(5.7,0.7)]
verts=[(r*math.cos(i*math.tau/12),r*math.sin(i*math.tau/12),z) for r,z in profile for i in range(12)]
faces=[]
for j in range(len(profile)-1):
    for i in range(12):
        faces.append((j*12+i,j*12+(i+1)%12,(j+1)*12+(i+1)%12,(j+1)*12+i))
faces.extend([(i,(i+1)%12,(len(profile)-1)*12+(i+1)%12,(len(profile)-1)*12+i) for i in range(12)])
pot=mesh("HollowPot",verts,faces,"terra")
pot.data.materials.append(MATS["rim"])
for polygon in pot.data.polygons:
    if 24 <= polygon.index < 60:
        polygon.material_index=1
for i in range(24):
    angle=(i+0.5)*math.tau/24
    cylinder((9*math.cos(angle),9*math.sin(angle),6.52),0.48,0.24,"rim")
finish_asset("Pot24",0,"Ground center; top rim 6.4; outer diameter 24; opening 12",[1,1])

for i,(x,y,z,s) in enumerate([(-1.15,0,1.45,1),(1.05,0.55,1.1,0.85),(0,-1.05,0.8,0.65)]):
    block((x,y,z),(2.35*s,2.05*s,2.75*s),"red",0.48*s, (0,0,i*0.43))
    for j in range(5):
        a=j*math.tau/5+i*0.3
        blade((x,y,z+1.18*s),(math.cos(a),math.sin(a),0.08),1.7*s,0.82*s,"leaf",0.2)
    for sx,sz in [(-0.5,0.4),(0.5,0.4),(0,-0.35)]:
        block((x+sx*s,y-1.02*s,z+sz*s),(0.19*s,0.1*s,0.31*s),"seed",0.04*s)
finish_asset("BerryTuft",1,"Soil center; fruit bases at soil; no player support",[0.85,1.4])

for i,(x,y,h) in enumerate([(-0.9,0,3.4),(1,0.8,2.7)]):
    rings=[(0.28,0),(0.78,h*0.2),(1.1,h*0.7),(0.95,h)]
    vs=[(x+r*math.cos(a*math.tau/8),y+r*math.sin(a*math.tau/8),z) for r,z in rings for a in range(8)]
    fs=[]
    for j in range(3):
        for a in range(8): fs.append((j*8+a,j*8+(a+1)%8,(j+1)*8+(a+1)%8,(j+1)*8+a))
    fs.extend([tuple(reversed(range(8))),tuple(range(24,32))])
    mesh("CarrotRoot",vs,fs,"orange")
    for j in range(5):
        a=j*math.tau/5+i
        blade((x,y,h-0.1),(math.cos(a)*0.5,math.sin(a)*0.5,1),3.1,0.8,"leaf" if j%2 else "lime",1)
finish_asset("CarrotPair",2,"Soil center; roots fully visible or bury bottom 0.4",[0.8,1.4])

for i,(x,y,h) in enumerate([(-1,0.6,7),(1.8,1.2,5.2),(0,-1.1,4.4)]):
    cylinder((x,y,h/2),0.22,h,"leaf",8)
    for z,a in [(h*0.35,0.4),(h*0.55,3.5)]:
        blade((x,y,z),(math.cos(a),math.sin(a),0.5),2.6,1.3,"leaf",0.5)
    cylinder((x,y,h),0.95,0.55,"brown",16,(math.pi/2,0,0))
    for j in range(10):
        a=j*math.tau/10
        block((x+math.cos(a)*1.35,y,h+math.sin(a)*1.35),(1.3,0.45,0.78),"gold",0.18,(0,-a,0))
    for a,b in [(-0.3,-0.3),(0.3,-0.3),(-0.3,0.3),(0.3,0.3)]:
        cylinder((x+a,y-0.34,h+b),0.17,0.13,"brown",8,(math.pi/2,0,0))
finish_asset("SunflowerClump",3,"Ground/soil center; flowers face -Y in Blender, -Z in Roblox",[0.9,1.3])

for i,(x,y,h) in enumerate([(-1.3,0,13),(1,0.6,16),(0,-1.2,10)]):
    cylinder((x,y,h/2),0.58,h,"bamboo",10)
    for z in range(2,int(h),3): cylinder((x,y,z),0.71,0.32,"lime",10)
    for j in range(3):
        a=i*1.5+j*2.2
        blade((x,y,h-1-j*1.8),(math.cos(a),math.sin(a),0.18),4.3,1.3,"leaf",0.6)
finish_asset("BambooClump",4,"Ground center; culms are scenery blockers; foliage is overhead",[0.85,1.2])

blade((0,-6.5,0),(0,1,0),13,8,"leaf",0.4)
blade((0,-6.5,0.12),(0,1,0),12.7,7.7,"lime",0.4)
cylinder((0,-2.5,-0.45),0.38,8,"leaf",8,(math.pi/2,0,0))
for y in [-3,0,3]:
    for x in [-1.8,1.8]: cylinder((x,y,0.92),0.38,0.2,"lime",10)
finish_asset("BroadLeaf",5,"Source leaf surface varies in height; contact requires inspection",[1,1.4])

block((204,0,5),(10,10,10),"seed")
finish_asset("Calibration10",0,"10x10x10 import scale witness",[1,1])

all_meshes=[obj for obj in bpy.context.scene.objects if obj.type=="MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in all_meshes: obj.select_set(True)
bpy.context.view_layer.objects.active=all_meshes[0]
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f"{REVISION}.blend"))
bpy.ops.export_scene.fbx(filepath=str(ROOT/f"{REVISION}.fbx"),use_selection=True,object_types={"MESH"},
                        apply_unit_scale=True,axis_forward="-Z",axis_up="Y",path_mode="COPY",embed_textures=False,bake_anim=False)
manifest={"revision":REVISION,"units":"authored studs; verify Calibration10 on import", "axes":"Blender Z up; exported Y up",
          "assets":assets,"materials":PALETTE,"meshObjects":len(all_meshes),"triangles":sum(a["triangles"] for a in assets),
          "provenance":"Original procedural geometry; no third-party asset or texture", "textures":0}
(ROOT/f"{REVISION}.json").write_text(json.dumps(manifest,indent=2)+"\n")
print(json.dumps({"revision":REVISION,"assets":len(assets),"meshes":len(all_meshes),"triangles":manifest["triangles"]}))
