"""Check authored mesh data without importing or operating Blender."""
import ast
from collections import Counter
import json
from pathlib import Path
import runpy
import sys
import types

folder = Path(__file__).resolve().parent
source = folder / "BlenderTowerRecipe.py"
ast.parse(source.read_text())
sys.modules["bpy"] = types.ModuleType("bpy")
recipe = runpy.run_path(str(source))
report = {}
for factory in ("grand_pinnacle","flank_pinnacle","stepped_buttress"):
    unit = recipe[factory]()
    totals = {"parts":0,"triangles":0,"materialGroups":{},"nativeVerified":False}
    all_points = []
    unique_points = set()
    for role,(vertices,faces) in unit.geometry.items():
        edge_counts = Counter()
        directed_edges = Counter()
        signed_volume = 0
        for face in faces:
            for i,index in enumerate(face):
                edge_counts[tuple(sorted((index,face[(i+1)%len(face)])))] += 1
                directed_edges[(index,face[(i+1)%len(face)])] += 1
            a = vertices[face[0]]
            for i in range(1,len(face)-1):
                b,c = vertices[face[i]],vertices[face[i+1]]
                cross = (b[1]*c[2]-b[2]*c[1],b[2]*c[0]-b[0]*c[2],b[0]*c[1]-b[1]*c[0])
                signed_volume += sum(a[j]*cross[j] for j in range(3))/6
        assert all(count==2 for count in edge_counts.values()), (unit.name,role,"boundary/nonmanifold edge")
        assert all(directed_edges[(b,a)]==count for (a,b),count in directed_edges.items()), (unit.name,role,"inconsistent face winding")
        assert signed_volume>0, (unit.name,role,"inward winding")
        for point in vertices:
            rounded = tuple(round(channel,6) for channel in point)
            assert rounded not in unique_points, (unit.name,role,"coincident vertex across closed components/materials")
            unique_points.add(rounded)
        triangles = sum(len(face)-2 for face in faces)
        totals["materialGroups"][role] = {"vertices":len(vertices),"triangles":triangles,"closedEdges":True,"positiveSignedVolume":signed_volume}
        totals["parts"] += bool(faces)
        totals["triangles"] += triangles
        all_points.extend((x,y,-z) for x,z,y in vertices)
    low = [min(point[j] for point in all_points) for j in range(3)]
    high = [max(point[j] for point in all_points) for j in range(3)]
    totals["low"],totals["high"],totals["size"] = low,high,[high[j]-low[j] for j in range(3)]
    report[unit.name] = totals
(folder / "recipe-check.json").write_text(json.dumps(report,indent=2)+"\n")
for name,data in report.items():
    print(name,data["parts"],data["triangles"],data["size"],"closed edges; outward winding")
