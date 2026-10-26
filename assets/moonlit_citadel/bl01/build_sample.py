"""Build the bounded daylight sample in an isolated Blender process."""
import argparse
import hashlib
import json
import math
import sys
import time
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import architecture
import mechanisms

BUILD = "MC_P1_BL01"
started = time.perf_counter()
parser = argparse.ArgumentParser()
parser.add_argument("--render-only", action="store_true")
parser.add_argument("--skip-render", action="store_true")
options = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])


def collection(name):
    result = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(result)
    return result


def context_library(destination):
    mats = architecture._materials()
    mats.update(mechanisms._materials())
    for key, rgb in {"Floor": (164, 172, 180), "Leaf": (68, 94, 67), "Banner": (38, 64, 104)}.items():
        material = bpy.data.materials.new("MC_BL01_" + key)
        material.use_nodes = True
        material.diffuse_color = tuple(architecture._linear(v) for v in rgb) + (1,)
        shader = material.node_tree.nodes.get("Principled BSDF")
        shader.inputs["Base Color"].default_value = material.diffuse_color
        shader.inputs["Roughness"].default_value = .85
        mats[key] = material
    results = []

    def make(name, geometry, role, bevel=.04):
        item = mechanisms._make_object(destination, name, geometry, mats, role, bevel)
        results.append(item)

    g = mechanisms._Geometry()
    g.box((0, 1.75, 33), (66, .5, 66), "StoneDark")
    for row in range(16):
        z = 2.05 + row * 4.1
        for x_side in (-1, 1):
            for column in range(3):
                x = x_side * (15.1 + column * 7.18)
                key = "StoneLight" if (row + column) % 7 == 0 else "Stone"
                g.box((x, 0, z), (7.10, 3.3, 4.02), key)
    for z in (.4, 44, 64):
        g.box((0, -.1, z), (66.7, 3.7, .65), "StoneLight")
    for z in (1.7, 63):
        g.box((0, 0, z), (24, 3.3, 3.2), "Stone")
    make("MC_KeepShell", g, "Closed facade with actual shallow stone courses and window recess", .045)

    g = mechanisms._Geometry()
    g.rectangle_profile([(0, 5.2, 5.8), (1, 5.2, 5.8), (1.4, 4.3, 5.3),
                         (12, 4.3, 5.3), (12.5, 3.6, 4.8), (51, 3.6, 4.8),
                         (52, 4.4, 5.4), (53, 4.4, 5.4), (54, 3.2, 4.4),
                         (58, 3.2, 4.4), (60, .4, 3.4)], "Stone")
    for z in (1.2, 12.2, 31, 52.3):
        g.box((0, 0, z), (4.6, 5.45, .45), "StoneLight")
    make("MC_PierStone", g, "Stepped carved buttress; base Z0", .055)

    g = mechanisms._Geometry()
    for row in range(3):
        for column in range(3):
            g.box((-6 + column * 6, -4 + row * 4, -.42), (5.96, 3.96, .84), "Floor")
    g.box((0, 0, -.87), (18, 12, .16), "StoneDark")
    g.box((0, -5.94, -.61), (18, .12, .2), "StoneLight")
    make("MC_FloorStone", g, "Pale reusable terrace/deck; top Z0,18x12", .014)

    g = mechanisms._Geometry()
    g.box((0, 0, 0), (.48, 1.3, 52), "Iron")
    for y in (-.62, .62):
        g.box((0, y, 0), (1.1, .16, 52), "Iron")
    for z in (-25.5, -13, 0, 13, 25.5):
        g.box((0, -.77, z), (1.45, .25, .42), "Brass")
    make("MC_GuideIron", g, "Machine guide,52 high,center origin", .018)

    g = mechanisms._Geometry()
    radius = 3.02 * .7
    center = 5.8 - radius
    points = [(-center + radius * math.cos(math.radians(180 - i * 7.5)), 0,
               radius * math.sin(math.radians(180 - i * 7.5))) for i in range(13)]
    points.extend((center + radius * math.cos(math.radians(90 - i * 7.5)), 0,
                   radius * math.sin(math.radians(90 - i * 7.5))) for i in range(13))
    g.tube(points, .085, "Iron", sides=6)
    make("MC_CableReturnIron", g, "Continuous upper pulley return,11.6 span,base Z0", 0)

    g = architecture._Mesh()
    g.prism(architecture._pointed(1.86, 10.5, 14.52), -3.31, -3.25, "Amber")
    item = architecture._object(destination, "MC_TurretAmber", g, mats, .01,
                                "Matches front turret recess; duplicate around shaft at90 degrees")
    results.append(item)

    g = mechanisms._Geometry()
    # A folded fabric outline and its emblem are separate material surfaces.
    points = [(-1.6, -.06, 0), (1.6, .08, 0), (1.5, .16, -8.2),
              (0, -.03, -10.4), (-1.5, .05, -8.2)]
    back = [(x, y + .09, z) for x, y, z in points]
    g.add(points + back, [(0, 1, 2, 3, 4), (9, 8, 7, 6, 5)] +
          [(i, (i + 1) % 5, (i + 1) % 5 + 5, i + 5) for i in range(5)], "Banner")
    g.tube([(-1.9, 0, .3), (1.9, 0, .3)], .08, "Brass", sides=8)
    g.tube([(.55 * math.cos(t), -.15, -4.4 + .55 * math.sin(t))
            for t in [math.radians(70 + i * 16) for i in range(15)]], .065, "Brass", sides=6)
    mechanisms._diamond(g, (0, -.16, -6.25), .55, .85, .04, "Brass")
    make("MC_Banner", g, "Restrained folded blue banner with crescent and diamond", .01)

    g = mechanisms._Geometry()
    g.tube([(math.sin(i * .6) * .3, .1, i * .55) for i in range(20)], .06, "Leaf", sides=5)
    for i in range(18):
        z = .4 + i * .54
        side = -1 if i % 2 else 1
        x = side * (.4 + (i % 3) * .1)
        g.add([(x, 0, z), (x + side * .62, .01, z + .48),
               (x + side * .25, -.12, z + .78), (x - side * .14, 0, z + .47),
               (x + side * .24, .05, z + .38)],
              [(0, 1, 2), (0, 2, 3), (0, 4, 1), (0, 3, 4), (1, 4, 2), (2, 4, 3)], "Leaf")
    make("MC_Ivy", g, "Sparse relief ivy,grouped mesh,not individual leaf instances", 0)
    return results


