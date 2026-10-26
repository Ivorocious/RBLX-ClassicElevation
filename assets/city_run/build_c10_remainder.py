"""Extend the owner's obstacle rhythm and close city framing after CP03."""
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
scene.name = "CityRun_C10_Remainder"
owner, box, beam, cylinder, geo, text = (api[k] for k in ("owner", "box", "beam", "cylinder", "geo", "text"))
for name, color in {"Danger": (1, .02, .015), "Direction": (.02, .85, .87),
                    "Crumble": (.91, .69, .16), "Sage": (.40, .54, .39),
                    "Ochre": (.78, .54, .28), "Powder": (.40, .58, .64)}.items():
    api["COLORS"][name] = color
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1)
    api["MATS"][name] = material

saved = json.loads((ROOT / "docs/artifacts/city-run/C10-current-surfaces.json").read_text())
surfaces = {r["path"].split("/")[3]: r for r in saved}
definitions = {}


def component(name, section, role="Scenery", **options):
    owner(name, section)
    definitions[name] = dict(section=section, role=role, **options)


def local(p):
    return (p[0] - 3500, p[1], p[2])


def top(name):
    s = surfaces[name]
    return (s["cf"][0], s["cf"][1] + s["size"][1] / 2, s["cf"][2])


def kill_box(name, p, size, section, **attrs):
    component(name, section, "Kill", attrs=attrs)
    box("Danger", local(p), size)


def strip(surface, travel, section, offset=0):
    x, y, z = top(surface)
    width = surfaces[surface]["size"][2 if travel == "X" else 0]
    size = (.85, .55, width - .65) if travel == "X" else (width - .65, .55, .85)
    kill_box("Hurdle_" + surface, (x + (offset if travel == "X" else 0), y + .275,
                                  z + (offset if travel == "Z" else 0)), size, section)


def offset_block(surface, travel, side, section):
    x, y, z = top(surface)
    if travel == "X":
        p, size = (x, y + 1, z + side * 2.8), (2.5, 2, 4)
    else:
        p, size = (x + side * 2.8, y + 1, z), (4, 2, 2.5)
    kill_box("Weave_" + surface, p, size, section)


def spinner(surface, section, diameter=10, period=8, cross=False):
    x, y, z = top(surface)
    component("Hub_" + surface, section)
    cylinder("Iron", local((x, y + .35, z)), 1.05, .7, 12)
    cylinder("Yellow", local((x, y + .74, z)), .72, .12, 12)
    kill_box("Spinner_" + surface, (x, y + .95, z), (diameter, .6, .85), section,
             KitMotion="Spin", MotionAxis="Y", MotionPeriod=period)
    if cross:
        kill_box("SpinnerCross_" + surface, (x, y + .95, z), (.85, .6, diameter), section,
                 KitMotion="Spin", MotionAxis="Y", MotionPeriod=period)


for name in ("DistrictRoofs_00_01", "DistrictRoofs_00_03"):
    strip(name, "X", "Roof")
for name, side in (("DistrictRoofs_01_01", -1), ("DistrictRoofs_01_02", 1),
                   ("DistrictRoofs_01_03", -1)):
    offset_block(name, "Z", side, "Roof")
spinner("DistrictRoofs_02_01", "Roof", 10, 8)
spinner("DistrictRoofs_02_03", "Roof", 10.5, 9, True)
strip("DistrictRoofs_04_01", "X", "Roof")

# The waiting decks immediately beside the wrecking balls remain clear.
for name, travel in (("RoofMainEntry_00_01", "Z"), ("RoofMainEntry_01_01", "X"),
                     ("RoofMainMiddle_00_02", "Z"), ("RoofMainMiddle_02_01", "Z")):
    strip(name, travel, "Construction")
for name, side in (("RoofGarden_00_01", -1), ("RoofGarden_01_01", 1)):
    offset_block(name, "Z" if "00_" in name else "X", side, "RoofGarden")

strip("DepotAccess_00_01", "X", "Depot")
for index, side in ((1, -1), (2, 1), (3, -1)):
    offset_block(f"StationaryTrains_00_{index:02}", "Z", side, "Depot")
strip("StationaryTrains_00_02", "Z", "Depot", offset=-6)
strip("DepotExit_00_01", "Z", "Depot")

for name in ("StationEntry_02", "StationEntry_05"):
    strip(name, "Z", "Station")
