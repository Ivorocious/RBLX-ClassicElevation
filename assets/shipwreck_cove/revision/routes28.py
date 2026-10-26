"""In-memory route layout refinement for an already loaded SC_MAP_27 layout."""
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


def _resample(points, spacing, margin=0):
    points = [list(p) for p in points]
    cumulative = [0.0]
    for a, b in zip(points, points[1:]):
        cumulative.append(cumulative[-1] + _distance_xz(a, b))
    total = cumulative[-1]
    usable = max(0.0, total - 2 * margin)
    steps = max(1, math.ceil(usable / spacing))
    return [_polyline_at(points, cumulative, margin + usable * i / steps)
            for i in range(steps + 1)]


def _stagger(points, amount):
    result = [list(p) for p in points]
    for i in range(1, len(result) - 1):
        before, after = result[i - 1], result[i + 1]
        dx, dz = after[0] - before[0], after[2] - before[2]
        length = math.hypot(dx, dz)
        if length == 0:
            continue
        offset = amount * (1 if i % 2 else -1) * math.sin(math.pi * i / (len(result) - 1))
        result[i][0] -= dz / length * offset
        result[i][2] += dx / length * offset
    return result


def _vary_height(points, amplitude, max_rise):
    result = [list(p) for p in points]
    for i, p in enumerate(result):
        p[1] += amplitude * math.sin(i * 1.37)
        if i and p[1] > result[i - 1][1] + max_rise:
            p[1] = result[i - 1][1] + max_rise
    return result


def _yaw_z(points, i):
    before = points[max(0, i - 1)]
    after = points[min(len(points) - 1, i + 1)]
    return math.degrees(math.atan2(after[0] - before[0], after[2] - before[2]))


def _yaw_x(points, i):
    before = points[max(0, i - 1)]
    after = points[min(len(points) - 1, i + 1)]
    return math.degrees(math.atan2(-(after[2] - before[2]), after[0] - before[0]))


def _asset_landing(data, assets, name, asset_id, p, size, yaw, section):
    asset = assets[asset_id]
    dimensions = asset["dimensionsRobloxXYZ"]
    scale = [size[0] / dimensions[0], 1.0, size[2] / dimensions[2]]
    placement = dict(asset=asset_id, name=name,
                     p=[p[0], p[1] - dimensions[1], p[2]],
                     scale=scale, yaw=yaw, section=section)
    data["placements"].append(placement)
    data["surfaces"].append(dict(name=name, p=list(p), size=list(size),
                                 yaw=yaw, section=section))


def _crumble_landing(data, assets, name, p, size, yaw, section):
    asset = assets["SC_R_CrumbleStone26"]
    dimensions = asset["dimensionsRobloxXYZ"]
    bed = -4.0
    data["placements"].append(dict(
        asset="SC_R_CrumbleStone26", name=name, p=[p[0], bed, p[2]],
        scale=[size[0] / dimensions[0], (p[1] - bed) / dimensions[1],
               size[2] / dimensions[2]], yaw=yaw, section=section))
    data["surfaces"].append(dict(name=name, p=list(p), size=list(size),
                                 yaw=yaw, section=section))


def _replace_chain(data, old_names, chain):
    data["links"][:] = [edge for edge in data["links"]
                        if edge[0] not in old_names and edge[1] not in old_names]
    data["links"].extend([[a, b] for a, b in zip(chain, chain[1:])])


def _remove_named(rows, names):
    rows[:] = [row for row in rows if row.get("name") not in names]


def _surface(data, name):
    return next(row for row in data["surfaces"] if row["name"] == name)


def _resize_refuge(data, assets, name, depth):
    surface = _surface(data, name)
    surface["size"][2] = depth
    placement = next(row for row in data["placements"] if row["name"] == name)
    placement["scale"][2] = depth / assets[placement["asset"]]["dimensionsRobloxXYZ"][2]


def _dock_row_bounds(data, row_index):
    names = (f"DockCluster{row_index}_",)
    rows = [s for s in data["surfaces"] if s["section"] == "S01"
            and (s["name"].startswith(names) or s["name"] == f"S01_{row_index:02d}")]
    if not rows:
        raise ValueError(f"no dock surfaces found for row {row_index}")
    bounds = []
    for s in rows:
        half_x = (abs(math.cos(math.radians(s.get("yaw", 0)))) * s["size"][0]
                  + abs(math.sin(math.radians(s.get("yaw", 0)))) * s["size"][2]) / 2
        bounds.extend((s["p"][0] - half_x, s["p"][0] + half_x))
    return min(bounds), max(bounds)