def evaluated_mesh(obj):
    graph = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(graph),
                                          preserve_all_data_layers=True, depsgraph=graph)
    # Bevels at pointed tips can leave coincident edges in the evaluated mesh.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return mesh


def validate(mesh):
    mesh.calc_loop_triangles()
    assert all(math.isfinite(value) for vertex in mesh.vertices for value in vertex.co)
    small = [p.index for p in mesh.polygons if p.area < 1e-9]
    assert not small, (mesh.name, "degenerate faces", small[:8])
    bm = bmesh.new()
    bm.from_mesh(mesh)
    result = {"vertices": len(mesh.vertices), "triangles": len(mesh.loop_triangles),
              "boundary_edges": sum(e.is_boundary for e in bm.edges),
              "nonmanifold_edges": sum(not e.is_manifold for e in bm.edges),
              "signed_volume": bm.calc_volume(signed=True)}
    bm.free()
    assert result["signed_volume"] > 0, (mesh.name, result)
    return result


def bounds(mesh):
    low = [min(v.co[axis] for v in mesh.vertices) for axis in range(3)]
    high = [max(v.co[axis] for v in mesh.vertices) for axis in range(3)]
    return low, high


def srgb(value):
    return round(255 * (12.92 * value if value <= .0031308 else 1.055 * value ** (1 / 2.4) - .055))