strip("StationMain_00_01", "X", "Station")
offset_block("StationMain_00_02", "X", -1, "Station")
spinner("StationMain_00_03", "Station", 9, 8.5)
strip("StationMain_00_05", "X", "Station")
offset_block("StationMain_01_08", "Z", 1, "Station")
strip("StationMain_02_01", "X", "Station")
spinner("StationMain_02_03", "Station", 9, 9)

# Edge patches preserve the difficult shortcut's existing takeoff and landing centers.
for index, side in ((2, -1), (4, 1), (6, -1), (8, 1)):
    name = f"X03_01_{index:02}"
    x, y, z = top(name)
    kill_box("ExpertEdge_" + name, (x + side * 1.5, y + .2, z), (.65, .4, 2.8), "StationExpert")

replacements = [f"StationMain_01_{i:02}" for i in range(2, 6)]
crumble_rows = []
for row in range(9):
    z = 88 + row * 10
    y = 96.375 + (z - 77.375) * 11 / 163
    crumble_rows.append((z, y))
    for lane, x in enumerate((3827, 3834, 3841), 1):
        name = f"StationCrumble_Row{row + 1:02}_Lane{lane}"
        component(name, "Station", "Crumble", attrs={"CrumbleDelay": .75, "CrumbleResetTime": 2.5})
        box("Crumble", local((x, y - .5, z)), (5.5, 1, 5))
        for dx in (-1.65, 1.65):
            box("WoodDark", local((x + dx, y + .015, z)), (.07, .035, 4.45))

# The scaffold carries the tile rows while leaving empty space beneath a fallen tile.
component("StationCrumble_Scaffold", "Station")
for x in (3822.8, 3845.2):
    for z, y in (crumble_rows[0], crumble_rows[4], crumble_rows[-1]):
        beam("Rail", local((x, 75, z)), local((x, y - 2.3, z)), .2, 8)
        box("Iron", local((x, 75.2, z)), (1.4, .4, 1.4))
    beam("Rail", local((x, crumble_rows[0][1] - 2.3, crumble_rows[0][0] - 3)),
         local((x, crumble_rows[-1][1] - 2.3, crumble_rows[-1][0] + 3)), .19, 8)
for z, y in crumble_rows:
    beam("Rail", local((3822.8, y - 2.3, z)), local((3845.2, y - 2.3, z)), .13, 6)


def arrow(name, p, direction, size=1):
    component(name, "Wayfinding")
    x, y, z = local(p)
    dx, dz = direction
    outline = [(-.6, -2), (.6, -2), (.6, .25), (1.55, .25), (0, 2.25), (-1.55, .25), (-.6, .25)]
    vertices = [(x + (a * dz + b * dx) * size, y + h, z + (-a * dx + b * dz) * size)
                for h in (0, .05) for a, b in outline]
    n = len(outline)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    faces.extend((i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n))
    geo("Direction", vertices, faces)


for name, p, direction in [
    ("RoofEntry", (3343, 69.08, -123), (-1, 0)),
    ("RoofTurnNorth", (3280, 73.08, -126), (0, -1)),
    ("RoofTurnEast", (3281, 78.08, -202), (1, 0)),
    ("RoofTurnNorth2", (3345, 82.08, -202), (0, -1)),
    ("RoofTurnEast2", (3346, 82.08, -244), (1, 0)),
    ("WorkLoop", (3480, 82.08, -301), (1, 0)),
    ("WorkReturn", (3519, 82.08, -305), (0, 1)),
    ("GardenTurn", (3567, 84.08, -306), (1, 0)),
    ("DepotTurn", (3665, 82.08, -242), (0, 1)),
    ("DepotTransfer", (3665, 82.08, -97), (1, 0)),
    ("DepotExit", (3705, 82.08, -96), (0, 1)),
    ("StationTurn", (3830, 95.08, 57), (0, 1)),
    ("StationHome", (3830, 106.08, 220), (-1, 0)),
    ("StationLastTurn", (3745, 116.08, 220), (0, -1)),
]:
    arrow("RouteArrow_" + name, p, direction)


component("StationCrumble_EntrySign", "Wayfinding")
beam("Iron", local((3845.2, 75, 88)), local((3845.2, 102.5, 88)), .17, 8)
beam("Iron", local((3845.2, 102.5, 88)), local((3849, 102.5, 85.5)), .17, 8)
box("Teal", local((3849, 102.5, 85.5)), (8, 2.3, .45))
text("KEEP MOVING", local((3849, 102.5, 85.25)), 1.0, "Cream", math.pi)
text("KEEP MOVING", local((3849, 102.5, 85.75)), 1.0, "Cream")

