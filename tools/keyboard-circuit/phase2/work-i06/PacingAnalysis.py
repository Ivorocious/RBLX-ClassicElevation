"""Account for saved pacing receipts without treating probe timings as human results."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
from collections import defaultdict
from pathlib import Path


DISTRICTS = {
    **dict.fromkeys(("O01", "H02", "O02", "H03", "CP1"), "S01"),
    **dict.fromkeys(("O03", "H04", "H05", "O04", "CP2"), "S02"),
    **dict.fromkeys(("O05", "H06", "H07", "O06", "CP3", "X02"), "S03"),
    **dict.fromkeys(("O07", "H08", "H01", "O08"), "S04"),
    "F00": "Return", "F01": "Return",
}


def distance(a, b):
    return math.hypot(a[0] - b[0], a[2] - b[2])


def district(label):
    match = re.match(r"(F00|F01|CP[123]|[OHX]\d\d)(?:→(\w+))?", label)
    if not match:
        return "Other"
    first, after = match.groups()
    if after and first in {"F00", "CP1", "CP2", "CP3"}:
        return DISTRICTS.get(after, "Other")
    return DISTRICTS.get(first, "Other")


def analyze_old(path):
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    report, records = data["report"], data["records"]
    categories = defaultdict(lambda: dict(seconds=0.0, endpointStuds=0.0, records=0))
    portions = defaultdict(lambda: dict(moveSeconds=0.0, waitSeconds=0.0, endpointStuds=0.0))
    for row in records:
        label = row["label"]
        category = next((name for name in ("takeoff", "jump", "center") if label.endswith(" " + name)), "walk")
        if "back side" in label or "forward crossing" in label:
            category = "gateWalk"
        travelled = distance(row["start"], row["finish"])
        category_row = categories[category]
        category_row["seconds"] += row["elapsed"]
        category_row["endpointStuds"] += travelled
        category_row["records"] += 1
        portion = portions[district(label)]
        portion["moveSeconds"] += row["elapsed"]
        portion["endpointStuds"] += travelled
    waits = defaultdict(float)
    for row in report["waits"]:
        label = row["label"]
        kind = "carrying" if "carried to exit" in label else "freshWindow" if row.get("freshWindow") else "otherHazard" if label.startswith("H") else "serverConfirmation"
        waits[kind] += row["elapsed"]
        portions[district(label)]["waitSeconds"] += row["elapsed"]
    move_seconds = sum(row["elapsed"] for row in records)
    wait_seconds = sum(row["elapsed"] for row in report["waits"])
    displacement = sum(distance(row["start"], row["finish"]) for row in records)
    return {
        "source": path.as_posix(), "sourceSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "fixtureSeconds": report["elapsed"], "continuousSeconds": report["continuousSeconds"],
        "setupSeconds": report["elapsed"] - report["continuousSeconds"],
        "moveSeconds": move_seconds, "waitSeconds": wait_seconds,
        "continuousUnassignedSeconds": report["continuousSeconds"] - move_seconds - wait_seconds,
        "joinsSeconds": sum(row["elapsed"] for row in report["joins"]),
        "joins": [{key: row[key] for key in ("from", "to", "connectors", "elapsed")} for row in report["joins"]], "movementCategories": dict(categories),
        "waitCategories": dict(waits), "districts": dict(portions),
        "endpointDisplacementStuds": displacement,
        "chosenEndpointDisplacementAt16Seconds": displacement / 16,
        "boundary": "Endpoint sums underestimate sampled travel, but describe this chosen path, not the shortest legal route. Center time includes real forward travel; fresh-window time includes necessary waiting. Neither entire category is removable overhead. Carrying is necessary travel, not idle fixture waste.",
    }


def compare_pair(normal_path, expert_path):
    normal = json.loads(normal_path.read_text(encoding="utf-8-sig"))
    expert = json.loads(expert_path.read_text(encoding="utf-8-sig"))
    normal, expert = normal.get("report", normal), expert.get("report", expert)
    reasons = []
    for report, route in ((normal, "normal"), (expert, "x02")):
        if not report.get("passed") or report.get("routeChoice") != route or not report.get("pairedX02"):
            reasons.append(f"{route} lacks a passing paired fixture run")
        if report.get("recoveries"):
            reasons.append(f"{route} contains recovery records")
    a, b = normal.get("branchComparison"), expert.get("branchComparison")
    if not a or not b or "elapsed" not in a or "elapsed" not in b:
        return dict(comparable=False, reasons=reasons + ["Missing complete branch interval"])
    position_difference = distance(a["before"]["root"], b["before"]["root"])
    if position_difference > .75:
        reasons.append("Common H07 exit positions differ by more than .75 studs")
    for key in ("walkSpeed", "jumpHeight", "useJumpPower", "gravity"):
        if normal["movement"].get(key) != expert["movement"].get(key):
            reasons.append("Movement settings differ: " + key)
    for key in ("candidate", "iteration", "revision", "layoutRevision", "userId"):
        if normal.get(key) != expert.get(key):
            reasons.append("Candidate or player identity differs: " + key)
    for segment in (a, b):
        if segment["before"].get("speed", float("inf")) >= .5:
            reasons.append("Common departure was not at standstill")
        if segment.get("after", {}).get("nextGate") != "F01":
            reasons.append("Branch interval does not end at authoritative CP3 acceptance")
    if a["before"].get("nextGate") != "CP3" or b["before"].get("nextGate") != "CP3":
        reasons.append("Branch intervals did not both start with CP3 pending")
    return dict(comparable=not reasons, reasons=reasons, normalSeconds=a["elapsed"], expertSeconds=b["elapsed"],
                expertBenefitSeconds=a["elapsed"] - b["elapsed"], startPositionDifferenceStuds=position_difference,
                boundary="Same automated controller/common departure and authoritative CP3 endpoint; no human shortcut benefit claim. Both branch lines are static after H07. Review per-run support/landing records before accepting the comparison.")


def analyze_efficient(path):
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    report = data.get("report", data)
    operations = report.get("operations", [])
    categories = defaultdict(float)
    ride_phases = defaultdict(float)
    for operation in operations:
        if operation.get("continuous"):
            categories[operation["kind"]] += operation.get("elapsed", 0)
        for phase, seconds in operation.get("ridePhaseSeconds", {}).items():
            ride_phases[phase] += seconds
    records = report.get("records", data.get("records", []))
    return dict(source=path.as_posix(), sourceSha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                passed=report.get("passed"), routeChoice=report.get("routeChoice"), requestedLaps=report.get("requestedLaps", 1),
                fixtureSeconds=report.get("elapsed"), continuousSeconds=report.get("continuousSeconds"),
                perDistrict=report.get("districts"), laps=report.get("laps", []), categories=dict(categories), ridePhaseSeconds=dict(ride_phases),
                sampledPathStuds=report.get("sampledPathStuds"), airLandingHoldSeconds=sum(row.get("airLandingHoldSeconds", 0) for row in records),
                takeoffSettleSeconds=sum(row.get("elapsed", 0) for row in records if row.get("controlHold")),
                gates=len(report.get("gates", [])), recoveries=report.get("recoveries", []), planningTarget=report.get("targetSeconds"), withinPlanningTarget=report.get("withinPlanningTarget"),
                boundary="Uses actual completed/failed fixture records. Takeoff settling is counted inside move time and shown as a subset. Move, wait and physical ride phases are separate; sampled path is not shortest-path or human pacing proof.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("receipt", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--expert", type=Path)
    parser.add_argument("--efficient", action="store_true")
    args = parser.parse_args()
    result = compare_pair(args.receipt, args.expert) if args.expert else analyze_efficient(args.receipt) if args.efficient else analyze_old(args.receipt)
    encoded = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)


if __name__ == "__main__":
    main()