def _refine_red_cargo(data):
    for hazard in data["hazards"]:
        if not hazard["name"].startswith("RedCargo"):
            continue
        suffix = hazard["name"][len("RedCargo"):].split("_", 1)[0]
        if not suffix.isdigit():
            continue
        row_index = int(suffix)
        min_x, max_x = _dock_row_bounds(data, row_index)
        hazard["p"][0] = (min_x + max_x) / 2
        hazard["axis"] = "X"
        hazard["amplitude"] = max(0.0, (max_x - min_x - hazard["size"][0]) / 2)


def _refine_dock_and_battery(data, assets):
    _resize_refuge(data, assets, "R1_Refuge", 16.0)
    _resize_refuge(data, assets, "R2_Boarding", 10.0)


def _refine_wreck(data, assets):
    old_names = {s["name"] for s in data["surfaces"]
                 if s["section"] == "S02" and s["name"].startswith("S02_")}
    old_nodes = sorted((s for s in data["surfaces"] if s["name"] in old_names),
                       key=lambda s: int(s["name"].split("_")[-1]))
    old_points = [list(s["p"]) for s in old_nodes]
    start = _surface(data, "R2_Boarding")
    end = _surface(data, "R3_Stern")
    start_edge = _edge_toward(start["p"], start["size"], old_points[0])
    end_edge = _edge_toward(end["p"], end["size"], old_points[-1])
    route = _resample([start_edge] + old_points + [end_edge], 7.3, margin=5.8)
    route = _vary_height(_stagger(route, 0.8), 0.22, 2.7)

    obstacle_surfaces = [s for s in data["surfaces"]
                         if s["name"].startswith("WreckObstacle27_")]
    obstacle_names = {s["name"] for s in obstacle_surfaces}
    for obstacle in obstacle_surfaces:
        placement = next((p for p in data["placements"]
                          if p["name"] == obstacle["name"]), None)
        if placement is None:
            continue
        anchor_index = min(range(len(route)),
                           key=lambda j: _distance_xz(route[j], obstacle["p"]))
        anchor = route[anchor_index]
        yaw = math.radians(_yaw_z(route, anchor_index))
        nx, nz = math.cos(yaw), -math.sin(yaw)
        dx, dz = obstacle["p"][0] - anchor[0], obstacle["p"][2] - anchor[2]
        side = 1 if dx * nx + dz * nz >= 0 else -1
        placement["p"][0] = anchor[0] + nx * side * 6.5
        placement["p"][2] = anchor[2] + nz * side * 6.5

    _remove_named(data["surfaces"], obstacle_names)
    data["links"][:] = [edge for edge in data["links"]
                        if edge[0] not in obstacle_names and edge[1] not in obstacle_names]

    _remove_named(data["surfaces"], old_names)
    _remove_named(data["placements"], old_names)
    names = []
    plank_size = [4.2, 1.0, 3.8]
    for i, p in enumerate(route):
        name = f"WreckPlank28_{i:02d}"
        names.append(name)
        _asset_landing(data, assets, name, "SC_ShipDeck", p, plank_size,
                       _yaw_z(route, i), "S02")

    _replace_chain(data, old_names, ["R2_Boarding"] + names + ["R3_Stern"])
    data["paths"]["S02"] = [list(p) for p in route]

    for hazard in data["hazards"][:]:
        if hazard["name"].startswith("DeckBurn"):
            data["hazards"].remove(hazard)
    kill_indices = [max(1, round((len(route) - 1) * f)) for f in (0.24, 0.5, 0.76)]
    for i, node_index in enumerate(kill_indices):
        p = route[node_index]
        data["hazards"].append(dict(name=f"WreckKill28_{i}", p=[p[0], p[1] + 0.42, p[2]],
                                    size=[2.8, 0.8, 0.8], section="S02", kind="static",
                                    period=4, amplitude=0, axis="X", phase=0))

    moving = [h for h in data["hazards"] if h["name"].startswith(("ShipSweep", "WreckSweep27"))]
    for i, hazard in enumerate(moving):
        node_index = round((len(route) - 1) * (i + 1) / (len(moving) + 1))
        p = route[node_index]
        hazard["p"] = [p[0], p[1] + 0.5, p[2]]
        hazard["size"] = [2.8, 0.65, 0.65]
        hazard["amplitude"] = 0.65
        hazard["section"] = "S02"

    return names


