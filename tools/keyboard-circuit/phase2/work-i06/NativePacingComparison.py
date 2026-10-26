"""Compare completed branch intervals without claiming paired or full Expert proof."""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path


ROOT = Path.cwd()
ARTIFACTS = ROOT / "docs/artifacts/keyboard-circuit/phase2"
OUTPUT = ROOT / "tools/keyboard-circuit/phase2/work-i06/Pacing-native08-09-analysis.json"


def horizontal_distance(first, second):
    return math.hypot(first[0] - second[0], first[2] - second[2])


def interval(report, branch, departure, gate, expert):
    if expert:
        sequence = next(row for row in report["sequences"] if row["id"] == branch)
        assert sequence["passed"] and sequence["landings"] == (24 if branch == "X01" else 12)
        before = sequence["before"]
    else:
        join = next(row for row in report["joins"] if row["from"] == departure)
        assert join["passed"]
        before = join["before"]
    checkpoint = next(row for row in report["checkpoints"] if row["id"] == gate)
    after = checkpoint["after"]
    assert checkpoint["passed"] and before["nextGate"] == gate
    assert before["recoveries"] == after["recoveries"] == 0
    assert after["nextGate"] == ("CP3" if gate == "CP2" else "F01")
    operations = [row for row in report["operations"]
                  if row["before"]["elapsed"] >= before["elapsed"] - .002
                  and row["after"]["elapsed"] <= after["elapsed"] + .002]
    assert operations and operations[-1]["label"] == gate + " authoritative acceptance"
    categories = {}
    for operation in operations:
        assert not operation.get("interrupted")
        categories[operation["kind"]] = categories.get(operation["kind"], 0) + operation["elapsed"]
    seconds = after["elapsed"] - before["elapsed"]
    accounting_error = seconds - sum(categories.values())
    assert abs(accounting_error) < .005
    first_record, last_record = operations[0]["firstRecord"], operations[-1]["lastRecord"]
    records = report["records"][first_record - 1:last_record]
    gate_record = next(row for row in report["gates"] if row["gate"] == gate)
    return dict(seconds=seconds, serverGateSeconds=gate_record["at"] - before["at"],
                before=before, after=after, categories=categories,
                sampledPathStuds=sum(row["sampledPathStuds"] for row in operations),
                takeoffSettleSeconds=sum(row.get("takeoffSettleSeconds", 0) for row in operations),
                jumpRecords=sum(row.get("jump", False) for row in records),
                accountingErrorSeconds=accounting_error,
                definition="Common encounter exit departure through the forward checkpoint crossing and client-confirmed authoritative acceptance")


def main():
    paths = {name: ARTIFACTS / filename for name, filename in {
        "normal": "P2-C01-efficient-normal-08.json", "expert": "P2-C01-efficient-expert-09.json"}.items()}
    reports = {name: json.loads(path.read_text(encoding="utf-8-sig")) for name, path in paths.items()}
    normal, expert = reports["normal"], reports["expert"]
    assert normal["passed"] and not expert["passed"]
    for key in ("candidate", "iteration", "revision", "layoutRevision", "movement"):
        assert normal[key] == expert[key], key
    branches = {}
    for branch, departure, gate in (("X01", "H04", "CP2"), ("X02", "H07", "CP3")):
        first = interval(normal, branch, departure, gate, False)
        second = interval(expert, branch, departure, gate, True)
        branches[branch] = dict(normal=first, expert=second,
                                observedExpertPenaltySeconds=second["seconds"] - first["seconds"],
                                observedExpertBenefitSeconds=first["seconds"] - second["seconds"],
                                departurePositionDifferenceStuds=horizontal_distance(first["before"]["root"], second["before"]["root"]),
                                mergePositionDifferenceStuds=horizontal_distance(first["after"]["root"], second["after"]["root"]),
                                paired=False,
                                boundary="Different players, arrival phases and initial delays; normal X01 alternative includes phase-dependent lift carrying. These completed intervals are descriptive, not a paired causal or human shortcut benefit.")
    connector, takeoff, failed_jump = expert["records"][-3:]
    assert connector["label"] == "H08→H01 connector1 jump" and connector["arrived"]
    assert takeoff["label"] == "H08→H01 arrival takeoff" and takeoff["arrived"]
    assert failed_jump["label"] == "H08→H01 arrival jump" and not failed_jump["arrived"]
    recovery = next(row for row in expert["recoveries"] if row["reason"] == "SupportLanding")
    upward_air = [row for row in failed_jump["samples"] if row["floor"] == "Air" and row["velocity"][1] > 1]
    assert upward_air
    result = dict(
        sources={name: dict(path=path.relative_to(ROOT).as_posix(), sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for name, path in paths.items()},
        normal=dict(passed=True, continuousSeconds=normal["continuousSeconds"], moveSeconds=normal["moveSeconds"],
                    waitSeconds=normal["waitSeconds"], carrySeconds=normal["carrySeconds"],
                    takeoffSettleSeconds=normal["takeoffSettleSeconds"], sampledPathStuds=normal["sampledPathStuds"],
                    sequences=len(normal["sequences"]), joins=len(normal["joins"]), gates=len(normal["gates"]), recoveries=len(normal["recoveries"]),
                    secondsOver120=normal["continuousSeconds"] - 120),
        expert=dict(passed=False, continuousSecondsBeforeFailure=expert["continuousSeconds"],
                    completedSequences=sum(row.get("passed", False) for row in expert["sequences"]),
                    completedGates=len(expert["gates"]), recoveryReason=recovery["reason"],
                    unfinished=["H08→H01 arrival", "H01", "H01→O08", "O08", "O08→F01", "F01", "F01→F00", "F00"]),
        arrivalDelays={name: report["arrivalDelaySeconds"] for name, report in reports.items()},
        playerUserIds={name: report["userId"] for name, report in reports.items()},
        branches=branches,
        readiness=dict(connectorFinishVelocity=connector["finishVelocity"], connectorFinish=connector["finish"],
                       takeoffSeconds=takeoff["elapsed"], nextJumpStartVelocity=failed_jump["startVelocity"],
                       nextJumpLaunchSettleSeconds=failed_jump["launch"]["settleSeconds"],
                       firstUpwardAirSample=upward_air[0], recoverySecondsAfterJump=recovery["at"] - failed_jump["at"],
                       interpretation="The next jump fired. The prior landing was accepted while rising; tightening fixture readiness is justified. Exact server blocker/pose is absent, so recovery causation and native repair success remain unresolved."),
        boundary="One successful normal lap and one unfinished Expert attempt, not a full three-lap race or human typicality. Settling stays counted inside movement. Both branches were slower in these unpaired observations; target fit and a beneficial Expert route are not demonstrated.",
    )
    OUTPUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"normalSeconds":normal["continuousSeconds"], "expertFailureSeconds":expert["continuousSeconds"],
                      "branches":{name:{key:row[key] for key in ("observedExpertPenaltySeconds", "departurePositionDifferenceStuds", "mergePositionDifferenceStuds")} for name,row in branches.items()},
                      "output":OUTPUT.relative_to(ROOT).as_posix()}, indent=2))


if __name__ == "__main__":
    main()
