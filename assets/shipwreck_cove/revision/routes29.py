"""Route-only refinement applied to the frozen layout28 data."""
from __future__ import annotations

import math


def _distance_xz(a, b):
    return math.hypot(b[0] - a[0], b[2] - a[2])


def _edge_toward(center, size, target):
    dx, dz = target[0] - center[0], target[2] - center[2]
    length = math.hypot(dx, dz)
    if length == 0:
        raise ValueError("route edge needs a direction")
    ux, uz = dx / length, dz / length
    radius = abs(ux) * size[0] / 2 + abs(uz) * size[2] / 2
    return [center[0] + ux * radius, center[1], center[2] + uz * radius]


def _polyline_at(points, cumulative, distance):
    for i in range(1, len(points)):
        if distance <= cumulative[i]:
            span = cumulative[i] - cumulative[i - 1]
            t = 0 if span == 0 else (distance - cumulative[i - 1]) / span
            return [points[i - 1][k] + (points[i][k] - points[i - 1][k]) * t
                    for k in range(3)]
    return list(points[-1])


def _resample(points, spacing, margin, alternating=0.0):
    points = [list(p) for p in points]
    cumulative = [0.0]
    for a, b in zip(points, points[1:]):
        cumulative.append(cumulative[-1] + _distance_xz(a, b))
    total = cumulative[-1]
    margin = min(margin, total * 0.4)
    usable = max(0.0, total - 2 * margin)
    steps = max(1, math.ceil(usable / spacing))
    distances = [margin + usable * i / steps for i in range(steps + 1)]
    for i in range(1, len(distances) - 1):
        distances[i] += alternating * (1 if i % 2 else -1)
    return [_polyline_at(points, cumulative, distance) for distance in distances]


def _stagger(points, amount):
    result = [list(p) for p in points]
    for i in range(1, len(result) - 1):
        before, after = result[i - 1], result[i + 1]
        dx, dz = after[0] - before[0], after[2] - before[2]
        length = math.hypot(dx, dz)
        if length == 0:
            continue
        offset = amount * (1 if i % 2 else -1)
        result[i][0] -= dz / length * offset
        result[i][2] += dx / length * offset
    return result


def _limit_vertical_steps(points, max_rise, max_drop):
    result = [list(p) for p in points]
    for i in range(1, len(result)):
        delta = result[i][1] - result[i - 1][1]
        result[i][1] = result[i - 1][1] + min(max_rise, max(-max_drop, delta))
    return result


def _limit_vertical_steps_between(points, max_rise, max_drop):
    result = [list(p) for p in points]
    for _ in range(6):
        for i in range(1, len(result) - 1):
            delta = result[i][1] - result[i - 1][1]
            result[i][1] = result[i - 1][1] + min(max_rise, max(-max_drop, delta))
        for i in range(len(result) - 2, 0, -1):
            lower = result[i + 1][1] - max_rise
            upper = result[i + 1][1] + max_drop
            result[i][1] = min(upper, max(lower, result[i][1]))
    return result


def _yaw_z(points, i):
    before = points[max(0, i - 1)]
    after = points[min(len(points) - 1, i + 1)]
    return math.degrees(math.atan2(after[0] - before[0], after[2] - before[2]))


def _yaw_x(points, i):
    before = points[max(0, i - 1)]
    after = points[min(len(points) - 1, i + 1)]
    return math.degrees(math.atan2(-(after[2] - before[2]), after[0] - before[0]))


def _rotated_height_vector(height, yaw, pitch, roll):
    yaw, pitch, roll = map(math.radians, (yaw, pitch, roll))
    return [height * (-math.cos(yaw) * math.sin(roll)
                      + math.sin(yaw) * math.sin(pitch) * math.cos(roll)),
            height * math.cos(pitch) * math.cos(roll),
            height * (math.sin(yaw) * math.sin(roll)
                      + math.cos(yaw) * math.sin(pitch) * math.cos(roll))]


def _surface(data, name):
    return next(row for row in data["surfaces"] if row["name"] == name)


def _numbered_rows(data, prefix):
    rows = [row for row in data["surfaces"]
            if row["name"].startswith(prefix)
            and row["name"][len(prefix):].isdigit()]
    return sorted(rows, key=lambda row: int(row["name"][len(prefix):]))


def _replace_links(data, removed_names, chains):
    data["links"][:] = [edge for edge in data["links"]
                        if not any(name in removed_names for name in edge)]
    for chain in chains:
        data["links"].extend([[a, b] for a, b in zip(chain, chain[1:])])


