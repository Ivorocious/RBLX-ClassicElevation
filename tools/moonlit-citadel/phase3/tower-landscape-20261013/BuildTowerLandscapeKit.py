"""Author the tower and rural landscape in an isolated Blender process."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import types
import bpy

ROOT = Path(__file__).resolve().parents[4]
BUILD = "MC_P3_TOWER_LANDSCAPE_TL01"


def load(path, name, expanded=False):
    source = path.read_text(encoding="utf-8")
    if expanded:
        source = source.replace("zip(size, (40, 30, 40))", "zip(size, (160, 160, 220))")
    module = types.ModuleType(name)
    module.__file__ = str(path)
    exec(compile(source, str(path), "exec"), module.__dict__)
    return module


def main():
    assert bpy.app.background, "Use a separate background Blender process."
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    out = args.output.resolve()
    assert out.is_relative_to(ROOT)
    assert not out.exists() or not any(out.iterdir()), "Preserve existing outputs."
    folder = Path(__file__).resolve().parent
    paths = [ROOT / "assets/moonlit_citadel/bl02/architecture.py",
             ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py",
             folder / "drafts/tower/BlenderTowerRecipe.py",
             folder / "drafts/landscape/LandscapeKitRecipes.py"]
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    a = load(paths[0], "tl_architecture")
    e = load(paths[1], "tl_exporter", True)
    tower = load(paths[2], "tl_tower")
    landscape = load(paths[3], "tl_landscape")
    e.BUILD, e.MAX_LIBRARY_TRIANGLES, e.MAX_ASSET_TRIANGLES, e.MAX_EXPORT_PARTS = BUILD, 12000, 3500, 24
    root = e.new_collection(BUILD, bpy.context.scene.collection)
    authored = e.new_collection(BUILD + "_Authored", root)
    exported = e.new_collection(BUILD + "_Export", root)
    palette = a._materials()
    for key, rgb in landscape.PALETTE.items():
        material = bpy.data.materials.new("MC_P3_" + key)
        material.diffuse_color = tuple(a._linear(c) for c in rgb) + (1,)
        palette[key] = material
    objects, occupied = [], {}
    for unit in (tower.grand_pinnacle(), tower.flank_pinnacle(), tower.stepped_buttress()):
        geometry = a._Mesh()
        for role, (vertices, faces) in unit.geometry.items():
            geometry.add(vertices, faces, role)
        obj = a._object(authored, unit.name, geometry, palette, 0, "Grounded closed keep architecture; base pivot.")
        obj["Build"], obj["Role"] = BUILD, "Noncolliding architecture"
        objects.append(obj)
        low = [min(v[i] for v in geometry.vertices) for i in range(3)]
        high = [max(v[i] for v in geometry.vertices) for i in range(3)]
        occupied[unit.name] = [{"low": low, "high": high}]
    for name, rural in landscape.build_recipes().items():
        geometry = a._Mesh()
        vertices = [(x, -z, y) for x, y, z in rural.vertices]
        for role in dict.fromkeys(rural.materials):
            faces = [face for face, material in zip(rural.faces, rural.materials) if material == role]
            geometry.add(vertices, faces, role, smooth=role in {"Grass", "Foliage", "Leaf"})
        low, high = rural.bounds()
        boxes = [{"low": [low[0], -high[2], low[1]], "high": [high[0], -low[2], high[1]]}]
        notes = "Closed rural scenery; soil/root pivot; Roblox front +Z."
        obj = a._object(authored, name, geometry, palette, 0, notes)
        obj["Build"], obj["Role"] = BUILD, "Noncolliding rural scenery"
        objects.append(obj)
        occupied[name] = boxes
    bpy.context.view_layer.update()
    assets, parts = e.export_units(objects, exported, occupied)
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in exported.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(out / "MC_TOWER_LANDSCAPE_KIT.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             use_mesh_modifiers=True, bake_anim=False, add_leaf_bones=False)
    exported.hide_viewport, exported.hide_render = True, True
    manifest = {"candidate": BUILD, "units": "1 Blender unit = 1 intended stud",
                "axes": "Roblox=(X,Z,-Y); base pivots", "assets": assets,
                "export_parts": parts, "source_hashes": hashes, "part_count": len(parts),
                "export_triangles": sum(p["triangles"] for p in parts)}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "MC_TOWER_LANDSCAPE_KIT.blend"))
    for p, digest in hashes.items():
        assert hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == digest
    receipt = {name: {"bytes": (out / name).stat().st_size,
                      "sha256": hashlib.sha256((out / name).read_bytes()).hexdigest()}
               for name in ("MC_TOWER_LANDSCAPE_KIT.fbx", "MC_TOWER_LANDSCAPE_KIT.blend", "manifest.json")}
    (out / "build_receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(out), "parts": len(parts), "triangles": manifest["export_triangles"]}), flush=True)


if __name__ == "__main__":
    main()
