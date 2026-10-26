"""Build the R05 hatchery world kit in Blender; never changes Studio or uploads."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
MODULE = REPO / "src/ServerStorage/CourseBuilders/EggRush/Phase3/WorldKit.luau"
BUILD = "ER_P3_WORLD_KIT_A03"
PALETTE = {
    "Cream": "FFF0CA", "Ivory": "FFF8E7", "Coral": "E87968", "CoralShade": "C85D50",
    "Honey": "CF913D", "HoneyShade": "9B6933", "Mint": "46C2B0", "MintShade": "278F86",
    "Glass": "B2E3DC", "Ink": "354349", "Rock": "818894", "RockShade": "666F7B",
    "Green": "6BAF50", "GreenShade": "448657", "Soil": "A38A68", "Patch": "92D9C8",
}


def B(name, size, position, material="Cream", rotation=(0, 0, 0), shape="Block"):
    return dict(name=name, size=size, position=position, material=material, rotation=rotation, shape=shape)


def M(name, mesh, size, position, material="Cream", rotation=(0, 0, 0), transparency=0):
    return dict(B(name, size, position, material, rotation, "Mesh"), mesh=mesh, transparency=transparency)


def room(width, height, depth, roof="Coral", window=True):
    """A complete room shell with a real recessed doorway and deep side windows."""
    front, back = -depth / 2 + 1, depth / 2 - 1
    opening, spring = width * .25, height * .46
    outer = opening + 2
    wall_top = spring + outer / 2
    parts = [B("FloorUnderside", (width - 1, 2, depth - 1), (0, 1.1, 0), "HoneyShade"),
             B("RearWall", (width, height - 3, 2), (0, (height - 3) / 2, back)),
             B("FrontLeftWall", ((width - outer) / 2, wall_top, 2), (-(width + outer) / 4, wall_top / 2, front)),
             B("FrontRightWall", ((width - outer) / 2, wall_top, 2), ((width + outer) / 4, wall_top / 2, front)),
             B("FrontLintel", (width, height - wall_top - 3, 2), (0, (height - 3 + wall_top) / 2, front)),
             B("Ceiling", (width - 1, 1.5, depth - 1), (0, height - 3.85, 0), "Ivory"),
             B("RoofDeck", (width + 2, 2.5, depth + 2), (0, height - 1.25, 0), roof),
             B("Cornice", (width + 1, 1.1, depth + 1), (0, height - 3.05, 0), "Ivory"),
             B("DoorRecessBack", (opening - .5, spring + opening / 2, .4), (0, (spring + opening / 2) / 2 + 1, back - 1.3), "Ink"),
             M("DoorArch", "ArchBand", (outer, outer / 2, 2.5), (0, spring + outer / 4, front - .25), roof),
             M("DoorSpandrels", "ArchSpandrels", (outer, outer / 2, 2), (0, spring + outer / 4, front), "Cream")]
    for side in (-1, 1):
        parts.append(B(f"DoorJamb{side}", (1, spring, 2.5), (side * (opening / 2 + .5), spring / 2, front - .25), roof))
        if window:
            x = side * (width / 2 - 1)
            # Separate surround volumes leave a deep window recess in the side wall.
            for z in (-depth * .32, depth * .32):
                parts.append(B(f"SidePier{side}_{z}", (2, height - 4, depth * .36 - 2), (x, (height - 4) / 2, z - math.copysign(1, z))))
            parts.extend([B(f"WindowSill{side}", (2.5, height * .30, depth * .28), (x, height * .15, 0)),
                          B(f"WindowHead{side}", (2, height * .37 - 3, depth * .28), (x, (height * 1.63 - 3) / 2, 0)),
                          B(f"RecessedWindow{side}", (.4, height * .34, depth * .27), (x - side * .8, height * .46, 0), "Glass")])
        else:
            parts.append(B(f"SideWall{side}", (2, height - 3, depth - 2), (side * (width / 2 - 1), (height - 3) / 2, 0)))
    return parts


def make_templates():
    templates = {}
    def add(name, size, parts, role):
        templates[name] = dict(size=size, role=role, parts=parts)
    add("WorkshopBay", (28, 28, 22), room(26, 28, 20), "UnreachableArchitecture")
    add("HallBay", (36, 48, 28), room(34, 48, 26, "MintShade"), "Landmark")
    add("NurseryPavilion", (30, 26, 30), room(28, 26, 28, "Coral"), "UnreachableArchitecture")
    p = [M("ArcCrown", "ArchBand", (28, 14, 6), (0, 21, -1.5), "Coral"),
         B("RoofBack", (28, 2, 10), (0, 27, 0), "Coral"),
         B("LintelBack", (28, 5, 2), (0, 23.5, 4), "Cream")]
    for s in (-1, 1):
        p.extend([B(f"Pier{s}", (5, 14, 8), (s * 11.5, 9, 0)),
                  B(f"Foot{s}", (7, 2, 10), (s * 10.5, 1, 0), "Honey"),
                  B(f"ArchJamb{s}", (3.1, 12, 6), (s * 12.2, 8, -1.5), "Coral")])
    add("WorkshopArch", (28, 28, 10), p, "UnreachableArchitecture")
    add("HallCrown", (36, 12, 28), [M("Vault", "VaultRoof", (36, 10, 28), (0, 6, 0), "Mint"),
        B("VaultBase", (36, 2, 28), (0, 1, 0), "Ivory"),
        B("Ridge", (5, 2.5, 26), (0, 10.25, 0), "Honey"),
        B("RidgeCap", (9, 1.2, 6), (0, 11.4, 0), "Coral")], "Landmark")
    p = [B("Beam", (22, 3, 8), (0, 26.5, 0), "Honey"), B("BackBeam", (20, 2, 2), (0, 22, 3), "HoneyShade")]
    for s in (-1, 1):
        p.extend([B(f"Column{s}", (3, 22, 6), (s * 9.5, 14, 0), "Honey"),
                  B(f"StoneFoot{s}", (5, 3, 8), (s * 8.5, 1.5, 0), "Cream"),
                  B(f"Brace{s}", (2.5, 8, 5), (s * 7.5, 22, 0), "HoneyShade", (0, 0, -s * 38))])
    add("HoneyFrame", (22, 28, 8), p, "UnreachableArchitecture")
    p = [B("MachineBase", (22, 3, 22), (0, 1.5, 0)),
         M("LowerCollar", "TankDrum", (20, 3, 20), (0, 4.5, 0), "MintShade"),
         M("TankGlass", "TankDrum", (18, 17, 18), (0, 14.5, 0), "Glass", transparency=.68),
         M("UpperCollar", "TankDrum", (20, 2, 20), (0, 23, 0), "Mint"),
         M("Dome", "TankDome", (21, 5, 21), (0, 26.5, 0), "Mint"),
         B("CrownControl", (5, 2, 5), (0, 29, 0), "Coral")]
    for s in (-1, 1):
        p.append(B(f"TankPost{s}", (1.2, 19, 1.5), (s * 8, 13.5, 4.5), "Honey"))
    for i, (w, h, y) in enumerate([(8, 3, 7.5), (10, 6, 12), (8, 3, 16.5), (5, 2, 19), (3, 1, 20.5)]):
        p.append(B(f"BlockEgg{i}", (w, h, w), (0, y, 0), "Ivory"))
    p.extend([B("EggPatchMint", (3, 3, .3), (-2, 12, -5.1), "Patch"),
              B("EggPatchCoral", (2, 2, .3), (2, 15.5, -4.1), "Coral")])
    add("IncubatorTank", (22, 30, 22), p, "Landmark")
    add("TerraceBase", (40, 14, 40), [M("Bedrock", "RockLobe", (40, 12, 40), (0, 6, 0), "RockShade"),
        M("TerraceRock", "RockLobe", (35, 7, 35), (-1, 9.5, -1), "Rock"),
        M("DistantTurf", "RockLobe", (33, 1.4, 33), (-1, 13.3, -1), "GreenShade")], "BelowCourseFoundation")
    add("TerraceCorner", (40, 14, 40), [M("LowerShelf", "RockLobe", (40, 8, 40), (0, 4, 0), "RockShade"),
        M("HighShelf", "RockLobe", (25, 10, 26), (-6, 8, 5), "Rock"),
        M("DistantTurf", "RockLobe", (23, 1, 24), (-6, 13.5, 5), "GreenShade")], "DistantLandscape")
    add("RookeryPlinth", (72, 26, 60), [M("RookeryBedrock", "RockLobe", (72, 16, 60), (0, 8, 0), "RockShade"),
        M("UpperRoost", "RockLobe", (60, 12, 48), (-3, 18, 0), "Rock"),
        M("RoostSoil", "RockLobe", (56, 1.5, 44), (-3, 24.65, 0), "Soil"),
        B("RoostFrontRim", (51, 2, 3), (-3, 25, -18), "Honey"),
        B("RoostBackRim", (51, 2, 3), (-3, 25, 18), "Honey"),
        B("RoostLeftRim", (3, 2, 33), (-27, 25, 0), "Honey"),
        B("RoostRightRim", (3, 2, 33), (21, 25, 0), "Honey")], "BelowCourseFoundation")
    p = [B("ServiceRoof", (44, 3, 32), (0, 16.5, 0), "Cream"),
         B("RoofLip", (44, 1.25, 3), (0, 14.375, -14.5), "Coral"),
         B("BackCrossBeam", (40, 3, 3), (0, 12, 13), "Honey"),
         B("ServiceMachineBack", (24, 8, 3), (0, 4, 13), "MintShade")]
    for x in (-19, 19):
        for z in (-12, 12):
            p.append(B(f"CanopyPost{x}_{z}", (3, 15, 3), (x, 7.5, z), "Honey"))
    add("ServiceCanopy", (44, 18, 32), p, "UnreachableArchitecture")
    p = [B("SorterBase", (28, 3, 22), (0, 1.5, 0), "HoneyShade"),
         M("SorterHousing", "TankDrum", (20, 16, 20), (0, 11, 0), "MintShade"),
         M("SorterLid", "TankDome", (22, 3, 22), (0, 20.5, 0), "Mint"),
         B("DeliveryMouth", (12, 6, 8), (0, 7, -7), "Ink"),
         B("DeliveryHeader", (16, 2, 8), (0, 11, -7), "Cream"),
         B("DriveBox", (6, 10, 9), (10, 8, 1), "Honey"),
         B("DriveLid", (7, 2, 10), (10, 14, 1), "Cream")]
    for s in (-1, 1):
        p.append(B(f"MouthJamb{s}", (2, 7, 8), (s * 7, 6.5, -7), "Cream"))
    add("SortingDrum", (28, 22, 22), p, "UnreachableArchitecture")
    p = [M("MintReturnArch", "ArchBand", (36, 18, 12), (0, 23, 0), "Mint"),
         M("CreamReturnArch", "ArchBand", (30, 15, 1.5), (0, 21.5, -6.2), "Ivory"),
         B("ArchRearBack", (32, 21, 2), (0, 13.5, 6), "MintShade")]
    for s in (-1, 1):
        p.extend([B(f"ReturnPier{s}", (6, 11, 12), (s * 15, 8.5, 0), "Mint"),
                  B(f"ReturnFoot{s}", (8, 3, 14), (s * 14, 1.5, 0), "Honey"),
                  B(f"InnerJamb{s}", (2, 11, 1.5), (s * 12.9, 8.5, -6.2), "Ivory")])
    add("ShellReturnArch", (36, 32, 14), p, "UnreachableArchitecture")
    p = [M("PlantingBank", "RockLobe", (32, 3, 28), (0, 1.5, 0), "Soil")]
    for i, (x, z, w, h, d) in enumerate([(-8, 2, 14, 10, 16), (3, 3, 17, 12, 18), (10, -5, 11, 8, 13)]):
        p.append(M(f"BroadCrown{i}", "LeafCrown", (w, h, d), (x, 2 + h / 2, z), "GreenShade" if i == 0 else "Green"))
    add("GardenCluster", (32, 14, 28), p, "DistantLandscape")
    add("ShellRoof", (32, 14, 28), [M("MintBarrelRoof", "VaultRoof", (32, 12, 28), (0, 8, 0), "Mint"),
        B("RoofUndertray", (32, 2, 28), (0, 1, 0), "Cream"),
        B("RidgeCoping", (4, 2, 26), (0, 13, 0), "Honey")], "UnreachableArchitecture")
    return templates


TEMPLATES = make_templates()
MESH_SIZES = {"ArchBand": (16, 8, 3), "ArchSpandrels": (16, 8, 2), "VaultRoof": (32, 12, 28),
              "TankDome": (21, 5, 21), "TankDrum": (18, 17, 18),
              "RockLobe": (40, 14, 40), "PipeElbow": (12, 12, 5), "LeafCrown": (17, 12, 18)}


def mesh_geometry(key):
    verts, faces = [], []
    if key == "ArchBand":
        n, inner = 16, .76
        for z in (-.5, .5):
            for r in (1, inner):
                verts += [(r * math.cos(i * math.pi / n), r * math.sin(i * math.pi / n), z) for i in range(n + 1)]
        q = n + 1
        for i in range(n):
            faces += [(i, i + 1, q + i + 1, q + i),
                      (2*q + i, 3*q + i, 3*q + i + 1, 2*q + i + 1),
                      (i, 2*q + i, 2*q + i + 1, i + 1),
                      (q + i, q + i + 1, 3*q + i + 1, 3*q + i)]
        faces += [(0, q, 3*q, 2*q), (n, 2*q + n, 3*q + n, q + n)]
    elif key == "ArchSpandrels":
        for side in (-1, 1):
            poly = [(side * math.cos(i * math.pi / 2 / 8), math.sin(i * math.pi / 2 / 8)) for i in range(9)]
            poly.append((side, 1))
            offset, q = len(verts), len(poly)
            verts += [(x, y, z) for z in (-.5, .5) for x, y in poly]
            faces += [tuple(offset + i for i in reversed(range(q))), tuple(offset + q + i for i in range(q))]
            faces += [(offset+i, offset+(i+1)%q, offset+(i+1)%q+q, offset+i+q) for i in range(q)]
    elif key == "VaultRoof":
        n = 16
        polygon = [(math.cos(math.pi * i / n), math.sin(math.pi * i / n)) for i in range(n + 1)]
        polygon += [(0, 0)]
        q = len(polygon)
        verts = [(x, y, z) for z in (-.5, .5) for x, y in polygon]
        faces = [tuple(reversed(range(q))), tuple(range(q, 2*q))]
        faces += [(i, (i + 1) % q, (i + 1) % q + q, i + q) for i in range(q)]
    elif key in ("TankDome", "TankDrum", "LeafCrown", "RockLobe"):
        n = 16 if key in ("TankDome", "TankDrum") else 10
        if key == "TankDome":
            rings = [(1, 0), (.98, .24), (.88, .55), (.66, .82), (.32, .98)]
        elif key == "TankDrum":
            rings = [(1, 0), (1, 1)]
        elif key == "LeafCrown":
            rings = [(.65, 0), (1, .25), (.95, .63), (.67, 1)]
        else:
            rings = [(1, 0), (.96, .38), (.80, 1)]
        for radius, y in rings:
            for i in range(n):
                a = 2 * math.pi * i / n
                factor = (1 + .075 * math.sin(i * 2.2) + .035 * math.cos(i * 4.4)) if key == "RockLobe" else 1
                verts.append((radius * math.cos(a) * factor, y, radius * math.sin(a) * factor))
        faces = [tuple(reversed(range(n)))]
        for r in range(len(rings) - 1):
            faces += [(r*n+i, r*n+(i+1)%n, (r+1)*n+(i+1)%n, (r+1)*n+i) for i in range(n)]
        faces.append(tuple((len(rings) - 1)*n+i for i in range(n)))
    elif key == "PipeElbow":
        rings, sides = 12, 12
        for i in range(rings + 1):
            a = i * math.pi / 2 / rings
            for j in range(sides):
                b = j * 2 * math.pi / sides
                radius = 1 + .23 * math.cos(b)
                verts.append((radius * math.cos(a), radius * math.sin(a), .23 * math.sin(b)))
        faces = [tuple(reversed(range(sides))), tuple(rings*sides+j for j in range(sides))]
        for i in range(rings):
            faces += [(i*sides+j, i*sides+(j+1)%sides, (i+1)*sides+(j+1)%sides, (i+1)*sides+j) for j in range(sides)]
    low = [min(p[i] for p in verts) for i in range(3)]
    high = [max(p[i] for p in verts) for i in range(3)]
    return [tuple((p[i] - (low[i] + high[i]) / 2) / (high[i] - low[i]) for i in range(3)) for p in verts], faces


def lua(v):
    if isinstance(v, str): return json.dumps(v)
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (float, int)): return str(round(v, 6))
    if isinstance(v, (list, tuple)): return "{" + ",".join(lua(x) for x in v) + "}"
    return "{" + ",".join("[" + lua(k) + "]=" + lua(value) for k, value in v.items()) + "}"


def write_module():
    content = '''--!nonstrict
-- Generated from the saved Blender world-kit recipe. Pivots are bottom centers, front is -Z.
local WorldKit = {}
WorldKit.Build = "__BUILD__"
local palette = __PALETTE__
local templates = __TEMPLATES__
WorldKit.Templates = templates
local meshLibrary = nil
-- Roblox imports this package's mesh geometry rotated Y180 relative to the source.
local importMeshCorrection = CFrame.Angles(0, math.pi, 0)

function WorldKit.setMeshLibrary(folder)
    meshLibrary = folder
end

function WorldKit.getSize(archetype)
    local row = assert(templates[archetype], "Unknown world kit: " .. tostring(archetype))
    return Vector3.new(table.unpack(row.size))
end

function WorldKit.build(parent, archetype, frame, scale, options)
    local row = assert(templates[archetype], "Unknown world kit: " .. tostring(archetype))
    scale = scale or Vector3.one
    options = options or {}
    local model = Instance.new("Model")
    model.Name = options.Name or archetype
    model:SetAttribute("ERPhase3Archetype", archetype)
    model:SetAttribute("ERPhase3Build", WorldKit.Build)
    model:SetAttribute("ERWorldRole", options.Role or row.role)
    model.WorldPivot = frame
    for _, definition in ipairs(row.parts) do
        local part
        if definition.shape == "Mesh" then
            local source = meshLibrary and meshLibrary:FindFirstChild("ERW_" .. definition.mesh, true)
            assert(source and source:IsA("MeshPart"), "World kit mesh missing: ERW_" .. definition.mesh)
            part = source:Clone()
            part:ClearAllChildren()
        else
            part = Instance.new(definition.shape == "Wedge" and "WedgePart" or "Part")
        end
        part.Name = definition.name
        local size = Vector3.new(table.unpack(definition.size)) * scale
        part.Size = size
        local p = Vector3.new(table.unpack(definition.position)) * scale
        local r = definition.rotation
        part.CFrame = frame * CFrame.new(p) * CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
        if definition.shape == "Mesh" then
            part.CFrame = part.CFrame * importMeshCorrection
        end
        local hex = palette[definition.material]
        part.Color = Color3.fromHex(hex)
        if options.WallTint and definition.material == "Cream" then
            part.Color = options.WallTint
        end
        if options.Accent and (definition.material == "Mint" or definition.material == "MintShade" or definition.material == "Coral" or definition.material == "CoralShade") then
            local shaded = definition.material == "MintShade" or definition.material == "CoralShade"
            part.Color = shaded and options.Accent:Lerp(Color3.new(0, 0, 0), 0.22) or options.Accent
        end
        part.Material = definition.material == "Glass" and Enum.Material.Glass or Enum.Material.SmoothPlastic
        part.Transparency = definition.transparency or 0
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = definition.material ~= "Glass"
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part:SetAttribute("ERWorldRole", options.Role or row.role)
        part:SetAttribute("ERMaterialRole", definition.material)
        part.Parent = model
    end
    model.Parent = parent
    return model
end

return WorldKit
'''.replace("__BUILD__", BUILD).replace("__PALETTE__", lua(PALETTE)).replace("__TEMPLATES__", lua(TEMPLATES))
    MODULE.parent.mkdir(parents=True, exist_ok=True)
    MODULE.write_text(content, encoding="utf8")


def run_blender(args):
    import bpy
    import bmesh
    from mathutils import Matrix, Vector, Euler
    AXES = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
    inverse = AXES.inverted()
    started = time.perf_counter()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    if (out / "manifest.json").exists():
        raise RuntimeError("Choose a fresh output folder; completed asset candidates are preserved.")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = BUILD
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 2
    mats = {}
    for key, hex_color in PALETTE.items():
        srgb = [int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4)]
        rgb = [c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in srgb]
        mat = bpy.data.materials.new("ERW_" + key)
        mat.diffuse_color = (*rgb, 1)
        mat.use_nodes = True
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1)
        mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .8
        mats[key] = mat

    def mesh_object(name, verts, faces, material):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        mesh.update()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(obj)
        obj.data.materials.append(mats[material])
        return obj

    library, checks = {}, {}
    for key, size in MESH_SIZES.items():
        verts, faces = mesh_geometry(key)
        obj = mesh_object("ERW_" + key, [AXES @ (Vector(p) * Vector(size)) for p in verts], faces, "Mint" if key in ("TankDome", "PipeElbow") else "Cream")
        obj["ERMeshTemplate"] = key
        obj["NativeSize"] = list(size)
        library[key] = obj
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        assert all(e.is_manifold for e in bm.edges), key
        volume = bm.calc_volume(signed=True)
        assert volume > 0, (key, volume)
        assert all(math.isfinite(c) for v in bm.verts for c in v.co), key
        triangles = sum(len(f.verts) - 2 for f in bm.faces)
        assert triangles <= 600, (key, triangles)
        checks[key] = dict(vertices=len(bm.verts), triangles=triangles, positiveVolume=round(volume, 5),
                           closedManifold=True, outwardFaces=True, size=size,
                           materialSlots=len(obj.data.materials), pivot="center")
        bm.free()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in library.values(): obj.select_set(True)
    bpy.ops.export_scene.fbx(filepath=str(out / "ER_WorldMeshLibrary.fbx"), use_selection=True,
                            object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True,
                            apply_scale_options="FBX_SCALE_UNITS", bake_space_transform=False,
                            use_mesh_modifiers=True, add_leaf_bones=False, bake_anim=False)
    for obj in library.values(): obj.hide_render = True; obj.hide_set(True)

    def create(definition, root):
        size = Vector(definition["size"])
        if definition["shape"] == "Mesh":
            verts, faces = mesh_geometry(definition["mesh"])
        else:
            verts = [(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),
                     (-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)]
            faces = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)]
        obj = mesh_object(root.name + "__" + definition["name"], [AXES @ (Vector(p) * size) for p in verts], faces, definition["material"])
        obj.parent = root
        obj.location = AXES @ Vector(definition["position"])
        rotation = Euler(tuple(math.radians(a) for a in definition["rotation"]), "XYZ").to_matrix()
        obj.rotation_euler = (AXES @ rotation @ inverse).to_euler()
        obj["ERDefinition"] = json.dumps(definition, sort_keys=True)
        obj["ERRole"] = TEMPLATES[root.name]["role"]
        if definition.get("transparency"):
            glass = obj.data.materials[0].copy()
            glass.name = "ERW_TransparentTankGlass"
            glass.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 1 - definition["transparency"]
            glass.surface_render_method = "DITHERED"
            obj.data.materials.clear()
            obj.data.materials.append(glass)
        return obj

    roots = {}
    for key, row in TEMPLATES.items():
        root = bpy.data.objects.new(key, None)
        scene.collection.objects.link(root)
        roots[key] = root
        root["ERArchetype"] = key
        for definition in row["parts"]: create(definition, root)
    write_module()
    manifest = dict(build=BUILD, blender=bpy.app.version_string, palette=PALETTE, templates=TEMPLATES,
                    meshLibrary=checks, meshPackage="ER_WorldMeshLibrary.fbx",
                    meshObjectNames=["ERW_" + key for key in library],
                    axes="Roblox X,Y,Z = Blender X,Z,-Y; FBX forward -Z up Y; one Blender unit per stud",
                    importContract="Use exact named MeshPart templates; ignore package placement. Imported mesh local orientation must be checked against source before repetition.",
                    collision="All world art is noncolliding decoration. Intentional native gameplay contacts are separately authored and unchanged.",
                    inputs=["ER_P3_A05", "ER_P3_B02", "ER_P3_C02", "ER_P3_D02", "ER_P3_E03", "ER_P2_R05_C01/Chicken_R05_A02"],
                    representative=["WorkshopBay", "TerraceBase"],
                    partCount=sum(len(row["parts"]) for row in TEMPLATES.values()),
                    sourceSHA256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                    moduleSHA256=hashlib.sha256(MODULE.read_bytes()).hexdigest(),
                    proofBoundary="Source geometry and saved readback only; native import appearance, clearance, play and performance are separate checks.")
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf8")

    # Save source units at their true pivots before arranging preview instances.
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "world_kit.blend"))
    verify_saved(out, manifest, bpy, bmesh)
    scene = bpy.context.scene
    roots = {key: bpy.data.objects[key] for key in TEMPLATES}
    if not args.skip_render:
        for i, (key, root) in enumerate(roots.items()):
            root.location = AXES @ Vector(((i % 5) * 64, 0, (i // 5) * 74))
        scene.render.engine = "BLENDER_EEVEE"
        scene.render.resolution_x, scene.render.resolution_y = 1600, 1100
        scene.render.resolution_percentage = 100
        scene.render.image_settings.file_format = "PNG"
        scene.view_settings.view_transform = "AgX"
        scene.world = bpy.data.worlds.new("WarmStudio")
        scene.world.use_nodes = True
        scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.50, .58, .66, 1)
        scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .8
        def look(obj, target): obj.rotation_euler = (AXES @ Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
        for label, pos, energy in [("Key", (30, 180, -100), 1400000), ("Fill", (230, 140, 200), 900000)]:
            data = bpy.data.lights.new(label, "AREA")
            data.energy, data.shape, data.size = energy, "DISK", 240
            obj = bpy.data.objects.new(label, data)
            scene.collection.objects.link(obj)
            obj.location = AXES @ Vector(pos)
            look(obj, (128, 10, 74))
        data = bpy.data.cameras.new("SourcePreview")
        data.type, data.ortho_scale = "ORTHO", 350
        camera = bpy.data.objects.new("SourcePreview", data)
        scene.collection.objects.link(camera)
        scene.camera = camera
        for label, pos in [("front_oblique", (400, 250, -310)), ("rear_oblique", (-140, 240, 340)), ("underside", (400, -110, -260))]:
            camera.location = AXES @ Vector(pos)
            look(camera, (128, 15, 74))
            scene.render.filepath = str(out / ("source_" + label + ".png"))
            bpy.ops.render.render(write_still=True)
    report = dict(build=BUILD, archetypes=len(TEMPLATES), nativeAndMeshPieces=manifest["partCount"],
                  meshTemplates=len(library), triangles=sum(row["triangles"] for row in checks.values()),
                  seconds=round(time.perf_counter()-started, 3),
                  hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir() if p.suffix in (".fbx", ".blend", ".png", ".json")})
    (out / "build_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
    print("WORLD_KIT_BUILD " + json.dumps(report), flush=True)


def verify_saved(out, manifest, bpy, bmesh):
    from mathutils import Matrix, Vector, Euler
    axes = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
    inverse = axes.inverted()
    bpy.ops.wm.open_mainfile(filepath=str(out / "world_kit.blend"))
    checked, volume = 0, 0
    for key, row in manifest["templates"].items():
        root = bpy.data.objects[key]
        assert len(root.children) == len(row["parts"]), key
        expected = {definition["name"]: definition for definition in row["parts"]}
        for obj in root.children:
            definition = json.loads(obj["ERDefinition"])
            assert definition == json.loads(json.dumps(expected[definition["name"]])), obj.name
            native_position = inverse @ obj.location
            assert max(abs(native_position[i] - definition["position"][i]) for i in range(3)) < .0001, obj.name
            corners = [inverse @ vertex.co for vertex in obj.data.vertices]
            size = [max(p[i] for p in corners) - min(p[i] for p in corners) for i in range(3)]
            assert max(abs(size[i] - definition["size"][i]) for i in range(3)) < .0002, (obj.name, size)
            expected_rotation = axes @ Euler(tuple(math.radians(a) for a in definition["rotation"]), "XYZ").to_matrix() @ inverse
            assert max(abs(expected_rotation[i][j] - obj.rotation_euler.to_matrix()[i][j]) for i in range(3) for j in range(3)) < .0001, obj.name
            bm = bmesh.new()
            bm.from_mesh(obj.data)
            assert all(e.is_manifold for e in bm.edges), obj.name
            assert bm.calc_volume(signed=True) > 0, obj.name
            assert all(f.calc_area() > 1e-8 for f in bm.faces), obj.name
            volume += bm.calc_volume(signed=True)
            bm.free()
            checked += 1
    report = dict(build=BUILD, savedReadback=True, exactRecipeParity=True, checkedPieces=checked,
                  closedManifold=True, positiveVolume=True, nondegenerateFaces=True, actualDimensionsAndFrames=True,
                  totalSourceVolume=round(volume, 4), bottomCenteredArchetypePivots=True,
                  meshTemplateNames=manifest["meshObjectNames"])
    (out / "saved_blend_check.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
    print("WORLD_KIT_SAVED_CHECK " + json.dumps(report), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=HERE / "candidate_a03")
    parser.add_argument("--skip-render", action="store_true")
    parser.add_argument("--source-only", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
    if args.source_only:
        write_module()
        print("WorldKit source generated; Blender build and saved readback remain required.")
    else:
        run_blender(args)


if __name__ == "__main__": main()
