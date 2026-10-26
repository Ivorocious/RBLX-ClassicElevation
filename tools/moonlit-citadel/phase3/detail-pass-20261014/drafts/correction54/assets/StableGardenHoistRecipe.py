"""Repair only the reused closed rope and wheel frames in the isolated kit."""
import importlib.util
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('dg02_unmodified_recipe', HERE / 'GardenHoistRecipe.py')
original = importlib.util.module_from_spec(spec)
spec.loader.exec_module(original)
PALETTE = original.PALETTE

def build_recipes(a, e):
    original_tube = a._Mesh.tube
    repaired = []

    def tube(self, path, radius, color='Brass', sides=8, closed=False):
        if not (closed and len(path) == 16 and
                ((color == 'Iron' and sides == 6 and abs(radius-.115) < 1e-9) or
                 (color == 'Brass' and sides == 5 and abs(radius-.075) < 1e-9))):
            return original_tube(self, path, radius, color, sides, closed)
        centre = tuple(sum(point[k] for point in path)/len(path) for k in range(3))
        assert all(abs(point[0]-centre[0]) < 1e-8 for point in path)
        major = math.hypot(path[0][1]-centre[1], path[0][2]-centre[2])
        assert all(abs(math.hypot(point[1]-centre[1], point[2]-centre[2])-major) < 1e-8 for point in path)
        phase = math.pi if color == 'Brass' and centre[0] < 0 else 0
        vertices = []
        for index in range(16):
            theta = math.tau*index/16
            for side in range(sides):
                phi = math.tau*side/sides + phase
                ring_radius = major + radius*math.sin(phi)
                vertices.append((centre[0]+radius*math.cos(phi),
                                 centre[1]+ring_radius*math.cos(theta),
                                 centre[2]+ring_radius*math.sin(theta)))
        faces = []
        for index in range(16):
            for side in range(sides):
                a0 = index*sides+side
                b0 = index*sides+(side+1)%sides
                c0 = ((index+1)%16)*sides+(side+1)%sides
                d0 = ((index+1)%16)*sides+side
                faces.extend(((a0,b0,c0),(a0,c0,d0)))
        self.add(vertices, faces, color, smooth=True)
        repaired.append({'material': color, 'centre': centre, 'majorRadius': major,
                         'minorRadius': radius, 'majorSegments': 16, 'minorSegments': sides,
                         'continuousFixedAxialFrame': True, 'explicitTriangles': len(faces)})

    a._Mesh.tube = tube
    try:
        result = original.build_recipes(a, e)
    finally:
        a._Mesh.tube = original_tube
    assert len(repaired) == 7
    for name, mesh, notes in result:
        if name == 'MC_DG_WallHoist':
            mesh.stable_torus_repairs = repaired
    return result
