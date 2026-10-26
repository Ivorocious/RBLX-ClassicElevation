"""Rebind archived actual triangles to Source56 and scan current within-unit faces."""
from collections import defaultdict, Counter
from pathlib import Path
import hashlib
import json
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
OLD = ROOT / "tools/moonlit-citadel/phase3/repair-20261019/overlap"
BEFORE = ROOT / "docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json"
AFTER = ROOT / "docs/artifacts/moonlit-citadel/phase3/repair-20261019/final/native-snapshot55.json"
ORIGIN = np.array((4000, 300, 2600))
GAP = .035


def prop(record, key):
    v = record["props"].get(key, record["props"].get(key.lower()))
    return v.get("value") if isinstance(v, dict) else v


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def attrs(record):
    return record["attrs"] if isinstance(record.get("attrs"), dict) else {}


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def clip(a, b):
    output = list(a)
    if cross(b[1] - b[0], b[2] - b[0]) < 0:
        b = b[::-1]
    for k in range(3):
        start, end = b[k], b[(k + 1) % 3]
        source, output = output, []
        if not source:
            break
        prev = source[-1]
        pdist = cross(end - start, prev - start)
        for point in source:
            dist = cross(end - start, point - start)
            if (dist >= -1e-9) != (pdist >= -1e-9):
                output.append(prev + (point - prev) * (pdist / (pdist - dist)))
            if dist >= -1e-9:
                output.append(point)
            prev, pdist = point, dist
    if len(output) < 3:
        return 0, None
    polygon = np.array(output)
    area = abs(sum(cross(polygon[i + 1] - polygon[0], polygon[i + 2] - polygon[0])
                   for i in range(len(polygon) - 2))) * .5
    return area, polygon.mean(axis=0)


