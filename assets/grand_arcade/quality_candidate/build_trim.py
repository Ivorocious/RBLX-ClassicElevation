"""Isolated Q01 decorative trim; uses A01 bay positions and writes only this folder."""
import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
BASE = ROOT.parent / "A01"
OUT = ROOT / "Q01"
OUT.mkdir(parents=True, exist_ok=True)
manifest = json.loads((BASE / "manifest.json").read_text())
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = "NONE"
scene.unit_settings.scale_length = 1
materials = {}
for name, color in manifest["colors"].items():
    material = bpy.data.materials.new("Q01_" + name)
    material.diffuse_color = (*color, 1)
    materials[name] = material
added = []
section = "PlatformTrim"
transform = None


def mapped(v):
    if transform is None:
        return tuple(v)
    x, y, angle = transform
    c, s = math.cos(angle), math.sin(angle)
    return (x + v[0]*c - v[1]*s, y + v[0]*s + v[1]*c, v[2])


def mesh(name, mat, vertices, faces, bevel=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata([mapped(v) for v in vertices], [], faces)
    data.materials.append(materials[mat])
    data.update()
    data.validate()
    normals = bmesh.new()
    normals.from_mesh(data)
    bmesh.ops.recalc_face_normals(normals, faces=list(normals.faces))
    normals.to_mesh(data)
    normals.free()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj["Section"], obj["Material"] = section, mat
    if bevel:
        bpy.context.view_layer.objects.active = obj
        modifier = obj.modifiers.new("SmallEdgeFinish", "BEVEL")
        modifier.width, modifier.segments = bevel, 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.context.view_layer.objects.active = obj
    triangulate = obj.modifiers.new("ExplicitTriangles", "TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    added.append(obj)
    return obj


def box(name, mat, p, size, bevel=.04):
    x, y, z = p
    a, b, c = (v/2 for v in size)
    vs = [(x+dx*a, y+dy*b, z+dz*c) for dx, dy, dz in [
        (-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
        (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name, mat, vs, [(0,3,2,1),(4,5,6,7),(0,1,5,4),
        (1,2,6,5),(2,3,7,6),(3,0,4,7)], bevel)


def arch(name, mat, inner, outer, spring, front, depth):
    segments = 40
    vs = []
    for y in [front, front+depth]:
        for radius in [inner, outer]:
            vs += [(radius*math.cos(i*math.pi/segments), y,
                    spring+radius*math.sin(i*math.pi/segments)) for i in range(segments+1)]
    ring = segments+1
    fs = []
    for i in range(segments):
        fs += [(i,i+1,ring+i+1,ring+i),
               (2*ring+i,3*ring+i,3*ring+i+1,2*ring+i+1),
               (i,2*ring+i,2*ring+i+1,i+1),
               (ring+i,ring+i+1,3*ring+i+1,3*ring+i)]
    fs += [(0,ring,3*ring,2*ring),
           (segments,2*ring+segments,3*ring+segments,ring+segments)]
    return mesh(name, mat, vs, fs)


def ring(name, mat, rx, ry, width, bottom, top, center=(0,0)):
    n = 96
    vs = []
    for z in [bottom, top]:
        for offset in [-width/2, width/2]:
            vs += [(center[0]+(rx+offset)*math.cos(i*math.tau/n),
                    center[1]+(ry+offset)*math.sin(i*math.tau/n),z) for i in range(n)]
    fs = []
    for i in range(n):
        j = (i+1)%n
        fs += [(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),
               (i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)]
    return mesh(name, mat, vs, fs)


PANEL_WIDTH = 12.4
PANEL_HEIGHT = PANEL_WIDTH * 13.2 / 13.5
PANEL_Z, PLAQUE_Z = 14.0, 6.6
KEY_HALF_ANGLE = math.radians(6)


def bay_arch_trim(name, start, end):
    segments = max(4, math.ceil((end-start)/math.radians(4)))
    angles = [start+(end-start)*i/segments for i in range(segments+1)]
    vertices = [(radius*math.cos(angle),y,17.5+radius*math.sin(angle))
                for y in [-.69,-.50] for radius in [8.86,9.12] for angle in angles]
    ring = segments+1
    faces = []
    for i in range(segments):
        faces += [(i,i+1,ring+i+1,ring+i),
                  (2*ring+i,3*ring+i,3*ring+i+1,2*ring+i+1),
                  (i,2*ring+i,2*ring+i+1,i+1),
                  (ring+i,ring+i+1,3*ring+i+1,3*ring+i)]
    faces += [(0,ring,3*ring,2*ring),
              (segments,2*ring+segments,3*ring+segments,ring+segments)]
    return mesh(name,"Pale",vertices,faces)


def panel_ring(name, mat, outer_width, outer_height, inner_width, inner_height, z, front, depth):
    vertices = []
    for y in [front,front+depth]:
        for width,height in [(inner_width,inner_height),(outer_width,outer_height)]:
            vertices += [(x*width/2,y,z+zz*height/2) for x,zz in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    faces = []
    for i in range(4):
        j = (i+1)%4
        faces += [(i,j,4+j,4+i),(8+i,12+i,12+j,8+j),
                  (i,8+i,8+j,j),(4+i,4+j,12+j,12+i)]
    return mesh(name,mat,vertices,faces)


for bay in manifest["bays"]:
    section = "Bay" + str(bay["index"]) + "Trim"
    transform = (bay["p"][0], bay["p"][1], bay["angle"])
    for side,(start,end) in enumerate([(0,math.pi/2-KEY_HALF_ANGLE),(math.pi/2+KEY_HALF_ANGLE,math.pi)]):
        bay_arch_trim("OuterMolding"+str(side),start,end)
    for side in [-1,1]:
        box("ColumnFace", "Pale", (side*8.28,-1.01,9.0), (.94,.18,15.5), .045)
        box("ColumnInset", "Ivory", (side*8.28,-1.13,9.0), (.54,.08,14.8), .025)
        box("BaseLip", "Ivory", (side*8.28,0,1.38), (2.47,2.73,.16), .045)
        box("CapitalLip", "Ivory", (side*8.28,0,17.04), (2.20,2.63,.17), .04)
    panel_ring("OnePanelCasing","Pale",PANEL_WIDTH+.7,PANEL_HEIGHT+.7,PANEL_WIDTH,PANEL_HEIGHT,PANEL_Z,-1.08,.30)
    panel_ring("PanelGoldFace","Gold",PANEL_WIDTH+.18,PANEL_HEIGHT+.18,PANEL_WIDTH,PANEL_HEIGHT,PANEL_Z,-1.11,.03)
    panel_ring("PlaqueGoldFace","Gold",PANEL_WIDTH+.36,1.77,PANEL_WIDTH,1.55,PLAQUE_Z,-.99,.13)
    for rank, x, h, mat in [(2,-3.6,2.3,"Silver"),(1,0,3.4,"Gold"),(3,3.6,1.95,"Bronze")]:
        box("PodiumFoot"+str(rank), "Navy", (x,-3,.09), (3.49,3.39,.18), .06)
        box("PodiumLedge"+str(rank), "Pale", (x,-3,h-.04), (3.48,3.38,.14), .045)
        for dx in [-1.48,1.48]:
            box("PodiumFaceSide"+str(rank), mat, (x+dx,-4.70,h/2), (.10,.16,h-.20), .018)
        for z in [.14,h-.14]:
            box("PodiumFaceLine"+str(rank), mat, (x,-4.70,z), (3.05,.16,.08), .015)
transform = None
section = "PresenterTrim"
ring("PresenterRim", "Gold", 6.86, 6.86, .14, .40, .46, (0,-5))
section = "PlatformTrim"
ring("LowerPlinthBand", "Pale", 52.06, 24.06, .16, -.90, -.74)

# Join only candidate trim by section/material; keep preview base outside export.
groups = {}
for obj in added:
    groups.setdefault((obj["Section"],obj["Material"]),[]).append(obj)
exported = []
mesh_info = {}
for (group, mat), members in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in members:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = members[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = group+"__"+mat
    obj.data.calc_loop_triangles()
    mesh_info[obj.name] = {"section":group,"material":mat,
                           "triangles":len(obj.data.loop_triangles)}
    mesh_info[obj.name]["bounds"] = [
        [min(v.co[axis] for v in obj.data.vertices) for axis in range(3)],
        [max(v.co[axis] for v in obj.data.vertices) for axis in range(3)]]
    exported.append(obj)

section = "Calibration"
for key, position in [("Origin",(0,0,0)),("Right",(10,0,0)),
                      ("Up",(0,0,10)),("Forward",(0,-10,0))]:
    obj = box("Q01Marker"+key+"__Navy", "Navy", position, (.12,.12,.12), 0)
    obj.hide_render = True
    obj.data.calc_loop_triangles()
    mesh_info[obj.name] = {"section":"Calibration","material":"Navy",
                          "triangles":len(obj.data.loop_triangles)}
    exported.append(obj)

bpy.ops.object.select_all(action="DESELECT")
for obj in exported:
    obj.select_set(True)
bpy.context.view_layer.objects.active = exported[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/"GrandArcade_Q01_Trim.fbx"),
    use_selection=True,object_types={"MESH"},axis_forward="-Z",axis_up="Y",
    apply_unit_scale=True,add_leaf_bones=False)
report = {"revision":"Q01-trim-candidate","base":"A01","meshes":mesh_info,
          "triangles":sum(v["triangles"] for v in mesh_info.values()),
          "meshCount":len(exported),"colliders":0,"slotChanges":0,"bayChanges":0,
          "colors":manifest["colors"],"apertureStuds":[PANEL_WIDTH,PANEL_HEIGHT],
          "units":manifest["units"],
          "note":"Decorative add-on only. Native runtime collision/UI and all original positions remain owned by the lead.",
          "calibration":{"origin":"Q01MarkerOrigin__Navy","right":"Q01MarkerRight__Navy",
                         "up":"Q01MarkerUp__Navy","forward":"Q01MarkerForward__Navy"}}
(OUT/"trim-manifest.json").write_text(json.dumps(report,indent=2))

# Save the editable candidate without loading the owner's live scene.
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"GrandArcade_Q01_Trim.blend"))
with bpy.data.libraries.load(str(BASE/"GrandArcade_A01.blend"),link=False) as (available, requested):
    requested.objects = [name for name in available.objects if "__" in name and not name.startswith("Marker")]
for obj in requested.objects:
    if obj:
        scene.collection.objects.link(obj)
scene.world = bpy.data.worlds.new("CandidateReviewWorld")
scene.world.color = (.66,.69,.74)
camera_data = bpy.data.cameras.new("CandidateReviewCamera")
camera = bpy.data.objects.new("CandidateReviewCamera",camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.cavity_type = "BOTH"
scene.display.shading.background_type = "WORLD"
scene.view_settings.view_transform = "Standard"
scene.render.resolution_x,scene.render.resolution_y = 1440,1000
scene.render.resolution_percentage = 100
camera_data.ortho_scale = 117
views = {"front":((0,-120,48),(0,0,10)),"quarter":((90,-100,54),(0,-5,9)),
         "player":((10,-53,5.2),(0,10,10)),"podium":((10,-20,7),(0,10,9))}
for name,(position,target) in views.items():
    camera.location = position
    camera.rotation_euler = (Vector(target)-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.type = "PERSP" if name in ["player","podium"] else "ORTHO"
    camera_data.lens = 24 if name=="player" else 32
    scene.render.filepath = str(OUT/(name+".png"))
    bpy.ops.render.render(write_still=True)
print("Q01_TRIM "+json.dumps({"meshes":report["meshCount"],"triangles":report["triangles"],"colliders":0}))
