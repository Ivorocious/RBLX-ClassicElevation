"""Reconstruct contact frames from native C01 plus the unchanged Course formulas."""
import contextlib
import copy
import hashlib
import io
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path.cwd()
library = (ROOT / "tools/keyboard-circuit/phase2/p2_route_C01_geometry_preflight.py").read_text()
scope = {}
exec(library.split("\ncontacts = []")[0], scope)
exec("def jump(" + library.split("def jump(")[1].split("\n\ndef allowed_pair")[0], scope)
original_meta = scope["meta"]
polygon, jump, distance = (scope[k] for k in ["polygon", "jump", "distance"])


def meta(row):
    path = scope["compact"](row["path"])
    match = re.search(r"CheckpointBays\.RecoveryMerge_(CP[123]|F00)(?:_\d+)?\.", path)
    if match:
        return "RecoveryMerge_" + match[1], "recovery", {match[1]}
    return original_meta(row)


scope["meta"] = meta
native, main = scope["data"], scope["main"]
ORIGIN = [3300, 330, -1600]
text = (ROOT / "tools/keyboard-circuit/phase2/p2_route_layout_C01_baseline.luau").read_text()
baseline = {m[1]: [float(m[i]) for i in [2, 3, 4]] for m in re.finditer(r'(\w+) = \{(-?[\d.]+), (-?[\d.]+), (-?[\d.]+), "', text)}


def frame(nodes, headings, name):
    p = [ORIGIN[i] + nodes[name][i] for i in range(3)]
    if name in headings:
        dx, dz = headings[name]
    else:
        b = nodes[main[(main.index(name) + 1) % len(main)]]
        dx, dz = b[0] - nodes[name][0], b[2] - nodes[name][2]
    length = math.hypot(dx, dz)
    return p, (dx / length, dz / length)


def local_point(world, basis):
    p, (dx, dz) = basis
    x, z = world[0] - p[0], world[2] - p[2]
    return [x * dx + z * dz, world[1] - p[1], -x * dz + z * dx]


def world_point(local, basis):
    p, (dx, dz) = basis
    return [p[0] + local[0] * dx - local[2] * dz, p[1] + local[1], p[2] + local[0] * dz + local[2] * dx]


def transformed(row, name, nodes, headings):
    old, new = frame(baseline, {}, name), frame(nodes, headings, name)
    result = copy.deepcopy(row)
    center = world_point(local_point(row["cf"][:3], old), new)
    cf = center[:]
    for r in range(3):
        cf += [0, 0, 0]
    for column in range(3):
        vector = [row["cf"][3 + r * 3 + column] for r in range(3)]
        local = local_point([old[0][i] + vector[i] for i in range(3)], old)
        world = world_point(local, ([0, 0, 0], new[1]))
        for r in range(3):
            cf[3 + r * 3 + column] = world[r]
    result["cf"], result["position"] = cf, center
    return result


def contact(path, p, size, heading=(1, 0)):
    dx, dz = heading
    return {"path": "KeyboardCircuit_P2_C01." + path, "position": [p[0], p[1] - .575, p[2]], "cf": [p[0], p[1] - .575, p[2], dx, 0, -dz, 0, 1, 0, dz, 0, dx], "size": size}


def annotate(rows):
    for row in rows:
        row["short"] = row["path"].rsplit("KeyboardCircuit_P2_C01.", 1)[-1]
        row["group"], row["kind"], row["anchors"] = meta(row)
        row["top"] = row["position"][1] + row["size"][1] / 2
        row["poly"] = polygon(row)
    return rows


