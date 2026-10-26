"""Compare native iteration 2 rest geometry with the retained exact-source fixture."""
import copy
import hashlib
import json
import math
import re
from pathlib import Path

import p2_route_layout_reconstruction as r

ROOT = Path.cwd()
ARTIFACT = ROOT / "docs/artifacts/keyboard-circuit/phase2/research"
NATIVE_PATH = ARTIFACT.parent / "P2-C01-native-geometry-02.json"
FIXTURE_PATH = ARTIFACT / "p2_route_layout_course_fixture.json"
native = json.loads(NATIVE_PATH.read_text(encoding="utf-8-sig"))
fixture = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
actual = r.annotate(copy.deepcopy(native["contacts"]))
offline = r.annotate(copy.deepcopy(fixture["contacts"]))
exec("def allowed_pair(" + r.library.split("def allowed_pair(")[1].split("\n\npairs = []")[0], r.scope)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def by_path(rows):
    result = {r.scope["compact"](row["path"]): row for row in rows}
    assert len(result) == len(rows), "Contact paths must be unique."
    return result


native_by_path, offline_by_path = by_path(actual), by_path(offline)
missing_native = sorted(offline_by_path.keys() - native_by_path.keys())
extra_native = sorted(native_by_path.keys() - offline_by_path.keys())
comparisons = []
for path in sorted(native_by_path.keys() & offline_by_path.keys()):
    a, b = native_by_path[path], offline_by_path[path]
    comparisons.append({
        "path": path,
        "positionError": math.dist(a["cf"][:3], b["cf"][:3]),
        "frameComponentError": max(abs(a["cf"][i] - b["cf"][i]) for i in range(3, 12)),
        "sizeComponentError": max(abs(a["size"][i] - b["size"][i]) for i in range(3)),
        "roleMatches": a.get("role") == b.get("role"),
    })
source_comparisons = {}
for name, text in fixture["sourceTexts"].items():
    path = ROOT / "tools/keyboard-circuit/phase2/staged" / name
    fixture_hash = hashlib.sha256(text.encode("utf-8")).hexdigest()
    source_comparisons[name] = {"fixtureSha256": fixture_hash, "currentStagedSha256": sha(path), "matches": fixture_hash == sha(path)}


def group(name):
    return lambda row: row["group"] == name


def named(name, child):
    return lambda row: row["group"] == name and child in row["short"]


def endpoint(name, end):
    return next(row for row in actual if row["group"] == name and (row["kind"] == "checkpoint" or f".{end}." in row["short"] or f".{end}Bank." in row["short"]))


adjacent = []
transfers = []
for i, before in enumerate(r.main):
    after = r.main[(i + 1) % len(r.main)]
    first, last = endpoint(before, "Exit"), endpoint(after, "Entry")
    edge = before + "To" + after
    metric = r.jump(first, last)
    metric.update({"edge": edge, "meshSkinGap": r.distance(r.polygon(first, -.1), r.polygon(last, -.1))})
    adjacent.append(metric)
    links = sorted([row for row in actual if row["group"] == before + "_to_" + after], key=lambda row: int(re.search(r"_(\d+)\.BankContact", row["short"])[1]))
    chain = [first] + links + [last]
    for a, b in zip(chain, chain[1:]):
        metric = r.jump(a, b)
        metric["edge"] = edge
        transfers.append(metric)

endpoint_overlays, interior_overlays = [], []
for connector in [row for row in actual if row["kind"] == "connector"]:
    before, after = connector["group"].split("_to_")
    for name, end in [(before, "Exit"), (after, "Entry")]:
        target = endpoint(name, end)
        gap = r.distance(r.polygon(connector, -.1), r.polygon(target, -.1))
        if gap < .01:
            endpoint_overlays.append({"connector": connector["short"], "target": target["short"], "meshSkinGap": gap})
    for target in actual:
        if target["group"] not in connector["anchors"] or target["kind"] != "sequence" or "Entry" in target["short"] or "Exit" in target["short"]:
            continue
        if r.distance(r.polygon(connector, -.1), r.polygon(target, -.1)) < .01:
            interior_overlays.append(r.jump(connector, target))

nonadjacent = []
for i, a in enumerate(actual):
    for b in actual[i + 1:]:
        if r.scope["allowed_pair"](a, b) or {a["kind"], b["kind"]} & {"expert", "recovery"}:
            continue
        for first, last in [(a, b), (b, a)]:
            metric = r.jump(first, last)
            if metric["feasibleByIdealPointMath"]:
                nonadjacent.append(metric)

