import hashlib
import json
from pathlib import Path

root = Path.cwd().resolve()
phase = root / "docs/artifacts/keyboard-circuit/phase1"
manifest_path = phase / "C08-evidence-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
freeze = json.loads((phase / "C08-freeze-verification.json").read_text(encoding="utf-8"))
digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
assert digest(manifest_path) == freeze["manifestSha256"]
for item in manifest["files"]:
    path = root / item["path"]
    assert path.stat().st_size == item["bytes"] and digest(path) == item["sha256"], item["path"]
source_entries = sorted(manifest["sources"], key=lambda item: item["path"])
fingerprint = hashlib.sha256("".join(item["path"] + "\0" + digest(root / item["path"]) + "\n" for item in source_entries).encode()).hexdigest()
assert fingerprint == freeze["sourceFingerprint"] == manifest["sourceFingerprint"]
original = json.loads((phase / "reviews/C07-FINAL-GATE.json").read_text(encoding="utf-8"))["reviews"]
owner = json.loads((phase / "C08-owner-checkpoint.json").read_text(encoding="utf-8"))
closing = json.loads((phase / "C08-CLOSING-STATE.json").read_text(encoding="utf-8"))
assert owner["candidate"] == "KC_P1_C08" and owner["ownerCheckpointAccepted"] is True
assert closing["revision"] == "KC_P1_C08" and closing["passed"] is True
assert closing["studioMode"] == "Edit" and closing["sourceMatches"] == len(source_entries)
assert closing["fourFrozenModelsMatch"] is True
assert not closing["wholePlaceSaved"] and not closing["published"]
assert len(manifest["native"]) == freeze["nativeFiles"] == 4
for item in manifest["native"].values():
    assert digest(root / item["path"]) == item["sha256"]
reviews = []

def field(review, *names, nested_names=None):
    nested_names = names if nested_names is None else nested_names
    values = [review[name] for name in names if name in review]
    values += [review["hashes"][name] for name in nested_names if name in review.get("hashes", {})]
    assert values and len(set(values)) == 1, "Missing or conflicting review field: " + "/".join(names)
    return values[0]

for index, old in enumerate(original, 1):
    path = phase / f"reviews/R{index}-C08.json"
    review = json.loads(path.read_text(encoding="utf-8"))
    assert review["reviewer"] == old["reviewer"]
    assert review["canonicalOriginalIdentity"] == old["canonicalAgentIdentity"]
    assert review["model"] == "gpt-6.1-sol" and review["reasoningEffort"].lower() == "high"
    assert field(review, "candidate", "revision", nested_names=()) == "KC_P1_C08"
    if "kit" in review or "kitRevision" in review: assert field(review, "kit", "kitRevision", nested_names=()) == "KC_KIT_C08_01"
    assert field(review, "sourceFingerprint", nested_names=("sourceFingerprint", "fourteenSourceFingerprint", "source")) == fingerprint
    assert field(review, "manifestSHA256", "manifestSha256", "evidenceManifestSHA256", "evidenceManifestSha256", nested_names=("manifestSHA256", "manifestSha256", "evidenceManifestSHA256", "evidenceManifestSha256", "manifest")) == freeze["manifestSha256"]
    assert field(review, "candidateSHA256", "candidateSha256", nested_names=("candidateSHA256", "candidateSha256", "candidate")) == manifest["native"]["C08"]["sha256"]
    assert field(review, "kitSHA256", "kitSha256", nested_names=("kitSHA256", "kitSha256", "kit")) == manifest["native"]["KitC08"]["sha256"]
    score = field(review, "overallScore", "overallPhase1Score")
    assert score >= 8.5 and review["blockers"] == [], f"R{index} has not passed"
    reviews.append({"reviewer": review["reviewer"], "canonicalAgentIdentity": old["canonicalAgentIdentity"], "model": review["model"], "reasoningEffort": review["reasoningEffort"].lower(), "overallPhase1Score": score, "unresolvedBlockers": len(review["blockers"]), "report": path.relative_to(root).as_posix(), "reportSha256": digest(path)})
assert len(reviews) == 5 and len({item["canonicalAgentIdentity"] for item in reviews}) == 5
gate = {"candidate": "KC_P1_C08", "kitRevision": "KC_KIT_C08_01", "candidateSha256": manifest["native"]["C08"]["sha256"], "kitSha256": manifest["native"]["KitC08"]["sha256"], "sourceFingerprint": fingerprint, "manifestSha256": freeze["manifestSha256"], "verifiedFrozenEntries": len(manifest["files"]), "sourceCount": len(source_entries), "originalIndependentReviewerCount": 5, "eachRequiredScore": 8.5, "eachReviewerPassed": True, "reviewGatePassed": True, "historicalScoresInherited": False, "implementationSpecialistsSubstituteForJudges": False, "reviews": reviews, "ownerCheckpointAccepted": True, "ownerAcceptanceRecord": "docs/artifacts/keyboard-circuit/phase1/C08-owner-checkpoint.json", "phase1Accepted": True, "phase2": "Ready for separately authorized final pass; production remains on hold", "phase2ProductionAuthorized": False, "closingStateSha256": digest(phase / "C08-CLOSING-STATE.json"), "wholePlaceSaved": False, "published": False, "releaseBoundary": "Local Phase 1 acceptance only. Fresh readiness is solo/actual-avatar; earlier two-client shared occupancy stays separate. No 20-racer, physical-device, full-race or FPS claim. No whole-place save/publication authorization."}
(phase / "reviews/C08-FINAL-GATE.json").write_text(json.dumps(gate, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"reviewGatePassed": True, "originalJudges": 5, "scores": [item["overallPhase1Score"] for item in reviews], "blockers": 0, "verifiedFrozenEntries": len(manifest["files"]), "sourceFingerprint": fingerprint}))
