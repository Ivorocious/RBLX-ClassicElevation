"""Read the exported unchanged E1 floor geometry; check jump reach across the parapet."""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
PACKET = ROOT / "docs/artifacts/moonlit-citadel/phase3/INTEGRATED_LAYOUT.json"
data = json.loads(PACKET.read_text(encoding="utf-8"))
surfaces = data["Surfaces"]


def polygon(surface):
    p, size = surface["position"]["value"], surface["size"]["value"]
    cf = surface.get("frame", {}).get("value")
    right, back = ((cf[3], cf[9]), (cf[5], cf[11])) if cf else ((1, 0), (0, 1))
    half_x, half_z = max(0, size[0] / 2 - 1), max(0, size[2] / 2 - 1)
    return [(p[0] + right[0] * x + back[0] * z, p[2] + right[1] * x + back[1] * z)
            for x, z in [(-half_x, -half_z), (half_x, -half_z),
                         (half_x, half_z), (-half_x, half_z)]]


def clip_west(points, boundary=-145):
    result = []
    for a, b in zip(points, points[1:] + points[:1]):
        inside_a, inside_b = a[0] <= boundary, b[0] <= boundary
        if inside_a:
            result.append(a)
        if inside_a != inside_b:
            t = (boundary - a[0]) / (b[0] - a[0])
            result.append((boundary, a[1] + t * (b[1] - a[1])))
    return result


def point_segment(point, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    denominator = dx * dx + dz * dz
    t = max(0, min(1, ((point[0] - a[0]) * dx + (point[1] - a[1]) * dz) / denominator)) if denominator else 0
    nearest = (a[0] + t * dx, a[1] + t * dz)
    return math.dist(point, nearest)


def distance(first, second):
    return min(point_segment(point, a, b)
               for points, edges in [(first, second), (second, first)]
               for point in points for a, b in zip(edges, edges[1:] + edges[:1]))


speed = math.sqrt(2 * 196.2 * 7.2)
sources = [surface for surface in surfaces if surface["group"] in {"Gate", "SharedArches", "ArchNormal"}]
targets = [surface for surface in surfaces if surface["group"] == "ArchExpert"
           and surface["name"] in {"RiseCorbel", "WrapTurn", "HurdleBeam"}]
possible = []
for target in targets:
    rows = []
    for source in sources:
        source_points = clip_west(polygon(source))
        if not source_points:
            continue
        rise = target["position"]["value"][1] - source["position"]["value"][1]
        if rise > 7.2:
            continue
        reach = 16 * (speed + math.sqrt(speed * speed - 2 * 196.2 * rise)) / 196.2
        separation = distance(source_points, polygon(target))
        rows.append((separation - reach, separation, reach, rise, source["group"] + "/" + source["name"]))
        if separation <= reach:
            possible.append((source["group"] + "/" + source["name"], target["name"], separation, reach))
    for deficit, separation, reach, rise, source_name in sorted(rows)[:2]:
        print(f"{source_name} -> {target['name']}: foot separation {separation:.2f}, ideal reach {reach:.2f}, rise {rise:.2f}, deficit {deficit:.2f} studs")

print(f"Possible airborne west-to-east bypass pairs in this early route subset: {len(possible)}")
for finding in possible:
    print(finding)
print("CP01 28 -> WrapTurn 36 = rise8; RiseCorbel32 -> HurdleBeam40 = rise8; both exceed JumpHeight7.2.")
print("This ideal static reach screen is not a native movement or visual pass.")
