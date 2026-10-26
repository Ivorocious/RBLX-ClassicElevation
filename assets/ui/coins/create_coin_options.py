"""Build the coin design options in Blender and render matching gold and clay views.

Run with the installed Blender, not system Python:
  blender --background --factory-startup --python-exit-code 1 --python assets/ui/coins/create_coin_options.py -- [coin ids]

Coins share one base (gold body, raised rims, milled edge, navy inverted-hull outline). Emblem outlines use the
same 64-unit coordinates as the concept page SVGs so the 2D icons and 3D pickups stay identical. Writes
coin-options.blend (or coin-<ids>.blend for a subset) and renders/<id>-<view>.png next to this file.
Add --turntable after the coin ids for the full eight-angle gold and clay set.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix

OUT = Path(__file__).resolve().parent
RENDERS = OUT / "renders"
RENDERS.mkdir(parents=True, exist_ok=True)

DIAMETER = 2.5          # studs; a 2.5-stud pickup
THICKNESS = 0.24
SVG_RADIUS = 28.0       # coin radius in the 64-unit SVG drawings
SCALE = (DIAMETER / 2) / SVG_RADIUS


def srgb(hex_color):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    h = hex_color.lstrip("#")
    return tuple(lin(int(h[i:i + 2], 16)) for i in (0, 2, 4)) + (1.0,)


def star_points(cx, cy, outer, inner, points):
    pts = []
    for i in range(points * 2):
        a = -math.pi / 2 + i * math.pi / points
        r = outer if i % 2 == 0 else inner
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


LEFT_WING = [(17.55, 22.31), (12.62, 18.77), (7.07, 15.68), (0.91, 13.47), (3.99, 18.44), (8.92, 22.86), (2.76, 24.52), (6.46, 27.84), (10.77, 30.6), (5.84, 34.47), (11.39, 37.23), (17.55, 39.99)]

COINS = {
    "star": {"emblems": [star_points(32, 32, 15.5, 5.4, 4)]},
    "stud": {"stud": 11.0},
    "crown": {"emblems": [[(18, 45), (16.5, 24), (25, 31), (32, 19), (39, 31), (47.5, 24), (46, 45)]], "jewels": [(16.5, 24), (32, 19), (47.5, 24)]},
    "ot": {"rings": [(24.5, 32, 9.0, 4.2)], "emblems": [[(33, 23), (48, 23), (48, 29), (43.5, 29), (43.5, 42), (37.5, 42), (37.5, 29), (33, 29)]]},
    "wings": {"radius": 18.0, "emblems": [star_points(32, 32, 10.0, 3.5, 4)], "wings": True},
    "bolt": {"emblems": [[(35.5, 15), (22, 35), (31, 35), (27.5, 49), (42, 28.5), (33, 28.5)]]},
}

VIEWS = {
    "hero": {"turn": 28, "tilt": 8, "clay": False},
    "front": {"turn": 0, "tilt": 0, "clay": False},
    "edge": {"turn": 78, "tilt": 6, "clay": False},
    "clay": {"turn": 28, "tilt": 8, "clay": True},
}
# --turntable: the full angle set handed to implementers for the chosen coin.
TURNTABLE = {f"{kind}-{turn:03d}": {"turn": turn, "tilt": 10, "clay": kind == "clay"} for kind in ("gold", "clay") for turn in range(0, 360, 45)}
TURNTABLE["gold-high"] = {"turn": 25, "tilt": 40, "clay": False}
TURNTABLE["clay-high"] = {"turn": 25, "tilt": 40, "clay": True}


def svg_xy(x, y):
    return ((x - 32) * SCALE, -(y - 32) * SCALE)


def material(name, color, metallic=0.0, roughness=0.5, outline=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    if outline:
        shader = nodes.new("ShaderNodeEmission")
        shader.inputs["Color"].default_value = srgb(color)
        shader.inputs["Strength"].default_value = 1.0
        mat.node_tree.links.new(shader.outputs["Emission"], out.inputs["Surface"])
        mat.use_backface_culling = True
    else:
        shader = nodes.new("ShaderNodeBsdfPrincipled")
        shader.inputs["Base Color"].default_value = srgb(color)
        shader.inputs["Metallic"].default_value = metallic
        shader.inputs["Roughness"].default_value = roughness
        mat.node_tree.links.new(shader.outputs["BSDF"], out.inputs["Surface"])
    mat["clay_source"] = color
    return mat


def mesh_object(name, bm, collection, mats, smooth=True):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = smooth
    obj = bpy.data.objects.new(name, mesh)
    for mat in mats:
        mesh.materials.append(mat)
    collection.objects.link(obj)
    return obj


def add_bevel(obj, width, segments=3):
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.harden_normals = True


def add_outline(obj, width):
    mod = obj.modifiers.new("Outline", "SOLIDIFY")
    mod.thickness = width
    mod.offset = 1.0
    mod.use_flip_normals = True
    mod.use_rim = False
    mod.material_offset = 1


def torus(bm, major, minor, z, segments=72, ring=10):
    rows = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        row = []
        for j in range(ring):
            b = 2 * math.pi * j / ring
            r = major + minor * math.cos(b)
            row.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z + minor * math.sin(b))))
        rows.append(row)
    for i in range(segments):
        for j in range(ring):
            a, b = rows[i][j], rows[(i + 1) % segments][j]
            c, d = rows[(i + 1) % segments][(j + 1) % ring], rows[i][(j + 1) % ring]
            bm.faces.new((a, b, c, d))


def flat_shape(name, points, z, collection, mats, thickness, mirror_back):
    """Extrude a 64-unit SVG outline into a raised emblem on one or both coin faces."""
    objs = []
    for side in ((1, -1) if mirror_back else (1,)):
        bm = bmesh.new()
        verts = [bm.verts.new((*svg_xy(x, y), 0.0)) for x, y in points]
        face = bm.faces.new(verts)
        face.normal_update()
        if face.normal.z < 0:
            face.normal_flip()
        obj = mesh_object(f"{name}_{'front' if side > 0 else 'back'}", bm, collection, mats, smooth=False)
        solid = obj.modifiers.new("Raise", "SOLIDIFY")
        solid.thickness = thickness
        solid.offset = 1.0
        add_bevel(obj, thickness * 0.35, 2)
        obj.location.z = z * side
        if side < 0:
            obj.rotation_euler.y = math.pi  # turned, not mirrored, so the back reads correctly
        objs.append(obj)
    return objs


def build_coin(coin_id, spec, mats):
    collection = bpy.data.collections.new(f"Coin_{coin_id}")
    bpy.context.scene.collection.children.link(collection)
    root = bpy.data.objects.new(f"Coin_{coin_id}", None)
    collection.objects.link(root)
    radius = (spec.get("radius", SVG_RADIUS)) * SCALE
    half = THICKNESS / 2
    parts = []

    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=72, radius1=radius, radius2=radius, depth=THICKNESS)
    body = mesh_object(f"{coin_id}_body", bm, collection, [mats["gold"], mats["outline"]])
    add_bevel(body, 0.03)
    add_outline(body, 0.045)
    parts.append(body)

    bm = bmesh.new()
    for z in (half, -half):
        torus(bm, radius - 0.085, 0.06, z)
    rim = mesh_object(f"{coin_id}_rim", bm, collection, [mats["rim"], mats["outline"]])
    add_outline(rim, 0.02)
    parts.append(rim)

    bm = bmesh.new()
    ridges = 64
    for i in range(ridges):
        a = 2 * math.pi * i / ridges
        m = Matrix.Translation((radius * math.cos(a), radius * math.sin(a), 0)) @ Matrix.Rotation(a, 4, "Z") @ Matrix.Diagonal((0.03, 0.045, THICKNESS * 0.62, 1))
        bmesh.ops.create_cube(bm, size=1.0, matrix=m)
    parts.append(mesh_object(f"{coin_id}_ridges", bm, collection, [mats["rim"]], smooth=False))

    bm = bmesh.new()
    dot_radius = radius - 0.2
    for z in (half + 0.005, -half - 0.005):
        for i in range(28):
            a = 2 * math.pi * i / 28
            bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=6, radius=0.022, matrix=Matrix.Translation((dot_radius * math.cos(a), dot_radius * math.sin(a), z)))
    parts.append(mesh_object(f"{coin_id}_dots", bm, collection, [mats["rim"]]))

    emblem_parts = []
    for k, points in enumerate(spec.get("emblems", [])):
        emblem_parts += flat_shape(f"{coin_id}_emblem{k}", points, half, collection, [mats["emblem"], mats["outline"]], 0.06, True)
    for k, (cx, cy, outer, inner) in enumerate(spec.get("rings", [])):
        for side in (1, -1):
            bm = bmesh.new()
            segs = 48
            ox, oy = svg_xy(cx, cy)
            outer_v = [bm.verts.new((ox + outer * SCALE * math.cos(2 * math.pi * i / segs), oy + outer * SCALE * math.sin(2 * math.pi * i / segs), 0)) for i in range(segs)]
            inner_v = [bm.verts.new((ox + inner * SCALE * math.cos(2 * math.pi * i / segs), oy + inner * SCALE * math.sin(2 * math.pi * i / segs), 0)) for i in range(segs)]
            for i in range(segs):
                bm.faces.new((outer_v[i], outer_v[(i + 1) % segs], inner_v[(i + 1) % segs], inner_v[i]))
            ring = mesh_object(f"{coin_id}_ring{k}_{side}", bm, collection, [mats["emblem"], mats["outline"]], smooth=False)
            solid = ring.modifiers.new("Raise", "SOLIDIFY")
            solid.thickness = 0.06
            solid.offset = 1.0
            add_bevel(ring, 0.02, 2)
            ring.location.z = half * side
            if side < 0:
                ring.rotation_euler.y = math.pi
            emblem_parts.append(ring)
    for p in emblem_parts:
        add_outline(p, 0.022)
    parts += emblem_parts

    for k, (jx, jy) in enumerate(spec.get("jewels", [])):
        bm = bmesh.new()
        x, y = svg_xy(jx, jy)
        for side in (1, -1):
            bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=2.4 * SCALE, matrix=Matrix.Translation((x, y, side * (half + 0.07))))
        jewel = mesh_object(f"{coin_id}_jewel{k}", bm, collection, [mats["jewel"], mats["outline"]])
        add_outline(jewel, 0.018)
        parts.append(jewel)

    if spec.get("stud"):
        r = spec["stud"] * SCALE
        for side in (1, -1):
            bm = bmesh.new()
            bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=48, radius1=r, radius2=r, depth=0.1, matrix=Matrix.Translation((0, 0, side * (half + 0.05))))
            stud = mesh_object(f"{coin_id}_stud_{side}", bm, collection, [mats["emblem"], mats["outline"]])
            add_bevel(stud, 0.03)
            add_outline(stud, 0.025)
            parts.append(stud)

    if spec.get("wings"):
        for side in (1, -1):
            pts = LEFT_WING if side > 0 else [(64 - x, y) for x, y in reversed(LEFT_WING)]
            bm = bmesh.new()
            verts = [bm.verts.new((*svg_xy(x, y), 0.0)) for x, y in pts]
            face = bm.faces.new(verts)
            face.normal_update()
            if face.normal.z < 0:
                face.normal_flip()
            wing = mesh_object(f"{coin_id}_wing_{'L' if side > 0 else 'R'}", bm, collection, [mats["wing"], mats["outline"]], smooth=False)
            solid = wing.modifiers.new("Thickness", "SOLIDIFY")
            solid.thickness = 0.1
            solid.offset = 0.0
            add_bevel(wing, 0.025, 2)
            add_outline(wing, 0.035)
            parts.append(wing)

    for p in parts:
        p.parent = root
    root.rotation_euler = (math.radians(90), 0, 0)
    return collection, root


def setup_scene():
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x = scene.render.resolution_y = 640
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 48
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = srgb("#FFF1DC")
    bg.inputs["Strength"].default_value = 0.9
    scene.world = world

    def light(name, kind, energy, loc, color="#FFFFFF", size=3.0):
        data = bpy.data.lights.new(name, kind)
        data.energy = energy
        data.color = srgb(color)[:3]
        if kind == "AREA":
            data.size = size
        obj = bpy.data.objects.new(name, data)
        obj.location = loc
        obj.rotation_euler = (0, 0, 0)
        direction = -obj.location.normalized()
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(obj)

    light("Key", "AREA", 1300, (-4, -6, 5), "#FFF4DE", 4)
    light("Fill", "AREA", 300, (5, -5, 0.5), "#DCEBFF", 4)
    light("Rim", "AREA", 700, (2, 6, 3), "#BFE2FF", 3)

    cam_data = bpy.data.cameras.new("Camera")
    cam_data.lens = 85
    cam = bpy.data.objects.new("Camera", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return scene, cam


def frame_camera(cam, tilt_deg, wide):
    distance = 11.5 if wide else 10.5
    t = math.radians(tilt_deg)
    cam.location = (0, -distance * math.cos(t), distance * math.sin(t))
    cam.rotation_euler = (math.radians(90) - t, 0, 0)


def set_clay(mats, on):
    for key, mat in mats.items():
        if key == "outline":
            continue
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf is None:
            continue
        if on:
            bsdf.inputs["Base Color"].default_value = srgb("#D9D9DE")
            bsdf.inputs["Metallic"].default_value = 0.0
            bsdf.inputs["Roughness"].default_value = 0.75
        else:
            bsdf.inputs["Base Color"].default_value = srgb(mat["clay_source"])
            bsdf.inputs["Metallic"].default_value = mat["metallic"]
            bsdf.inputs["Roughness"].default_value = mat["roughness"]


def main():
    wanted = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    views = TURNTABLE if "--turntable" in wanted else VIEWS
    ids = [c for c in COINS if c in wanted] or list(COINS)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene, cam = setup_scene()
    mats = {
        "gold": material("Gold", "#FFB300", 0.25, 0.35),
        "rim": material("GoldRim", "#FFD03A", 0.3, 0.3),
        "emblem": material("GoldEmblem", "#FFE066", 0.2, 0.28),
        "wing": material("Wing", "#FFFFFF", 0.0, 0.45),
        "jewel": material("Jewel", "#56C8FF", 0.1, 0.15),
        "outline": material("Outline", "#10215C", outline=True),
    }
    for mat, metallic, roughness in ((mats["gold"], .25, .35), (mats["rim"], .3, .3), (mats["emblem"], .2, .28), (mats["wing"], 0, .45), (mats["jewel"], .1, .15)):
        mat["metallic"], mat["roughness"] = metallic, roughness

    built = {cid: build_coin(cid, COINS[cid], mats) for cid in ids}
    for cid, (collection, root) in built.items():
        for other, (col, _) in built.items():
            col.hide_render = other != cid
        for view, v in views.items():
            root.rotation_euler = (math.radians(90), 0, math.radians(v["turn"]))
            frame_camera(cam, v["tilt"], COINS[cid].get("wings", False))
            set_clay(mats, v["clay"])
            scene.render.filepath = str(RENDERS / f"{cid}-{view}.png")
            bpy.ops.render.render(write_still=True)
        root.rotation_euler = (math.radians(90), 0, 0)
        print(f"Rendered coin {cid}")
    set_clay(mats, False)
    for col, _ in built.values():
        col.hide_render = False
    blend = OUT / ("coin-options.blend" if len(ids) == len(COINS) else f"coin-{'-'.join(ids)}.blend")
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    print("Saved", blend)


main()
