"""Build the small V1 stud kit in a fresh Blender scene; never alter the open scene."""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

OUT = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)
SCENE = bpy.data.scenes.new("ClassicStudKit_V1")
bpy.context.window.scene = SCENE
SCENE.unit_settings.system = "NONE"
COLORS = {"Green": (94, 157, 76), "Gold": (231, 186, 71), "Blue": (79, 140, 193),
          "Coral": (192, 97, 76), "Purple": (150, 116, 181), "Gray": (178, 185, 192)}
MATS = {}
for name, rgb in COLORS.items():
    mat = bpy.data.materials.new("StudKit_" + name)
    mat.diffuse_color = tuple(v / 255 for v in rgb) + (1,)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = mat.diffuse_color
    shader.inputs["Roughness"].default_value = 0.72
    MATS[name] = mat

OBJECTS, MANIFEST = [], {}


class Mesh:
    def __init__(self):
        self.vertices, self.faces = [], []

    def add(self, vertices, faces):
        start = len(self.vertices)
        self.vertices.extend(vertices)
        self.faces.extend(tuple(start + i for i in face) for face in faces)

    def box(self, center, size):
        x, y, z = center
        a, b, c = (v / 2 for v in size)
        self.add([(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),
                  (x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)],
                 [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])

    def stud(self, center, u=(1,0,0), v=(0,1,0)):
        center, u, v = Vector(center), Vector(u), Vector(v)
        n = u.cross(v).normalized()
        vertices = []
        # A square tapered cap catches light without creating cylindrical Lego-like studs.
        for height, halfwidth in [(0, .325), (.085, .325), (.12, .285)]:
            for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)]:
                vertices.append(tuple(center + u*a*halfwidth + v*b*halfwidth + n*height))
        faces = [(8,9,10,11)]
        for ring in [0,4]:
            for i in range(4):
                j=(i+1)%4
                faces.append((ring+i,ring+j,ring+4+j,ring+4+i))
        self.add(vertices, faces)

    def finish(self, name, material, location, count, colliders):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.materials.append(MATS[material])
        mesh.update()
        mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles) < 20000
        assert all(poly.area > 0 for poly in mesh.polygons)
        obj = bpy.data.objects.new(name, mesh)
        SCENE.collection.objects.link(obj)
        obj.location = location
        OBJECTS.append(obj)
        MANIFEST[name] = {"triangles":len(mesh.loop_triangles),"studs":count,"material":material,
                          "location":location,"colliders":colliders}
        return obj


def block(center, size):
    return {"shape":"Block", "center":center, "size":size}


mesh = Mesh()
mesh.box((0,0,.5),(8,8,1))
for x in range(8):
    for y in range(8): mesh.stud((x-3.5,y-3.5,1))
mesh.finish("Floor", "Green", (-11,-7,0), 64, [block((0,0,.5),(8,8,1))])

mesh=Mesh()
mesh.box((0,0,3),(8,1,6))
for x in range(8):
    for z in range(6): mesh.stud((x-3.5,-.5,z+.5),v=(0,0,1))
mesh.finish("Wall", "Gold", (0,7,0),48,[block((0,0,3),(8,1,6))])

mesh=Mesh()
mesh.add([(-4,-4,0),(4,-4,0),(4,4,0),(-4,4,0),(-4,4,4),(4,4,4)],
         [(0,3,2,1),(3,4,5,2),(0,1,5,4),(0,4,3),(1,2,5)])
slope=Vector((0,8,4)).normalized()
slope_length=math.sqrt(80)
rows=8
for x in range(8):
    for row in range(rows):
        distance=(slope_length-(rows-1))/2+row
        mesh.stud(Vector((x-3.5,-4,0))+slope*distance,v=slope)
mesh.finish("Wedge", "Blue", (0,-7,0),64,[{"shape":"Wedge","center":(0,0,2),"size":(8,8,4)}])

mesh=Mesh()
colliders=[]
for step in range(4):
    height=step+1
    center=(0,-3+step*2,height/2)
    mesh.box(center,(8,2,height))
    colliders.append(block(center,(8,2,height)))
    for x in range(8):
        for y in range(2): mesh.stud((x-3.5,-3.5+step*2+y,height))
mesh.finish("Stair", "Coral", (11,-7,0),64,colliders)

mesh=Mesh()
mesh.box((-2.5,0,.5),(3,8,1))
mesh.box((1.5,2.5,.5),(5,3,1))
count=0
for x in range(8):
    for y in range(8):
        if x<3 or y>=5:
            mesh.stud((x-3.5,y-3.5,1)); count+=1
mesh.finish("Corner", "Purple", (-11,7,0),count,
            [block((-2.5,0,.5),(3,8,1)),block((1.5,2.5,.5),(5,3,1))])

# A single repeatable tile supplies either baked color shading or an OpenGL normal map.
size=128
heights=[]
for y in range(size):
    for x in range(size):
        d=max(abs((x+.5)/size-.5),abs((y+.5)/size-.5))
        heights.append(.12 if d<=.285 else max(0,.12-(d-.285)*3) if d<=.325 else 0)
