"""Editable Moonlit mechanism meshes; Blender units are studs, Z up, front -Y."""

import math

import bmesh
import bpy
from mathutils import Vector


PALETTE = {
    "Stone": (111, 122, 137),
    "StoneCarve": (86, 98, 116),
    "Iron": (30, 37, 49),
    "Brass": (176, 131, 62),
    "Amber": (191, 106, 28),
    "Red": (255, 29, 43),
}


def _linear(channel):
    value = channel / 255
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def _materials():
    result = {}
    for key, color in PALETTE.items():
        name = "MC_BL02_" + key
        material = bpy.data.materials.get(name)
        if material is None:
            material = bpy.data.materials.new(name)
            material.use_nodes = True
            rgba = tuple(_linear(channel) for channel in color) + (1,)
            material.diffuse_color = rgba
            shader = material.node_tree.nodes.get("Principled BSDF")
            shader.inputs["Base Color"].default_value = rgba
            shader.inputs["Roughness"].default_value = 0.76 if key.startswith("Stone") else 0.38
            shader.inputs["Metallic"].default_value = 0.65 if key in ("Iron", "Brass") else 0
            if key == "Amber":
                shader.inputs["Roughness"].default_value = 0.48
            elif key == "Red":
                shader.inputs["Emission Color"].default_value = rgba
                shader.inputs["Emission Strength"].default_value = 0.28
        result[key] = material
    return result