def _asset_landing(data, assets, name, asset_id, p, size, yaw, section,
                   pitch=0.0, roll=0.0):
    dimensions = assets[asset_id]["dimensionsRobloxXYZ"]
    top_offset = _rotated_height_vector(dimensions[1], yaw, pitch, roll)
    placement = dict(asset=asset_id, name=name,
                     p=[p[0] - top_offset[0], p[1] - top_offset[1],
                        p[2] - top_offset[2]],
                     scale=[size[0] / dimensions[0], 1.0,
                            size[2] / dimensions[2]],
                     yaw=yaw, section=section)
    surface = dict(name=name, p=list(p), size=list(size), yaw=yaw,
                   section=section)
    if pitch:
        placement["pitch"] = surface["pitch"] = pitch
    if roll:
        placement["roll"] = surface["roll"] = roll
    data["placements"].append(placement)
    data["surfaces"].append(surface)


def _crumble_landing(data, assets, name, p, size, yaw, section):
    asset_id = "SC_R_CrumbleStone26"
    dimensions = assets[asset_id]["dimensionsRobloxXYZ"]
    skirt = 12.5
    data["placements"].append(dict(
        asset=asset_id, name=name,
        p=[p[0], p[1] - skirt, p[2]],
        scale=[size[0] / dimensions[0], skirt / dimensions[1],
               size[2] / dimensions[2]],
        yaw=yaw, section="S03"))
    data["surfaces"].append(dict(name=name, p=list(p), size=list(size),
                                 yaw=yaw, section=section))


def _set_path(data, key, points):
    data["paths"][key] = [list(point) for point in points]


def _refine_ribs(data, assets):
    old_rows = _numbered_rows(data, "Rib")
    old_names = {row["name"] for row in old_rows}
    old_points = [list(row["p"]) for row in old_rows]
    start = _surface(data, "R2_Boarding")
    end = _surface(data, "R3_Stern")
    start_edge = _edge_toward(start["p"], start["size"], old_points[0])
    end_edge = _edge_toward(end["p"], end["size"], old_points[-1])
    sampled = _resample([start_edge] + old_points + [end_edge],
                        spacing=7.8, margin=4.8, alternating=0.32)
    profile = _limit_vertical_steps([start_edge] + _stagger(sampled, 0.62)
                                    + [end_edge], max_rise=2.55, max_drop=2.8)
    route = profile[1:-1]

    data["surfaces"][:] = [row for row in data["surfaces"]
                           if row["name"] not in old_names]
    data["placements"][:] = [row for row in data["placements"]
                             if row["name"] not in old_names
                             and not row["name"].startswith("RibTimber28_")]
    data["placements"][:] = [row for row in data["placements"]
                             if not (row["section"] == "X01"
                                     and row["asset"] == "SC_DockPost")]

    names = []
    size = [1.45, 0.62, 1.2]
    for i, point in enumerate(route):
        name = f"Rib{i:02d}"
        names.append(name)
        heading = _yaw_x(route, i)
        data["placements"].append(dict(
            asset="SC_PlayableRib", name=name,
            p=[point[0], point[1] - 18.6, point[2] - 6.36],
            scale=[0.53, 1.0, 0.53], yaw=-90, section="X01"))
        data["surfaces"].append(dict(name=name, p=list(point), size=list(size),
                                     yaw=heading, section="X01"))
        data["placements"].append(dict(
            asset="SC_DockPost", name=f"RibTimber29_{i:02d}",
            p=[point[0] + (0.38 if i % 2 else -0.38), point[1] - 8.0, point[2]],
            scale=[0.48, 0.72, 0.48], yaw=0, section="X01"))

    _replace_links(data, old_names, [["R2_Boarding"] + names + ["R3_Stern"]])
    _set_path(data, "X01", [data["checkpoints"][2]] + route
              + [data["checkpoints"][3]])
    data["testRoutes"]["expert_ribs"] = ["R2_Boarding"] + names + ["R3_Stern"]
    return names


