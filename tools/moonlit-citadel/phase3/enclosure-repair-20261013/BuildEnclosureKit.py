"""Build the integrated fortress and connected landscape in an isolated Blender process."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import types

import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[4]
BUILD = "MC_P3_ENCLOSURE_REPAIR_ER01"


def load(path, name, expanded=False):
    source = path.read_text(encoding="utf-8")
    if expanded:
        expected = "zip(size, (40, 30, 40))"
        assert expected in source
        source = source.replace(expected, "zip(size, (1000, 1000, 650))")
    module = types.ModuleType(name)
    module.__file__ = str(path)
    sys.modules[name] = module
    exec(compile(source, str(path), "exec"), module.__dict__)
    return module


def main():
    assert bpy.app.background, "Preserve the live Blender scene."
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    out = args.output.resolve()
    assert out.is_relative_to(ROOT)
    assert not out.exists() or not any(out.iterdir()), "Preserve prior build outputs."
    folder = Path(__file__).resolve().parent
    landscape_folder = folder / "drafts/landscape"
    sys.path.insert(0, str(landscape_folder))
    sys.path.insert(0, str(folder / "drafts/geometry"))
    paths = [Path(__file__).resolve(),
             ROOT / "assets/moonlit_citadel/bl02/architecture.py",
             ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py",
             folder / "drafts/geometry/BlenderEnclosureRepairKit.py",
             folder / "drafts/geometry/MainKeepShell.py",
             folder / "drafts/fortress/FortressRecipes.py",
             folder / "drafts/fortress/BlenderFortressRecipe.py",
             landscape_folder / "EnclosureRecipes.py",
             landscape_folder / "Source48TreeRecipes.py",
             landscape_folder / "FortressSeats.json",
             folder / "drafts/geometry/crown-inputs.json"]
    crown = folder / "drafts/geometry/CrownBaseShell.py"
    if crown.is_file():
        paths.append(crown)
    hashes = {str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    a = load(ROOT / "assets/moonlit_citadel/bl02/architecture.py", "er_architecture")
    e = load(ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py", "er_exporter", True)
    repair = load(folder / "drafts/geometry/BlenderEnclosureRepairKit.py", "er_caps")
    fortress = load(folder / "drafts/fortress/BlenderFortressRecipe.py", "er_fortress")
    landscape = load(landscape_folder / "EnclosureRecipes.py", "er_landscape")
    trees = load(landscape_folder / "Source48TreeRecipes.py", "er_tree_palette")
    assert "MC_ER_MainKeepShell" in repair.FACTORIES
    assert "MC_ER_CrownBaseShell" in repair.FACTORIES, "Complete the crown geometry repair first."
    e.BUILD, e.MAX_LIBRARY_TRIANGLES, e.MAX_ASSET_TRIANGLES, e.MAX_EXPORT_PARTS = BUILD, 100000, 40000, 80
    root = e.new_collection(BUILD, bpy.context.scene.collection)
    authored = e.new_collection(BUILD + "_Authored", root)
    exported = e.new_collection(BUILD + "_Export", root)
    palette = a._materials()
    for colors in (fortress.PALETTE, landscape.PALETTE, trees.PALETTE):
        for key, rgb in colors.items():
            if key in palette:
                continue
            material = bpy.data.materials.new("MC_P3_" + key)
            material.diffuse_color = tuple(a._linear(c) for c in rgb) + (1,)
            palette[key] = material
    recipes = [(name, *factory(a, e)) for name, factory in repair.FACTORIES.items()]
    recipes.extend(fortress.recipes(a, e))
    for name, mesh in landscape.build_recipes().items():
        geometry = a._Mesh()
        vertices = [(x, -z, y) for x, y, z in mesh.vertices]
        for material in dict.fromkeys(mesh.materials):
            faces = [face for face, role in zip(mesh.faces, mesh.materials) if role == material]
            geometry.add(vertices, faces, material, smooth=material in {"Foliage", "Needles"})
        low, high = mesh.bounds()
        boxes = [{"low": [low[0], -high[2], low[1]], "high": [high[0], -low[2], high[1]]}]
        recipes.append((name, geometry, boxes, "Connected course-local terrain or rooted woodland; terrain material boundaries share exact exterior edges."))
    objects, occupied = [], {}
    for name, geometry, boxes, notes in recipes:
        assert name not in occupied
        obj = a._object(authored, name, geometry, palette, 0, notes)
        obj["Build"], obj["Role"] = BUILD, "Noncolliding enclosing scenery"
        objects.append(obj)
        occupied[name] = boxes
    bpy.context.view_layer.update()
    assets, parts = e.export_units(objects, exported, occupied)
    references, topology = [], []
    for obj in exported.objects:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        boundary = sum(edge.is_boundary for edge in bm.edges)
        nonmanifold = sum(not edge.is_manifold for edge in bm.edges)
        bm.free()
        topology.append({"part": obj.name, "boundary_edges": boundary, "nonmanifold_edges": nonmanifold})
        references.append({"name": obj.name, "vertices": [[v.co.x, v.co.z, -v.co.y] for v in obj.data.vertices]})
    assert all(part["triangles"] < 15000 for part in parts), "Partition a large material mesh without duplicating surface area."
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in exported.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(out / "MC_ENCLOSURE_KIT.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             use_mesh_modifiers=True, bake_anim=False, add_leaf_bones=False)
    exported.hide_viewport, exported.hide_render = True, True
    manifest = {"candidate": BUILD, "units": "1 Blender unit = 1 intended stud",
                "axes": "Roblox=(X,Z,-Y); terrain vertices include course-local placement",
                "assets": assets, "export_parts": parts, "source_hashes": hashes,
                "part_count": len(parts), "export_triangles": sum(p["triangles"] for p in parts),
                "material_part_topology": topology,
                "terrain_material_boundary_rule": "Partitions have one coherent closed assembled exterior; no duplicated top surface area."}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (out / "authored-vertices.json").write_text(json.dumps({"axes": "Roblox", "parts": references}, separators=(",", ":")) + "\n", encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "MC_ENCLOSURE_KIT.blend"))
    for name, digest in hashes.items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest
    receipt = {p.name: {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
               for p in out.iterdir() if p.is_file()}
    (out / "build-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(out), "assets": len(assets), "parts": len(parts), "triangles": manifest["export_triangles"]}), flush=True)


if __name__ == "__main__":
    main()
