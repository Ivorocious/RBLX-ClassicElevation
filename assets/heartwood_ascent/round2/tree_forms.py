"""Three independent Heartwood studies. Run only in a headless Blender process.

Blender -b --factory-startup --python tree_forms.py -- --variant braided_windows
    --output-dir PATH --detail study
One Blender unit is one stud. Geometry uses Blender Z-up; manifest includes Roblox Y-up.
"""

from pathlib import Path
import argparse
from collections import Counter
import hashlib
import json
import math
import random
import sys

import bpy
import bmesh
from mathutils import Vector
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tree_materials import PALETTE, make_materials, tile_uv, write_atlases


VARIANTS = ("braided_windows", "cathedral_fan", "windswept_split")


class Geometry:
    def __init__(self):
        self.vertices, self.faces, self.colours, self.uvs = [], [], [], []

    def add(self, vertices, faces, colours, uvs=None):
        offset = len(self.vertices)
        self.vertices.extend(tuple(p) for p in vertices)
        self.faces.extend(tuple(offset + index for index in face) for face in faces)
        self.colours.extend(colours if isinstance(colours, list) else [colours] * len(faces))
        self.uvs.extend(uvs if uvs is not None else [None] * len(faces))

    def sweep(self, points, radii, colour=0, sides=16, steps=5, relief=.045):
        ps, rs = smooth_path(points, radii, steps)
        verts, faces, colours, uvs = [], [], [], []
        old_side = None
        for j, (point, radius) in enumerate(zip(ps, rs)):
            tangent = (ps[min(j + 1, len(ps) - 1)] - ps[max(0, j - 1)]).normalized()
            side = tangent.cross(Vector((0, 1, 0))) if old_side is None else old_side - tangent * old_side.dot(tangent)
            if side.length < .01:
                side = tangent.cross(Vector((1, 0, 0)))
            side.normalize()
            up = tangent.cross(side).normalized()
            old_side = side
            for i in range(sides):
                angle = math.tau * i / sides
                flute = 1 + relief * math.cos(angle * 5 + j * .10) + relief * .35 * math.sin(angle * 9 - j * .06)
                verts.append(point + radius * flute * (side * math.cos(angle) + up * math.sin(angle)))
        for j in range(len(ps) - 1):
            for i in range(sides):
                k = (i + 1) % sides
                faces.append((j * sides + i, j * sides + k, (j + 1) * sides + k, (j + 1) * sides + i))
                colours.append(colour if i % 11 else (1 if colour == 0 else colour))
                v0, v1 = (j % 8) / 8, ((j % 8) + 1) / 8
                uvs.append(((i / sides, v0), ((i + 1) / sides, v0), ((i + 1) / sides, v1), (i / sides, v1)))
        faces.extend((tuple(range(sides - 1, -1, -1)), tuple((len(ps) - 1) * sides + i for i in range(sides))))
        colours.extend((colour, colour))
        uvs.extend((None, None))
        self.add(verts, faces, colours, uvs)

    def leaf(self, base, length, width, yaw, colour=3, droop=.28, twist=0):
        """A closed broad leaf has a shaped edge, convex midrib, and visible underside."""
        base = Vector(base)
        direction = Vector((math.cos(yaw), math.sin(yaw), 0))
        side = Vector((-direction.y, direction.x, 0))
        rows, verts = 6, []
        thickness = max(.09, width * .025)
        for skin in (0, 1):
            for j in range(rows):
                t = j / (rows - 1)
                half = width * .5 * max(.035, math.sin(math.pi * t) ** .72)
                for k in (-1, 0, 1):
                    p = base + direction * length * t + side * half * k
                    p.z += length * (.14 * math.sin(math.pi * t) - droop * t * t)
                    p.z += width * .12 * (1 - abs(k)) * math.sin(math.pi * t) + twist * k * t
                    p.z -= skin * thickness
                    verts.append(p)
        layer = rows * 3
        faces, colours, uvs = [], [], []
        for j in range(rows - 1):
            for k in range(2):
                a = j * 3 + k
                faces.extend(((a, a + 1, a + 4, a + 3), (a + layer, a + layer + 3, a + layer + 4, a + layer + 1)))
                colours.extend((colour, 11 if colour in (3, 4, 5, 10) else colour))
                uv = ((k / 2, j / (rows - 1)), ((k + 1) / 2, j / (rows - 1)), ((k + 1) / 2, (j + 1) / (rows - 1)), (k / 2, (j + 1) / (rows - 1)))
                uvs.extend((uv, tuple(reversed(uv))))
            for k in (0, 2):
                a = j * 3 + k
                face = (a, a + 3, a + layer + 3, a + layer)
                faces.append(face if k == 0 else tuple(reversed(face)))
                colours.append(colour)
                uvs.append(None)
        faces.extend(((0, layer, layer + 1, 1), (1, layer + 1, layer + 2, 2),
                      (layer - 3, layer - 2, 2 * layer - 2, 2 * layer - 3),
                      (layer - 2, layer - 1, 2 * layer - 1, 2 * layer - 2)))
        colours.extend([colour] * 4)
        uvs.extend([None] * 4)
        self.add(verts, faces, colours, uvs)

    def box(self, centre, size, colour):
        c = Vector(centre)
        x, y, z = [value / 2 for value in size]
        verts = [c + Vector((a * x, b * y, d * z)) for a, b, d in
                 ((-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1),
                  (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1))]
        self.add(verts, ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
                         (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)), colour)

    def petal(self, base, length, width, yaw, lift, colour=6):
        base = Vector(base)
        direction = Vector((math.cos(yaw), math.sin(yaw), 0))
        side = Vector((-direction.y, direction.x, 0))
        rows, across, thickness = 11, 5, max(.12, width * .024)
        verts = []
        for skin in (0, 1):
            for j in range(rows):
                t = j / (rows - 1)
                half = width * .5 * max(.025, math.sin(math.pi * t) ** .72)
                centre_z = lift * t * t + length * .07 * math.sin(math.pi * t)
                for k in range(across):
                    s = 2 * k / (across - 1) - 1
                    p = base + direction * (length * t - length * .07 * t ** 4) + side * (half * s)
                    p.z += centre_z + width * .19 * abs(s) ** 1.7 * math.sin(math.pi * t)
                    p.z -= skin * thickness
                    verts.append(p)
        layer = rows * across
        faces, colours, uvs = [], [], []
        for j in range(rows - 1):
            for k in range(across - 1):
                a = j * across + k
                faces.extend(((a, a + 1, a + across + 1, a + across),
                              (a + layer, a + layer + across, a + layer + across + 1, a + layer + 1)))
                colours.extend((12 if j >= rows - 3 and colour == 7 else colour, colour))
                local = ((k / (across - 1), j / (rows - 1)), ((k + 1) / (across - 1), j / (rows - 1)),
                         ((k + 1) / (across - 1), (j + 1) / (rows - 1)), (k / (across - 1), (j + 1) / (rows - 1)))
                uvs.extend((local, tuple(reversed(local))))
            for k in (0, across - 1):
                a = j * across + k
                f = (a, a + across, a + layer + across, a + layer)
                faces.append(f if k == 0 else tuple(reversed(f)))
                colours.append(colour)
                uvs.append(None)
        for j in (0, rows - 1):
            for k in range(across - 1):
                a = j * across + k
                f = (a, a + layer, a + layer + 1, a + 1)
                faces.append(f if j == 0 else tuple(reversed(f)))
                colours.append(colour)
                uvs.append(None)
        self.add(verts, faces, colours, uvs)


