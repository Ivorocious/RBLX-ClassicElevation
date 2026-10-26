"""Measure actual exported support polygons; this does not simulate avatars."""

import argparse
import itertools
import json
import math
from pathlib import Path


def cross(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def hull(points):
    points = sorted(set(tuple(p) for p in points))
    if len(points) < 3:
        return points
    lower, upper = [], []
    for chain, sequence in ((lower, points), (upper, reversed(points))):
        for p in sequence:
            while len(chain) >= 2 and cross(chain[-2], chain[-1], p) <= 1e-7:
                chain.pop()
            chain.append(p)
    return lower[:-1]+upper[:-1]


def clip(subject, a, b, offset=0):
    output = []
    if not subject:
        return output
    length = math.dist(a, b)
    for p, q in zip(subject, subject[1:]+subject[:1]):
        dp, dq = cross(a, b, p)-offset*length, cross(a, b, q)-offset*length
        inside_p, inside_q = dp >= -1e-8, dq >= -1e-8
        if inside_p:
            output.append(p)
        if inside_p != inside_q:
            t = dp/(dp-dq)
            output.append((p[0]+t*(q[0]-p[0]), p[1]+t*(q[1]-p[1])))
    return output


def intersection(a, b):
    result = a
    for p, q in zip(b, b[1:]+b[:1]):
        result = clip(result, p, q)
    return result


def area(poly):
    return abs(sum(a[0]*b[1]-a[1]*b[0] for a, b in zip(poly, poly[1:]+poly[:1])))/2


def inset(poly, distance):
    result = poly
    for a, b in zip(poly, poly[1:]+poly[:1]):
        result = clip(result, a, b, distance)
    return result


def closest(point, a, b):
    v = (b[0]-a[0], b[1]-a[1])
    length_squared = v[0]**2+v[1]**2
    t = max(0, min(1, ((point[0]-a[0])*v[0]+(point[1]-a[1])*v[1])/length_squared))
    return (a[0]+t*v[0], a[1]+t*v[1])


def separation(a, b):
    if not a or not b:
        return {"distance": None, "a": None, "b": None}
    overlap = intersection(a, b)
    if overlap:
        return {"distance": 0, "a": overlap[0], "b": overlap[0]}
    best = {"distance": float("inf")}
    for reverse, p, q in ((False, a, b), (True, b, a)):
        for point in p:
            for u, v in zip(q, q[1:]+q[:1]):
                target = closest(point, u, v)
                distance = math.dist(point, target)
                if distance < best["distance"]:
                    best = {"distance": distance, "a": target if reverse else point, "b": point if reverse else target}
    return best


def support(group):
    points = [p for part in group["parts"] for p in part["points"]]
    return hull([(p[0], p[2]) for p in points]), max(p[1] for p in points)


def top(part):
    maximum = max(p[1] for p in part["points"])
    points = [(p[0], p[2]) for p in part["points"] if abs(p[1]-maximum) < .001]
    return hull(points), maximum


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    data = json.loads(args.input.read_text(encoding="utf-8"))
    groups = {g["name"]: g for g in data["groups"]}
    tool_overlaps = []
    for group in data["groups"]:
        if not group.get("family", "").startswith("GardenTool_"):
            continue
        for a, b in itertools.combinations(group["parts"], 2):
            pa, ya = top(a)
            pb, yb = top(b)
            if len(pa) < 3 or len(pb) < 3 or abs(ya-yb) > .001:
                continue
            overlap = area(intersection(pa, pb))
            if overlap > .01:
                tool_overlaps.append({"group": group["name"], "a": a["name"], "b": b["name"], "area": overlap})
    crops = "Obstacles.G2_CropGarden.PlayableObjects."
    grove = "Obstacles.G3_CandyGrove."
    vine = "Obstacles.G4_LowerVine."
    routes = {
        "crop_main": ["H1_Sprinkler.DryExitAndChoice"]+[crops+n for n in ("BambooWest", "BambooTurn", "BambooSouth", "BambooReturn", "MergeRefuge")],
        "crop_expert": ["H1_Sprinkler.DryExitAndChoice",crops+"BambooWest"]+[crops+f"ExpertStakes.Stake_{i}" for i in range(1, 6)]+[crops+"MergeRefuge"],
        "grove_entry": ["Obstacles.G2_ToolGardenExit.GroveRefuge"]+[grove+n for n in ("EntryRoot", "ForkRoot", "HarvestRoot")]+["H2_Fruit.EntryRefuge"],
        "grove_roots": ["H2_Fruit.ExitRefuge"]+[grove+f"GroveRoot_{i}" for i in range(1, 9)]+[grove+"VineRefuge"],
        "vine_entry": [grove+"VineRefuge"]+[vine+f"OpeningLeaf_{i}" for i in range(1, 5)]+[vine+"VineChoice"],
        "vine_main": [vine+"VineChoice"]+[vine+f"BroadTurnLeaf_{i}" for i in range(1, 7)]+[vine+"VineMerge"],
        "vine_expert": [vine+"VineChoice"]+[vine+f"ExpertTendril_{i}" for i in range(1, 6)]+[vine+"VineMerge"],
        "vine_exit": [vine+"VineMerge", vine+"ExitLeaf_1", vine+"ExitLeaf_2", vine+"FestivalRefuge"],
    }
    measured = {}
    for route, names in routes.items():
        pairs = []
        for an, bn in zip(names, names[1:]):
            a, ya = support(groups[an])
            b, yb = support(groups[bn])
            visible = separation(a, b)
            feet = separation(inset(a, .65), inset(b, .65))
            rise = yb-ya
            jump_velocity = math.sqrt(2*196.2*7.2)
            maximum = 16*(jump_velocity+math.sqrt(max(0, jump_velocity**2-2*196.2*rise)))/196.2
            pairs.append({"a": an, "b": bn, "edgeGap": visible["distance"], "footCenterGap": feet["distance"], "footInset": .65, "rise": rise,
                          "idealBallisticRange": maximum, "rangeMargin": maximum-feet["distance"] if feet["distance"] is not None else None,
                          "from": [feet["a"][0], ya, feet["a"][1]] if feet["a"] else None,
                          "to": [feet["b"][0], yb, feet["b"][1]] if feet["b"] else None})
        measured[route] = pairs
    root_overlaps = []
    roots = [g for g in data["groups"] if g["name"].startswith(grove+"GroveRoot_")]
    for a, b in itertools.combinations(roots, 2):
        pa, _ = support(a)
        pb, _ = support(b)
        overlap = area(intersection(pa, pb))
        if overlap > .01:
            root_overlaps.append({"a": a["name"], "b": b["name"], "area": overlap})
    result = {"candidate": data["candidate"], "method": "Convex footprint from actual exported collider vertices; flat tool top-face clipping; no centerline-only gap inference.",
              "limits": "Includes lower bevel edges in the support outline. Foot inset is a geometric screen, not an avatar body. Ideal ballistic range ignores run-up, steering, obstruction and controller behavior. No gameplay, crowd or timing proof.",
              "toolCoplanarOverlaps": tool_overlaps, "groveRootFootprintOverlaps": root_overlaps, "routes": measured}
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"candidate": data["candidate"], "toolOverlaps": len(tool_overlaps), "rootOverlaps": len(root_overlaps),
                      "routes": {name: [{"a": p["a"].split(".")[-1], "b": p["b"].split(".")[-1], "gap": round(p["edgeGap"], 2), "feet": round(p["footCenterGap"], 2) if p["footCenterGap"] is not None else None, "rise": round(p["rise"], 2), "margin": round(p["rangeMargin"], 2) if p["rangeMargin"] is not None else None} for p in pairs] for name, pairs in measured.items()}}, indent=2))


if __name__ == "__main__":
    main()