def prepare():
    old_records = json.loads(BEFORE.read_text(encoding="utf8"))["editable"]["records"]
    new_records = json.loads(AFTER.read_text(encoding="utf8"))["editable"]["records"]
    old_meta = json.loads((OLD / "surface-objects54-bound.json").read_text(encoding="utf8"))
    source = np.load(OLD / "surface-triangles54.npz")
    old_triangles, old_owners, old_faces = source["triangles"], source["owners"], source["faces"]
    by_mesh = {}
    for row in old_meta["objects"]:
        r = old_records[row["nativePath"]]
        if r["class"] == "MeshPart":
            by_mesh.setdefault(prop(r, "MeshId"), row)
    floor = {p: r for p, r in old_records.items() if r["class"] == "MeshPart" and
             attrs(r).get("SourceAsset") == "MC_EC_InnerRavine"}
    assert len(floor) == 3
    records = {**{p: r for p, r in new_records.items() if attrs(r).get("SourceAsset") != "MC_DP_InnerChasm"}, **floor}
    objects, triangles, owners, faces, omitted = [], [], [], [], []
    old_by_path = {r["nativePath"]: r for r in old_meta["objects"]}
    for path, record in sorted(records.items()):
        if record["class"] not in ("MeshPart", "Part") or (prop(record, "Transparency") or 0) >= 1:
            continue
        row = old_by_path.get(path)
        if row is not None and record["class"] == "MeshPart":
            if prop(old_records[row["nativePath"]], "MeshId") != prop(record, "MeshId"):
                row = None
        if row is None and record["class"] == "MeshPart":
            row = by_mesh.get(prop(record, "MeshId"))
        if row is None:
            omitted.append(path)
            continue
        old_record = old_records[row["nativePath"]]
        old_cf, new_cf = np.array(prop(old_record, "CFrame")), np.array(prop(record, "CFrame"))
        old_size, new_size = np.array(prop(old_record, "Size")), np.array(prop(record, "Size"))
        indices = np.flatnonzero(old_owners == row["index"])
        local = (old_triangles[indices] + ORIGIN - old_cf[:3]) @ old_cf[3:].reshape(3, 3)
        converted = (local / old_size * new_size) @ new_cf[3:].reshape(3, 3).T + new_cf[:3] - ORIGIN
        native_local = (converted.reshape(-1, 3) + ORIGIN - new_cf[:3]) @ new_cf[3:].reshape(3, 3)
        low, high = native_local.min(axis=0), native_local.max(axis=0)
        err = float(max(np.max(np.abs((low + high) / 2)), np.max(np.abs(high - low - new_size))))
        assert err < .003, (path, err)
        objects.append({"index": len(objects), "path": path, "unit": path.rsplit("/", 1)[0],
                        "class": record["class"], "asset": attrs(record).get("SourceAsset"),
                        "material": attrs(record).get("SourceMaterial"),
                        "color": prop(record, "Color"), "robloxMaterial": prop(record, "Material"),
                        "cframe": new_cf.tolist(), "size": new_size.tolist(), "sourceIndex": row["index"],
                        "sourceGeometryPath": row["nativePath"], "meshId": prop(record, "MeshId"),
                        "boundsError": err, "triangles": len(indices),
                        "flags": {k: prop(record, k) for k in ("CanCollide", "CanQuery", "CanTouch", "DoubleSided")}})
        triangles.append(converted)
        owners.append(np.full(len(indices), len(objects) - 1, dtype=np.int32))
        faces.append(old_faces[indices])
    triangles, owners, faces = np.concatenate(triangles), np.concatenate(owners), np.concatenate(faces)
    assert len(objects) == 1586, len(objects)
    meta = {"scope": "Source55 saved poses plus exact restored Source54 ER01 floor, matching Source56 installation receipt; mist anchors are transparent and omitted",
            "objects": objects, "triangles": len(triangles), "omitted": omitted,
            "sources": {str(p.relative_to(ROOT)): sha(p) for p in
                        (BEFORE, AFTER, OLD / "surface-objects54-bound.json", OLD / "surface-triangles54.npz")},
            "maximumBoundsError": max(o["boundsError"] for o in objects), "live56ParityPending": True}
    (HERE / "surface-objects56.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf8")
    np.savez_compressed(HERE / "surface-triangles56.npz", triangles=triangles, owners=owners, faces=faces)
    print("PREPARED " + json.dumps({k: v for k, v in meta.items() if k not in ("objects", "sources")}), flush=True)
    return objects, triangles, owners, faces


