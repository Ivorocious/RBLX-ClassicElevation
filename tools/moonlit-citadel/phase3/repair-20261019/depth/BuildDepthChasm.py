"""Build a new, measured two-part chasm kit in isolated background Blender."""
import collections
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector
from mathutils.kdtree import KDTree

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
OUT = HERE / "dp01f"
spec = importlib.util.spec_from_file_location("depth_recipe", HERE / "DepthChasmRecipe.py")
recipe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recipe)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def axis(point):
    return (point[0], -point[2], point[1])


def roblox(point):
    return (point[0], point[2], -point[1])


def reduced_cap(data):
    selected = [f for f, role in zip(data["faces"], data["materials"]) if role == "RockUnderside"]
    used = sorted({v for f in selected for v in f})
    remap = {old: new for new, old in enumerate(used)}
    mesh = bpy.data.meshes.new("Temporary_Constrained_Underside")
    mesh.from_pydata([axis(data["vertices"][v]) for v in used], [], [tuple(remap[v] for v in f) for f in selected])
    mesh.update()
    original_area = sum(p.area for p in mesh.polygons)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.normal_update()
    boundary = {tuple(round(x, 5) for x in v.co) for e in bm.edges if e.is_boundary for v in e.verts}
    internal = [v for v in bm.verts if all(not e.is_boundary for e in v.link_edges)]
    print("DEPTH_CAP_DEBUG", len(bm.faces), len(bm.edges), len(internal), sum(e.is_boundary for e in bm.edges),
          min(v.co.z for v in bm.verts), max(v.co.z for v in bm.verts), tuple(next(iter(bm.faces)).normal), flush=True)
    bmesh.ops.dissolve_limit(bm, angle_limit=.01, use_dissolve_boundaries=False,
                             verts=internal, edges=[e for e in bm.edges if not e.is_boundary], delimit=set())
    print("DEPTH_CAP_DISSOLVED", len(bm.faces), flush=True)
    bmesh.ops.triangulate(bm, faces=list(bm.faces), quad_method="FIXED", ngon_method="EAR_CLIP")
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    assert abs(sum(p.area for p in mesh.polygons) - original_area) < .1
    now_boundary = {tuple(round(x, 5) for x in v.co) for edge in mesh.edges for v in []}
    check = bmesh.new()
    check.from_mesh(mesh)
    now_boundary = {tuple(round(x, 5) for x in v.co) for e in check.edges if e.is_boundary for v in e.verts}
    check.free()
    assert boundary == now_boundary, "Underside reduction changed the exact side boundary"
    result = ([roblox(v.co) for v in mesh.vertices], [tuple(p.vertices) for p in mesh.polygons])
    report = {"originalTriangles": len(selected), "reducedTriangles": len(result[1]),
              "area": original_area, "boundaryVerticesExact": True}
    bpy.data.meshes.remove(mesh)
    return result, report


def material(name, rgb):
    m = bpy.data.materials.new(name)
    m.diffuse_color = tuple(x / 255 for x in rgb) + (1,)
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = m.diffuse_color
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .92
    return m


def surface_key(points):
    row = [tuple(round(x, 4) for x in p) for p in points]
    return min(tuple(row[i:] + row[:i]) for i in range(3))


def indexed_face(values):
    return min(tuple(values[i:] + values[:i]) for i in range(3))


