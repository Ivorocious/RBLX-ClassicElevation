"""Author the feathered chicken as editable native Roblox Blocks and Wedges."""
from __future__ import annotations
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import runpy
import time
import bpy
from mathutils import Euler, Matrix, Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
OUT = HERE / "candidate_a02"
MODULE = REPO / "src/ServerStorage/CourseBuilders/EggRush/RestartP2/ChickenKit.luau"
BUILD = "ER_CHICKEN_R05_A02"
spec = importlib.util.spec_from_file_location("chicken_r04_source", HERE.parent / "chicken_r04/build_chicken.py")
r04 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r04)
kit, ATTACHMENTS = r04.kit, dict(r04.ATTACHMENTS)


def B(name, size, position, role="Cream", rx=0, ry=0, rz=0, primitive="Block"):
    return dict(name=name, size=size, position=position, role=role,
                angle=rz, angles=(rx, ry, rz), primitive=primitive)


TEMPLATES = {
    "Body": [
        B("PearCore", (25, 18, 28), (-5, 16, 0)),
        B("PearMiddle", (31, 14, 30), (-5, 16, 0)),
        B("ShoulderRound", (25, 11, 26), (-5, 25, 0)),
        B("RoundRump", (13, 16, 23), (-19, 16, 0)),
        B("TuckedBelly", (20, 10, 22), (-4, 7, 0)),
        B("LowerBreast", (9, 14, 22), (7.5, 17, 0)),
        B("UpperBreast", (10, 9, 23), (10, 29.5, 0)),
        B("BreastBib", (8, 9, 24), (8, 24.5, 0)),
    ],
    "Head": [
        B("BroadHead", (13.8, 10, 14), (0, 2, 0)),
        B("Face", (16, 7, 10), (0, 2, -1)),
        B("CheekPuff", (10.8, 4, 8), (0, -4, 3)),
        B("CombRoot", (3.5, 1.6, 13), (0, 7.5, 0), "Coral"),
        B("CombFront", (3.3, 5.5, 2.8), (0, 10.6, -4.8), "Coral"),
        B("CombFrontHigh", (3.3, 7.8, 2.8), (0, 11.75, -2.4), "Coral"),
        B("CombCrown", (3.3, 9.3, 2.8), (0, 12.5, 0), "Coral"),
        B("CombBackHigh", (3.3, 7.3, 2.8), (0, 11.5, 2.4), "Coral"),
        B("CombBack", (3.3, 5.2, 2.8), (0, 10.45, 4.8), "Coral"),
        B("Beak", (6, 3, 3), (0, -.5, -8.5), "Hot", primitive="Wedge"),
        B("WattleLeft", (2.6, 4.3, 2), (-2, -4.9, -5.2), "Coral", rz=-8),
        B("WattleRight", (2.6, 4.3, 2), (2, -4.9, -5.2), "Coral", rz=8),
    ],
    "Feet": [dict(part, primitive="Block") for part in r04.TEMPLATES["Feet"]],
}
for side in (-1, 1):
    TEMPLATES["Body"].extend([
        B(f"ShoulderFeather{side}", (5.8, 6, 9), (11.5, 30, side * 6.5), "Cream", rz=-5),
        B(f"WingCape{side}", (18, 7, 2.4), (-3.5, 22, side * 14.7), "Cream", rz=8),
        B(f"WingFrontFeather{side}", (2.6, 10, 11), (-.5, 17, side * 15.7), "Feather", ry=90, primitive="Wedge"),
        B(f"WingMiddleFeather{side}", (2.6, 12, 13), (-6.6, 16.5, side * 16.5), "Cream", ry=90, primitive="Wedge"),
        B(f"WingRearFeather{side}", (2.6, 10, 12), (-12.8, 17.5, side * 15.8), "Feather", ry=90, primitive="Wedge"),
        B(f"WingTipFeather{side}", (2.4, 8, 10), (-17, 19, side * 14.8), "Cream", ry=90, primitive="Wedge"),
    ])
    TEMPLATES["Head"].extend([
        B(f"CheekFeather{side}", (3, 4, 8), (side * 5.4, -4, 3), "Cream", primitive="Wedge"),
        B(f"EyeWhite{side}", (4.3, 4.7, .4), (side * 7.9, 2, -7.1), "Ivory", ry=-side * 45),
        B(f"Pupil{side}", (2.2, 2.75, .45), (side * 8.15, 1.8, -7.35), "Ink", ry=-side * 45),
        B(f"Brow{side}", (3.7, .65, .2), (side * 8.12, 3.85, -7.32), "Cream", ry=-side * 45),
        B(f"EyeGlint{side}", (.65, .65, .2), (side * 8.4, 2.55, -7.6), "Ivory", ry=-side * 45),
    ])
