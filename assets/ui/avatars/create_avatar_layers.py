"""Render layered 3D stand-in avatars for the UI concept page.

Blocky Roblox-style racer rendered once per pose, one transparent PNG per body part, face and accessory.
Body parts are white so the page can tint skin and clothing live while keeping the 3D shading; other parts
are held out of each layer so the stacked layers occlude correctly. In the game, Arrival and Results use the
players' real avatars (HumanoidDescription -> R15 model in a ViewportFrame); these renders only stand in.

  blender --background --factory-startup --python-exit-code 1 --python assets/ui/avatars/create_avatar_layers.py
"""
import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix

OUT = Path(__file__).resolve().parent / "renders"
OUT.mkdir(parents=True, exist_ok=True)

POSES = {
    "idle": {"armA": 6, "armB": 6, "turn": 16},
    "wave": {"armA": 6, "armB": 140, "turn": 16},
    "victory": {"armA": 135, "armB": 135, "turn": 0},
    "cheer": {"armA": 100, "armB": 100, "turn": 0},
}
BODY = ["legs", "torso", "armA", "armB", "head"]
DECALS = ["face"]
ACCESSORIES = ["hair_tousled", "hair_classic", "hair_spiked", "hat", "glasses"]


def srgb(hex_color):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    h = hex_color.lstrip("#")
    return tuple(lin(int(h[i:i + 2], 16)) for i in (0, 2, 4)) + (1.0,)


def material(name, color, roughness=0.55, emit=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    if emit:
        shader = nodes.new("ShaderNodeEmission")
        shader.inputs["Color"].default_value = srgb(color)
        mat.node_tree.links.new(shader.outputs["Emission"], out.inputs["Surface"])
    else:
        shader = nodes.new("ShaderNodeBsdfPrincipled")
        shader.inputs["Base Color"].default_value = srgb(color)
        shader.inputs["Roughness"].default_value = roughness
        mat.node_tree.links.new(shader.outputs["BSDF"], out.inputs["Surface"])
    return mat


COLLECTIONS = {}


def collection(name):
    if name not in COLLECTIONS:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
        COLLECTIONS[name] = col
    return COLLECTIONS[name]


def obj_from(bm, name, layer, mat, parent, smooth=True, bevel=None):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = smooth
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    collection(layer).objects.link(obj)
    obj.parent = parent
    if bevel:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width, mod.segments, mod.limit_method = bevel[0], bevel[1], "ANGLE"
        mod.harden_normals = True
    return obj


def box(bm, size, center):
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(center) @ Matrix.Diagonal((*size, 1)))


def build(mats):
    root = bpy.data.objects.new("Racer", None)
    bpy.context.scene.collection.objects.link(root)

    bm = bmesh.new()
    box(bm, (0.98, 0.98, 2.0), (-0.5, 0, 1.0))
    box(bm, (0.98, 0.98, 2.0), (0.5, 0, 1.0))
    obj_from(bm, "Legs", "legs", mats["white"], root, bevel=(0.06, 3))
    bm = bmesh.new()
    box(bm, (2.0, 1.0, 2.0), (0, 0, 3.0))
    obj_from(bm, "Torso", "torso", mats["white"], root, bevel=(0.06, 3))
    arms = {}
    # Roblox shoulder joint: the arm's inner top corner, half a stud below the torso top.
    for name, side in (("armA", -1), ("armB", 1)):
        pivot = bpy.data.objects.new(name + "_pivot", None)
        bpy.context.scene.collection.objects.link(pivot)
        pivot.parent = root
        pivot.location = (side * 1.0, 0, 3.5)
        bm = bmesh.new()
        box(bm, (0.98, 0.98, 2.0), (side * 0.5, 0, -0.5))
        obj_from(bm, name, name, mats["white"], pivot, bevel=(0.06, 3))
        arms[name] = pivot
    bm = bmesh.new()
    box(bm, (1.25, 1.2, 1.2), (0, 0, 4.62))
    obj_from(bm, "Head", "head", mats["white"], root, bevel=(0.28, 5))

    bm = bmesh.new()
    for x in (-0.22, 0.22):
        bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=0.085, radius2=0.085, depth=0.03,
                              matrix=Matrix.Translation((x, -0.61, 4.74)) @ Matrix.Rotation(math.radians(90), 4, "X") @ Matrix.Diagonal((0.85, 1.25, 1, 1)))
    rows = []
    for i in range(13):
        a = math.radians(200 + i * 140 / 12)
        cx, cz = 0.27 * math.cos(a), 4.6 + 0.27 * math.sin(a)
        ring = []
        for j in range(8):
            b = 2 * math.pi * j / 8
            ring.append(bm.verts.new((cx + 0.035 * math.cos(b) * math.cos(a), -0.615 + 0.035 * math.sin(b), cz + 0.035 * math.cos(b) * math.sin(a))))
        rows.append(ring)
    for i in range(12):
        for j in range(8):
            bm.faces.new((rows[i][j], rows[i + 1][j], rows[i + 1][(j + 1) % 8], rows[i][(j + 1) % 8]))
    obj_from(bm, "Face", "face", mats["face"], root)

    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=16, radius=1.0, matrix=Matrix.Translation((0, 0.04, 5.08)) @ Matrix.Diagonal((0.74, 0.7, 0.4, 1)))
    for k in range(6):
        a = math.radians(-150 + k * 24)
        bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.2, matrix=Matrix.Translation((0.55 * math.cos(a), -0.32 + 0.1 * math.sin(a), 5.12 + 0.06 * (k % 2))))
    obj_from(bm, "HairTousled", "hair_tousled", mats["hair"], root)
    bm = bmesh.new()
    box(bm, (1.38, 1.32, 0.42), (0, 0.02, 5.18))
    box(bm, (0.3, 1.3, 0.62), (-0.56, 0.04, 4.86))
    box(bm, (1.36, 0.3, 0.9), (0, 0.56, 4.8))
    obj_from(bm, "HairClassic", "hair_classic", mats["hair"], root, bevel=(0.12, 3))
    bm = bmesh.new()
    box(bm, (1.3, 1.26, 0.26), (0, 0.02, 5.14))
    for k, (x, y) in enumerate([(-0.42, -0.3), (0, -0.36), (0.42, -0.3), (-0.3, 0.2), (0.3, 0.2), (0, 0.0), (-0.55, 0.0), (0.55, 0.0)]):
        bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.2, radius2=0.0, depth=0.52 if k < 3 else 0.42,
                              matrix=Matrix.Translation((x, y, 5.42)) @ Matrix.Rotation(math.radians(-14 if y < 0 else 8), 4, "X"))
    obj_from(bm, "HairSpiked", "hair_spiked", mats["hair"], root, smooth=False)

    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=16, radius=1.0, matrix=Matrix.Translation((0, 0, 5.0)) @ Matrix.Diagonal((0.74, 0.74, 0.62, 1)))
    obj_from(bm, "HatDome", "hat", mats["hat"], root)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=40, radius1=0.86, radius2=0.86, depth=0.08, matrix=Matrix.Translation((0, -0.06, 5.04)))
    obj_from(bm, "HatBrim", "hat", mats["hat"], root, bevel=(0.03, 2))
    bm = bmesh.new()
    box(bm, (0.2, 1.52, 0.2), (0, 0, 5.56))
    obj_from(bm, "HatStripe", "hat", mats["stripe"], root, bevel=(0.05, 2))

    bm = bmesh.new()
    for x in (-0.25, 0.25):
        box(bm, (0.44, 0.05, 0.24), (x, -0.645, 4.76))
    box(bm, (0.12, 0.04, 0.05), (0, -0.645, 4.8))
    obj_from(bm, "Lenses", "glasses", mats["lens"], root, bevel=(0.03, 2))
    bm = bmesh.new()
    for x in (-0.25, 0.25):
        box(bm, (0.46, 0.06, 0.05), (x, -0.66, 4.87))
    obj_from(bm, "Frames", "glasses", mats["frame"], root)
    return root, arms


