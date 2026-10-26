"""Build the bounded C10 review refinements in a separate Blender scene."""
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
scene.name = "CityRun_C10_Refinement"
owner, box, beam, text = (api[k] for k in ("owner", "box", "beam", "text"))
definitions = {}


def point(x, y, z):
    return (x - 3500, y, z)


def component(name, section):
    owner(name, section)
    definitions[name] = dict(section=section)


for name, x, z, width, depth, height, color in (
    ("Construction_RenovationBlock", 3507, -207, 34, 30, 116, "Plaster"),
    ("Station_TracksideOffice", 3796, 20, 48, 24, 115, "Brick"),
):
    api["building"](name, x - 3500, z, width, depth, height, color, detail=True)
    definitions[name] = dict(section="Construction" if name.startswith("Construction") else "Station")

component("Construction_RenovationScaffold", "Construction")
for x in (3489, 3501, 3513, 3525):
    beam("Iron", point(x, 0, -224), point(x, 119, -224), .18, 8)
    box("Stone", point(x, .4, -224), (1.4, .8, 1.4))
for y in (80, 92, 104, 116):
    box("WoodDark", point(3507, y, -224.1), (38, .45, 2.8))
    beam("Rail", point(3488, y + 3, -225.4), point(3526, y + 3, -225.4), .13, 8)
for x in (3489, 3501, 3513):
    for y in (80, 92, 104):
        beam("Iron", point(x, y, -224.5), point(x + 12, y + 12, -224.5), .1, 6)
box("Teal", point(3507, 99, -225.1), (13, 3.2, .3))
text("RENOVATION", point(3507, 99, -225.3), 1.1, "White", math.pi)

component("Station_HallClerestory", "Station")
box("Cream", point(3800, 112, 163), (25, 18, 34))
box("Stone", point(3800, 103.5, 163), (26, 1, 35))
box("Teal", point(3800, 121.6, 163), (27, 1.2, 36))
for x in (3790, 3795, 3800, 3805, 3810):
    for z in (145.85, 180.15):
        box("Iron", point(x, 114.5, z), (3.8, 8, .25))
        box("Glass", point(x, 114.5, z + (.16 if z > 163 else -.16)), (3.2, 7.4, .12))
        box("Cream", point(x, 114.5, z + (.24 if z > 163 else -.24)), (.16, 7.6, .12))
for z in (151, 159, 167, 175):
    for x in (3787.35, 3812.65):
        box("Glass", point(x, 114.5, z), (.2, 7.5, 5.5))
box("Teal", point(3800, 117, 180.5), (13, 2.7, .4))
text("CITY RAIL", point(3800, 117, 180.73), 1.5, "White")

for name, z, title, subtitle in (
    ("Depot_ArrivalGantry", -204, "DEPOT", "PARKED TRAINS"),
    ("Depot_TransferGantry", -101, "TRANSFER", "TO THE CROSSING"),
):
    component(name, "Depot")
    for x in (3657.6, 3672.4):
        beam("Iron", point(x, 74, z), point(x, 99, z), .24, 8)
        box("Stone", point(x, 74.5, z), (1.7, 1, 1.7))
    for y in (97.5, 99):
        beam("Iron", point(3657.6, y, z), point(3672.4, y, z), .2, 8)
    for x in (3657.6, 3661.3, 3665, 3668.7):
        beam("Rail", point(x, 97.5, z), point(x + 3.7, 99, z), .11, 6)
    box("Iron", point(3665, 96.4, z), (14.3, 3.4, .45))
    for face, rotation in ((-.27, math.pi), (.27, 0)):
        text(title, point(3665, 97, z + face), 1.45, "White", rotation)
        text(subtitle, point(3665, 95.6, z + face), .72, "White", rotation)

component("Depot_OverheadRailWires", "Depot")
for z in (-174, -140):
    beam("Iron", point(3672.4, 74, z), point(3672.4, 97.5, z), .18, 8)
    beam("Rail", point(3672.4, 97.5, z), point(3664.7, 97.5, z), .14, 8)
    beam("Rail", point(3672.4, 95, z), point(3666, 97.5, z), .11, 6)
    box("Cream", point(3665, 97.1, z), (.65, .9, .65))
beam("Iron", point(3665, 96.5, -204), point(3665, 96.5, -101), .06, 6)

component("StationCrumble_OverheadNotice", "Wayfinding")
for x in (3822.8, 3845.2):
    beam("Iron", point(x, 75, 85.5), point(x, 109.4, 85.5), .17, 8)
    box("Stone", point(x, 75.35, 85.5), (1.2, .7, 1.2))
beam("Iron", point(3822.8, 109.4, 85.5), point(3845.2, 109.4, 85.5), .16, 8)
box("Teal", point(3834, 108.7, 85.5), (10, 2.3, .4))
text("KEEP MOVING", point(3834, 108.7, 85.26), 1, "White", math.pi)
text("KEEP MOVING", point(3834, 108.7, 85.74), 1, "White")

for name, p in (("Origin", (0, 0, 0)), ("Right", (10, 0, 0)),
                ("Up", (0, 10, 0)), ("Forward", (0, 0, -10))):
    component("Marker" + name, "Calibration")
    box("Iron", p, (.1, .1, .1))

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
        meshes[obj.name] = dict(component=name, material=material, triangles=len(mesh.loop_triangles))
for obj in scene.objects:
    obj.select_set(False)
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT / "CityRun_C10_refinement.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = dict(revision="C10_02", components=definitions, meshes=meshes, colors=api["COLORS"])
(OUT / "manifest_C10_refinement.json").write_text(json.dumps(data, indent=2))


def luau(value):
    if isinstance(value, dict):
        return "{" + ",".join("[" + json.dumps(k) + "]=" + luau(v) for k, v in value.items()) + "}"
    if isinstance(value, (list, tuple)):
        return "{" + ",".join(map(luau, value)) + "}"
    if isinstance(value, str):
        return json.dumps(value)
    return str(value)


(ROOT / "src/ServerStorage/CourseBuilders/CityRun/C10RefinementManifest.luau").write_text("--!strict\nreturn " + luau(data) + "\n")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CityRun_C10_refinement.blend"))
print(json.dumps(dict(meshes=len(meshes), components=len(definitions),
                      triangles=sum(m["triangles"] for m in meshes.values()))))