def reconstruct(proposal):
    nodes = copy.deepcopy(baseline)
    nodes.update(proposal.get("nodes", {}))
    headings = proposal.get("headings", {})
    rows = []
    for original in native["contacts"]:
        group, kind, anchors = meta(original)
        if kind in {"connector", "expert"}:
            continue
        name = next(iter(anchors))
        if kind == "recovery" and group.startswith("RecoveryMerge_") and proposal.get("removeRecoveryMerge"):
            continue
        row = transformed(original, name, nodes, headings)
        offset = proposal.get("recoveryOffsets", {}).get(name)
        if offset and kind == "recovery":
            center = world_point([offset[0], offset[1] - .575, offset[2]], frame(nodes, headings, name))
            if group.startswith("RecoveryMerge_"):
                center = world_point([offset[0] / 2, offset[1] / 2 - .575, offset[2] / 2], frame(nodes, headings, name))
            row["position"], row["cf"][:3] = center, center
        rows.append(row)
    ends = {}
    for unit in native["units"]:
        name = unit.get("mechanism", unit["id"])
        old, new = frame(baseline, {}, name), frame(nodes, headings, name)
        ends[name] = {k: world_point(local_point(unit[k], old), new) for k in ["entry", "exit"]}
    for name in ["F00", "CP1", "CP2", "CP3", "F01"]:
        basis = frame(nodes, headings, name)
        ends[name] = {"entry": world_point([-10, 0, 0], basis), "exit": world_point([10, 0, 0], basis)}
    for i, name in enumerate(main):
        after = main[(i + 1) % len(main)]
        a, b = ends[name]["exit"], ends[after]["entry"]
        if proposal.get("contactAwareConnections"):
            def endpoint_row(identifier, end):
                return next(c for c in rows if meta(c)[0] == identifier and (meta(c)[1] == "checkpoint" or f".{end}." in c["path"] or f".{end}Bank." in c["path"]))
            first, last = endpoint_row(name, "Exit"), endpoint_row(after, "Entry")
            a, b = ([c["cf"][0], c["cf"][1] + .575, c["cf"][2]] for c in [first, last])
        dx, dz = b[0] - a[0], b[2] - a[2]
        length = math.hypot(dx, dz)
        count = max(0, math.ceil(length / 16) - 1)
        if proposal.get("contactAwareConnections"):
            direction = (dx / length, dz / length)
            def extent(c):
                cf = c["cf"]
                xx = direction[0] * cf[3] + direction[1] * cf[9]
                zz = direction[0] * cf[5] + direction[1] * cf[11]
                return abs(xx) * c["size"][0] / 2 + abs(zz) * c["size"][2] / 2
            from_extent, to_extent = extent(first), extent(last)
            clear = length - from_extent - to_extent
            count = max(0, math.ceil((clear - 4.5) / 19.9))
            if not count:
                continue
            maximum_width = min(15.4, (clear - (count + 1)) / count)
            cells = max(1, min(6, math.floor((maximum_width + .2) / 2.6)))
            width = cells * 2.6 - .2
            gap = (clear - count * width) / (count + 1)
            assert 1 - .001 <= gap <= 4.5 + .001
        for n in range(1, count + 1):
            alpha = n / (count + 1)
            if proposal.get("contactAwareConnections"):
                alpha = (from_extent + gap + width / 2 + (n - 1) * (width + gap)) / length
            p = [a[j] * (1 - alpha) + b[j] * alpha for j in range(3)]
            rows.append(contact(f"RouteLinks.{name}_to_{after}_{n}.BankContact", p, [width if proposal.get("contactAwareConnections") else 15.4, .25, 12.8], (dx / length, dz / length)))
    expert_details = []
    for name, before, after in [("X01", "H04", "CP2"), ("X02", "H07", "CP3")]:
        a, b = ends[before]["exit"], ends[after]["entry"]
        control = [ORIGIN[i] + nodes[name][i] for i in range(3)]
        approximate = math.dist(a, control) + math.dist(control, b)
        settings = proposal.get("experts", {}).get(name, {})
        count = settings.get("count", max(5, math.ceil(approximate / 8)))
        def curve(t):
            return [a[j] * (1 - t) ** 2 + control[j] * 2 * t * (1 - t) + b[j] * t * t for j in range(3)]
        samples = [(0, 0)]
        if settings.get("arcLength"):
            previous, total = curve(0), 0
            sample_count = settings.get("arcSamples", 1000)
            for sample in range(1, sample_count + 1):
                t = sample / sample_count
                current = curve(t)
                total += math.dist(previous, current)
                samples.append((t, total))
                previous = current
            if settings.get("spacingTarget"):
                count = max(5, math.ceil(total / settings["spacingTarget"]))
        for n in range(1, count):
            alpha = n / count
            if settings.get("arcLength"):
                goal = samples[-1][1] * alpha
                sample = next(i for i in range(1, len(samples)) if samples[i][1] >= goal)
                t0, d0 = samples[sample - 1]
                t1, d1 = samples[sample]
                alpha = t0 + (t1 - t0) * (goal - d0) / (d1 - d0)
            p = curve(alpha)
            c, d = curve(max(0, alpha - .01)), curve(min(1, alpha + .01))
            dx, dz = d[0] - c[0], d[2] - c[2]
            length = math.hypot(dx, dz)
            offset = settings.get("side", 2.1) * (1 if n % 2 == 0 else -1)
            p[0] -= dz / length * offset
            p[2] += dx / length * offset
            p[1] += 1.6 if n % 2 == 0 else .2
            if settings.get("trimCommon"):
                departure = next(c for c in rows if meta(c)[0] == before and ".ExitBank." in c["path"])
                arrival = next(c for c in rows if meta(c)[0] == after and meta(c)[1] == "checkpoint")
                def common_overlap(c):
                    cf = c["cf"]
                    dx, dz = p[0] - cf[0], p[2] - cf[2]
                    x, z = dx * cf[3] + dz * cf[9], dx * cf[5] + dz * cf[11]
                    hx = 1.2 * (abs(cf[3]) + abs(cf[9]))
                    hz = 1.2 * (abs(cf[5]) + abs(cf[11]))
                    return abs(x) < c["size"][0] / 2 + hx and abs(z) < c["size"][2] / 2 + hz
                if common_overlap(departure) or common_overlap(arrival):
                    continue
            rows.append(contact(f"ExpertRoutes.{name}.PrecisionLanding{n}.KeyContact", p, [2.4, .25, 2.4]))
        expert_details.append({"id": name, "count": count, "control": control, "approximate": approximate, "curveLength": samples[-1][1] if settings.get("arcLength") else None})
    return annotate(rows), ends, expert_details