# New blocks sit beside the route, with the dense frontage concentrated near eye level.
buildings = [
    ("Roof_WestCorner", 3246, -183, 28, 42, 105, "Brick"),
    ("Roof_InnerCorner", 3392, -205, 29, 30, 103, "Plaster"),
    ("Roof_EastCourt", 3410, -157, 32, 35, 111, "Sage"),
    ("Roof_NorthFrame", 3424, -370, 34, 30, 131, "Brick"),
    ("Roof_GardenFrame", 3628, -366, 36, 33, 119, "Powder"),
    ("Depot_WestArrival", 3638, -191, 28, 38, 110, "Ochre"),
    ("Depot_EastWorks", 3699, -171, 30, 46, 119, "Brick"),
    ("Depot_WestYard", 3639, -94, 28, 34, 109, "Plaster"),
    ("Depot_EastHotel", 3750, -110, 36, 44, 128, "Sage"),
    ("Depot_CrossingCorner", 3675, -66, 27, 22, 114, "Powder"),
    ("Depot_EastRefuge", 3760, -53, 36, 30, 106, "Plaster"),
    ("Station_EastArrival", 3885, 58, 40, 40, 113, "Brick"),
    ("Station_EastArcade", 3890, 119, 44, 46, 131, "Ochre"),
    ("Station_EastCorner", 3884, 181, 42, 48, 142, "Sage"),
    ("Station_SouthCourt", 3828, 274, 46, 34, 137, "Brick"),
    ("Station_SouthHotel", 3772, 277, 42, 29, 127, "Powder"),
]
for index, (name, wx, z, w, d, h, color) in enumerate(buildings):
    name = "CityC10_" + name
    api["building"](name, wx - 3500, z, w, d, h, color, detail=True)
    definitions[name] = dict(section="Depot" if "Depot_" in name else "Station" if "Station_" in name else "Roof",
                             role="Scenery", footprint=[wx, z, w, d], height=h)

# Section-specific details occupy the building side of the route.
for i, (x, y, z) in enumerate(((3290, 59, -168), (3358, 59, -182), (3377, 60, -244))):
    component(f"Roof_ServiceBox{i + 1}", "Roof")
    box("Rail", local((x, y + 2, z)), (5.5, 4, 4))
    for zz in (-1.3, -.65, 0, .65, 1.3):
        box("Iron", local((x + 2.79, y + 2, z + zz)), (.1, 2.7, .18))
    box("Cream", local((x, y + 4.15, z)), (6, .3, 4.5))

for i, z in enumerate((-185, -155, -124)):
    component(f"Depot_RoofVent{i + 1}", "Depot")
    box("Rail", local((3661.7, 82.35, z)), (1.5, .7, 3.6))
    for dz in (-1.1, -.35, .35, 1.1):
        box("Iron", local((3661.7, 82.75, z + dz)), (1.25, .15, .18))

for i, (x, y, z) in enumerate(((3830, 75, 203), (3810, 75, 230), (3738, 104, 184))):
    component(f"Station_ServicePlanter{i + 1}", "Station")
    api["planter"](local((x, y, z)), 6)

for name, position in [("Origin", (0, 0, 0)), ("Right", (10, 0, 0)),
                       ("Up", (0, 10, 0)), ("Forward", (0, 0, -10))]:
    component("Marker" + name, "Calibration")
    box("Iron", position, (.1, .1, .1))

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
bpy.ops.export_scene.fbx(filepath=str(OUT / "CityRun_C10_remainder.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)

data = dict(revision="C10_01", components=definitions, meshes=meshes, colors=api["COLORS"],
            replacements=replacements, expectedOwnerBuild="C09_05_Park")
(OUT / "manifest_C10.json").write_text(json.dumps(data, indent=2))


def luau(value):
    if isinstance(value, dict):
        return "{" + ",".join("[" + json.dumps(k) + "]=" + luau(v) for k, v in value.items()) + "}"
    if isinstance(value, (list, tuple)):
        return "{" + ",".join(map(luau, value)) + "}"
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


(ROOT / "src/ServerStorage/CourseBuilders/CityRun/C10Manifest.luau").write_text("--!strict\nreturn " + luau(data) + "\n")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CityRun_C10_remainder.blend"))
print(json.dumps(dict(meshes=len(meshes), components=len(definitions), triangles=sum(m["triangles"] for m in meshes.values()),
                      replacements=replacements)))
