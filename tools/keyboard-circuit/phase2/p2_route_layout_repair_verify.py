import copy
import hashlib
import json
import math
import re
from pathlib import Path

import p2_route_layout_reconstruction as r

ROOT = Path.cwd()
artifact = ROOT / "docs/artifacts/keyboard-circuit/phase2/research"
fixture_path = artifact / "p2_route_layout_course_fixture.json"
fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
proposal = {
    "nodes": {"F00": [-144, 0, 149], "O01": [-168, 0, 96.5], "O02": [-169.5, 2, -36], "O07": [-46.5, 10, 148.5], "H08": [-60, 7, 74.5], "H01": [-83.5, 4, 2], "O08": [-128, 2, 60], "X01": [70, 11, 0], "X02": [33, 13, 110]},
    "headings": {"O03": [2, 1], "H06": [-1, 0], "CP3": [-1, 0], "H01": [-23.5, -72.5], "CP2": [3, 4]},
    "recoveryOffsets": {"F00": [0, 0, -31], "CP1": [0, 0, 31], "CP2": [0, 0, -31], "CP3": [-12, 0, -28]},
    "contactAwareConnections": True,
    "removeRecoveryMerge": True,
    "experts": {name: {"arcLength": True, "arcSamples": 64, "spacingTarget": 6.5, "trimCommon": True} for name in ["X01", "X02"]},
}
predicted, ends, expert_formula, _ = r.assess(proposal)
actual = r.annotate(copy.deepcopy(fixture["contacts"]))
exec("def allowed_pair(" + r.library.split("def allowed_pair(")[1].split("\n\npairs = []")[0], r.scope)


def key(row):
    path = row["short"].replace("X01_SwitchSpine", "X01").replace("X02_BracketCut", "X02")
    return path.replace(".BankContact", "") if row["group"].startswith("Recovery_") else path


actual_by_key = {key(c): c for c in actual}
predicted_by_key = {key(c): c for c in predicted}
assert actual_by_key.keys() == predicted_by_key.keys()
max_position_error = max(math.dist(actual_by_key[k]["position"], predicted_by_key[k]["position"]) for k in actual_by_key)
max_frame_error = max(abs(actual_by_key[k]["cf"][i] - predicted_by_key[k]["cf"][i]) for k in actual_by_key for i in range(3, 12))
assert max_position_error < .004 and max_frame_error < .0002


def group(name):
    return lambda c: c["group"] == name


def named(name, child):
    return lambda c: c["group"] == name and child in c["short"]


main_metrics = {
    "O07ToF01": r.minimum_between(actual, group("O07"), group("F01")),
    "H08ExitToH01Entry": r.minimum_between(actual, named("H08", "ExitBank"), named("H01", "EntryBank")),
    "H01MiddleToOutgoingConnector": r.minimum_between(actual, named("H01", "PermanentCtrlRefuge"), group("H01_to_O08")),
    "H01IncomingToMiddle": r.minimum_between(actual, group("H08_to_H01"), named("H01", "PermanentCtrlRefuge")),
    "O04ToCurrentCP2Recovery": r.minimum_between(actual, group("O04"), group("Recovery_CP2")),
    "O05ToCurrentCP2Recovery": r.minimum_between(actual, group("O05"), group("Recovery_CP2")),
}
assert not main_metrics["O07ToF01"]["feasibleByIdealPointMath"]
assert main_metrics["H08ExitToH01Entry"]["footprintGap"] > 4
assert main_metrics["H08ExitToH01Entry"]["idealMargin"] > 2
assert not main_metrics["H01MiddleToOutgoingConnector"]["feasibleByIdealPointMath"]
assert not main_metrics["H01IncomingToMiddle"]["feasibleByIdealPointMath"]
assert not main_metrics["O04ToCurrentCP2Recovery"]["feasibleByIdealPointMath"]
assert not main_metrics["O05ToCurrentCP2Recovery"]["feasibleByIdealPointMath"]

nonadjacent = []
for i, a in enumerate(actual):
    for b in actual[i + 1:]:
        if r.scope["allowed_pair"](a, b) or {a["kind"], b["kind"]} & {"expert", "recovery"}:
            continue
        if r.distance(a["poly"], b["poly"]) > 12:
            continue
        for first, last in [(a, b), (b, a)]:
            metric = r.jump(first, last)
            if metric["feasibleByIdealPointMath"]:
                nonadjacent.append(metric)
assert not nonadjacent

nodes = {**r.baseline, **proposal["nodes"]}
o08_frame = r.frame(nodes, proposal["headings"], "O08")
connector_max_x = max(r.local_point([x, c["top"], z], o08_frame)[0] for c in actual if c["group"] == "H01_to_O08" for x, z in c["poly"])
entry = next(c for c in actual if c["group"] == "O08" and ".Entry." in c["short"])
entry_forward_x = max(r.local_point([x, entry["top"], z], o08_frame)[0] for x, z in entry["poly"])
assert entry_forward_x - connector_max_x > 3


