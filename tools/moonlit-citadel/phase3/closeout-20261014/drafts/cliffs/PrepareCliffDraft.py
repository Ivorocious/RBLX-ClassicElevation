"""Stage a small landscape finishing overlay using existing imported assets."""
import ast
import bisect
import hashlib
import json
import math
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[6]
OWN = Path(__file__).resolve().parent
TERRAIN_FILE = ROOT / "tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/landscape/terrain-metadata.json"
terrain = json.loads(TERRAIN_FILE.read_text())
units, support = [], []
authored_er_file = ROOT / "assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/authored-vertices.json"
authored_er = json.loads(authored_er_file.read_text())["parts"]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def height(x, z, details=False):
    sector = next(v for v in terrain.values() if "xs" in v and v["xs"][0] <= x <= v["xs"][-1] and v["zs"][0] <= z <= v["zs"][-1])
    xs, zs, heights = sector["xs"], sector["zs"], sector["heights"]
    c = min(len(xs) - 2, max(0, bisect.bisect_right(xs, x) - 1))
    r = min(len(zs) - 2, max(0, bisect.bisect_right(zs, z) - 1))
    a, b = (xs[c], heights[r][c], zs[r]), (xs[c + 1], heights[r][c + 1], zs[r])
    cc, d = (xs[c], heights[r + 1][c], zs[r + 1]), (xs[c + 1], heights[r + 1][c + 1], zs[r + 1])
    triangles = [(a, cc, d), (a, d, b)] if (r + c) % 2 == 0 else [(a, cc, b), (b, cc, d)]
    for a, b, cc in triangles:
        den = (b[2] - cc[2]) * (a[0] - cc[0]) + (cc[0] - b[0]) * (a[2] - cc[2])
        u = ((b[2] - cc[2]) * (x - cc[0]) + (cc[0] - b[0]) * (z - cc[2])) / den
        v = ((cc[2] - a[2]) * (x - cc[0]) + (a[0] - cc[0]) * (z - cc[2])) / den
        if min(u, v, 1 - u - v) >= -1e-7:
            result = u * a[1] + v * b[1] + (1 - u - v) * cc[1]
            if not details:
                return result
            points = [a, b, cc]
            slope = max(abs(points[i][1] - points[j][1]) / max(1, math.hypot(points[i][0] - points[j][0], points[i][2] - points[j][2])) for i in range(3) for j in range(i))
            material = "Grass" if slope < 1.28 and max(p[1] for p in points) > 8 else "Earth" if slope < 1.75 and max(p[1] for p in points) > 0 else "Rock"
            return {"surfaceY": result, "sourceMaterial": material, "sourceTriangle": points, "sourceTriangleSlope": slope}
    raise ValueError((x, z))


def line_min(fixed_axis, fixed, low, high):
    points = {low, high}
    for sector in terrain.values():
        if "xs" not in sector:
            continue
        if fixed_axis == 0 and sector["xs"][0] <= fixed <= sector["xs"][-1]:
            xs, zs = sector["xs"], sector["zs"]
            c = min(len(xs) - 2, max(0, bisect.bisect_right(xs, fixed) - 1))
            t = (fixed - xs[c]) / (xs[c + 1] - xs[c])
            for r in range(len(zs) - 1):
                points.update(p for p in [zs[r], zs[r + 1], zs[r] + (zs[r + 1] - zs[r]) * (t if (r + c) % 2 == 0 else 1 - t)] if low <= p <= high)
        elif fixed_axis == 2 and sector["zs"][0] <= fixed <= sector["zs"][-1]:
            xs, zs = sector["xs"], sector["zs"]
            r = min(len(zs) - 2, max(0, bisect.bisect_right(zs, fixed) - 1))
            t = (fixed - zs[r]) / (zs[r + 1] - zs[r])
            for c in range(len(xs) - 1):
                points.update(p for p in [xs[c], xs[c + 1], xs[c] + (xs[c + 1] - xs[c]) * (t if (r + c) % 2 == 0 else 1 - t)] if low <= p <= high)
    values = [height(fixed, p) if fixed_axis == 0 else height(p, fixed) for p in sorted(points)]
    return min(values), len(values)


def selected_code(path, names):
    tree = ast.parse(path.read_text())
    nodes = [n for n in tree.body if isinstance(n, (ast.ClassDef, ast.FunctionDef)) and n.name in names]
    namespace = {"math": math}
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(path), "exec"), namespace)
    return namespace


