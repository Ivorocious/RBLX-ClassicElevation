"""Focused placement measurements, without native or rendered-visibility claims."""
import hashlib
import importlib.util
import json
import math
from pathlib import Path

OWN = Path(__file__).parent
plan = json.loads((OWN / "placement-plan.json").read_text(encoding="utf-8"))
spec = importlib.util.spec_from_file_location("rural_geometry", OWN / "LandscapeKitRecipes.py")
mesh_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mesh_module)
mesh = mesh_module.mound()
grass_triangles = []
for face, material in zip(mesh.faces, mesh.materials):
    if material != "Grass":
        continue
    for i in range(1, len(face) - 1):
        grass_triangles.append([mesh.vertices[k] for k in (face[0], face[i], face[i + 1])])


def grass_height(x, z):
    for a, b, c in grass_triangles:
        denominator = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
        if abs(denominator) < 1e-8:
            continue
        u = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / denominator
        v = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / denominator
        w = 1 - u - v
        if min(u, v, w) >= -1e-6:
            return u * a[1] + v * b[1] + w * c[1]
    return None


def transform(row, point):
    cf = row["frame"]
    scaled = [point[i] * row["scale"][i] for i in range(3)]
    return [cf[i] + sum(cf[3 + i * 3 + j] * scaled[j] for j in range(3)) for i in range(3)]


def inverse_xz(row, x, z):
    cf, scale = row["frame"], row["scale"]
    dx, dz = x - cf[0], z - cf[2]
    return (cf[3] * dx + cf[9] * dz) / scale[0], (cf[5] * dx + cf[11] * dz) / scale[2]


def polygon_ellipse(x, z, rx, rz, sides):
    u, v = x / rx, z / rz
    radial = math.sqrt(u * u + v * v)
    if radial > 1:
        return False
    sector = math.tau / sides
    angle = math.atan2(v, u) % sector - sector / 2
    edge = math.cos(sector / 2) / math.cos(angle)
    return radial <= edge


hills = [row for row in plan if row["asset"] == "MC_P3_Rural_Mound"]
groves = [row for row in plan if row["asset"] in {"MC_P3_Rural_BroadleafClump", "MC_P3_Rural_EvergreenGrove"}]
seats = [row for row in plan if row["name"].endswith("SeatedBedrock")]
above_soil = []
for row in groves:
    roots = [(-8, -2, -3), (7, -2, 1), (-1, -2, 6)] if "Broadleaf" in row["asset"] else [(-9, -2, -7), (8, -2, 6), (-5, -2, 9)]
    for index, root in enumerate(roots):
        world = transform(row, root)
        heights = []
        for hill in hills:
            x, z = inverse_xz(hill, world[0], world[2])
            height = grass_height(x, z)
            if height is not None:
                heights.append(hill["frame"][1] + height * hill["scale"][1])
        gap = world[1] - max(heights)
        if gap > .1:
            above_soil.append({"grove": row["name"], "tree": index + 1, "gap": gap})
assert not above_soil, above_soil

area = green = canopy = wooded_hills = wooded_canopy = 0
step = 4
for x in range(-366, 338, step):
    for z in range(-332, 334, step):
        inside = is_green = is_wooded = False
        for hill in hills:
            u, v = inverse_xz(hill, x, z)
            inside |= polygon_ellipse(u, v, 32, 26, 16)
            grass = polygon_ellipse(u, v, 31.2, 25.35, 20)
            is_green |= grass
            is_wooded |= grass and hill["name"] in {"WestHighHill", "SouthGateHill", "SouthEastHill", "EastHighHill", "NorthHighHill"}
        if not inside:
            continue
        area += step * step
        for seat in seats:
            u, v = inverse_xz(seat, x, z)
            if abs(u) <= 16 and abs(v) <= 12:
                is_green = False
                break
        if is_green:
            green += step * step
        if is_wooded:
            wooded_hills += step * step
        crown = False
        for row in groves:
            u, v = inverse_xz(row, x, z)
            ellipses = [(-8, -3, 9, 9), (7, 1, 9, 10), (-1, 6, 8, 8)] if "Broadleaf" in row["asset"] else [(-9, -7, 6, 6), (8, 6, 7.3, 7.3), (-5, 9, 6, 6)]
            if any(((u - cx) / rx) ** 2 + ((v - cz) / rz) ** 2 <= 1 for cx, cz, rx, rz in ellipses):
                crown = True
                break
        if crown:
            canopy += step * step
            if is_wooded:
                wooded_canopy += step * step

source43 = json.loads(Path("docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/source43/final/artrepair_final_source43_sources.json").read_text(encoding="utf-8"))
original = next(row["source"] for row in source43["sources"] if row["instancePath"].endswith("EnvironmentPlan"))
draft = (OWN / "EnvironmentPlan.luau").read_text(encoding="utf-8")
profile_start, profile_end = "Environment.Profile", "local function frame"
assert draft[draft.index(profile_start):draft.index(profile_end)] == original[original.index(profile_start):original.index(profile_end)]
tail = "function Environment.PlaceSolidArrow"
assert draft[draft.index(tail):] == original[original.index(tail):]
report = {"plannedOnly": True, "rasterCellStuds": step, "islandFootprintStudsSquared": area,
          "conservativeGreenFootprintStudsSquared": green, "greenPercentExcludingBedrockSeats": round(green / area * 100, 2),
          "canopyEllipseUnionStudsSquared": canopy, "canopyPercentWholeIsland": round(canopy / area * 100, 2),
          "canopyPercentWoodedHills": round(wooded_canopy / wooded_hills * 100, 2),
          "rootCentresChecked": 33, "rootCentresAboveSoil": 0,
          "profileExactSource43": True, "arrowTailExactSource43": True,
          "arrowTailBytes": len(draft[draft.index(tail):].encode()),
          "arrowTailSha256": hashlib.sha256(draft[draft.index(tail):].encode()).hexdigest(),
          "nativeRenderedGreenCoverageVerified": False}
(OWN / "coverage-seating.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
