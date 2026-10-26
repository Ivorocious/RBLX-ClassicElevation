"""Check final saved HA04 evidence; missing files remain pending and no Studio calls run."""

import argparse
import hashlib
import json
import math
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


BUILD = "HA_V1_04"
COUNTERS = ("hits", "acknowledgements", "releases", "cancels")
SECTION = "Decoration.S04_SanctuaryBough."
FINISH_SUPPORTS = (SECTION + "F0.Top", SECTION + "F0.SanctuaryArtwork", SECTION + "FinishWalk_4")
FINISH_DISTANCE = 4
FINISH_LIMIT = (
    "Finish support and authoritative Finished/checkpoint 3 remain required within four studs "
    "of unchanged F0 (-106,162,28). The authored 26x5x3 finish marker accepts avatar contact "
    "and immediately freezes movement. Preserved continuous-main-finish-freeze-history-HA_V1_04.json "
    "recorded valid Finished on SanctuaryArtwork at 3.329 studs; this bounded fixture allowance is not a "
    "geometry/tuning fix or evidence of a physical lip defect."
)
SOURCE_PATHS = (
    "src/ReplicatedStorage/Shared/HeartwoodState.luau",
    "src/ReplicatedStorage/Config/HeartwoodConfig.luau",
    "src/ServerStorage/CourseBuilders/HeartwoodAscent/Runtime.luau",
    "src/ServerStorage/CourseBuilders/HeartwoodAscent/Layout.luau",
    "src/ServerStorage/CourseBuilders/HeartwoodAscent/Build.luau",
    "src/ServerStorage/CourseBuilders/HeartwoodAscent/Art.luau",
    "src/ServerStorage/CourseBuilders/HeartwoodAscent/ArtManifest.luau",
    "src/ServerStorage/CourseBuilders/HeartwoodAscent/Verification.luau",
    "src/ServerScriptService/Services/CourseService.luau",
    "src/ServerScriptService/Services/HeartwoodService.luau",
    "src/ServerScriptService/Main.server.luau",
    "src/StarterPlayer/StarterPlayerScripts/HeartwoodBloomCue.client.luau",
)
SCOPE = (
    "Read-only checks of final saved solo Studio evidence. Server-driven movement and a "
    "forced normal jump are separate from initial setup. This report does not establish "
    "human route acceptance, pacing, difficulty, foreground FPS, device performance, "
    "multiplayer, network-delay behavior, or universal bypass prevention."
)


def obj(value):
    return value if isinstance(value, dict) else {}


def rows(value):
    if isinstance(value, list):
        return value
    if isinstance(value, dict) and all(str(key).isdigit() for key in value):
        return [value[key] for key in sorted(value, key=lambda key: int(key))]
    return []