architecture_file = ROOT / "assets/moonlit_citadel/bl02/architecture.py"
rock_recipe_file = ROOT / "tools/moonlit-citadel/phase3/rework-20261012/drafts/BlenderReworkKit.py"
mesh_class = selected_code(architecture_file, {"_Mesh"})["_Mesh"]
rock_mesh = selected_code(rock_recipe_file, {"rocks"})["rocks"](SimpleNamespace(_Mesh=mesh_class))[0]
rock_vertices = [(x, z, -y) for x, y, z in rock_mesh.vertices]
tree_recipe_file = ROOT / "tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/landscape/Source48TreeRecipes.py"
tree_namespace = selected_code(tree_recipe_file, {"Mesh", "herbs"})
heather_vertices = tree_namespace["herbs"]().vertices
heather_roots = [p for p in heather_vertices if p[1] <= .05]

manifests = {
    "P3": ROOT / "assets/moonlit_citadel/phase3/rework-20261012/rw01/manifest.json",
    "TL01": ROOT / "assets/moonlit_citadel/phase3/tower-landscape-20261013/tl01/manifest.json",
    "ER01": ROOT / "assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/manifest.json",
}
metadata = {}
for library, path in manifests.items():
    data = json.loads(path.read_text())
    for asset in data["assets"]:
        parts = [part for part in data["export_parts"] if part["asset"] == asset["asset"]]
        low_b, high_b = asset["bounds"]
        low, high = [low_b[0], low_b[2], -high_b[1]], [high_b[0], high_b[2], -low_b[1]]
        metadata[asset["asset"]] = {"parts": len(parts), "triangles": asset["geometry"]["triangles"], "low": low, "high": high, "library": library}


def transform(point, frame, scale):
    p = [point[i] * scale[i] for i in range(3)]
    return tuple(frame[i] + sum(frame[3 + i * 3 + j] * p[j] for j in range(3)) for i in range(3))


def add(name, asset, frame, scale, role, proof):
    unit = {"district": "CliffFinishing", "name": name, "asset": asset, "localCF": frame, "scale": scale, "library": metadata[asset]["library"], "materialRole": role}
    units.append(unit)
    support.append({"name": name, **proof})


def outcrop(name, side, lateral, y, scale):
    meta = metadata["MC_P3_Rework_RockCluster"]
    if side == "west":
        # Rotate the closed rock bases into the cliff: these are projections, not horizontal pads.
        rot = [0, 1, 0, 0, 0, 1, 1, 0, 0]
        span_low, span_high = lateral + meta["low"][0] * scale[0], lateral + meta["high"][0] * scale[0]
        top_y = y + meta["high"][2] * scale[2]
        chosen = None
        for step in range(260):
            x = -298 - step * .25
            minimum, count = line_min(0, x, span_low, span_high)
            if minimum >= top_y + 4:
                chosen = x
                break
        assert chosen is not None
        frame = [chosen, y, lateral] + rot
    else:
        rot = [1, 0, 0, 0, 0, -1, 0, 1, 0]
        span_low, span_high = lateral + meta["low"][0] * scale[0], lateral + meta["high"][0] * scale[0]
        top_y = y - meta["low"][2] * scale[2]
        chosen = None
        for step in range(240):
            z = -242 - step * .25
            minimum, count = line_min(2, z, span_low, span_high)
            if minimum >= top_y + 4:
                chosen = z
                break
        assert chosen is not None
        frame = [lateral, y, chosen] + rot
    vertices = [transform(p, frame, scale) for p in rock_vertices]
    exposure = [p[1] - height(p[0], p[2]) for p in vertices]
    assert max(exposure) > 5, (name, max(exposure))
    add(name, "MC_P3_Rework_RockCluster", frame, scale, "EmbeddedCliffRock", {"kind": "vertical buried rock base envelope", "minimumBaseBurial": minimum - top_y, "exactTerrainLineBreaks": count, "exposedVertexCount": sum(n > .1 for n in exposure), "authoredVertexCount": len(vertices), "maximumVertexHeightAboveTerrain": max(exposure), "baseHorizontal": False, "maximumOutwardProjectionStuds": meta["high"][1] * scale[1]})


for name, side, lateral, y, scale in [
    ("WestCliffLowerFold", "west", -88, 83, [4.5, 6.4, 3]),
    ("WestCliffUpperFold", "west", -67, 137, [3.3, 5.6, 2.8]),
    ("WestCliffMiddleFold", "west", 14, 121, [4, 6.4, 3]),
    ("WestCliffArrivalFold", "west", 73, 91, [4.6, 6.8, 2.9]),
    ("WestCliffSouthShoulder", "west", 114, 165, [3.1, 5, 2.5]),
    ("NorthCliffWestFold", "north", -174, 145, [3.8, 6, 3.4]),
    ("NorthCliffCentralFold", "north", -102, 186, [3.2, 5.3, 2.8]),
    ("NorthCliffGalleryFold", "north", -52, 153, [3.6, 6.5, 2.7]),
]:
    outcrop(name, side, lateral, y, scale)


