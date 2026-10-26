"""Measure palm roots and stalactite anchors against the authored Blender meshes."""
import json
import math
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree


ROOT = Path(__file__).resolve().parent
LAYOUT_PATH = ROOT / "layout28.json"
SOURCE_BLEND = ROOT / "ShipwreckCove_SC_MAP_27.blend"
KIT_BLEND = ROOT / "ShipwreckCove_Kit28.blend"
LAYOUT = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
assert LAYOUT["build"] == "SC_MAP_28" and LAYOUT["kitBuild"] == "SC_KIT_28"

bpy.ops.wm.open_mainfile(filepath=str(SOURCE_BLEND))


def mesh_bvh(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    matrix = obj.matrix_world
    vertices = [matrix @ vertex.co for vertex in mesh.vertices]
    polygons = [list(polygon.vertices) for polygon in mesh.polygons if len(polygon.vertices) >= 3]
    tree = BVHTree.FromPolygons(vertices, polygons)
    evaluated.to_mesh_clear()
    return tree


ground_bvhs = []
cave_bvhs = []
for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        continue
    asset = obj.get("Asset", "")
    if asset in ("SC_R_SandIsland", "SC_R_SandWedge", "SC_R_ShoreBank"):
        ground_bvhs.append((obj.name, asset, mesh_bvh(obj)))
    if asset in ("SC_R_CaveMouth26", "SC_R_CaveVault26", "SC_R_CaveSurge26"):
        cave_bvhs.append((obj.name, asset, mesh_bvh(obj)))
assert ground_bvhs and cave_bvhs

with bpy.data.libraries.load(str(KIT_BLEND), link=False) as (source, target):
    target.objects = [name for name in source.objects if name in ("SC_R_Palm28", "SC_R_Stalactite28")]
kit_objects = {obj.name: obj for obj in target.objects if obj is not None}
assert set(kit_objects) == {"SC_R_Palm28", "SC_R_Stalactite28"}
palm_mesh = kit_objects["SC_R_Palm28"].data
stalactite_mesh = kit_objects["SC_R_Stalactite28"].data
trunk_vertex_count = 17 * 12
assert len(palm_mesh.vertices) >= trunk_vertex_count
stalactite_local_y = [vertex.co.z for vertex in stalactite_mesh.vertices]
stalactite_top_rooted = abs(max(stalactite_local_y)) < 1e-5 and abs(min(stalactite_local_y) + 7.0) < 1e-4
assert stalactite_top_rooted, (min(stalactite_local_y), max(stalactite_local_y))


def transform_for(placement, x=None, z=None):
    px, py, pz = placement["p"]
    sx, sy, sz = placement.get("scale", (1.0, 1.0, 1.0))
    yaw = math.radians(placement.get("yaw", 0.0))
    pitch = math.radians(placement.get("pitch", 0.0))
    rotation = Euler((pitch, 0.0, yaw), "XYZ").to_matrix().to_4x4()
    scale = Matrix.Diagonal((sx, sz, sy, 1.0))
    return Matrix.Translation((px if x is None else x, -(pz if z is None else z), py)) @ rotation @ scale


def ray_hits(group, x, z, origin_y, direction, maximum=500.0):
    origin = Vector((x, -z, origin_y))
    ray_direction = Vector(direction)
    hits = []
    for name, asset, tree in group:
        hit, normal, _index, distance = tree.ray_cast(origin, ray_direction, maximum)
        if hit is not None:
            hits.append({
                "y": float(hit.z),
                "surface": name,
                "asset": asset,
                "normalBlender": [float(normal.x), float(normal.y), float(normal.z)],
                "distance": float(distance),
            })
    return hits


def support_at(x, z, local_samples, matrix, minimum_hits=9):
    hits = []
    objects = set()
    for sample in local_samples:
        point = matrix @ sample
        ray_result = ray_hits(ground_bvhs, point.x, -point.y, 180.0, (0.0, 0.0, -1.0))
        if ray_result:
            hit = max(ray_result, key=lambda row: row["y"])
            hits.append(hit["y"])
            objects.add(hit["surface"])
    if len(hits) < minimum_hits:
        return None
    ordered = sorted(hits)
    middle = len(ordered) // 2
    median = ordered[middle] if len(ordered) % 2 else 0.5 * (ordered[middle - 1] + ordered[middle])
    return {
        "rootY": median - 0.05,
        "medianSurfaceY": median,
        "minSurfaceY": ordered[0],
        "maxSurfaceY": ordered[-1],
        "sampleCount": len(hits),
        "sampleTotal": len(local_samples),
        "surfaces": sorted(objects),
    }


def convex_hull(points):
    points = sorted(set((float(point[0]), float(point[1])) for point in points))
    if len(points) <= 1:
        return points

    def cross(origin, a, b):
        return (a[0] - origin[0]) * (b[1] - origin[1]) - (a[1] - origin[1]) * (b[0] - origin[0])

    lower = []
    for point in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0.0:
            lower.pop()
        lower.append(point)
    upper = []
    for point in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0.0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def point_segment_distance(point, start, end):
    dx, dz = end[0] - start[0], end[1] - start[1]
    length_squared = dx * dx + dz * dz
    if length_squared <= 1e-10:
        return math.dist(point, start), start
    t = max(0.0, min(1.0, ((point[0] - start[0]) * dx + (point[1] - start[1]) * dz) / length_squared))
    nearest = (start[0] + t * dx, start[1] + t * dz)
    return math.dist(point, nearest), nearest


def segments_intersect(a, b, c, d):
    def orient(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])

    def on_segment(p, q, r):
        return (min(p[0], r[0]) - 1e-8 <= q[0] <= max(p[0], r[0]) + 1e-8
                and min(p[1], r[1]) - 1e-8 <= q[1] <= max(p[1], r[1]) + 1e-8)

    o1, o2 = orient(a, b, c), orient(a, b, d)
    o3, o4 = orient(c, d, a), orient(c, d, b)
    if o1 * o2 < 0.0 and o3 * o4 < 0.0:
        return True
    return ((abs(o1) <= 1e-8 and on_segment(a, c, b))
            or (abs(o2) <= 1e-8 and on_segment(a, d, b))
            or (abs(o3) <= 1e-8 and on_segment(c, a, d))
            or (abs(o4) <= 1e-8 and on_segment(c, b, d)))