def main():
    assert bpy.app.background and not OUT.exists(), "Preserve existing drafts and use isolated background Blender"
    binding = json.loads((HERE / "fresh54-depth-binding.json").read_text())
    assert binding["pass"] and binding["sha256"] == "c7cb26d6c08ffd1251844fb5076396ab846069f9247e971abec92dac8506d158"
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if hasattr(bpy.context.preferences.filepaths, "use_save_preview"):
        bpy.context.preferences.filepaths.use_save_preview = False
    data = recipe.build()
    (cap_vertices, cap_faces), cap_report = reduced_cap(data)
    print("DEPTH_CAP " + json.dumps(cap_report), flush=True)
    groups = {"RockTop": ([], []), "DeepRock": ([], [])}
    for role in groups:
        chosen = [f for f, source_role in zip(data["faces"], data["materials"])
                  if source_role == "RockTop"] if role == "RockTop" else [f for f, source_role in zip(data["faces"], data["materials"]) if source_role not in ("RockTop", "RockUnderside")]
        used = sorted({v for f in chosen for v in f})
        mapping = {old: new for new, old in enumerate(used)}
        vertices = [data["vertices"][v] for v in used]
        faces = [tuple(mapping[v] for v in f) for f in chosen]
        if role == "DeepRock":
            offset = len(vertices)
            vertices.extend(cap_vertices)
            faces.extend(tuple(offset + v for v in f) for f in cap_faces)
        groups[role] = vertices, faces
    OUT.mkdir()
    root = bpy.data.collections.new("DP01_CourseLocal_Export_Parts")
    bpy.context.scene.collection.children.link(root)
    objects, records = [], []
    authored = {"axes": "Roblox=(BlenderX,BlenderZ,-BlenderY)", "parts": []}
    all_vertices, all_faces = [], []
    for role, (vertices, faces) in groups.items():
        name = recipe.ASSET + "__" + role
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([axis(v) for v in vertices], [], faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        root.objects.link(obj)
        rgb = (100, 112, 116) if role == "RockTop" else (53, 69, 91)
        mesh.materials.append(material("DP01_" + role, rgb))
        obj["SourceAsset"], obj["SourceMaterial"] = recipe.ASSET, role
        obj["NativeCanCollide"], obj["NativeCanQuery"], obj["NativeCanTouch"] = False, False, False
        obj["IntendedBasePivot"] = [0, 0, 0]
        assert len(faces) < 15000, (role, len(faces))
        vertices = [roblox(v.co) for v in mesh.vertices]
        low = [min(v[i] for v in vertices) for i in range(3)]
        high = [max(v[i] for v in vertices) for i in range(3)]
        records.append({"name": name, "asset": recipe.ASSET, "material": role, "rgb": list(rgb),
                        "roblox_center": [(low[i] + high[i]) / 2 for i in range(3)],
                        "roblox_size": [high[i] - low[i] for i in range(3)], "triangles": len(faces)})
        authored["parts"].append({"name": name, "vertices": vertices, "triangles": [list(f) for f in faces]})
        offset = len(all_vertices)
        all_vertices.extend(vertices)
        all_faces.extend(tuple(offset + v for v in f) for f in faces)
        objects.append(obj)
    welded, remap = {}, {}
    for i, vertex in enumerate(all_vertices):
        key = tuple(round(x, 4) for x in vertex)
        if key not in welded:
            welded[key] = len(welded)
        remap[i] = welded[key]
    edges = collections.Counter(tuple(sorted((remap[f[i]], remap[f[(i + 1) % 3]]))) for f in all_faces for i in range(3))
    directed = collections.Counter((remap[f[i]], remap[f[(i + 1) % 3]]) for f in all_faces for i in range(3))
    assert all(n == 2 for n in edges.values()), "Assembled exterior must remain closed after cap reduction"
    assert all(directed[(b, a)] == n for (a, b), n in directed.items())
    proof = data["proof"]
    proof.update({"parts": 2, "newTriangles": len(all_faces), "undersideReduction": cap_report,
                  "materialTriangles": {r["material"]: r["triangles"] for r in records},
                  "fresh54ModelsSha256": binding["sha256"], "roundedWeldTolerance": .0001,
                  "combinedBudget": {"units": 320, "meshes": 880, "triangles": 282944 - 30716 + len(all_faces)}})
    assert proof["combinedBudget"]["triangles"] < 420000
    manifest = {"candidate": "MC_DEPTH_DP01_DRAFT", "asset": recipe.ASSET,
                "axes": authored["axes"], "basePivot": [0, 0, 0], "units": "1 Blender unit = 1 intended stud",
                "export_parts": records, "part_count": 2, "export_triangles": len(all_faces),
                "bounds": proof["bounds"], "assembledClosed": True,
                "physics": {"collide": False, "query": False, "touch": False}, "proof": proof,
                "inputHashes": {str(p.relative_to(ROOT)).replace("\\", "/"): sha(p) for p in (Path(__file__), HERE / "DepthChasmRecipe.py", HERE / "source54-depth-inputs.json", HERE / "fresh54-depth-binding.json")}}
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.context.scene.unit_settings.system = "NONE"
    bpy.context.scene.unit_settings.scale_length = 1
    blend = OUT / "MC_DEPTH_CHASM_DP01.blend"
    fbx = OUT / "MC_DEPTH_CHASM_DP01.fbx"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS", bake_space_transform=False,
                             use_mesh_modifiers=True, mesh_smooth_type="FACE", use_triangles=True, add_leaf_bones=False,
                             path_mode="AUTO", use_custom_props=False, bake_anim=False)
    expected = {}
    for part in authored["parts"]:
        unique = {tuple(point): index for index, point in enumerate(dict.fromkeys(tuple(p) for p in part["vertices"]))}
        tree = KDTree(len(unique))
        for point, index in unique.items():
            tree.insert(point, index)
        tree.balance()
        expected[part["name"]] = {
            "tree": tree,
            "faces": collections.Counter(indexed_face([unique[tuple(part["vertices"][i])] for i in face]) for face in part["triangles"]),
        }
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(fbx), use_custom_normals=True)
    actual, max_error = {}, 0
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        points = [roblox(obj.matrix_world @ v.co) for v in obj.data.vertices]
        mapped = []
        for point in points:
            _, index, error = expected[obj.name]["tree"].find(point)
            assert error < .001, (obj.name, error)
            max_error = max(max_error, error)
            mapped.append(index)
        actual[obj.name] = collections.Counter(indexed_face([mapped[i] for i in p.vertices]) for p in obj.data.polygons)
    assert actual.keys() == expected.keys()
    assert all(actual[name] == expected[name]["faces"] for name in expected), "FBX oriented triangle surface changed"
    manifest["fbxRoundtripOrientedTrianglesExact"] = True
    manifest["fbxMaximumVertexError"] = max_error
    manifest["files"] = {p.name: {"bytes": p.stat().st_size, "sha256": sha(p)} for p in (blend, fbx)}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (OUT / "authored-geometry.json").write_text(json.dumps(authored, separators=(",", ":")) + "\n", encoding="utf-8")
    (OUT / "recipe-proof.json").write_text(json.dumps(proof, indent=2) + "\n", encoding="utf-8")
    print("DEPTH_KIT_PASS " + json.dumps({"parts": 2, "triangles": len(all_faces), "combined": proof["combinedBudget"], "cap": cap_report}), flush=True)


if __name__ == "__main__":
    main()