recovery_bays = {gate: r.minimum_between(actual, group("Recovery_" + gate), group(gate)) for gate in ["F00", "CP1", "CP2", "CP3"]}
recovery_metrics, recovery_risks = {}, []
for gate in ["CP2", "CP3"]:
    for source in ["O04", "O05", "O06", "O07", "X01", "X02"]:
        metric = r.minimum_between(actual, group(source), group("Recovery_" + gate), .35 if source.startswith("X") else .6)
        recovery_metrics[source + "ToRecovery_" + gate] = metric
        if metric["feasibleByIdealPointMath"]:
            recovery_risks.append(metric)

expert_metrics = {}
for name, before, after in [("X01", "H04", "CP2"), ("X02", "H07", "CP3")]:
    caps = sorted([row for row in actual if row["group"] == name], key=lambda row: int(re.search(r"PrecisionLanding(\d+)", row["short"])[1]))
    chain = [endpoint(before, "Exit")] + caps + [endpoint(after, "Entry")]
    full = [r.jump(a, b, .35) for a, b in zip(chain, chain[1:])]
    internal = [r.jump(a, b, .35) for a, b in zip(caps, caps[1:])]
    skips = [r.jump(a, caps[i + 2], .35) for i, a in enumerate(caps[:-2])]
    expert_metrics[name] = {"caps": len(caps), "fullChainJumps": full, "minimumFullChainInsetMargin": min(m["idealMargin"] for m in full), "minimumCapJumpInsetMargin": min(m["idealMargin"] for m in internal), "oneLandingSkipCandidates": [m for m in skips if m["feasibleByIdealPointMath"]]}

# Static traversal point names and jump flags are unchanged from the retained first native snapshot.
static_jumps = []
for unit in r.native["units"]:
    if not re.fullmatch(r"O\d\d", unit["id"]):
        continue
    rows = [row for row in actual if row["group"] == unit["id"]]
    for i, point in enumerate(unit["points"][1:], 1):
        if not point["jump"]:
            continue
        before = unit["points"][i - 1]
        def surfaces(name):
            return [row for row in rows if "EnterHairpin." in row["short"]] if name in {"EnterStem", "EnterTurn"} else [row for row in rows if f".{name}." in row["short"]]
        options = [r.jump(a, b) for a in surfaces(before["name"]) for b in surfaces(point["name"])]
        assert options, (unit["id"], before["name"], point["name"])
        best = max(options, key=lambda m: m["idealMargin"] if m["idealMargin"] is not None else -float("inf"))
        best.update({"sequence": unit["id"], "authoredFrom": before["name"], "authoredTo": point["name"]})
        static_jumps.append(best)

nodes = r.baseline | {"O08": [-128, 2, 60]}
o08_frame = r.frame(nodes, {}, "O08")
connector_max_x = max(r.local_point([x, row["top"], z], o08_frame)[0] for row in actual if row["group"] == "H01_to_O08" for x, z in row["poly"])
entry = endpoint("O08", "Entry")
entry_forward_x = max(r.local_point([x, entry["top"], z], o08_frame)[0] for x, z in entry["poly"])
rotary = next(row for row in native["blockers"] if "RotaryDial" in row["path"])
cp3_pad = next(row for row in actual if row["group"] == "Recovery_CP3")
rotary_gap = r.distance(cp3_pad["poly"], r.polygon(rotary))

