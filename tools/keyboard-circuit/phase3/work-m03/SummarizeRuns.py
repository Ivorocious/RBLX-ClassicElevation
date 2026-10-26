from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
folder = root / "docs/artifacts/keyboard-circuit/phase3"
runs = {}
for route in ("normal", "expert"):
    path = folder / f"P3-M03-{route}-two-lap-01.json"
    raw = path.read_bytes()
    data = json.loads(raw)
    assert data["passed"] and data["requestedLaps"] == 2
    if route == "normal": assert data["withinPlanningTarget"]
    assert len(data["midpointReceipts"]) == 8
    assert data["setupCalls"] == 1 and data["setup"]["attempts"] == 1
    assert data["finalState"]["recoveries"] == 0 and data["finalState"]["finished"]
    assert data["serverState"]["requiredLaps"] == 2 and data["serverState"]["completedLaps"] == 2 and data["serverState"]["finished"]
    assert len(data["gates"]) == 10 and data["fixtureHoldSeconds"] == 0
    assert all(row["arrived"] and row["finishSupport"] == row["expectedSupport"] for row in data["records"])
    movement = data["movement"]
    assert abs(movement["walkSpeed"] - 16) < .001 and abs(movement["jumpHeight"] - 7.2) < .001 and not movement["useJumpPower"] and abs(movement["gravity"] - 196.2) < .001
    runs[route] = data
    summary = {
        "passed": True, "candidate": data["candidate"], "revision": data["prototypeRevision"], "route": route,
        "requiredLaps": 2, "continuousSeconds": data["continuousSeconds"], "lapSeconds": [row["elapsed"] for row in data["laps"]],
        "serverEnrollmentSeconds": data["serverState"]["elapsed"], "serverLapSeconds": data["serverState"]["lapTimes"],
        "targetSeconds": data.get("targetSeconds"), "withinPlanningTarget": data.get("withinPlanningTarget"), "naturalGates": len(data["gates"]), "naturalMidpoints": len(data["midpointReceipts"]), "expertPacingPriority": data["expertPacingPriority"], "previousExpertTargetSeconds": data["previousExpertTargetSeconds"],
        "sequences": len(data["sequences"]), "joins": len(data["joins"]), "precisionLandings": sum(row.get("landings", 0) for row in data["sequences"]),
        "setupCalls": data["setupCalls"], "recoveries": data["finalState"]["recoveries"], "moveSeconds": data["moveSeconds"],
        "waitSeconds": data["waitSeconds"], "carrySeconds": data["carrySeconds"], "fixtureHoldSeconds": data["fixtureHoldSeconds"],
        "accountingResidualSeconds": data["unassignedContinuousSeconds"], "records": len(data["records"]), "movement": movement,
        "cleanup": data["cleanup"], "rawTrace": path.name, "rawSha256": hashlib.sha256(raw).hexdigest(),
        "boundary": "Clean automated continuous two-lap movement with natural ordered server crossings; outside setup clock is separately disclosed. Not typical-human, crowd, device or FPS certification.",
    }
    (folder / f"P3-M03-{route}-two-lap-summary-01.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

branches = [("X03", "H02", "CP1"), ("X02", "H06", "CP3")]
comparison = []
for lap in (1, 2):
    for branch, departure, gate in branches:
        n = runs["normal"]
        e = runs["expert"]
        ns = next(row for row in n["sequences"] if row["id"] == departure and row["lap"] == lap)
        es = next(row for row in e["sequences"] if row["id"] == branch and row["lap"] == lap)
        ng = next(row for row in n["checkpoints"] if row["id"] == gate and row["lap"] == lap)
        eg = next(row for row in e["checkpoints"] if row["id"] == gate and row["lap"] == lap)
        normal_seconds = ng["after"]["elapsed"] - ns["after"]["elapsed"]
        expert_seconds = eg["after"]["elapsed"] - es["before"]["elapsed"]
        def length(data, start, end):
            return sum(row["sampledPathStuds"] for row in data["operations"] if row["before"]["elapsed"] >= start - .001 and row["after"]["elapsed"] <= end + .001)
        normal_length = length(n, ns["after"]["elapsed"], ng["after"]["elapsed"])
        expert_length = length(e, es["before"]["elapsed"], eg["after"]["elapsed"])
        assert normal_seconds > expert_seconds and normal_length > expert_length > 0
        comparison.append({"branch": branch, "lap": lap, "from": departure, "to": gate, "normalSeconds": normal_seconds,
                           "expertSeconds": expert_seconds, "secondsSaved": normal_seconds - expert_seconds,
                           "normalSampledPathStuds": normal_length, "expertSampledPathStuds": expert_length})
assert runs["expert"]["continuousSeconds"] < runs["normal"]["continuousSeconds"]
result = {"passed": True, "normalSeconds": runs["normal"]["continuousSeconds"], "expertSeconds": runs["expert"]["continuousSeconds"], "wholeRaceSecondsSaved": runs["normal"]["continuousSeconds"]-runs["expert"]["continuousSeconds"], "candidate": runs["normal"]["candidate"], "revision": runs["normal"]["prototypeRevision"], "intervals": comparison,
          "boundary": "Comparable departure-to-natural-gate intervals derived from the two unchanged full traces. Unpaired hazard arrivals; not controlled same-phase or human savings."}
(folder / "P3-M03-route-comparison-01.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"normalSeconds": runs["normal"]["continuousSeconds"], "expertSeconds": runs["expert"]["continuousSeconds"], "branchIntervalsPassed": len(comparison)}))
