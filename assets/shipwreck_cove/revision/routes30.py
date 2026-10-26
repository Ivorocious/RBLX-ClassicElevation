"""Route-only refinement applied to the frozen SC_MAP_29 layout."""
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
    distances = [size[0] / (2 * abs(ux)) if abs(ux) > 1e-9 else math.inf,
                 size[2] / (2 * abs(uz)) if abs(uz) > 1e-9 else math.inf]
    radius = min(distances)
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


def _asset_landing(data, assets, name, asset_id, point, size, yaw, section,
                   pitch=0.0, roll=0.0):
    dimensions = assets[asset_id]["dimensionsRobloxXYZ"]
    top_offset = _rotated_height_vector(dimensions[1], yaw, pitch, roll)
    placement = dict(asset=asset_id, name=name,
                     p=[point[0] - top_offset[0], point[1] - top_offset[1],
                        point[2] - top_offset[2]],
                     scale=[size[0] / dimensions[0], 1.0,
                            size[2] / dimensions[2]],
                     yaw=yaw, section=section)
    surface = dict(name=name, p=list(point), size=list(size), yaw=yaw,
                   section=section)
    if pitch:
        placement["pitch"] = surface["pitch"] = pitch
    if roll:
        placement["roll"] = surface["roll"] = roll
    data["placements"].append(placement)
    data["surfaces"].append(surface)


