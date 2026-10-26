"""Joined Moonlit architecture, authored in an isolated Blender process."""

import argparse
import hashlib
import json
from pathlib import Path
import sys
import types

import bpy


ROOT = Path(__file__).resolve().parents[4]
BUILD = "MC_P3_ART_REPAIR_AR01"


def load(path, name, expanded=False):
    source = path.read_text(encoding="utf-8")
    if expanded:
        source = source.replace("zip(size, (40, 30, 40))", "zip(size, (120, 120, 220))")
    module = types.ModuleType(name)
    module.__file__ = str(path)
    exec(compile(source, str(path), "exec"), module.__dict__)
    return module


def gallery_body(a, e):
    g, boxes = a._Mesh(), []

    def block(center, size, material="Stone"):
        g.box(center, size, material)
        boxes.append(e.box_proxy(center, size))

    block((-22, 11, 13), (2, 22, 26))
    block((22, 11, 13), (2, 22, 26))
    block((0, 21, 13), (44.1, 2, 26))
    for side in (-1, 1):
        block((side * 19.5, 1, 12.8), (7, 2, 25.6))
    boxes.extend(e.arch_band(g, a, 32, 24, 28, 22, -.42, 2.42,
                            "StoneLight", samples=16))
    block((0, 1, 25.3), (46, 2.05, 1.4))
    for y in (0, 22):
        block((0, y, 25.65), (47.6, 1.2, .7), "StoneLight")
    for side in (-1, 1):
        block((side * 23, 11, 25.65), (1.2, 22.2, .7), "StoneLight")
        for height in (5, 13, 21):
            g.box((side * 23.04, 11, height), (.10, 22, .20), "StoneDark")
    return g, boxes, "Full side/rear walls, a 28-wide pointed front opening, joined cornice; front Roblox +Z."


def gallery_roof(a, e):
    g = a._Mesh()
    g.prism([(-24, -.35), (24, -.35), (24, .45), (0, 8.6), (-24, .45)],
            -1.5, 23.5, "Slate")
    for y in (-1.56, 23.52):
        g.prism([(-23.15, .48), (23.15, .48), (0, 8.22)], y, y + .05, "StoneDark")
    for side in (-1, 1):
        g.box((side * 23.78, 11, .07), (.62, 25.2, .68), "SlateBand")
    g.box((0, 11, 8.47), (.65, 25.2, .6), "SlateBand")
    return g, [e.box_proxy((0, 11, 4.125), (48.2, 25.2, 9.55))], "Closed pitched roof, closed gables and soffit; base seats at gallery Y26."


def foundation(a, e):
    g = a._Mesh()
    g.box((0, 11, 20), (46, 22, 40))
    g.box((0, 11, .8), (48, 24, 1.6), "StoneLight")
    g.box((0, 11, 39.5), (47.5, 23.5, 1), "StoneLight")
    for height in (10, 20, 30):
        for y in (-.035, 22.035):
            g.box((0, y, height), (45.8, .06, .28), "StoneDark")
        for x in (-23.035, 23.035):
            g.box((x, 11, height), (.06, 21.8, .28), "StoneDark")
    for x in (-14, 0, 14):
        detail = a._Mesh()
        detail.prism(a._pointed(7.6, 31, 7, 12), -.12, -.05, "StoneDark")
        e.arch_band(detail, a, 8.1, 31.5, 7.6, 31, -.30, -.16,
                    "StoneLight", base=6.8, inner_base=7, samples=12)
        g.transformed(detail, offset=(x, 0, 0))
    return g, [e.box_proxy((0, 10.85, 20), (48, 24.3, 40))], "Broad three-bay masonry foundation with continuous plinth and upper coping; modest Y scaling only."