normal_pixels, color_pixels=[],[]
for y in range(size):
    for x in range(size):
        dx=(heights[y*size+(x+1)%size]-heights[y*size+(x-1)%size])*size/2
        dy=(heights[((y+1)%size)*size+x]-heights[((y-1)%size)*size+x])*size/2
        normal=Vector((-dx,-dy,1)).normalized()
        normal_pixels.extend([(normal.x+1)/2,(normal.y+1)/2,(normal.z+1)/2,1])
        shade=.70+.25*max(0,normal.dot(Vector((-.4,-.5,1)).normalized()))
        color_pixels.extend([shade,shade,shade,1])
for name,pixels in [("stud_normal_opengl",normal_pixels),("stud_shaded_color",color_pixels)]:
    img=bpy.data.images.new(name,width=size,height=size,alpha=True)
    img.colorspace_settings.name="Non-Color" if "normal" in name else "sRGB"
    img.pixels.foreach_set(pixels)
    img.filepath_raw=str(OUT/(name+".png"));img.file_format="PNG";img.save()

for sample,location in [("ColorTexture",(7,7,0)),("NormalMap",(14,7,0))]:
    mesh=Mesh();mesh.box((0,0,.5),(5,5,1))
    obj=mesh.finish(sample,"Gray",location,0,[block((0,0,.5),(5,5,1))])
    uv=obj.data.uv_layers.new(name="UVMap")
    for poly in obj.data.polygons:
        for loop_index in poly.loop_indices:
            co=obj.data.vertices[obj.data.loops[loop_index].vertex_index].co
            uv.data[loop_index].uv=(co.x+.5,co.y+.5)
    mat=MATS["Gray"].copy();mat.name=sample
    obj.data.materials[0]=mat
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;shader=nodes.get("Principled BSDF")
    tex=nodes.new("ShaderNodeTexImage")
    tex.image=bpy.data.images["stud_normal_opengl" if sample=="NormalMap" else "stud_shaded_color"]
    tex.interpolation="Linear";tex.extension="REPEAT"
    # Top faces receive the comparison material; sides use the original plain gray.
    obj.data.materials.append(MATS["Gray"])
    for poly in obj.data.polygons: poly.material_index=0 if poly.normal.z>.9 else 1
    if sample=="NormalMap":
        normal=nodes.new("ShaderNodeNormalMap")
        links.new(tex.outputs["Color"],normal.inputs["Color"])
        links.new(normal.outputs["Normal"],shader.inputs["Normal"])
    else:
        links.new(tex.outputs["Color"],shader.inputs["Base Color"])

for obj in SCENE.objects: obj.select_set(False)
geometry=[obj for obj in OBJECTS if obj.name not in ("ColorTexture","NormalMap")]
for obj in geometry: obj.select_set(True)
bpy.context.view_layer.objects.active=geometry[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/"ClassicStudKit_V1.fbx"),use_selection=True,
                         object_types={"MESH"},axis_forward="-Z",axis_up="Y",
                         apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
manifest={"revision":"V1","units":"studs","axes":"X right, Y depth, Z up",
          "pitch":1,"width":.65,"height":.12,"colors":COLORS,"meshes":MANIFEST,
          "fbxMeshes":[obj.name for obj in geometry],"totalGeometryStuds":sum(MANIFEST[o.name]["studs"] for o in geometry)}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2))

world=bpy.data.worlds.new("StudKitWorld");world.use_nodes=True
world.node_tree.nodes["Background"].inputs["Color"].default_value=(.42,.49,.58,1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value=.6
SCENE.world=world
lightdata=bpy.data.lights.new("KitSun","SUN");lightdata.energy=2.5;lightdata.angle=.15
light=bpy.data.objects.new("KitSun",lightdata);SCENE.collection.objects.link(light)
light.rotation_euler=(math.radians(27),math.radians(-32),math.radians(-25))
camera_data=bpy.data.cameras.new("KitCamera");camera=bpy.data.objects.new("KitCamera",camera_data)
SCENE.collection.objects.link(camera);SCENE.camera=camera
SCENE.render.engine="CYCLES";SCENE.cycles.samples=24
SCENE.render.resolution_x=1800;SCENE.render.resolution_y=1200;SCENE.render.resolution_percentage=100
SCENE.view_settings.view_transform="Standard"
for name,position,look,scale in [("overview",(32,-44,42),(1,0,1),43),
                                ("stud_closeup",(-4,-16,7),(-10,-7,1),12),
                                ("map_comparison",(23,-2,10),(10.5,7,.7),15)]:
    camera.location=position;camera.rotation_euler=(Vector(look)-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.type="ORTHO";camera_data.ortho_scale=scale
    SCENE.render.filepath=str(OUT/(name+".png"));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"ClassicStudKit_V1.blend"))
print(json.dumps({"meshes":len(geometry),"studs":manifest["totalGeometryStuds"],
                  "triangles":sum(MANIFEST[o.name]["triangles"] for o in geometry)}))
