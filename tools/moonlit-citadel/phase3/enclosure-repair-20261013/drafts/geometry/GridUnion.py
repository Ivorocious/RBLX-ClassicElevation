"""Welded closed union surfaces for axis-aligned occupied boxes in Roblox axes."""
import bisect
import itertools


def mesh(boxes):
    axes = [sorted({box[side][i] for box in boxes for side in ("low","high")}) for i in range(3)]
    indices = [{v:i for i,v in enumerate(axis)} for axis in axes]
    occupied = set()
    for box in boxes:
        ranges = [range(indices[i][box["low"][i]], indices[i][box["high"][i]]) for i in range(3)]
        occupied.update(itertools.product(*ranges))
    planes = {}
    for cell in sorted(occupied):
        for axis in range(3):
            others = [n for n in range(3) if n != axis]
            for direction in (-1,1):
                neighbor = list(cell)
                neighbor[axis] += direction
                if tuple(neighbor) in occupied:
                    continue
                key = (axis,direction,cell[axis]+(direction == 1))
                planes.setdefault(key,set()).add(tuple(cell[n] for n in others))
    rectangles = []
    for (axis,direction,plane), tiles in sorted(planes.items()):
        others = [n for n in range(3) if n != axis]
        while tiles:
            u,v = min(tiles)
            width = 1
            while (u+width,v) in tiles:
                width += 1
            height = 1
            while all((u+s,v+height) in tiles for s in range(width)):
                height += 1
            tiles -= {(u+s,v+t) for s in range(width) for t in range(height)}
            corners = []
            for left,right in [(u,v),(u+width,v),(u+width,v+height),(u,v+height)]:
                point = [0,0,0]
                point[axis],point[others[0]],point[others[1]] = plane,left,right
                corners.append(tuple(point))
            if direction != (1 if axis != 1 else -1):
                corners.reverse()
            rectangles.append(corners)
    grid_points = {p for rectangle in rectangles for p in rectangle}
    # Edge lists avoid rescanning every point when the source contains many strips.
    lines = {}
    for point in grid_points:
        for axis in range(3):
            key = (axis,)+tuple(point[n] for n in range(3) if n != axis)
            lines.setdefault(key,[]).append(point)
    for key in lines:
        lines[key].sort(key=lambda p:p[key[0]])
    vertices,lookup,faces = [],{},[]

    def index(position):
        if position not in lookup:
            lookup[position] = len(vertices)
            vertices.append(position)
        return lookup[position]

    def position(point):
        return tuple(axes[n][point[n]] for n in range(3))

    for rectangle in rectangles:
        perimeter = []
        for start,end in zip(rectangle,rectangle[1:]+rectangle[:1]):
            axis = next(n for n in range(3) if start[n] != end[n])
            key = (axis,)+tuple(start[n] for n in range(3) if n != axis)
            candidates = lines[key]
            values = [p[axis] for p in candidates]
            left = bisect.bisect_left(values,min(start[axis],end[axis]))
            right = bisect.bisect_right(values,max(start[axis],end[axis]))
            edge = candidates[left:right]
            if start[axis] > end[axis]:
                edge = list(reversed(edge))
            perimeter.extend(edge[:-1])
        points = [position(p) for p in perimeter]
        center = tuple(sum(position(p)[n] for p in rectangle)/4 for n in range(3))
        middle = index(center)
        for start,end in zip(points,points[1:]+points[:1]):
            faces.append((middle,index(start),index(end)))
    volume = sum((axes[0][i+1]-axes[0][i])*(axes[1][j+1]-axes[1][j])*(axes[2][k+1]-axes[2][k]) for i,j,k in occupied)
    return vertices,faces,{"occupied_cells":len(occupied),"rectangular_surfaces":len(rectangles),"union_volume":volume}
