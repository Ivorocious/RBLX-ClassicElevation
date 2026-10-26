import hashlib
import json
import math
import re
from pathlib import Path

ROOT = Path.cwd()
INPUT = ROOT / "docs/artifacts/keyboard-circuit/phase2/P2-C01-native-geometry.json"
OUTPUT = ROOT / "docs/artifacts/keyboard-circuit/phase2/research/p2_route_C01_geometry_preflight.json"
data = json.loads(INPUT.read_text(encoding="utf-8-sig"))
main = ["F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"]
index = {name: i for i, name in enumerate(main)}
gravity, speed, height = 196.2, 16.0, 7.2
launch = math.sqrt(2 * gravity * height)


def compact(path):
    return path.rsplit("KeyboardCircuit_P2_C01.", 1)[-1]


def meta(row):
    path = compact(row["path"])
    if path.startswith("RouteLinks."):
        match = re.search(r"RouteLinks\.((\w+)_to_(\w+))_\d+", path)
        return match[1], "connector", {match[2], match[3]}
    if path.startswith("RecoveryPads."):
        gate = path.split(".")[1]
        return "Recovery_" + gate, "recovery", {gate}
    if path.startswith("CheckpointBays.RecoveryMerge_"):
        gate = path.split(".")[1].split("_", 1)[1]
        return "RecoveryMerge_" + gate, "recovery", {gate}
    if path.startswith("CheckpointBays."):
        gate = path.split(".")[1]
        return gate, "checkpoint", {gate}
    match = re.search(r"\.([OHX]\d\d)(?:_|\.)", path)
    group = match[1]
    return group, "expert" if group.startswith("X") else "sequence", {group}