def minimum_between(rows, first, second, inset=.6):
    metrics = [jump(a, b, inset) for a in rows if first(a) for b in rows if second(b)]
    return min(metrics, key=lambda row: row["insetGap"])


def assess(proposal):
    rows, ends, experts = reconstruct(proposal)
    get = lambda group: lambda r: r["group"] == group
    metrics = {}
    for a, b in [("O07", "F01"), ("H08", "F01"), ("H01", "F01"), ("O07", "O08"), ("H08", "O08")]:
        metrics[a + "_to_" + b] = minimum_between(rows, get(a), get(b))
    middle = lambda r: r["group"] == "H01" and "PermanentCtrlRefuge" in r["short"]
    h01_entry = lambda r: r["group"] == "H01" and "EntryBank" in r["short"]
    h01_exit = lambda r: r["group"] == "H01" and "ExitBank" in r["short"]
    for a in ["H08_to_H01", "H01_to_O08"]:
        if any(get(a)(r) for r in rows):
            metrics[a + "_to_H01_middle"] = minimum_between(rows, get(a), middle)
            metrics["H01_middle_to_" + a] = minimum_between(rows, middle, get(a))
    metrics["H08_to_H01_middle"] = minimum_between(rows, get("H08"), middle)
    metrics["H01_middle_to_O08"] = minimum_between(rows, middle, get("O08"))
    metrics["H01_entry_to_exit"] = minimum_between(rows, h01_entry, h01_exit)
    return rows, ends, experts, metrics


if __name__ == "__main__":
    proposal = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
    rows, ends, experts, metrics = assess(proposal)
    print(json.dumps({"proposal": proposal, "metrics": {k: {kk: round(vv, 3) if isinstance(vv, float) else vv for kk, vv in v.items()} for k, v in metrics.items()}, "experts": experts}, indent=2))
    if len(sys.argv) > 2:
        output = {"contacts": [{k: v for k, v in r.items() if k not in {"anchors", "poly"}} for r in rows], "units": ends, "experts": experts, "proposal": proposal, "metrics": metrics}
        Path(sys.argv[2]).write_text(json.dumps(output, indent=2), encoding="utf-8")