def export_units(objects, destination):
    records, asset_records = [], []
    for obj in objects:
        baked = evaluated_mesh(obj)
        info = validate(baked)
        low, high = bounds(baked)
        asset_records.append({"asset": obj.name, "bounds": [low, high], "geometry": info,
                              "origin": [0, 0, 0], "role": obj.get("Role", obj.get("MountingNotes", "Decoration"))})
        for slot, material in enumerate(baked.materials):
            indices = [p.index for p in baked.polygons if p.material_index == slot]
            if not indices:
                continue
            subset = baked.copy()
            bm = bmesh.new()
            bm.from_mesh(subset)
            bm.faces.ensure_lookup_table()
            discard = [f for f in bm.faces if f.material_index != slot]
            bmesh.ops.delete(bm, geom=discard, context="FACES")
            loose = [v for v in bm.verts if not v.link_faces]
            if loose:
                bmesh.ops.delete(bm, geom=loose, context="VERTS")
            for face in bm.faces:
                face.material_index = 0
            bm.to_mesh(subset)
            bm.free()
            subset.materials.clear()
            subset.materials.append(material)
            key = material.name.removeprefix("MC_BL01_")
            name = obj.name + "__" + key
            exported = bpy.data.objects.new(name, subset)
            destination.objects.link(exported)
            exported["AssetKey"], exported["Build"] = obj.name, BUILD
            local_low, local_high = bounds(subset)
            center = [(a + b) / 2 for a, b in zip(local_low, local_high)]
            size = [b - a for a, b in zip(local_low, local_high)]
            records.append({"name": name, "asset": obj.name, "material": key,
                            "rgb": [srgb(v) for v in material.diffuse_color[:3]],
                            "center": center, "size": size,
                            "roblox_center": [center[0], center[2], -center[1]],
                            "roblox_size": [size[0], size[2], size[1]],
                            "triangles": len(subset.loop_triangles) if subset.loop_triangles else sum(len(p.vertices) - 2 for p in subset.polygons)})
        bpy.data.meshes.remove(baked)
    return records, asset_records


def place(source, destination, asset, name, point, scale=(1, 1, 1), angle=0):
    obj = source[asset].copy()
    obj.data = source[asset].data
    obj.name = name
    destination.objects.link(obj)
    obj.location, obj.scale, obj.rotation_euler.z = point, scale, angle
    return obj