def hull_route_distance(hull, path):
    best = (float("inf"), None, None)
    if not hull or len(path) < 2:
        return best
    hull_edges = list(zip(hull, hull[1:] + hull[:1])) if len(hull) > 1 else [(hull[0], hull[0])]
    for route_start, route_end in zip(path, path[1:]):
        for edge_start, edge_end in hull_edges:
            if segments_intersect(route_start, route_end, edge_start, edge_end):
                return 0.0, route_start, route_start
            a, near_route = point_segment_distance(edge_start, route_start, route_end)
            b, near_edge = point_segment_distance(route_start, edge_start, edge_end)
            c, near_route_end = point_segment_distance(edge_end, route_start, route_end)
            d, near_edge_end = point_segment_distance(route_end, edge_start, edge_end)
            if a < best[0]:
                best = (a, near_route, edge_start)
            if b < best[0]:
                best = (b, route_start, near_edge)
            if c < best[0]:
                best = (c, near_route_end, edge_end)
            if d < best[0]:
                best = (d, route_end, near_edge_end)
    return best


def palm_measure(placement, x=None, z=None):
    matrix = transform_for(placement, x, z)
    base_ring = [palm_mesh.vertices[index].co.copy() for index in range(12)]
    base_samples = [Vector((0.0, 0.0, 0.0))] + base_ring
    support = support_at(placement["p"][0] if x is None else x,
                         placement["p"][2] if z is None else z,
                         base_samples, matrix)

    local_trunk = [vertex.co.copy() for vertex in palm_mesh.vertices[:trunk_vertex_count]
                   if vertex.co.z <= 8.01]
    hull_points = []
    for vertex in local_trunk:
        point = matrix @ vertex
        hull_points.append((point.x, -point.y))
    hull = convex_hull(hull_points)
    path = [(float(point[0]), float(point[2])) for point in LAYOUT["paths"]["S04_Shore"]]
    distance, route_point, hull_point = hull_route_distance(hull, path)
    return support, distance - 6.0, distance, route_point, hull_point


def closest_surface(x, z):
    best = None
    for surface in LAYOUT["surfaces"]:
        if surface.get("section") not in ("S04_Entry", "H02"):
            continue
        sx, _sy, sz = surface["p"]
        width, _height, depth = surface["size"]
        angle = math.radians(surface.get("yaw", 0.0))
        dx, dz = x - sx, z - sz
        lx = math.cos(angle) * dx - math.sin(angle) * dz
        lz = math.sin(angle) * dx + math.cos(angle) * dz
        clx = max(-width / 2.0, min(width / 2.0, lx))
        clz = max(-depth / 2.0, min(depth / 2.0, lz))
        nearest_x = sx + math.cos(angle) * clx + math.sin(angle) * clz
        nearest_z = sz - math.sin(angle) * clx + math.cos(angle) * clz
        gap = math.hypot(x - nearest_x, z - nearest_z)
        if best is None or gap < best["gap"]:
            best = {"name": surface["name"], "y": surface["p"][1], "gap": gap,
                    "nearestXZ": [nearest_x, nearest_z], "containsPoint": gap < 1e-5,
                    "section": surface.get("section", ""), "centerXZ": [sx, sz],
                    "sizeXZ": [width, depth], "yaw": surface.get("yaw", 0.0)}
    return best


