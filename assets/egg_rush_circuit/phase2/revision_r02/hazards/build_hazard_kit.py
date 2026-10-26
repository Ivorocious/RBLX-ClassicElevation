"""Build editable hatchery hazards in isolated Blender and export native Roblox Parts."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time

import bpy
import bmesh
from mathutils import Euler, Matrix, Vector


BUILD = "ER_P2_R02_H02"
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
PALETTE = {
    "Cream": (255, 240, 202), "Coral": (246, 125, 96),
    "Mint": (104, 205, 176), "Honey": (185, 123, 67),
    "Iron": (100, 106, 120), "Hot": (255, 20, 35),
}
AXES = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
INVERSE_AXES = AXES.transposed()
CUBE_VERTICES = [(-1,-1,-1), (1,-1,-1), (1,1,-1), (-1,1,-1),
                 (-1,-1,1), (1,-1,1), (1,1,1), (-1,1,1)]
CUBE_FACES = [(0,3,2,1), (4,5,6,7), (0,1,5,4),
              (2,3,7,6), (1,2,6,5), (3,0,4,7)]


def block(name, size, position, role, angle=0):
    return dict(name=name, size=size, position=position, role=role, angle=angle)


TEMPLATES = {
    "ScorchedShell": [
        block("IronCradle", (6.6,.4,2.4), (0,.2,0), "Iron"),
        block("ShellLeft", (1.25,2.15,2.45), (-2.32,1.39,0), "Cream", 24),
        block("ShellRight", (1.25,2.15,2.45), (2.32,1.39,0), "Cream", -24),
        block("BrokenRimLeft", (1.8,.6,2.5), (-1.54,.65,0), "Cream", 21),
        block("BrokenRimRight", (1.8,.6,2.5), (1.54,.65,0), "Cream", -21),
        block("HotToothLeft", (.85,1.65,2.1), (-1.15,1.28,0), "Hot", -13),
        block("HotToothCenter", (1,2.05,2.1), (0,1.45,0), "Hot"),
        block("HotToothRight", (.85,1.5,2.1), (1.15,1.2,0), "Hot", 13),
    ],
    "FeederPaddle": [
        block("IronFoot", (1.55,.4,2.35), (-2.22,.2,0), "Iron"),
        block("MintStem", (.85,1.9,1.6), (-2.22,1.3,0), "Mint"),
        block("IronHub", (1.25,.85,2.1), (-2.22,1.65,0), "Iron"),
        block("MintArm", (4.3,.7,1.5), (-.25,1.65,0), "Mint"),
        block("HoneyBrace", (2.4,.35,1.45), (-.95,1.18,0), "Honey", 12),
        block("CoralCollar", (.55,1.05,2.1), (1.45,1.65,0), "Coral"),
        block("HotPaddle", (1.25,1.35,3), (2.23,1.65,0), "Hot"),
    ],
    "HeatGrate": [
        block("CoralFrontRail", (6.8,.55,.5), (0,.275,-1.25), "Coral"),
        block("CoralBackRail", (6.8,.55,.5), (0,.275,1.25), "Coral"),
        block("IronLeftRail", (.5,.5,2.1), (-3.12,.25,0), "Iron"),
        block("IronRightRail", (.5,.5,2.1), (3.12,.25,0), "Iron"),
        block("HotBar1", (.72,.7,2.45), (-2.17,.56,0), "Hot"),
        block("HotBar2", (.72,.7,2.45), (-.72,.56,0), "Hot"),
        block("HotBar3", (.72,.7,2.45), (.72,.56,0), "Hot"),
        block("HotBar4", (.72,.7,2.45), (2.17,.56,0), "Hot"),
    ],
    "FeatherPinch": [
        block("IronFoot", (6.7,.4,2.4), (0,.2,0), "Iron"),
        block("CreamFeatherLeft", (1.3,2.15,2.25), (-2.57,1.4,0), "Cream", -12),
        block("CreamFeatherRight", (1.3,2.15,2.25), (2.57,1.4,0), "Cream", 12),
        block("CreamTipLeft", (2.15,.65,2.25), (-1.66,2.4,0), "Cream", 12),
        block("CreamTipRight", (2.15,.65,2.25), (1.66,2.4,0), "Cream", -12),
        block("HotLowerFingerLeft", (1.65,.65,1.9), (-1.36,1.15,0), "Hot", 20),
        block("HotLowerFingerRight", (1.65,.65,1.9), (1.36,1.15,0), "Hot", -20),
        block("HotUpperFingerLeft", (1.3,.55,1.9), (-.96,2.03,0), "Hot", 12),
        block("HotUpperFingerRight", (1.3,.55,1.9), (.96,2.03,0), "Hot", -12),
    ],
}


def linear_channel(value):
    value /= 255
    return value/12.92 if value <= .04045 else ((value+.055)/1.055)**2.4


def material(name, rgb, hot=False, metal=False):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    color = tuple(linear_channel(value) for value in rgb) + (1,)
    result.diffuse_color = color
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = .42
    shader.inputs["Metallic"].default_value = .3 if metal else 0
    if hot:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = .6
    return result


def create_box(scene, parent, spec, materials):
    sx, sy, sz = spec["size"]
    mesh = bpy.data.meshes.new(spec["name"])
    mesh.from_pydata([(x*sx/2, y*sz/2, z*sy/2) for x,y,z in CUBE_VERTICES], [], CUBE_FACES)
    mesh.update()
    obj = bpy.data.objects.new(spec["name"], mesh)
    scene.collection.objects.link(obj)
    obj.parent = parent
    obj.location = AXES @ Vector(spec["position"])
    rotation = Euler((0, 0, math.radians(spec["angle"])), "XYZ").to_matrix()
    obj.rotation_euler = (AXES @ rotation @ INVERSE_AXES).to_euler()
    obj.data.materials.append(materials[spec["role"]])
    obj["RobloxPrimitive"] = "Block"
    obj["NativeName"] = spec["name"]
    obj["PaletteRole"] = spec["role"]
    obj["ERLethal"] = spec["role"] == "Hot"
    return obj


def rounded(values):
    return [0 if abs(value) < 1e-6 else round(value, 5) for value in values]


def inspect_part(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(edge.is_manifold for edge in bm.edges), (obj.name, "open primitive")
    volume = bm.calc_volume(signed=True)
    assert volume > 1e-6, (obj.name, "non-positive volume")
    assert all(face.calc_area() > 1e-6 for face in bm.faces), (obj.name, "degenerate face")
    assert all(math.isfinite(number) for vert in bm.verts for number in vert.co), obj.name
    bm.free()
    local = obj.matrix_local
    rotation = INVERSE_AXES @ local.to_3x3() @ AXES
    assert abs(rotation.determinant()-1) < 1e-5, obj.name
    bounds = [Vector(corner) for corner in obj.bound_box]
    extent = [max(corner[i] for corner in bounds)-min(corner[i] for corner in bounds) for i in range(3)]
    size = rounded((extent[0], extent[2], extent[1]))
    position = rounded(INVERSE_AXES @ local.translation)
    matrix = rounded(number for row in rotation for number in row)
    native_corners = [INVERSE_AXES @ (local @ corner) for corner in bounds]
    role = obj["PaletteRole"]
    return dict(name=obj["NativeName"], primitive="Block", size=size, position=position,
                rotationMatrix=matrix, rotationDegrees=rounded(math.degrees(v) for v in rotation.to_euler("XYZ")),
                paletteRole=role, color=list(PALETTE[role]), material="Neon" if obj["ERLethal"] else ("Metal" if role=="Iron" else "SmoothPlastic"),
                lethal=bool(obj["ERLethal"]), volume=round(volume, 6), vertices=8, triangles=12), native_corners


def export_module(path, records):
    def number(value):
        return f"{value:.7f}".rstrip("0").rstrip(".") if value else "0"
    def values(numbers):
        return ",".join(number(value) for value in numbers)
    lines = ["--!strict", "-- Generated by assets/egg_rush_circuit/phase2/revision_r02/hazards/build_hazard_kit.py.",
             "local HazardKit = {}", "local V = Vector3.new", "",
             "type PartDefinition = {name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material, lethal: boolean}",
             "local templates: {[string]: {PartDefinition}} = {"]
    for key, record in records.items():
        lines.append(f"\t{key} = {{")
        for part in record["parts"]:
            lines.append(f'\t\t{{name="{part["name"]}", size=V({values(part["size"])}), frame=CFrame.new({values(part["position"]+part["rotationMatrix"])}), color=Color3.fromRGB({values(part["color"])}), material=Enum.Material.{part["material"]}, lethal={str(part["lethal"]).lower()}}},')
        lines.append("\t},")
    lines.extend(["}", "", "function HazardKit.Create(parent: Instance, key: string, frame: CFrame, scale: (number | Vector3)?): Model",
        '\tlocal definitions = assert(templates[key], "Unknown Egg Rush hazard: " .. key)',
        '\tlocal factor = if typeof(scale) == "number" then V(scale, scale, scale) elseif typeof(scale) == "Vector3" then scale else Vector3.one',
        '\tlocal model = Instance.new("Model")', '\tmodel.Name = key',
        '\tfor _, definition in definitions do', '\t\tlocal part = Instance.new("Part")',
        '\t\tpart.Name = definition.name', '\t\tpart.Size = definition.size * factor',
        '\t\tpart.CFrame = frame * CFrame.new(definition.frame.Position * factor) * definition.frame.Rotation',
        '\t\tpart.Color, part.Material = definition.color, definition.material',
        '\t\tpart.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, definition.lethal',
        '\t\tpart.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth',
        '\t\tpart:SetAttribute("ERLethal", definition.lethal)', '\t\tpart.Parent = model', '\tend',
        '\tmodel.WorldPivot = frame', '\tmodel.Parent = parent', '\treturn model', 'end', '', 'return HazardKit', ''])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def add_text(scene, name, text, location, size, mat):
    data = bpy.data.curves.new(name, "FONT")
    data.body, data.size, data.align_x = text, size, "CENTER"
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (math.radians(90), 0, 0)
    data.materials.append(mat)


def make_preview(scene, out, placements):
    backdrop = material("BoardCharcoal", (39, 45, 56))
    label = material("BoardCream", (255, 240, 202))
    floor_mesh = bpy.data.meshes.new("PreviewFloor")
    floor_mesh.from_pydata([(-16,-14,-.04),(16,-14,-.04),(16,14,-.04),(-16,14,-.04)], [], [(0,1,2,3)])
    floor = bpy.data.objects.new("PreviewFloor", floor_mesh)
    scene.collection.objects.link(floor)
    floor.data.materials.append(backdrop)
    for key, (x,y) in placements.items():
        words = {"ScorchedShell":"SCORCHED SHELL", "FeederPaddle":"FEEDER PADDLE", "HeatGrate":"HEAT GRATE", "FeatherPinch":"FEATHER PINCH"}
        add_text(scene, key+"_Label", words[key], (x,y-2.1,.15), .45, label)
    camera_data = bpy.data.cameras.new("HazardBoardCamera")
    camera = bpy.data.objects.new("HazardBoardCamera", camera_data)
    scene.collection.objects.link(camera)
    camera.location = (0,-23,22)
    camera.rotation_euler = (Vector((0,.6,.4))-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.type, camera_data.ortho_scale = "ORTHO", 21
    scene.camera = camera
    for name, position, power, size in [("BroadKey",(-8,-6,14),2000,10),("SoftFill",(10,3,9),1400,9)]:
        data = bpy.data.lights.new(name,"AREA")
        light = bpy.data.objects.new(name,data)
        scene.collection.objects.link(light)
        light.location = position
        light.rotation_euler = (-light.location).to_track_quat("-Z","Y").to_euler()
        data.energy, data.shape, data.size = power,"DISK",size
    scene.world = bpy.data.worlds.new("NeutralStudio")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.22,.25,.3,1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .45
    scene.render.engine = "CYCLES"
    scene.cycles.samples, scene.cycles.use_denoising = 16, True
    scene.render.resolution_x, scene.render.resolution_y = 1600,1000
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "Standard"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(out/"hazard_board.png")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=HERE/"candidate_h02")
    parser.add_argument("--module", type=Path, default=REPO/"src/ServerStorage/CourseBuilders/EggRush/RestartP2/HazardKit.luau")
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    started = time.perf_counter()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    assert not (out/"hazard_kit.blend").exists(), "Choose a new candidate output folder."
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = BUILD
    scene.unit_settings.system, scene.unit_settings.scale_length = "NONE",1
    materials = {role:material(role,rgb,role=="Hot",role=="Iron") for role,rgb in PALETTE.items()}
    placements = dict(zip(TEMPLATES, [(-5.1,3.8),(5.1,3.8),(-5.1,-4),(5.1,-4)]))
    records = {}
    for key, definitions in TEMPLATES.items():
        root = bpy.data.objects.new(key,None)
        root.empty_display_type, root.empty_display_size = "PLAIN_AXES",.5
        scene.collection.objects.link(root)
        root.location = (*placements[key],0)
        parts = [create_box(scene,root,spec,materials) for spec in definitions]
        bpy.context.view_layer.update()
        exported, corners = [],[]
        for part in parts:
            record, points = inspect_part(part)
            exported.append(record)
            corners.extend(points)
        low = rounded(min(v[i] for v in corners) for i in range(3))
        high = rounded(max(v[i] for v in corners) for i in range(3))
        assert all(math.isfinite(v) for v in low+high), key
        assert 5 <= len(parts) <= 10, key
        assert high[0]-low[0] <= 7.2 and high[1] <= 3.1 and high[2]-low[2] <= 3.1, (key,low,high)
        records[key] = dict(partCount=len(parts), lethalPartCount=sum(p["lethal"] for p in exported),
                            boundsRoblox=[low,high], pivot="Local base center, Y up", parts=exported)
    export_module(args.module.resolve(),records)
    manifest = dict(build=BUILD,blenderVersion=bpy.app.version_string,units="Roblox studs",axes="Roblox X,Y,Z -> Blender X,-Z,Y",
                    primitives="Native Roblox Block Parts, no mesh upload",palette=PALETTE,
                    templates=records,checks=dict(finite=True,closedManifold=True,positiveVolume=True,nondegenerateFaces=True,orthonormalFrames=True),
                    nativeProof="Not installed or playtested in Roblox Studio.")
    (out/"hazard_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    make_preview(scene,out,placements)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"hazard_kit.blend"))
    generated = time.perf_counter()
    if args.render:
        bpy.ops.render.render(write_still=True)
    completed = time.perf_counter()
    files = [out/"hazard_manifest.json",out/"hazard_kit.blend",args.module.resolve()]
    if args.render:
        files.append(out/"hazard_board.png")
    report = dict(build=BUILD,templates=len(records),parts=sum(v["partCount"] for v in records.values()),
                  lethalParts=sum(v["lethalPartCount"] for v in records.values()),
                  generationSeconds=round(generated-started,3),renderSeconds=round(completed-generated,3),
                  hashes={str(path):hashlib.sha256(path.read_bytes()).hexdigest() for path in files})
    (out/"build_report.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print("HAZARD_KIT_BUILD "+json.dumps(report))


if __name__ == "__main__":
    main()