def _add_cliff_alternates(data, assets, route, names):
    center_x = sum(point[0] for point in route) / len(route)
    center_z = sum(point[2] for point in route) / len(route)
    dimensions = assets["SC_R_CrumbleStone26"]["dimensionsRobloxXYZ"]
    alternates = {}

    for anchor_index in range(1, len(route) - 1, 2):
        before, after = route[anchor_index - 1], route[anchor_index + 1]
        dx, dz = after[0] - before[0], after[2] - before[2]
        length = math.hypot(dx, dz)
        if length == 0:
            continue
        nx, nz = -dz / length, dx / length
        toward_center = (center_x - route[anchor_index][0],
                         center_z - route[anchor_index][2])
        if nx * toward_center[0] + nz * toward_center[1] < 0:
            nx, nz = -nx, -nz

        point = [route[anchor_index][0] + nx * 5.4,
                 route[anchor_index][1] + (0.65 if anchor_index % 4 == 1 else -0.65),
                 route[anchor_index][2] + nz * 5.4]
        name = f"CliffPass29_{anchor_index:02d}"
        size = [5.2, 1.0, 4.8]
        yaw = _yaw_z(route, anchor_index)
        skirt = 12.5
        data["placements"].append(dict(
            asset="SC_R_CrumbleStone26", name=name,
            p=[point[0], point[1] - skirt, point[2]],
            scale=[size[0] / dimensions[0], skirt / dimensions[1],
                   size[2] / dimensions[2]],
            yaw=yaw, section="S03"))
        data["surfaces"].append(dict(name=name, p=point, size=size,
                                     section="S03", yaw=yaw))
        alternates[anchor_index] = name

    chains = []
    alternate_route = ["R3_Stern", names[0]]
    for anchor_index, name in sorted(alternates.items()):
        chains.append([names[anchor_index - 1], name, names[anchor_index + 1]])
        alternate_route.extend([name, names[anchor_index + 1]])
    if alternate_route[-1] != names[-1]:
        alternate_route.append(names[-1])
    alternate_route.append("R4_CaveEntry")
    _set_path(data, "S03_Pass", [_surface(data, name)["p"]
                                 for name in alternate_route])
    return alternate_route, chains


def _refine_cliffs(data, assets):
    old_rows = _numbered_rows(data, "S03_")
    old_names = {row["name"] for row in old_rows}
    old_alternates = {row["name"] for row in data["surfaces"]
                      if row["name"].startswith(("CliffPass28_", "CliffPass29_"))}
    old_points = [list(row["p"]) for row in old_rows]
    start = _surface(data, "R3_Stern")
    end = _surface(data, "R4_CaveEntry")
    start_edge = _edge_toward(start["p"], start["size"], old_points[0])
    end_edge = _edge_toward(end["p"], end["size"], old_points[-1])
    sampled = _resample([start_edge] + old_points + [end_edge],
                        spacing=7.7, margin=5.4)
    profile = _limit_vertical_steps_between([start_edge] + sampled + [end_edge],
                                            max_rise=1.8, max_drop=2.65)
    route = profile[1:-1]
    oriented_path = [start_edge] + route + [end_edge]

    remove_names = old_names | old_alternates
    data["surfaces"][:] = [row for row in data["surfaces"]
                           if row["name"] not in remove_names]
    data["placements"][:] = [row for row in data["placements"]
                             if row["name"] not in remove_names]
    data["crumble"] = [name for name in data["crumble"] if name not in remove_names]
    data["placements"][:] = [row for row in data["placements"]
                             if not (row["name"].startswith("CliffShoulder27_")
                                     or row["name"].startswith("CliffGrowthShelf")
                                     or row["name"] == "ArchSlopeJoin")]

    names = []
    for i, point in enumerate(route):
        name = f"S03_{i:02d}"
        names.append(name)
        width, depth = 5.2, 4.2
        yaw = _yaw_z(oriented_path, i + 1)
        skirt = 12.5 + (i % 3) * 0.5
        _crumble_landing(data, assets, name, point, [width, 1.0, depth],
                         yaw, "S03")
        placement = next(row for row in data["placements"]
                         if row["name"] == name)
        placement["p"][1] = point[1] - skirt
        placement["scale"][1] = skirt / assets["SC_R_CrumbleStone26"]["dimensionsRobloxXYZ"][1]
        if i % 5 == 4:
            data["crumble"].append(name)

    alternate_route, alternate_chains = _add_cliff_alternates(data, assets,
                                                               route, names)
    main_chain = ["R3_Stern"] + names + ["R4_CaveEntry"]
    _replace_links(data, remove_names, [main_chain] + alternate_chains)
    _set_path(data, "S03", route)
    data["testRoutes"]["cliffs"] = main_chain
    data["testRoutes"]["cliff_pass"] = alternate_route

    for hazard in data["hazards"]:
        if not hazard["name"].startswith(("CliffSweep", "CliffDanger")):
            continue
        point = min(route, key=lambda candidate: _distance_xz(candidate, hazard["p"]))
        hazard["p"] = [point[0], point[1] + 0.48, point[2]]
        hazard["size"] = [2.8, 0.65, 0.65] if "Sweep" in hazard["name"] else [3.0, 0.7, 0.8]
        hazard["amplitude"] = 0.65 if "Sweep" in hazard["name"] else 0
        hazard["axis"] = "X"
        hazard["section"] = "S03"

    return names, alternate_route