def cave_roof(x, z, floor_hint=0.0):
    hits = ray_hits(cave_bvhs, x, z, floor_hint, (0.0, 0.0, 1.0))
    hits = [hit for hit in hits if hit["y"] >= floor_hint - 1e-4]
    return min(hits, key=lambda row: row["y"]) if hits else None


placements = {}
evidence = []
walking_half_width = 6.0
for placement in LAYOUT["placements"]:
    if placement["name"].startswith("GrovePalm28_"):
        original_x, original_y, original_z = placement["p"]
        x, z = original_x, original_z
        support, clearance, distance, route_point, hull_point = palm_measure(placement, x, z)
        original_clearance = clearance

        if clearance < 0.0:
            nearest_route = min((point_segment_distance((x, z), start, end)
                                 for start, end in zip(LAYOUT["paths"]["S04_Shore"],
                                                       LAYOUT["paths"]["S04_Shore"][1:])),
                                key=lambda row: row[0])
            _, route_center = nearest_route
            direction_x, direction_z = x - route_center[0], z - route_center[1]
            direction_length = math.hypot(direction_x, direction_z)
            if direction_length < 1e-6:
                direction_x, direction_z, direction_length = 1.0, 0.0, 1.0
            direction_x, direction_z = direction_x / direction_length, direction_z / direction_length
            found = False
            for offset in [step * 1.0 for step in range(1, 41)]:
                candidate_x = original_x + direction_x * offset
                candidate_z = original_z + direction_z * offset
                candidate_support, candidate_clearance, candidate_distance, candidate_route, candidate_hull = palm_measure(
                    placement, candidate_x, candidate_z)
                if candidate_clearance >= 0.25 and candidate_support is not None and candidate_support["sampleCount"] >= 11:
                    x, z = candidate_x, candidate_z
                    support, clearance, distance = candidate_support, candidate_clearance, candidate_distance
                    route_point, hull_point = candidate_route, candidate_hull
                    found = True
                    break
            if not found:
                raise RuntimeError(f"Could not find a supported lane-clear root for {placement['name']}")

        assert support is not None, placement["name"]
        corrected = [round(x, 4), round(support["rootY"], 4), round(z, 4)]
        placements[placement["name"]] = corrected
        evidence.append({
            "name": placement["name"],
            "asset": "SC_R_Palm28",
            "supportSurfaces": support["surfaces"],
            "baseRaySamples": support["sampleCount"],
            "baseRaySamplesRequested": support["sampleTotal"],
            "visualSurfaceYRange": [round(support["minSurfaceY"], 4), round(support["maxSurfaceY"], 4)],
            "rootY": corrected[1],
            "originalP": [original_x, original_y, original_z],
            "suggestedP": corrected,
            "routeCenterlineDistanceFromTrunkHull": round(distance, 4),
            "walkingLaneHalfWidth": walking_half_width,
            "clearanceOutside12StudLane": round(clearance, 4),
            "originalClearanceOutside12StudLane": round(original_clearance, 4),
            "nearestRoutePointXZ": [round(route_point[0], 4), round(route_point[1], 4)] if route_point else None,
        })

for placement in LAYOUT["placements"]:
    if placement["name"].startswith("FixedSpike27_"):
        x, _y, z = placement["p"]
        roof = cave_roof(x, z)
        assert roof, placement["name"]
        root_y = roof["y"] + 0.3
        suggested = [round(x, 4), round(root_y, 4), round(z, 4)]
        placements[placement["name"]] = suggested
        evidence.append({
            "name": placement["name"],
            "asset": "SC_R_Stalactite28",
            "supportCaveMesh": roof["surface"],
            "roofY": round(roof["y"], 4),
            "recommendedRootOffsetIntoShell": 0.3,
            "originalP": placement["p"],
            "suggestedP": suggested,
        })