def expert_summary(rows, name):
    caps = sorted([c for c in rows if c["group"] == name], key=lambda c: int(re.search(r"PrecisionLanding(\d+)", c["short"])[1]))
    metrics = [r.jump(a, b, .35) for a, b in zip(caps, caps[1:])]
    skips = [r.jump(a, caps[i + 2], .35) for i, a in enumerate(caps[:-2])]
    return {"caps": len(caps), "minimumCapJumpInsetMargin": min(m["idealMargin"] for m in metrics), "adjacentCapSkipsByIdealMath": sum(m["feasibleByIdealPointMath"] for m in skips), "capJumps": metrics}


current_experts = {name: expert_summary(actual, name) for name in ["X01", "X02"]}
assert all(e["minimumCapJumpInsetMargin"] > 1 for e in current_experts.values())
for name, before, after in [("X01", "H04", "CP2"), ("X02", "H07", "CP3")]:
    caps = sorted([c for c in actual if c["group"] == name], key=lambda c: int(re.search(r"PrecisionLanding(\d+)", c["short"])[1]))
    chain = [next(c for c in actual if c["group"] == before and ".ExitBank." in c["short"])] + caps + [next(c for c in actual if c["group"] == after)]
    full = [r.jump(a, b, .35) for a, b in zip(chain, chain[1:])]
    assert all(m["feasibleByIdealPointMath"] for m in full)
    current_experts[name]["fullChainJumpsIncludingTrimmedEndpoints"] = full
    current_experts[name]["minimumFullChainInsetMargin"] = min(m["idealMargin"] for m in full)
parent_proposal = copy.deepcopy(proposal)
parent_proposal["experts"] = proposal["experts"]
future, _, future_formula, _ = r.assess(parent_proposal)
future_experts = {name: expert_summary(future, name) for name in ["X01", "X02"]}
assert all(e["minimumCapJumpInsetMargin"] > 2 and not e["adjacentCapSkipsByIdealMath"] for e in future_experts.values())
recovery_metrics = {}
recovery_risks = []
for gate in ["CP2", "CP3"]:
    for source in ["O04", "O05", "O06", "O07", "X01", "X02"]:
        for target in ["Recovery_" + gate]:
            metric = r.minimum_between(future, group(source), group(target), .35 if source.startswith("X") else .6)
            if metric["feasibleByIdealPointMath"]:
                recovery_risks.append({"source": source, "target": target, **metric})
            recovery_metrics[source + "To" + target] = metric

def endpoint(rows, name, end):
    return next(c for c in rows if c["group"] == name and (c["kind"] == "checkpoint" or f".{end}." in c["short"] or f".{end}Bank." in c["short"]))

old_rows = r.annotate(copy.deepcopy(r.native["contacts"]))
adjacent_decks = []
for i, name in enumerate(r.main):
    after = r.main[(i + 1) % len(r.main)]
    first, last = endpoint(actual, name, "Exit"), endpoint(actual, after, "Entry")
    old_first, old_last = endpoint(old_rows, name, "Exit"), endpoint(old_rows, after, "Entry")
    metric = r.jump(first, last)
    metric.update({"edge": name + "To" + after, "C01BareFootprintGap": r.distance(old_first["poly"], old_last["poly"]), "currentMeshSkinGap": r.distance(r.polygon(first, -.1), r.polygon(last, -.1)), "note": "Skin rectangles expand BankContact by0.1 per edge to account for the accepted ordinary caps."})
    adjacent_decks.append(metric)

connector_overlays = []
for row in actual:
    if row["kind"] != "connector":
        continue
    before, after = row["group"].split("_to_")
    for name, end in [(before, "Exit"), (after, "Entry")]:
        target = endpoint(actual, name, end)
        skin_gap = r.distance(r.polygon(row, -.1), r.polygon(target, -.1))
        if skin_gap < .01:
            metric = r.jump(row, target)
            metric.update({"connector": row["group"], "target": name, "currentMeshSkinGap": skin_gap})
            connector_overlays.append(metric)

recovery_jumps = {gate: r.minimum_between(actual, group("Recovery_" + gate), group(gate)) for gate in ["F00", "CP1", "CP2", "CP3"]}
assert all(m["feasibleByIdealPointMath"] and m["idealMargin"] > 2 for m in recovery_jumps.values())
assert not recovery_risks
assert all(m["currentMeshSkinGap"] > .2 for m in adjacent_decks)
assert not connector_overlays
connector_interior_overlays = []
for row in actual:
    if row["kind"] != "connector":
        continue
    for target in actual:
        if target["group"] not in row["anchors"] or target["kind"] != "sequence" or "Entry" in target["short"] or "Exit" in target["short"]:
            continue
        if r.distance(r.polygon(row, -.1), r.polygon(target, -.1)) < .01:
            connector_interior_overlays.append(r.jump(row, target))
assert not connector_interior_overlays
transfer_jumps = []
for i, name in enumerate(r.main):
    after = r.main[(i + 1) % len(r.main)]
    links = sorted([c for c in actual if c["group"] == name + "_to_" + after], key=lambda c: int(re.search(r"_(\d+)\.BankContact", c["short"])[1]))
    chain = [endpoint(actual, name, "Exit")] + links + [endpoint(actual, after, "Entry")]
    for first, last in zip(chain, chain[1:]):
        metric = r.jump(first, last)
        metric["edge"] = name + "To" + after
        transfer_jumps.append(metric)
