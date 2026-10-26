"""Read the preserved Source54 composition without changing or saving its scene."""
import hashlib
import json
from pathlib import Path

import bpy
import numpy as np

OWN = Path(__file__).resolve().parent
ROOT = next(p for p in OWN.parents if (p / "default.project.json").exists())
SOURCE = ROOT / "tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend"
COLLECTIONS = ("Final_233_World_Units", "Unchanged_Source49_Visible_Course", "DT54_Corrected_77_Details")
assert bpy.app.background
before = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
objects, triangles, owners, faces = [], [], [], []
for collection_name in COLLECTIONS:
    source_objects = sorted(bpy.data.collections[collection_name].all_objects, key=lambda obj: obj.name)
    for obj in source_objects:
        assert obj.type == "MESH" and not obj.hide_render, obj.name
        row = {"index": len(objects), "name": obj.name, "collection": collection_name,
               "props": {key: value.to_list() if hasattr(value, "to_list") else value
                         for key, value in obj.items()},
               "materialSlots": [material.name if material else "" for material in obj.data.materials],
               "matrix": [value for line in obj.matrix_world for value in line]}
        points = np.array([tuple(obj.matrix_world @ vertex.co) for vertex in obj.data.vertices], dtype=np.float64)
        points = points[:, (0, 2, 1)] * np.array((1, 1, -1))
        row["bounds"] = [points.min(axis=0).tolist(), points.max(axis=0).tolist()]
        obj.data.calc_loop_triangles()
        indices = np.array([tuple(triangle.vertices) for triangle in obj.data.loop_triangles])
        rows = points[indices]
        triangles.append(rows)
        owners.append(np.full(len(rows), len(objects), dtype=np.int32))
        faces.append(np.array([triangle.polygon_index for triangle in obj.data.loop_triangles], dtype=np.int32))
        row["triangles"], row["vertices"] = len(rows), len(points)
        objects.append(row)
np.savez_compressed(OWN / "surface-triangles54.npz", triangles=np.concatenate(triangles),
                    owners=np.concatenate(owners), faces=np.concatenate(faces))
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == before
meta = {"sourceBlend": str(SOURCE.relative_to(ROOT)), "sourceBlendSHA256": before,
        "objects": objects, "triangles": sum(row["triangles"] for row in objects),
        "sourceUnchanged": True, "studioTouched": False, "liveBlenderTouched": False}
(OWN / "surface-objects54.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf8")
print("SURFACE_EXPORT " + json.dumps({"objects": len(objects), "triangles": meta["triangles"],
                                      "sample": objects[0], "protectedSample": next(row for row in objects if row["collection"] == COLLECTIONS[1])}), flush=True)
