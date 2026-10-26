"""Blender-authored Gothic edit units for MC_P1_BL01.

Call build_library(collection) in Blender. Nothing is built on import; this module
does not reset, save, render or export a scene. Units are intended studs, Z is up,
X is right and the facade front faces -Y. All returned object origins stay at zero.
Procedural stone grain is a preview treatment; mesh/UV/material export is separate.
"""

import math

import bmesh
import bpy
from mathutils import Vector


PALETTE = {
    "Stone": (111, 122, 137),
    "StoneLight": (149, 157, 169),
    "StoneDark": (77, 87, 103),
    "Slate": (37, 55, 81),
    "SlateBand": (49, 66, 89),
    "Iron": (30, 37, 49),
    "Brass": (176, 131, 62),
    "Amber": (191, 106, 28),
}


def _linear(channel):
    value = channel / 255.0
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def _materials():
    result = {}
    for key, rgb in PALETTE.items():
        name = "MC_BL01_" + key
        material = bpy.data.materials.get(name)
        if material is None:
            material = bpy.data.materials.new(name)
            material.use_nodes = True
            rgba = tuple(_linear(c) for c in rgb) + (1.0,)
            material.diffuse_color = rgba
            shader = material.node_tree.nodes.get("Principled BSDF")
            shader.inputs["Base Color"].default_value = rgba
            shader.inputs["Roughness"].default_value = 0.78
            if key in {"Iron", "Brass"}:
                shader.inputs["Metallic"].default_value = 0.68
                shader.inputs["Roughness"].default_value = 0.43
            elif key == "Amber":
                shader.inputs["Roughness"].default_value = 0.3
                emission = shader.inputs.get("Emission Color") or shader.inputs.get("Emission")
                if emission is not None:
                    emission.default_value = rgba
                strength = shader.inputs.get("Emission Strength")
                if strength is not None:
                    strength.default_value = 0.7
            elif key.startswith("Stone"):
                coordinate = material.node_tree.nodes.new("ShaderNodeTexCoord")
                noise = material.node_tree.nodes.new("ShaderNodeTexNoise")
                noise.inputs["Scale"].default_value = 1.7
                noise.inputs["Detail"].default_value = 2.0
                bump = material.node_tree.nodes.new("ShaderNodeBump")
                bump.inputs["Strength"].default_value = 0.12
                bump.inputs["Distance"].default_value = 0.045
                material.node_tree.links.new(coordinate.outputs["Object"], noise.inputs["Vector"])
                material.node_tree.links.new(noise.outputs["Fac"], bump.inputs["Height"])
                material.node_tree.links.new(bump.outputs["Normal"], shader.inputs["Normal"])
            material["PaletteRGB"] = list(rgb)
            material["ProceduralDetailNeedsBakeForRoblox"] = key.startswith("Stone")
        result[key] = material
    return result


