"""Union of retained crown mass/curb solids; vertex coordinates are course-local."""
import json
from pathlib import Path
import types

path = Path(__file__).with_name("GridUnion.py")
grid = types.ModuleType("er_grid_union")
exec(compile(path.read_text(encoding="utf-8"),str(path),"exec"),grid.__dict__)


def inputs():
    return json.loads(Path(__file__).with_name("crown-inputs.json").read_text(encoding="utf-8"))


def crown_base_shell(a,e):
    boxes = inputs()["boxes"]
    g = a._Mesh()
    for material in sorted({b["material"] for b in boxes}):
        vertices,faces,_ = grid.mesh([b for b in boxes if b["material"] == material])
        g.add([(x,-z,y) for x,y,z in vertices],faces,material)
    occupied = [e.box_proxy(((b["low"][0]+b["high"][0])/2,-(b["low"][2]+b["high"][2])/2,
                            (b["low"][1]+b["high"][1])/2),
                           (b["high"][0]-b["low"][0],b["high"][2]-b["low"][2],b["high"][1]-b["low"][1])) for b in boxes]
    return g,occupied,"Nine retained crown masses/curbs unioned per closed material; buried fixed Stone caps preserved. Course-local vertices: identity CFrame/unit scale. East approach void/contact clearance unchanged within5e-6stud authored snapping; joined screens/emblem mount separate."


def exterior(a):
    vertices,faces,stats = grid.mesh(inputs()["boxes"])
    g = a._Mesh()
    g.add([(x,-z,y) for x,y,z in vertices],faces,"Stone")
    return g,stats
