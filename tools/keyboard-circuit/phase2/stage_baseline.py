import hashlib
import json
from pathlib import Path

root = Path.cwd().resolve()
base = root / "docs/artifacts/keyboard-circuit"
phase = base / "phase2"
staged = root / "tools/keyboard-circuit/phase2/staged"
phase.mkdir(parents=True, exist_ok=True)
staged.mkdir(parents=True, exist_ok=True)
manifest = json.loads((base / "phase1/C08-evidence-manifest.json").read_text(encoding="utf-8"))
gate = json.loads((base / "phase1/reviews/C08-FINAL-GATE.json").read_text(encoding="utf-8"))
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert gate["reviewGatePassed"] and gate["ownerCheckpointAccepted"]
assert len(gate["reviews"]) == 5
assert digest(base / "phase1/C08-evidence-manifest.json") == gate["manifestSha256"]
for item in manifest["files"]:
    path = root / item["path"]
    assert path.stat().st_size == item["bytes"] and digest(path) == item["sha256"], item["path"]

package = json.loads((base / "phase1/C08-source-package.json").read_text(encoding="utf-8"))
imports = {}
for name in ["Parts", "ConfigSnapshot", "KeyboardCircuitAudio", "KeyboardCircuitFeedback"]:
    destination = staged / (name + ".luau")
    value = package[name].replace("\r\n", "\n").rstrip() + "\n"
    if destination.exists():
        assert destination.read_text(encoding="utf-8") == value, destination
    else:
        destination.write_text(value, encoding="utf-8", newline="\n")
    imports[name] = {"path": destination.relative_to(root).as_posix(), "sha256": digest(destination), "origin": "Accepted C08 source package; unchanged"}

forward = root / "src/ReplicatedStorage/Shared/ForwardGate.luau"
destination = staged / "ForwardGate.luau"
value = forward.read_text(encoding="utf-8").replace("\r\n", "\n").rstrip() + "\n"
if destination.exists():
    assert destination.read_text(encoding="utf-8") == value
else:
    destination.write_text(value, encoding="utf-8", newline="\n")
imports["ForwardGate"] = {"path": destination.relative_to(root).as_posix(), "sha256": digest(destination), "origin": forward.relative_to(root).as_posix()}

receipt = {
    "candidate": "KC_P2_C01", "phase": 2, "state": "Offline staging; owner Play preserved",
    "lead": {"identity": "/root", "model": "gpt-6.1-sol", "reasoningEffort": "max", "verifiedTurn": "01a116db-c292-7fc0-8e52-e72004b0c5c8"},
    "helpers": [
        {"identity": "/root/kc_p2_route_xhigh", "model": "gpt-6.1-sol", "reasoningEffort": "xhigh", "role": "Route and all eight mechanism implementations"},
        {"identity": "/root/kc_p2_integration_xhigh", "model": "gpt-6.1-sol", "reasoningEffort": "xhigh", "role": "Progression, readiness and integration checks"},
    ],
    "reviewers": [{"identity": item["canonicalAgentIdentity"], "model": "gpt-6.1-sol", "reasoningEffort": "high", "phase2State": "Not started; fresh review follows lead checks"} for item in gate["reviews"]],
    "commissionSha256": digest(base / "PHASE2_START.md"),
    "acceptedC08ManifestSha256": gate["manifestSha256"], "verifiedC08FrozenEntries": len(manifest["files"]),
    "imports": imports, "wholePlaceSaved": False, "published": False,
}
(phase / "P2-C01-baseline-preflight.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8", newline="\n")

brief = base / "COURSE_BRIEF.md"
lines = brief.read_text(encoding="utf-8").splitlines()
changes = {
    "- **Status:**": "- **Status:** Phase 2 is active. Source/runtime metadata confirms the lead is gpt-6.1-sol / max. The two requested ExtraHigh helpers are implementing offline; all 82 accepted C08 frozen entries were reverified. Owner Play remains active and untouched. New candidate KC_P2_C01 is staged separately; no installed course or Phase 2 score is claimed yet.",
    "- **Helpers/researchers:**": "- **Helpers/researchers:** exactly two active gpt-6.1-sol / xhigh helpers: /root/kc_p2_route_xhigh owns staged Layout/Mechanisms/Motion/MechanismRuntime and route tests; /root/kc_p2_integration_xhigh owns staged Progression/Phase2Readiness/KeyboardCircuitPhase2Preview and integration tests. They were spawned with those exact settings and may implement within their ownership. Lead owns Course/static patterns/Session/assembly and final judgment.",
    "- **Reviewers:**": "- **Reviewers:** original identities /root/kc_r1_visual, /root/kc_r2_route, /root/kc_r3_hazards, /root/kc_r4_experience and /root/kc_r5_engineering; each gpt-6.1-sol / high. Fresh Phase 2 reviews have not started. Every judge must independently score the same final Phase 2 candidate at least 8.5/10 with zero blockers. C08 scores and helper reports cannot substitute.",
    "- **Next action:**": "- **Next action:** prepare the full connected Phase 2 source offline, then recheck Edit, owner changes and available space before installation. Prove native traversal, eight mechanisms, ordered three-lap progression, recovery, readiness lifecycle and resource costs before the original five review the same frozen candidate.",
    "- **Operations / reviews in flight:**": "- **Operations / reviews in flight:** two ExtraHigh implementation helpers active. Studio fec3170c-94e4-4a1d-8f12-5641fdaffd1c is Obby Tournament, place85558151074819/universe10191126818, currently owner Play. Owner is testing the C08 comparison area. No stop, runtime mutation or camera change performed. Asked owner to confirm Edit when their test is finished. [Baseline/team receipt](phase2/P2-C01-baseline-preflight.json) records source integrity and exact assignments.",
}
for index, line in enumerate(lines):
    for prefix, value in changes.items():
        if line.startswith(prefix):
            lines[index] = value
brief.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"phase2Active": True, "frozenC08EntriesVerified": len(manifest["files"]), "stagedAcceptedImports": len(imports), "helpers": 2, "phase2ReviewsStarted": 0}))
