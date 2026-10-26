"""Bind the selected crown poses and focused evidence; no external applications are used."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
module = HERE / "SceneryRevisions.luau"
expected = "50f851d6b275bc716e87946b1288b9828d11b709005ec70a46c9f16a6a06b20f"
assert hashlib.sha256(module.read_bytes()).hexdigest() == expected
clearance = json.loads((HERE / "focused-checks.json").read_text())
caps = json.loads((HERE / "cap-join-check.json").read_text())
rays = json.loads((HERE / "crown-rays.json").read_text())
assert clearance["pass"] and clearance["uniqueVolumes"] == 1581 and clearance["occupiedRows"] == 8
assert caps["focusPass"] and len(caps["focusedChangedUnitNames"]) == 2 and not caps["focusedExternalCandidates"]
assert len(caps["focusedRawCandidates"]) == 16 and all(p["provenBuried"] for p in caps["convexBurialProofs"])
assert rays["selectedCase"] == "turretsOnly"
for report, key in [(clearance, "inputHashes"), (caps, "inputHashes"), (rays, "inputHashes")]:
    for path, digest in report[key].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
candidate = {u["name"]: u for u in json.loads((HERE / "candidate-unit-plan.json").read_text())}
luau = json.loads((HERE / "luau-changed-plan.json").read_text())
assert {u["name"] for u in luau} == {"GrandFlankPinnacle-1", "GrandFlankPinnacle1"}
maximum = 0
for row in luau:
    wanted = candidate[row["name"]]
    assert row["asset"] == wanted["asset"] and row["library"] == wanted["library"]
    maximum = max(maximum, *(abs(a-b) for key in ("localCF", "scale") for a, b in zip(row[key], wanted[key])))
assert maximum < .00002
files = [p for p in HERE.iterdir() if p.is_file() and p.name != "draft-freeze.json"]
result = {"selectedModule": module.name, "moduleSha256": expected, "changedUnits": 2,
          "addedUnits": 0, "addedMeshParts": 0, "addedTriangles": 0,
          "luauPythonPoseMaximumDelta": maximum, "staticClearancePass": True, "focusedCapPass": True,
          "nativeCameraAndRenderingVerified": False, "productionEdited": False,
          "historicalAlternativeOnly": "PreparedRaisedRimAlternative.luau",
          "files": {p.name: {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in files}}
(HERE / "draft-freeze.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({k: result[k] for k in ("moduleSha256", "changedUnits", "addedUnits", "luauPythonPoseMaximumDelta", "staticClearancePass", "focusedCapPass")}))