def point_on_slope(side, lateral, desired_height, preferred_material=None):
    possible = []
    offsets = [0] if not preferred_material else [0, -2, 2, -4, 4, -6, 6, -8, 8, -10, 10, -12, 12, -14, 14]
    for offset in offsets:
        for step in range(300):
            edge = (-298 if side == "west" else -242) - step * .25
            x, z = (edge, lateral + offset) if side == "west" else (lateral + offset, edge)
            if preferred_material and height(x, z, True)["sourceMaterial"] != preferred_material:
                continue
            possible.append((abs(height(x, z) - desired_height) + abs(offset) * .25, x, z))
    assert possible, (side, lateral, desired_height, preferred_material)
    _, x, z = min(possible)
    return x, z


def tree(name, side, lateral, desired, asset, scale, yaw):
    x, z = point_on_slope(side, lateral, desired)
    c, s = math.cos(yaw), math.sin(yaw)
    rot = [c, 0, s, 0, 1, 0, -s, 0, c]
    radius = .9 if "Broadleaf" in asset else .8
    rz = .85 if "Broadleaf" in asset else .75
    roots = [(math.cos(i * math.tau / 8) * radius, -2, math.sin(i * math.tau / 8) * rz) for i in range(8)]
    provisional = [x, 0, z] + rot
    samples = [transform(p, provisional, [scale] * 3) for p in roots]
    y = min(height(p[0], p[2]) - p[1] for p in samples) - 1.1
    frame = [x, y, z] + rot
    depths = [height(p[0], p[2]) - p[1] for p in [transform(p, frame, [scale] * 3) for p in roots]]
    assert min(depths) >= 1.09
    points = [transform(p, frame, [scale] * 3) for part in authored_er if part["name"].startswith(asset + "__") for p in part["vertices"]]
    exposed = [p[1] - height(p[0], p[2]) for p in points]
    assert sum(n > .1 for n in exposed) >= 20, (name, "tree buried completely")
    add(name, asset, frame, [scale] * 3, "CliffTreeGroup", {"kind": "all eight actual trunk base vertices", "minimumBaseBurial": min(depths), "maximumBaseBurial": max(depths), "actualTerrainCenterHeight": height(x, z), "trunkBaseVertexCount": len(roots), "upright": True, "exposedVertexCount": sum(n > .1 for n in exposed), "authoredVertexCount": len(points), "treeTopY": max(p[1] for p in points)})


for args in [
    ("WestCliffLowPine", "west", -112, 98, "MC_EC_SlopePine", .80, .42),
    ("WestCliffLowBroadleaf", "west", -95, 77, "MC_EC_SlopeBroadleaf", .84, 1.1),
    ("WestCliffMiddleBroadleaf", "west", -5, 121, "MC_EC_SlopeBroadleaf", .91, 2.3),
    ("WestCliffArrivalPine", "west", 94, 103, "MC_EC_SlopePine", .78, 2.8),
    ("NorthCliffLowBroadleaf", "north", -153, 121, "MC_EC_SlopeBroadleaf", .86, .8),
    ("NorthCliffLowPine", "north", -68, 136, "MC_EC_SlopePine", .79, 1.7),
]:
    tree(*args)


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def norm(a):
    length = math.sqrt(sum(n * n for n in a))
    return [n / length for n in a]


def herbs(name, side, lateral, desired, scale, yaw, preferred_material=None):
    x, z = point_on_slope(side, lateral, desired, preferred_material)
    dx, dz = (height(x + .02, z) - height(x - .02, z)) / .04, (height(x, z + .02) - height(x, z - .02)) / .04
    up = norm([-dx, 1, -dz])
    right = norm(cross(up, [0, 0, 1]))
    back = cross(right, up)
    c, s = math.cos(yaw), math.sin(yaw)
    right, back = ([c * right[i] - s * back[i] for i in range(3)], [s * right[i] + c * back[i] for i in range(3)])
    rot = [right[0], up[0], back[0], right[1], up[1], back[1], right[2], up[2], back[2]]
    y = height(x, z)
    frame = [x, y, z] + rot
    base_points = [transform(p, frame, [scale] * 3) for p in heather_roots]
    drop = max(p[1] - height(p[0], p[2]) for p in base_points) + .18
    frame[1] -= drop
    roots = [transform(p, frame, [scale] * 3) for p in heather_roots]
    burial = [height(p[0], p[2]) - p[1] for p in roots]
    all_points = [transform(p, frame, [scale] * 3) for p in heather_vertices]
    exposure = [p[1] - height(p[0], p[2]) for p in all_points]
    assert min(burial) >= .179 and sum(n > .1 for n in exposure) >= 30
    add(name, "MC_P3_Rural_HeatherFern", frame, [scale] * 3, "CliffUnderstory", {"kind": "all authored low herb vertices; terrain tangent orientation", "minimumBaseBurial": min(burial), "lowVertexCount": len(roots), "exposedVertexCount": sum(n > .1 for n in exposure), "authoredVertexCount": len(all_points), "terrainNormal": up, **height(x, z, True)})


