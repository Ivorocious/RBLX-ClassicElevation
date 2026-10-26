"""Add a Gothic architecture extension to a candidate copy of accepted BL02.

Run only in a separate Blender background process. Importing this module does
not change the scene. build_library() only creates its requested edit units.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time
import types

import bmesh
import bpy
from mathutils import Vector


HERE = Path(__file__).resolve().parent
ASSET_ROOT = HERE.parents[1]
ACCEPTED = ASSET_ROOT / "bl02"
PHASE3 = HERE.parent
BUILD = "MC_P3_WORLD_KIT_C01"
COLLECTION = "MC_P3_WORLD_KIT"
MAX_LIBRARY_TRIANGLES = 26000
MAX_ASSET_TRIANGLES = 7000
MAX_EXPORT_PARTS = 40


def load_architecture():
    path = ACCEPTED / "architecture.py"
    module = types.ModuleType("mc_p3_accepted_bl02_architecture")
    module.__file__ = str(path)
    exec(compile(path.read_text(encoding="utf-8"), str(path), "exec"), module.__dict__)
    return module


def materials(architecture):
    result = architecture._materials()
    for key, rgb in {"Leaf": (68, 94, 67), "LeafDark": (35, 57, 48),
                     "Soil": (55, 49, 42), "Floor": (149, 164, 178)}.items():
        prefix = "MC_P3_" if key in {"LeafDark", "Soil"} else "MC_BL02_"
        material = bpy.data.materials.get(prefix + key)
        if material is None:
            material = bpy.data.materials.new(prefix + key)
            material.use_nodes = True
            rgba = tuple(architecture._linear(c) for c in rgb) + (1.0,)
            material.diffuse_color = rgba
            shader = material.node_tree.nodes.get("Principled BSDF")
            shader.inputs["Base Color"].default_value = rgba
            shader.inputs["Roughness"].default_value = 0.85
            material["PaletteRGB"] = list(rgb)
        result[key] = material
    return result


def box_proxy(center, size):
    return {"low": [a - b / 2 for a, b in zip(center, size)],
            "high": [a + b / 2 for a, b in zip(center, size)]}


def arch_path(architecture, width, height, base=0, samples=12):
    outline = architecture._pointed(width, height, base, samples)
    return outline[1:] + [outline[0]]


def arch_band(geometry, architecture, outer_width, outer_height,
              inner_width, inner_height, front, back, color="Stone",
              base=0, inner_base=0, samples=12):
    outer = arch_path(architecture, outer_width, outer_height, base, samples)
    inner = arch_path(architecture, inner_width, inner_height, inner_base, samples)
    geometry.arc_strip(outer, inner, front, back, color)
    proxies = []
    for i in range(len(outer) - 1):
        points = [outer[i], outer[i + 1], inner[i], inner[i + 1]]
        proxies.append({"low": [min(p[0] for p in points), front, min(p[1] for p in points)],
                        "high": [max(p[0] for p in points), back, max(p[1] for p in points)]})
    return proxies


def fluted_column(geometry, center, height, radius, color="Stone"):
    geometry.profile([(0, radius * 1.22), (.35, radius * 1.22),
                      (.65, radius), (height - .75, radius),
                      (height - .45, radius * 1.28), (height, radius * 1.28)],
                     sides=8, color=color, center=center)
    for side in (-1, 1):
        geometry.profile([(0, radius * .28), (height - .5, radius * .28)], sides=6,
                         color="StoneLight", center=(center[0] + side * radius * .68,
                                                     center[1] - radius * .72, center[2]))


def open_gateway(architecture):
    g = architecture._Mesh()
    proxies = arch_band(g, architecture, 27.4, 23, 18, 20, -1.8, 1.8, samples=16)
    for proxy in proxies:
        proxy["low"][1] = -2.20
    arch_band(g, architecture, 26.6, 22.55, 25.1, 21.85, -2.12, -1.72,
              "StoneLight", samples=16)
    arch_band(g, architecture, 20.05, 20.8, 18.55, 20.05, -2.05, -1.7,
              "StoneDark", samples=16)
    for side in (-1, 1):
        fluted_column(g, (side * 10.45, -1.94, 0), 12.55, .74)
        g.box((side * 11.85, 0, .42), (3.6, 4.45, .84), "StoneLight")
        proxies.append(box_proxy((side * 11.85, -.30, 6.3), (4.9, 5.15, 12.6)))
    for i in (3, 7, 11, 15, 19, 23, 27, 31):
        outer = arch_path(architecture, 26.25, 22.2, samples=16)
        inner = arch_path(architecture, 20.1, 20.8, samples=16)
        a, b = outer[i], inner[i]
        g.tube([(a[0], -2.14, a[1]), (b[0], -2.14, b[1])], .042, "StoneDark", sides=4)
    return g, proxies


def gallery_arcade(architecture):
    g = architecture._Mesh()
    proxies = arch_band(g, architecture, 24, 18.5, 20, 16.8, -1.35, 1.25, samples=12)
    arch_band(g, architecture, 23.2, 18.15, 21.75, 17.3, -1.68, -1.3,
              "StoneLight", samples=12)
    for side in (-1, 1):
        fluted_column(g, (side * 11.18, -1.38, 0), 11.3, .50)
        g.box((side * 11.10, .12, .4), (1.8, 3.2, .8), "StoneLight")
        proxies.append(box_proxy((side * 11.10, -.45, 5.7), (1.8, 3.7, 11.4)))
    for proxy in proxies:
        proxy["low"][1] = min(proxy["low"][1], -1.85)
    # The quatrefoil is high in the spandrel, outside the broad passage.
    outer, inner = [], []
    for i in range(24):
        angle = math.tau * i / 24
        radius = .68 * (1 + .17 * math.cos(4 * angle))
        outer.append((radius * math.cos(angle), 17.87 + radius * math.sin(angle)))
        inner.append((.70 * radius * math.cos(angle), 17.87 + .70 * radius * math.sin(angle)))
    g.ring(outer, inner, -1.83, -1.65, "StoneLight")
    proxies.append(box_proxy((0, -1.73, 17.87), (1.7, .2, 1.7)))
    return g, proxies


def vault_ribs(architecture):
    g = architecture._Mesh()
    proxies = []
    for y in (-8.15, 8.15):
        points = arch_path(architecture, 22.8, 7.4, samples=12)
        path = [(x, y, z) for x, z in points]
        g.tube(path, .28, "StoneLight", sides=6)
        proxies.extend(box_proxy(tuple((a[k] + b[k]) / 2 for k in range(3)),
                                 tuple(abs(a[k] - b[k]) + .58 for k in range(3)))
                       for a, b in zip(path, path[1:]))
    for side in (-1, 1):
        path = [(-11 + 22 * i / 24, side * (-7.8 + 15.6 * i / 24),
                 7.5 * math.sin(math.pi * i / 24)) for i in range(25)]
        g.tube(path, .23, "Stone", sides=6)
        proxies.extend(box_proxy(tuple((a[k] + b[k]) / 2 for k in range(3)),
                                 tuple(abs(a[k] - b[k]) + .48 for k in range(3)))
                       for a, b in zip(path, path[1:]))
    g.profile([(7.10, .7), (7.30, .94), (7.70, .7)], sides=8, color="StoneLight")
    proxies.append(box_proxy((0, 0, 7.4), (1.9, 1.9, .65)))
    return g, proxies


def flying_buttress(architecture):
    g = architecture._Mesh()
    # A curved load-bearing rib meets a stepped outer pier, leaving the space below open.
    outer = [(16 * i / 20, 29 - 7 * (i / 20) ** 1.35) for i in range(21)]
    inner = [(x, z - 2.5) for x, z in outer]
    g.arc_strip(outer, inner, -1.25, 1.25, "Stone")
    g.arc_strip([(x, z + .13) for x, z in outer],
                [(x, z - .32) for x, z in outer], -1.5, -1.19, "StoneLight")
    g.profile([(0, 2.05), (.5, 2.05), (.85, 1.60),
               (10, 1.60), (10.5, 1.38), (21.5, 1.38),
               (22, 1.8), (22.65, 1.8), (23, 1.35), (29.5, .92),
               (30.5, .92), (31, .72), (34, .12)],
              sides=8, color="Stone", center=(17, 0, 0))
    for z, radius in ((.55, 2.10), (10.25, 1.65), (22.3, 1.86), (30, 1.00)):
        g.profile([(z - .18, radius), (z + .18, radius)], sides=8,
                  color="StoneLight", center=(17, 0, 0))
    proxies = [box_proxy((17, 0, 11.6), (4.3, 4.3, 23.2)),
               box_proxy((17, 0, 28.5), (2.2, 2.2, 11))]
    for i in range(len(outer) - 1):
        points = [outer[i], outer[i + 1], inner[i], inner[i + 1]]
        proxies.append({"low": [min(p[0] for p in points), -1.5, min(p[1] for p in points)],
                        "high": [max(p[0] for p in points), 1.25, max(p[1] for p in points)]})
    return g, proxies


def terrace_fascia(architecture):
    g = architecture._Mesh()
    g.prism([(-12, 0), (12, 0), (12, -.7), (11.55, -1.35),
             (11.55, -2.15), (-11.55, -2.15), (-11.55, -1.35), (-12, -.7)],
            -.7, .7, "StoneLight")
    g.box((0, .18, -2.58), (23.1, 1.35, .85), "Stone")
    for x in (-9, -3, 3, 9):
        # Sloped corbels have a narrow foot and a broad capital beneath the deck.
        profile = [(x - 2, -2.92), (x + 2, -2.92), (x + 1.6, -3.6),
                   (x + .75, -7.8), (x - .75, -7.8), (x - 1.6, -3.6)]
        g.prism(profile, -.25, 1.25, "Stone")
        g.box((x, .45, -3.22), (4.25, 1.75, .48), "StoneDark")
    proxies = [box_proxy((0, .1, -1.5), (24, 1.6, 3))]
    proxies.extend(box_proxy((x, .5, -5.5), (4.3, 1.8, 5.4)) for x in (-9, -3, 3, 9))
    return g, proxies


def parapet(architecture):
    g = architecture._Mesh()
    g.prism([(-12, 0), (12, 0), (12, .40), (11.75, .62),
             (11.75, 1.35), (-11.75, 1.35), (-11.75, .62), (-12, .40)],
            -.85, .85, "Stone")
    g.box((0, 0, 1.46), (24, 1.95, .22), "StoneLight")
    proxies = [box_proxy((0, 0, .8), (24, 2, 1.6))]
    for x in (-10.3, -5.15, 0, 5.15, 10.3):
        g.prism([(x - 1.3, 1.55), (x + 1.3, 1.55), (x + 1.3, 3.13),
                 (x + 1.02, 3.48), (x - 1.02, 3.48), (x - 1.3, 3.13)],
                -.77, .77, "Stone")
        g.box((x, 0, 3.49), (2.84, 2, .20), "StoneLight")
        g.ring(architecture._pointed(1.0, 1.40, 1.75, samples=6),
               architecture._pointed(.62, 1.10, 1.88, samples=6),
               -.83, -.76, "StoneDark")
        # Move the relief independently, avoiding a full facade solid.
        count = 4 * len(architecture._pointed(1.0, 1.40, 1.75, samples=6))
        g.vertices[-count:] = [(a + x, b, c) for a, b, c in g.vertices[-count:]]
        proxies.append(box_proxy((x, 0, 2.6), (2.9, 2, 2.2)))
    return g, proxies


def slate_gable(architecture):
    g = architecture._Mesh()
    # A steep roof with an exported slate profile, broad seam bands and stone gable edges.
    outline = [(-12, 0), (-11.6, .4), (-8.4, 3.3), (-4.4, 6.7),
               (-.12, 10), (.12, 10), (4.4, 6.7), (8.4, 3.3), (11.6, .4), (12, 0)]
    g.prism(outline, -9, 9, "Slate")
    for y in (-9.12, 9.02):
        left = [(-12.2, -.08), (-11.9, .50), (-8.7, 3.6), (-4.7, 7.0), (-.25, 10.15)]
        right = [(x + .55, z - .23) for x, z in left]
        g.arc_strip(left, right, y, y + .10, "StoneLight")
        g.arc_strip([(-x, z) for x, z in left], [(-x, z) for x, z in right],
                    y, y + .10, "StoneLight")
    for x, z in ((9.55, 2.26), (6.43, 5.03), (2.7, 8.06)):
        for side in (-1, 1):
            g.tube([(side * x, -9.06, z), (side * x, 9.06, z)],
                   .055, "SlateBand", sides=4)
    g.tube([(0, -9.15, 10.10), (0, 9.15, 10.10)], .14, "SlateBand", sides=6)
    return g, [box_proxy((0, 0, 5.1), (24.5, 18.4, 10.5))]


def crown_screen(architecture):
    g = architecture._Mesh()
    g.box((0, .15, .55), (24, 1.65, 1.1), "StoneLight")
    proxies = [box_proxy((0, .15, .55), (24, 1.65, 1.1))]
    for x in (-8, 0, 8):
        child = architecture._Mesh()
        local = arch_band(child, architecture, 7.2, 11.8, 5.85, 10.8,
                          -.35, .45, "Stone", base=1, inner_base=1, samples=10)
        arch_band(child, architecture, 6.8, 11.45, 6.35, 11.10,
                  -.58, -.30, "StoneLight", base=1.1, inner_base=1.12, samples=10)
        child.tube([(a, -.69, b) for a, b in arch_path(architecture, 5.1, 8.1, 1.5, 8)],
                   .09, "Iron", sides=6)
        child.box((0, -.56, 4.6), (.13, .20, 6.2), "Brass")
        g.transformed(child, offset=(x, 0, 0))
        for proxy in local:
            proxies.append({"low": [proxy["low"][0] + x, proxy["low"][1], proxy["low"][2]],
                            "high": [proxy["high"][0] + x, proxy["high"][1], proxy["high"][2]]})
        iron_path = [(a + x, -.69, b) for a, b in arch_path(architecture, 5.1, 8.1, 1.5, 8)]
        proxies.extend(box_proxy(tuple((a[k] + b[k]) / 2 for k in range(3)),
                                 tuple(abs(a[k] - b[k]) + .20 for k in range(3)))
                       for a, b in zip(iron_path, iron_path[1:]))
        proxies.append(box_proxy((x, -.56, 4.6), (.14, .22, 6.2)))
    return g, proxies


def plant_pocket(architecture):
    g = architecture._Mesh()
    # Four tapered rim solids leave a real inset soil pocket.
    g.box((0, 0, .24), (7.8, 4.8, .48), "StoneDark")
    for side in (-1, 1):
        g.prism([(side * 3.45, .40), (side * 4.0, .40),
                 (side * 4.0, 1.25), (side * 3.35, 1.1)], -2.5, 2.5, "Stone")
        g.box((0, side * 2.28, .82), (6.7, .45, .82), "Stone")
    g.box((0, 0, .91), (6.65, 4.0, .10), "Soil")
    for i, (x, y) in enumerate(((-2.4, .8), (-1.1, -.7), (.5, .9), (2.2, -.5))):
        radius = .84 + .11 * (i % 2)
        g.profile([(1, radius * .68), (1.48, radius), (2.5, radius * .5), (3.1, .08)],
                  sides=6, color="Leaf" if i % 2 else "LeafDark", center=(x, y, 0))
    return g, [box_proxy((0, 0, 1.55), (8.05, 5.05, 3.15))]


def cypress(architecture):
    g = architecture._Mesh()
    g.profile([(0, .32), (10.6, .2)], sides=6, color="Soil")
    for i in range(5):
        bottom = 1.5 + i * 2.12
        radius = 2.5 - i * .35
        # Uneven octagonal foliage shells keep a distinct dark planted silhouette.
        rings = [(bottom, radius * .45), (bottom + .45, radius),
                 (bottom + 2.3, radius * .42), (bottom + 3.7, .06)]
        g.profile(rings, sides=8, color="LeafDark" if i % 2 else "Leaf",
                  center=(.08 * math.sin(i * 2), .11 * math.cos(i * 2), 0))
    return g, [box_proxy((0, 0, 7.0), (5.3, 5.3, 14.1))]


def build_library(destination):
    architecture = load_architecture()
    palette = materials(architecture)
    recipes = [
        ("MC_P3_GatewayStone", open_gateway, .035,
         "Base Z0; front-Y; open18-wide doorway,20-high apex,no threshold; gateway passage,not a jump contact."),
        ("MC_P3_GalleryArcadeStone", gallery_arcade, .025,
         "Base Z0;24-wide open bay; backdrop/frontage outside route; no floor or blocking insert."),
        ("MC_P3_VaultRibs", vault_ribs, 0,
         "Springline Z0; overhead ribs rise7.8; place springline above jump/camera ceiling,at least deck+18.2."),
        ("MC_P3_FlyingButtress", flying_buttress, .025,
         "Ground mount Z0; inner attachment X0/Z29; outer grounded pier X17; reverse by rotation,not negative scale."),
        ("MC_P3_TerraceFascia", terrace_fascia, .025,
         "Mount at deck top Z0; all geometry below deck;24-wide outward fascia,never a walking surface."),
        ("MC_P3_Parapet", parapet, .025,
         "Base Z0;24-long boundary; keep outside native contact; separate native blockers if needed."),
        ("MC_P3_SlateGable", slate_gable, 0,
         "Roof eave Z0;24x18 footprint;10.3 rise; scenery only,above movement/camera clearance."),
        ("MC_P3_CrownScreen", crown_screen, .015,
         "Base Z0; three open lancets,24-long screen; outside crown arrival lane; no floor."),
        ("MC_P3_PlantPocket", plant_pocket, .02,
         "Base Z0;8x5 planted basin; place outside route,not on takeoff or catch; no light."),
        ("MC_P3_Cypress", cypress, 0,
         "Base Z0; grouped14-high dark tree; place behind boundary,avoid forward/reverse sightlines."),
    ]
    objects, proxies = [], {}
    for key, recipe, bevel, notes in recipes:
        assert bpy.data.objects.get(key) is None, "Existing P3 unit must be preserved: " + key
        geometry, occupied = recipe(architecture)
        assert len(geometry.faces) == len(geometry.colors) == len(geometry.smooth)
        assert all(0 <= index < len(geometry.vertices) for face in geometry.faces for index in face)
        assert all(len(set(face)) == len(face) >= 3 for face in geometry.faces)
        obj = architecture._object(destination, key, geometry, palette, bevel, notes)
        obj["Build"] = BUILD
        obj["Role"] = "Noncolliding world decoration"
        proxies[key] = occupied
        objects.append(obj)
    return objects, proxies


def face_islands(bm):
    unseen, islands = set(bm.faces), []
    while unseen:
        seed = unseen.pop()
        island, pending = {seed}, [seed]
        while pending:
            face = pending.pop()
            for edge in face.edges:
                for neighbor in edge.link_faces:
                    if neighbor in unseen:
                        unseen.remove(neighbor)
                        island.add(neighbor)
                        pending.append(neighbor)
        islands.append(island)
    return islands


def clean_and_check(mesh, asset_name):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    # Keep the accepted export's pointed-tip cleanup; do not weld unrelated solid islands.
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    assert not any(not edge.is_manifold for edge in bm.edges), (asset_name, "open or nonmanifold source")
    islands = face_islands(bm)
    volumes = []
    for island in islands:
        volume = 0
        for face in island:
            first = face.verts[0].co
            for i in range(1, len(face.verts) - 1):
                volume += first.dot(face.verts[i].co.cross(face.verts[i + 1].co)) / 6
        if volume < 0:
            bmesh.ops.reverse_faces(bm, faces=list(island))
            volume = -volume
        assert volume > 1e-10, (asset_name, "flat source island")
        volumes.append(volume)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update(calc_edges=True)
    mesh.calc_loop_triangles()
    assert len(mesh.vertices) and len(mesh.polygons), (asset_name, "empty mesh")
    assert all(math.isfinite(c) for vertex in mesh.vertices for c in vertex.co), (asset_name, "nonfinite coordinate")
    assert all(t.area > 1e-12 for t in mesh.loop_triangles), (asset_name, "degenerate triangle")
    assert all(0 <= p.material_index < len(mesh.materials) for p in mesh.polygons), (asset_name, "material index")
    assert all(material is not None for material in mesh.materials), (asset_name, "missing material")
    assert all(0 <= index < len(mesh.vertices) for t in mesh.loop_triangles for index in t.vertices), (asset_name, "vertex index")
    low = [min(v.co[axis] for v in mesh.vertices) for axis in range(3)]
    high = [max(v.co[axis] for v in mesh.vertices) for axis in range(3)]
    size = [high[i] - low[i] for i in range(3)]
    assert all(.01 < value < limit for value, limit in zip(size, (40, 30, 40))), (asset_name, "unexpected dimensions", size)
    assert len(mesh.loop_triangles) <= MAX_ASSET_TRIANGLES, (asset_name, "asset triangle budget")
    return {"vertices": len(mesh.vertices), "triangles": len(mesh.loop_triangles),
            "boundary_edges": 0, "nonmanifold_edges": 0, "zero_area_triangles": 0,
            "closed_islands": len(islands), "minimum_island_volume": min(volumes),
            "signed_volume": sum(volumes), "outward_island_winding": True,
            "bounds": [low, high]}


def srgb(value):
    value = max(0, min(1, value))
    return round(255 * (12.92 * value if value <= .0031308 else 1.055 * value ** (1 / 2.4) - .055))


def export_units(objects, destination, occupied):
    graph = bpy.context.evaluated_depsgraph_get()
    assets, parts = [], []
    for obj in objects:
        evaluated = obj.evaluated_get(graph)
        baked = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=graph)
        record = clean_and_check(baked, obj.name)
        assets.append({"asset": obj.name, "bounds": record.pop("bounds"), "geometry": record,
                       "origin": [0, 0, 0], "role": obj["Role"], "mounting_notes": obj["MountingNotes"],
                       "occupied_boxes_blender": occupied[obj.name],
                       "proxy_boundary": "Occupied structure only; hollow arch passages are excluded. Decoration remains noncolliding."})
        for slot, material in enumerate(baked.materials):
            if not any(p.material_index == slot for p in baked.polygons):
                continue
            subset = baked.copy()
            bm = bmesh.new()
            bm.from_mesh(subset)
            bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != slot], context="FACES")
            loose = [v for v in bm.verts if not v.link_faces]
            if loose:
                bmesh.ops.delete(bm, geom=loose, context="VERTS")
            for face in bm.faces:
                face.material_index = 0
            bm.to_mesh(subset)
            bm.free()
            subset.materials.clear()
            subset.materials.append(material)
            subset.update(calc_edges=True)
            subset.calc_loop_triangles()
            assert all(triangle.area > 1e-12 for triangle in subset.loop_triangles), (obj.name, material.name)
            key = material.name.removeprefix("MC_BL02_").removeprefix("MC_P3_")
            name = obj.name + "__" + key
            part = bpy.data.objects.new(name, subset)
            destination.objects.link(part)
            part["AssetKey"], part["Build"] = obj.name, BUILD
            low = [min(v.co[axis] for v in subset.vertices) for axis in range(3)]
            high = [max(v.co[axis] for v in subset.vertices) for axis in range(3)]
            center = [(a + b) / 2 for a, b in zip(low, high)]
            size = [b - a for a, b in zip(low, high)]
            parts.append({"name": name, "asset": obj.name, "material": key,
                          "rgb": [srgb(c) for c in material.diffuse_color[:3]],
                          "center": center, "size": size,
                          "roblox_center": [center[0], center[2], -center[1]],
                          "roblox_size": [size[0], size[2], size[1]], "triangles": len(subset.loop_triangles)})
        bpy.data.meshes.remove(baked)
    assert len(parts) <= MAX_EXPORT_PARTS, "Material-part budget exceeded"
    assert sum(p["triangles"] for p in parts) <= MAX_LIBRARY_TRIANGLES, "Library triangle budget exceeded"
    return assets, parts


def linked_place(source, destination, asset, name, point, scale=(1, 1, 1), yaw=0):
    obj = source[asset].copy()
    obj.data = source[asset].data
    obj.name = name
    destination.objects.link(obj)
    obj.location, obj.scale, obj.rotation_euler.z = point, scale, yaw
    return obj


def compose_specimen(new_objects, destination):
    source = {obj.name: obj for obj in new_objects}
    for name in ("MC_FloorStone", "MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass",
                 "MC_TurretStone", "MC_TurretAmber", "MC_SlateSpire", "MC_Banner", "MC_Ivy"):
        obj = bpy.data.objects.get(name)
        assert obj and obj.type == "MESH", "Accepted source missing: " + name
        source[name] = obj
    place = lambda key, name, point, scale=(1, 1, 1), yaw=0: linked_place(source, destination, key, name, point, scale, yaw)
    place("MC_FloorStone", "Specimen_Deck", (0, 0, 0), (48 / 18, 30 / 12, 1))
    place("MC_P3_GatewayStone", "Specimen_EntryGateway", (-24, 0, 0), yaw=math.pi / 2)
    for x in (-12, 12):
        place("MC_P3_GalleryArcadeStone", "Specimen_Arcade" + str(x), (x, 15, 0))
        place("MC_P3_VaultRibs", "Specimen_Ribs" + str(x), (x, 5, 18.6))
        place("MC_P3_SlateGable", "Specimen_Roof" + str(x), (x, 5, 26.7))
        place("MC_P3_TerraceFascia", "Specimen_Fascia" + str(x), (x, -15, 0))
        place("MC_P3_Parapet", "Specimen_Parapet" + str(x), (x, -16.15, 0))
    for x in (-24, 24):
        place("MC_TurretStone", "Specimen_Turret" + str(x), (x, 18.6, 0), (.72, .72, .72))
        place("MC_TurretAmber", "Specimen_TurretAmber" + str(x), (x, 18.6, 0), (.72, .72, .72))
        place("MC_SlateSpire", "Specimen_Spire" + str(x), (x, 18.6, 20.16), (.72, .72, .72))
        place("MC_Banner", "Specimen_Banner" + str(x), (x, 15.95, 13.3), (.85, .85, .85))
        place("MC_Ivy", "Specimen_Ivy" + str(x), (x + (2.2 if x < 0 else -2.2), 15.75, 1), (.85, .85, .85))
    for key in ("MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"):
        place(key, "Specimen_Hero" + key, (0, 21.3, 0), (.72, .72, .72))
    place("MC_P3_FlyingButtress", "Specimen_GroundedButtress", (23, 19, -8), yaw=math.pi / 2)
    place("MC_P3_PlantPocket", "Specimen_PlantedPocket", (20, 10.3, 0))
    place("MC_P3_Cypress", "Specimen_Cypress", (24, 30, -1))
    place("MC_P3_CrownScreen", "Specimen_CrownScreen", (39, 5, 0), yaw=math.pi / 2)
    # Static 5.3-stud figures give scale; the specimen has no gameplay collision or timing proof.
    architecture = load_architecture()
    palette = materials(architecture)
    for i, (x, y) in enumerate(((-16, 0), (1, -4), (17, 1))):
        g = architecture._Mesh()
        g.box((x, y, 3.1), (1.6, .9, 1.9), "StoneLight")
        g.box((x, y, 4.7), (1.2, 1.05, 1.2), "StoneLight")
        for side in (-1, 1):
            g.box((x + side * 1.1, y, 3.1), (.55, .85, 1.85), "StoneLight")
            g.box((x + side * .45, y, 1.04), (.7, .8, 2.08), "StoneLight")
        architecture._object(destination, "Specimen_ScaleFigure" + str(i), g, palette, .04,
                             "Static scale reference only")


def daylight_render(destination, output):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1536, 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world = bpy.data.worlds.new("MC_P3_SpecimenDaylight")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.48, .54, .64, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .7
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.exposure = .7
    for name, point, power, size in (("MC_P3_Daylight", (-35, -40, 65), 100000, 45),
                                     ("MC_P3_Fill", (40, 20, 48), 70000, 35)):
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.shape, data.size = power, "DISK", size
        obj = bpy.data.objects.new(name, data)
        destination.objects.link(obj)
        obj.location = point
        obj.rotation_euler = (Vector((0, 8, 14)) - obj.location).to_track_quat("-Z", "Y").to_euler()
    camera = bpy.data.cameras.new("MC_P3_SpecimenCamera")
    obj = bpy.data.objects.new(camera.name, camera)
    destination.objects.link(obj)
    scene.camera = obj
    views = [("world-specimen-daylight", (70, -73, 47), (0, 8, 14), 40),
             ("world-specimen-player", (-35, -8, 5.5), (7, 13, 10), 24)]
    for name, point, aim, focal in views:
        obj.location = point
        obj.rotation_euler = (Vector(aim) - obj.location).to_track_quat("-Z", "Y").to_euler()
        camera.lens = focal
        scene.render.filepath = str(output / (name + ".png"))
        bpy.ops.render.render(write_still=True)
    return [name + ".png" for name, *_ in views]


def new_collection(name, parent):
    assert bpy.data.collections.get(name) is None, "Existing collection must be preserved: " + name
    result = bpy.data.collections.new(name)
    parent.children.link(result)
    return result


def main():
    global BUILD
    assert bpy.app.background, "Run in a separate background process; never load/reset the live Blender editor"
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-blend", type=Path, default=ACCEPTED / "MC_BL02_sample.blend")
    parser.add_argument("--output", type=Path, default=PHASE3 / "candidate01")
    parser.add_argument("--skip-render", action="store_true")
    options = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    source, output = options.source_blend.resolve(), options.output.resolve()
    assert source.is_file() and source.suffix == ".blend", "Missing source blend"
    number = output.name.removeprefix("candidate")
    assert output.parent == PHASE3.resolve() and number.isdigit(), "Use a new Phase3 candidateNN directory"
    BUILD = "MC_P3_WORLD_KIT_C" + number
    assert not any((output / name).exists() for name in ("MC_P3_WORLD_KIT.blend", "MC_P3_WORLD_KIT.fbx", "manifest.json")), "Preserve existing candidate; use a fresh output directory"
    started = time.perf_counter()
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    # Only the isolated loaded copy is hidden; source collections and source files remain intact.
    for existing in bpy.context.scene.collection.children:
        existing.hide_render = True
        existing.hide_viewport = True
    root = new_collection(COLLECTION, bpy.context.scene.collection)
    authored = new_collection("MC_P3_AUTHOR_EDIT_UNITS", root)
    exported = new_collection("MC_P3_EXPORT_MATERIAL_UNITS", root)
    specimen = new_collection("MC_P3_GATEWAY_GALLERY_SPECIMEN", root)
    preview = new_collection("MC_P3_DAYLIGHT_PREVIEW", root)
    objects, occupied = build_library(authored)
    bpy.context.view_layer.update()
    assets, parts = export_units(objects, exported, occupied)
    compose_specimen(objects, specimen)
    authored.hide_render, exported.hide_render = True, True
    authored.hide_viewport, exported.hide_viewport = True, True
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    # Hidden author/export collections are temporarily shown for selection/export.
    exported.hide_viewport = False
    for obj in exported.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(output / "MC_P3_WORLD_KIT.fbx"), use_selection=True,
                             object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             use_mesh_modifiers=True, bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
    exported.hide_viewport = True
    manifest = {"candidate": BUILD, "blender": bpy.app.version_string,
                "units": "1 unit=1 intended stud", "axes": "X right,Z up,front-Y; Roblox center=(X,Z,-Y)",
                "collection": COLLECTION, "source_blend": str(source), "source_blend_sha256": source_hash,
                "source_boundary": "Accepted BL02 is loaded into an isolated copy,not rebuilt or exported. New-only FBX.",
                "presentation": "Daylight gateway/gallery specimen; static art,not a course assembly or gameplay proof.",
                "runtime_boundary": "All art noncolliding,anchored,query/touch off; native contacts/blockers remain authoritative.",
                "assets": assets, "export_parts": parts, "asset_count": len(assets), "part_count": len(parts),
                "export_triangles": sum(p["triangles"] for p in parts),
                "budget": {"library_triangles": MAX_LIBRARY_TRIANGLES, "asset_triangles": MAX_ASSET_TRIANGLES,
                           "export_parts": MAX_EXPORT_PARTS},
                "build_seconds_before_render": round(time.perf_counter() - started, 3)}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    images = [] if options.skip_render else daylight_render(preview, output)
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.shading.type = "MATERIAL"
                area.spaces.active.region_3d.view_location = (0, 8, 12)
                area.spaces.active.region_3d.view_distance = 100
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "MC_P3_WORLD_KIT.blend"))
    assert hashlib.sha256(source.read_bytes()).hexdigest() == source_hash, "Source preservation check"
    files = ["MC_P3_WORLD_KIT.blend", "MC_P3_WORLD_KIT.fbx", "manifest.json"] + images
    receipt = {"candidate": BUILD, "source_preserved": True,
               "elapsed_seconds": round(time.perf_counter() - started, 3),
               "files": {name: {"bytes": (output / name).stat().st_size,
                                  "sha256": hashlib.sha256((output / name).read_bytes()).hexdigest()}
                         for name in files}}
    (output / "build_receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print("MC_P3_WORLD_KIT " + json.dumps({"output": str(output), "asset_count": len(assets),
                                          "part_count": len(parts), "triangles": manifest["export_triangles"],
                                          "elapsed_seconds": receipt["elapsed_seconds"]}), flush=True)


if __name__ == "__main__":
    main()