def _refine_ribs(data, assets):
    old_rows = sorted((s for s in data["surfaces"] if s["name"].startswith("Rib")),
                      key=lambda s: int(s["name"][3:]))
    old_names = {s["name"] for s in old_rows}
    old_points = [list(s["p"]) for s in old_rows]
    start = _surface(data, "R2_Boarding")
    end = _surface(data, "R3_Stern")
    first_anchor = [-88.0, 15.5, -66.5]
    start_edge = _edge_toward(start["p"], start["size"], first_anchor)
    end_edge = _edge_toward(end["p"], end["size"], old_points[13])
    skeleton = [start_edge, first_anchor] + old_points[3:14] + [end_edge]
    route = _resample(skeleton, 8.1, margin=7.4)
    route = _vary_height(route, 0.2, 2.8)

    _remove_named(data["surfaces"], old_names)
    _remove_named(data["placements"], old_names)
    data["placements"][:] = [p for p in data["placements"]
                              if not (p["section"] == "X01" and p["asset"] == "SC_DockPost")]
    names = []
    for i, p in enumerate(route):
        name = f"Rib{i:02d}"
        names.append(name)
        data["placements"].append(dict(asset="SC_PlayableRib", name=name,
                                       p=[p[0], p[1] - 18.6, p[2] - 12 * 0.53],
                                       scale=[0.53, 1, 0.53], yaw=-90, section="X01"))
        data["surfaces"].append(dict(name=name, p=list(p), size=[1.75, 0.6, 1.65],
                                     yaw=0, section="X01"))
        data["placements"].append(dict(asset="SC_DockPost", name=f"RibTimber28_{i:02d}",
                                       p=[p[0] + (0.45 if i % 2 else -0.45), p[1] - 8.0, p[2]],
                                       scale=[0.55, 0.8, 0.55], yaw=0, section="X01"))

    _replace_chain(data, old_names, ["R2_Boarding"] + names + ["R3_Stern"])
    data["paths"]["X01"] = [list(data["checkpoints"][2])] + [list(p) for p in route] + [list(data["checkpoints"][3])]
    return names


def _add_cliff_alternates(data, assets, route, names):
    center_x = sum(p[0] for p in route) / len(route)
    center_z = sum(p[2] for p in route) / len(route)
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

        rise = 1.4 if (anchor_index // 2) % 2 == 0 else -1.4
        p = [route[anchor_index][0] + nx * 6.5,
             route[anchor_index][1] + rise,
             route[anchor_index][2] + nz * 6.5]
        name = f"CliffPass28_{anchor_index:02d}"
        width, depth, skirt = 4.2, 4.0, 12.5
        yaw = _yaw_z(route, anchor_index)
        data["placements"].append(dict(
            asset="SC_R_CrumbleStone26", name=name,
            p=[p[0], p[1] - skirt, p[2]],
            scale=[width / dimensions[0], skirt / dimensions[1],
                   depth / dimensions[2]],
            yaw=yaw, section="S03"))
        data["surfaces"].append(dict(name=name, p=p, size=[width, 1, depth],
                                     section="S03", yaw=yaw))
        alternates[anchor_index] = name
        data["links"].extend([[names[anchor_index - 1], name],
                              [name, names[anchor_index + 1]]])

    alternate_route = ["R3_Stern", names[0]]
    for anchor_index, name in sorted(alternates.items()):
        alternate_route.extend([name, names[anchor_index + 1]])
    alternate_route.extend([names[-1], "R4_CaveEntry"])
    data["paths"]["S03_Pass"] = [list(_surface(data, name)["p"])
                                  for name in alternate_route]
    return alternate_route


def _refine_cliffs(data, assets):
    old_rows = sorted((s for s in data["surfaces"] if s["name"].startswith("S03_")),
                      key=lambda s: int(s["name"].split("_")[-1]))
    old_names = {s["name"] for s in old_rows}
    old_points = [list(s["p"]) for s in old_rows]
    start_point = list(old_points[1])
    start_point[0] = 18.5
    route = _resample([start_point] + old_points[2:24], 7.45)
    route = _vary_height(_stagger(route, 0.3), 0.3, 2.6)

    _remove_named(data["surfaces"], old_names)
    _remove_named(data["placements"], old_names)
    data["crumble"] = [name for name in data["crumble"] if name not in old_names]

    names = []
    for i, p in enumerate(route):
        name = f"S03_{i:02d}"
        names.append(name)
        width, depth = (4.6, 4.2) if i % 4 == 3 else (4.3, 4.0)
        yaw = _yaw_z(route, i)
        skirt = 12.5 + (i % 3) * 0.9
        asset = assets["SC_R_CrumbleStone26"]
        dimensions = asset["dimensionsRobloxXYZ"]
        data["placements"].append(dict(
            asset="SC_R_CrumbleStone26", name=name,
            p=[p[0], p[1] - skirt, p[2]],
            scale=[width / dimensions[0], skirt / dimensions[1], depth / dimensions[2]],
            yaw=yaw, section="S03"))
        data["surfaces"].append(dict(name=name, p=list(p), size=[width, 1, depth],
                                     section="S03", yaw=yaw))
        if i % 4 != 3:
            data["crumble"].append(name)

    _replace_chain(data, old_names, ["R3_Stern"] + names + ["R4_CaveEntry"])
    data["paths"]["S03"] = [list(p) for p in route]
    for hazard in data["hazards"]:
        if hazard["name"].startswith(("CliffSweep", "CliffDanger")):
            p = min(route, key=lambda candidate: _distance_xz(candidate, hazard["p"]))
            hazard["p"] = [p[0], p[1] + 0.48, p[2]]
            hazard["size"] = [2.8, 0.65, 0.65] if "Sweep" in hazard["name"] else [3.0, 0.7, 0.8]
            hazard["amplitude"] = 0.65 if "Sweep" in hazard["name"] else 0
            hazard["axis"] = "X"
            hazard["section"] = "S03"
    alternate_route = _add_cliff_alternates(data, assets, route, names)
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
        asset="SC_TimberBeam", name=f"SparSupportBeam28_{index:02d}",
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
                name=f"SparSupportPost28_{index:02d}_{side}_{segment:02d}",
                p=[x, bottom, z],
                scale=[post_scale, segment_height / post_dimensions[1], post_scale],
                yaw=yaw, section="X02"))