def set_layers(target):
    """Show one layer, hold out the body that can block it, exclude everything else."""
    for name, col in COLLECTIONS.items():
        lc = bpy.context.view_layer.layer_collection.children[col.name]
        if name == target:
            lc.exclude, lc.holdout = False, False
        elif name in BODY:
            lc.exclude, lc.holdout = False, True
        else:
            lc.exclude, lc.holdout = True, False


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 32
    world = bpy.data.worlds.new("Studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = srgb("#FFFFFF")
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55
    scene.world = world
    for name, energy, loc, size in (("Key", 1400, (-5, -7, 9), 5), ("Fill", 450, (6, -6, 3), 5), ("Rim", 900, (2, 7, 7), 4)):
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.size = energy, size
        light = bpy.data.objects.new(name, data)
        light.location = loc
        light.rotation_euler = (-light.location.normalized()).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(light)
    cam_data = bpy.data.cameras.new("Camera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 7.6
    cam = bpy.data.objects.new("Camera", cam_data)
    cam.location = (0, -20, 3.0)
    cam.rotation_euler = (math.radians(90), 0, 0)
    scene.collection.objects.link(cam)
    scene.camera = cam

    mats = {
        "white": material("Body", "#FFFFFF", 0.55),
        "face": material("Face", "#1A1F33", 0.4),
        "hair": material("Hair", "#6B3E1F", 0.6),
        "hat": material("Hat", "#FFC21F", 0.35),
        "stripe": material("HatStripe", "#52DFFF", 0.35),
        "lens": material("Lens", "#2B2F55", 0.15),
        "frame": material("Frame", "#FF6FB0", 0.4),
    }
    root, arms = build(mats)
    for pose, p in POSES.items():
        arms["armA"].rotation_euler = (0, math.radians(p["armA"]), 0)
        arms["armB"].rotation_euler = (0, -math.radians(p["armB"]), 0)
        root.rotation_euler = (0, 0, math.radians(p["turn"]))
        for layer in BODY + DECALS + ACCESSORIES:
            set_layers(layer)
            scene.render.filepath = str(OUT / f"{pose}-{layer}.png")
            bpy.ops.render.render(write_still=True)
        print(f"Rendered pose {pose}")
    for name, col in COLLECTIONS.items():
        lc = bpy.context.view_layer.layer_collection.children[col.name]
        lc.exclude, lc.holdout = False, False
    POSE = POSES["idle"]
    arms["armA"].rotation_euler = (0, math.radians(POSE["armA"]), 0)
    arms["armB"].rotation_euler = (0, -math.radians(POSE["armB"]), 0)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT.parent / "avatar-layers.blend"))
    print("Saved", OUT.parent / "avatar-layers.blend")


main()