def scan(objects, triangles, owners, faces):
    normals = np.cross(triangles[:, 1] - triangles[:, 0], triangles[:, 2] - triangles[:, 0])
    lengths = np.linalg.norm(normals, axis=1)
    good = lengths > 1e-7
    normals[good] /= lengths[good, None]
    distances = np.einsum("ij,ij->i", normals, triangles[:, 0])
    groups = defaultdict(list)
    for i in np.flatnonzero(good):
        owner = int(owners[i])
        normal = tuple(np.rint(normals[i] * 1000).astype(int))
        distance = int(round(distances[i] / .08))
        groups[(objects[owner]["unit"], owner, normal, distance)].append(int(i))
    surfaces, buckets = [], defaultdict(list)
    for (unit, owner, normal, distance), indices in groups.items():
        idx = np.array(indices, dtype=np.int32)
        n = normals[idx].mean(axis=0)
        n /= np.linalg.norm(n)
        axes = [a for a in range(3) if a != int(np.argmax(np.abs(n)))]
        points = triangles[idx][:, :, axes]
        surfaces.append({"unit": unit, "owner": owner, "n": n, "distance": float(distances[idx].mean()),
                         "indices": idx, "axes": axes, "points": points,
                         "low": points.min(axis=(0, 1)), "high": points.max(axis=(0, 1))})
        buckets[(unit, normal, distance)].append(len(surfaces) - 1)
    candidates = set()
    for (unit, normal, distance), group in buckets.items():
        other = group + buckets.get((unit, normal, distance + 1), [])
        for i in group:
            for j in other:
                a, b = surfaces[i], surfaces[j]
                if np.dot(a["n"], b["n"]) < 1 - 1e-6 or abs(a["distance"] - b["distance"]) > GAP + .001 or a["axes"] != b["axes"]:
                    continue
                if np.any(np.minimum(a["high"], b["high"]) - np.maximum(a["low"], b["low"]) <= 1e-6):
                    continue
                candidates.add(tuple(sorted((i, j))))
    hits, tested = {}, 0
    for si, sj in sorted(candidates):
        a, b = surfaces[si], surfaces[sj]
        ap, bp = a["points"], b["points"]
        blo, bhi = bp.min(axis=1), bp.max(axis=1)
        for ai, at in enumerate(ap):
            alo, ahi = at.min(axis=0), at.max(axis=0)
            choices = np.flatnonzero(np.all(np.minimum(ahi, bhi) - np.maximum(alo, blo) > 1e-6, axis=1))
            for bi in choices:
                i, j = int(a["indices"][ai]), int(b["indices"][bi])
                if i >= j and si == sj:
                    continue
                if owners[i] == owners[j] and faces[i] == faces[j]:
                    continue
                tested += 1
                gap = float(np.abs((triangles[j] - triangles[i, 0]) @ normals[i]).max())
                if gap > GAP:
                    continue
                area, centre = clip(at, bp[bi])
                drop = 3 - sum(a["axes"])
                area /= abs(a["n"][drop])
                if area < .01:
                    continue
                key = tuple(sorted((int(owners[i]), int(owners[j]))))
                item = hits.setdefault(key, {"a": key[0], "b": key[1], "paths": [objects[k]["path"] for k in key],
                                             "area": 0., "minimumGap": float("inf"), "maximumGap": 0.,
                                             "trianglePairs": 0, "witnesses": []})
                item["area"] += float(area)
                item["minimumGap"] = min(item["minimumGap"], gap)
                item["maximumGap"] = max(item["maximumGap"], gap)
                item["trianglePairs"] += 1
                point = np.zeros(3)
                point[a["axes"]] = centre
                point[drop] = (np.dot(normals[i], triangles[i, 0]) - sum(normals[i, axis] * point[axis] for axis in a["axes"])) / normals[i, drop]
                item["witnesses"].append({"area": float(area), "gap": gap, "point": point.tolist(),
                                          "normal": normals[i].tolist(), "faces": [int(faces[i]), int(faces[j])],
                                          "triangleIndices": [i, j]})
    for row in hits.values():
        row["witnessCount"] = len(row["witnesses"])
        row["normalHistogram"] = dict(Counter(str(tuple(np.rint(np.array(w["normal"])*1000).astype(int))) for w in row["witnesses"]))
        row["witnesses"] = sorted(row["witnesses"], key=lambda x: x["area"], reverse=True)[:12]
        a, b = objects[row["a"]], objects[row["b"]]
        contrast = float(np.linalg.norm(np.array(a["color"]) - np.array(b["color"])))
        row["samePart"] = row["a"] == row["b"]
        row["differentAppearance"] = contrast > .02 or a["robloxMaterial"] != b["robloxMaterial"]
    result = {"scope": "Fresh same-facing actual triangle intersection scan within current asset instances, not old witness closure",
              "maximumGap": GAP, "objects": len(objects), "triangles": len(triangles), "tested": tested,
              "pairs": sorted(hits.values(), key=lambda r: r["area"], reverse=True),
              "live56ParityPending": True, "visibilityPending": True}
    (HERE / "internal-candidates56.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf8")
    print("SCANNED " + json.dumps({"pairs": len(hits), "selfPairs": sum(r["samePart"] for r in hits.values()),
                                    "differentAppearance": sum(r["differentAppearance"] for r in hits.values()), "tested": tested}), flush=True)


if __name__ == "__main__":
    scan(*prepare())
