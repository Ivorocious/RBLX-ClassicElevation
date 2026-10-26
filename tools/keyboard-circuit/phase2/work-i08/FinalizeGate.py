import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
folder = root / "docs/artifacts/keyboard-circuit/phase2"
candidate = "Workspace.KeyboardCircuit_P2_I08_TwoLaps01"
revision = "KC_P2_I08_01"


def read(name):
    return json.loads((folder / name).read_text(encoding="utf-8"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def strings(value):
    if isinstance(value, dict):
        for child in value.values():
            yield from strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from strings(child)
    elif isinstance(value, str):
        yield value


freeze_name = "P2-I08-source-freeze-02.json"
freeze = read(freeze_name)
freeze_sha = sha(folder / freeze_name)
frozen = {row["path"]: row for row in freeze["entries"]}
assert len(frozen) == 35
mismatches = [path for path, row in frozen.items() if sha(root / path) != row["sha256"] or (root / path).stat().st_size != row["bytes"]]
assert not mismatches, mismatches

reviews = []
for number, focus in [(1, "visual"), (2, "route"), (3, "hazards"), (4, "experience"), (5, "engineering")]:
    identity = f"I08-R{number}-{focus}"
    path = folder / "reviews" / f"{identity}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    reviewed_candidate = data["candidate"] if isinstance(data["candidate"], str) else data["candidate"]["path"]
    reviewed_revision = data.get("revision") or data["candidate"]["revision"]
    assert reviewed_candidate == candidate and reviewed_revision == revision, identity
    assert data["score"] >= 8.5 and not data["blockers"] and data.get("blockerCount", 0) == 0, identity
    values = set(strings(data))
    assert freeze_sha in values and any(value.endswith(freeze_name) for value in values), identity
    reviews.append({"identity": identity, "agent": f"/root/kc_i08_r{number}_{focus}", "model": "gpt-6.1-sol", "reasoningEffort": "high", "candidate": candidate, "revision": revision, "score": data["score"], "passed": True, "blockerCount": 0, "finalFreeze": freeze_name, "finalFreezeSha256": freeze_sha, "reviewFile": f"reviews/{path.name}", "reviewSha256": sha(path), "notesSha256": sha(path.with_suffix(".md"))})

edit_name = "P2-I08-post-review-edit-agreement-02.json"
edit = read(edit_name)
assert edit["passed"] and edit["edit"] and edit["requiredLaps"] == 2 and edit["activeKeyboardModels"] == 1
assert edit["descendants"] == 14028 and edit["parts"] == 6992 and edit["workspaceParts"] == 16901
assert edit["olderCourses"] == 9 and edit["archivedParts"] == 47398 and edit["archivedDescendants"] == 96360 and edit["placementOffsetStuds"] == 0
assert len(edit["rows"]) == 19
names = {path.name.removesuffix(".server.luau").removesuffix(".client.luau").removesuffix(".luau"): str(path.relative_to(root)).replace("\\", "/") for path in (root / "tools/keyboard-circuit/phase2/work-i08/sources").glob("*.luau")}
globals = {
    "ServerScriptService.Services.StudioDevService": "src/ServerScriptService/Services/StudioDevService.luau",
    "StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController": "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau",
    "StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview": "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
}
for row in edit["rows"]:
    path = globals[row["path"]] if row["path"] in globals else names[row["name"]]
    assert row["sha256"] == frozen[path]["sha256"] and row["bytes"] == frozen[path]["bytes"], path

normal = read("P2-I08-normal-two-lap-summary-01.json")
expert = read("P2-I08-expert-two-lap-summary-01.json")
for run in [normal, expert]:
    assert run["passed"] and run["requiredLaps"] == 2 and run["recoveries"] == 0 and run["naturalGates"] == 10 and run["setupCalls"] == 1 and run["fixtureHoldSeconds"] == 0
    lower, upper = run["targetSeconds"]
    assert lower <= run["continuousSeconds"] <= upper and lower <= run["serverEnrollmentSeconds"] <= upper
    assert sha(folder / run["rawTrace"]) == run["rawSha256"]
    assert all(run["cleanup"].values())
assert expert["precisionLandings"] == 68

native = read("P2-I08-native-recovery-01.json")
model = folder / "native/KeyboardCircuit_P2_I08_TwoLaps01.rbxm"
assert native["roundTrip"]["passed"] and native["freshSourceRebuild"]["passed"]
assert model.stat().st_size == 174243 and sha(model) == native["nativeSha256"]
archive = read("P2-I08-archive-01.json")
assert archive["passed"] and len(archive["oldCourses"]) == 9 and len(archive["olderPreparation"]) == 17
assert sum(row["parts"] for row in archive["oldCourses"]) == 47398
# The nine-course archival total already includes the former active Final06.
net_removed = archive["partsRemovedFromWorkspace"] - edit["parts"]
assert net_removed == 40406
correction = read("P2-I08-receipt-path-correction-01.json")
assert correction["passed"] and correction["gameSourceChanges"] == 0 and len(correction["changedInputs"]) == 1
motion = read("P2-I08-motion-boundaries-01.json")
assert motion["passed"] and motion["revision"] == revision and sum(row["samples"] for row in motion["checks"].values()) == 14412
comparison = read("P2-I08-route-comparison-01.json")
assert comparison["passed"] and len(comparison["intervals"]) == 8
assert all(row["secondsSaved"] > 0 and row["expertSampledPathStuds"] < row["normalSampledPathStuds"] for row in comparison["intervals"])

artifacts = [freeze_name, "P2-I08-freeze-agreement-02.json", "P2-I08-normal-two-lap-summary-01.json", "P2-I08-expert-two-lap-summary-01.json", normal["rawTrace"], expert["rawTrace"], "P2-I08-route-comparison-01.json", "P2-I08-archive-01.json", "P2-I08-dev-control-01.json", "P2-I08-native-feature-audit-01.json", "P2-I08-recovery-footprints-01.json", "P2-I08-focused-recovery-01.json", "P2-I08-focused-held-press-01.json", "P2-I08-focused-bypass-01.json", "P2-I08-native-recovery-01.json", edit_name, "P2-I08-receipt-path-correction-01.json", "P2-I08-motion-boundaries-01.json", "P2-I08-FINAL-REPORT-01.md", "P2-I08-REVIEW-BRIEF-01.md", "native/KeyboardCircuit_P2_I08_TwoLaps01.rbxm", "native/I08-TwoLap-Normal-Native.jpg"]
gate = {
    "candidate": candidate, "revision": revision, "layoutRevision": "KC_LAYOUT_P2_I08_01", "date": "2026-10-08", "status": "complete_technical_pass", "passed": True, "requiredLaps": 2,
    "requiredIndividualScore": 8.5, "reviewerCount": 5, "helperAgents": 0, "allIndividualScoresPass": True, "allZeroBlockers": True, "reviews": reviews,
    "frozenInputCount": 35, "sourceFreeze": freeze_name, "sourceFreezeSha256": freeze_sha, "postReviewMismatches": mismatches, "postReviewEditAgreement": edit_name, "nativeSources": 19,
    "normalContinuousSeconds": normal["continuousSeconds"], "expertContinuousSeconds": expert["continuousSeconds"], "normalServerEnrollmentSeconds": normal["serverEnrollmentSeconds"], "expertServerEnrollmentSeconds": expert["serverEnrollmentSeconds"],
    "clockBoundary": "Enrollment includes startup/setup before continuous movement. Do not substitute the continuous value for the server HUD time.",
    "fullTraceHashes": {"normal": normal["rawSha256"], "expert": expert["rawSha256"]}, "nativeExportSha256": native["nativeSha256"], "nativeExportBytes": 174243,
    "archivedOlderCourses": 9, "archive": archive["archive"], "oldPartsRemovedFromWorkspace": 47398, "netWorkspacePartReduction": net_removed, "activeWorkspaceKeyboardCourses": 1, "unrelatedMapsPreserved": archive["unrelatedPreserved"],
    "studioId": "df0bbff3-e155-4625-90f8-03fd79e1e177", "studioMode": "Edit",
    "automation": "Owned tests finished; movement/render bindings released; participant detached through Lobby; owned solo Play stopped. No computer or camera control.",
    "ownerTest": "Play > F6 > Keyboard Circuit - 2 Laps. Same action restarts; Lobby exits.", "report": "P2-I08-FINAL-REPORT-01.md",
    "evidence": [{"path": name, "bytes": (folder / name).stat().st_size, "sha256": sha(folder / name)} for name in artifacts],
    "boundary": "Five independent final I08 judgments bound to the same freeze02; no inherited, averaged or coerced score. Two fresh clean automated two-lap runs and focused tests. Human pacing/audio satisfaction, exhaustive shortcuts,20-racer/device/FPS remain unverified. Only older Keyboard Circuit archived with geometry/source retained. No Phase3, whole-place save, publication, persistent-player-data or economy changes.",
}
(folder / "P2-I08-FINAL-GATE-01.json").write_text(json.dumps(gate, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"passed": True, "scores": [review["score"] for review in reviews], "blockers": 0, "inputs": 35, "nativeSources": 19, "netWorkspacePartsRemoved": net_removed, "output": "P2-I08-FINAL-GATE-01.json"}))
