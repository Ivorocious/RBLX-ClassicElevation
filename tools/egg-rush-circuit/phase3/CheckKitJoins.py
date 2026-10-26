"""Audit recipe box faces without Blender, Studio, or canonical source writes."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import itertools
import json
import math
import os
from pathlib import Path
import sys
import tempfile

sys.dont_write_bytecode = True
REPO = Path(__file__).resolve().parents[3]
EPS = .005
OUTSIDE = .02


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def matrix(rotation):
    x, y, z = map(math.radians, rotation)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    return ((cy*cz, -cy*sz, sy),
            (cx*sz + sx*sy*cz, cx*cz - sx*sy*sz, -sx*cy),
            (sx*sz - cx*sy*cz, sx*cz + cx*sy*sz, cx*cy))


def record(definition, palette):
    rotation = definition.get("rotation", (0, 0, 0))
    basis = matrix(rotation)
    half = [value / 2 for value in definition["size"]]
    extent = [sum(abs(basis[i][j]) * half[j] for j in range(3)) for i in range(3)]
    position = definition["position"]
    block = definition["shape"] == "Block"
    aligned = all(abs(value / 90 - round(value / 90)) < 1e-8 for value in rotation)
    material = definition["material"]
    return {
        "name": definition["name"],
        "min": [position[i] - extent[i] for i in range(3)],
        "max": [position[i] + extent[i] for i in range(3)],
        "exactBox": block and aligned,
        "shape": definition["shape"],
        "rotation": rotation,
        "materialRole": material,
        "appearance": [palette[material], "Glass" if material == "Glass" else "SmoothPlastic", definition.get("transparency", 0)],
        "transparency": definition.get("transparency", 0),
    }


def contains(row, point):
    return all(row["min"][i] + EPS < point[i] < row["max"][i] - EPS for i in range(3))


def inspect(template, rows):
    candidates, hidden = [], []
    boxes = [row for row in rows if row["exactBox"] and row["transparency"] < .95]
    for a, b in itertools.combinations(boxes, 2):
        low = [max(a["min"][i], b["min"][i]) for i in range(3)]
        high = [min(a["max"][i], b["max"][i]) for i in range(3)]
        for axis in range(3):
            other = [i for i in range(3) if i != axis]
            spans = [high[i] - low[i] for i in other]
            if any(span <= EPS for span in spans):
                continue
            for side, sign in (("min", -1), ("max", 1)):
                plane = a[side][axis]
                if abs(plane - b[side][axis]) > EPS:
                    continue
                samples = []
                for s, t in itertools.product((.25, .75), repeat=2):
                    point = [0., 0., 0.]
                    point[axis] = plane + sign * OUTSIDE
                    point[other[0]] = low[other[0]] + spans[0] * s
                    point[other[1]] = low[other[1]] + spans[1] * t
                    occluders = [row for row in rows if row is not a and row is not b
                                 and row["transparency"] < .05 and contains(row, point)]
                    samples.append({
                        "point": point,
                        "exactBoxOccluders": [row["name"] for row in occluders if row["exactBox"]],
                        "meshBoundsMayOcclude": [row["name"] for row in occluders if row["shape"] == "Mesh"],
                        "otherBoundsMayOcclude": [row["name"] for row in occluders if not row["exactBox"] and row["shape"] != "Mesh"],
                    })
                visible = sum(not sample["exactBoxOccluders"] for sample in samples)
                item = {
                    "template": template, "a": a["name"], "b": b["name"],
                    "appearanceA": a["appearance"], "appearanceB": b["appearance"],
                    "materialRoleA": a["materialRole"], "materialRoleB": b["materialRole"],
                    "sameAppearance": a["appearance"] == b["appearance"],
                    "axis": "XYZ"[axis], "outward": sign, "plane": plane,
                    "overlapArea": spans[0] * spans[1],
                    "visibleBoxSamples": visible, "totalSamples": 4,
                    "meshMayOcclude": any(sample["meshBoundsMayOcclude"] for sample in samples),
                    "otherBoundsMayOcclude": any(sample["otherBoundsMayOcclude"] for sample in samples),
                    "classification": "SameFacingBoxFaceCandidate" if visible else "BoxOccludedAtFourSamples",
                    "samples": samples,
                }
                (candidates if visible else hidden).append(item)
    return candidates, hidden


def source_parity(recipe, output_parent):
    canonical = recipe.MODULE.resolve()
    before = digest(canonical)
    descriptor, name = tempfile.mkstemp(prefix="kit-joins-generated-", suffix=".luau", dir=output_parent)
    os.close(descriptor)
    temporary = Path(name).resolve()
    assert temporary.parent == output_parent.resolve()
    original = recipe.MODULE
    try:
        recipe.MODULE = temporary
        recipe.write_module()
        generated = temporary.read_text(encoding="utf8").replace("\r\n", "\n")
        saved = canonical.read_text(encoding="utf8").replace("\r\n", "\n")
        return {"matchesCanonicalNormalizedLF": generated == saved,
                "canonicalSHA256Before": before, "canonicalSHA256After": digest(canonical),
                "generatedNormalizedSHA256": hashlib.sha256(generated.encode()).hexdigest(),
                "canonicalUnchangedDuringAudit": before == digest(canonical)}
    finally:
        recipe.MODULE = original
        temporary.unlink()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--recipe", type=Path, default=REPO / "assets/egg_rush_circuit/phase3/current/build_world_kit.py")
    parser.add_argument("--out", type=Path, default=REPO / "docs/artifacts/egg-rush-circuit/phase3/qc-pass/kit-joins-current.json")
    args = parser.parse_args()
    recipe_path, output = args.recipe.resolve(), args.out.resolve()
    before = digest(recipe_path)
    spec = importlib.util.spec_from_file_location("egg_rush_world_kit_join_audit", recipe_path)
    recipe = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(recipe)
    output.parent.mkdir(parents=True, exist_ok=True)
    all_candidates, all_hidden, skipped, per_template = [], [], [], []
    piece_count = 0
    for name, template in recipe.TEMPLATES.items():
        rows = [record(part, recipe.PALETTE) for part in template["parts"]]
        candidates, hidden = inspect(name, rows)
        all_candidates.extend(candidates)
        all_hidden.extend(hidden)
        piece_count += len(rows)
        for row in rows:
            if not row["exactBox"]:
                skipped.append({"template": name, "part": row["name"], "shape": row["shape"],
                                "rotation": row["rotation"], "reason": "Mesh bounds only" if row["shape"] == "Mesh" else "Non-axis-aligned or non-block primitive"})
        per_template.append({"template": name, "parts": len(rows),
                             "exactBoxes": sum(row["exactBox"] for row in rows),
                             "differentAppearanceCandidates": sum(not row["sameAppearance"] for row in candidates),
                             "sameAppearanceCandidates": sum(row["sameAppearance"] for row in candidates),
                             "boxOccludedPairs": len(hidden)})
    different = sorted((row for row in all_candidates if not row["sameAppearance"]), key=lambda row: (-row["overlapArea"], row["template"], row["a"]))
    same = sorted((row for row in all_candidates if row["sameAppearance"]), key=lambda row: (-row["overlapArea"], row["template"], row["a"]))
    report = {
        "audit": "ER_KIT_JOINS_OFFLINE_A01", "recipe": str(recipe_path), "build": recipe.BUILD,
        "recipeSHA256Before": before, "recipeSHA256After": digest(recipe_path),
        "recipeUnchangedDuringAudit": before == digest(recipe_path),
        "templateCount": len(recipe.TEMPLATES), "templatePieces": piece_count,
        "meshTemplateCount": len(recipe.MESH_SIZES),
        "expectedCountsPreserved": piece_count == 151 and len(recipe.MESH_SIZES) == 8,
        "sourceParity": source_parity(recipe, output.parent),
        "differentAppearanceCandidateCount": len(different), "sameAppearanceCandidateCount": len(same),
        "boxOccludedPairCount": len(all_hidden), "skippedPrimitiveCount": len(skipped),
        "boxOccludedDifferentAppearanceCount": sum(not row["sameAppearance"] for row in all_hidden),
        "boxOccludedSameAppearanceCount": sum(row["sameAppearance"] for row in all_hidden),
        "differentAppearanceCandidates": different, "sameAppearanceCandidates": same,
        "boxOccludedPairs": all_hidden, "skippedPrimitives": skipped, "perTemplate": per_template,
        "limits": [
            "Checks same-facing faces of exact axis-aligned Block definitions within each template; opposite-facing seated contacts are excluded.",
            "A positive overlap wider than 0.005 on both face axes is tested at four points offset 0.02 outside the face.",
            "Four samples do not establish visibility over the whole face; fully box-hidden pairs remain in this report.",
            "Mesh and rotated-primitive bounds only flag possible occlusion and never clear a candidate.",
            "Appearance compares source palette color, Roblox material and transparency; placement accent overrides are not expanded.",
            "Non-axis-aligned blocks and non-block primitives are excluded as face candidates and listed explicitly.",
            "No Blender, Studio, assets, mesh shapes, recipe or canonical module were changed; generated parity source used an owned temporary file.",
        ],
    }
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
    print(json.dumps({key: report[key] for key in ("audit", "templateCount", "templatePieces", "meshTemplateCount", "expectedCountsPreserved", "differentAppearanceCandidateCount", "sameAppearanceCandidateCount", "boxOccludedPairCount", "skippedPrimitiveCount")}))
    print("sourceParity=" + json.dumps(report["sourceParity"]))
    print("output=" + str(output))
    for row in different:
        print(f"{row['template']} {row['a']} / {row['b']}: {row['axis']}{row['outward']:+} plane={row['plane']:g} area={row['overlapArea']:g} visible={row['visibleBoxSamples']}/4 meshMayOcclude={row['meshMayOcclude']}")


if __name__ == "__main__":
    main()