falling = {}
for definition in LAYOUT["falling"]:
    if definition.get("kind") != "stalactite":
        continue
    original_x, _top_y, original_z = definition["top"]
    floor = closest_surface(original_x, original_z)
    assert floor, definition["name"]
    original_floor = dict(floor)
    x, z = original_x, original_z
    if not floor["containsPoint"]:
        edge_x, edge_z = floor["nearestXZ"]
        center_x, center_z = floor["centerXZ"]
        inward_x, inward_z = center_x - edge_x, center_z - edge_z
        inward_length = math.hypot(inward_x, inward_z)
        if inward_length > 1e-8:
            inset = min(0.3, inward_length)
            x = edge_x + inward_x / inward_length * inset
            z = edge_z + inward_z / inward_length * inset
        floor = closest_surface(x, z)
        assert floor and floor["containsPoint"], (definition["name"], x, z, floor)
    roof = cave_roof(x, z)
    assert roof, definition["name"]
    # The kit28 source pivot is at the blunt upper face; runtime positions are MeshPart centers.
    top_root_y = roof["y"] + 0.3
    bottom_root_y = floor["y"] + 7.0 - 0.1
    top_center_y = top_root_y - 3.5
    bottom_center_y = bottom_root_y - 3.5
    top_root = [round(x, 4), round(top_root_y, 4), round(z, 4)]
    bottom_root = [round(x, 4), round(bottom_root_y, 4), round(z, 4)]
    top = [round(x, 4), round(top_center_y, 4), round(z, 4)]
    bottom = [round(x, 4), round(bottom_center_y, 4), round(z, 4)]
    falling[definition["name"]] = {"top": top, "bottom": bottom,
                                   "topRoot": top_root, "bottomRoot": bottom_root}
    evidence.append({
        "name": definition["name"],
        "asset": "SC_R_Stalactite28",
        "supportCaveMesh": roof["surface"],
        "roofY": round(roof["y"], 4),
        "topRoot": top_root,
        "bottomRoot": bottom_root,
        "runtimeMeshPartCenterTop": top,
        "runtimeMeshPartCenterBottom": bottom,
        "localTipY": -7.0,
        "floorCollider": floor["name"],
        "floorColliderTopY": floor["y"],
        "floorColliderGapFromSpikeXZ": round(floor["gap"], 4),
        "floorColliderContainsSpikeXZ": floor["containsPoint"],
        "originalXZ": [original_x, original_z],
        "suggestedXZ": [round(x, 4), round(z, 4)],
        "horizontalShiftFromOriginal": round(math.hypot(x - original_x, z - original_z), 4),
        "nearestPlatformAtOriginalXZ": original_floor["name"],
        "originalXZFloorColliderGap": round(original_floor["gap"], 4),
        "nearestPlatformXZAtOriginal": [round(original_floor["nearestXZ"][0], 4), round(original_floor["nearestXZ"][1], 4)],
        "originalTop": definition["top"],
        "originalBottom": definition["bottom"],
    })

result = {
    "build": LAYOUT["build"],
    "kitBuild": LAYOUT["kitBuild"],
    "basis": "Roblox [x,y,z]; Blender [x,-z,y]",
    "sourceScene": SOURCE_BLEND.name,
    "meshLibrary": KIT_BLEND.name,
    "layoutReadOnce": LAYOUT_PATH.name,
    "caveShellAssets": ["SC_R_CaveMouth26", "SC_R_CaveVault26", "SC_R_CaveSurge26"],
    "groundVisualAssets": ["SC_R_SandIsland", "SC_R_SandWedge", "SC_R_ShoreBank"],
    "stalactitePivot": {"rootAtLocalRobloxY": 0.0, "tipLocalRobloxY": -7.0,
                         "checkedFromMeshVertices": stalactite_top_rooted},
    "fallingPositionSemantics": "top and bottom are MeshPart center CFrames; topRoot and bottomRoot document the source-mesh anchor points; center Y = anchor Y - 3.5.",
    "walkingLaneWidth": 12.0,
    "placements": placements,
    "falling": falling,
    "evidence": evidence,
    "limits": [
        "Palm roots were ray-tested against visible sand/beach mesh BVHs; route clearance is a geometric plan-view check against the layout path.",
        "Cave ceiling roots were ray-tested against the approved cave shell meshes.",
        "Added falling spikes are shifted to the nearest Cave26Stone collider interior before ceiling and landing rays are measured.",
        "This is mesh-grounding evidence, not a collision or Studio playtest result."
    ],
}
(ROOT / "grounding28.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps({
    "palmCount": sum(name.startswith("GrovePalm28_") for name in placements),
    "fixedSpikeCount": sum(name.startswith("FixedSpike27_") for name in placements),
    "fallingSpikeCount": len(falling),
    "palmLaneClearanceMin": min(row["clearanceOutside12StudLane"] for row in evidence if row.get("asset") == "SC_R_Palm28"),
    "palmSurfaceSamplesMin": min(row["baseRaySamples"] for row in evidence if row.get("asset") == "SC_R_Palm28"),
    "fallingWithoutDirectCollider": [row["name"] for row in evidence if row.get("asset") == "SC_R_Stalactite28" and row.get("floorColliderContainsSpikeXZ") is False],
    "output": str(ROOT / "grounding28.json"),
}, indent=2))
