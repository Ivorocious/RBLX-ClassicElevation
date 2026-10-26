"""Author the C11 depot and rolling stock in an isolated Blender scene."""
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
scene.name = "CityRun_C11_Depot"
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


component("Depot_RetainingViaduct")
box("Iron", (3684, 72.8, -154), (66, 2.4, 142))
box("Stone", (3652, 37, -154), (3, 74, 142))
box("Brick", (3716, 36, -154), (4, 72, 142))
for z in (-214, -185, -156, -127, -98):
    for x in (3653, 3681, 3715):
        box("Stone", (x, 37, z), (4, 74, 4))
        box("Stone", (x, 72.5, z), (7, 2, 7))
    beam("Iron", (3654, 56, z), (3681, 72, z), .55)
    beam("Iron", (3714, 56, z), (3681, 72, z), .55)
for x in (3665, 3682, 3698):
    box("Roof", (x, 74.15, -154), (12.8, .65, 140))
    for z in range(-222, -84, 4):
        box("WoodDark", (x, 74.65, z), (10.8, .28, .8))
    for dx in (-4.65, 4.65):
        box("Rail", (x+dx, 74.95, -154), (.28, .35, 139))

component("Depot_MaintenanceShed")
# Three open workshop bays face the parkour siding; their roofs carry the district silhouette.
box("Brick", (3696, 36, -163), (35, 72, 108))
box("Stone", (3696, 73.2, -163), (36, 2.4, 110))
box("Brick", (3713, 88, -163), (1.8, 27, 108))
for z in (-217, -181, -145, -109):
    box("Brick", (3696, 87, z), (35, 26, 2))
    box("Stone", (3678.8, 88, z), (2.2, 28, 3))
    box("Cream", (3678.5, 100, z), (2.6, 1.4, 3.6))
