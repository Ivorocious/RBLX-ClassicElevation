"""Run only durable bay definitions and compare them with the reviewed candidates."""
import ast
import bmesh
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector, kdtree

ROOT = Path(__file__).resolve().parent
ASSET = ROOT.parent
manifest = json.loads((ASSET/"A01/manifest.json").read_text())
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
materials = {}
for name,color in manifest["colors"].items():
    material = bpy.data.materials.new("Verify_"+name)
    material.diffuse_color = (*color,1)
    materials[name] = material


def run_bay_definitions(path, function_names, loop_name):
    parsed = ast.parse(path.read_text())
    constants = {"PANEL_WIDTH","PANEL_HEIGHT","PANEL_Z","PLAQUE_Z","KEY_HALF_ANGLE"}
    nodes = []
    for node in parsed.body:
        if isinstance(node,ast.FunctionDef) and node.name in function_names:
            nodes.append(node)
        elif isinstance(node,ast.Assign):
            names = {value.id for target in node.targets for value in ast.walk(target) if isinstance(value,ast.Name)}
            if names and names <= constants:
                nodes.append(node)
        elif isinstance(node,ast.For) and isinstance(node.target,ast.Name) and node.target.id == loop_name:
            if loop_name == "bay" or ast.unparse(node.iter) == "range(5)":
                nodes.append(node)
    assert sum(isinstance(node,ast.For) for node in nodes) == 1
    namespace = {"bpy":bpy,"bmesh":bmesh,"math":math,"Vector":Vector,"scene":scene,
        "MATS":materials,"materials":materials,"objects":[],"added":[],"colliders":[],
        "sections":{},"bays":[],"manifest":manifest,"section":"Bay1","transform":None}
    module = ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[]))
    exec(compile(module,str(path),"exec"),namespace)
    return namespace


base = run_bay_definitions(ASSET/"build_stage.py",
    {"mapped","mesh","box","extrude","lathe","bay_arch_section"},"i")
trim = run_bay_definitions(ASSET/"quality_candidate/build_trim.py",
    {"mapped","mesh","box","bay_arch_trim","panel_ring"},"bay")
source_groups = {}
for obj in base["objects"] + trim["added"]:
    source_groups.setdefault(obj["Section"]+"__"+obj["Material"],[]).append(obj)


def components(data):
    neighbors = [set() for _ in data.vertices]
    for edge in data.edges:
        a,b = edge.vertices
        neighbors[a].add(b)
        neighbors[b].add(a)
    remaining = set(range(len(data.vertices)))
    result = []
    while remaining:
        pending, found = [min(remaining)], set()
        while pending:
            vertex = pending.pop()
            if vertex in found:
                continue
            found.add(vertex)
            pending.extend(neighbors[vertex]-found)
        remaining.difference_update(found)
        ids = sorted(found)
        remap = {old:new for new,old in enumerate(ids)}
        vertices = [tuple(data.vertices[i].co) for i in ids]
        faces = [[remap[i] for i in face.vertices] for face in data.polygons if face.vertices[0] in found]
        temporary = bpy.data.meshes.new("SourceValidation")
        temporary.from_pydata(vertices,[],faces)
        bm = bmesh.new()
        bm.from_mesh(temporary)
        volume = bm.calc_volume(signed=True)
        assert volume > 1e-8 and all(edge.is_manifold for edge in bm.edges)
        area = sum(face.calc_area() for face in bm.faces)
        bm.free()
        bpy.data.meshes.remove(temporary)
        result.append({"vertices":vertices,"volume":volume,"area":area,
            "bounds":[[min(v[axis] for v in vertices) for axis in range(3)],
                      [max(v[axis] for v in vertices) for axis in range(3)]]})
    return result


records = []
for folder,stem in [(ROOT/"R01_bays","GrandArcade_R01_Bay3"),
                    (ROOT/"R01_bays_remaining","GrandArcade_R01_BaysRemaining")]:
    candidate = json.loads((folder/"bay-manifest.json").read_text())
    names = [name for name,row in candidate["meshes"].items() if "replaces" in row]
    with bpy.data.libraries.load(str(folder/(stem+".blend")),link=False) as (available,requested):
        requested.objects = names
    for obj in requested.objects:
        name = obj.name.removeprefix("R01_")
        actual = [component for member in source_groups[name] for component in components(member.data)]
        expected = components(obj.data)
        assert len(actual) == len(expected), name
        distances = []
        for item in expected:
            matches = [value for value in actual if len(value["vertices"]) == len(item["vertices"])
                and max(abs(value["bounds"][i][j]-item["bounds"][i][j]) for i in range(2) for j in range(3)) < 1e-4]
            assert len(matches) == 1, (name,item["bounds"])
            match = matches[0]
            tree = kdtree.KDTree(len(match["vertices"]))
            for index,vertex in enumerate(match["vertices"]):
                tree.insert(vertex,index)
            tree.balance()
            maximum = max(tree.find(vertex)[2] for vertex in item["vertices"])
            assert maximum < 1e-4 and abs(match["volume"]-item["volume"]) < 1e-3
            assert abs(match["area"]-item["area"]) < 1e-3
            distances.append(maximum)
            actual.remove(match)
        records.append({"group":name,"components":len(expected),"maxVertexDeviation":max(distances)})
assert len(base["bays"]) == 5 and sum(len(bay["slots"]) for bay in base["bays"]) == 15
assert all(bay["screen"][2] == 14 and bay["plaque"][2] == 6.6 for bay in base["bays"])
report = {"state":"passed","groups":records,"bayCount":5,"rankSlots":15,
    "verifiedComponents":sum(row["components"] for row in records),
    "maxVertexDeviation":max(row["maxVertexDeviation"] for row in records),
    "method":"Executed only bay constants, helpers and bay loops in an isolated Blender process. Compared closed geometry, bounds, vertices, surface area and signed volume with center and remaining candidates.",
    "preservedOutputs":"No original builder output, manifest, .blend or .fbx was rewritten.",
    "nativeLimit":"Does not verify Roblox import or native display rendering."}
(ROOT/"R01_bays_remaining/future-source-validation.json").write_text(json.dumps(report,indent=2))
print("BAY_SOURCE_PARITY "+json.dumps(report))
