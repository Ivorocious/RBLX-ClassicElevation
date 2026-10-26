"""Sculpt compact, irregular geology for the final V8 recovery candidate."""
import bpy
import json
import math
import random
from pathlib import Path
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent
exec((BASE / "create_ascent_props.py").read_text().split("RESULT=build()")[0])
OUT = BASE / "recovery"
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new("RecoveryGeology")
bpy.context.window.scene = scene
COLORS.update({"WarmRock": (.34,.36,.32), "ColdRock": (.25,.32,.35), "Fracture": (.17,.23,.25)})


def mesh_object(col, name, vertices, faces, material):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    mesh.materials.append(mat(material))
    return obj


def spur(name, seed):
    col = collection(name)
    rng = random.Random(seed)
    n = 10
    angles = [math.tau*i/n+rng.uniform(-.09,.09) for i in range(n)]
    outline = [rng.uniform(.85,1.08) for _ in range(n)]
    vertices = []
    rings = [(0,.29,1.2,-.7),(9,.54,-.4,.6),(22,.71,.8,-.4),(32,.90,-.3,.2),(36,1,0,0)]
    for ring,(height,width,dx,dy) in enumerate(rings):
        for i,angle in enumerate(angles):
            z = height if ring==4 else height+rng.uniform(-1.5,1.5)
            vertices.append((math.cos(angle)*7*width*outline[i]+dx,
                             math.sin(angle)*6*width*outline[i]+dy,z))
    faces = [tuple(range(n-1,-1,-1)),tuple(range(4*n,5*n))]
    for ring in range(4):
        for i in range(n):
            a,b=ring*n+i,ring*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    mesh_object(col,name,vertices,faces,"ColdRock")
    return finish(col,name,36)


def fault_wall(name,seed):
    col=collection(name)
    rng=random.Random(seed)
    n=15
    angles=[math.tau*i/n+rng.uniform(-.08,.08) for i in range(n)]
    outline=[rng.uniform(.82,1.12) for _ in range(n)]
    vertices=[]
    for ring in range(7):
        t=ring/6
        scale=(1.05,1.15,1.04,1.01,.9,.67,.28)[ring]
        for i,angle in enumerate(angles):
            x=math.cos(angle)*40*scale*outline[i]+t*7
            y=math.sin(angle)*23*scale*outline[i]+t*9
            z=t*68 + (0 if ring==0 else 6*math.sin(angle*2+seed)+rng.uniform(-3,3))
            vertices.append((x,y,z))
    faces=[tuple(range(n-1,-1,-1)),tuple(range(6*n,7*n))]
    for ring in range(6):
        for i in range(n):
            a,b=ring*n+i,ring*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    mesh_object(col,name,vertices,faces,'WarmRock')
    return finish(col,name,72)


def talus_fan():
    col=collection("TalusFan")
    rng=random.Random(927)
    for i in range(13):
        angle=rng.uniform(0,math.tau)
        radius=rng.uniform(1,14)
        size=rng.uniform(2.4,6)
        ico(col,"scree",(math.cos(angle)*radius,math.sin(angle)*radius*.6,size*.37),
            (size,size*rng.uniform(.6,1.2),size*rng.uniform(.4,.85)),"ColdRock",927+i,2)
    return finish(col,"TalusFan",9)


def basalt_fan():
    col=collection("BasaltFan")
    rng=random.Random(933)
    for i in range(12):
        x,y=rng.uniform(-14,14),rng.uniform(-9,9)
        h=rng.uniform(7,31)*(1-abs(x)/45)
        cone(col,"column",(x,y,h*.5),rng.uniform(1.7,3.3),rng.uniform(1.2,2.7),h,6,"Basalt",
             rot=(rng.uniform(-.12,.12),rng.uniform(-.18,.18),rng.uniform(0,.5)))
    return finish(col,"BasaltFan",31)


props=[spur("RockSpurA",901),spur("RockSpurB",911),fault_wall("FaultWallA",921),
       fault_wall("FaultWallB",939),talus_fan(),basalt_fan()]
objects=[o for col in scene.collection.children for o in col.objects if o.type=="MESH"]
for obj in objects:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in objects: obj.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/"RecoveryGeology.fbx"),use_selection=True,object_types={"MESH"},
                         axis_forward="-Z",axis_up="Y",apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
manifest={"props":props,"colors":{o.name:list(o.data.materials[0].diffuse_color[:3]) for o in objects}}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
gallery=bpy.data.scenes.new("RecoveryGallery")
gallery.world=bpy.data.worlds.new("RecoveryWorld")
gallery.world.color=(.10,.12,.14)
for index,p in enumerate(props):
    for obj in objects:
        if obj.name.startswith(p["name"]+"__"):
            duplicate=obj.copy()
            duplicate.data=obj.data
            duplicate.matrix_world=Matrix.Translation(((index%3-1)*105,(index//3)*95,0))@obj.matrix_world
            gallery.collection.objects.link(duplicate)
camera=bpy.data.objects.new("Camera",bpy.data.cameras.new("Camera"))
gallery.collection.objects.link(camera)
camera.location=(125,240,190)
camera.rotation_euler=(Vector((0,40,22))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type="ORTHO"
camera.data.ortho_scale=335
gallery.camera=camera
gallery.render.engine="BLENDER_WORKBENCH"
gallery.display.shading.light="STUDIO"
gallery.display.shading.color_type="MATERIAL"
gallery.display.shading.show_shadows=True
gallery.display.shading.show_cavity=True
gallery.render.resolution_x=1600
gallery.render.resolution_y=1050
gallery.render.resolution_percentage=100
gallery.render.filepath=str(OUT/"preview.png")
bpy.context.window.scene=gallery
bpy.ops.render.render(write_still=True)
bpy.context.window.scene=scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"RecoveryGeology.blend"))
print(json.dumps(manifest))