for z in (-199, -163, -127):
    box("Iron", (3695.5, 98.8, z), (37, 1.3, 33.5))
    box("Glass", (3678.3, 104.4, z), (.3, 9, 31.5))
    for zz in range(z-15, z+16, 5):
        box("Cream", (3678.05, 104.4, zz), (.25, 9.4, .2))
    prism("Roof", [(3677.6, 109.6), (3714.8, 101.2), (3714.8, 100.1), (3677.6, 108.5)], z-17.3, z+17.3)
    box("Iron", (3678.5, 99, z), (1.8, 1.5, 34))
    for y in (83, 93):
        beam("Iron", (3679, y, z-16), (3712, y+4, z-16), .2)
    for zz in (z-11, z, z+11):
        beam("Iron", (3679, 97.7, zz), (3712, 97.7, zz), .22)
        box("Light", (3690, 96.9, zz), (6, .28, 1))
    box("Iron", (3711.8, 84, z), (.4, 16, 27))
    for zz in (z-9, z+9):
        box("Teal", (3711.4, 81.8, zz), (.5, 9, 6))
    for xx in (3683, 3695, 3707):
        box("Yellow", (xx, 74.6, z-16), (5, .07, .4))
    text("SERVICE " + str((-z-91)//36), (3677.75, 97.1, z), 1.4, "Cream", -math.pi/2)
for z in range(-214, -109, 8):
    box("Terracotta", (3714.05, 86.5, z), (.16, 22, .7))
box("Teal", (3696, 95, -218.15), (28, 4, .45))
text("CITY RAIL  /  WORKS", (3696, 95, -218.42), 1.7, "White", math.pi)

component("Depot_ControlTower")
box("Brick", (3721, 41, -116), (12, 82, 15))
box("Stone", (3721, 82, -116), (13, 1.5, 16))
box("Cream", (3721, 93, -116), (11, 20, 14))
for x in (3715.35, 3726.65):
    box("Glass", (x, 96.5, -116), (.18, 7, 12))
    for z in (-121, -116, -111):
        box("Iron", (x, 96.5, z), (.25, 7.3, .18))
for z in (-123.2, -108.8):
    box("Glass", (3721, 96.5, z), (9, 7, .18))
box("Roof", (3721, 104, -116), (15, 1.3, 18))
beam("Iron", (3721, 104, -116), (3721, 115, -116), .16)
beam("Rail", (3718, 112, -116), (3724, 112, -116), .1)
text("CONTROL", (3721, 89, -108.38), 1.3, "Iron")

component("Depot_ServiceProps")
for z, color in ((-197, "Teal"), (-160, "Yellow"), (-126, "Coral")):
    box(color, (3707, 77.8, z), (7, 5.6, 8))
    for x in (3704.5, 3709.5):
        beam("Iron", (x, 75.8, z-4.1), (x, 75.8, z+4.1), .75, 12)
    for zz in (z-2.7, z, z+2.7):
        box("Rail", (3707, 81, zz), (6, .4, 1.5))
for z in (-189, -152, -117):
    box("Wood", (3675.2, 75.7, z), (3, 1.4, 4.5))
    box("Yellow", (3675.2, 77.4, z), (2.4, 2, 3.5))
    for zz in (z-1.1, z+1.1):
        box("Iron", (3675.2, 77.4, zz), (2.5, 2.1, .12))
for z in (-175, -140):
    beam("Rail", (3675, 75, z), (3675, 80, z), 1.1, 12)
    beam("Iron", (3675, 77.5, z), (3675, 77.7, z), 1.13, 12)


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
                     (x+dx+axle, wheel_y, z+side*(gauge+.32)), 1.05, 16)
                beam("Rail", (x+dx+axle, wheel_y, z+side*(gauge+.32)),
                     (x+dx+axle, wheel_y, z+side*(gauge+.38)), .46, 12)
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


# Wheels extend below the lethal body volume to meet the existing rails.
for i in range(3):
    rail_vehicle("ActiveTrain"+str(i), (3590+(i-1)*38, -12), 36.7, 9.8,
                 89.25, "Blue" if i == 1 else "Iron", cab=i == 2, active=True, rear=i == 0)

# Parked stock is authored along X, then rotated to match each existing roof collider.
for i, z in enumerate((-210, -181.5, -153, -124.5, -96)):
    start_keys = set(api["groups"])
    rail_vehicle("Depot_Parked"+str(i), (3665, z), 23.8, 10, 82,
                 ("Teal", "Coral", "Blue", "Yellow", "Teal")[i], cab=i in (0, 4))
    for key in set(api["groups"])-start_keys:
        for vertices, _ in api["groups"][key]:
            for index, (bx, by, bz) in enumerate(vertices):
                worldx, worldz = bx+3500, -by
                vertices[index] = (3665+(worldz-z)-3500, -(z-(worldx-3665)), bz)

component("Depot_CrossingEquipment")
for x, z in ((3697.5, -26), (3712.5, 2)):
    box("Stone", (x, 82.6, z), (2.4, 1.2, 2.8))
    box("Yellow", (x, 84.1, z), (1.6, 2.4, 1.8))
    box("Iron", (x, 84.85, z), (2, .5, 2.1))
    beam("Iron", (x, 82, z+2), (x, 91.5, z+2), .16)
    box("Iron", (x, 90.4, z+2), (3.5, 2, .6))
    for dx in (-.9, .9):
        beam("Red", (x+dx, 90.4, z+1.62), (x+dx, 90.4, z+1.68), .49, 12)
    box("White", (x, 87.8, z+2), (4, .6, .25))
    box("White", (x, 87.8, z+2), (.6, 4, .25))
for name, x, z, direction in (("TrainBarrier", 3697.5, -26, 1), ("TrainBarrierExit", 3712.5, 2, -1)):
    component(name, "Moving", [x, 84.8, z])
    box("Cream", (x+direction*7.2, 84.8, z), (14.4, .65, .6))
    for i in range(7):
        box("Red", (x+direction*(1.2+i*2), 84.8, z), (1, .67, .62))
    box("Iron", (x-direction*1, 84.8, z), (2.5, 1.5, 1.5))
    beam("Rail", (x, 84.8, z-.65), (x, 84.8, z+.65), .5, 12)

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
bpy.ops.export_scene.fbx(filepath=str(OUT / "CityRun_C11_depot.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = dict(revision="C11_02", components=definitions, meshes=meshes, colors=api["COLORS"])
(OUT / "manifest_C11_depot.json").write_text(json.dumps(data, indent=2))


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


(ROOT / "src/ServerStorage/CourseBuilders/CityRun/C11DepotManifest.luau").write_text("--!strict\nreturn " + luau(data) + "\n")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CityRun_C11_depot.blend"))
print(json.dumps(dict(meshes=len(meshes), components=len(definitions),
                      triangles=sum(m["triangles"] for m in meshes.values()))))
