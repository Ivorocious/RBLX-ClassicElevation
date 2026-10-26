"""Focus the existing horizontal-cap audit on the revised crown apron and its seated supports."""
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
sys.path.insert(0, str(HERE.parent / "crown"))
import AnalyseCrown as crown
import CheckCapJoins as previous_caps
sys.path.insert(0, str(crown.ENCLOSURE / "drafts/geometry"))
from AuditCaps import audit


def main():
    source = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json"
    candidate_path = HERE / "candidate-unit-plan.json"
    original = {u["name"]: u for u in json.loads(source.read_text())["units"]}
    candidate = json.loads(candidate_path.read_text())
    changed = {u["name"] for u in candidate if u != original.get(u["name"])}
    assert len(changed) == 12
    authored_path = crown.ENCLOSURE / "drafts/geometry/combined-authored.json"
    authored = json.loads(authored_path.read_text())
    known = {a["asset"] for a in authored["assets"]}
    for name, parts in crown.recipes().items():
        if name.startswith("MC_TL_") or name == "MC_P3_CrownScreen":
            authored["assets"].append({"asset": name, "parts": parts})
            known.add(name)
    placements = [{"id":u["name"],"asset":u["asset"],"cf":u["localCF"],"scaleRoblox":u["scale"]}
                  for u in candidate if u["asset"] in known]
    result = audit(authored, placements, .002)
    relevant = [c for c in result.pop("conflicts") if c["a"].split("/")[0] in changed or c["b"].split("/")[0] in changed]
    raw = [c for c in relevant if c["classification"] == "external_coplanar_candidate"]
    proofs = [previous_caps.convex_burial(c, authored, placements) for c in raw]
    unproven = [c for c,p in zip(raw,proofs) if not p["provenBuried"]]
    result.update({"focusedChangedNames":sorted(changed),"focusedConflicts":relevant,"rawCandidates":raw,
                   "convexBurialProofs":proofs,"unproven":unproven,"pass":not unproven,
                   "boundary":"Focused authored horizontal-cap proof only; excludes temporal native render and unrelated unchanged surfaces.",
                   "inputHashes":{str(p.relative_to(ROOT)).replace("\\","/"):hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in [source,candidate_path,authored_path,HERE/"SceneryRevisions.luau",Path(__file__).resolve()]}})
    (HERE / "cap-join-check.json").write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps({"pass":result["pass"],"changedUnits":len(changed),"rawCandidates":len(raw),
                      "convexProvenBuried":len(raw)-len(unproven),"unproven":len(unproven)}))
    assert result["pass"], "Resolve exposed crown cap candidates before native installation"


if __name__ == "__main__":
    main()
