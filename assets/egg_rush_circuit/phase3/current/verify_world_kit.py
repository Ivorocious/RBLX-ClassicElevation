"""Reopen world source and round-trip its exact FBX mesh library in Blender."""
import argparse
import importlib.util
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("world_kit_source", HERE / "build_world_kit.py")
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)

parser = argparse.ArgumentParser()
parser.add_argument("--out", type=Path, default=HERE / "candidate_a03")
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
out = args.out.resolve()
manifest = json.loads((out / "manifest.json").read_text(encoding="utf8"))
bpy.ops.wm.open_mainfile(filepath=str(out / "world_kit.blend"))
expected = {}
for name in manifest["meshObjectNames"]:
    obj = bpy.data.objects[name]
    expected[name] = [tuple(obj.matrix_world @ vertex.co) for vertex in obj.data.vertices]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(out / manifest["meshPackage"]), use_anim=False)
actual = {obj.name: obj for obj in bpy.context.scene.objects if obj.type == "MESH"}
assert set(actual) == set(expected), (set(actual), set(expected))
records = {}
for name, points in expected.items():
    obj = actual[name]
    vertices = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    assert len(vertices) == len(points), (name, len(vertices), len(points))
    distance = max(min((vertex - Vector(point)).length for vertex in vertices) for point in points)
    assert distance < .0005, (name, distance)
    records[name] = dict(vertices=len(vertices), maximumVertexError=round(distance, 8),
                         materialSlots=len(obj.data.materials), axisAndPivotParity=True)
report = dict(build=manifest["build"], exactExport=manifest["meshPackage"], meshCount=len(records),
              geometryAndAxisRoundtrip=True, records=records,
              proofBoundary="Blender FBX readback only; Roblox import orientation and size remain native checks.")
(out / "fbx_readback_check.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
print("WORLD_KIT_FBX_CHECK " + json.dumps(report), flush=True)