class _Geometry:
    def __init__(self):
        self.vertices = []
        self.faces = []
        self.material_keys = []
        self.smooth = []

    def add(self, vertices, faces, material="Iron", smooth=False):
        base = len(self.vertices)
        self.vertices.extend(tuple(vertex) for vertex in vertices)
        self.faces.extend(tuple(base + index for index in face) for face in faces)
        self.material_keys.extend([material] * len(faces))
        self.smooth.extend([smooth] * len(faces))

    def box(self, center, size, material="Iron"):
        c = Vector(center)
        half = Vector(size) / 2
        vertices = [c + Vector((x * half.x, y * half.y, z * half.z))
                    for z in (-1, 1) for y in (-1, 1) for x in (-1, 1)]
        faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
                 (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
        self.add(vertices, faces, material)

    def tube(self, path, radius, material="Iron", sides=6, closed=False):
        points = [Vector(point) for point in path]
        vertices = []
        previous_u = None
        for index, point in enumerate(points):
            previous = points[index - 1] if index > 0 or closed else points[index]
            following = points[(index + 1) % len(points)] if index + 1 < len(points) or closed else points[index]
            tangent = (following - previous).normalized()
            u = previous_u - tangent * previous_u.dot(tangent) if previous_u is not None else Vector((0, 0, 0))
            if u.length < 0.001:
                reference = Vector((0, 0, 1)) if abs(tangent.z) < 0.95 else Vector((0, 1, 0))
                u = tangent.cross(reference)
            u.normalize()
            previous_u = u
            v = tangent.cross(u).normalized()
            vertices.extend(point + radius * (u * math.cos(2 * math.pi * side / sides)
                                               + v * math.sin(2 * math.pi * side / sides))
                            for side in range(sides))
        segment_count = len(points) if closed else len(points) - 1
        faces = []
        for index in range(segment_count):
            following = (index + 1) % len(points)
            for side in range(sides):
                next_side = (side + 1) % sides
                faces.append((index * sides + side, index * sides + next_side,
                              following * sides + next_side, following * sides + side))
        if not closed:
            faces.extend([tuple(reversed(range(sides))),
                          tuple((len(points) - 1) * sides + side for side in range(sides))])
        self.add(vertices, faces, material, smooth=True)

    def lathe(self, profile, material="Iron", segments=32, axis="Z", capped=True):
        vertices = []
        for position, radius in profile:
            for index in range(segments):
                angle = 2 * math.pi * index / segments
                a, b = radius * math.cos(angle), radius * math.sin(angle)
                vertices.append((a, b, position) if axis == "Z" else (a, position, b))
        faces = []
        for ring in range(len(profile) - 1):
            for index in range(segments):
                following = (index + 1) % segments
                faces.append((ring * segments + index, ring * segments + following,
                              (ring + 1) * segments + following, (ring + 1) * segments + index))
        if capped:
            faces.extend([tuple(reversed(range(segments))),
                          tuple((len(profile) - 1) * segments + index for index in range(segments))])
        self.add(vertices, faces, material, smooth=segments > 12)
        if capped:
            self.smooth[-2:] = [False, False]

    def rectangle_profile(self, profiles, material="Stone", cap_top=True):
        vertices = [(x * width / 2, y * depth / 2, height)
                    for height, width, depth in profiles for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        faces = [(3, 2, 1, 0)]
        faces.extend((ring * 4 + side, ring * 4 + (side + 1) % 4,
                      (ring + 1) * 4 + (side + 1) % 4, (ring + 1) * 4 + side)
                     for ring in range(len(profiles) - 1) for side in range(4))
        if cap_top:
            faces.append(tuple((len(profiles) - 1) * 4 + side for side in range(4)))
        self.add(vertices, faces, material)


def _quadratic(start, control, end, steps=4):
    a, b, c = Vector(start), Vector(control), Vector(end)
    return [(1 - t) ** 2 * a + 2 * t * (1 - t) * b + t ** 2 * c
            for t in (index / steps for index in range(steps + 1))]


def _ring(geometry, radius, position, thickness, material="Brass", axis="Z", segments=32):
    path = []
    for index in range(segments):
        angle = 2 * math.pi * index / segments
        a, b = radius * math.cos(angle), radius * math.sin(angle)
        path.append((a, b, position) if axis == "Z" else (a, position, b))
    geometry.tube(path, thickness, material, sides=6, closed=True)


def _diamond(geometry, center, width, height, radius=0.055, material="Brass"):
    x, y, z = center
    geometry.tube([(x, y, z - height / 2), (x + width / 2, y, z),
                   (x, y, z + height / 2), (x - width / 2, y, z)], radius, material, closed=True)


def _make_object(collection, name, geometry, materials, role, bevel=0.025):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(geometry.vertices, [], geometry.faces)
    mesh.update()
    used_keys = list(dict.fromkeys(geometry.material_keys))
    for key in used_keys:
        mesh.materials.append(materials[key])
    for polygon, key, smooth in zip(mesh.polygons, geometry.material_keys, geometry.smooth):
        polygon.material_index = used_keys.index(key)
        polygon.use_smooth = smooth
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    if bevel:
        modifier = obj.modifiers.new("Soft authored edges", "BEVEL")
        modifier.width, modifier.segments = bevel, 1
        modifier.limit_method, modifier.angle_limit = "ANGLE", math.radians(40)
        modifier.use_clamp_overlap = True
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        baked = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph), preserve_all_data_layers=True, depsgraph=depsgraph)
        obj.modifiers.clear()
        obj.data = baked
        baked.name = name + "_Mesh"
        bpy.data.meshes.remove(mesh)
    obj["AssetKey"], obj["Role"] = name, role
    obj["Units"], obj["UpAxis"], obj["FrontAxis"] = "stud", "Z", "-Y"
    obj["VisualOnly"], obj["Build"] = True, "MC_P1_BL02"
    return obj


def _car_stone():
    geometry = _Geometry()
    geometry.rectangle_profile([(-1, 13.5, 11.5), (-0.9, 13.7, 11.7),
                                (-0.30, 13.7, 11.7), (-0.17, 14, 12), (0, 14, 12)])
    # The shallow apron relief stays below the uninterrupted transfer surface.
    for y in (-5.865, 5.865):
        for x in (-4.5, 0, 4.5):
            _diamond(geometry, (x, y, -0.61), 0.58, 0.48, 0.018, "StoneCarve")
    return geometry