def _add_spar_support_frame(data, assets, index, p, yaw, surface_size):
    post = assets["SC_DockPost"]
    beam = assets["SC_TimberBeam"]
    post_dimensions = post["dimensionsRobloxXYZ"]
    beam_dimensions = beam["dimensionsRobloxXYZ"]
    cap_bottom = p[1] - surface_size[1]
    beam_bottom = cap_bottom - beam_dimensions[1]
    base_y = -10.0
    support_height = beam_bottom - base_y
    segments = max(1, math.ceil(support_height / (post_dimensions[1] * 2)))
    segment_height = support_height / segments
    post_scale = 0.48
    post_offset = surface_size[2] / 2 - post_dimensions[0] * post_scale / 2
    yaw_radians = math.radians(yaw)

    data["placements"].append(dict(
        asset="SC_TimberBeam", name=f"SparSupportBeam29_{index:02d}",
        p=[p[0], beam_bottom, p[2]],
        scale=[(surface_size[2] + 0.5) / beam_dimensions[0], 1.0, 1.0],
        yaw=yaw + 90, section="X02"))
    for side in (-1, 1):
        x = p[0] + math.sin(yaw_radians) * post_offset * side
        z = p[2] + math.cos(yaw_radians) * post_offset * side
        for segment in range(segments):
            bottom = base_y + segment * segment_height
            data["placements"].append(dict(
                asset="SC_DockPost",
                name=f"SparSupportPost29_{index:02d}_{side}_{segment:02d}",
                p=[x, bottom, z],
                scale=[post_scale, segment_height / post_dimensions[1], post_scale],
                yaw=yaw, section="X02"))


def _refine_spars(data, assets):
    old_rows = _numbered_rows(data, "Spar")
    old_names = {row["name"] for row in old_rows}
    route = [list(row["p"]) for row in old_rows]
    route = _stagger(route, 0.9)
    for i, point in enumerate(route):
        point[1] += 0.22 * math.sin(i * 1.7)

    start = _surface(data, "R3_Stern")
    end = _surface(data, "R4_CaveEntry")
    start_edge = _edge_toward(start["p"], start["size"], route[0])
    end_edge = _edge_toward(end["p"], end["size"], route[-1])
    profile = _limit_vertical_steps([start_edge] + route + [end_edge],
                                    max_rise=1.8, max_drop=3.1)
    route = profile[1:-1]

    data["surfaces"][:] = [row for row in data["surfaces"]
                           if row["name"] not in old_names]
    data["placements"][:] = [row for row in data["placements"]
                             if row["name"] not in old_names
                             and not row["name"].startswith(("SparSupportBeam28_",
                                                             "SparSupportPost28_",
                                                             "SparSupportBeam29_",
                                                             "SparSupportPost29_"))]

    names = []
    surface_size = [3.2, 1.88, 1.25]
    for i, point in enumerate(route):
        name = f"Spar{i:02d}"
        names.append(name)
        heading = _yaw_x(route, i)
        yaw = heading + (24 if i % 2 else -24)
        pitch = 6 if i % 2 else -6
        roll = 22 if i % 2 else -22
        _asset_landing(data, assets, name, "SC_BrokenSpar", point,
                       surface_size, yaw, "X02", pitch=pitch, roll=roll)
        _add_spar_support_frame(data, assets, i, point, yaw, surface_size)

    chain = ["R3_Stern"] + names + ["R4_CaveEntry"]
    _replace_links(data, old_names, [chain])
    _set_path(data, "X02", [data["checkpoints"][3]] + route
              + [data["checkpoints"][4]])
    data["testRoutes"]["expert_spars"] = chain
    return names


def apply(data, assets):
    """Mutate a loaded layout28 dict; this pass never runs an earlier route pass."""
    ribs = _refine_ribs(data, assets)
    cliffs, cliff_pass = _refine_cliffs(data, assets)
    spars = _refine_spars(data, assets)

    data["testRoutes"]["expert_ribs"] = ["R2_Boarding"] + ribs + ["R3_Stern"]
    data["testRoutes"]["cliffs"] = ["R3_Stern"] + cliffs + ["R4_CaveEntry"]
    data["testRoutes"]["cliff_pass"] = cliff_pass
    data["testRoutes"]["expert_spars"] = ["R3_Stern"] + spars + ["R4_CaveEntry"]
    resource = dict(data.get("resource", {}))
    resource.update(
        visuals=len(data["placements"]),
        visualTriangles=sum(assets[row["asset"]]["triangles"]
                            for row in data["placements"]),
        colliders=len(data["surfaces"]))
    data["resource"] = resource
    return data