def _refine_ribs(data, assets):
    old_rows = _numbered_rows(data, "Rib")
    old_names = {row["name"] for row in old_rows}
    old_points = [list(row["p"]) for row in old_rows]
    start = _surface(data, "R2_Boarding")
    end = _surface(data, "R3_Stern")
    start_edge = _edge_toward(start["p"], start["size"], old_points[0])
    end_edge = _edge_toward(end["p"], end["size"], old_points[-1])
    sampled = _resample([start_edge] + old_points + [end_edge],
                        spacing=8.0, margin=4.8, alternating=0.45)
    profile = _limit_vertical_steps([start_edge] + _stagger(sampled, 0.65)
                                    + [end_edge], max_rise=2.2, max_drop=2.7)
    route = profile[1:-1]

    data["surfaces"][:] = [row for row in data["surfaces"]
                           if row["name"] not in old_names]
    data["placements"][:] = [row for row in data["placements"]
                             if row["name"] not in old_names
                             and not row["name"].startswith(("RibTimber28_",
                                                             "RibTimber29_",
                                                             "RibStringer30_"))]

    names = []
    cap = assets["SC_PlayableRib"]["colliders"][0]
    cap_center, cap_dimensions = cap["center"], cap["size"]
    for i, point in enumerate(route):
        rib_scale = [0.53, 0.63 + 0.1 * (i % 3), 0.53]
        size = [cap_dimensions[k] * rib_scale[k] for k in range(3)]
        name = f"Rib{i:02d}"
        names.append(name)
        heading = _yaw_x(route, i)
        yaw_radians = math.radians(heading)
        local_cap_x = cap_center[0] * rib_scale[0]
        local_cap_z = cap_center[2] * rib_scale[2]
        root_to_cap_x = local_cap_x * math.cos(yaw_radians) + local_cap_z * math.sin(yaw_radians)
        root_to_cap_z = -local_cap_x * math.sin(yaw_radians) + local_cap_z * math.cos(yaw_radians)
        data["placements"].append(dict(
            asset="SC_PlayableRib", name=name,
            p=[point[0] - root_to_cap_x,
               point[1] - (cap_center[1] * rib_scale[1]
                           + cap_dimensions[1] * rib_scale[1] / 2),
               point[2] - root_to_cap_z],
            scale=rib_scale, yaw=heading, section="X01"))
        data["surfaces"].append(dict(name=name, p=list(point), size=list(size),
                                     yaw=heading, section="X01"))

    beam_dimensions = assets["SC_TimberBeam"]["dimensionsRobloxXYZ"]
    for i, (a, b) in enumerate(zip(route, route[1:])):
        if i % 4 == 2:
            continue
        length = _distance_xz(a, b)
        yaw = _yaw_x([a, b], 0)
        roll = math.degrees(math.atan2(b[1] - a[1], length))
        data["placements"].append(dict(
            asset="SC_TimberBeam", name=f"RibStringer30_{i:02d}",
            p=[(a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 7.5,
               (a[2] + b[2]) / 2],
            scale=[length / beam_dimensions[0], 0.7, 0.7],
            yaw=yaw, roll=roll, section="X01"))

    for i in (1, 4, 7, 10, 13):
        p = route[i]
        a = [p[0] - 2, p[1] - 5.5, p[2]]
        b = [p[0] - 2.8, p[1] - 8.5, -80]
        horizontal = _distance_xz(a, b)
        length = math.sqrt(horizontal ** 2 + (b[1] - a[1]) ** 2)
        data['placements'].append(dict(asset='SC_TimberBeam',name=f'RibHullTie30_{i:02d}',
            p=[(a[k]+b[k])/2 for k in range(3)],
            scale=[length/beam_dimensions[0],.3,.3],yaw=_yaw_x([a,b],0),
            roll=math.degrees(math.atan2(b[1]-a[1],horizontal)),section='X01'))

    chain = ["R2_Boarding"] + names + ["R3_Stern"]
    _replace_links(data, old_names, [chain])
    data["paths"]["X01"] = [data["checkpoints"][2]] + route + [data["checkpoints"][3]]
    data["testRoutes"]["expert_ribs"] = chain
    data['crumble'] = list(dict.fromkeys(data['crumble'] + ['Rib03','Rib07','Rib11']))
    return names


def _refine_cliff_route(data, assets):
    main_rows = _numbered_rows(data, "S03_")
    main_names = [row["name"] for row in main_rows]
    pass_rows = [row for row in data["surfaces"]
                 if row["name"].startswith("CliffPass29_")
                 and row["name"][len("CliffPass29_"):].isdigit()]
    pass_rows.sort(key=lambda row: int(row["name"].split("_")[-1]))
    pass_names = [row["name"] for row in pass_rows]

    # These were visual-only plants or rock caps close enough to resemble route ledges.
    obsolete_placements = {
        "CliffGrowth1", "CliffGrowth4", "CliffGrowth6", "CliffGrowth9",
        "DockPost_111", "DockPost_112", "DockPost_117", "DockPost_118",
        "R_SeaRockSpire_271", "R_SeaRockSpire_272", "R_SeaRockSpire_276",
    }
    route_names = set(main_names) | set(pass_names)
    _replace_links(data, route_names, [])
    main_chain = ["R3_Stern"] + main_names + ["R4_CaveEntry"]
    pass_chain = ["R3_Stern", main_names[0]]
    alternate_chains = []
    for alternate in pass_rows:
        index = int(alternate["name"].split("_")[-1])
        before, after = main_names[index - 1], main_names[index + 1]
        alternate_chains.append([before, alternate["name"], after])
        pass_chain.extend([alternate["name"], after])
    pass_chain.append("R4_CaveEntry")
    _replace_links(data, set(), [main_chain] + alternate_chains)

    data["placements"][:] = [row for row in data["placements"]
                             if row["name"] not in obsolete_placements]
    headland = next(row for row in data["placements"]
                    if row["name"] == "ConnectedHeadland")
    headland["asset"] = "SC_Headland30"

    placements = {row['name']: row for row in data['placements']}
    for i, surface in enumerate(main_rows + pass_rows):
        asset_id = 'SC_CliffLedge30' + 'AC'[i % 2]
        asset = assets[asset_id]
        height = asset['topYRoblox']
        surface['size'][1] = 0.3
        placement = placements[surface['name']]
        placement.update(asset=asset_id,
            p=[surface['p'][0], surface['p'][1] - height, surface['p'][2]],
            scale=[surface['size'][0] / asset['dimensionsRobloxXYZ'][0], 1,
                   surface['size'][2] / asset['dimensionsRobloxXYZ'][2]],
            yaw=surface['yaw'])

    data["paths"]["S03"] = [list(row["p"]) for row in main_rows]
    data["paths"]["S03_Pass"] = [_surface(data, name)["p"] for name in pass_chain]
    data["testRoutes"]["cliffs"] = main_chain
    data["testRoutes"]["cliff_pass"] = pass_chain


def _add_spar_support_frame(data, assets, index, point, yaw, pitch, roll, size):
    post_dimensions = assets["SC_DockPost"]["dimensionsRobloxXYZ"]
    beam_dimensions = assets["SC_TimberBeam"]["dimensionsRobloxXYZ"]
    underside_y = point[1] - _rotated_height_vector(size[1], yaw, pitch, roll)[1]
    beam_bottom = underside_y - beam_dimensions[1]
    base_y = -10.0
    support_height = beam_bottom - base_y
    segments = max(1, math.ceil(support_height / (post_dimensions[1] * 2)))
    segment_height = support_height / segments
    post_scale = 0.48
    post_offset = size[2] / 2 - post_dimensions[0] * post_scale / 2
    yaw_radians = math.radians(yaw)

    data["placements"].append(dict(
        asset="SC_TimberBeam", name=f"SparSupportBeam30_{index:02d}",
        p=[point[0], beam_bottom, point[2]],
        scale=[(size[2] + 0.5) / beam_dimensions[0], 1.0, 1.0],
        yaw=yaw + 90, section="X02"))
    for side in (-1, 1):
        x = point[0] + math.sin(yaw_radians) * post_offset * side
        z = point[2] + math.cos(yaw_radians) * post_offset * side
        for segment in range(segments):
            bottom = base_y + segment * segment_height
            data["placements"].append(dict(
                asset="SC_DockPost",
                name=f"SparSupportPost30_{index:02d}_{side}_{segment:02d}",
                p=[x, bottom, z],
                scale=[post_scale, segment_height / post_dimensions[1], post_scale],
                yaw=yaw, section="X02"))


def _refine_spars(data, assets):
    old_rows = _numbered_rows(data, "Spar")
    old_names = {row["name"] for row in old_rows}
    route = [list(row["p"]) for row in old_rows]
    height_offsets = [1.25, -1.25, 1.25, -1.25, 1.25, -1.25,
                      1.25, -1.25, 1.25, -0.35, 0.8]
    if len(height_offsets) != len(route):
        raise ValueError("frozen spar route no longer matches route30 tuning")
    for point, offset in zip(route, height_offsets):
        point[1] += offset

    start = _surface(data, "R3_Stern")
    end = _surface(data, "R4_CaveEntry")
    start_edge = _edge_toward(start["p"], start["size"], route[0])
    end_edge = _edge_toward(end["p"], end["size"], route[-1])
    profile = _limit_vertical_steps([start_edge] + route + [end_edge],
                                    max_rise=2.2, max_drop=6.0)
    route = profile[1:-1]

    data["surfaces"][:] = [row for row in data["surfaces"]
                           if row["name"] not in old_names]
    data["placements"][:] = [row for row in data["placements"]
                             if row["name"] not in old_names
                             and not row["name"].startswith(("SparSupportBeam28_",
                                                             "SparSupportPost28_",
                                                             "SparSupportBeam29_",
                                                             "SparSupportPost29_",
                                                             "SparSupportBeam30_",
                                                             "SparSupportPost30_"))]

    names = []
    size = [3.2, 1.88, 1.25]
    for i, point in enumerate(route):
        name = f"Spar{i:02d}"
        names.append(name)
        heading = _yaw_x(route, i)
        yaw_offset = 30 if i % 2 else -30
        pitch = 14 if i % 2 else -14
        roll = 30 if i % 2 else -30
        yaw = heading + yaw_offset
        _asset_landing(data, assets, name, "SC_BrokenSpar", point,
                       size, yaw, "X02", pitch=pitch, roll=roll)
        _add_spar_support_frame(data, assets, i, point, yaw, pitch, roll, size)

    chain = ["R3_Stern"] + names + ["R4_CaveEntry"]
    _replace_links(data, old_names, [chain])
    _set_crumble = {"Spar02", "Spar05", "Spar08"}
    data["crumble"] = [name for name in data["crumble"]
                        if name not in old_names and not name.startswith("SparSupport")]
    data["crumble"] = list(dict.fromkeys(data["crumble"] + sorted(_set_crumble)))
    data["paths"]["X02"] = [data["checkpoints"][3]] + route + [data["checkpoints"][4]]
    data["testRoutes"]["expert_spars"] = chain
    return names


def apply(data, assets):
    """Refine only the ribs, cliff routes, and expert spars from frozen layout29."""
    _refine_ribs(data, assets)
    _refine_cliff_route(data, assets)
    _refine_spars(data, assets)

    resource = dict(data.get("resource", {}))
    resource.update(
        visuals=len(data["placements"]),
        visualTriangles=sum(assets[row["asset"]]["triangles"]
                            for row in data["placements"]),
        colliders=len(data["surfaces"]))
    data["resource"] = resource
    return data
