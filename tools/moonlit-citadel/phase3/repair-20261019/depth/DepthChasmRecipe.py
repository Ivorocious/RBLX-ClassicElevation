"""Reuse Source54 terrain tops and replace unsupported bed with an open chasm."""
import collections
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
OLD = ROOT / "tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/landscape"
MANIFEST = ROOT / "assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/manifest.json"
ASSET = "MC_DP_InnerChasm"
PALETTE = {"RockTop": (100, 112, 116), "RockUpper": (100, 112, 116),
           "RockMiddle": (57, 73, 93), "RockDeep": (27, 40, 61), "RockUnderside": (18, 27, 43)}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def original():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    for name in ("EnclosureRecipes.py", "FortressSeats.json"):
        path = OLD / name
        key = path.relative_to(ROOT).as_posix()
        assert sha(path) == manifest["source_hashes"][key], "Frozen ER01 recipe changed: " + name
    sys.path.insert(0, str(OLD))
    spec = importlib.util.spec_from_file_location("depth_frozen_er01", OLD / "EnclosureRecipes.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    mesh, metadata = module.terrain("MC_EC_InnerRavine")
    assert mesh.triangles() == 30716 and len(metadata["topTriangles"]) == 29264
    return mesh, metadata


def support_boxes(inputs):
    result = []
    for seat in inputs["groundContactBoxes"]:
        for box in seat["boxes"]:
            f, size = box["frame"], box["size"]
            points = [(f[0] + f[3] * x + f[5] * z, f[2] + f[9] * x + f[11] * z)
                      for x in (-size[0] / 2, size[0] / 2) for z in (-size[2] / 2, size[2] / 2)]
            result.append({"unit": seat["name"], "asset": seat["asset"], "bottomY": seat["bottomY"],
                           "low": [min(p[0] for p in points) - .35, min(p[1] for p in points) - .35],
                           "high": [max(p[0] for p in points) + .35, max(p[1] for p in points) + .35]})
    return result


def build():
    inputs_path = HERE / "source54-depth-inputs.json"
    inputs = json.loads(inputs_path.read_text(encoding="utf-8"))
    mesh, metadata = original()
    supports = support_boxes(inputs)
    vertices, faces, materials = [], [], []
    original_tops = mesh.faces[:len(metadata["topTriangles"])]
    retained, removed, reasons = [], [], collections.Counter()
    support_coverage = {seat["name"]: set() for seat in inputs["groundContactBoxes"]}
    area = collections.Counter()
    for index, face in enumerate(original_tops):
        points = [mesh.vertices[v] for v in face]
        low_x, high_x = min(p[0] for p in points), max(p[0] for p in points)
        low_z, high_z = min(p[2] for p in points), max(p[2] for p in points)
        rooted = [b["unit"] for b in supports if low_x <= b["high"][0] and high_x >= b["low"][0]
                  and low_z <= b["high"][1] and high_z >= b["low"][1]]
        reason = "upperBank" if max(p[1] for p in points) >= -23 else "support" if rooted else "openVoid"
        a, b, c = points
        projected = abs((b[0] - a[0]) * (c[2] - a[2]) - (c[0] - a[0]) * (b[2] - a[2])) / 2
        reasons[reason] += 1
        area[reason] += projected
        if reason == "openVoid":
            removed.append(index)
        else:
            retained.append(index)
            for name in rooted:
                support_coverage[name].add(index)
    assert len(retained) == 12759 and len(removed) == 16505
    assert all(support_coverage.values()), "Every actual grounded architecture seat keeps its terrain"
    used = sorted({vertex for index in retained for vertex in original_tops[index]})
    mapping = {old: i for i, old in enumerate(used)}
    vertices.extend(mesh.vertices[i] for i in used)
    for index in retained:
        faces.append(tuple(mapping[v] for v in original_tops[index]))
        materials.append("RockTop")
    directed = collections.Counter((face[i], face[(i + 1) % 3]) for face in faces for i in range(3))
    boundary = [(a, b) for a, b in directed if not directed[(b, a)]]
    degree = collections.Counter(v for edge in boundary for v in edge)
    assert all(value == 2 for value in degree.values()), "Boundary requires a bounded topology repair"
    boundary_vertices = sorted(degree)
    previous = {v: v for v in boundary_vertices}
    for layer, base_y, variation, material in ((1, -700, 0, "RockUpper"),):
        current = {}
        for v in boundary_vertices:
            x, _, z = vertices[v]
            y = base_y + variation * math.sin(x * .017 + z * .019) * math.cos(z * .013 - x * .011)
            current[v] = len(vertices)
            vertices.append((x, y, z))
        for a, b in boundary:
            # Adjacent faces traverse their common edge in opposite directions.
            faces.extend(((previous[b], previous[a], current[a]), (previous[b], current[a], current[b])))
            materials.extend((material, material))
        previous = current
    bottom = {}
    for v in range(len(used)):
        if v in previous:
            bottom[v] = previous[v]
        else:
            x, _, z = vertices[v]
            y = -700
            bottom[v] = len(vertices)
            vertices.append((x, y, z))
    for index in retained:
        faces.append(tuple(bottom[mapping[v]] for v in reversed(original_tops[index])))
        materials.append("RockUnderside")
    edges = collections.Counter(tuple(sorted((f[i], f[(i + 1) % 3]))) for f in faces for i in range(3))
    winding = collections.Counter((f[i], f[(i + 1) % 3]) for f in faces for i in range(3))
    assert all(count == 2 for count in edges.values()), "New chasm must have a closed assembled exterior"
    assert all(winding[(b, a)] == count for (a, b), count in winding.items()), "Inconsistent winding"
    zero = 0
    volume = 0
    for face in faces:
        a, b, c = [vertices[i] for i in face]
        u, v = [b[i] - a[i] for i in range(3)], [c[i] - a[i] for i in range(3)]
        cross = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        zero += sum(x * x for x in cross) < 1e-14
        volume += (a[0] * (b[1] * c[2] - b[2] * c[1]) + a[1] * (b[2] * c[0] - b[0] * c[2]) + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
    assert zero == 0 and volume > 0
    cost = dict(collections.Counter(materials))
    assert max(cost.values()) < 15000
    low = [min(p[i] for p in vertices) for i in range(3)]
    high = [max(p[i] for p in vertices) for i in range(3)]
    proof = {"asset": ASSET, "inputPath": inputs_path.relative_to(ROOT).as_posix(), "inputSha256": sha(inputs_path),
             "originalManifestSha256": sha(MANIFEST), "originalTriangles": 30716, "newTriangles": len(faces),
             "parts": len(cost), "materialTriangles": cost, "bounds": {"low": low, "high": high},
             "retainedOriginalTopTrianglesExact": len(retained), "retainedUpperBankTrianglesExact": reasons["upperBank"],
             "removedUnsupportedLowBedTriangles": len(removed), "areaSquareStuds": dict(area),
             "actualGroundedUnits": len(support_coverage), "occupiedGroundContactBoxes": len(supports),
             "boundaryEdges": len(boundary), "assembledClosed": True, "consistentWinding": True,
             "zeroAreaTriangles": zero, "positiveVolume": volume,
             "allNewSideGeometryBelowResetExceptExistingUpperBankBorders": True,
             "voidHasHorizontalSurface": False, "physicsChanged": False, "nativeVerified": False,
             "supportRetainedTriangles": {name: len(rows) for name, rows in support_coverage.items()},
             "combinedBudget": {"units": 320, "meshes": 881 - 3 + len(cost), "triangles": 282944 - 30716 + len(faces)}}
    return {"vertices": vertices, "faces": faces, "materials": materials, "proof": proof,
            "retainedOriginalTopIndices": retained, "removedOriginalTopIndices": removed, "supportBoxes": supports}


if __name__ == "__main__":
    result = build()
    (HERE / "chasm-recipe-proof.json").write_text(json.dumps(result["proof"], indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result["proof"], indent=2))
