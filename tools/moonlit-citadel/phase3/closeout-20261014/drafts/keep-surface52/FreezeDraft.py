"""Bind the finite correction, actual-face evidence and preserved render assembly."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())


def record(path):
    return {"file":str(path.relative_to(ROOT)), "sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes":path.stat().st_size}


def main():
    output = HERE / "draft-freeze.json"
    assert not output.exists(), "Preserve the frozen candidate."
    proof = json.loads((HERE / "face-overlap-proof.json").read_text())
    assert proof["cases"]["depth1_04"]["notWhollyBuriedPairs"] == 0
    syntax = json.loads((HERE / "draft-syntax-check.json").read_text())
    assert syntax["pass"]
    render = json.loads((HERE / "render01/keep-surface-render-report.json").read_text())
    assert render["sourcePreserved"] and not render["protectedMoved"] and not render["windowsMoved"]
    assert render["windowVisibilityBefore"] == render["windowVisibilityAfter"]
    source = ROOT / render["sourceBlend"]
    assert record(source)["sha256"] == render["sourceBlendSHA256"]
    check = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/verification52/part-override52-focused-check.json"
    focused = json.loads(check.read_text())
    assert focused["pass"] and focused["CFUnchanged"] and focused["sizeOnly"]
    assert abs(focused["correctedPartBoundingRow"]["size"][2] - 21.527998) < .00001
    files = [record(p) for p in sorted(HERE.rglob("*")) if p.is_file() and "__pycache__" not in p.parts]
    result = {"candidate":"Source52 / Build46 / MC_P3_CLOSEOUT_FC03 keep surface draft",
        "change":{"unit":"GrandRearCentralPinnacle","asset":"MC_TL_GrandPinnacle","library":"TL01",
                  "part":"MC_TL_GrandPinnacle__StoneLight","field":"partLocalScaleOverrides",
                  "value":[1,1,1.04],"semantics":"Native part Size.Z after authorScale; all CFrames unchanged"},
        "files":files,"externalFocusedCheck":record(check),"source51Blend":record(source),
        "faceProofPass":True,"draftSyntaxPass":True,"focusedBoundingClearancePass":True,
        "finalIntegratedPlanBound":False,"nativeTemporalVerified":False,
        "protectedVisibleObjects":717,"otherWorldMaterialPartsPreserved":638,"windowMaterialPartsPreserved":14,
        "windowSurfaceRayOutcomesUnchanged":True,"windowProbeCountPerCamera":27014,
        "resourceDelta":{"units":0,"meshParts":0,"triangles":0},
        "newAssetOrUpload":False,"productionEdited":False,"studioTouched":False,"liveBlenderTouched":False,
        "boundary":"Finite isolated draft proof. Root must bind the integrated plan and verify native camera movement before acceptance."}
    output.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(record(output)))


if __name__ == "__main__":
    main()
