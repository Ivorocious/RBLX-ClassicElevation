"""Grid union of the five retained keep footprints, with an open inner court."""
import itertools

CORE = [(-38, 38, 10, 18), (-38, -30, -18, 10), (-30, 38, -18, -10),
        (30, 38, -10, 10), (-15, 15, -43, -16)]
COPING = [(x0-1, x1+1, z0-1, z1+1) for x0, x1, z0, z1 in CORE]


def coordinates():
    rectangles = CORE+COPING
    return (sorted({x for r in rectangles for x in r[:2]}),
            sorted({z for r in rectangles for z in r[2:]}))


def contains(rectangles, x, z):
    return any(x0 < x < x1 and z0 < z < z1 for x0, x1, z0, z1 in rectangles)


def cells(layers):
    xs, zs = coordinates()
    ys = sorted({y for lo, hi, _ in layers for y in (lo, hi)})
    occupied = set()
    for i, j, k in itertools.product(range(len(xs)-1), range(len(ys)-1), range(len(zs)-1)):
        x, y, z = (xs[i]+xs[i+1])/2, (ys[j]+ys[j+1])/2, (zs[k]+zs[k+1])/2
        if any(lo < y < hi and contains(rectangles, x, z) for lo, hi, rectangles in layers):
            occupied.add((i, j, k))
    return xs, ys, zs, occupied


def surface(a, layers, material):
    xs, ys, zs, occupied = cells(layers)
    planes = {}
    for i, j, k in sorted(occupied):
        sides = [((-1, 0, 0), [(i,j,k),(i,j,k+1),(i,j+1,k+1),(i,j+1,k)]),
                 ((1, 0, 0), [(i+1,j,k),(i+1,j+1,k),(i+1,j+1,k+1),(i+1,j,k+1)]),
                 ((0, -1, 0), [(i,j,k),(i+1,j,k),(i+1,j,k+1),(i,j,k+1)]),
                 ((0, 1, 0), [(i,j+1,k),(i,j+1,k+1),(i+1,j+1,k+1),(i+1,j+1,k)]),
                 ((0, 0, -1), [(i,j,k),(i,j+1,k),(i+1,j+1,k),(i+1,j,k)]),
                 ((0, 0, 1), [(i,j,k+1),(i+1,j,k+1),(i+1,j+1,k+1),(i,j+1,k+1)])]
        for delta, corners in sides:
            neighbor = (i+delta[0], j+delta[1], k+delta[2])
            if neighbor not in occupied:
                axis = next(n for n, value in enumerate(delta) if value)
                axes = [n for n in range(3) if n != axis]
                key = (axis, delta[axis], corners[0][axis])
                planes.setdefault(key, set()).add(tuple(min(c[n] for c in corners) for n in axes))
    rectangles = []
    for (axis, direction, plane), tiles in sorted(planes.items()):
        axes = [n for n in range(3) if n != axis]
        while tiles:
            u, v = min(tiles)
            width = 1
            while (u+width, v) in tiles:
                width += 1
            height = 1
            while all((u+s, v+height) in tiles for s in range(width)):
                height += 1
            tiles -= {(u+s, v+t) for s in range(width) for t in range(height)}
            corners = []
            for left, right in [(u,v),(u+width,v),(u+width,v+height),(u,v+height)]:
                point = [0,0,0]
                point[axis], point[axes[0]], point[axes[1]] = plane, left, right
                corners.append(tuple(point))
            if direction != (1 if axis != 1 else -1):
                corners.reverse()
            rectangles.append(corners)
    grid_points = {point for rectangle in rectangles for point in rectangle}
    vertices, indices, faces = [], {}, []

    def vertex(point):
        if point not in indices:
            indices[point] = len(vertices)
            vertices.append(point)
        return indices[point]

    def position(index):
        i, j, k = index
        return (xs[i], -zs[k], ys[j])

    for rectangle in rectangles:
        perimeter = []
        for start, end in zip(rectangle, rectangle[1:]+rectangle[:1]):
            axis = next(n for n in range(3) if start[n] != end[n])
            points = [p for p in grid_points if all(p[n] == start[n] for n in range(3) if n != axis)
                      and min(start[axis], end[axis]) <= p[axis] <= max(start[axis], end[axis])]
            points.sort(key=lambda p: p[axis], reverse=start[axis] > end[axis])
            perimeter.extend(points[:-1])
        positions = [position(p) for p in perimeter]
        center = tuple(sum(position(p)[axis] for p in rectangle)/4 for axis in range(3))
        middle = vertex(center)
        for start, end in zip(positions, positions[1:]+positions[:1]):
            faces.append((middle, vertex(start), vertex(end)))
    g = a._Mesh()
    g.add(vertices, faces, material)
    return g


def exterior(a):
    """One closed welded exterior union, useful for manifold and void checks."""
    return surface(a, [(0, 3, COPING), (3, 160.8, CORE), (160.8, 163.8, COPING)], "Stone")


def boxes(e):
    # Exact rectangles cover the union without filling the court void.
    result = []
    for lo, hi, rectangles in [(0,3,COPING), (3,160.8,CORE), (160.8,163.8,COPING)]:
        for x0, x1, z0, z1 in rectangles:
            result.append(e.box_proxy(((x0+x1)/2, -(z0+z1)/2, (lo+hi)/2),
                                      (x1-x0, z1-z0, hi-lo)))
    return result


def solid_boxes_roblox():
    return [{"low": [x0,lo,z0], "high": [x1,hi,z1]}
            for lo, hi, rectangles in [(0,3,COPING), (3,160.8,CORE), (160.8,163.8,COPING)]
            for x0, x1, z0, z1 in rectangles]


def main_keep_shell(a, e):
    g = surface(a, [(2.99,160.81,CORE)], "Stone")
    bands = surface(a, [(0,3,COPING), (160.8,163.8,COPING)], "StoneLight")
    g.transformed(bands)
    return g, boxes(e), "Connected keep/apse union with open inner court. Exclusive exterior cornices; closed core caps buried .01 inside coping. Base0,top163.8. Place at FinishPoint.X,-38,FinishPoint.Z; focal windows/pinnacles/buttresses retain original poses."
