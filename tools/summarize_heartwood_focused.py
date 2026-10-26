"""Classify saved HA03 focused evidence without running Studio or changing game source."""

import argparse
import hashlib
import json
import math
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


BUILD = "HA_V1_03"
COUNTERS = ("acknowledgements", "releases", "cancels", "hits")
PREFIX = "Workspace.RaceCourse."
SAFE_POINTS = ("j1", "j2", "refuge", "j3", "j4", "p0", "p1", "p2", "p3",
               "pod_entry", "pod_middle", "pod_exit")
STATE_FIELDS = ("position", "support", "grounded", "checkpoint", "status", "official",
                "recoveryUntil", "diagnostics", "supportMethod", "distance")
SCOPE = (
    "Read-only classification of saved solo Studio observations. Most probes use server-driven "
    "movement with real client cue acknowledgements and one initial setup placement/checkpoint. "
    "Normal-input is one recorded W-key start check. No new physics checks were run. These files "
    "do not establish full human route acceptance, difficulty, cue readability, whole-body flight "
    "clearance, device performance, multiplayer or network-delay behavior."
)


def numeric(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def vector(value):
    if isinstance(value, dict):
        value = [value.get(str(i)) for i in (1, 2, 3)]
    return value if isinstance(value, list) and len(value) == 3 and all(map(numeric, value)) else None


def horizontal(a, b):
    a, b = vector(a), vector(b)
    return math.hypot(a[0] - b[0], a[2] - b[2]) if a and b else None


def same(actual, expected):
    return actual == expected if actual is not None else None


def near(actual, expected, tolerance):
    return abs(actual - expected) <= tolerance if numeric(actual) else None


def within(actual, low, high):
    return low <= actual <= high if numeric(actual) else None


def supported(state, paths):
    actual = state.get("support")
    if actual is None or state.get("grounded") is None:
        return None
    return state["grounded"] is True and any(actual == path or actual.startswith(path + ".") for path in paths)


def compact(state):
    return {key: state[key] for key in STATE_FIELDS if key in state}


def deltas(before, after):
    b, a = before.get("diagnostics", {}), after.get("diagnostics", {})
    return {key: a[key] - b[key] if numeric(a.get(key)) and numeric(b.get(key)) else None for key in COUNTERS}


def recovery_delta(before, after):
    a, b = after.get("recoveryUntil"), before.get("recoveryUntil")
    return a - b if numeric(a) and numeric(b) else None


def add(case, name, condition):
    case["checks"].append({"criterion": name, "status": "passed" if condition is True else "incomplete" if condition is None else "failed"})


def finish(case, success="passed"):
    statuses = [check["status"] for check in case["checks"]]
    case["verdict"] = "failed" if "failed" in statuses else "incomplete" if "incomplete" in statuses or not statuses else success
    return case


def load(path, root):
    evidence = {"file": path.relative_to(root).as_posix() if path.is_relative_to(root) else str(path)}
    if not path.exists():
        return None, {**evidence, "status": "missing", "sha256": None}
    raw = path.read_bytes()
    evidence["sha256"] = hashlib.sha256(raw).hexdigest()
    try:
        record = json.loads(raw)
        if not isinstance(record, dict):
            raise ValueError("Expected an object")
    except (ValueError, UnicodeError) as error:
        return None, {**evidence, "status": "invalid", "error": str(error)}
    result = record.get("result")
    result = result if isinstance(result, dict) else {}
    evidence.update({"status": "available", "scope": record.get("scope") or result.get("scope"), "id": record.get("id")})
    return record, evidence


def missing(case_id, evidence):
    return {"id": case_id, "verdict": "incomplete", "evidence": evidence, "checks": [], "limits": ["Missing or invalid raw evidence cannot be counted as a pass."]}


def sequence(case_id, record, evidence, command, expect_pass=True):
    result = record.get("result", {})
    before, after = result.get("before", {}), result.get("after", {})
    steps = result.get("steps", [])
    case = {"id": case_id, "evidence": evidence, "checks": [], "limits": [],
            "observed": {"outerOk": record.get("ok"), "resultPassed": result.get("passed"),
                         "elapsedSeconds": result.get("elapsed"), "before": compact(before), "after": compact(after),
                         "counterDeltas": deltas(before, after), "recoveryUntilDelta": recovery_delta(before, after),
                         "initialRepositions": result.get("initialRepositions"), "withinRunRepositions": result.get("withinRunRepositions")}}
    add(case, "outer command completed", same(record.get("ok"), True))
    add(case, "reported sequence result matches expected outcome", same(result.get("passed"), expect_pass))
    add(case, "no test placement inside the sequence", same(result.get("withinRunRepositions"), 0))
    add(case, "one initial setup placement is recorded", same(result.get("initialRepositions"), 1))
    ids = [step.get("id") for step in steps]
    expected_ids = [step["id"] for step in command["steps"]]
    add(case, "all requested steps were executed in the specified order", ids == expected_ids and result.get("completedSteps") == result.get("requestedSteps") == len(expected_ids))
    if expect_pass:
        add(case, "every recorded step reported passed", all(step.get("passed") is True for step in steps))
    states = [before, after] + [step.get("after", step) for step in steps]
    add(case, "official racer and expected checkpoint/status stay unchanged", all(state.get("official") is True and state.get("checkpoint") == command["expectCheckpoint"] and state.get("status") == command["expectStatus"] for state in states))
    add(case, "hazard-hit delta is zero", same(deltas(before, after)["hits"], 0))
    add(case, "recovery timestamp does not advance", same(recovery_delta(before, after), 0))
    case["observed"]["steps"] = [{"id": step.get("id"), "passed": step.get("passed"), "reason": step.get("reason"),
                                  "elapsedSeconds": step.get("elapsed"), **compact(step.get("after", step))} for step in steps]
    return case, result, steps


def warning(case_id, record, evidence, command):
    case, result, steps = sequence(case_id, record, evidence, command)
    index = int(case_id[-1])
    start = PREFIX + f"Decoration.S03_HangingGardens.P{index - 1}"
    end = PREFIX + f"Decoration.S03_HangingGardens.P{index}"
    wait, crossing = steps[0], steps[1]
    contact = crossing.get("firstLeafContact", {})
    add(case, "initial and phase-wait support are the expected permanent perch", supported(result.get("before", {}), [start]) and supported(wait, [start]))
    add(case, "first actual leaf support contact is Warning", same(contact.get("phase"), "Warning"))
    phase = contact.get("localPhase")
    add(case, "first contact local phase is at least 4 and below 6.8", (4 <= phase < 6.8) if numeric(phase) else None)
    add(case, "crossing arrives grounded on the next permanent perch", same(crossing.get("reason"), "arrived") and supported(crossing, [end]) and supported(result.get("after", {}), [end]))
    case["observed"]["firstLeafContact"] = contact
    case["limits"] = ["First support contact and arrival are observed; rendered cue readability and full-body trailing-edge clearance are not recorded."]
    return finish(case)


def stationary(case_id, record, evidence, command, petal=None):
    case, result, steps = sequence(case_id, record, evidence, command)
    before, after = result.get("before", {}), result.get("after", {})
    paths = [PREFIX + path for path in command["steps"][-1]["supports"]]
    states = [before, after] + steps
    add(case, "all observed supports are grounded within the specified station/pocket", all(supported(state, paths) is True for state in states))
    distances = [horizontal(before.get("position"), state.get("position")) for state in states]
    add(case, "sampled X/Z remain within 0.1 stud of the initial chosen point", all(numeric(d) and d <= .1 for d in distances))
    for counter, delta in deltas(before, after).items():
        add(case, counter + " delta is zero", same(delta, 0))
    waits = [step for step, recipe in zip(steps, command["steps"]) if recipe.get("waitLeaf") or recipe.get("waitPod") or recipe.get("waitPulseClear")]
    case["observed"]["waitDurationsSeconds"] = [step.get("elapsed") for step in waits]
    if any(step.get("waitLeaf") for step in command["steps"]):
        duration = sum(step["elapsed"] for step in waits[1:])
        add(case, "fresh Open to next fresh Open spans approximately nine seconds", near(duration, 9, .15))
        for step, recipe in zip(steps, command["steps"]):
            if recipe.get("waitLeaf"):
                add(case, step["id"] + " reaches its requested Open phase window", same(step.get("phaseAfter"), "Open") and within(step.get("localPhase"), recipe["leafPhaseMinimum"], recipe["leafPhaseMaximum"]))
    else:
        duration = waits[-1].get("elapsed")
        add(case, "second synchronized Clear wait spans approximately six seconds", near(duration, 6, .15))
        add(case, "both synchronized waits end Clear", all(step.get("phaseAfter") == "Clear" for step in waits))
    case["observed"]["completeCycleSeconds"] = duration
    case["observed"]["cycleToleranceSeconds"] = .15
    case["observed"]["maximumSampledHorizontalDrift"] = max(distances) if all(map(numeric, distances)) else None
    if petal:
        bloom, center, radius = petal
        exact = PREFIX + f"Decoration.S04_SanctuaryBough.Blooms.{bloom}.FlowerSurface"
        add(case, "initial/final support is the exact visible FlowerSurface", same(before.get("support"), exact) and same(after.get("support"), exact))
        radii = [horizontal(state.get("position"), center) for state in states]
        add(case, "all observed X/Z stay outside the active bloom radius", all(numeric(r) and r > radius for r in radii))
        case["observed"].update({"bloom": bloom, "activeRadius": radius, "sampledRadialDistances": radii})
        case["limits"].append("Counters record no acknowledgements, releases, cancels or hits during this interval; begin messages and rendered cue frames are not captured.")
    case["limits"].append("One stationary solo avatar and one complete cycle; no crowd-flow, human-control or repeated-run reliability claim.")
    return finish(case)


def bloom_edge(case_id, record, evidence, command):
    case, result, steps = sequence(case_id, record, evidence, command)
    before, after, flight = result.get("before", {}), result.get("after", {}), steps[0]
    bloom = "B2" if case_id.startswith("b2") else "XB"
    center = [-62, 140, 60] if bloom == "B2" else [-40, 136, 58]
    radius, expected_start = (9.85, 14) if bloom == "B2" else (2.85, 4.5)
    start_radius = horizontal(before.get("position"), center)
    add(case, "initial support is the bloom FlowerSurface", supported(before, [PREFIX + f"Decoration.S04_SanctuaryBough.Blooms.{bloom}.FlowerSurface"]))
    add(case, "initial radius matches the specified outside-center takeoff setup", near(start_radius, expected_start, .05) and start_radius > radius)
    entry = flight.get("entry", {})
    entry_point = command["steps"][0].get("entryPoint", center)
    add(case, "entry actually arrived before release", same(entry.get("reason"), "arrived") and same(entry.get("passed"), True))
    add(case, "entry distance is at most 0.4 and matches the intended X/Z", within(entry.get("distance"), 0, .4) and within(horizontal(entry.get("position"), entry_point), 0, .4))
    add(case, "exactly one release and at least one acknowledgement", same(flight.get("releaseDelta"), 1) and within(flight.get("acknowledgementDelta"), 1, math.inf))
    receiver = PREFIX + "Decoration.S04_SanctuaryBough.J4"
    paths = [receiver] if bloom == "B2" else [receiver + ".Top"]
    landing = flight.get("landing", {})
    add(case, "actual landing and final support are the required J4 receiver", supported(landing, paths) and supported(after, paths))
    add(case, "receiver landing arrives near the specified aim", same(landing.get("reason"), "arrived") and within(horizontal(landing.get("position"), command["finishTo"]), 0, .8))
    case["observed"].update({"bloom": bloom, "initialRadialDistance": start_radius, "activeRadius": radius,
                             "entry": compact(entry), "entryReason": entry.get("reason"),
                             "entryPoint": entry_point, "aim": command["finishTo"], "landing": compact(landing),
                             "highestRootYRelativeToCourse": flight.get("highestY"), "releaseDelta": flight.get("releaseDelta"),
                             "acknowledgementDelta": flight.get("acknowledgementDelta"), "cancellationDelta": flight.get("cancellationDelta")})
    case["limits"] = ["B2 J4.FinishWalk_1 is a legitimate J4 joining receiver; XB requires J4.Top.",
                      "Recorded highest root position and grounded landing do not independently prove whole-body canopy clearance or rendered flight readability."]
    return finish(case)


def catch_return(case_id, record, evidence, command):
    case, result, steps = sequence(case_id, record, evidence, command)
    for step, recipe in zip(steps[:4], command["steps"][:4]):
        add(case, step["id"] + " reaches its specified grounded return support", same(step.get("reason"), "arrived") and supported(step, [PREFIX + p for p in recipe["supports"]]))
    flight = steps[-1]
    add(case, "B0 earns exactly one release and at least one acknowledgement", same(flight.get("releaseDelta"), 1) and within(flight.get("acknowledgementDelta"), 1, math.inf))
    add(case, "B0 entry actually arrives before release", same(flight.get("entry", {}).get("reason"), "arrived"))
    add(case, "B0 arrives on a grounded J3 receiver", supported(flight.get("landing", {}), [PREFIX + "Decoration.S04_SanctuaryBough.J3"]) and supported(result.get("after", {}), [PREFIX + "Decoration.S04_SanctuaryBough.J3"]))
    case["observed"].update({"releaseDelta": flight.get("releaseDelta"), "acknowledgementDelta": flight.get("acknowledgementDelta")})
    case["limits"] = ["Checkpoint 3 is initial test setup; checkpoint acquisition is covered separately by the continuous runs.",
                      "The original strict support-list timeout is retained as history; Fork_3 was added only to the source test list before this subsequent physical v2 pass."]
    return finish(case)


def catch_skip(case_id, record, evidence, command):
    case, result, steps = sequence(case_id, record, evidence, command, expect_pass=False)
    step = steps[0]
    add(case, "scripted direct attempt times out grounded on Catch instead of J3", same(step.get("passed"), False) and same(step.get("reason"), "timeout") and supported(result.get("after", {}), [PREFIX + "Decoration.S04_SanctuaryBough.Catch"]))
    case["observed"].update({key: step.get(key) for key in ("reason", "minimumY", "highestY", "jumps", "distance")})
    case["limits"] = ["The observed driver made zero jumps and remained on Catch. This rejects this scripted direction only; it does not prove every ordinary-jump bypass impossible.",
                      "No recovery occurred, so the recovery-dependent continuation was not executed or validated."]
    return finish(case, "expected_attempt_rejected")


def closure(case_id, record, evidence):
    trial = record.get("trial", {})
    result = trial.get("result", {})
    steps = result.get("steps", [])
    before = result.get("before", {})
    recovery = record.get("afterRecovery", {})
    state_record = recovery.get("state", {})
    state = state_record.get("result", {})
    case = {"id": case_id, "evidence": {**evidence, "trialScope": result.get("scope")}, "checks": [],
            "limits": ["Recovery observation captures R2 position, Wood floor material and race diagnostics; an exact final support instance/grounded field is not recorded."]}
    add(case, "trial and post-recovery state commands completed", same(trial.get("ok"), True) and same(state_record.get("ok"), True))
    add(case, "one setup placement and zero in-run test placements", same(result.get("initialRepositions"), 1) and same(result.get("withinRunRepositions"), 0))
    stand = next((s for s in steps if s.get("id") == "stand-on-leaf"), {})
    hold = next((s for s in steps if s.get("id") == "remain-through-closure"), {})
    add(case, "avatar first arrives on the actual leaf surface", same(stand.get("reason"), "arrived") and supported(stand, [PREFIX + "Decoration.S03_HangingGardens.Leaves.Leaf_1.Surface"]))
    add(case, "remaining through Curl loses support", same(result.get("passed"), False) and same(hold.get("phaseAfter"), "Curl") and same(hold.get("grounded"), False))
    add(case, "exactly one new local-fall hit is observed after this trial", same(deltas(before, state)["hits"], 1) and same(state.get("diagnostics", {}).get("lastRecovery"), "HeartwoodLocalFall"))
    change = recovery_delta(before, recovery)
    add(case, "recovery timestamp advances after closure", change > 0 if numeric(change) else None)
    add(case, "racer remains official, Racing and checkpoint 2", same(state.get("official"), True) and same(state.get("status"), "Racing") and same(state.get("checkpoint"), 2))
    add(case, "post-recovery position is at R2 with full health", within(horizontal(recovery.get("position"), [52, 68, -50]), 0, .5) and within((vector(recovery.get("position")) or [None, None, None])[1], 70.5, 72) and same(recovery.get("health"), 100))
    case["observed"] = {"reportedPassed": record.get("passed"), "trialReportedPassed": result.get("passed"),
                        "before": compact(before), "supportLoss": compact(hold), "supportLossPhase": hold.get("phaseAfter"),
                        "afterRecovery": recovery, "counterDeltas": deltas(before, state), "recoveryUntilDelta": change}
    return finish(case)


def pulse(case_id, record, evidence):
    rows = record.get("records", {})
    records = [rows[key] for key in sorted(rows, key=lambda key: int(key))] if isinstance(rows, dict) else rows
    case = {"id": case_id, "evidence": evidence, "checks": [], "limits": ["One timed server-driven jump during active Travel; sampled root positions and Humanoid state are recorded, not a body-wide clearance trace or human robustness.", "This separate probe does not record checkpoint or hazard-hit counters."]}
    add(case, "jump occurs from a grounded takeoff", same(record.get("groundedTakeoff"), True) and same(record.get("jumped"), True))
    add(case, "all recorded approach/jump samples occur in active Travel", bool(records) and all(row.get("phase") == "Travel" for row in records))
    add(case, "sampled airborne state confirms a real jump", any(row.get("state") == "Enum.HumanoidStateType.Freefall" for row in records))
    add(case, "final support is grounded R2", supported(record, [PREFIX + "Decoration.S03_HangingGardens.R2"]) and within(record.get("distance"), 0, .8))
    add(case, "recovery timestamp remains unchanged and health is full", same(record.get("recoveryAfter"), record.get("recoveryBefore")) and same(record.get("health"), 100))
    add(case, "recorded probe reports passed", same(record.get("passed"), True))
    jump = vector(record.get("jumpPosition"))
    peak = record.get("maxRelativeY")
    case["observed"] = {"samples": len(records), "phases": sorted(set(row.get("phase") for row in records)),
                        "elapsedLastSampleSeconds": records[-1].get("t") if records else None,
                        "jumpPositionRelativeToCourse": jump, "highestRootYRelativeToCourse": peak,
                        "rootRiseAboveJumpPoint": peak - jump[1] if jump and numeric(peak) else None,
                        "support": record.get("support"), "grounded": record.get("grounded"), "distance": record.get("distance"),
                        "recoveryBefore": record.get("recoveryBefore"), "recoveryAfter": record.get("recoveryAfter")}
    return finish(case)


def checkpoint_finish(case_id, record, evidence):
    command = {"expectCheckpoint": 0, "expectStatus": "Racing", "steps": [{"id": "F0-without-checkpoints"}]}
    case, result, _ = sequence(case_id, record, evidence, command)
    add(case, "checkpoint-zero racer is grounded at F0 without finishing", supported(result.get("after", {}), [PREFIX + "Decoration.S04_SanctuaryBough.F0"]) and same(result.get("after", {}).get("status"), "Racing"))
    case["limits"] = ["One initial placement at F0 with checkpoint 0; this is a recorded finish-gate rejection, not an earned full-route finish."]
    return finish(case)


def normal_input(case_id, record, evidence):
    before, after = record.get("before", {}), record.get("after", {})
    actual = horizontal(before.get("position"), after.get("position"))
    case = {"id": case_id, "evidence": evidence, "checks": [], "limits": ["One normal W-key start check with standard automatic network ownership; no full manual route, device or multiplayer claim."]}
    add(case, "saved normal-input description identifies official W down/up", "Official Studio W down" in record.get("input", "") and "W up" in record.get("input", ""))
    add(case, "observed position moves and agrees with the recorded horizontal distance", within(actual, .5, 20) and near(record.get("horizontalDistance"), actual, .001))
    add(case, "speed remains 16 with full health and grounded final state", same(before.get("walkSpeed"), 16) and same(after.get("walkSpeed"), 16) and same(before.get("health"), 100) and same(after.get("health"), 100) and same(after.get("grounded"), True))
    case["observed"] = {"input": record.get("input"), "before": before, "after": after, "horizontalDistance": actual}
    return finish(case)


def summarize(root, directory, recipe_path):
    recipe, recipe_evidence = load(recipe_path, root)
    commands = (recipe or {}).get("commands", {})
    criteria = {row["id"]: row for row in (recipe or {}).get("cases", [])}
    cases, history = [], []

    def run(case_id, filename, evaluator, needs_command=True):
        record, evidence = load(directory / (filename + "-" + BUILD + ".json"), root)
        if record is None or (needs_command and case_id not in commands):
            case = missing(case_id, evidence)
        else:
            try:
                if needs_command or evaluator is checkpoint_finish:
                    result = record.get("result")
                    if not isinstance(result, dict) or not isinstance(result.get("steps"), list):
                        raise ValueError("Expected a completed sequence record with steps")
                    if not isinstance(record.get("ok"), bool) or not isinstance(result.get("passed"), bool):
                        raise ValueError("Command/result is pending or lacks its explicit success fields")
                    if not all(isinstance(result.get(key), dict) for key in ("before", "after")):
                        raise ValueError("Sequence lacks its before/after observations")
                args = (case_id, record, evidence, commands[case_id]) if needs_command else (case_id, record, evidence)
                case = evaluator(*args)
            except (AttributeError, KeyError, IndexError, TypeError, ValueError) as error:
                case = missing(case_id, evidence)
                case["limits"].append("Raw structure is incomplete or inconsistent: " + str(error))
        if case_id in criteria:
            case["manualCriteria"] = criteria[case_id].get("manualChecks", [])
            case["limits"] += criteria[case_id].get("limits", [])
        cases.append(case)

    for i in range(1, 4):
        case_id = f"late_warning_leaf_{i}"
        run(case_id, "focused-" + case_id, warning)
    for point in SAFE_POINTS:
        case_id = "safe_cycle_" + point
        run(case_id, "focused-" + case_id + "-v2", stationary)
    for case_id in ("b2_inward_edge", "xb_edge_receiver"):
        run(case_id, "focused-" + case_id, bloom_edge)
    petals = (("broad", "B0", [-2, 112, 86], 9.85), ("small", "XB", [-40, 136, 58], 2.85))
    for suffix, bloom, center, radius in petals:
        case_id = "petal_no_ack_release_" + suffix
        run(case_id, "focused-" + case_id, lambda *args: stationary(*args, petal=(bloom, center, radius)))
    run("catch_walk_repeat_b0", "focused-catch_walk_repeat_b0-v2", catch_return)
    run("catch_direct_skip_attempt", "focused-catch_direct_skip_attempt-v2", catch_skip)
    run("leaf_closure_recovery", "leaf-closure-recovery", closure, False)
    run("active_travel_pulse_jump", "pulse-jump", pulse, False)
    run("checkpoint_zero_finish_rejected", "checkpoint-zero-finish", checkpoint_finish, False)
    run("normal_input_start", "normal-input", normal_input, False)

    for filename, explanation in (
        ("focused-catch_walk_repeat_b0", "Original strict support-list timeout on grounded Fork_3.Top, corrected only in the source test support list; subsequent v2 is the physical pass."),
        ("leaf-closure", "Earlier closure trial recorded loss of leaf support during Curl; its file ends before a confirmed recovery. The separate recovery wrapper contains a later trial and post-recovery observation."),
    ):
        record, evidence = load(directory / (filename + "-" + BUILD + ".json"), root)
        result = (record or {}).get("result") or {}
        history.append({"id": filename, "classification": "superseded_history", "evidence": evidence,
                        "reportedPassed": result.get("passed"), "completedSteps": result.get("completedSteps"),
                        "requestedSteps": result.get("requestedSteps"), "after": compact(result.get("after", {})),
                        "failedSteps": [{"id": step.get("id"), "reason": step.get("reason"), **compact(step)} for step in result.get("steps", []) if step.get("passed") is False],
                        "explanation": explanation, "countedAsFinalPass": False})
    continuation = {"id": "catch_skip_recovery_continue", "verdict": "not_executed",
                    "reason": "The recorded direct skip timed out on Catch with no recovery. The required authentic R3 recovery prerequisite did not occur; the continuation was explicitly not run.",
                    "manualCriteria": criteria.get("catch_skip_recovery_continue", {}).get("manualChecks", []),
                    "evidence": None, "countedAsFinalPass": False}
    counts = dict(Counter(case["verdict"] for case in cases))
    cycles = [case["observed"]["completeCycleSeconds"] for case in cases if case["id"].startswith("safe_cycle_") and case["verdict"] == "passed"]
    return {"schemaVersion": 1, "candidate": BUILD, "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
            "scope": SCOPE, "criteriaSource": recipe_evidence,
            "classificationRules": {"cycleToleranceSeconds": .15, "stationarySampleDriftToleranceStuds": .1,
                                    "missingOrInvalidEvidence": "incomplete, never passed", "negativeProbe": "expected attempt rejected is separate from a positive pass",
                                    "history": "retained but not counted as final passes", "sourceTestListCorrection": "Fork_3 added to accepted catch return supports; no game source edit by this summarizer"},
            "summary": {"finalExecutedChecks": len(cases), "verdictCounts": counts, "supersededHistoryFiles": len(history),
                        "notExecutedChecks": 1, "safeFullCycleChecksPassed": len(cycles),
                        "finalEvidenceConditionsMet": all(case["verdict"] in ("passed", "expected_attempt_rejected") for case in cases),
                        "allRecipeBranchesExecuted": False,
                        "scopeLimits": ["Catch recovery continuation was not executed.", "No universal Catch-jump bypass rejection, full human/device/multiplayer acceptance or whole-body clearance claim."]},
            "cases": cases, "notExecuted": [continuation], "history": history}


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=root / "docs/artifacts/heartwood-ascent/v1")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    directory = args.input_dir.resolve()
    output = args.output or directory / ("focused-check-summary-" + BUILD + ".json")
    result = summarize(root, directory, root / "tests/studio/HeartwoodFocusedRunsHA03.json")
    output.write_text(json.dumps(result, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(output), **result["summary"]}, indent=2))


if __name__ == "__main__":
    main()