def smooth_path(points, radii, steps):
    ps = [Vector(p) for p in points]
    dense, values = [], []
    for j in range(len(ps) - 1):
        p0, p1, p2, p3 = ps[max(0, j - 1)], ps[j], ps[j + 1], ps[min(len(ps) - 1, j + 2)]
        for k in range(steps):
            t = k / steps
            dense.append(.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                               + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t))
            values.append(radii[j] * (1 - t) + radii[j + 1] * t)
    dense.append(ps[-1])
    values.append(radii[-1])
    return dense, values


def design(variant):
    if variant == "braided_windows":
        trunks = [
            ([(-32, -7, 4), (-40, -12, 55), (-32, -15, 110), (-8, -12, 156), (27, -6, 204), (34, 4, 246), (9, 9, 287), (-20, 7, 329), (-12, 8, 370)], [28, 26, 22, 24, 23, 20, 19, 16, 8]),
            ([(34, 13, 4), (42, 14, 53), (36, 12, 105), (20, 13, 151), (-17, 18, 196), (-31, 13, 238), (-5, 7, 284), (29, 9, 331), (21, 9, 366)], [27, 24, 22, 21, 23, 22, 18, 15, 7]),
        ]
        branches = [
            ([(-39, -10, 68), (-62, -13, 88), (-87, -9, 107), (-95, -6, 128)], [16, 13, 9, 3]),
            ([(39, 13, 96), (64, 6, 113), (86, 1, 126), (98, 7, 145)], [16, 12, 8, 3]),
            ([(-14, 15, 202), (-43, 14, 228), (-72, 8, 247), (-92, -4, 254)], [21, 17, 12, 5]),
            ([(32, 4, 241), (65, 13, 259), (94, 18, 286), (113, 9, 304)], [18, 15, 9, 3]),
            ([(-7, 9, 286), (-39, 18, 308), (-72, 15, 330), (-104, 5, 341)], [17, 14, 9, 3]),
            ([(-19, 7, 326), (-29, -1, 351), (-47, -6, 373), (-51, -4, 386)], [14, 10, 7, 2]),
            ([(26, 10, 323), (43, 13, 347), (66, 10, 368), (75, 7, 380)], [15, 12, 8, 2]),
            ([(-12, 8, 354), (-9, 6, 375), (7, 8, 389)], [12, 8, 2]),
        ]
        crowns = [(-95, -6, 132, 25), (98, 7, 149, 27), (-82, 13, 254, 25),
                  (113, 9, 307, 35), (81, 23, 284, 25), (-104, 5, 345, 35),
                  (-67, 21, 326, 27), (-51, -4, 389, 29), (75, 7, 383, 31),
                  (7, 8, 391, 29), (27, 34, 353, 25)]
        flower, close = (-91, -6, 263), (-83, -9, 263)
        note = "Two stems exchange sides twice. Lower, middle and upper windows remain separate, with alternating asymmetrical side crowns."
    elif variant == "cathedral_fan":
        trunks = [
            ([(-36, -12, 3), (-43, -17, 42), (-42, -17, 86), (-24, -9, 133), (-9, 0, 167), (-15, 6, 209), (-45, 8, 248), (-60, 10, 282)], [30, 27, 25, 25, 28, 25, 21, 10]),
            ([(36, -12, 3), (43, -17, 46), (39, -16, 90), (20, -7, 136), (9, 4, 178), (19, 7, 225), (43, 12, 267), (65, 13, 302)], [29, 27, 25, 26, 28, 25, 20, 8]),
            ([(0, 35, 3), (-2, 39, 48), (4, 35, 99), (4, 28, 153), (2, 22, 207), (-6, 17, 263), (2, 15, 312), (-9, 18, 370)], [28, 27, 25, 28, 26, 21, 16, 6]),
        ]
        branches = [
            ([(-42, -15, 84), (-67, -21, 109), (-88, -12, 129)], [16, 11, 3]),
            ([(35, -14, 103), (69, -5, 131), (88, 7, 157)], [17, 11, 3]),
            ([(-13, 1, 201), (-45, 0, 229), (-73, -4, 247), (-93, -10, 254)], [21, 17, 13, 5]),
            ([(-42, 8, 243), (-71, 7, 270), (-95, 4, 291), (-123, -1, 308)], [20, 16, 10, 3]),
            ([(41, 11, 261), (69, 16, 286), (95, 12, 319), (116, 7, 340)], [20, 16, 10, 3]),
            ([(-52, 10, 269), (-54, 15, 297), (-37, 18, 329), (-33, 17, 346)], [13, 11, 7, 2]),
            ([(50, 13, 278), (47, 17, 309), (24, 18, 349), (31, 17, 373)], [14, 12, 8, 3]),
            ([(-3, 15, 305), (-29, 10, 340), (-36, 6, 368), (-25, 3, 387)], [16, 12, 7, 2]),
            ([(1, 15, 317), (19, 28, 347), (59, 32, 364), (75, 27, 375)], [14, 11, 8, 2]),
        ]
        crowns = [(-88, -12, 132, 25), (88, 7, 160, 27), (-80, 7, 254, 26),
                  (-123, -1, 312, 32), (-82, 14, 291, 27), (116, 7, 344, 33),
                  (84, 21, 322, 27), (-33, 17, 350, 30), (31, 17, 376, 28),
                  (-25, 3, 390, 30), (75, 27, 378, 29), (-9, 18, 374, 24)]
        flower, close = (-92, -12, 263), (-85, -14, 263)
        note = "Three rooted piers enclose a lower chamber; the upper trunk opens into a spreading fan with a taller rear leader."
    else:
        trunks = [
            ([(-15, -8, 4), (-24, -14, 55), (-29, -10, 105), (-17, -5, 155), (9, 2, 208), (36, 9, 255), (55, 12, 300), (66, 12, 346), (76, 9, 375)], [34, 31, 27, 28, 28, 24, 20, 14, 5]),
            ([(55, 17, 4), (68, 18, 55), (61, 20, 105), (17, 22, 157), (-38, 20, 203), (-28, 13, 235), (11, 8, 253)], [28, 26, 24, 23, 22, 17, 7]),
        ]
        branches = [
            ([(-27, -10, 94), (-57, -18, 112), (-84, -9, 130)], [17, 12, 3]),
            ([(29, 17, 95), (61, 9, 121), (91, 1, 143)], [16, 11, 3]),
            ([(-37, 19, 206), (-59, 8, 233), (-79, -3, 247), (-99, -10, 254)], [21, 17, 12, 5]),
            ([(34, 8, 252), (69, 9, 272), (109, 8, 290), (137, -2, 305)], [20, 16, 10, 3]),
            ([(49, 13, 285), (25, 27, 307), (0, 32, 327), (-29, 25, 339)], [18, 14, 10, 3]),
            ([(58, 13, 307), (95, 15, 334), (120, 8, 358), (140, 0, 375)], [16, 13, 8, 2]),
            ([(65, 12, 337), (43, 19, 357), (36, 17, 380)], [14, 10, 2]),
            ([(75, 10, 364), (100, 7, 380), (117, 3, 389)], [11, 8, 2]),
        ]
        crowns = [(-84, -9, 134, 24), (91, 1, 147, 26), (-84, 8, 254, 26),
                  (137, -2, 309, 35), (102, 17, 292, 28), (-29, 25, 343, 31),
                  (2, 32, 326, 26), (140, 0, 378, 31), (105, 20, 359, 27),
                  (36, 17, 383, 29), (117, 3, 392, 30), (76, 9, 378, 24)]
        flower, close = (-98, -12, 263), (-91, -14, 263)
        note = "A leaning main stem and returning side stem frame an off-centre hollow. Upper limbs continue east while the flower rests west."
    return trunks, branches, crowns, flower, close, note