focused = {
    "O07ToF01": r.minimum_between(actual, group("O07"), group("F01")),
    "H08ExitToH01Entry": r.minimum_between(actual, named("H08", "ExitBank"), named("H01", "EntryBank")),
    "H01MiddleToOutgoingConnector": r.minimum_between(actual, named("H01", "PermanentCtrlRefuge"), group("H01_to_O08")),
    "H01IncomingToMiddle": r.minimum_between(actual, group("H08_to_H01"), named("H01", "PermanentCtrlRefuge")),
}
checks = {
    "134UniqueMatchingContactPaths": len(actual) == len(offline) == 134 and not missing_native and not extra_native,
    "ContactTransformsAndSizesAgree": all(m["positionError"] < .004 and m["frameComponentError"] < .0002 and m["sizeComponentError"] < .0002 and m["roleMatches"] for m in comparisons),
    "All16CurrentStagedSourcesMatchFixture": len(source_comparisons) == 16 and all(v["matches"] for v in source_comparisons.values()),
    "NativeBuildHasNoReportedSourceOrReferenceFailures": not native["sourceMismatches"] and not native["failures"],
    "21DirectAdjacentDecksHaveClearMeshSkins": len(adjacent) == 21 and all(m["meshSkinGap"] > .2 for m in adjacent),
    "ConnectorsDoNotOverlayEndpointOrInteriorMeshGrids": not endpoint_overlays and not interior_overlays,
    "MainNonadjacentShortcutScanClear": not nonadjacent,
    "FocusedRecoveryShortcutScanClear": not recovery_risks,
    "36MainTransfersHavePositiveInsetEnvelope": len(transfers) == 36 and all(m["feasibleByIdealPointMath"] and m["idealMargin"] > 1 for m in transfers),
    "24StaticJumpEnvelopesRemainPositive": len(static_jumps) == 24 and all(m["feasibleByIdealPointMath"] for m in static_jumps),
    "BothFullTrimmedExpertChainsHavePositiveInsetEnvelope": all(all(m["feasibleByIdealPointMath"] for m in e["fullChainJumps"]) and e["minimumCapJumpInsetMargin"] > 2 for e in expert_metrics.values()),
    "NoOneLandingExpertSkipCandidates": all(not e["oneLandingSkipCandidates"] for e in expert_metrics.values()),
    "FourRecoveryPadsHaveClearBayJumps": all(m["feasibleByIdealPointMath"] and m["idealMargin"] > 2 for m in recovery_bays.values()),
    "O08ForwardEntryStripClear": entry_forward_x - connector_max_x > 3,
    "RotaryDialOutsideCP3RecoveryApproach": rotary_gap > 20,
    "O07ToF01AndH01MiddleConnectorRisksClosed": all(not focused[k]["feasibleByIdealPointMath"] for k in ["O07ToF01", "H01MiddleToOutgoingConnector", "H01IncomingToMiddle"]),
}
report = {
    "status": "native_iteration02_targeted_rest_geometry_checks_passed" if all(checks.values()) else "native_iteration02_targeted_geometry_or_source_difference_found",
    "nativeRevision": native["revision"], "nativeIteration": native["iteration"], "layoutRevision": fixture["layoutRevision"],
    "nativeInput": str(NATIVE_PATH.relative_to(ROOT)), "nativeInputSha256": sha(NATIVE_PATH),
    "offlineFixtureInput": str(FIXTURE_PATH.relative_to(ROOT)), "offlineFixtureSha256": sha(FIXTURE_PATH),
    "checks": checks,
    "contactAgreement": {"nativeContacts": len(actual), "offlineContacts": len(offline), "matchedContacts": len(comparisons), "missingNativePaths": missing_native, "extraNativePaths": extra_native, "maxPositionError": max(m["positionError"] for m in comparisons), "maxFrameComponentError": max(m["frameComponentError"] for m in comparisons), "maxSizeComponentError": max(m["sizeComponentError"] for m in comparisons), "rows": comparisons},
    "sourceComparisons": source_comparisons, "reportedNativeCounts": native["counts"],
    "focusedRepairMetrics": focused, "adjacentDeckMetrics": adjacent,
    "connectorEndpointMeshOverlays": endpoint_overlays, "connectorInteriorMeshOverlays": interior_overlays,
    "nonadjacentMainConnectorReachablePairs": nonadjacent, "focusedRecoveryRiskPairs": recovery_risks, "focusedRecoveryMetrics": recovery_metrics,
    "mainTransferJumps": transfers, "normalStaticJumps": static_jumps, "expertMetrics": expert_metrics, "recoveryPadToBayJumps": recovery_bays,
    "O08ForwardEntryClearStrip": entry_forward_x - connector_max_x, "CP3RecoveryToRotaryDialFootprintGap": rotary_gap,
    "movement": {"walkSpeed": 16, "jumpHeight": 7.2, "gravity": 196.2, "mainLandingInsetPerSurface": .6, "expertLandingInsetPerSurface": .35},
    "limits": "Uses actual native iteration2 Edit/rest contact transforms. Contact agreement is independent of lead avatar results. Native source/reference/count fields are retained input reports; this helper additionally compared all16 staged source bytes to the fixture. Optimistic ballistic point envelopes assume full speed and ignore acceleration, head/body clearance, motion phases, physical carrying, humanoid input/state and hazards. Main nonadjacent scan omits experts/recovery; the explicitly listed recovery pairs are separately checked. Static hairpin envelopes choose the best matching nested contact footprint and do not prove the continuous hairpin path. No avatar traversal, crowd capacity, lap/race duration, device, FPS, performance, camera or judge acceptance is claimed.",
}
receipt_path = ARTIFACT / "p2_route_native_iteration02_receipt.json"
receipt_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps({"status": report["status"], "checks": checks, "contactAgreement": {k: v for k, v in report["contactAgreement"].items() if k != "rows"}, "minimumMainTransferMargin": min(m["idealMargin"] for m in transfers), "minimumStaticJumpMargin": min(m["idealMargin"] for m in static_jumps), "expertCapMargins": {k: v["minimumCapJumpInsetMargin"] for k, v in expert_metrics.items()}, "O08ForwardEntryClearStrip": report["O08ForwardEntryClearStrip"], "CP3RecoveryToRotaryDialFootprintGap": rotary_gap}, indent=2))
if not all(checks.values()):
    raise SystemExit(1)