class _Mesh:
    def __init__(self):
        self.vertices = []
        self.faces = []
        self.colors = []
        self.smooth = []

    def add(self, vertices, faces, color="Stone", smooth=False):
        offset = len(self.vertices)
        self.vertices.extend(tuple(v) for v in vertices)
        self.faces.extend(tuple(offset + index for index in face) for face in faces)
        self.colors.extend([color] * len(faces))
        self.smooth.extend([smooth] * len(faces))

    def box(self, center, size, color="Stone"):
        x, y, z = center
        a, b, c = (value / 2 for value in size)
        vertices = [(x + sx * a, y + sy * b, z + sz * c)
                    for sz in (-1, 1) for sy in (-1, 1) for sx in (-1, 1)]
        faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
                 (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
        self.add(vertices, faces, color)

    def prism(self, outline, front, back, color="Stone"):
        count = len(outline)
        vertices = [(x, y, z) for y in (front, back) for x, z in outline]
        faces = [tuple(reversed(range(count))), tuple(count + i for i in range(count))]
        faces.extend((i, (i + 1) % count, (i + 1) % count + count, i + count)
                     for i in range(count))
        self.add(vertices, faces, color)

    def ring(self, outer, inner, front, back, color="Stone"):
        """Closed extruded contour ring; both contours share sample indices."""
        assert len(outer) == len(inner)
        count = len(outer)
        vertices = [(x, y, z) for y in (front, back) for contour in (outer, inner)
                    for x, z in contour]
        faces = []
        for i in range(count):
            j = (i + 1) % count
            faces.extend([(i, j, count + j, count + i),
                          (2 * count + i, 3 * count + i, 3 * count + j, 2 * count + j),
                          (i, 2 * count + i, 2 * count + j, j),
                          (count + i, count + j, 3 * count + j, 3 * count + i)])
        self.add(vertices, faces, color)

    def arc_strip(self, outer, inner, front, back, color="Stone"):
        count = len(outer)
        assert count == len(inner)
        vertices = [(x, y, z) for y in (front, back) for contour in (outer, inner)
                    for x, z in contour]
        faces = []
        for i in range(count - 1):
            j = i + 1
            faces.extend([(i, j, count + j, count + i),
                          (2 * count + i, 3 * count + i, 3 * count + j, 2 * count + j),
                          (i, 2 * count + i, 2 * count + j, j),
                          (count + i, count + j, 3 * count + j, 3 * count + i)])
        faces.extend([(0, count, 3 * count, 2 * count),
                      (count - 1, 3 * count - 1, 4 * count - 1, 2 * count - 1)])
        self.add(vertices, faces, color)

    def tube(self, path, radius, color="Brass", sides=8, closed=False):
        points = [Vector(p) for p in path]
        assert len(points) >= 2
        vertices = []
        for index, point in enumerate(points):
            previous = points[(index - 1) % len(points)] if closed or index else points[0]
            following = points[(index + 1) % len(points)] if closed or index < len(points) - 1 else points[-1]
            tangent = following - previous
            assert tangent.length > 1e-8
            tangent.normalize()
            guide = Vector((0, -1, 0))
            if abs(tangent.dot(guide)) > 0.95:
                guide = Vector((0, 0, 1))
            u = tangent.cross(guide).normalized()
            v = tangent.cross(u).normalized()
            for side in range(sides):
                angle = 2 * math.pi * side / sides
                vertices.append(tuple(point + radius * (math.cos(angle) * u + math.sin(angle) * v)))
        faces = []
        intervals = len(points) if closed else len(points) - 1
        for index in range(intervals):
            following = (index + 1) % len(points)
            for side in range(sides):
                next_side = (side + 1) % sides
                faces.append((index * sides + side, index * sides + next_side,
                              following * sides + next_side, following * sides + side))
        if not closed:
            faces.extend([tuple(reversed(range(sides))),
                          tuple((len(points) - 1) * sides + i for i in range(sides))])
        self.add(vertices, faces, color, smooth=True)

    def profile(self, rings, sides=8, color="Stone", center=(0, 0, 0), colors=None, smooth=False):
        """Closed octagonal/round vertical profile with deliberate band heights."""
        rotation = math.pi / sides
        vertices = []
        for z, radius in rings:
            for side in range(sides):
                angle = rotation + 2 * math.pi * side / sides
                vertices.append((center[0] + radius * math.cos(angle),
                                 center[1] + radius * math.sin(angle), center[2] + z))
        faces = [(level * sides + side, level * sides + (side + 1) % sides,
                  (level + 1) * sides + (side + 1) % sides, (level + 1) * sides + side)
                 for level in range(len(rings) - 1) for side in range(sides)]
        faces.extend([tuple(reversed(range(sides))),
                      tuple((len(rings) - 1) * sides + i for i in range(sides))])
        first_face = len(self.faces)
        self.add(vertices, faces, color, smooth)
        if colors:
            self.colors[first_face:] = [level_color for level_color in colors for _ in range(sides)] + [color, color]
        self.smooth[-2:] = [False, False]

    def transformed(self, source, angle=0, offset=(0, 0, 0)):
        cosine, sine = math.cos(angle), math.sin(angle)
        vertices = [(cosine * x - sine * y + offset[0],
                     sine * x + cosine * y + offset[1], z + offset[2])
                    for x, y, z in source.vertices]
        first = len(self.faces)
        self.add(vertices, source.faces)
        self.colors[first:] = source.colors
        self.smooth[first:] = source.smooth


def _pointed(width, height, base=0.0, samples=20):
    half = width / 2
    shoulder = height * 0.64
    peak = height - shoulder
    points = [(-half, base), (half, base), (half, base + shoulder)]
    for i in range(1, samples + 1):
        theta = math.pi / 3 * i / samples
        points.append((-half + width * math.cos(theta),
                       base + shoulder + peak * math.sin(theta) / math.sin(math.pi / 3)))
    for i in range(samples - 1, -1, -1):
        theta = math.pi / 3 * i / samples
        points.append((half - width * math.cos(theta),
                       base + shoulder + peak * math.sin(theta) / math.sin(math.pi / 3)))
    return points


def _path(outline, y, x_offset=0):
    return [(x + x_offset, y, z) for x, z in outline]


def _object(collection, name, geometry, materials, bevel=0.06, notes=""):
    assert geometry.vertices and geometry.faces
    assert all(math.isfinite(value) for vertex in geometry.vertices for value in vertex)
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(geometry.vertices, [], geometry.faces)
    mesh.validate(verbose=False)
    mesh.update(calc_edges=True)
    keys = list(dict.fromkeys(geometry.colors))
    for key in keys:
        mesh.materials.append(materials[key])
    for face, color, smooth in zip(mesh.polygons, geometry.colors, geometry.smooth):
        face.material_index = keys.index(color)
        face.use_smooth = smooth
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    uv = mesh.uv_layers.new(name="MC_SharedSurfaceUV")
    for face in mesh.polygons:
        normal = face.normal
        axis = max(range(3), key=lambda index: abs(normal[index]))
        planar = (1, 2) if axis == 0 else (0, 2) if axis == 1 else (0, 1)
        for loop_index in face.loop_indices:
            vertex = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            uv.data[loop_index].uv = (vertex[planar[0]] / 8, vertex[planar[1]] / 8)
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = (0, 0, 0)
    obj["AssetKey"] = name
    obj["Role"] = "Decoration"
    obj["Build"] = "MC_P1_BL01"
    obj["Units"] = "1 Blender unit = 1 intended stud; Z up; front -Y"
    obj["LocalOrigin"] = "Base Z=0; origin X/Y=0"
    obj["MountingNotes"] = notes
    obj["ExportApplyModifiers"] = True
    if bevel:
        modifier = obj.modifiers.new("Small edge highlights", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        modifier.angle_limit = math.radians(38)
        modifier.use_clamp_overlap = True
    return obj


def _window_frame():
    geometry = _Mesh()
    geometry.ring(_pointed(24, 58), _pointed(19.6, 54.6, 1.2), -0.42, 1.4, "Stone")
    geometry.ring(_pointed(22.8, 56.8, 0.55), _pointed(21.25, 54.9, 1.25), -0.88, -0.31, "StoneLight")
    geometry.ring(_pointed(20.65, 55, 1.15), _pointed(19.6, 54.1, 1.4), -1.03, 0.2, "StoneDark")
    geometry.tube(_path(_pointed(23.05, 56.85, 0.52), -0.92), 0.23, "StoneLight", sides=8, closed=True)
    geometry.box((0, 0.02, 0.57), (24, 2.72, 1.14), "StoneLight")
    return geometry


def _window_tracery():
    geometry = _Mesh()
    for center in (-4.72, 4.72):
        geometry.tube(_path(_pointed(8.35, 37.7, 2.25), -0.34, center), 0.27, "Brass", closed=True)
        for z in (10.5, 22, 30.2):
            diamond = [(center, -0.41, z - 4.0), (center + 2.45, -0.41, z),
                       (center, -0.41, z + 4.0), (center - 2.45, -0.41, z)]
            geometry.tube(diamond, 0.064, "Brass", sides=6, closed=True)
    geometry.tube([(0, -0.38, 1.5), (0, -0.38, 40)], 0.31, "Brass")
    flower = []
    for i in range(64):
        theta = 2 * math.pi * i / 64
        radius = 3.45 * (1 + 0.21 * math.cos(4 * theta))
        flower.append((radius * math.cos(theta), -0.36, 45.6 + radius * math.sin(theta)))
    geometry.tube(flower, 0.29, "Brass", sides=8, closed=True)
    geometry.tube(_path(_pointed(18.95, 53.35, 1.7), -0.19), 0.12, "Brass", sides=8, closed=True)
    return geometry


def _stone_arch():
    geometry = _Mesh()
    samples = 40
    outer = [(-12 * math.cos(math.pi * i / samples), 17 * math.sin(math.pi * i / samples))
             for i in range(samples + 1)]
    inner = [(-10 * math.cos(math.pi * i / samples), 14.5 * math.sin(math.pi * i / samples))
             for i in range(samples + 1)]
    geometry.arc_strip(outer, inner, -2, 2, "Stone")
    trim_outer = [(-11.75 * math.cos(math.pi * i / samples), 16.8 * math.sin(math.pi * i / samples))
                  for i in range(samples + 1)]
    trim_inner = [(-11.27 * math.cos(math.pi * i / samples), 16.2 * math.sin(math.pi * i / samples))
                  for i in range(samples + 1)]
    for front, back in ((-2.12, -1.96), (1.96, 2.12)):
        geometry.arc_strip(trim_outer, trim_inner, front, back, "StoneLight")
    return geometry


def _turret_stone():
    geometry = _Mesh()
    conversion = 1 / (2 * math.cos(math.pi / 8))
    widths = [(0, 7), (0.55, 7), (0.8, 6.6), (1.1, 6.4),
              (11.7, 6.4), (11.9, 6.85), (12.3, 6.85), (12.55, 6.4),
              (26.4, 6.4), (26.7, 7), (27.8, 7), (28, 6.75)]
    geometry.profile([(z, width * conversion) for z, width in widths], color="Stone")
    for angle in (0, math.pi / 2):
        surround = _Mesh()
        surround.ring(_pointed(2.56, 11.2, 14.2), _pointed(1.9, 10.55, 14.5), -3.48, -3.1, "StoneLight")
        surround.prism(_pointed(1.9, 10.55, 14.5), -3.23, -3.15, "StoneDark")
        surround.box((0, -3.38, 14.35), (2.72, 0.8, 0.45), "StoneLight")
        geometry.transformed(surround, angle)
    return geometry


def _slate_spire():
    geometry = _Mesh()
    flat_radius = 4 / math.cos(math.pi / 8)
    profile = [(0, 1), (0.25, 1), (0.62, 0.945), (2.5, 0.78), (5, 0.58),
               (7.5, 0.42), (10, 0.29), (12.5, 0.19), (15, 0.10),
               (17.35, 0.024), (18, 0.006)]

    def radius_at(z):
        for (a, ra), (b, rb) in zip(profile, profile[1:]):
            if a <= z <= b:
                return flat_radius * (ra + (rb - ra) * (z - a) / (b - a))
        raise ValueError("Spire profile height out of range")

    levels = {z: radius * flat_radius for z, radius in profile}
    bands = (3.5, 6.5, 9.5, 12.5)
    for z in bands:
        levels[z - 0.06] = radius_at(z - 0.06)
        levels[z] = radius_at(z) + 0.035
        levels[z + 0.06] = radius_at(z + 0.06)
    rings = sorted(levels.items())
    colors = []
    for (z, _), (next_z, _) in zip(rings, rings[1:]):
        center = (z + next_z) / 2
        colors.append("Brass" if z >= 17.35 else "SlateBand" if any(abs(center - band) <= 0.061 for band in bands) else "Slate")
    geometry.profile(rings, color="Slate", colors=colors, smooth=False)
    return geometry


def _balustrade_stone():
    geometry = _Mesh()
    geometry.box((0, 0, 0.28), (18, 0.88, 0.56), "Stone")
    geometry.box((0, 0, 0.57), (18, 1.02, 0.16), "StoneLight")
    for x in (-8.525, 8.525):
        geometry.box((x, 0, 1.55), (0.66, 0.7, 1.8), "Stone")
        geometry.box((x, 0, 0.83), (0.84, 0.86, 0.3), "StoneLight")
        geometry.box((x, 0, 2.5), (0.84, 0.86, 0.24), "StoneLight")
        geometry.box((x, 0, 2.86), (0.95, 1.02, 0.28), "StoneLight")
    return geometry


def _balustrade_iron():
    geometry = _Mesh()
    for center in (-6.075, -2.025, 2.025, 6.075):
        geometry.tube(_path(_pointed(3.85, 2.07, 0.64, samples=10), 0, center), 0.075, "Iron", sides=6, closed=True)
    for x in (-8.1, -4.05, 0, 4.05, 8.1):
        geometry.tube([(x, 0, 0.61), (x, 0, 2.81)], 0.07, "Iron", sides=8)
    geometry.box((0, 0, 2.86), (16.5, 0.23, 0.18), "Brass")
    geometry.box((0, 0, 0.75), (16.5, 0.18, 0.12), "Iron")
    return geometry


def build_library(collection):
    """Return eight independent material/edit units without changing the scene setup."""
    materials = _materials()
    glass = _Mesh()
    glass.prism(_pointed(19.25, 53.65, 1.65), 0.08, 0.26, "Amber")
    recipes = [
        ("MC_WindowFrame", _window_frame(), 0.085, "24 wide x 58 high; base Z=0. Match Tracery/Glass at the same origin. Front -Y."),
        ("MC_WindowTracery", _window_tracery(), 0.018, "Same origin as WindowFrame. Two lancets, quatrefoil and restrained lead diamonds; front -Y."),
        ("MC_WindowGlass", glass, 0.025, "Inset opaque warm pane matching the curved pointed opening; same origin as frame."),
        ("MC_StoneArch", _stone_arch(), 0.09, "24 wide; outer crown Z=17; main depth 4, shallow fascia adds 0.24. Hidden contacts must follow the real curved top."),
        ("MC_TurretStone", _turret_stone(), 0.06, "7 wide stone bands; shaft height 28. Two small stone surrounds/shadow recesses; small amber inserts may be placed separately."),
        ("MC_SlateSpire", _slate_spire(), 0.035, "8 wide x 18 high, octagonal taper; base Z=0. Mount at turret Z=28, not at shaft origin."),
        ("MC_BalustradeStone", _balustrade_stone(), 0.06, "18 long along X; base Z=0, height 3. Paired origin with Iron; do not span a transfer edge."),
        ("MC_BalustradeIron", _balustrade_iron(), 0.015, "Paired origin with Stone. Broad pointed iron openings, slim uprights and brass handrail."),
    ]
    return [_object(collection, name, geometry, materials, bevel, notes)
            for name, geometry, bevel, notes in recipes]
