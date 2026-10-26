import hashlib
import json
from pathlib import Path


root = Path.cwd()
phase = root / "docs/artifacts/keyboard-circuit/phase1"
manifest_path = phase / "C07-evidence-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
hashes = json.loads((phase / "C07-native-hashes.json").read_text(encoding="utf-8"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


manifest_sha = sha(manifest_path)
assert manifest_sha == "2061a0cd08f106eaadcd92a386f2d309d8a8c550ec47e0baac4f37fb4e9d85d2"
assert len(manifest["files"]) == 48
for entry in manifest["files"]:
    path = root / entry["path"]
    assert path.stat().st_size == entry["bytes"] and sha(path) == entry["sha256"], entry["path"]

records = []
for source in hashes["sources"]:
    actual_sha = sha(root / source["path"])
    assert actual_sha == source["sha256"], source["path"]
    records.append((source["path"], actual_sha))
fingerprint = hashlib.sha256("".join(path + "\0" + digest + "\n" for path, digest in sorted(records)).encode()).hexdigest()
assert len(records) == 13 and fingerprint == hashes["sourceFingerprint"] == manifest["sourceFingerprint"]
for name, native in hashes["native"].items():
    path = phase / (name + "-native.rbxm")
    assert sha(path) == native["sha256"] and path.stat().st_size == native["bytes"]

identities = ["kc_r1_visual", "kc_r2_route", "kc_r3_hazards", "kc_r4_experience", "kc_r5_engineering"]
reviews = []
for number, identity in enumerate(identities, 1):
    path = phase / "reviews" / f"R{number}-C07.json"
    report = json.loads(path.read_text(encoding="utf-8"))
    fields = {key.lower(): value for key, value in report.items()}
    fields.update({key.lower(): value for key, value in report.get("hashes", {}).items()})

    def field(*names):
        for name in names:
            if name.lower() in fields:
                return fields[name.lower()]
        raise AssertionError(f"{path.name}: missing {names}")

    assert field("reviewer") == f"R{number}"
    canonical = field("canonicalOriginalIdentity", "canonicalAgentIdentity", "canonicalIdentity")
    assert canonical == "/root/" + identity
    assert field("model") == "gpt-6.1-sol" and str(field("reasoningEffort")).lower() == "high"
    score = field("overallPhase1Score", "overallScore")
    passed = fields.get("pass") is True or str(fields.get("verdict", "")).lower().startswith("pass")
    assert score >= 8.5 and passed
    blocker_fields = [fields[name] for name in ["blockers", "blockingfindings", "unresolvedblockers", "requiredfixes"] if name in fields]
    assert blocker_fields and all(value == [] or value == 0 for value in blocker_fields)
    assert field("candidateSha256", "candidate") == hashes["native"]["C07"]["sha256"]
    assert field("kitSha256", "kit") == hashes["native"]["KitC07"]["sha256"]
    assert field("sourceFingerprint", "thirteenSourceFingerprint", "source") == fingerprint
    assert field("manifestSha256", "evidenceManifestSha256", "manifest") == manifest_sha
    reviews.append({"reviewer": f"R{number}", "canonicalAgentIdentity": canonical, "model": "gpt-6.1-sol", "reasoningEffort": "high", "overallPhase1Score": score, "unresolvedBlockers": 0, "report": path.relative_to(root).as_posix(), "reportSha256": sha(path)})

closing_path = phase / "reviews/C07-CLOSING-STATE.json"
closing = json.loads(closing_path.read_text(encoding="utf-8"))
assert closing["edit"] and closing["placeId"] == 85558151074819 and closing["sourceAgreement"]
assert closing["candidateRevision"] == "KC_P1_C07" and closing["kitRevision"] == "KC_KIT_C07_01"
assert closing["noTemporaryDisplay"] and all(closing["camera"][name] for name in ["cframeRestored", "focusRestored", "fovRestored"])
rojo = closing["rojo"].values() if isinstance(closing["rojo"], dict) else closing["rojo"]
assert {"Disconnect", "localhost:34872", "ProjectClassicElevation"} <= {item["text"] for item in rojo}

receipt = {"candidate": "KC_P1_C07", "kitRevision": "KC_KIT_C07_01", "candidateSha256": hashes["native"]["C07"]["sha256"], "kitSha256": hashes["native"]["KitC07"]["sha256"], "sourceFingerprint": fingerprint, "manifestSha256": manifest_sha, "verifiedFrozenEntries": 48, "originalIndependentReviewerCount": 5, "eachRequiredScore": 8.5, "eachReviewerPassed": True, "reviewGatePassed": True, "reviews": reviews, "closingStateSha256": sha(closing_path), "additionalExtraHighCritic": {"role": "advisory", "report": "docs/artifacts/keyboard-circuit/phase1/reviews/OWNER-IMPROVEMENTS-XHIGH.md"}, "ownerCheckpointAccepted": False, "phase1Accepted": False, "checkpointPair": ["docs/artifacts/keyboard-circuit/phase1/KC_C07_study_owner_view.png", "docs/artifacts/keyboard-circuit/phase1/KC_C07_sample_owner_view.png"], "releaseBoundary": "Local Phase 1 construction/review only. Human key feel and sound judgment, owner acceptance, full-race/20-racer/device results, Phase 2/3 authorization, whole-place save and publication remain separate."}
(phase / "reviews/C07-FINAL-GATE.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"gatePassed": True, "scores": [review["overallPhase1Score"] for review in reviews], "verifiedFrozenEntries": 48, "manifestSha256": manifest_sha, "ownerCheckpointAccepted": False}))
