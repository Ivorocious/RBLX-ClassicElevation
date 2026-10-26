"""Check extracted entrance helpers without executing either production builder."""
import ast
import bpy
import bmesh
import hashlib
import json
import math
from pathlib import Path
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = HERE / "R01_entrance"
STAGE = ROOT / "assets/grand_arcade/build_stage.py"
CONNECTION = ROOT / "assets/grand_arcade/connection_candidate/build_connection.py"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene


def functions_from(path, names, namespace):
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    nodes = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in names]
    assert {node.name for node in nodes} == set(names)
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(path), "exec"), namespace)
    return namespace


def load_objects(path, names, prefix):
    wanted = list(names)
    with bpy.data.libraries.load(str(path), link=False) as (source, loaded):
        assert set(wanted) <= set(source.objects)
        loaded.objects = list(wanted)
    result = dict(zip(wanted, loaded.objects))
    for name, obj in result.items():
        obj.name = prefix+name
    return result


checks = functions_from(HERE / "build_entrance.py",
                        ["points", "components", "mesh_checks", "polygon_area", "clip_inside", "floor_overlap"],
                        {"bpy": bpy, "math": math, "Vector": Vector})
points, components = checks["points"], checks["components"]
beam_names = [f"FrontWing{side}__{mat}" for side in (-1,1) for mat in ("Ivory","Pale","Gold")]
reference_names = beam_names+["UpperLanding__FloorA","UpperLanding__FloorB"]
references = load_objects(OUT / "GrandArcade_R01_Entrance.blend", reference_names, "Reference__")
baseline = load_objects(ROOT / "assets/grand_arcade/A01/GrandArcade_A01.blend", beam_names+["Platform__Floor"], "Baseline__")
floor_baseline = load_objects(ROOT / "assets/grand_arcade/connection_candidate/GrandArcadeConnection_C01.blend",
                             ["UpperLanding__FloorA","UpperLanding__FloorB"], "Baseline__")
mats = {}
for material in ("Ivory","Pale","Gold","FloorA","FloorB"):
    mats[material] = bpy.data.materials.new("Check__"+material)
stage = functions_from(STAGE, ["mapped","mesh","extend_entrance_terminal","curved_beam"],
                       {"bpy": bpy, "bmesh": bmesh, "math": math, "scene": scene, "MATS": mats,
                        "objects": [], "transform": None, "section": ""})
results = []
for side in (-1,1):
    stage["section"] = "FrontWing"+str(side)
    a,b = (math.radians(191),math.radians(256)) if side < 0 else (math.radians(284),math.radians(349))
    for material,z,width,height in [("Ivory",.25,1.7,.5),("Pale",2.7,1.3,.34),("Gold",2.90,1.12,.10)]:
        name = f"FrontWing{side}__{material}"
        obj = stage["curved_beam"](name,material,a,b,z,width,height)
        assert len(obj.data.vertices) == 188
        old_points = points(baseline[name])
        assert [tuple(vertex.co) for vertex in obj.data.vertices[:164]] == [tuple(point) for point in old_points]
        geometry = checks["mesh_checks"](obj)
        assert geometry["closed"] and geometry["outward"] and geometry["finite"] and geometry["degenerateTriangles"] == 0
        source_points = [point+Vector((0,49.5,4.2)) for point in points(obj)]
        ref_points = points(references[name])
        difference = max(min((point-ref).length for ref in ref_points) for point in source_points)
        assert len(source_points) == len(ref_points) and difference < .00002, (name,difference)
        results.append({"mesh": name, "closedOutward": True, "originalCurveRingsPreserved": 41,
                        "maximumCandidateDifferenceStuds": difference, "triangles": geometry["triangles"]})

connection = functions_from(CONNECTION,
                            ["mesh","height","profile","stage_front_boundary","stage_boundary_depth","upper_landing_tile"],
                            {"bpy": bpy, "math": math, "scene": scene, "MATS": mats, "groups": {}})
boundary = connection["stage_front_boundary"](ROOT / "assets/grand_arcade/A01/GrandArcade_A01.blend")
assert len(boundary) == 49
for row in range(3):
    near = 17.5+10*row/3+.028
    far = 17.5+10*(row+1)/3-.028
    for column in range(4):
        x0 = -9+column*4.5+.025
        x1 = x0+4.45
        material = "FloorA" if (row+column)%2 == 0 else "FloorB"
        connection["upper_landing_tile"](material,x0,x1,near,far,boundary)
floors = []
for material in ("FloorA","FloorB"):
    objects = connection["groups"][("UpperLanding",material)]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    name = "UpperLanding__"+material
    obj.name = name
    floors.append(obj)
    geometry = checks["mesh_checks"](obj)
    assert geometry["closed"] and geometry["outward"] and geometry["finite"] and geometry["degenerateTriangles"] == 0
    ref_points, source_points = points(references[name]), points(obj)
    difference = max(min((point-ref).length for ref in ref_points) for point in source_points)
    assert len(source_points) == len(ref_points) and difference < .00002, (name,difference)
    preserved = 0
    old = floor_baseline[name]
    old_points = points(old)
    for group in components(old):
        tile = [old_points[index] for index in group]
        if max(point.y for point in tile) < 25.2:
            assert all(tuple(point) in [tuple(p) for p in source_points] for point in tile)
            preserved += 1
    assert preserved == 4
    results.append({"mesh": name, "closedOutward": True, "originalTileComponentsPreserved": preserved,
                    "maximumCandidateDifferenceStuds": difference, "triangles": geometry["triangles"]})
floor_points = points(baseline["Platform__Floor"], Vector((0,49.5,4.2)))
top = max(point.z for point in floor_points)
checks["ellipse"] = [(point.x,point.y) for point in floor_points if abs(point.z-top) < 1e-6]
overlap = checks["floor_overlap"](floors)
assert overlap < 1e-8, overlap
report = {
    "status": "passed", "executed": "AST-extracted helpers only in an isolated background Blender process",
    "productionBuilderExecutions": 0, "productionOutputWrites": 0,
    "sourceFiles": [{"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in (STAGE,CONNECTION)],
    "meshes": results, "floorTriangleStageOverlapArea": overlap, "actualStageFrontBoundaryPoints": len(boundary),
    "collisionChanges": 0, "nativeProof": "None; candidate installation and walking belong to the main operator",
}
(OUT / "durable-source-checks.json").write_text(json.dumps(report, indent=2))
print("ENTRANCE_DURABLE_SOURCE " + json.dumps({"status": report["status"], "meshes": len(results), "overlapArea": overlap}))
