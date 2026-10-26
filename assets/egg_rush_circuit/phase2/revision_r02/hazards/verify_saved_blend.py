"""Read the saved candidate and compare its native solids against the exported data."""
import json
import math
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

out = Path(bpy.data.filepath).parent
manifest = json.loads((out / "hazard_manifest.json").read_text(encoding="utf-8"))
inverse_axes = Matrix(((1,0,0),(0,0,1),(0,-1,0)))
checked = 0
for key, template in manifest["templates"].items():
    root = bpy.data.objects[key]
    assert len(root.children) == template["partCount"], key
    by_name = {obj["NativeName"]: obj for obj in root.children}
    for part in template["parts"]:
        obj = by_name[part["name"]]
        assert obj.type == "MESH" and obj["RobloxPrimitive"] == "Block"
        assert obj["ERLethal"] == part["lethal"]
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        assert len(bm.verts) == 8 and len(bm.faces) == 6
        assert all(edge.is_manifold for edge in bm.edges)
        assert abs(bm.calc_volume(signed=True)-part["volume"]) < 1e-5
        assert all(face.calc_area() > 1e-6 for face in bm.faces)
        bm.free()
        matrix = obj.matrix_local
        position = inverse_axes @ matrix.translation
        rotation = inverse_axes @ matrix.to_3x3() @ inverse_axes.transposed()
        assert max(abs(position[i]-part["position"][i]) for i in range(3)) < 1e-5
        assert max(abs(rotation[row][col]-part["rotationMatrix"][row*3+col]) for row in range(3) for col in range(3)) < 1e-5
        assert all(math.isfinite(value) for vert in obj.data.vertices for value in vert.co)
        checked += 1
report = dict(build=manifest["build"], status="passed", savedBlendReloaded=True,
              templates=len(manifest["templates"]), solidsChecked=checked,
              checks=["finite vertices", "closed manifold", "positive solid volume", "saved transforms match manifest"])
(out / "saved_blend_check.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
print("SAVED_HAZARD_KIT_CHECK " + json.dumps(report))