def tower_base(a, e):
    g = a._Mesh()
    rings = [(0, 12, 12), (1.2, 12, 12), (2.2, 10, 10),
             (21.8, 10, 10), (22.6, 11.2, 11.2), (24, 12, 12)]
    vertices = [(sx * w / 2, sy * d / 2, z)
                for z, w, d in rings for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    faces = [(3, 2, 1, 0), tuple(range(len(vertices) - 4, len(vertices)))]
    faces.extend((4 * r + s, 4 * r + (s + 1) % 4,
                  4 * (r + 1) + (s + 1) % 4, 4 * (r + 1) + s)
                 for r in range(len(rings) - 1) for s in range(4))
    g.add(vertices, faces, "Stone")
    for yaw in (0, a.math.pi / 2, a.math.pi, -a.math.pi / 2):
        detail = a._Mesh()
        detail.prism(a._pointed(3.6, 18.6, 4.2, 10), -5.055, -5.025, "StoneDark")
        e.arch_band(detail, a, 4.1, 19, 3.6, 18.6, -5.22, -5.07,
                    "StoneLight", base=4, inner_base=4.2, samples=10)
        g.transformed(detail, yaw)
    return g, [e.box_proxy((0, 0, 12), (12, 12, 24))], "Closed buttressed tower base; place on an intermediate building or terrace, never a stretched ground pole."


def masonry_mass(a, e):
    g = a._Mesh()
    g.box((0, 0, 12), (24, 12, 24))
    g.box((0, 0, .65), (25, 13, 1.3), "StoneLight")
    g.box((0, 0, 23.45), (25, 13, 1.1), "StoneLight")
    for height in (8, 16):
        for y in (-6.035, 6.035):
            g.box((0, y, height), (23.8, .06, .22), "StoneDark")
        for x in (-12.035, 12.035):
            g.box((x, 0, height), (.06, 11.8, .22), "StoneDark")
    return g, [e.box_proxy((0, 0, 12), (25, 13, 24))], "Closed masonry volume; centered 24x12 footprint with base pivot, joined side/rear/underfloor walls."


def main():
    assert bpy.app.background, "Use the isolated Blender build."
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    out = args.output.resolve()
    assert out.is_relative_to(ROOT)
    assert not out.exists() or not any(out.iterdir()), "Preserve existing outputs."
    paths = [ROOT / "assets/moonlit_citadel/bl02/architecture.py",
             ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py"]
    hashes = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    a, e = load(paths[0], "ar_architecture"), load(paths[1], "ar_exporter", True)
    e.BUILD, e.MAX_LIBRARY_TRIANGLES, e.MAX_ASSET_TRIANGLES, e.MAX_EXPORT_PARTS = BUILD, 9000, 3500, 20
    root = bpy.data.collections.new(BUILD)
    bpy.context.scene.collection.children.link(root)
    authored, exported = e.new_collection(BUILD + "_Authored", root), e.new_collection(BUILD + "_Export", root)
    palette, objects, occupied = a._materials(), [], {}
    for key, recipe in [("GalleryBody46", gallery_body), ("GalleryRoof46", gallery_roof),
                        ("FoundationBay46", foundation), ("TowerBase", tower_base),
                        ("MasonryMass", masonry_mass)]:
        name = "MC_AR_" + key
        geometry, boxes, notes = recipe(a, e)
        obj = a._object(authored, name, geometry, palette, 0, notes)
        obj["Build"], obj["Role"] = BUILD, "Noncolliding architecture"
        objects.append(obj)
        occupied[name] = boxes
    bpy.context.view_layer.update()
    assets, parts = e.export_units(objects, exported, occupied)
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in exported.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(out / "MC_ART_REPAIR_KIT.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             use_mesh_modifiers=True, bake_anim=False, add_leaf_bones=False)
    exported.hide_viewport, exported.hide_render = True, True
    manifest = {"candidate": BUILD, "units": "1 Blender unit = 1 intended stud",
                "axes": "Roblox=(X,Z,-Y); gallery front Roblox +Z; base pivots",
                "assets": assets, "export_parts": parts, "source_hashes": hashes,
                "part_count": len(parts), "export_triangles": sum(p["triangles"] for p in parts)}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "MC_ART_REPAIR_KIT.blend"))
    for p, digest in hashes.items():
        assert hashlib.sha256(Path(p).read_bytes()).hexdigest() == digest
    receipt = {name: {"bytes": (out / name).stat().st_size,
                      "sha256": hashlib.sha256((out / name).read_bytes()).hexdigest()}
               for name in ("MC_ART_REPAIR_KIT.fbx", "MC_ART_REPAIR_KIT.blend", "manifest.json")}
    (out / "build_receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(out), "parts": len(parts), "triangles": manifest["export_triangles"]}), flush=True)


if __name__ == "__main__":
    main()