def _car_iron_brass():
    geometry = _Geometry()
    for x in (-6.82, 6.82):
        geometry.box((x, 0, 0.18), (0.30, 11.8, 0.32))
        geometry.box((x, 0, 2.83), (0.30, 11.8, 0.24))
        geometry.box((x, 0, 2.96), (0.35, 11.9, 0.08), "Brass")
        for y in (-5.68, -1.89, 1.89, 5.68):
            geometry.box((x, y, 1.5), (0.28, 0.28, 2.85))
            geometry.box((x, y, 0.22), (0.34, 0.42, 0.36), "Brass")
        for center_y in (-3.78, 0, 3.78):
            left = (x, center_y - 1.59, 0.35)
            peak = (x, center_y, 2.70)
            right = (x, center_y + 1.59, 0.35)
            path = _quadratic(left, (x, center_y - 1.5, 2.25), peak)
            path += _quadratic(peak, (x, center_y + 1.5, 2.25), right)[1:]
            geometry.tube(path, 0.085, sides=6)
    for y in (-5.90, 5.90):
        geometry.box((0, y, -0.48), (13.8, 0.18, 0.48))
        geometry.box((0, y, -0.23), (13.8, 0.19, 0.045), "Brass")
    return geometry


def _weight_stone():
    geometry = _Geometry()
    front, back = -1.25, 1.25
    rectangle = [(-2, -4), (2, -4), (2, 4), (-2, 4)]
    diamond = [(0, -2.15), (1.15, 0), (0, 2.15), (-1.15, 0)]
    vertices = [(x, y, z) for y, polygon in ((front, rectangle), (back, rectangle),
                                            (front, diamond), (front + 0.10, diamond)) for x, z in polygon]
    faces = [(4, 5, 6, 7)]
    for side in range(4):
        next_side = (side + 1) % 4
        faces.append((side, next_side, next_side + 4, side + 4))
        faces.append((side, next_side, next_side + 8, side + 8))
    carved_faces = [(8 + side, 8 + (side + 1) % 4, 12 + (side + 1) % 4, 12 + side)
                    for side in range(4)] + [(12, 13, 14, 15)]
    geometry.add(vertices, faces + carved_faces, "Stone")
    geometry.material_keys[-len(carved_faces):] = ["StoneCarve"] * len(carved_faces)
    return geometry


def _weight_iron():
    geometry = _Geometry()
    for x in (-1.93, 1.93):
        geometry.box((x, -1.28, 0), (0.14, 0.16, 7.8))
    for z in (-3.88, 3.88):
        geometry.box((0, -1.28, z), (4, 0.16, 0.18))
        geometry.box((0, -1.39, z), (3.75, 0.05, 0.065), "Brass")
    _diamond(geometry, (0, -1.26, 0), 2.18, 4.12, 0.055)
    _diamond(geometry, (0, -1.23, 0), 0.63, 1.1, 0.045)
    return geometry


def _pulley_iron():
    geometry = _Geometry()
    geometry.lathe([(-0.58, 3.4), (-0.40, 3.4), (-0.27, 3.02),
                    (0.27, 3.02), (0.40, 3.4), (0.58, 3.4)], axis="Y", segments=24)
    geometry.lathe([(-0.91, 0.56), (-0.64, 0.69), (-0.54, 0.69)], axis="Y", segments=16)
    for index in range(6):
        angle = 2 * math.pi * index / 6
        geometry.tube([(radius * math.cos(angle), -0.61, radius * math.sin(angle))
                       for radius in (0.75, 2.92)], 0.045, sides=6)
    return geometry


def _pulley_brass():
    geometry = _Geometry()
    for y in (-0.635, 0.635):
        _ring(geometry, 3.21, y, 0.10, axis="Y", segments=24)
    _ring(geometry, 0.64, -0.94, 0.065, axis="Y", segments=16)
    geometry.lathe([(-1.02, 0.26), (-0.97, 0.33), (-0.89, 0.33)], "Brass", axis="Y", segments=12)
    return geometry


