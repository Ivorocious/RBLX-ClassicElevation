"""Read the saved source and check the authored solid primitives again."""
import json
from pathlib import Path
import bpy
import bmesh

out = Path(__file__).resolve().parent / "candidate_a01"
bpy.ops.wm.open_mainfile(filepath=str(out / "readable_kit.blend"))
manifest = json.loads((out / "manifest.json").read_text(encoding="utf8"))
objects = [obj for obj in bpy.context.scene.objects if obj.get("RobloxPrimitive") == "Block"]
assert len(objects) == sum(row["partCount"] for row in manifest["templates"].values())
lethal = 0
for obj in objects:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(edge.is_manifold for edge in bm.edges), obj.name
    assert bm.calc_volume(signed=True) > 0, obj.name
    assert all(face.calc_area() > 0 for face in bm.faces), obj.name
    bm.free()
    lethal += bool(obj.get("ERLethal"))
assert lethal == sum(row["lethalPartCount"] for row in manifest["templates"].values())
report = {"build":manifest["build"],"savedReadback":True,"closedPositiveSolids":len(objects),"lethalParts":lethal}
(out / "saved_blend_check.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
print(json.dumps(report))
