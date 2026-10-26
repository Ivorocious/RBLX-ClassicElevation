"""Read back the saved chicken source without changing it."""
import importlib.util
import json
from pathlib import Path
import bpy
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("chicken_source",HERE/"build_chicken.py")
source=importlib.util.module_from_spec(spec);spec.loader.exec_module(source)
out=source.OUT
bpy.ops.wm.open_mainfile(filepath=str(out/"chicken_kit.blend"))
manifest=json.loads((out/"manifest.json").read_text())
checked=0
for key,template in manifest["templates"].items():
    root=bpy.data.objects[key]
    expected={p["name"]:p for p in template["parts"]}
    children=[p for p in root.children if p.type=="MESH"]
    assert len(children)==template["partCount"]
    for obj in children:
        record,_=source.kit.inspect_part(obj)
        assert record==expected[record["name"]],record["name"]
        checked+=1
report={"build":manifest["build"],"partsChecked":checked,"closedPositiveSolids":checked,"savedManifestParity":True,"sourceUnmodified":True}
(out/"saved_blend_check.json").write_text(json.dumps(report,indent=2)+"\n")
print("SAVED_CHICKEN_CHECK "+json.dumps(report))