assert all(m["feasibleByIdealPointMath"] and m["idealMargin"] > 1 for m in transfer_jumps)

rough_blockers = [c for c in fixture["colliders"] if c.get("role") == "SolidBlocker"]
rough_metrics = []
for name in ["Recovery_CP2", "Recovery_CP3"]:
    pad = next(c for c in future if c["group"] == name)
    for blocker in rough_blockers:
        if pad["top"] + 6 < blocker["position"][1] - blocker["size"][1] / 2 or pad["top"] > blocker["position"][1] + blocker["size"][1] / 2:
            continue
        rough_metrics.append({"pad": name, "blocker": blocker["path"], "bareFootprintGap": r.distance(pad["poly"], r.polygon(blocker))})
rotary = next(c for c in rough_blockers if "RotaryDial" in c["path"])
cp3pad = next(c for c in future if c["group"] == "Recovery_CP3")
rotary_clearance = r.distance(cp3pad["poly"], r.polygon(rotary))
assert rotary_clearance > 20

layout_path = ROOT / "tools/keyboard-circuit/phase2/p2_route_layout_proposed.luau"
report = {
    "status": "targeted_layout_and_connector_geometry_verified_offline",
    "layoutRevision": "KC_LAYOUT_P2_03",
    "layoutSha256": hashlib.sha256(layout_path.read_bytes()).hexdigest(),
    "retainedFailedC01Receipt": "p2_route_C01_geometry_preflight.json",
    "nativeC01GeometrySha256": hashlib.sha256(r.scope["INPUT"].read_bytes()).hexdigest(),
    "offlineCourseFixtureSha256": hashlib.sha256(fixture_path.read_bytes()).hexdigest(),
    "actualSourceHashes": {name: hashlib.sha256(content.encode("utf-8")).hexdigest() for name, content in fixture["sourceTexts"].items()},
    "actualStagedCourse": {"compiledSources": fixture["compiledSources"], "contacts": len(actual), "colliders": len(fixture["colliders"]), "sequences": fixture["sequenceCount"], "mechanisms": fixture["mechanismCount"], "experts": fixture["expertCount"]},
    "predictionAgreement": {"maxPositionError": max_position_error, "maxFrameComponentError": max_frame_error},
    "layoutProposal": proposal,
    "mainMetrics": main_metrics,
    "adjacentDeckMetrics": adjacent_decks,
    "remainingDirectAdjacentMeshOverlaps": [m for m in adjacent_decks if m["currentMeshSkinGap"] < .01],
    "currentConnectorEndpointMeshOverlays": connector_overlays,
    "currentConnectorInteriorMeshOverlays": connector_interior_overlays,
    "mainTransferJumps": transfer_jumps,
    "recoveryPadToBayJumps": recovery_jumps,
    "currentRecoveryRiskPairs": recovery_risks,
    "nonadjacentMainConnectorReachablePairs": nonadjacent,
    "O08EntryForwardEdge": {"localForwardX": entry_forward_x, "incomingBankMaximumLocalX": connector_max_x, "clearStrip": entry_forward_x - connector_max_x},
    "currentCourseExpertFormula": expert_formula,
    "currentExpertMargins": current_experts,
    "parentOwnedRepairs": {"proposal": parent_proposal, "recoveryMergeBanks": 0, "expertFormula": future_formula, "expertMargins": future_experts, "recoveryMetrics": recovery_metrics, "roughBlockerMetrics": rough_metrics, "RotaryDialMoveAlreadyInParentSource": {"fromRelativePosition": [-5, 13, 211], "toRelativePosition": [-5, 13, 244], "CP3PadBareClearanceAfterMove": rotary_clearance}},
    "limits": "Actual current staged Course was built offline with only proposed Layout replacement. Native C01 frames plus the current parent Course formulas independently predict contacts within stated error. Jump envelopes are optimistic point math at speed16/height7.2; geometry is captured rest geometry, not dynamic phase, body/head clearance, engine carrying/contact, human traversal, capacity, pacing, camera/device, or performance proof. Parent implemented complete recovery-bank Models, offsets, removed merge banks, arc spacing/trim, RotaryDial movement and contact-centered connectors; this helper only owns Layout. This targeted geometric receipt is not whole-course acceptance or a judge score.",
}
(artifact / "p2_route_layout_repair_receipt.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps({"status": report["status"], "contacts": len(actual), "maxPredictionPositionError": max_position_error, "mainShortcutPairs": len(nonadjacent), "O08ClearForwardStrip": entry_forward_x - connector_max_x, "currentExpertMargins": {k: v["minimumCapJumpInsetMargin"] for k, v in current_experts.items()}, "parentArcMargins": {k: v["minimumCapJumpInsetMargin"] for k, v in future_experts.items()}, "parentRotaryMoveClearance": rotary_clearance}, indent=2))
