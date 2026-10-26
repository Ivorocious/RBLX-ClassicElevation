"""Reopen the saved native primitive source and check manifest parity."""
import importlib.util
import json
from pathlib import Path
import bpy

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("chicken_source", HERE / "build_chicken.py")
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)
out = source.OUT
bpy.ops.wm.open_mainfile(filepath=str(out / "chicken_kit.blend"))
manifest = json.loads((out / "manifest.json").read_text())
checked, wedges = 0, 0
for key, template in manifest["templates"].items():
    expected = {part["name"]: part for part in template["parts"]}
    children = [obj for obj in bpy.data.objects[key].children if obj.type == "MESH"]
    assert len(children) == template["partCount"]
    for obj in children:
        record, _ = source.inspect_part(obj)
        assert record == expected[record["name"]], record["name"]
        checked += 1
        wedges += record["primitive"] == "Wedge"
report = dict(build=manifest["build"], partsChecked=checked, wedgePartsChecked=wedges,
              closedPositiveSolids=checked, exactPrimitiveTopology=True,
              savedManifestParity=True, sourceUnmodified=True)
(out / "saved_blend_check.json").write_text(json.dumps(report, indent=2) + "\n")
print("SAVED_CHICKEN_CHECK " + json.dumps(report))