def selected_braid_design():
    trunks = [
        ([(-32, -7, 3), (-42, -10, 50), (-35, -14, 101), (-10, -11, 154), (28, -4, 202),
          (35, 4, 245), (10, 9, 286), (-21, 8, 328), (-16, 8, 363), (-29, 11, 387), (-32, 15, 397)],
         [34, 30, 24, 29, 31, 25, 23, 20, 12, 5, .6]),
        ([(37, 14, 3), (46, 14, 52), (43, 12, 105), (24, 15, 151), (-16, 19, 199),
          (-35, 14, 238), (-8, 8, 282), (28, 10, 330), (26, 14, 366), (44, 14, 384), (56, 18, 391)],
         [32, 29, 24, 27, 29, 25, 23, 19, 10, 4, .5]),
    ]
    branches = [
        ([(-41, -10, 75), (-60, -11, 95), (-86, -4, 116), (-105, 3, 125)], [19, 14, 7, .5]),
        ([(45, 12, 112), (64, 4, 129), (88, 1, 140), (111, 8, 153)], [20, 13, 7, .4]),
        ([(-18, 17, 200), (-43, 16, 228), (-70, 9, 249), (-94, -4, 256), (-102, -8, 262)], [24, 20, 15, 8, 1]),
        ([(33, 5, 239), (63, 12, 268), (82, 11, 294), (108, 4, 316), (123, 6, 331)], [24, 19, 13, 7, .5]),
        ([(-11, 9, 284), (-39, 19, 305), (-61, 16, 328), (-83, 11, 349), (-103, 6, 357)], [23, 18, 13, 7, .5]),
        ([(-21, 8, 328), (-39, 5, 351), (-55, 0, 373), (-60, -1, 387)], [18, 13, 7, .4]),
        ([(26, 10, 323), (54, 13, 342), (84, 10, 361), (103, 12, 373)], [19, 14, 8, .4]),
        ([(9, 8, 289), (10, 30, 319), (4, 42, 347), (-9, 39, 368)], [17, 13, 7, .4]),
        ([(-61, 16, 328), (-78, 35, 339), (-91, 41, 352)], [11, 7, .4]),
        ([(82, 11, 294), (75, 31, 312), (62, 37, 333)], [11, 7, .4]),
        ([(-29, 11, 386), (-8, 3, 397), (10, 0, 401)], [7, 4, .4]),
    ]
    return trunks, branches, [], (-98, -7, 263), (-10, -105, 0), (
        "Selected braid revision 02: changing growth width, one broad asymmetric root arch, "
        "fused wood, three irregular crown masses and a western cupped flower below continuing leaders.")


