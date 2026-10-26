"""Read the saved FBX and Blend in a separate process; preserve their contents."""
import hashlib
import json
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parent
manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT / "MC_BL01_library.fbx"))
imported = {obj.name: obj for obj in bpy.context.scene.objects}
expected = {item["name"]: item for item in manifest["export_parts"]}
assert set(imported) == set(expected), (sorted(set(imported) - set(expected)), sorted(set(expected) - set(imported)))
results = []
for name, obj in imported.items():
    assert obj.type == "MESH" and len(obj.data.materials) == 1, name
    coords = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    assert all(math.isfinite(value) for vertex in coords for value in vertex)
    low = [min(vertex[axis] for vertex in coords) for axis in range(3)]
    high = [max(vertex[axis] for vertex in coords) for axis in range(3)]
    target = expected[name]
    size = [b - a for a, b in zip(low, high)]
    center = [(a + b) / 2 for a, b in zip(low, high)]
    error = max(abs(a - b) for values, target_values in ((size, target["size"]), (center, target["center"]))
                for a, b in zip(values, target_values))
    assert error < .002, (name, error, center, size, target)
    obj.data.calc_loop_triangles()
    results.append({"name": name, "triangles": len(obj.data.loop_triangles), "max_bounds_error": error,
                    "material": obj.data.materials[0].name})
triangle_count = sum(item["triangles"] for item in results)
assert triangle_count == manifest["export_triangles"], (triangle_count, manifest["export_triangles"])
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "MC_BL01_sample.blend"))
authored = bpy.data.collections["AUTHOR_EDIT_UNITS"]
assert len(authored.objects) == manifest["asset_count"]
assert all(obj.type == "MESH" and tuple(obj.location) == (0, 0, 0) for obj in authored.objects)
assert bpy.data.collections["DAYLIGHT"] and bpy.context.scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value >= .5
result = {"candidate": manifest["candidate"], "status": "passed local roundtrip",
          "file_sha256": hashlib.sha256((ROOT / "MC_BL01_library.fbx").read_bytes()).hexdigest(),
          "fbx_meshes": len(results), "triangles": triangle_count, "editable_units": len(authored.objects),
          "max_bounds_error": max(item["max_bounds_error"] for item in results), "parts": results,
          "boundary": "Blender file checks only. Roblox import, colors, pivots and gameplay remain unverified."}
(ROOT / "export_check.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: value for key, value in result.items() if key != "parts"}), flush=True)
