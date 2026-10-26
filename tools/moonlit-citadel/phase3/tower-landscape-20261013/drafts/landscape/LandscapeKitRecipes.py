"""Closed low-cost mesh recipes in Roblox axes; the lead exports through Blender."""
import math

PALETTE = {
    "Grass": (91, 129, 64), "Earth": (104, 86, 63), "Rock": (102, 111, 108),
    "Wood": (101, 77, 53), "Foliage": (70, 117, 67), "Needles": (62, 102, 73),
    "Leaf": (86, 123, 66), "Flower": (151, 133, 171),
}


class Mesh:
    def __init__(self):
        self.vertices = []
        self.faces = []
        self.materials = []

    def add(self, vertices, faces, material):
        offset = len(self.vertices)
        self.vertices.extend(vertices)
        self.faces.extend(tuple(offset + i for i in reversed(face)) for face in faces)
        self.materials.extend([material] * len(faces))

    def rings(self, rings, material):
        sides = len(rings[0])
        vertices = [point for ring in rings for point in ring]
        faces = [tuple(range(sides - 1, -1, -1))]
        for level in range(len(rings) - 1):
            for side in range(sides):
                a = level * sides + side
                b = level * sides + (side + 1) % sides
                faces.append((a, b, b + sides, a + sides))
        faces.append(tuple(range((len(rings) - 1) * sides, len(rings) * sides)))
        self.add(vertices, faces, material)

    def profile(self, centre, profile, sides, material):
        cx, cy, cz = centre
        rings = []
        for height, rx, rz in profile:
            rings.append([(cx + math.cos(i * math.tau / sides) * rx, cy + height,
                           cz + math.sin(i * math.tau / sides) * rz) for i in range(sides)])
        self.rings(rings, material)

    def ellipsoid(self, centre, radii, sides, levels, material):
        cx, cy, cz = centre
        rx, ry, rz = radii
        bottom, top = len(self.vertices), len(self.vertices) + 1
        vertices = [(cx, cy - ry, cz), (cx, cy + ry, cz)]
        for level in range(1, levels):
            phi = -math.pi / 2 + math.pi * level / levels
            for side in range(sides):
                theta = side * math.tau / sides
                vertices.append((cx + math.cos(theta) * math.cos(phi) * rx,
                                 cy + math.sin(phi) * ry,
                                 cz + math.sin(theta) * math.cos(phi) * rz))
        faces = []
        for side in range(sides):
            a, b = 2 + side, 2 + (side + 1) % sides
            faces.append((0, b, a))
        for level in range(levels - 2):
            for side in range(sides):
                a = 2 + level * sides + side
                b = 2 + level * sides + (side + 1) % sides
                faces.append((a, b, b + sides, a + sides))
        last = 2 + (levels - 2) * sides
        for side in range(sides):
            faces.append((1, last + side, last + (side + 1) % sides))
        self.add(vertices, faces, material)

    def bounds(self):
        return tuple(min(v[i] for v in self.vertices) for i in range(3)), tuple(max(v[i] for v in self.vertices) for i in range(3))

    def triangles(self):
        return sum(len(face) - 2 for face in self.faces)


def hill_height(x, z):
    radial = (x / 31.2) ** 2 + (z / 25.35) ** 2
    return 6 * max(0, 1 - radial) ** 2


def mound():
    mesh = Mesh()
    mesh.profile((0, 0, 0), [(-14, 23.5, 18.5), (-10, 29.0, 23.0),
                             (-7.2, 32, 26), (-3.7, 29.0, 23.5)], 16, "Rock")
    mesh.profile((0, 0, 0), [(-4, 29, 23.5), (-2.4, 30.8, 25.1),
                             (-.35, 30.5, 24.9)], 16, "Earth")
    sides, levels = 20, 6
    vertices = [(0, 6, 0)]
    for level in range(1, levels + 1):
        radial = level / levels
        for side in range(sides):
            theta = side * math.tau / sides
            vertices.append((math.cos(theta) * 31.2 * radial,
                             6 * (1 - radial * radial) ** 2,
                             math.sin(theta) * 25.35 * radial))
    for side in range(sides):
        theta = side * math.tau / sides
        vertices.append((math.cos(theta) * 31.2, -.4, math.sin(theta) * 25.35))
    faces = [(0, 1 + side, 1 + (side + 1) % sides) for side in range(sides)]
    for level in range(levels - 1):
        for side in range(sides):
            a, b = 1 + level * sides + side, 1 + level * sides + (side + 1) % sides
            faces.append((a, a + sides, b + sides, b))
    outer, bottom = 1 + (levels - 1) * sides, 1 + levels * sides
    for side in range(sides):
        a, b = outer + side, outer + (side + 1) % sides
        faces.append((b, a, bottom + side, bottom + (side + 1) % sides))
    faces.append(tuple(range(bottom + sides - 1, bottom - 1, -1)))
    mesh.add(vertices, faces, "Grass")
    return mesh


def broadleaf():
    mesh = Mesh()
    for point, height, crown in [((-8, 0, -3), 22, (9, 6, 9)), ((7, 0, 1), 30, (9, 8, 10)),
                                 ((-1, 0, 6), 25, (8, 7, 8))]:
        mesh.profile(point, [(-2, .9, .85), (0, .75, .72), (height * .52, .55, .50),
                             (height * .75, .27, .24)], 8, "Wood")
        mesh.ellipsoid((point[0], height - crown[1], point[2]), crown, 14, 7, "Foliage")
    return mesh


def evergreen():
    mesh = Mesh()
    for point, height in [((-9, 0, -7), 24), ((8, 0, 6), 34), ((-5, 0, 9), 29)]:
        mesh.profile(point, [(-2, .8, .75), (0, .65, .62), (height - 2, .2, .18)], 8, "Wood")
        radius = 6.0 if height < 30 else 7.3
        for tier in range(4):
            base = 4 + tier * (height - 7) / 4
            width = radius * (1 - tier * .13)
            top = min(height, base + (height - 4) * .44)
            if tier == 3:
                top = height
            mesh.profile(point, [(base, width * .28, width * .28), (base + .6, width, width),
                                 (top - .5, .5, .5), (top, .05, .05)], 10, "Needles")
    return mesh


def herbs():
    mesh = Mesh()
    for centre, radii in [((-6.5, 1.05, -2), (2.5, 1.3, 2.4)), ((-2.5, 1.1, 2.3), (2.5, 1.2, 2.8)),
                           ((2.5, 1.3, -2), (3, 1.5, 2.5)), ((6.5, .9, 1.2), (2.5, 1.1, 2.5)),
                           ((0, .8, 3.2), (2, 1.0, 2.8))]:
        mesh.ellipsoid(centre, radii, 8, 4, "Leaf")
    for x, z, height in [(-6, -2, 2.5), (-2, 2, 2.6), (2.5, -2, 2.8), (6, 1, 2.2), (0, 3, 2.1)]:
        mesh.ellipsoid((x, height - .2, z), (.5, .2, .5), 6, 3, "Flower")
    return mesh


def build_recipes():
    return {"MC_P3_Rural_Mound": mound(), "MC_P3_Rural_BroadleafClump": broadleaf(),
            "MC_P3_Rural_EvergreenGrove": evergreen(), "MC_P3_Rural_HeatherFern": herbs()}


if __name__ == "__main__":
    import json
    print(json.dumps({name: {"bounds": mesh.bounds(), "triangles": mesh.triangles(),
                             "materials": sorted(set(mesh.materials))}
                      for name, mesh in build_recipes().items()}, indent=2))
