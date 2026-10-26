"""New-only Moonlit rework art. Lead runs this in an isolated background Blender.

No live scene, accepted .blend, material upload, or native place is changed.
The accepted BL02 geometry helpers and verified P3 exporter are reused.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import types

import bpy


ROOT = Path(__file__).resolve().parents[5]
BUILD = "MC_P3_REWORK_KIT_RW01"
PALETTE = {"Arrow": (246, 228, 158), "Mount": (27, 37, 57),
           "Rock": (64, 79, 108), "Leaf": (54, 78, 63), "Flower": (141, 132, 182)}


def load_module(path, name):
    result = types.ModuleType(name)
    result.__file__ = str(path)
    exec(compile(path.read_text(encoding="utf-8"), str(path), "exec"), result.__dict__)
    return result


def horizontal_prism(g, outline, low, high, color):
    count = len(outline)
    vertices = [(x, y, z) for z in (low, high) for x, y in outline]
    faces = [tuple(reversed(range(count))), tuple(count + i for i in range(count))]
    faces.extend((i, (i + 1) % count, (i + 1) % count + count, i + count)
                 for i in range(count))
    g.add(vertices, faces, color)


def arrow(architecture):
    g = architecture._Mesh()
    # Positive Blender Y is Roblox -Z, which is CFrame.LookVector.
    horizontal_prism(g, [(-.48, -2.4), (.48, -2.4), (.48, .2),
                         (1.6, .2), (0, 2.4), (-1.6, .2), (-.48, .2)], 0, .10, "Arrow")
    return g, "One closed, connected extruded arrow, 3.2x4.8 studs, forward Roblox -Z."


def arrow_mount(architecture):
    g = architecture._Mesh()
    horizontal_prism(g, [(-1.85, -2.7), (1.85, -2.7), (2.1, -2.45), (2.1, 2.45),
                         (1.85, 2.7), (-1.85, 2.7), (-2.1, 2.45), (-2.1, -2.45)], 0, .12, "Mount")
    return g, "Physical dark mounting plate; top .12, arrow base must be .17; no coplanar faces."


def foundation(architecture, exporter):
    g = architecture._Mesh()
    rings = ((0, 7.6, 7.8), (1, 7.6, 7.8), (1.8, 6.8, 7.0), (2.1, 5.2, 5.8),
             (26.1, 5.2, 5.8), (26.7, 6.1, 6.6), (27, 6.1, 6.6),
             (27.4, 7.4, 7.6), (28, 7.4, 7.6))
    vertices = [(x * width / 2, y * depth / 2, height)
                for height, width, depth in rings for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    faces = [(3, 2, 1, 0), tuple(range(len(vertices) - 4, len(vertices)))]
    for ring in range(len(rings) - 1):
        for side in range(4):
            a, b = ring * 4 + side, ring * 4 + (side + 1) % 4
            faces.append((a, b, b + 4, a + 4))
    g.add(vertices, faces, "Stone")
    for yaw in (0, math.pi / 2, math.pi, -math.pi / 2):
        detail = architecture._Mesh()
        outline = architecture._pointed(3.6, 18.8, 4.0, 8)
        detail.prism(outline, -2.935, -2.905, "StoneDark")
        exporter.arch_band(detail, architecture, 3.85, 19.2, 3.6, 18.8,
                           -3.07, -2.955, "StoneLight", base=3.8, inner_base=4, samples=8)
        g.transformed(detail, yaw)
    return g, "Ground-origin 7.6x28x7.8 carved four-face foundation pier; scale to pad underside; never project above it."


def rocks(architecture):
    g = architecture._Mesh()
    for x, y, height, radius, angle in ((-2.2, .3, 2.8, 2.5, .2), (1.4, 1.1, 2.0, 2.2, .8), (2.9, -.8, 1.3, 1.3, .4)):
        body = architecture._Mesh()
        body.profile([(0, radius * .75), (height * .28, radius), (height * .72, radius * .78),
                      (height, radius * .28)], sides=7, color="Rock")
        g.transformed(body, angle, (x, y, 0))
    return g, "Three faceted rocks in one material mesh; outer base only; no walkable contact."


def ground_plinth(architecture):
    g = architecture._Mesh()
    outline = [(-12, -12), (12, -12), (16, -8), (16, 8), (12, 12), (-12, 12), (-16, 8), (-16, -8)]
    horizontal_prism(g, outline, -3.2, .12, "Rock")
    return g, "Low octagonal foundation/terrain plinth; 32x24, top+.12; noncolliding 30 studs beneath first route."


def plants(architecture):
    g = architecture._Mesh()
    for stem in range(8):
        angle = stem * math.tau / 8 + .17
        body = architecture._Mesh()
        body.prism([(-.12, 0), (.15, 0), (.56, .7), (.94, 1.5), (.71, 1.7), (.16, .85)],
                   -.05, .05, "Leaf")
        for level in range(3):
            z = .25 + .30 * level
            for side in (-1, 1):
                body.prism([(side * .1, z), (side * .62, z + .10), (side * .34, z + .36)],
                           -.065, -.015, "Leaf")
        g.transformed(body, angle, (math.cos(angle) * .4, math.sin(angle) * .4, 0))
    for flower in range(3):
        x, y, z = ((-.5, -.7, 1.2), (.8, .45, 1.5), (.1, .6, .85))[flower]
        for petal in range(5):
            a = petal * math.tau / 5
            body = architecture._Mesh()
            body.profile([(0, .06), (.14, .17), (.26, .08)], sides=5, color="Flower")
            g.transformed(body, a, (x + math.cos(a) * .15, y + math.sin(a) * .15, z))
    return g, "Opaque low fern and three restrained lavender flowers; two material meshes; no alpha cards."


def main():
    assert bpy.app.background, "Use isolated background Blender; live editor is lead-controlled."
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    output = args.output.resolve()
    assert output.is_relative_to(ROOT), "Output must stay inside this project."
    assert not output.exists() or not any(output.iterdir()), "Use a fresh output directory."
    source = ROOT / "assets/moonlit_citadel/bl02/architecture.py"
    exporter_path = ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py"
    hashes = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in (source, exporter_path)}
    architecture = load_module(source, "moonlit_rework_accepted_helpers")
    exporter = load_module(exporter_path, "moonlit_rework_verified_exporter")
    exporter.BUILD = BUILD
    exporter.MAX_LIBRARY_TRIANGLES = 6000
    exporter.MAX_ASSET_TRIANGLES = 2500
    exporter.MAX_EXPORT_PARTS = 9
    root = bpy.data.collections.new(BUILD)
    bpy.context.scene.collection.children.link(root)
    authored = exporter.new_collection(BUILD + "_Authored", root)
    exported = exporter.new_collection(BUILD + "_Export", root)
    palette = architecture._materials()
    for key, rgb in PALETTE.items():
        mat = bpy.data.materials.new("MC_P3_" + key)
        mat.use_nodes = True
        rgba = tuple(architecture._linear(c) for c in rgb) + (1.0,)
        mat.diffuse_color = rgba
        shader = mat.node_tree.nodes.get("Principled BSDF")
        shader.inputs["Base Color"].default_value = rgba
        shader.inputs["Roughness"].default_value = .8
        mat["PaletteRGB"] = list(rgb)
        palette[key] = mat
    recipes = (("SolidArrow", lambda: arrow(architecture)),
               ("ArrowMount", lambda: arrow_mount(architecture)),
               ("FoundationPier", lambda: foundation(architecture, exporter)),
               ("GroundPlinth", lambda: ground_plinth(architecture)),
               ("RockCluster", lambda: rocks(architecture)),
               ("FernCluster", lambda: plants(architecture)))
    objects, occupied = [], {}
    for suffix, recipe in recipes:
        key = "MC_P3_Rework_" + suffix
        assert bpy.data.objects.get(key) is None, "Existing kit must be preserved."
        geometry, notes = recipe()
        obj = architecture._object(authored, key, geometry, palette, 0, notes)
        obj["Build"], obj["Role"] = BUILD, "Noncolliding decoration"
        objects.append(obj)
        occupied[key] = []
    bpy.context.view_layer.update()
    assets, parts = exporter.export_units(objects, exported, occupied)
    # The marker must stay one connected geometry island and one material mesh.
    solid = next(asset for asset in assets if asset["asset"].endswith("_SolidArrow"))
    assert solid["geometry"]["closed_islands"] == 1
    assert sum(part["asset"].endswith("_SolidArrow") for part in parts) == 1
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in exported.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(output / "MC_P3_REWORK_KIT.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             use_mesh_modifiers=True, bake_anim=False, add_leaf_bones=False)
    exported.hide_viewport, exported.hide_render = True, True
    manifest = {"candidate": BUILD, "units": "1 Blender unit = 1 intended stud",
                "axes": "Roblox center=(X,Z,-Y); arrow forward=Roblox -Z",
                "assets": assets, "export_parts": parts, "source_hashes": hashes,
                "part_count": len(parts), "export_triangles": sum(p["triangles"] for p in parts),
                "boundary": "New-only static art. No imports, uploads, native changes, or collision.",
                "preview_boundary": "Library geometry checks only; not installed-map or runtime proof."}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "MC_P3_REWORK_KIT.blend"))
    for path, digest in hashes.items():
        assert hashlib.sha256(Path(path).read_bytes()).hexdigest() == digest
    receipt = {name: {"bytes": (output / name).stat().st_size,
                      "sha256": hashlib.sha256((output / name).read_bytes()).hexdigest()}
               for name in ("MC_P3_REWORK_KIT.fbx", "MC_P3_REWORK_KIT.blend", "manifest.json")}
    (output / "build_receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(output), "parts": len(parts), "triangles": manifest["export_triangles"]}), flush=True)


if __name__ == "__main__":
    main()