def numeric(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def eq(actual, expected):
    if actual is None:
        return None
    if isinstance(expected, bool):
        return actual is expected
    if numeric(expected) and not numeric(actual):
        return False
    return actual == expected


def bounded(actual, low, high):
    return low <= actual <= high if numeric(actual) else None


def all_of(values):
    values = list(values)
    return False if False in values else None if None in values or not values else True


def vector(value):
    value = rows(value) if isinstance(value, dict) else value
    return value if isinstance(value, list) and len(value) == 3 and all(map(numeric, value)) else None


def horizontal(position, target):
    position = vector(position)
    return math.hypot(position[0] - target[0], position[2] - target[2]) if position else None


def delta(before, after, name):
    a, b = after.get(name), before.get(name)
    return a - b if numeric(a) and numeric(b) else None


def counter_deltas(before, after):
    a, b = obj(after.get("diagnostics")), obj(before.get("diagnostics"))
    return {key: delta(b, a, key) for key in COUNTERS}


def unwrap(record):
    record = obj(record)
    return obj(record.get("result")) if "ok" in record else record


def state(step):
    return obj(step.get("after")) if isinstance(step.get("after"), dict) else obj(step)


def compact(value):
    fields = ("position", "support", "grounded", "supportMethod", "checkpoint", "status",
              "official", "recoveryUntil", "distance", "diagnostics")
    return {key: value[key] for key in fields if key in value}


def supports(value, paths):
    support = value.get("support")
    if not isinstance(support, str) or value.get("grounded") is None:
        return None
    local_path = "Decoration." + support.split(".Decoration.", 1)[1] if ".Decoration." in support else support
    return value["grounded"] is True and any(local_path == path or local_path.startswith(path + ".") for path in paths)


def add(case, criterion, condition):
    case["checks"].append({"criterion": criterion,
                           "status": "passed" if condition is True else "incomplete" if condition is None else "failed"})


def finish(case, success="passed"):
    statuses = [check["status"] for check in case["checks"]]
    case["status"] = "failed" if "failed" in statuses else "incomplete" if "incomplete" in statuses or not statuses else success
    return case


def new_case(case_id, evidence):
    return {"id": case_id, "evidence": evidence, "checks": [], "observed": {}, "limits": []}


def expected_route(shortcut):
    roots = [f"root-{n}" for n in range(1, 7)] + ["H01-clear-1", "root-7", "root-8", "H01-clear-2"]
    roots += [f"root-{n}" for n in range(9, 13)] + ["R1", "entry-1", "entry-2", "J1"]
    heart = [f"X01_{n}" for n in range(1, 7)] if shortcut else [f"Main_{n}" for n in range(1, 15)]
    gardens = ["J2", "H02-clear", "R2", "garden-1", "garden-2", "garden-3", "P0",
               "H03-open-1", "P1", "H03-open-2", "P2", "H03-open-3", "P3", "fork-1", "fork-2", "fork-3", "R3", "B0"]
    blooms = ["XA-approach", "XA", "XB"] if shortcut else ["B1-approach", "B1", "wide-edge-preparation"] + [f"detour-{n}" for n in range(1, 8)] + ["B2"]
    return roots + heart + gardens + blooms + ["J4", "finish-walk-1", "finish-walk-2", "finish-walk-3", "F0"]


def sequence(case_id, record, evidence, expected_ids):
    case = new_case(case_id, evidence)
    result = obj(record.get("result"))
    steps = rows(result.get("steps"))
    before, after = obj(result.get("before")), obj(result.get("after"))
    add(case, "outer command and sequence report success", all_of((eq(record.get("ok"), True), eq(result.get("passed"), True))))
    add(case, "all steps execute once in the expected order", all_of((
        eq(result.get("completedSteps"), len(expected_ids)), eq(result.get("requestedSteps"), len(expected_ids)),
        [obj(step).get("id") for step in steps] == expected_ids if "steps" in result else None)))
    add(case, "every step explicitly passes", all_of(eq(obj(step).get("passed"), True) for step in steps))
    add(case, "one initial placement and no in-run test placement", all_of((eq(result.get("initialRepositions"), 1), eq(result.get("withinRunRepositions"), 0))))
    add(case, "hazard hit delta is zero", eq(counter_deltas(before, after)["hits"], 0))
    add(case, "recovery timestamp does not advance", eq(delta(before, after, "recoveryUntil"), 0))
    add(case, "finish is grounded on an exact intended finish collider", supports(after, FINISH_SUPPORTS))
    add(case, "finished at checkpoint three within four studs", all_of((
        eq(after.get("checkpoint"), 3), eq(after.get("status"), "Finished"), bounded(after.get("distance"), 0, FINISH_DISTANCE),
        bounded(horizontal(after.get("position"), [-106, 162, 28]), 0, FINISH_DISTANCE))))
    case["observed"] = {"resultPassed": result.get("passed"), "completedSteps": result.get("completedSteps"),
                        "requestedSteps": result.get("requestedSteps"), "recordedSteps": len(steps),
                        "finishDistanceAllowanceStuds": FINISH_DISTANCE,
                        "before": compact(before), "after": compact(after),
                        "counterDeltas": counter_deltas(before, after), "recoveryUntilDelta": delta(before, after, "recoveryUntil"),
                        "initialRepositions": result.get("initialRepositions"), "withinRunRepositions": result.get("withinRunRepositions"),
                        "timingSeconds": {key: result.get(key) for key in ("elapsed", "travel", "wait", "replay")}}
    case["limits"].append(FINISH_LIMIT)
    return case, result, steps, before, after


def continuous(case_id, record, evidence, shortcut=False):
    case, result, steps, before, after = sequence(case_id, record, evidence, expected_route(shortcut))
    states = [before] + [state(obj(step)) for step in steps] + [after]
    checkpoints = [value.get("checkpoint") for value in states]
    order = [cp for index, cp in enumerate(checkpoints) if index == 0 or cp != checkpoints[index - 1]]
    add(case, "actual checkpoint order is zero, one, two, three", order == [0, 1, 2, 3] if all(cp is not None for cp in checkpoints) else None)
    add(case, "checkpoint gains occur on R1, R2, R3", all_of(
        eq(state(obj(next((step for step in steps if obj(step).get("id") == name), {}))).get("checkpoint"), cp)
        for name, cp in (("R1", 1), ("R2", 2), ("R3", 3))))
    add(case, "official racer is recorded throughout", all_of(eq(value.get("official"), True) for value in states))
    add(case, "starts Racing on grounded R0", all_of((eq(before.get("status"), "Racing"), eq(before.get("checkpoint"), 0),
        supports(before, ("Decoration.S01_AncientRoots.R0.Top",)))))
    add(case, "Racing continues until the final finish step", all_of(eq(state(obj(step)).get("status"), "Finished" if obj(step).get("id") == "F0" else "Racing") for step in steps))
    add(case, "all four sections are represented", {obj(step).get("section") for step in steps} == {"S01", "S02", "S03", "S04"} if steps else None)
    add(case, "replay time is zero", eq(result.get("replay"), 0))
    for metric in ("elapsed", "travel", "wait", "replay"):
        values = [obj(step).get(metric) for step in steps]
        recorded = result.get(metric)
        valid = all(numeric(value) and value >= 0 for value in values) and numeric(recorded) and recorded >= 0
        add(case, f"{metric} timing is finite and nonnegative", valid if metric in result and steps else None)
        if metric != "elapsed":
            add(case, f"{metric} equals the step sum", abs(sum(values) - recorded) <= .01 if valid else None)
    blooms = ("B0", "XA", "XB") if shortcut else ("B0", "B1", "B2")
    receiver_paths = {"B0": (SECTION + "J3.Top",), "B1": (SECTION + "Wide.Top",),
                      "B2": (SECTION + "J4.Top", SECTION + "J4.FinishWalk_1"),
                      "XA": (SECTION + "Blooms.XB",), "XB": (SECTION + "J4.Top",)}
    flights = []
    for name in blooms:
        flight = obj(next((step for step in steps if obj(step).get("id") == name), {}))
        landing = obj(flight.get("landing"))
        add(case, f"{name} has one release and actual acknowledged receiver landing", all_of((
            eq(flight.get("releaseDelta"), 1), bounded(flight.get("acknowledgementDelta"), 1, math.inf),
            eq(landing.get("passed"), True), supports(landing, receiver_paths[name]))))
        flights.append({"id": name, "releaseDelta": flight.get("releaseDelta"), "acknowledgementDelta": flight.get("acknowledgementDelta"),
                        "cancellationDelta": flight.get("cancellationDelta"), "landing": compact(landing)})
    case["observed"].update(checkpointOrder=order, sectionStepCounts=dict(Counter(obj(step).get("section") for step in steps)), blooms=flights)
    if not shortcut:
        preparation = obj(next((step for step in steps if obj(step).get("id") == "wide-edge-preparation"), {}))
        preparation_before, preparation_after = obj(preparation.get("before")), state(preparation)
        detour = obj(next((step for step in steps if obj(step).get("id") == "detour-1"), {}))
        add(case, "Wide-edge preparation is grounded on exact Wide.Top with zero jumps", all_of((
            supports(preparation_before, (SECTION + "Wide.Top",)), supports(preparation_after, (SECTION + "Wide.Top",)),
            eq(preparation.get("jumps"), 0), bounded(horizontal(preparation_after.get("position"), [-57, 132, 127]), 0, .8))))
        add(case, "Wide-edge preparation keeps checkpoint three and adds no recovery or hit", all_of((
            eq(preparation_before.get("checkpoint"), 3), eq(preparation_after.get("checkpoint"), 3),
            eq(delta(preparation_before, preparation_after, "recoveryUntil"), 0), eq(counter_deltas(preparation_before, preparation_after)["hits"], 0))))
        add(case, "following Detour_1 records an ordinary jump and grounded receiver", all_of((
            bounded(detour.get("jumps"), 1, math.inf), supports(state(detour), (SECTION + "Detour_1.Top",)),
            eq(state(detour).get("checkpoint"), 3))))
        case["observed"]["wideEdgePreparation"] = {"jumps": preparation.get("jumps"), "before": compact(preparation_before),
            "after": compact(preparation_after), "counterDeltas": counter_deltas(preparation_before, preparation_after),
            "recoveryUntilDelta": delta(preparation_before, preparation_after, "recoveryUntil"),
            "followingDetourJumps": detour.get("jumps"), "followingDetourLanding": compact(state(detour))}
    case["limits"].append("One complete scripted attempt; timing is travel and actual waits, not human pace or shortcut success-rate evidence.")
    if not shortcut:
        case["limits"].append("The final main route has 66 steps: a supported zero-jump Wide-edge walk precedes Detour_1; the original 65 route beats stay in order. Old pre-form and failed early-jump traces are separate history, not final proof.")
    return finish(case)


def finish_walk(case_id, record, evidence):
    case, _, steps, before, _ = sequence(case_id, record, evidence, ["finish-walk-1", "finish-walk-2", "finish-walk-3", "F0"])
    add(case, "starts grounded at checkpoint three while Racing", all_of((eq(before.get("grounded"), True), eq(before.get("checkpoint"), 3), eq(before.get("status"), "Racing"))))
    add(case, "all four steps record zero jumps", all_of(eq(obj(step).get("jumps"), 0) for step in steps))
    joins = ((SECTION + "J4.FinishWalk_1", SECTION + "FinishWalk_2"),
             (SECTION + "FinishWalk_2", SECTION + "FinishWalk_3"),
             (SECTION + "FinishWalk_3", SECTION + "FinishWalk_4"), FINISH_SUPPORTS)
    add(case, "each step is grounded on its exact walking surface or join", all_of(supports(state(obj(step)), paths) for step, paths in zip(steps, joins)))
    case["observed"]["jumps"] = [obj(step).get("jumps") for step in steps]
    case["limits"].append("The exact visible SanctuaryArtwork finish collider is legitimate support; the retained earlier strict-list timeout is not a physical lip defect.")
    return finish(case)


def catch_jump(case_id, record, evidence):
    case = new_case(case_id, evidence)
    setup, trial = obj(record.get("setup")), obj(record.get("trial"))
    before, after = unwrap(record.get("before")), unwrap(record.get("after"))
    add(case, "separate Catch setup succeeded", all_of((eq(setup.get("ok"), True), eq(unwrap(setup).get("passed"), True))))
    for label in ("before", "after"):
        wrapper = obj(record.get(label))
        add(case, f"{label} bridge state command completed", eq(wrapper.get("ok"), True))
    add(case, "takeoff is actually grounded on Catch", all_of((eq(obj(trial.get("before")).get("grounded"), True), eq(obj(trial.get("before")).get("onCatch"), True))))
    add(case, "one commanded jump produces observed lift", all_of((eq(trial.get("jumpCommands"), 1), eq(trial.get("jumpObserved"), True),
        eq(trial.get("validAttempt"), True), eq(trial.get("sawAirborne"), True), bounded(trial.get("actualRise"), .25, math.inf), bounded(trial.get("peakUpwardVelocity"), 1.000001, math.inf))))
    changes = rows(trial.get("stateChanges"))
    add(case, "actual Humanoid Jumping transition is recorded", any(obj(row).get("to") == "Jumping" for row in changes) if changes else None)
    add(case, "receiver landing is rejected in this actual jump", all_of((eq(trial.get("receiverLanded"), False), eq(trial.get("bypassPreventedInThisAttempt"), True), eq(obj(trial.get("after")).get("onReceiver"), False))))
    add(case, "recorder makes no test position or progress writes", all_of((eq(trial.get("withinRunRepositions"), 0), eq(trial.get("progressWrites"), 0), eq(trial.get("initialSetupInsideRecorder"), False))))
    add(case, "bridge checkpoint stays three and status stays Racing", all_of(eq(value.get(key), expected)
        for value in (before, after) for key, expected in (("checkpoint", 3), ("status", "Racing"), ("official", True))))
    counters = counter_deltas(before, after)
    add(case, "no bloom acknowledgements, releases or cancellations are added", all_of(eq(counters[key], 0) for key in ("acknowledgements", "releases", "cancels")))
    case["observed"] = {"beforeBridge": compact(before), "afterBridge": compact(after), "counterDeltas": counters,
                        "classification": trial.get("classification"), "jumpCommands": trial.get("jumpCommands"), "jumpObserved": trial.get("jumpObserved"),
                        "actualRise": trial.get("actualRise"), "peakUpwardVelocity": trial.get("peakUpwardVelocity"), "apex": trial.get("apex"),
                        "attemptedReceiver": trial.get("attemptedReceiver"), "receiverLanded": trial.get("receiverLanded"), "contacts": trial.get("contacts"),
                        "before": trial.get("before"), "after": trial.get("after"), "recovery": trial.get("recovery"), "recoveryObserved": trial.get("recoveryObserved"),
                        "stateChanges": changes}
    case["limits"] = ["One forced normal jump from one grounded Catch edge; not a universal bypass proof. Receiver spatial overlap is distinct from grounded landing."]
    return finish(case)


def leaf_closure(case_id, record, evidence):
    case = new_case(case_id, evidence)
    trial_wrapper = obj(record.get("trial"))
    trial = unwrap(trial_wrapper)
    after_wrapper = obj(record.get("after"))
    after_result = unwrap(after_wrapper)
    post = state(after_result)
    after = post
    before = obj(trial.get("before"))
    steps = rows(trial.get("steps"))
    stand = state(obj(next((step for step in steps if obj(step).get("id") == "stand-on-leaf"), {})))
    hold = obj(next((step for step in steps if obj(step).get("id") == "remain-through-closure"), {}))
    add(case, "trial and recovery state observations completed", all_of((eq(trial_wrapper.get("ok"), True), eq(after_wrapper.get("ok"), True))))
    add(case, "one initial placement and no test reposition within closure", all_of((eq(trial.get("initialRepositions"), 1), eq(trial.get("withinRunRepositions"), 0))))
    if "steps" in after_result:
        add(case, "recovery observation uses no initial or in-run placement", all_of((eq(after_result.get("initialRepositions"), 0), eq(after_result.get("withinRunRepositions"), 0))))
    add(case, "actual leaf Surface supported the avatar before closure", supports(stand, ("Decoration.S03_HangingGardens.Leaves.Leaf_1.Surface",)))
    add(case, "Curl removes support and interrupts the hold", all_of((eq(trial.get("passed"), False), eq(hold.get("phaseAfter"), "Curl"), eq(hold.get("grounded"), False))))
    counters = counter_deltas(before, after)
    recovery = delta(before, post, "recoveryUntil")
    add(case, "one natural local-fall recovery is recorded", all_of((eq(counters["hits"], 1), eq(obj(after.get("diagnostics")).get("lastRecovery"), "HeartwoodLocalFall"), bounded(recovery, .000001, math.inf))))
    add(case, "recovered racer is official, Racing at checkpoint two", all_of((eq(after.get("checkpoint"), 2), eq(after.get("status"), "Racing"), eq(after.get("official"), True))))
    position = vector(post.get("position"))
    add(case, "recovery returns to R2 with full health and actual support", all_of((
        bounded(horizontal(position, [52, 68, -50]), 0, .5), bounded(position[1] if position else None, 70, 73),
        eq(record.get("health"), 100), supports(post, ("Decoration.S03_HangingGardens.R2.Top", "Decoration.S02_LivingHeartwood.PulseLane")))))
    case["observed"] = {"before": compact(before), "stand": compact(stand), "closurePhase": hold.get("phaseAfter"),
                        "closureGrounded": hold.get("grounded"), "after": post, "counterDeltas": counters, "recoveryUntilDelta": recovery}
    case["limits"] = ["Natural closure loss followed by a saved grounded R2 recovery observation; no damage/death or manual-reset claim is inferred."]
    return finish(case)


def collision(case_id, record, evidence):
    case = new_case(case_id, evidence)
    add(case, "collision audit identifies HA04", eq(record.get("build"), BUILD))
    add(case, "positive bounded sample count is recorded", bounded(record.get("checked"), 1, math.inf))
    add(case, "no standing sample blockers or ghost surfaces", all_of((eq(record.get("blockers"), []), eq(record.get("ghosts"), []))))
    case["observed"] = record
    case["limits"] = ["Bounded body-height standing samples do not prove every edge or whole-body flight clearance."]
    return finish(case)


def native_restore(case_id, record, evidence):
    case = new_case(case_id, evidence)
    for key, expected in (("candidate", BUILD), ("passed", True), ("nativeRoundTrip", True), ("editableUnits", True), ("roots", 2), ("differenceCount", 0)):
        add(case, key, eq(record.get(key), expected))
    add(case, "native numeric differences stay within the recorded .001 limit", all_of((eq(record.get("numericTolerance"), .001),
        bounded(record.get("maxNumericDifference"), 0, .001), bounded(record.get("maxUnitDifference"), 0, .001), bounded(record.get("maxComparisonDifference"), 0, .001))))
    units = [obj(unit) for unit in rows(record.get("unitChecks"))]
    expected_units = ([f"BoughFamily_{n:02}" for n in range(14)] + [f"ForestTree_{n:02}" for n in range(1, 27)] + [f"Leaf_{n}" for n in range(1, 4)])
    add(case, "all fourteen branch families, twenty-six forest trees and three leaves were exercised once", Counter(unit.get("unit") for unit in units) == Counter(expected_units) if units else None)
    add(case, "every edited copy returns with consistent relative positions", all_of(
        all_of((eq(unit.get("passed"), True), bounded(unit.get("parts"), 1, math.inf),
                bounded(unit.get("maxShiftError"), 0, .001), bounded(unit.get("maxRelativeError"), 0, .001), bounded(unit.get("maxReturnError"), 0, .001))) for unit in units))
    add(case, "each restored leaf includes its warning vein", all_of(eq(unit.get("warningVein"), True) for unit in units if str(unit.get("unit", "")).startswith("Leaf_")))
    archive = record.get("archive")
    add(case, "restored copies are archived instead of deleted", archive.startswith("ServerStorage.HeartwoodBuildHistory.") if isinstance(archive, str) else None)
    case["observed"] = {key: record.get(key) for key in ("inventory", "serializedBytes", "comparedInstances", "numericTolerance", "maxNumericDifference", "maxUnitDifference", "maxComparisonDifference", "differenceCount", "archive", "compared")}
    case["observed"]["editableUnits"] = len(units)
    case["observed"]["unitNames"] = sorted(unit.get("unit", "") for unit in units)
    case["limits"] = ["Native Edit serialization and restored-copy edits do not run Runtime or prove gameplay."]
    return finish(case)


def backup(case_id, record, evidence, root):
    case = new_case(case_id, evidence)
    for key, expected in (("candidate", BUILD), ("reopened", True), ("roundTrip", True), ("roots", 2), ("assetLibrary", "HeartwoodV1HA04")):
        add(case, key, eq(record.get(key), expected))
    for key in ("parts", "meshes", "uniqueMeshes", "libraryTemplates", "branchFamilies", "routeGreenery", "buttressRoots", "comparedInstances", "artTriangles"):
        add(case, key + " inventory is positive", bounded(record.get(key), 1, math.inf))
    add(case, "local serialization numeric difference is bounded", bounded(record.get("maxNumericDifference"), 0, .001))
    relative = record.get("path")
    expected = f"docs/artifacts/heartwood-ascent/v1/heartwood-v1-{BUILD}.rbxm"
    add(case, "backup path identifies the HA04 native export", eq(relative, expected))
    export = root / expected
    add(case, "export file is present and nonempty", export.is_file() and export.stat().st_size > 0)
    case["observed"] = record.copy()
    if export.is_file():
        case["observed"]["exportSha256"] = hashlib.sha256(export.read_bytes()).hexdigest()
    case["limits"] = ["Local reopen proof is paired with native Studio exact CollisionFidelity proof; the local reader limitation is retained."]
    return finish(case)


def source_sync(case_id, record, evidence, root):
    case = new_case(case_id, evidence)
    sources = [obj(row) for row in rows(record.get("sources"))]
    add(case, "HA04 sources are reported matched", all_of((eq(record.get("candidate"), BUILD), eq(record.get("matched"), True))))
    add(case, "all twelve expected sources are captured exactly once", Counter(row.get("path") for row in sources) == Counter(SOURCE_PATHS) if sources else None)
    comparisons = []
    for row in sources:
        name = row.get("path")
        current_hash = None
        if name in SOURCE_PATHS and (root / name).is_file():
            current_hash = hashlib.sha256((root / name).read_text(encoding="utf-8").encode()).hexdigest()
        add(case, str(name) + " native match and current durable hash", all_of((eq(row.get("nativeMatch"), True), eq(row.get("sha256"), current_hash) if current_hash else None)))
        comparisons.append({"path": name, "nativeMatch": row.get("nativeMatch"), "recordedSha256": row.get("sha256"), "currentSha256": current_hash})
    add(case, "source-sync capture has no temporary starter", eq(record.get("testStarterPresent"), False))
    case["observed"] = {"sources": comparisons, "verificationEnabled": record.get("verificationEnabled")}
    return finish(case)


def cleanup(case_id, record, evidence):
    case = new_case(case_id, evidence)
    for key, expected in (("build", BUILD), ("study", False), ("bridge", False), ("starter", False), ("verificationEnabled", False), ("lights", 0)):
        add(case, key, eq(record.get(key), expected))
    for key in ("parts", "meshes", "templates", "collidable", "triangles"):
        add(case, key + " final inventory is positive", bounded(record.get(key), 1, math.inf))
    case["observed"] = record
    case["limits"] = ["Saved final native hierarchy/settings are cleanup evidence; no autosave or publish action is implied."]
    return finish(case)


def utc(value):
    if not isinstance(value, str):
        return None
    try:
        value = re.sub(r"\.(\d+)(?=Z|[+-]\d{2}:\d{2}$)", lambda match: "." + match[1][:6].ljust(6, "0"), value)
        result = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return result.astimezone(timezone.utc) if result.tzinfo else None
    except ValueError:
        return None


def focus_overlap(sample, focus):
    start, end = utc(sample.get("utcStart")), utc(sample.get("utcEnd"))
    observations = []
    if start and end:
        for row in rows(focus.get("samples")):
            row = obj(row)
            at = utc(row.get("utc"))
            if at and start <= at <= end:
                observations.append((at, row))
    observations.sort(key=lambda item: item[0])
    foreground = sum(row.get("studioForeground") is True for _, row in observations)
    background = sum(row.get("studioForeground") is False for _, row in observations)
    unknown = len(observations) - foreground - background
    classification = "not-observed-in-recording-window" if not observations else "incomplete-focus-flags" if unknown else (
        "studio-foreground-at-all-overlapping-samples" if not background else
        "studio-background-at-all-overlapping-samples" if not foreground else "mixed-foreground-and-background")
    result = {"classification": classification, "overlappingSamples": len(observations),
              "studioForegroundSamples": foreground, "studioBackgroundSamples": background, "unknownSamples": unknown,
              "recordingUtcStart": sample.get("utcStart"), "recordingUtcEnd": sample.get("utcEnd"),
              "focusScope": focus.get("scope"), "studioProcessIds": focus.get("studioProcessIds"),
              "limits": ["Process foreground is observed only at sampled UTC points, not continuously or for every Studio window."]}
    if observations:
        times = [at for at, _ in observations]
        result.update(firstOverlappingUtc=times[0].isoformat(), lastOverlappingUtc=times[-1].isoformat(),
                      firstSampleDelaySeconds=(times[0] - start).total_seconds(),
                      lastSampleToEndSeconds=(end - times[-1]).total_seconds(),
                      maximumInternalSampleGapSeconds=max(((b - a).total_seconds() for a, b in zip(times, times[1:])), default=0),
                      observedProcessIds=sorted({row.get("processId") for _, row in observations if numeric(row.get("processId"))}))
    return result


def performance(case_id, record, evidence):
    case = new_case(case_id, evidence)
    add(case, "performance observation identifies HA04", eq(record.get("candidate"), BUILD))
    samples = obj(record.get("samples"))
    add(case, "J2 and gardens raw samples are present", set(samples) == {"j2", "gardens"} if "samples" in record else None)
    focus = obj(record.get("focus"))
    joined_focus = {}
    for name, sample in samples.items():
        sample = unwrap(sample)
        start, end = utc(sample.get("utcStart")), utc(sample.get("utcEnd"))
        add(case, name + " UTC recording interval is ordered", start <= end if start and end else None)
        add(case, name + " is HA04 with Custom camera and FOV70", all_of((eq(sample.get("candidate"), BUILD), eq(sample.get("cameraType"), "Custom"), eq(sample.get("fieldOfView"), 70))))
        add(case, name + " rendering and saved quality are recorded", all_of(bool(sample.get(key)) if isinstance(sample.get(key), str) else None for key in ("quality", "savedQuality")))
        add(case, name + " sample has a positive duration and frame count", all_of((bounded(sample.get("seconds"), .001, math.inf), bounded(sample.get("frames"), 1, math.inf))))
        for metric in ("meanMs", "p95Ms", "maxMs", "wholePlaceMemoryMB"):
            add(case, name + " " + metric + " is a finite observation", bounded(sample.get(metric), 0, math.inf))
        joined_focus[name] = focus_overlap(sample, obj(focus.get(name)))
    case["observed"] = {"samples": samples, "overlappingFocus": joined_focus, "recordedLimits": record.get("limits")}
    case["limits"] = ["Raw stationary frame intervals and whole-place memory only. Overlapping foreground/background samples are recorded when available. Matched camera baseline, device or multiplayer performance are not established. No FPS target or improvement verdict is calculated."]
    return finish(case, "recorded")


def load(path, root):
    evidence = {"file": path.relative_to(root).as_posix() if path.is_relative_to(root) else str(path)}
    if not path.is_file():
        return None, {**evidence, "status": "missing"}
    try:
        raw = path.read_bytes()
        evidence["sha256"] = hashlib.sha256(raw).hexdigest()
        def reject_constant(value):
            raise ValueError("Nonfinite JSON constant: " + value)
        value = json.loads(raw, parse_constant=reject_constant)
        if not isinstance(value, dict):
            raise ValueError("Expected a JSON object")
        return value, {**evidence, "status": "available"}
    except (OSError, ValueError, UnicodeError) as error:
        return None, {**evidence, "status": "invalid", "reason": str(error)}


def summarize(root, directory):
    evaluators = (
        ("continuous-main", continuous),
        ("continuous-shortcuts", lambda *args: continuous(*args, shortcut=True)),
        ("finish-no-jump", finish_walk), ("catch-edge-jump", catch_jump),
        ("leaf-closure-recovery", leaf_closure), ("collision-final", collision),
        ("native-studio-restore", native_restore),
        ("native-backup-reopen", lambda *args: backup(*args, root=root)),
        ("source-sync", lambda *args: source_sync(*args, root=root)),
        ("final-native-state", cleanup), ("performance", performance),
    )
    cases = []
    for name, evaluate in evaluators:
        record, evidence = load(directory / f"{name}-{BUILD}.json", root)
        if record is None:
            case = new_case(name, evidence)
            case["status"] = "pending" if evidence["status"] == "missing" else "invalid"
            case["limits"] = ["Missing or invalid final evidence is never counted as a pass; historical attempts are not substituted."]
        else:
            try:
                case = evaluate(name, record, evidence)
            except (AttributeError, KeyError, IndexError, TypeError, ValueError) as error:
                case = new_case(name, evidence)
                case.update(status="invalid", reason="Unrecognized or inconsistent evidence structure: " + str(error))
        cases.append(case)
    ready = all(case["status"] in ("passed", "recorded") for case in cases)
    failed = any(case["status"] in ("failed", "invalid") for case in cases)
    return {
        "schemaVersion": 1, "candidate": BUILD, "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "status": "complete" if ready else "has-failures" if failed else "pending" if all(case["status"] == "pending" for case in cases) else "partial",
        "scope": SCOPE,
        "summary": {"requiredEvidenceFiles": len(cases), "statusCounts": dict(Counter(case["status"] for case in cases)),
                    "finalEvidenceConditionsMet": ready, "humanRouteAcceptanceValidated": False,
                    "humanPacingTargetsValidated": False, "foregroundFPSValidated": False,
                    "devicePerformanceValidated": False, "multiplayerValidated": False,
                    "universalBypassPreventionValidated": False},
        "classificationRules": {"missingFiles": "pending", "missingRequiredFields": "incomplete", "contradictedChecks": "failed",
                                "history": "Exact final filenames only; failed and superseded history remains separate",
                                "performance": "recorded observations, never a frame-rate acceptance pass"},
        "cases": cases,
    }


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=root / "docs/artifacts/heartwood-ascent/v1")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    directory = args.input_dir.resolve()
    output = args.output or directory / f"verification-summary-{BUILD}.json"
    result = summarize(root, directory)
    output.write_text(json.dumps(result, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(output), "status": result["status"], **result["summary"]}, indent=2))


if __name__ == "__main__":
    main()
