"""Freeze the one rendered crown refinement and its exact static/source bindings."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
EXPECTED = "5ff50030cd99c4cc3460eccdbf0cd5a1135aac7a68ec169252ba1b6bdc05d689"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


assert sha(HERE / "SceneryRevisions.luau") == EXPECTED
clearance = json.loads((HERE / "focused-checks.json").read_text())
caps = json.loads((HERE / "cap-join-check.json").read_text())
render = json.loads((HERE / "render02/refinement-report.json").read_text())
assert clearance["pass"] and clearance["uniqueVolumes"] == 1581 and clearance["occupiedRows"] == 118
assert caps["pass"] and not caps["rawCandidates"] and not caps["unproven"]
assert render["protectedGeometryDigestBefore"] == render["protectedGeometryDigestAfter"]
assert not render["protectedGeometryMoved"] and render["sourcePreserved"]
assert sha(ROOT / render["sourceBlend"]) == render["sourceBlendSHA256"]
assert sha(ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json") == render["sourcePlanSHA256"]
assert sha(HERE / "RenderCrownRefinement.py") == render["scriptSHA256"]
for report in (clearance, caps):
    for path, digest in report["inputHashes"].items():
        assert sha(ROOT / path) == digest, path
for view in render["views"]:
    assert sha(HERE / "render02" / view["file"]) == view["sha256"]
assert sha(HERE / "render02" / render["blend"]["file"]) == render["blend"]["sha256"]
candidate = {u["name"]:u for u in json.loads((HERE / "candidate-unit-plan.json").read_text())}
poses = json.loads((HERE / "luau-changed-plan.json").read_text())
assert len(poses) == 14 and len(candidate) == 243
maximum = 0
for row in poses:
    wanted = candidate[row["name"]]
    assert row["asset"] == wanted["asset"] and row["library"] == wanted["library"]
    for key in ("localCF", "scale"):
        maximum = max(maximum, *(abs(a-b) for a,b in zip(row[key],wanted[key])))
assert maximum < .00002
files = [p for p in HERE.rglob("*") if p.is_file() and p.name != "draft-freeze.json"]
result = {"selectedModule":"SceneryRevisions.luau","moduleSHA256":EXPECTED,"source50ExistingTransformsChanged":2,
          "additionalUnits":10,"resourceDelta":render["resourceDelta"],"totals":clearance["totalAfterRefinement"],
          "luaPythonPoseMaximumDelta":maximum,"staticClearancePass":True,"focusedCapPass":True,
          "blenderCompositionCompared":True,"protectedBlenderCollectionUnchanged":True,
          "nativeCompositionAccepted":False,"nativeMovingRenderVerified":False,"productionEdited":False,
          "files":{str(p.relative_to(HERE)).replace("\\","/"):{"bytes":p.stat().st_size,"sha256":sha(p)} for p in files}}
(HERE / "draft-freeze.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps({k:result[k] for k in ("moduleSHA256","source50ExistingTransformsChanged","additionalUnits","luaPythonPoseMaximumDelta","staticClearancePass","focusedCapPass","blenderCompositionCompared")}))