for args in [
    ("WestCliffHerbs1", "west", -111, 110, 1.10, .3),
    ("WestCliffHerbs2", "west", -88, 83, 1.0, 1.4),
    ("WestCliffHerbs3", "west", -71, 199, 1.1, 2.2, "Earth"),
    ("WestCliffHerbs4", "west", -20, 129, .95, .2),
    ("WestCliffHerbs5", "west", 27, 206, 1.0, 1.8),
    ("WestCliffHerbs6", "west", 89, 113, 1.1, 2.4),
    ("NorthCliffHerbs1", "north", -185, 217, 1.05, .1, "Earth"),
    ("NorthCliffHerbs2", "north", -144, 139, .95, 1.5),
    ("NorthCliffHerbs3", "north", -66, 161, 1.0, 2.2),
]:
    herbs(*args)

costs = {}
for u in units:
    costs.setdefault(u["asset"], {"library": u["library"], "count": 0, "partsEach": metadata[u["asset"]]["parts"], "trianglesEach": metadata[u["asset"]]["triangles"]})["count"] += 1
totals = {"units": len(units), "meshParts": sum(v["count"] * v["partsEach"] for v in costs.values()), "triangles": sum(v["count"] * v["trianglesEach"] for v in costs.values())}
source_inputs = [TERRAIN_FILE, architecture_file, rock_recipe_file, tree_recipe_file, authored_er_file, *manifests.values(), Path(__file__)]
report = {"schema": 1, "candidateBase": "MC_P3_ENCLOSURE_ER01 Source49 Build43", "additions": units, "costLedger": costs, "totals": totals, "supportProof": support, "metadata": {k: metadata[k] for k in costs}, "inputHashes": {str(p.relative_to(ROOT)).replace('\\', '/'): digest(p) for p in source_inputs}, "terrainChanged": False, "existingUnitsChanged": False, "nativeAppearanceVerified": False, "newUploadRequired": False, "collide": False, "query": False, "touch": False}
OWN.mkdir(parents=True, exist_ok=True)
(OWN / "cliff-placement-plan.json").write_text(json.dumps(report, indent=2) + "\n")


def numbers(values):
    return ",".join(f"{n:.9f}".rstrip("0").rstrip(".") or "0" for n in values)


lines = ["--!nonstrict", "local Finishing={}", "local v=Vector3.new", "local Metadata={"]
for name in costs:
    m = metadata[name]
    lines.append(f' ["{name}"]={{parts={m["parts"]},triangles={m["triangles"]},low=v({numbers(m["low"])}),high=v({numbers(m["high"])}),library="{m["library"]}"}},')
lines.extend(["}", "local Units={"])
for u in units:
    lines.append(f' {{district="{u["district"]}",name="{u["name"]}",asset="{u["asset"]}",localCF=CFrame.new({numbers(u["localCF"])}),scale=v({numbers(u["scale"])}),library="{u["library"]}",materialRole="{u["materialRole"]}"}},')
lines.extend(["}", "function Finishing.Get()", " local plan,rows={},{}", " local counts={units=0,meshParts=0,triangles=0,proposalRows=rows,artCanCollide=false,artCanQuery=false,artCanTouch=false}", " for _,unit in Units do", "  local meta=assert(Metadata[unit.asset])", "  table.insert(plan,table.clone(unit))", "  counts.units+=1;counts.meshParts+=meta.parts;counts.triangles+=meta.triangles", "  local cf=unit.localCF*CFrame.new((meta.low+meta.high)/2*unit.scale)", "  local size=(meta.high-meta.low)*unit.scale", '  table.insert(rows,{path="CliffFinishing/"..unit.name,frame={cf:GetComponents()},size={size.X,size.Y,size.Z},anchored=true,collide=false,query=false,touch=false,transparency=0})', " end", " return plan,counts", "end", "Finishing.AssetGeometry=Metadata", "return Finishing", ""])
(OWN / "CliffFinishingPlan.luau").write_text("\n".join(lines))
print(json.dumps({"totals": totals, "minimumRockBurial": min(p["minimumBaseBurial"] for p in support if p["kind"].startswith("vertical")), "rootedTrees": sum("trunkBaseVertexCount" in p for p in support), "rootedUnderstory": sum("lowVertexCount" in p for p in support), "newUpload": False}))
