"""Audit changed horizontal caps against existing coherent fortress and crown geometry."""
import hashlib
import json
from pathlib import Path
import sys

import AnalyseCrown as crown
import numpy as np
from scipy.spatial import ConvexHull

sys.dont_write_bytecode = True
sys.path.insert(0, str(crown.ENCLOSURE / "drafts/geometry"))
from AuditCaps import audit, components, transform


def convex_burial(conflict, authored, placements):
    units = {p["id"]: p for p in placements}
    assets = {a["asset"]: a for a in authored["assets"]}
    proofs = []
    for label in ("a", "b"):
        unit_name, material, face_name = conflict[label].split("/")
        row = units[unit_name]
        parts = assets[row["asset"]]["parts"]
        part = next(p for p in parts if p["material"] == material)
        face = part["faces"][int(face_name[4:])]
        points = np.array([transform(row, part["vertices"][i]) for i in face])
        normal = np.cross(points[1] - points[0], points[2] - points[0])
        sign = 1 if normal[1] > 0 else -1
        plane = float(np.mean(points[:, 1]))
        sample = np.array([(p[0], plane + sign * .0001, p[1]) for p in conflict["overlap_polygon_xz"]])
        proof = None
        for occluder in parts:
            for indices in components(occluder):
                vertices = np.array([transform(row, occluder["vertices"][i]) for i in sorted(indices)])
                if np.any(np.min(vertices, axis=0) >= np.min(sample, axis=0) - 1e-7) or np.any(np.max(vertices, axis=0) <= np.max(sample, axis=0) + 1e-7):
                    continue
                hull = ConvexHull(vertices)
                planes = hull.equations
                faces = [f for f in occluder["faces"] if f[0] in indices]
                # Each actual closed component face must lie on its hull boundary; concave hull fill is disallowed.
                if not all(np.any(np.all(np.abs(np.array([transform(row, occluder["vertices"][i]) for i in face]) @ planes[:, :3].T + planes[:, 3]) < 2e-7, axis=0)) for face in faces):
                    continue
                distances = sample @ planes[:, :3].T + planes[:, 3]
                if np.all(distances < -1e-7):
                    proof = {"label": label, "componentMaterial": occluder["material"], "componentVertices": len(indices),
                             "wholePolygonMargin": float(-np.max(distances)), "outwardProbe": .0001,
                             "actualConvexComponentFacesVerified": True}
                    break
            if proof:
                break
        proofs.append(proof)
    return {"a": conflict["a"], "b": conflict["b"], "provenBuried": all(proofs), "proofs": proofs}


def run():
    original_path = crown.ARTIFACTS / "combined-plan49.json"
    original = json.loads(original_path.read_text())["units"]
    before = {u["name"]: u for u in original}
    candidate = crown.revised(original, "turretsOnly")
    changed = {u["name"] for u in candidate if u != before.get(u["name"])}
    authored_path = crown.ENCLOSURE / "drafts/geometry/combined-authored.json"
    authored = json.loads(authored_path.read_text())
    known = {a["asset"] for a in authored["assets"]}
    for name, parts in crown.recipes().items():
        if name.startswith("MC_TL_") or name == "MC_P3_CrownScreen":
            authored["assets"].append({"asset": name, "parts": parts})
            known.add(name)
    placements = [{"id": u["name"], "asset": u["asset"], "cf": u["localCF"], "scaleRoblox": u["scale"]}
                  for u in candidate if u["asset"] in known]
    result = audit(authored, placements, .002)
    all_conflicts = result.pop("conflicts")
    relevant = [c for c in all_conflicts if c["a"].split("/")[0] in changed or c["b"].split("/")[0] in changed]
    external = [c for c in relevant if c["classification"] == "external_coplanar_candidate"]
    burial = [convex_burial(c, authored, placements) for c in external]
    unproven = [c for c, proof in zip(external, burial) if not proof["provenBuried"]]
    result["focusedChangedUnitNames"] = sorted(changed)
    result["focusedConflicts"] = relevant
    result["focusedRawCandidates"] = external
    result["convexBurialProofs"] = burial
    result["focusedExternalCandidates"] = unproven
    result["focusPass"] = len(unproven) == 0
    result["unchangedConflictsCount"] = len(all_conflicts) - len(relevant)
    result["claim"] = "No exposed same-facing horizontal cap candidate involving the two revised flank scenery units within0.002stud; unchanged terrain-buried candidates retain the Source49 proof. This is not temporal renderer or whole-map acceptance evidence."
    result["inputHashes"] = {str(p.relative_to(crown.ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest()
                              for p in [original_path, authored_path, Path(__file__).resolve(), crown.HERE / "AnalyseCrown.py",
                                        crown.HERE / "SceneryRevisions.luau", crown.HERE / "candidate-unit-plan.json"]}
    (crown.HERE / "cap-join-check.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"pass": result["focusPass"], "affectedUnits": len(changed), "focusedCapPairs": len(relevant),
                      "focusedRawCandidates": len(external), "convexProvenBuried": len(burial) - len(unproven),
                      "focusedExternalCandidates": len(unproven), "knownPlacementsChecked": result["affected_placements"]}))
    assert result["focusPass"], "Repair concrete new crown cap candidates before native assembly"


if __name__ == "__main__":
    run()