class Builder:
    def __init__(self, args):
        self.args = args
        self.output = Path(args.output_dir).resolve()
        self.output.mkdir(parents=True, exist_ok=True)
        self.selected = args.detail == "selected"
        self.selected_braid = self.selected and args.variant == "braided_windows"
        self.rng = random.Random(42173 + VARIANTS.index(args.variant))
        self.prefix = "HA2_" + args.variant
        self.scene = bpy.data.scenes.new(self.prefix + "_OwnedStudy")
        if bpy.context.window is None:
            raise RuntimeError("This Blender process has no window context for the owned headless scene")
        bpy.context.window.scene = self.scene
        self.collection = bpy.data.collections.new(self.prefix + "_EditableTree")
        self.scene.collection.children.link(self.collection)
        self.preview = bpy.data.collections.new(self.prefix + "_PreviewOnly")
        self.scene.collection.children.link(self.preview)
        self.colour_path, self.roughness_path, self.atlas_size = write_atlases(self.output, self.selected)
        self.material, self.clay = make_materials(bpy, self.colour_path, self.roughness_path, self.prefix)
        self.objects, self.packages, self.records = [], {}, []
        self.wood_paths, self.editable_source_records = [], []
        self.import_source_records, self.chunk_checks = [], []

    def object(self, name, geometry, package="structure", preview=False):
        mesh = bpy.data.meshes.new(self.prefix + "_" + name)
        mesh.from_pydata(geometry.vertices, [], geometry.faces)
        mesh.update()
        obj = bpy.data.objects.new(self.prefix + "_" + name, mesh)
        (self.preview if preview else self.collection).objects.link(obj)
        mesh.materials.append(self.material)
        uv = mesh.uv_layers.new(name="RobloxAtlasUV")
        for polygon, colour, local_uv in zip(mesh.polygons, geometry.colours, geometry.uvs):
            for k, loop_index in enumerate(polygon.loop_indices):
                uv.data[loop_index].uv = tile_uv(colour, *(local_uv[k] if local_uv else (.5, .5)), self.atlas_size)
            polygon.use_smooth = len(polygon.vertices) == 4 and package != "preview"
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(mesh)
        bm.free()
        mesh.calc_loop_triangles()
        if not mesh.vertices or any(not math.isfinite(v) for vertex in mesh.vertices for v in vertex.co):
            raise ValueError(name + " contains missing or non-finite geometry")
        if any(p.area < 1e-9 for p in mesh.polygons):
            raise ValueError(name + " contains a degenerate face")
        edge_uses = Counter(tuple(sorted((face[i], face[(i + 1) % len(face)])))
                            for face in geometry.faces for i in range(len(face)))
        bad_edges = sum(count != 2 for count in edge_uses.values())
        if bad_edges:
            raise ValueError(name + " contains " + str(bad_edges) + " open/non-manifold edges")
        obj["Round2Variant"] = self.args.variant
        obj["Role"] = package
        obj["NoRouteCollisionPromise"] = True
        if not preview:
            lo = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
            hi = [max(v.co[i] for v in mesh.vertices) for i in range(3)]
            centre = [(a + b) / 2 for a, b in zip(lo, hi)]
            size = [b - a for a, b in zip(lo, hi)]
            self.records.append({"name": obj.name, "package": package, "vertices": len(mesh.vertices),
                                 "triangles": len(mesh.loop_triangles), "bounds_min_blender": lo,
                                 "bounds_max_blender": hi, "center_blender": centre, "size_blender": size,
                                 "center_roblox": [centre[0], centre[2], -centre[1]],
                                 "size_roblox": [size[0], size[2], size[1]],
                                 "open_or_nonmanifold_edges": bad_edges,
                                 "collision_intent": "visible mesh only; route clearance/collision remains untested" if package == "structure" else "decorative; CanCollide=false"})
            self.objects.append(obj)
            self.packages.setdefault(package, []).append(obj)
        return obj

    def branch(self, name, points, radii, colour=0):
        geo = Geometry()
        steps = 7 if self.selected else 5
        geo.sweep(points, radii, colour, 24 if self.selected else 16, steps,
                  .055 if self.selected else .035)
        samples, _ = smooth_path(points, radii, steps)
        for j, point in enumerate(samples):
            tangent = (samples[min(j + 1, len(samples) - 1)] - samples[max(0, j - 1)]).normalized()
            self.wood_paths.append((point, tangent))
        return self.object(name, geo)

    def crown(self, name, centre, radius, small=False):
        geo = Geometry()
        centre = Vector(centre)
        per_tier = (27 if self.selected else 14) if not small else (14 if self.selected else 9)
        tiers = 4 if not small else 3
        for tier in range(tiers):
            tier_radius = radius * (.35 + tier * .20)
            tier_z = radius * (.32 - tier * .19)
            count = round(per_tier * (.8 + tier * .18))
            for j in range(count):
                yaw = math.tau * j / count + tier * .29 + self.rng.uniform(-.10, .10)
                start_radius = tier_radius * self.rng.uniform(.26, .53)
                p = centre + Vector((math.cos(yaw) * start_radius, math.sin(yaw) * start_radius,
                                      tier_z + self.rng.uniform(-radius * .06, radius * .06)))
                length = radius * self.rng.uniform(.43, .66)
                colour = (4, 3, 3, 5)[(j + tier) % 4]
                geo.leaf(p, length, length * self.rng.uniform(.55, .75), yaw, colour,
                         droop=.12 + tier * .045, twist=self.rng.uniform(-.6, .6))
        # Tapered sprays break the edge and bring the shade down below the main tiers.
        for j in range(5 if not small else 3):
            yaw = math.tau * j / (5 if not small else 3) + .27
            for k in range(3 if self.selected else 2):
                p = centre + Vector((math.cos(yaw) * radius * (.58 + k * .10),
                                      math.sin(yaw) * radius * (.58 + k * .10), -radius * (.19 + k * .16)))
                length = radius * (.38 - k * .055)
                geo.leaf(p, length, length * .65, yaw + .25 * (-1 if k % 2 else 1), 4 if k % 2 else 3, .5)
        self.object(name, geo, "foliage")
        twig = Geometry()
        for j in range(5):
            yaw = math.tau * j / 5 + .3
            twig.sweep([centre + Vector((0, 0, -radius * .4)), centre + Vector((math.cos(yaw) * radius * .28, math.sin(yaw) * radius * .28, -radius * .10)),
                        centre + Vector((math.cos(yaw) * radius * .6, math.sin(yaw) * radius * .6, -radius * .17))],
                       [radius * .055, radius * .028, .24], 0, 8, 3, 0)
        self.object(name + "_Twigs", twig, "branches")

    def roots(self, trunks):
        if self.selected_braid:
            roots = [
                ([(-33, -7, 18), (-53, -31, 23), (-80, -43, 12), (-116, -49, 1)], [29, 24, 15, 3]),
                ([(37, 13, 14), (57, -11, 21), (81, -34, 12), (113, -43, 1)], [28, 22, 14, 3]),
                ([(-30, -2, 18), (-54, 29, 20), (-83, 49, 8), (-107, 66, 1)], [26, 22, 13, 3]),
                ([(35, 15, 16), (55, 43, 18), (69, 75, 9), (71, 112, 1)], [28, 23, 13, 3]),
                ([(-34, -10, 16), (-56, -58, 30), (-40, -86, 57), (-5, -91, 68), (29, -74, 51), (46, -44, 25), (38, 12, 14)], [27, 20, 14, 11, 15, 22, 28]),
                ([(-16, 7, 16), (-28, 39, 20), (-16, 76, 8), (-2, 108, 1)], [23, 18, 10, 2.6]),
            ]
            for j, (points, radii) in enumerate(roots):
                self.branch("SweepingRoot_%02d" % j, points, radii)
            return
        for j in range(8):
            yaw = math.tau * j / 8 + .12
            source = min((Vector(ps[0]) for ps, _ in trunks), key=lambda p: (p.x - math.cos(yaw) * 50) ** 2 + (p.y - math.sin(yaw) * 50) ** 2)
            distance = (108, 96, 88, 112, 109, 104, 91, 111)[j]
            arch = (13, 9, 15, 28, 16, 11, 28, 9)[j]
            points = [source + Vector((math.cos(yaw) * 6, math.sin(yaw) * 6, 8)),
                      Vector((math.cos(yaw - .13) * 48, math.sin(yaw - .13) * 48, arch)),
                      Vector((math.cos(yaw + .13) * 76, math.sin(yaw + .13) * 76, arch * .68)),
                      Vector((math.cos(yaw + .17) * distance, math.sin(yaw + .17) * distance, 1.5))]
            self.branch("Root_%02d" % j, points, [22, 17, 10, 1.4])
        if self.args.variant == "cathedral_fan":
            # The arch frames a large lower-front entry rather than adding repeated rungs.
            self.branch("FrontRootArch", [(-36, -12, 10), (-50, -42, 31), (-39, -69, 59),
                                           (0, -79, 70), (38, -66, 55), (49, -40, 29), (36, -12, 10)],
                        [20, 15, 12, 10, 12, 15, 20])

    def growth_ridges(self, trunks):
        configurations = ((0, 0, 3, -.15, 2.8), (0, 2, 5, .18, 2.1),
                          (1, 0, 3, .28, 3.3), (1, 4, 7, -.22, 2.4))
        for j, (stem, first, last, drift, width) in enumerate(configurations):
            points, radii = trunks[stem]
            ridge, sizes = [], []
            for k in range(first, last + 1):
                p = Vector(points[k])
                angle = -math.pi / 2 + drift + .2 * math.sin(k * 1.1 + j)
                p += Vector((math.cos(angle) * radii[k] * .97, math.sin(angle) * radii[k] * .97, 0))
                ridge.append(p)
                sizes.append(width * (.26 + .74 * math.sin(math.pi * (k - first + .25) / (last - first + .5))))
            self.branch("GrowthFold_%02d" % j, ridge, sizes, 2 if j == 1 else 0)

    def irregular_crown(self, name, lobes, lower=False):
        geo, twig = Geometry(), Geometry()
        for lobe_index, (x, y, z, radius) in enumerate(lobes):
            centre = Vector((x, y, z))
            tiers = 3 if lower else 4
            for tier in range(tiers):
                count = (9 if lower else 13) + tier * 4
                span = radius * (.25 + .16 * tier)
                height = radius * (.36 - .21 * tier)
                for j in range(count):
                    yaw = math.tau * j / count + lobe_index * .72 + tier * .38 + self.rng.uniform(-.16, .16)
                    spread = span * self.rng.uniform(.36, .72)
                    p = centre + Vector((math.cos(yaw) * spread, math.sin(yaw) * spread,
                                          height + self.rng.uniform(-radius * .09, radius * .09)))
                    length = radius * self.rng.uniform(.40, .68)
                    geo.leaf(p, length, length * self.rng.uniform(.52, .76), yaw,
                             (3, 4, 3, 5, 3)[(j + tier + lobe_index) % 5],
                             droop=.10 + tier * .075, twist=self.rng.uniform(-1.2, 1.2))
            for j in range(5 if lower else 8):
                yaw = math.tau * j / (5 if lower else 8) + lobe_index * .51
                anchor = centre + Vector((math.cos(yaw) * radius * .68, math.sin(yaw) * radius * .68, -radius * .16))
                for k in range(3):
                    p = anchor + Vector((math.cos(yaw) * radius * k * .08, math.sin(yaw) * radius * k * .08, -radius * k * .13))
                    length = radius * (.38 - .055 * k)
                    geo.leaf(p, length, length * .64, yaw + .31 * (-1 if k % 2 else 1), 3 if k == 0 else 4, .46)
                twig.sweep([centre - Vector((0, 0, radius * .40)), anchor - Vector((0, 0, radius * .12)),
                            anchor + Vector((math.cos(yaw) * radius * .16, math.sin(yaw) * radius * .16, -radius * .48))],
                           [radius * .058, radius * .027, .22], 0, 8, 3, 0)
        self.object(name, geo, "foliage")
        self.object(name + "_FringeTwigs", twig, "branches")

    def fuse_core(self):
        """Voxel fusion is optional; original growth pieces remain editable in a hidden collection."""
        if not self.args.fuse_core:
            return
        sources = list(self.packages["structure"])
        vertices, faces = [], []
        for obj in sources:
            offset = len(vertices)
            vertices.extend(tuple(v.co) for v in obj.data.vertices)
            faces.extend(tuple(offset + i for i in p.vertices) for p in obj.data.polygons)
        work_mesh = bpy.data.meshes.new(self.prefix + "_FusionWork")
        work_mesh.from_pydata(vertices, [], faces)
        work_mesh.update()
        work = bpy.data.objects.new(self.prefix + "_FusionWork", work_mesh)
        self.collection.objects.link(work)
        modifier = work.modifiers.new("BoundedOrganicJoin", "REMESH")
        modifier.mode = "VOXEL"
        modifier.voxel_size = self.args.fusion_voxel_size
        modifier.use_smooth_shade = True
        evaluated = work.evaluated_get(bpy.context.evaluated_depsgraph_get())
        fused = evaluated.to_mesh()
        fused.calc_loop_triangles()
        if len(fused.loop_triangles) > self.args.fusion_max_triangles:
            evaluated.to_mesh_clear()
            bpy.data.objects.remove(work, do_unlink=True)
            raise ValueError("Fusion exceeds the explicit triangle ceiling; raise voxel size or omit --fuse-core")
        geo = Geometry()
        geo.vertices = [tuple(v.co) for v in fused.vertices]
        geo.faces = [tuple(p.vertices) for p in fused.polygons]
        tree = KDTree(len(self.wood_paths))
        for j, (point, _) in enumerate(self.wood_paths):
            tree.insert(point, j)
        tree.balance()
        for polygon in fused.polygons:
            _, index, _ = tree.find(polygon.center)
            point, tangent = self.wood_paths[index]
            side = tangent.cross(Vector((0, 1, 0)))
            if side.length < .01:
                side = tangent.cross(Vector((1, 0, 0)))
            side.normalize()
            up = tangent.cross(side).normalized()
            local = [Vector(geo.vertices[i]) - point for i in polygon.vertices]
            us = [.5 + math.atan2(p.dot(up), p.dot(side)) / math.tau for p in local]
            if max(us) - min(us) > .5:
                us = [u + 1 if u < .5 else u for u in us]
            mid_v = polygon.center.dot(tangent) % 18 / 18
            geo.uvs.append(tuple((u % 1, max(0, min(1, mid_v + p.dot(tangent) / 18))) for u, p in zip(us, local)))
            geo.colours.append(0)
        evaluated.to_mesh_clear()
        bpy.data.objects.remove(work, do_unlink=True)
        source_names = {obj.name for obj in sources}
        self.editable_source_records = [r for r in self.records if r["name"] in source_names]
        self.records = [r for r in self.records if r["name"] not in source_names]
        self.objects = [obj for obj in self.objects if obj.name not in source_names]
        self.packages["structure"] = []
        editable = bpy.data.collections.new(self.prefix + "_EditableGrowthSources")
        self.scene.collection.children.link(editable)
        editable.hide_render = True
        editable.hide_viewport = True
        for obj in sources:
            self.collection.objects.unlink(obj)
            editable.objects.link(obj)
            obj["EditableSourceOnly"] = True
        self.object("OrganicWoodCore", geo)

    def flower(self, centre, scale=1, name="WesternFlower"):
        geo = Geometry()
        centre = Vector(centre)
        if self.selected_braid:
            geo.sweep([centre - Vector((0, 0, 2 * scale)), centre - Vector((0, 0, .6 * scale))], [3.8 * scale, 4.8 * scale], 8, 20, 2, 0)
            for tier, count, length, width, lift in ((0, 9, 13, 8.7, 4), (1, 7, 10.5, 7.2, 6.2)):
                for j in range(count):
                    yaw = math.tau * j / count + tier * .42 + .05 * math.sin(j * 2)
                    p = centre + Vector((math.cos(yaw) * 1.5 * scale, math.sin(yaw) * 1.5 * scale, (-.4 + tier * .4) * scale))
                    geo.petal(p, length * scale, width * scale, yaw, lift * scale,
                              6 if (j + tier) % 3 else 7)
            for j in range(13):
                yaw = j * 2.399963
                r = 3.3 * math.sqrt((j + .5) / 13) * scale
                p = centre + Vector((math.cos(yaw) * r, math.sin(yaw) * r, -.2 * scale))
                geo.sweep([p, p + Vector((0, 0, 1.2 * scale))], [.13 * scale, .25 * scale], 8, 6, 1, 0)
            self.object(name, geo, "flowers")
            return
        geo.sweep([centre - Vector((0, 0, 3.2)), centre - Vector((0, 0, .6))], [7, 10], 7, 32, 2, 0)
        for tier, count, length, width in ((0, 11, 16, 10), (1, 8, 12, 9)):
            for j in range(count):
                yaw = math.tau * j / count + tier * .35
                p = centre + Vector((math.cos(yaw) * (3 + tier), math.sin(yaw) * (3 + tier), -.4 + tier * .5))
                geo.leaf(p, length, width, yaw, 6 if (j + tier) % 3 else 7,
                         droop=-.45 if tier else -.18, twist=.3 * math.sin(j))
        for j in range(13):
            yaw = j * 2.399963
            r = 4.7 * math.sqrt((j + .5) / 13)
            p = centre + Vector((math.cos(yaw) * r, math.sin(yaw) * r, -.3))
            geo.sweep([p, p + Vector((0, 0, .8))], [.16, .29], 8, 6, 1, 0)
        self.object(name, geo, "flowers")

    def hide_import_source(self, obj):
        name = obj.name
        records = [r for r in self.records if r["name"] == name]
        self.import_source_records.extend(records)
        self.records = [r for r in self.records if r["name"] != name]
        self.objects.remove(obj)
        package = obj["Role"]
        self.packages[package].remove(obj)
        collection_name = self.prefix + "_EditableUnsplitImportSources"
        collection = bpy.data.collections.get(collection_name)
        if collection is None:
            collection = bpy.data.collections.new(collection_name)
            self.scene.collection.children.link(collection)
            collection.hide_render = True
            collection.hide_viewport = True
        self.collection.objects.unlink(obj)
        collection.objects.link(obj)
        obj["EditableSourceOnly"] = True

    def make_chunk(self, name, bm, source, normal_sampler=None):
        bm.normal_update()
        caps = bm.faces.layers.int.get("HA2_InternalCap")
        cap_flags = [bool(face[caps]) if caps else False for face in bm.faces]
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        mesh.update()
        mesh.materials.append(self.material)
        mesh.calc_loop_triangles()
        if len(mesh.loop_triangles) > self.args.mesh_max_triangles:
            raise ValueError(name + " exceeds the per-mesh export ceiling")
        edges = Counter(tuple(sorted((p.vertices[i], p.vertices[(i + 1) % len(p.vertices)])))
                        for p in mesh.polygons for i in range(len(p.vertices)))
        if any(count != 2 for count in edges.values()):
            raise ValueError(name + " contains an open or non-manifold chunk edge")
        if any(not math.isfinite(x) for v in mesh.vertices for x in v.co) or any(p.area < 1e-10 for p in mesh.polygons):
            raise ValueError(name + " contains invalid chunk geometry")
        if len(cap_flags) != len(mesh.polygons):
            raise ValueError(name + " lost its face/cap correspondence")
        normals = [None] * len(mesh.loops)
        uv = mesh.uv_layers.active
        if uv is None:
            raise ValueError(name + " lost its colour atlas UVs")
        for polygon, cap in zip(mesh.polygons, cap_flags):
            if cap:
                polygon.use_smooth = False
            for loop_index in polygon.loop_indices:
                if cap:
                    uv.data[loop_index].uv = tile_uv(0, .5, .5, self.atlas_size)
                    normals[loop_index] = tuple(polygon.normal)
                elif normal_sampler:
                    normals[loop_index] = normal_sampler(mesh.vertices[mesh.loops[loop_index].vertex_index].co)
                else:
                    normals[loop_index] = (0, 0, 0)
        if normal_sampler:
            mesh.normals_split_custom_set(normals)
        obj = bpy.data.objects.new(name, mesh)
        self.collection.objects.link(obj)
        package = source["Role"]
        obj["Round2Variant"], obj["Role"] = self.args.variant, package
        obj["NoRouteCollisionPromise"], obj["ImportSource"] = True, source.name
        lo = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
        hi = [max(v.co[i] for v in mesh.vertices) for i in range(3)]
        centre, size = [(a + b) / 2 for a, b in zip(lo, hi)], [b - a for a, b in zip(lo, hi)]
        self.records.append({"name": name, "package": package, "vertices": len(mesh.vertices),
                             "triangles": len(mesh.loop_triangles), "bounds_min_blender": lo,
                             "bounds_max_blender": hi, "center_blender": centre, "size_blender": size,
                             "center_roblox": [centre[0], centre[2], -centre[1]],
                             "size_roblox": [size[0], size[2], size[1]], "open_or_nonmanifold_edges": 0,
                             "import_source": source.name, "internal_cap_triangles": sum(len(p.vertices) - 2 for p, cap in zip(mesh.polygons, cap_flags) if cap),
                             "normal_policy": "original smooth surface normals interpolated; internal caps flat" if normal_sampler else "unchanged complete closed components",
                             "collision_intent": "visible capped mesh; route collision remains untested" if package == "structure" else "decorative; CanCollide=false"})
        self.objects.append(obj)
        self.packages.setdefault(package, []).append(obj)
        return obj

    def spatial_chunks(self, source):
        mesh = source.data
        mesh.calc_loop_triangles()
        source_vertices = [v.co.copy() for v in mesh.vertices]
        source_normals = [v.normal.copy() for v in mesh.vertices]
        base = bmesh.new()
        base.from_mesh(mesh)
        base.verts.index_update()
        bmesh.ops.triangulate(base, faces=list(base.faces), quad_method="FIXED", ngon_method="EAR_CLIP")
        triangles = [tuple(v.index for v in face.verts) for face in base.faces]
        surface = BVHTree.FromPolygons(source_vertices, triangles, all_triangles=True)
        normal_cache = {}

        def sample_normal(point):
            key = tuple(point)
            if key not in normal_cache:
                location, normal, index, distance = surface.find_nearest(point)
                if index is None or distance > 1e-3:
                    raise ValueError("Chunk surface vertex no longer lies on the original visible core")
                a, b, c = triangles[index]
                n = barycentric_transform(location, source_vertices[a], source_vertices[b], source_vertices[c],
                                          source_normals[a], source_normals[b], source_normals[c])
                normal_cache[key] = tuple(n.normalized() if n.length > 1e-8 else normal)
            return normal_cache[key]

        pending = [base]
        base.faces.layers.int.new("HA2_InternalCap")
        final, split_count = [], 0
        while pending:
            current = pending.pop()
            count = sum(len(face.verts) - 2 for face in current.faces)
            if count <= self.args.mesh_max_triangles:
                final.append(current)
                continue
            if split_count >= 63:
                raise ValueError("Spatial chunking reached its bounded split ceiling")
            lo = [min(v.co[i] for v in current.verts) for i in range(3)]
            hi = [max(v.co[i] for v in current.verts) for i in range(3)]
            axis = max(range(3), key=lambda i: hi[i] - lo[i])
            plane = round((lo[axis] + hi[axis]) / 2, 6)
            origin, direction = Vector((0, 0, 0)), Vector((0, 0, 0))
            origin[axis], direction[axis] = plane, 1
            cut = bmesh.ops.bisect_plane(current, geom=list(current.verts) + list(current.edges) + list(current.faces),
                                         dist=1e-6, plane_co=origin, plane_no=direction,
                                         use_snap_center=False, clear_inner=False, clear_outer=False)
            # Both children copy this one cut, so their intersection coordinates are identical.
            for element in cut["geom_cut"]:
                if isinstance(element, bmesh.types.BMVert):
                    element.co[axis] = plane
            children, seam_sets = [], []
            for sign in (-1, 1):
                child = current.copy()
                remove = [face for face in child.faces if sign * (face.calc_center_median()[axis] - plane) < -1e-6]
                bmesh.ops.delete(child, geom=remove, context="FACES")
                if not child.faces:
                    raise ValueError("Spatial chunk split produced an empty side")
                boundaries = [edge for edge in child.edges if edge.is_boundary]
                seam_sets.append({tuple(v.co) for edge in boundaries for v in edge.verts})
                caps = bmesh.ops.holes_fill(child, edges=boundaries, sides=0)["faces"]
                cap_layer = child.faces.layers.int.get("HA2_InternalCap")
                for face in caps:
                    face[cap_layer], face.smooth = 1, False
                if caps:
                    bmesh.ops.triangulate(child, faces=caps, quad_method="FIXED", ngon_method="EAR_CLIP")
                bmesh.ops.recalc_face_normals(child, faces=list(child.faces))
                child.normal_update()
                if any(not edge.is_manifold for edge in child.edges):
                    raise ValueError("Spatial chunk cap did not close the mesh")
                children.append(child)
            if seam_sets[0] != seam_sets[1]:
                raise ValueError("Spatial chunk boundaries disagree at their shared seam")
            seam_hash = hashlib.sha256(json.dumps(sorted(seam_sets[0]), separators=(",", ":")).encode()).hexdigest()
            self.chunk_checks.append({"source": source.name, "split": split_count, "axis_blender": axis,
                                      "plane_blender": plane, "seam_vertices": len(seam_sets[0]),
                                      "seam_position_sha256": seam_hash, "exact_child_seam_match": True})
            split_count += 1
            current.free()
            pending.extend(children)
        final.sort(key=lambda bm: tuple(min(v.co[i] for v in bm.verts) for i in (2, 0, 1)))
        for index, bm in enumerate(final):
            self.make_chunk(source.name + "_Chunk_%02d" % index, bm, source, sample_normal)
            bm.free()

    def component_chunks(self, source):
        mesh = source.data
        parents = list(range(len(mesh.vertices)))

        def find(index):
            while parents[index] != index:
                parents[index] = parents[parents[index]]
                index = parents[index]
            return index

        for edge in mesh.edges:
            a, b = (find(index) for index in edge.vertices)
            parents[b] = a
        components = {}
        for polygon in mesh.polygons:
            components.setdefault(find(polygon.vertices[0]), []).append(polygon.index)
        groups, group, count = [], set(), 0
        for faces in sorted(components.values(), key=lambda fs: min(fs)):
            triangles = sum(len(mesh.polygons[index].vertices) - 2 for index in faces)
            if triangles > self.args.mesh_max_triangles:
                raise ValueError(source.name + " has one closed component above the mesh ceiling")
            if count + triangles > self.args.mesh_max_triangles:
                groups.append(group)
                group, count = set(), 0
            group.update(faces)
            count += triangles
        if group:
            groups.append(group)
        for index, keep in enumerate(groups):
            bm = bmesh.new()
            bm.from_mesh(mesh)
            bm.faces.index_update()
            bmesh.ops.delete(bm, geom=[face for face in bm.faces if face.index not in keep], context="FACES")
            self.make_chunk(source.name + "_Chunk_%02d" % index, bm, source)
            bm.free()
        self.chunk_checks.append({"source": source.name, "method": "whole_closed_components",
                                  "components": len(components), "chunks": len(groups), "no_leaf_component_cut": True})

    def prepare_import_chunks(self):
        if not self.selected:
            return
        for source in list(self.objects):
            source.data.calc_loop_triangles()
            if len(source.data.loop_triangles) <= self.args.mesh_max_triangles:
                continue
            if source["Role"] == "structure":
                self.spatial_chunks(source)
            else:
                self.component_chunks(source)
            self.hide_import_source(source)
        if any(record["triangles"] > self.args.mesh_max_triangles for record in self.records):
            raise ValueError("An exported mesh still exceeds the explicit import ceiling")

    def build(self):
        trunks, branches, crowns, flower, close, self.note = selected_braid_design() if self.selected_braid else design(self.args.variant)
        for j, (points, radii) in enumerate(trunks):
            self.branch("PrimaryStem_%02d" % j, points, radii)
        for j, (points, radii) in enumerate(branches):
            self.branch("MajorBough_%02d" % j, points, radii)
        self.roots(trunks)
        if self.selected_braid:
            self.growth_ridges(trunks)
        self.fuse_core()
        if self.selected_braid:
            self.irregular_crown("WesternCrownMass", [(-98, 10, 346, 34), (-66, 13, 361, 40), (-42, 26, 348, 29)])
            self.irregular_crown("EasternCrownMass", [(116, 7, 331, 38), (92, 20, 351, 38), (62, 30, 336, 30)])
            self.irregular_crown("ContinuingCrownMass", [(-32, 12, 396, 34), (9, 8, 400, 40), (51, 17, 389, 35)])
            self.irregular_crown("LowerWestFringe", [(-99, 6, 131, 22), (-83, 19, 120, 15)], True)
            self.irregular_crown("LowerEastFringe", [(107, 11, 157, 24), (89, 21, 147, 15)], True)
            self.irregular_crown("FlowerBoughFoliage", [(-82, 13, 264, 17), (-102, 17, 267, 14)], True)
        else:
            for j, (x, y, z, radius) in enumerate(crowns):
                self.crown("Crown_%02d" % j, (x, y, z), radius)
        # These are nearby material detail, not a second forest or a route.
        near = ((-33, -112, 2), (26, -109, 2), (-47, -70, 11), (38, -64, 7)) if self.selected_braid else (
            (flower[0] - 4, flower[1] + 8, flower[2] - 4), (flower[0] + 15, flower[1] + 12, flower[2] - 3), (-47, -23, 31), (47, -20, 24))
        for j, centre in enumerate(near):
            self.crown("NearLeafSpray_%02d" % j, centre, (4 if j < 2 else 5) if self.selected_braid else (7 if j < 2 else 9), True)
        self.flower(flower)
        if self.selected_braid:
            self.flower((-27, -112, 2.3), .28, "RootArchMaterialFlower")
        # The six-stud mannequin is only a visual scale marker.
        avatar = Geometry()
        c = Vector(close)
        avatar.box(c + Vector((-.55, 0, 1)), (.9, .9, 2), 13)
        avatar.box(c + Vector((.55, 0, 1)), (.9, .9, 2), 13)
        avatar.box(c + Vector((0, 0, 3.2)), (2, 1, 2.4), 13)
        avatar.box(c + Vector((-1.4, 0, 3.2)), (.7, .9, 2.2), 13)
        avatar.box(c + Vector((1.4, 0, 3.2)), (.7, .9, 2.2), 13)
        avatar.box(c + Vector((0, 0, 5.2)), (1.4, 1.2, 1.6), 14)
        self.object("SixStudScaleAvatar", avatar, "preview", True)
        ground = Geometry()
        ground.box((0, 0, -1.5 if self.selected_braid else -2), (1600, 1600, 3), 15)
        self.object("StudioGround", ground, "preview", True)
        self.close = Vector(close)
        self.prepare_import_chunks()
        total = sum(record["triangles"] for record in self.records)
        if self.selected and total > self.args.selected_max_triangles:
            raise ValueError("Selected tree exceeds its explicit total triangle ceiling: " + str(total))
        self.setup_render()

    def setup_render(self):
        scene = self.scene
        scene.render.engine = "CYCLES"
        scene.cycles.samples = self.args.samples
        scene.cycles.use_denoising = True
        scene.cycles.max_bounces = 4
        scene.cycles.diffuse_bounces = 2
        scene.cycles.glossy_bounces = 2
        scene.render.image_settings.file_format = "PNG"
        scene.render.film_transparent = False
        scene.view_settings.view_transform = "AgX"
        world = bpy.data.worlds.new(self.prefix + "_StudyWorld")
        world.use_nodes = True
        world.node_tree.nodes["Background"].inputs["Color"].default_value = (.49, .59, .67, 1)
        world.node_tree.nodes["Background"].inputs["Strength"].default_value = .42
        scene.world = world
        self.light("Sun", "SUN", (-120, -130, 400), 3.0, (1, .80, .60), (0, 0, 100))
        self.light("WarmKey", "AREA", (-170, -230, 310), 140000, (1, .81, .61), (-20, 0, 230), 220)
        self.light("SoftFill", "AREA", (190, -100, 260), 60000, (.70, .83, 1), (0, 0, 200), 250)
        self.light("CanopyRim", "AREA", (80, 160, 340), 130000, (1, .86, .65), (0, 0, 280), 180)
        lo = Vector(tuple(min(record["bounds_min_blender"][i] for record in self.records) for i in range(3)))
        hi = Vector(tuple(max(record["bounds_max_blender"][i] for record in self.records) for i in range(3)))
        target = (lo + hi) * .5
        self.whole_camera = self.camera("WholeTree", (-550, -850, target.z + 125), target, orthographic=True)
        self.whole_camera.data.ortho_scale = (hi.z - lo.z) * 1.12
        self.close_camera = self.camera("PlayerHeightColour", self.close + Vector((-35, -46, 10)),
                                        self.close + Vector((9, 5, 3.5)), orthographic=False)
        self.close_camera.data.lens = 43
        if self.selected_braid:
            self.close_camera.location = (-41, -153, 6)
            self.close_camera.rotation_euler = (Vector((-8, -79, 9)) - self.close_camera.location).to_track_quat("-Z", "Y").to_euler()
            self.close_camera.data.lens = 34
        self.scene.camera = self.whole_camera
        self.bounds = {"min_blender": list(lo), "max_blender": list(hi), "height_studs": hi.z - lo.z}

    def light(self, name, kind, position, energy, colour, target, size=100):
        data = bpy.data.lights.new(self.prefix + "_" + name, kind)
        data.energy, data.color = energy, colour
        if kind == "AREA":
            data.shape, data.size = "DISK", size
        if kind == "SUN":
            data.angle = .18
        obj = bpy.data.objects.new(data.name, data)
        self.preview.objects.link(obj)
        obj.location = position
        obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()

    def camera(self, name, position, target, orthographic):
        data = bpy.data.cameras.new(self.prefix + "_" + name)
        data.type = "ORTHO" if orthographic else "PERSP"
        data.clip_end = 3000
        data.clip_start = .1
        obj = bpy.data.objects.new(data.name, data)
        self.preview.objects.link(obj)
        obj.location = position
        obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
        return obj

    def render(self):
        if self.args.skip_renders:
            return
        scene = self.scene
        for name, camera, clay, size in (("whole-silhouette", self.whole_camera, True, (850, 1100)),
                                         ("whole-colour", self.whole_camera, False, (850, 1100)),
                                         ("playerheight-colour", self.close_camera, False, (1100, 750))):
            scene.camera = camera
            scene.view_layers[0].material_override = self.clay if clay else None
            scene.render.resolution_x, scene.render.resolution_y = size
            scene.render.resolution_percentage = self.args.resolution_percent
            scene.render.filepath = str(self.output / (name + ".png"))
            bpy.ops.render.render(write_still=True)
        scene.view_layers[0].material_override = None
        scene.camera = self.whole_camera

    def export(self):
        packages = {}
        if self.selected and not self.args.skip_fbx:
            for name, objects in self.packages.items():
                for obj in self.scene.objects:
                    obj.select_set(False)
                for obj in objects:
                    obj.select_set(True)
                bpy.context.view_layer.objects.active = objects[0]
                path = self.output / (name + ".fbx")
                bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, object_types={"MESH"},
                                         path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                                         use_triangles=True, add_leaf_bones=False)
                packages[name] = {"file": path.name, "bytes": path.stat().st_size,
                                  "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        bpy.ops.wm.save_as_mainfile(filepath=str(self.output / (self.args.variant + ".blend")))
        manifest = {"build": "HA_R2_TREE_SELECTED_02" if self.selected_braid else "HA_R2_TREE_STUDY_01", "variant": self.args.variant, "detail": self.args.detail,
                    "units": "one Blender unit = one Roblox stud before import normalization",
                    "coordinate_mapping": "Blender (x,y,z) -> Roblox (x,z,-y)",
                    "design": self.note, "tree_bounds": self.bounds, "objects": self.records,
                    "editable_growth_sources": self.editable_source_records,
                    "editable_unsplit_import_sources": self.import_source_records,
                    "import_chunking": {"individual_mesh_triangle_ceiling": self.args.mesh_max_triangles,
                                        "maximum_export_mesh_triangles": max(record["triangles"] for record in self.records),
                                        "checks": self.chunk_checks},
                    "wood_fusion": {"enabled": self.args.fuse_core, "voxel_size": self.args.fusion_voxel_size,
                                    "triangle_ceiling": self.args.fusion_max_triangles},
                    "selected_triangle_ceiling": self.args.selected_max_triangles,
                    "triangles": sum(record["triangles"] for record in self.records), "packages": packages,
                    "colour_texture": self.colour_path.name, "roughness_texture": self.roughness_path.name,
                    "palette": [{"tile": i, "name": name, "rgb": rgb, "roughness": rough}
                                for i, (name, rgb, rough) in enumerate(PALETTE)],
                    "preview_only": "Ground, lighting, cameras and six-stud mannequin are excluded from all FBX packages.",
                    "evidence_limits": ["A saved Blender render is not imported Roblox material proof.",
                                        "Closed meshes do not establish route collision, camera clearance or human playability.",
                                        "No device, 20-player, performance, route or owner acceptance claim is made."]}
        (self.output / "tree-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        print(json.dumps({"variant": self.args.variant, "objects": len(self.records), "triangles": manifest["triangles"],
                          "height": self.bounds["height_studs"], "output": str(self.output)}), flush=True)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--variant", choices=VARIANTS, required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--detail", choices=("study", "selected"), default="study")
    parser.add_argument("--samples", type=int, default=12)
    parser.add_argument("--resolution-percent", type=int, default=75)
    parser.add_argument("--skip-renders", action="store_true")
    parser.add_argument("--fuse-core", action="store_true")
    parser.add_argument("--skip-fbx", action="store_true")
    parser.add_argument("--fusion-voxel-size", type=float, default=2.2)
    parser.add_argument("--fusion-max-triangles", type=int, default=150000)
    parser.add_argument("--selected-max-triangles", type=int, default=260000)
    parser.add_argument("--mesh-max-triangles", type=int, default=18000)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if args.detail == "selected" and args.variant == "braided_windows":
        args.fuse_core = True
    if not 1 <= args.samples <= 128 or not 10 <= args.resolution_percent <= 100:
        parser.error("Samples must be 1..128 and resolution-percent 10..100")
    if not 1 <= args.fusion_voxel_size <= 5 or not 10000 <= args.fusion_max_triangles <= 300000:
        parser.error("Fusion voxel size must be 1..5 and fusion-max-triangles 10000..300000")
    if not 50000 <= args.selected_max_triangles <= 300000:
        parser.error("selected-max-triangles must be 50000..300000")
    if not 1000 <= args.mesh_max_triangles <= 18000:
        parser.error("mesh-max-triangles must be 1000..18000")
    return args


def main():
    if not bpy.app.background:
        raise RuntimeError("Run this builder in a separate headless Blender process; it does not edit the live scene")
    builder = Builder(parse_args())
    builder.build()
    builder.render()
    builder.export()


if __name__ == "__main__":
    main()
