import hashlib
import json
from pathlib import Path

own = Path(__file__).resolve().parent
report = json.loads((own / "focused-window-check.json").read_text())
assert report["pass"] and not report["failures"]
assert report["routeCombinations"] == 32 and report["uniqueVolumes"] == 1586
assert len(report["windowAssemblies"]) == 9
assert len([r for r in report["windowAssemblies"] if not r.get("existing")]) == 6
assert all(r["visible"] and not r["blockers"] and r["frameSamples"] == 1333 for r in report["visibleFaceChecks"])
root = Path.cwd()
for name, item in report["inputHashes"].items():
    assert hashlib.sha256((root / item["path"]).read_bytes()).hexdigest() == item["sha256"], name
names = ["WindowFinishingPlan.luau", "CheckWindowFinishing.luau", "placements.json", "focused-window-check.json", "WINDOW_FINISHING_NOTE.md"]
freeze = {
    "plannedOnly": True,
    "nativeAppearanceVerified": False,
    "resourceDelta": report["resourceDelta"],
    "checksPass": True,
    "noRetiredUnits": True,
    "replacedSceneryPlacements": report["replacements"],
    "inputsUnchanged": True,
    "files": {name: hashlib.sha256((own / name).read_bytes()).hexdigest() for name in names},
}
(own / "draft-freeze.json").write_text(json.dumps(freeze, indent=2) + "\n")
print(json.dumps(freeze))