def compose(source, destination):
    def pair(assets, name, point, scale=(1, 1, 1), angle=0):
        return [place(source, destination, asset, name + "_" + asset, point, scale, angle) for asset in assets]

    pair(["MC_KeepShell"], "Keep", (0, 31, -10))
    pair(["MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"], "HeroWindow", (0, 28, -8))
    for x in (-31, -18, 18, 31):
        pair(["MC_PierStone"], "Buttress" + str(x), (x, 27, -10))
    for x in (-37, 37):
        pair(["MC_TurretStone", "MC_TurretAmber"], "Turret" + str(x), (x, 23, -10))
        pair(["MC_TurretAmber"], "TurretSideAmber" + str(x), (x, 23, -10), angle=math.pi / 2)
        pair(["MC_SlateSpire"], "Spire" + str(x), (x, 23, 18))
        pair(["MC_StoneArch"], "Support" + str(x), (x, -13, -16), angle=math.pi / 2)
        pair(["MC_Banner"], "Banner" + str(x), (x - math.copysign(4.5, x), 19.6, 5))
        pair(["MC_Ivy"], "Ivy" + str(x), (x - math.copysign(4.8, x), 20, -3))
    for x in (-29, 29):
        pair(["MC_TurretStone", "MC_TurretAmber"], "HighTurret" + str(x), (x, 30, 39), scale=(.7, .7, .7))
        pair(["MC_TurretAmber"], "HighTurretSideAmber" + str(x), (x, 30, 39), scale=(.7, .7, .7), angle=math.pi / 2)
        pair(["MC_SlateSpire"], "HighSpire" + str(x), (x, 30, 58.6), scale=(.7, .7, .7))
    for x, height in ((-9, 0), (9, 18)):
        pair(["MC_CarStone", "MC_CarIronBrass"], "Balcony" + str(x), (x, 0, height))
        outside = math.copysign(27, x)
        car_cable_x = x + math.copysign(6.4, x)
        cable_mid = (outside + car_cable_x) / 2
        pair(["MC_WeightStone", "MC_WeightIron"], "Weight" + str(x), (outside, 0, 39 - height))
        for px in (min(outside, car_cable_x) + 3.02 * .7, max(outside, car_cable_x) - 3.02 * .7):
            pair(["MC_PulleyIron", "MC_PulleyBrass"], "Pulley" + str(px), (px, 0, 46), (.7, .7, .7))
        pair(["MC_CableReturnIron"], "CableReturn" + str(x), (cable_mid, 0, 46))
        header = pair(["MC_GuideIron"], "Header" + str(x), (cable_mid, 1.8, 46), (.75, .75, 11.6 / 52))[0]
        header.rotation_euler.y = math.pi / 2
        pair(["MC_KillCasing", "MC_KillRed"], "Red" + str(x), (x, 0, -12))
        for guide_x in (x - 8, x + 8, outside - 3, outside + 3):
            pair(["MC_GuideIron"], "Guide" + str(guide_x), (guide_x, 1, 18))
        for chain_x, lower in ((car_cable_x, height + 3), (outside, 43 - height)):
            g = mechanisms._Geometry()
            g.tube([(chain_x, 0, lower), (chain_x, 0, 46)], .085, "Iron", sides=6)
            mechanisms._make_object(destination, "Cable" + str(chain_x), g, mechanisms._materials(), "Preview only", 0)
    pair(["MC_FloorStone"], "BoardingTerrace", (0, -17, 0), (48 / 18, 18 / 12, 2))
    pair(["MC_FloorStone"], "UpperExit", (0, 17, 34), (40 / 18, 18 / 12, 2))
    pair(["MC_FloorStone"], "Catch", (0, -23, -8), (54 / 18, 14 / 12, 1))
    for x in (-15, 3):
        pair(["MC_BalustradeStone", "MC_BalustradeIron"], "EntryRail" + str(x), (x, -25.5, 0))
    for x in (-10, 10):
        pair(["MC_BalustradeStone", "MC_BalustradeIron"], "ExitRail" + str(x), (x, 25.5, 34))
    for i, (x, y, z) in enumerate([(23, -21, 0), (31, -19, 4), (25, -14, 8), (17, -12, 12), (9, -10.5, 14), (9, -10.5, 28)]):
        pair(["MC_FloorStone"], "Brace" + str(i), (x, y, z), (6 / 18, 5 / 12, 1))
    for x in (-24, 24):
        pair(["MC_LanternCage", "MC_LanternCore"], "FixedLantern" + str(x), (x, -21, 5), (.5, .5, .5))
    material = bpy.data.materials.new("ScaleIvory")
    material.diffuse_color = (.72, .75, .77, 1)
    material.use_nodes = True
    material.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = material.diffuse_color
    for i, point in enumerate([(-17, -21, 0), (-9, 0, 0), (9, 0, 18), (-7, 17, 34)]):
        g = mechanisms._Geometry()
        g.box((0, 0, 3.15), (1.6, .9, 2), "Ivory")
        g.box((0, 0, 4.72), (1.2, 1.05, 1.1), "Ivory")
        for side in (-1, 1):
            g.box((side * 1.1, 0, 3.10), (.55, .85, 1.85), "Ivory")
            g.box((side * .45, 0, 1.03), (.7, .8, 2.06), "Ivory")
        item = mechanisms._make_object(destination, "ScaleFigure" + str(i), g, {"Ivory": material}, "Static scale reference;not multiplayer proof", .055)
        item.location = point