def _lantern_cage():
    geometry = _Geometry()
    geometry.lathe([(-3.5, 0.04), (-3.08, 0.28), (-2.83, 0.55),
                    (-2.44, 1.3), (-2.05, 1.86), (-1.89, 1.9)], segments=8)
    geometry.lathe([(1.80, 2), (1.97, 2), (2.16, 1.68), (2.43, 1.22),
                    (2.70, 0.79), (2.92, 0.43), (3.10, 0.18)], segments=8)
    geometry.lathe([(3.08, 0.16), (3.20, 0.28), (3.36, 0.13), (3.5, 0.025)], "Brass", segments=8)
    for height in (-1.92, -1.60, 1.54, 1.85):
        _ring(geometry, 1.87, height, 0.085, "Brass", segments=8)
    for index in range(8):
        angle = 2 * math.pi * index / 8
        next_angle = 2 * math.pi * (index + 1) / 8
        corner = Vector((1.84 * math.cos(angle), 1.84 * math.sin(angle), 0))
        next_corner = Vector((1.84 * math.cos(next_angle), 1.84 * math.sin(next_angle), 0))
        geometry.tube([corner + Vector((0, 0, -1.9)), corner + Vector((0, 0, 1.82))], 0.075)
        left, right = corner.lerp(next_corner, 0.15), corner.lerp(next_corner, 0.85)
        peak = corner.lerp(next_corner, 0.5) + Vector((0, 0, 1.52))
        path = _quadratic(left + Vector((0, 0, 0.30)), left + Vector((0, 0, 1.15)), peak, 3)
        path += _quadratic(peak, right + Vector((0, 0, 1.15)), right + Vector((0, 0, 0.30)), 3)[1:]
        geometry.tube(path, 0.038, "Brass", sides=4)
    return geometry


def _lantern_core():
    geometry = _Geometry()
    geometry.lathe([(-1.75, 1.36), (-1.60, 1.45), (1.42, 1.45), (1.58, 1.31)], "Amber", segments=8)
    return geometry


def _kill_casing():
    geometry = _Geometry()
    geometry.rectangle_profile([(-1, 13.6, 11.6), (-0.83, 13.8, 11.8),
                                (0.80, 13.8, 11.8), (1, 14, 12)], "Stone", cap_top=False)
    outer = [(-7, -6, 1), (7, -6, 1), (7, 6, 1), (-7, 6, 1)]
    inner = [(-6.96, -5.96, 1), (6.96, -5.96, 1), (6.96, 5.96, 1), (-6.96, 5.96, 1)]
    floor = [(x, y, 0.90) for x, y, _ in inner]
    faces = [(side, (side + 1) % 4, 4 + (side + 1) % 4, 4 + side) for side in range(4)]
    faces += [(4 + side, 4 + (side + 1) % 4, 8 + (side + 1) % 4, 8 + side) for side in range(4)]
    faces.append((8, 9, 10, 11))
    geometry.add(outer + inner + floor, faces, "Iron")
    for y in (-5.94, 5.94):
        geometry.box((0, y, 0.48), (13.85, 0.10, 0.16))
        for x in (-4.5, 0, 4.5):
            _diamond(geometry, (x, y, -0.20), 1.05, 0.98, 0.05, "Iron")
    return geometry


def _kill_red():
    geometry = _Geometry()
    for x in (-3.495, 3.495):
        geometry.box((x, 0, 0.973), (6.93, 11.92, 0.054), "Red")
    return geometry


def build_library(collection):
    """Create ten separate visual edit units; caller owns scene and output files."""
    recipes = [
        ("MC_CarStone", _car_stone, "Moving deck stone; walking surface Z=0", 0.018),
        ("MC_CarIronBrass", _car_iron_brass, "Moving side rails; both transfer ends open", 0),
        ("MC_WeightStone", _weight_stone, "Separate outside-channel counterweight stone", 0.04),
        ("MC_WeightIron", _weight_iron, "Separate shallow counterweight metal frame", 0),
        ("MC_PulleyIron", _pulley_iron, "Fixed or animated pulley body; axle along Y", 0),
        ("MC_PulleyBrass", _pulley_brass, "Separate offset pulley rims and hub", 0),
        ("MC_LanternCage", _lantern_cage, "Visible moving Gothic lantern cage; main eight-sided cage envelope preserved", 0),
        ("MC_LanternCore", _lantern_core, "Separate opaque warm amber lantern core; original closed profile without cosmetic bevel", 0),
        ("MC_KillCasing", _kill_casing, "Shallow hazard casing; no standing rim", 0.006),
        ("MC_KillRed", _kill_red, "Flush broad red contact cue; surface Z=1", 0.002),
    ]
    collisions = [name for name, _, _, _ in recipes if bpy.data.objects.get(name)]
    if collisions:
        raise ValueError("Preserve existing authored objects before rebuilding: " + ", ".join(collisions))
    materials = _materials()
    return [_make_object(collection, name, recipe(), materials, role, bevel)
            for name, recipe, role, bevel in recipes]