def polygon(row, inset=0):
    cf, size = row["cf"], row["size"]
    hx, hz = max(0, size[0] / 2 - inset), max(0, size[2] / 2 - inset)
    a, b, center = (cf[3], cf[9]), (cf[5], cf[11]), (cf[0], cf[2])
    return [(center[0] + sx * hx * a[0] + sz * hz * b[0], center[1] + sx * hx * a[1] + sz * hz * b[1]) for sx, sz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def overlap(a, b):
    depth = float("inf")
    for shape in [a, b]:
        for i, p in enumerate(shape):
            q = shape[(i + 1) % len(shape)]
            axis = (-(q[1] - p[1]), q[0] - p[0])
            length = math.hypot(*axis)
            if length < 1e-9:
                continue
            axis = (axis[0] / length, axis[1] / length)
            aa, bb = [dot(v, axis) for v in a], [dot(v, axis) for v in b]
            distance = min(max(aa), max(bb)) - max(min(aa), min(bb))
            if distance < -1e-7:
                return False, 0
            depth = min(depth, max(0, distance))
    return True, depth


def segment_point(p, a, b):
    ab = (b[0] - a[0], b[1] - a[1])
    divisor = dot(ab, ab)
    t = max(0, min(1, dot((p[0] - a[0], p[1] - a[1]), ab) / divisor)) if divisor else 0
    q = (a[0] + t * ab[0], a[1] + t * ab[1])
    return math.dist(p, q), q


def distance(a, b):
    if overlap(a, b)[0]:
        return 0.0
    candidates = []
    for first, second in [(a, b), (b, a)]:
        for p in first:
            for i, q in enumerate(second):
                candidates.append(segment_point(p, q, second[(i + 1) % len(second)])[0])
    return min(candidates)


def maximum_range(dy):
    discriminant = launch * launch - 2 * gravity * dy
    return None if discriminant < 0 else speed * (launch + math.sqrt(discriminant)) / gravity


contacts = []
for row in data["contacts"]:
    row = dict(row)
    row["short"] = compact(row["path"])
    row["group"], row["kind"], row["anchors"] = meta(row)
    row["top"] = row["position"][1] + row["size"][1] / 2
    row["poly"] = polygon(row)
    row["moving"] = bool(re.search(r"RideableBank|Spacebar[12]|Lane[12]Row[123]|ShiftBridge[12]", row["short"]))
    contacts.append(row)


def jump(a, b, inset=.6):
    dy = b["top"] - a["top"]
    limit = maximum_range(dy)
    raw = distance(a["poly"], b["poly"])
    useful = distance(polygon(a, inset), polygon(b, inset))
    return {"from": a["short"], "to": b["short"], "heightChange": dy, "footprintGap": raw, "insetGap": useful, "insetPerSurface": inset, "idealMaxRange": limit, "idealMargin": None if limit is None else limit - useful, "feasibleByIdealPointMath": limit is not None and useful <= limit}


def allowed_pair(a, b):
    if a["group"] == b["group"]:
        return True
    if a["kind"] == "connector" and b["anchors"] <= a["anchors"]:
        return True
    if b["kind"] == "connector" and a["anchors"] <= b["anchors"]:
        return True
    if a["kind"] in {"checkpoint", "recovery"} and b["kind"] in {"checkpoint", "recovery"} and a["anchors"] == b["anchors"]:
        return True
    if a["group"] in index and b["group"] in index:
        delta = abs(index[a["group"]] - index[b["group"]])
        return delta in {1, len(main) - 1}
    for expert, ends in [("X01", {"H04", "CP2"}), ("X02", {"H07", "CP3"})]:
        if (a["group"] == expert and b["group"] in ends) or (b["group"] == expert and a["group"] in ends):
            return True
    return False


pairs = []
for i, a in enumerate(contacts):
    for b in contacts[i + 1:]:
        if allowed_pair(a, b):
            continue
        raw_gap = distance(a["poly"], b["poly"])
        if raw_gap > 12:
            continue
        for start, finish in [(a, b), (b, a)]:
            metric = jump(start, finish, .35 if start["kind"] == "expert" or finish["kind"] == "expert" else .6)
            if not metric["feasibleByIdealPointMath"]:
                continue
            _, penetration = overlap(start["poly"], finish["poly"])
            metric.update({"fromGroup": start["group"], "toGroup": finish["group"], "fromKind": start["kind"], "toKind": finish["kind"], "footprintOverlapDepth": penetration, "motionDependent": start["moving"] or finish["moving"]})
            pairs.append(metric)

groups = {}
for pair in pairs:
    key = (pair["fromGroup"], pair["toGroup"])
    if key not in groups or pair["insetGap"] < groups[key]["insetGap"]:
        groups[key] = pair

intrusions = []
for connector in contacts:
    if connector["kind"] != "connector":
        continue
    from_id, to_id = connector["group"].split("_to_")
    for target in contacts:
        if target["group"] not in {from_id, to_id} or target["kind"] != "sequence":
            continue
        endpoint_name = "Exit" if target["group"] == from_id else "Entry"
        if re.search(rf"\.{endpoint_name}(?:Bank)?\.", target["short"]):
            continue
        metric = jump(connector, target, .6)
        if metric["feasibleByIdealPointMath"]:
            metric.update({"connector": connector["group"], "targetSequence": target["group"], "targetMoving": target["moving"]})
            intrusions.append(metric)

repair_metrics = []
original_exit = next(c for c in contacts if c["group"] == "O07" and ".Exit." in c["short"])
last_arrow = next(c for c in contacts if c["group"] == "O07" and ".ArrowTurnLeft." in c["short"])
final_bay = next(c for c in contacts if c["group"] == "F01")
for sideways in [8, 10, 12]:
    proposed = dict(original_exit)
    proposed["cf"] = list(original_exit["cf"])
    for component, axis in [(0, 5), (1, 8), (2, 11)]:
        proposed["cf"][component] += original_exit["cf"][axis] * sideways
    proposed["position"] = proposed["cf"][:3]
    proposed["poly"] = polygon(proposed)
    onward = jump(proposed, final_bay)
    required = jump(last_arrow, proposed)
    repair_metrics.append({"proposal": f"Move O07 Exit from local z0 to z{sideways}; keep its y/x and other O07 banks", "exitPosition": proposed["position"], "O07FinalNormalJump": required, "F01Bypass": onward})

normal_jumps = []
for unit in data["units"]:
    if not re.fullmatch(r"O\d\d", unit["id"]):
        continue
    points = unit["points"]
    matching = [c for c in contacts if c["group"] == unit["id"]]
    for i, point in enumerate(points[1:], 1):
        if not point["jump"]:
            continue
        before = points[i - 1]
        def surfaces(name):
            if name in {"EnterStem", "EnterTurn"}:
                return [c for c in matching if "EnterHairpin." in c["short"]]
            return [c for c in matching if f".{name}." in c["short"]]
        aa, bb = surfaces(before["name"]), surfaces(point["name"])
        assert aa and bb, (unit["id"], before["name"], point["name"])
        metrics = [jump(a, b) for a in aa for b in bb]
        best = max(metrics, key=lambda item: item["idealMargin"] if item["idealMargin"] is not None else -float("inf"))
        best.update({"sequence": unit["id"], "authoredFrom": before["name"], "authoredTo": point["name"]})
        normal_jumps.append(best)

expert_jumps, expert_skips = [], []
for expert in data["experts"]:
    name = expert["id"]
    caps = sorted([c for c in contacts if c["group"] == name], key=lambda c: int(re.search(r"PrecisionLanding(\d+)", c["short"])[1]))
    before_id, after_id = ("H04", "CP2") if name == "X01" else ("H07", "CP3")
    before = next(c for c in contacts if c["group"] == before_id and ".ExitBank." in c["short"])
    after = next(c for c in contacts if c["kind"] == "checkpoint" and c["group"] == after_id)
    chain = [before] + caps + [after]
    for i, (a, b) in enumerate(zip(chain, chain[1:])):
        metric = jump(a, b, .35)
        metric.update({"expert": name, "segment": i + 1})
        expert_jumps.append(metric)
    for i, a in enumerate(caps):
        for j in range(i + 2, min(len(caps), i + 5)):
            metric = jump(a, caps[j], .35)
            if metric["feasibleByIdealPointMath"]:
                metric.update({"expert": name, "skippedLandings": j - i - 1})
                expert_skips.append(metric)

report = {
    "revision": data["revision"], "input": str(INPUT.relative_to(ROOT)), "inputSha256": hashlib.sha256(INPUT.read_bytes()).hexdigest(),
    "status": "geometry_risks_found", "contacts": len(contacts), "movement": {"walkSpeed": speed, "jumpHeight": height, "gravity": gravity, "idealSameHeightRange": maximum_range(0)},
    "normalStaticJumps": normal_jumps, "expertJumps": expert_jumps, "expertPotentialSkips": expert_skips,
    "nonadjacentReachableGroups": sorted(groups.values(), key=lambda p: (p["motionDependent"], p["insetGap"], abs(p["heightChange"]))),
    "nonadjacentReachablePairs": sorted(pairs, key=lambda p: (p["motionDependent"], p["insetGap"], abs(p["heightChange"]))),
    "connectorEndpointEncounterIntrusions": sorted(intrusions, key=lambda p: (p["connector"], p["insetGap"])), "O07ExitRepairPredictions": repair_metrics,
    "limits": "Oriented contact-footprint geometry and optimistic point-ballistic jump envelope at full WalkSpeed16; no engine input, acceleration, jump state, contact, dynamic phase, humanoid body clearance, hazard or blocker geometry, camera, network or human difficulty proof. Allowed adjacent unit pairs are omitted; connector crossings within their own endpoint encounters need manual review. Footprint overlap at different heights is not automatically a physical overlap or traversable bypass."
}
OUTPUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
summary = {"contacts": len(contacts), "normalJumps": len(normal_jumps), "minimumNormalMargin": min(p["idealMargin"] for p in normal_jumps), "expertJumps": len(expert_jumps), "minimumExpertMargin": min(p["idealMargin"] for p in expert_jumps), "reachableNonadjacentGroups": len(groups), "potentialExpertCapSkips": len(expert_skips)}
print(json.dumps(summary, indent=2))
for p in report["nonadjacentReachableGroups"]:
    print(f'{p["fromGroup"]} -> {p["toGroup"]}: gap{p["footprintGap"]:.2f}, inset{p["insetGap"]:.2f}, dy{p["heightChange"]:.2f}, margin{p["idealMargin"]:.2f}, moving={p["motionDependent"]} | {p["from"].split(".")[-2]} -> {p["to"].split(".")[-2]}')
print("TIGHT EXPERT SEGMENTS")
for p in sorted(expert_jumps, key=lambda p: p["idealMargin"])[:10]:
    print(f'{p["expert"]} segment{p["segment"]}: gap{p["footprintGap"]:.2f}, inset{p["insetGap"]:.2f}, dy{p["heightChange"]:.2f}, limit{p["idealMaxRange"]:.2f}, margin{p["idealMargin"]:.2f}')
print("CONNECTOR INTRUSIONS")
for p in intrusions:
    if p["targetSequence"] not in {"H01", "H08"}:
        continue
    print(f'{p["connector"]} via {p["from"].split(".")[-2]} -> {p["to"].split(".")[-2]}: raw{p["footprintGap"]:.2f}, inset{p["insetGap"]:.2f}, dy{p["heightChange"]:.2f}, moving={p["targetMoving"]}')
print("O07 REPAIR PREDICTIONS")
for p in repair_metrics:
    print(p["proposal"], "normal margin", round(p["O07FinalNormalJump"]["idealMargin"], 3), "bypass margin", round(p["F01Bypass"]["idealMargin"], 3), "raw bypass", round(p["F01Bypass"]["footprintGap"], 3))