def render_scene():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1600, 1100
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world = bpy.data.worlds.new("Clear daylight work")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.48, .54, .64, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .7
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.exposure = .8
    lights = collection("DAYLIGHT")
    for name, point, power, size in [("Broad daylight", (-35, -40, 70), 110000, 55), ("Open sky fill", (45, 0, 55), 95000, 45)]:
        light = bpy.data.lights.new(name, "AREA")
        light.energy, light.shape, light.size = power, "DISK", size
        obj = bpy.data.objects.new(name, light)
        lights.objects.link(obj)
        obj.location = point
        obj.rotation_euler = (Vector((0, 0, 18)) - obj.location).to_track_quat("-Z", "Y").to_euler()
    camera = bpy.data.cameras.new("SampleDaylightCamera")
    obj = bpy.data.objects.new("SampleDaylightCamera", camera)
    lights.objects.link(obj)
    scene.camera = obj
    for name, point, aim, focal in [("MC_BL01_blender_daylight", (89, -120, 79), (0, 5, 31), 39),
                                   ("MC_BL01_blender_player", (-13, -38, 5.2), (0, 1, 21), 24)]:
        obj.location = point
        obj.rotation_euler = (Vector(aim) - obj.location).to_track_quat("-Z", "Y").to_euler()
        camera.lens = focal
        scene.render.filepath = str(ROOT / (name + ".png"))
        bpy.ops.render.render(write_still=True)


if not options.render_only:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1
    authored = collection("AUTHOR_EDIT_UNITS")
    objects = architecture.build_library(authored) + mechanisms.build_library(authored) + context_library(authored)
    exported = collection("EXPORT_MATERIAL_UNITS")
    parts, assets = export_units(objects, exported)
    authored.hide_render, exported.hide_render = True, True
    preview = collection("UPPER_SAMPLE_DAYLIGHT_STATIC_POSE")
    compose({obj.name: obj for obj in objects}, preview)
    bpy.ops.object.select_all(action="DESELECT")
    for item in exported.objects:
        item.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(ROOT / "MC_BL01_library.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS", use_mesh_modifiers=True,
                             bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
    manifest = {"candidate": BUILD, "blender": bpy.app.version_string, "units": "1 unit=1 intended stud",
                "axes": "X right,Z up,front-Y; Roblox center=(X,Z,-Y)",
                "presentation": "Daylight. Static different lift heights are an appearance pose.",
                "texture_boundary": "Procedural stone grain is render-only. Native meshes carry actual shaped trim and material colors.",
                "assets": assets, "export_parts": parts,
                "asset_count": len(assets), "part_count": len(parts),
                "export_triangles": sum(p["triangles"] for p in parts),
                "build_seconds_before_render": round(time.perf_counter() - started, 3)}
    (ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
else:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / "MC_BL01_sample.blend"))

if not options.skip_render:
    render_scene()
for name in ("AUTHOR_EDIT_UNITS", "EXPORT_MATERIAL_UNITS"):
    bpy.data.collections[name].hide_viewport = True
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.shading.type = "MATERIAL"
            area.spaces.active.region_3d.view_location = (0, 5, 31)
            area.spaces.active.region_3d.view_distance = 135
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "MC_BL01_sample.blend"))
files = ["architecture.py", "mechanisms.py", "build_sample.py", "MC_BL01_library.fbx", "MC_BL01_sample.blend", "manifest.json"]
receipt = {"candidate": BUILD, "elapsed_seconds": round(time.perf_counter() - started, 3),
           "files": {name: {"bytes": (ROOT / name).stat().st_size, "sha256": hashlib.sha256((ROOT / name).read_bytes()).hexdigest()}
                     for name in files if (ROOT / name).is_file()}}
(ROOT / "build_receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"candidate": BUILD, "outputs": list(receipt["files"]), "elapsed_seconds": receipt["elapsed_seconds"]}), flush=True)
