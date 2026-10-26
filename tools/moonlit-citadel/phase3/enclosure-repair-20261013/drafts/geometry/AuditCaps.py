"""Audit horizontal cap triangles, including exact cuboid components, without native tools.

Inputs use Roblox local vertices and asset-origin CFrames. Positive scaleRoblox is
applied before rotation. This is a geometry screen, not a rendering verdict.
"""
import argparse
import collections
import hashlib
import itertools
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
REVIEW = ROOT / "docs/artifacts/moonlit-citadel/phase3/enclosure-review-20261013/data"
IDENTITY = [1, 0, 0, 0, 1, 0, 0, 0, 1]


def sub(a, b):
    return [x-y for x, y in zip(a, b)]


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def cross(a, b):
    return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]


def rotate(cf, p):
    return [dot(cf[3+i*3:6+i*3], p) for i in range(3)]


def transform(row, p):
    cf, scale = row["cf"], row.get("scaleRoblox", [1, 1, 1])
    rotated = rotate(cf, [p[i]*scale[i] for i in range(3)])
    return [cf[i]+rotated[i] for i in range(3)]


def local(row, p):
    cf, scale = row["cf"], row.get("scaleRoblox", [1, 1, 1])
    delta = sub(p, cf[:3])
    return [sum(cf[3+j*3+i]*delta[j] for j in range(3))/scale[i] for i in range(3)]


def components(part):
    adjacency = collections.defaultdict(set)
    for face in part["faces"]:
        for i, j in zip(face, face[1:]+face[:1]):
            adjacency[i].add(j)
            adjacency[j].add(i)
    remaining, groups = set(adjacency), []
    while remaining:
        group, pending = set(), [next(iter(remaining))]
        while pending:
            i = pending.pop()
            if i not in group:
                group.add(i)
                pending.extend(adjacency[i]-group)
        remaining -= group
        groups.append(group)
    return groups


def cuboids(part):
    result = []
    for group in components(part):
        if len(group) != 8:
            continue
        points = [part["vertices"][i] for i in group]
        low = [min(p[i] for p in points) for i in range(3)]
        high = [max(p[i] for p in points) for i in range(3)]
        expected = {tuple(round(v, 7) for v in p) for p in itertools.product(*zip(low, high))}
        actual = {tuple(round(v, 7) for v in p) for p in points}
        if expected == actual:
            result.append((low, high))
    return result