def _refine_spars(data, assets):
    old_rows = sorted((s for s in data["surfaces"] if s["name"].startswith("Spar")),
                      key=lambda s: int(s["name"][4:]))
    old_names = {s["name"] for s in old_rows}
    route = [list(s["p"]) for s in old_rows]
    route = _vary_height(route, 0.18, 2.8)

    _remove_named(data["surfaces"], old_names)
    _remove_named(data["placements"], old_names)
    data["placements"][:] = [p for p in data["placements"]
                              if not (p["section"] == "X02" and p["asset"] == "SC_DockPost")]
    names = []
    for i, p in enumerate(route):
        name = f"Spar{i:02d}"
        names.append(name)
        heading = _yaw_x(route, i)
        angle = 30 if i % 2 else -30
        yaw = heading + angle
        surface_size = [4.0, 1.88, 1.75]
        _asset_landing(data, assets, name, "SC_BrokenSpar", p, surface_size, yaw, "X02")
        _add_spar_support_frame(data, assets, i, p, yaw, surface_size)

    _replace_chain(data, old_names, ["R3_Stern"] + names + ["R4_CaveEntry"])
    data["paths"]["X02"] = [list(data["checkpoints"][3])] + [list(p) for p in route] + [list(data["checkpoints"][4])]
    return names


def _add_cave_entry(data, assets):
    entry_pads = [
        ("CaveEntryNearSide28", [101.0, 13.5, -2.0], [2.2, 1.0, 3.0]),
        ("CaveEntryNear28_00", [113.0, 14.0, 2.0], [3.0, 1.0, 3.0]),
    ]
    names = []
    for name, p, size in entry_pads:
        names.append(name)
        _crumble_landing(data, assets, name, p, size, 0, "S04_Entry")

    branch = ["R4_CaveEntry", names[0], "Cave26Stone00", names[1], "Cave26Stone01"]
    data["links"].extend([[a, b] for a, b in zip(branch, branch[1:])
                          if [a, b] not in data["links"]])
    data["paths"]["S04_NearEntry28"] = [
        list(_surface(data, name)["p"]) for name in branch]
    return ["R4_CaveEntry"] + [f"Cave26Stone{i:02d}" for i in range(7)] + ["SurgeEastRefuge"], branch


def apply(data, assets):
    """Mutate and return a loaded layout27 data dict; assets is keyed by asset id."""
    _refine_dock_and_battery(data, assets)
    _refine_red_cargo(data)
    wreck = _refine_wreck(data, assets)
    ribs = _refine_ribs(data, assets)
    cliffs, cliff_pass = _refine_cliffs(data, assets)
    spars = _refine_spars(data, assets)
    cave, cave_entry_branch = _add_cave_entry(data, assets)

    data["testRoutes"] = {
        "dock": ["HarborAssembly"] + [f"S01_{i:02d}" for i in range(6)] + ["R1_Refuge"],
        "battery": ["R1_Refuge", "BatteryDeck0", "BatteryDeck1", "BatteryDeck2",
                    "BatteryDeck3", "R2_Boarding"],
        "main_wreck": ["R2_Boarding"] + wreck + ["R3_Stern"],
        "expert_ribs": ["R2_Boarding"] + ribs + ["R3_Stern"],
        "cliffs": ["R3_Stern"] + cliffs + ["R4_CaveEntry"],
        "cliff_pass": cliff_pass,
        "expert_spars": ["R3_Stern"] + spars + ["R4_CaveEntry"],
        "cave": cave,
        "cave_entry_branch": cave_entry_branch,
    }
    data["resource"] = dict(
        visuals=len(data["placements"]),
        visualTriangles=sum(assets[p["asset"]]["triangles"] for p in data["placements"]),
        colliders=len(data["surfaces"]),
    )
    return data