for index, (z, height, tilt) in enumerate([(-10, 17, -20), (-5.2, 22, -10), (0, 25, 0), (5.2, 22, 10), (10, 17, 20)], 1):
    TEMPLATES["Body"].append(B(f"FanTail{index}", (4.5, height, 5.2), (-23, 20 + height * .12, z),
                                  "Feather" if index % 2 else "Cream", rx=tilt,
                                  ry=180 if z < 0 else 0, rz=18,
                                  primitive="Block" if index == 3 else "Wedge"))

WEDGE_VERTICES = [(-.5, -.5, -.5), (.5, -.5, -.5), (-.5, -.5, .5),
                  (.5, -.5, .5), (-.5, .5, .5), (.5, .5, .5)]
WEDGE_FACES = [(1, 3, 2, 0), (3, 5, 4, 2), (4, 5, 1, 0), (2, 4, 0), (5, 3, 1)]


def create(parent, definition, materials):
    if definition["primitive"] == "Block":
        return r04.create(parent, definition, materials)
    size = Vector(definition["size"])
    mesh = bpy.data.meshes.new(definition["name"])
    mesh.from_pydata([kit.AXES @ (Vector(vertex) * size) for vertex in WEDGE_VERTICES], [], WEDGE_FACES)
    mesh.update()
    obj = bpy.data.objects.new(definition["name"], mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.location = kit.AXES @ Vector(definition["position"])
    rotation = Euler(tuple(math.radians(angle) for angle in definition["angles"]), "XYZ").to_matrix()
    obj.rotation_euler = (kit.AXES @ rotation @ kit.INVERSE_AXES).to_euler()
    obj.data.materials.append(materials[definition["role"]])
    obj["RobloxPrimitive"], obj["NativeName"] = "Wedge", definition["name"]
    obj["PaletteRole"], obj["ERLethal"] = definition["role"], definition["role"] == "Hot"
    return obj


def inspect_part(obj):
    record, corners = kit.inspect_part(obj)
    primitive = obj.get("RobloxPrimitive", "Block")
    record["primitive"] = primitive
    record["vertices"] = len(obj.data.vertices)
    record["triangles"] = sum(len(polygon.vertices) - 2 for polygon in obj.data.polygons)
    expected_volume = math.prod(record["size"]) * (.5 if primitive == "Wedge" else 1)
    assert abs(record["volume"] - expected_volume) < .003, (record["name"], record["volume"], expected_volume)
    assert record["vertices"] == (6 if primitive == "Wedge" else 8)
    assert record["triangles"] == (8 if primitive == "Wedge" else 12)
    record["localVertices"] = [kit.rounded(kit.INVERSE_AXES @ vertex.co) for vertex in obj.data.vertices]
    return record, corners


def export_module(records):
    kit.export_module(MODULE, records)
    module = MODULE.read_text(encoding="utf8").replace("HazardKit", "ChickenKit").replace(
        "revision_r02/hazards/build_hazard_kit.py", "chicken_r05/build_chicken.py")
    module = module.replace("lethal: boolean}", "lethal: boolean, className: string}")
    module = module.replace("Unknown Egg Rush hazard:", "Unknown chicken template:")
    for template in records.values():
        for part in template["parts"]:
            class_name = "WedgePart" if part["primitive"] == "Wedge" else "Part"
            module = module.replace(f'{{name="{part["name"]}", size=', f'{{name="{part["name"]}", className="{class_name}", size=')
    module = module.replace('local part = Instance.new("Part")', 'local part = Instance.new(definition.className) :: BasePart')
    MODULE.write_text(module, encoding="utf8")


def main():
    started = time.perf_counter()
    OUT.mkdir(parents=True, exist_ok=True)
    assert not (OUT / "chicken_kit.blend").exists(), "Choose a fresh candidate folder."
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = BUILD
    materials = {role: kit.material(role, rgb, role == "Hot", False) for role, rgb in kit.PALETTE.items()}
    records, roots = {}, {}
    for key, definitions in TEMPLATES.items():
        root = bpy.data.objects.new(key, None)
        scene.collection.objects.link(root)
        root["TemplateKey"] = key
        roots[key] = root
        objects = [create(root, definition, materials) for definition in definitions]
        bpy.context.view_layer.update()
        exported, corners = [], []
        for obj in objects:
            record, points = inspect_part(obj)
            exported.append(record)
            corners.extend(points)
        low = kit.rounded(min(point[axis] for point in corners) for axis in range(3))
        high = kit.rounded(max(point[axis] for point in corners) for axis in range(3))
        records[key] = dict(partCount=len(exported), lethalPartCount=sum(part["lethal"] for part in exported),
                            boundsRoblox=[low, high], parts=exported)
    assert sum(record["partCount"] for record in records.values()) <= 60
    previous = json.loads((HERE.parent / "chicken_r04/candidate_a02/manifest.json").read_text())
    for key, template in records.items():
        for axis in range(3):
            assert template["boundsRoblox"][0][axis] >= previous["templates"][key]["boundsRoblox"][0][axis] - .001, (key, "lower", axis)
            assert template["boundsRoblox"][1][axis] <= previous["templates"][key]["boundsRoblox"][1][axis] + .001, (key, "upper", axis)
    export_module(records)
    manifest = dict(build=BUILD, templates=records, attachments=ATTACHMENTS, palette=kit.PALETTE,
                    axes="Roblox X,Y,Z -> Blender X,-Z,Y", primitives="Native Blocks and WedgeParts",
                    checks=dict(finite=True, closedManifold=True, positiveVolume=True, orthonormalFrames=True,
                                exactPrimitiveTopology=True, withinR04A02Envelope=True),
                    baseline="assets/egg_rush_circuit/phase2/chicken_r04/candidate_a02",
                    proofBoundary="Blender-authored native primitive kit; no native Studio motion/contact proof.")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf8")
    roots["Head"].location = kit.AXES @ Vector(ATTACHMENTS["headHome"])
    native = Euler((0, -math.pi / 2, 0), "XYZ").to_matrix()
    roots["Head"].rotation_euler = (kit.AXES @ native @ kit.INVERSE_AXES).to_euler()
    r04.preview_neck(scene, materials)
    floor = create(None, B("PreviewFloor", (120, .3, 90), (0, -2.2, 0), "Ink"), materials)
    floor["PreviewOnly"] = "Isolated studio floor; not exported to Roblox."
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 1280, 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.world = bpy.data.worlds.new("ChickenStudio")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.12, .16, .21, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .65
    for name, position, power, size in [("BroadKey", (25, -45, 80), 95000, 70), ("Fill", (-40, 30, 50), 45000, 60)]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.shape, data.size = power, "DISK", size
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.location = position
        r04.look(light, kit.AXES @ Vector((0, 20, 0)))
    camera_data = bpy.data.cameras.new("ChickenCamera")
    camera_data.type, camera_data.ortho_scale = "ORTHO", 94
    camera = bpy.data.objects.new("ChickenCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    scene["Candidate"], scene["EvidenceBoundary"] = BUILD, manifest["proofBoundary"]
    bpy.context.preferences.filepaths.save_version = 0
    views = [("chicken_three_quarter", (85, 48, 85)), ("chicken_profile", (0, 31, 110)), ("chicken_front", (110, 35, 0))]
    for name, position in views:
        camera.location = kit.AXES @ Vector(position)
        r04.look(camera, kit.AXES @ Vector((0, 22, 0)))
        scene.render.filepath = str(OUT / (name + ".png"))
        bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "chicken_kit.blend"))
    files = [MODULE, OUT / "manifest.json", OUT / "chicken_kit.blend"] + [OUT / (name + ".png") for name, _ in views]
    report = dict(build=BUILD, parts=sum(record["partCount"] for record in records.values()), templates=len(records),
                  seconds=round(time.perf_counter() - started, 3),
                  hashes={str(path.relative_to(REPO)): hashlib.sha256(path.read_bytes()).hexdigest() for path in files},
                  beforeViews=[str((HERE.parent / "chicken_r04/candidate_a02" / (name + ".png")).relative_to(REPO)) for name, _ in views])
    (OUT / "build_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
    print("CHICKEN_KIT_BUILD " + json.dumps(report))
    runpy.run_path(str(HERE / "verify_saved_chicken.py"), run_name="__main__")


if __name__ == "__main__":
    main()