def orient(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def clip(subject, cutter):
    sign = 1 if orient(*cutter[:3]) > 0 else -1
    polygon = subject
    for a, b in zip(cutter, cutter[1:]+cutter[:1]):
        output = []
        if not polygon:
            break
        previous = polygon[-1]
        dp = sign*orient(a, b, previous)
        for current in polygon:
            dc = sign*orient(a, b, current)
            if (dc >= -1e-9) != (dp >= -1e-9):
                t = dp/(dp-dc)
                output.append([previous[i]+t*(current[i]-previous[i]) for i in range(2)])
            if dc >= -1e-9:
                output.append(current)
            previous, dp = current, dc
        polygon = output
    return polygon


def area(polygon):
    return abs(sum(p[0]*q[1]-q[0]*p[1] for p, q in zip(polygon, polygon[1:]+polygon[:1])))/2


def triangulate_cap(points):
    polygon = [[p[0],p[2]] for p in points]
    remaining = list(range(len(points)))
    while len(remaining) > 3:
        collinear = next((j for j in range(len(remaining))
                          if abs(orient(polygon[remaining[j-1]], polygon[remaining[j]],
                                        polygon[remaining[(j+1)%len(remaining)]])) < 1e-9), None)
        if collinear is None:
            break
        remaining.pop(collinear)
    signed = sum(polygon[a][0]*polygon[b][1]-polygon[b][0]*polygon[a][1]
                 for a,b in zip(remaining, remaining[1:]+remaining[:1]))
    direction = 1 if signed > 0 else -1
    result = []
    while len(remaining) > 3:
        for j, b in enumerate(remaining):
            a,c = remaining[j-1],remaining[(j+1)%len(remaining)]
            if direction*orient(polygon[a],polygon[b],polygon[c]) <= 1e-9:
                continue
            if any(all(direction*orient(polygon[u],polygon[v],polygon[q]) >= -1e-9
                       for u,v in [(a,b),(b,c),(c,a)]) for q in remaining if q not in (a,b,c)):
                continue
            result.append([points[a],points[b],points[c]])
            remaining.pop(j)
            break
        else:
            raise ValueError("Non-simple cap polygon; use actual exported triangles.")
    if len(remaining) == 3:
        result.append([points[i] for i in remaining])
    return result


def extract_native(directory):
    rows = [part for path in sorted(directory.glob("parts-*.json"))
            for part in json.loads(path.read_text(encoding="utf-8"))]
    placements = []
    for part in rows:
        name = part["path"].split(".")[-1]
        asset = name.removesuffix("__Stone")
        if name not in ("MC_AR_MasonryMass__Stone", "MC_AR_FoundationBay46__Stone"):
            continue
        assert part["path"].startswith("Decoration.Phase3World.")
        original_size, center = (([24, 24, 12], [0, 12, 0]) if "Masonry" in asset
                                 else ([46, 40, 22], [0, 20, -11]))
        scale = [part["size"][i]/original_size[i] for i in range(3)]
        offset = rotate(part["cf"], [center[i]*scale[i] for i in range(3)])
        cf = [part["cf"][i]-offset[i] for i in range(3)]+part["cf"][3:]
        placements.append({"id": part["path"].rsplit(".", 1)[0], "asset": asset,
                           "cf": cf, "scaleRoblox": scale, "baseline": "Source48 native AR01"})
    assert len({p["id"] for p in placements}) == len(placements)
    return placements


def audit(authored, placements, tolerance):
    assets = {a["asset"]: a for a in authored["assets"]}
    cubes, triangles, omitted = [], [], []
    for row in placements:
        if row["asset"] not in assets:
            omitted.append(row["id"])
            continue
        assert len(row["cf"]) == 12 and all(v > 0 for v in row.get("scaleRoblox", [1, 1, 1]))
        rotation = row["cf"][3:]
        assert all(abs(dot(rotation[i*3:i*3+3], rotation[j*3:j*3+3])-(i == j)) < 1e-4
                   for i in range(3) for j in range(3)), row["id"]
        asset_record = assets[row["asset"]]
        for box in asset_record.get("solid_boxes", []):
            assert asset_record.get("solid_boxes_source") == "exact_canonical_union"
            corners = [transform(row, p) for p in itertools.product(*zip(box["low"], box["high"]))]
            cubes.append({"row": row, "low": box["low"], "high": box["high"],
                          "world_low": [min(p[i] for p in corners) for i in range(3)],
                          "world_high": [max(p[i] for p in corners) for i in range(3)]})
        for part in assets[row["asset"]]["parts"]:
            for low, high in cuboids(part):
                corners = [transform(row, p) for p in itertools.product(*zip(low, high))]
                cubes.append({"row": row, "low": low, "high": high,
                              "world_low": [min(p[i] for p in corners) for i in range(3)],
                              "world_high": [max(p[i] for p in corners) for i in range(3)]})
            points = [transform(row, p) for p in part["vertices"]]
            for face_index, face in enumerate(part["faces"]):
                face_points = [points[i] for i in face]
                face_normal = next((cross(sub(face_points[j], face_points[0]), sub(face_points[j+1],face_points[0]))
                                    for j in range(1,len(face_points)-1)
                                    if dot(cross(sub(face_points[j],face_points[0]), sub(face_points[j+1],face_points[0])),
                                           cross(sub(face_points[j],face_points[0]), sub(face_points[j+1],face_points[0]))) > 1e-16), None)
                if face_normal is None:
                    raise ValueError("Degenerate face: "+row["id"])
                if abs(face_normal[1])/math.sqrt(dot(face_normal,face_normal)) < 1-1e-6:
                    continue
                for p in triangulate_cap(face_points):
                    normal = cross(sub(p[1], p[0]), sub(p[2], p[0]))
                    length = math.sqrt(dot(normal, normal))
                    if length < 1e-9:
                        raise ValueError("Degenerate triangle: "+row["id"])
                    normal = [v/length for v in normal]
                    if abs(normal[1]) < 1-1e-6:
                        continue
                    triangles.append({"id": row["id"], "asset": row["asset"], "material": part["material"],
                                      "face": face_index, "p": p, "n": normal, "plane": sum(v[1] for v in p)/3,
                                      "polygon": [[v[0], v[2]] for v in p]})

    def hidden(triangle, polygon=None):
        sample = polygon or triangle["polygon"]
        samples = [[p[0], triangle["plane"]+triangle["n"][1]*.0001, p[1]] for p in sample]
        # A whole convex overlap polygon inside one exact cuboid proves burial.
        for cube in cubes:
            if any(not (cube["world_low"][i]-1e-6 <= samples[0][i] <= cube["world_high"][i]+1e-6) for i in range(3)):
                continue
            mapped = [local(cube["row"], p) for p in samples]
            if all(all(cube["low"][i]+1e-7 < p[i] < cube["high"][i]-1e-7 for i in range(3)) for p in mapped):
                return True
        return False

    buckets = collections.defaultdict(list)
    for index, t in enumerate(triangles):
        t["index"] = index
        t["hidden"] = hidden(t)
        t["min"] = [min(p[i] for p in t["polygon"]) for i in range(2)]
        t["max"] = [max(p[i] for p in t["polygon"]) for i in range(2)]
        buckets[round(t["plane"]/tolerance)].append(t)
    conflicts = []
    for key in sorted(buckets):
        for a in buckets[key]:
            for neighbor in (key, key+1):
                for b in buckets.get(neighbor, []):
                    if neighbor == key and a["index"] >= b["index"]:
                        continue
                    if a["id"] == b["id"] and a["material"] == b["material"] and a["face"] == b["face"]:
                        continue
                    if abs(a["plane"]-b["plane"]) > tolerance:
                        continue
                    if any(min(a["max"][i], b["max"][i])-max(a["min"][i], b["min"][i]) <= 1e-7 for i in range(2)):
                        continue
                    polygon = clip(a["polygon"], b["polygon"])
                    overlap = area(polygon)
                    if overlap <= 1e-7:
                        continue
                    ah, bh = hidden(a, polygon), hidden(b, polygon)
                    opposed = dot(a["n"], b["n"]) < 0
                    kind = ("opposing_normal_interior_contact" if opposed else "buried_join" if ah and bh
                            else "external_coplanar_candidate")
                    conflicts.append({"a": a["id"]+"/"+a["material"]+"/face"+str(a["face"]),
                                      "b": b["id"]+"/"+b["material"]+"/face"+str(b["face"]),
                                      "classification": kind, "hidden": [ah, bh], "plane_delta": abs(a["plane"]-b["plane"]),
                                      "plane_y": a["plane"], "overlap_area": overlap,
                                      "overlap_polygon_xz": polygon, "render_reproduced": False})
    return {"affected_placements": len(placements)-len(omitted), "omitted_nonfamily_placements": omitted,
            "cap_triangles": len(triangles), "fully_buried_cap_triangles": sum(t["hidden"] for t in triangles),
            "exact_cuboid_components": len(cubes), "classifications": dict(collections.Counter(c["classification"] for c in conflicts)),
            "conflicts": conflicts,
            "limits": "Horizontal cap triangles only. Noncuboid occluders are not assumed to hide a surface. Opposing normals are internal contacts, not same-facing depth competition. Render reproduction requires native moving-camera evidence."}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--authored", type=Path, default=HERE / "authored-vertices.json")
    parser.add_argument("--placements", type=Path)
    parser.add_argument("--native-dir", type=Path, default=REVIEW)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output", type=Path, default=HERE / "cap-audit.json")
    parser.add_argument("--tolerance", type=float, default=.001)
    args = parser.parse_args()
    assert args.output.resolve().is_relative_to(HERE), "Write only within owned geometry drafts."
    authored = json.loads(args.authored.read_text(encoding="utf-8"))
    assert authored["axes"] == "Roblox"
    placements = (json.loads(args.placements.read_text(encoding="utf-8"))["placements"] if args.placements
                  else extract_native(args.native_dir))
    result = audit(authored, placements, args.tolerance)
    grouped = collections.defaultdict(lambda: {"triangle_pairs": 0, "summed_overlap_area": 0, "planes_y": set()})
    for conflict in result["conflicts"]:
        pair = tuple(sorted((conflict["a"].rsplit("/face", 1)[0], conflict["b"].rsplit("/face", 1)[0])))
        key = (conflict["classification"],)+pair
        grouped[key]["triangle_pairs"] += 1
        grouped[key]["summed_overlap_area"] += conflict["overlap_area"]
        grouped[key]["planes_y"].add(round(conflict["plane_y"], 4))
    result["grouped_pairs"] = [{"classification": key[0], "a": key[1], "b": key[2],
                                **{k: sorted(v) if isinstance(v, set) else v for k, v in value.items()}}
                               for key, value in sorted(grouped.items())]
    result["same_instance_external_cap_pairs"] = sum(c["a"].rsplit("/", 2)[0] == c["b"].rsplit("/", 2)[0]
                                                    for c in result["conflicts"] if c["classification"] == "external_coplanar_candidate")
    result["inputs"] = {"authored": str(args.authored), "placements": str(args.placements or args.native_dir),
                        "authored_sha256": hashlib.sha256(args.authored.read_bytes()).hexdigest(),
                        "tolerance_studs": args.tolerance}
    if args.manifest:
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
        expected = {p["name"]: sum(len(f)-2 for f in p["faces"]) for a in authored["assets"] for p in a["parts"]}
        actual = {p["name"]: p["triangles"] for p in manifest["export_parts"]}
        assert expected == actual, (expected, actual)
        result["manifest_triangle_parity"] = True
    if not args.placements:
        (HERE / "source48-placements.json").write_text(json.dumps({"placements": placements}, indent=2)+"\n", encoding="utf-8")
        source_paths = sorted(args.native_dir.glob("parts-*.json"))
        result["inputs"]["native_chunk_sha256"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
    else:
        result["inputs"]["placements_sha256"] = hashlib.sha256(args.placements.read_bytes()).hexdigest()
    args.output.write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({k: result[k] for k in ("affected_placements", "cap_triangles", "fully_buried_cap_triangles", "classifications")}))


if __name__ == "__main__":
    main()
