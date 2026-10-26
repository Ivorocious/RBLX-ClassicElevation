"""Closed ER01 replacements; execute only in the lead's isolated Blender process."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import types

import bpy

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "default.project.json").exists())
BUILD = "MC_P3_ENCLOSURE_REPAIR_ER01"


def load(path, name):
    module = types.ModuleType(name)
    module.__file__ = str(path)
    exec(compile(path.read_text(encoding="utf-8"), str(path), "exec"), module.__dict__)
    return module


def foundation(a, e):
    g = a._Mesh()
    # Covered caps sit inside the closed trim, rather than on its exterior plane.
    g.box((0, 11, 20.3), (46, 22, 37.42))
    g.box((0, 11, .8), (48, 24, 1.6), "StoneLight")
    g.box((0, 11, 39.5), (47.5, 23.5, 1), "StoneLight")
    for height in (10, 20, 30):
        for y in (-.02, 22.02):
            g.box((0, y, height), (45.8, .06, .28), "StoneDark")
        for x in (-23.02, 23.02):
            g.box((x, 11, height), (.06, 21.8, .28), "StoneDark")
    for x in (-14, 0, 14):
        detail = a._Mesh()
        detail.prism(a._pointed(7.6, 31, 7, 12), -.12, -.05, "StoneDark")
        detail.faces = [tuple(reversed(face)) for face in detail.faces]
        e.arch_band(detail, a, 8.1, 31.5, 7.6, 31, -.30, -.16,
                    "StoneLight", base=6.8, inner_base=7, samples=12)
        g.transformed(detail, offset=(x, 0, 0))
    return g, [e.box_proxy((0, 10.85, 20), (48, 24.3, 40))], "Closed stone body 1.59..39.01; exclusive footer/coping exterior caps; join strips penetrate stone .01. Decoration remains noncolliding."


def masonry_mass(a, e):
    g = a._Mesh()
    g.box((0, 0, 12.1), (24, 12, 21.62))
    g.box((0, 0, .65), (25, 13, 1.3), "StoneLight")
    g.box((0, 0, 23.45), (25, 13, 1.1), "StoneLight")
    for height in (8, 16):
        for y in (-6.02, 6.02):
            g.box((0, y, height), (23.8, .06, .22), "StoneDark")
        for x in (-12.02, 12.02):
            g.box((x, 0, height), (.06, 11.8, .22), "StoneDark")
    return g, [e.box_proxy((0, 0, 12), (25, 13, 24))], "Closed stone body 1.29..22.91; exclusive footer/coping exterior caps; join strips penetrate stone .01. Decoration remains noncolliding."


FACTORIES = {"MC_AR_FoundationBay46": foundation, "MC_AR_MasonryMass": masonry_mass}
keep_recipe = load(Path(__file__).with_name("MainKeepShell.py"), "er_keep_recipe")
FACTORIES["MC_ER_MainKeepShell"] = keep_recipe.main_keep_shell
crown_recipe = load(Path(__file__).with_name("CrownBaseShell.py"), "er_crown_recipe")
FACTORIES["MC_ER_CrownBaseShell"] = crown_recipe.crown_base_shell


def authored_record(name, g):
    materials = {}
    for face, material in zip(g.faces, g.colors):
        materials.setdefault(material, []).append(face)
    parts = []
    for material, faces in materials.items():
        used = sorted({i for face in faces for i in face})
        index = {old: new for new, old in enumerate(used)}
        vertices = [[g.vertices[i][0], g.vertices[i][2], -g.vertices[i][1]] for i in used]
        parts.append({"name": name + "__" + material, "material": material,
                      "vertices": vertices, "faces": [[index[i] for i in face] for face in faces]})
    record = {"asset": name, "parts": parts}
    if name == "MC_ER_MainKeepShell":
        record["solid_boxes"] = keep_recipe.solid_boxes_roblox()
        record["solid_boxes_source"] = "exact_canonical_union"
    elif name == "MC_ER_CrownBaseShell":
        record["solid_boxes"] = [{"low":b["low"],"high":b["high"]} for b in crown_recipe.inputs()["boxes"]]
        record["solid_boxes_source"] = "exact_canonical_union"
    return record


def main():
    assert bpy.app.background, "Use an isolated background process."
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    out = args.output.resolve()
    assert out.is_relative_to(ROOT) and (not out.exists() or not any(out.iterdir()))
    paths = [ROOT / "assets/moonlit_citadel/bl02/architecture.py",
             ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py",
             ROOT / "tools/moonlit-citadel/phase3/art-repair-20261013/BlenderArtRepairKit.py",
             Path(__file__).with_name("MainKeepShell.py"), Path(__file__).with_name("CrownBaseShell.py"),
             Path(__file__).with_name("GridUnion.py"), Path(__file__).with_name("crown-inputs.json")]
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    a, e = load(paths[0], "er_architecture"), load(paths[1], "er_exporter")
    e.BUILD, e.MAX_LIBRARY_TRIANGLES, e.MAX_ASSET_TRIANGLES, e.MAX_EXPORT_PARTS = BUILD, 7000, 5000, 11
    root = bpy.data.collections.new(BUILD)
    bpy.context.scene.collection.children.link(root)
    authored = e.new_collection(BUILD + "_Authored", root)
    exported = e.new_collection(BUILD + "_Export", root)
    palette, objects, occupied, recipes = a._materials(), [], {}, []
    for name, factory in FACTORIES.items():
        assert bpy.data.objects.get(name) is None, "Use a clean isolated file; preserve legacy assets."
        g, boxes, notes = factory(a, e)
        recipes.append(authored_record(name, g))
        occupied[name] = boxes
        obj = a._object(authored, name, g, palette, 0, notes)
        obj["Build"], obj["Role"] = BUILD, "Noncolliding architecture"
        objects.append(obj)
    bpy.context.view_layer.update()
    assets, parts = e.export_units(objects, exported, occupied)
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in exported.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(out / "MC_ENCLOSURE_REPAIR_ER01.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             use_mesh_modifiers=True, bake_anim=False, add_leaf_bones=False)
    exported.hide_viewport, exported.hide_render = True, True
    manifest = {"candidate": BUILD, "axes": "Roblox=(X,Z,-Y)", "assets": assets,
                "export_parts": parts, "source_hashes": hashes, "part_count": len(parts),
                "export_triangles": sum(p["triangles"] for p in parts)}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (out / "authored-vertices.json").write_text(json.dumps({"axes": "Roblox", "assets": recipes}) + "\n", encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "MC_ENCLOSURE_REPAIR_ER01.blend"))
    for p in paths:
        assert hashlib.sha256(p.read_bytes()).hexdigest() == hashes[str(p.relative_to(ROOT))]
    receipt = {p.name: {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
               for p in out.iterdir() if p.is_file()}
    (out / "build-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(out), "parts": len(parts), "triangles": manifest["export_triangles"]}))


if __name__ == "__main__":
    main()
