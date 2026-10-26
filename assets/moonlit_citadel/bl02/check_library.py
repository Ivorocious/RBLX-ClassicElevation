"""Read-only source comparison in a fresh isolated Blender background process.

Prints evaluated geometry counts/bounds. Does not save, render, export, upload,
write reports or touch another Blender process. Existing BL01 files remain intact.
"""

import json
import math
from pathlib import Path
import types

import bmesh
import bpy


HERE = Path(__file__).resolve().parent


def load_source(path, name):
    module = types.ModuleType(name)
    module.__file__ = str(path)
    exec(compile(path.read_text(), str(path), "exec"), module.__dict__)
    return module


def inspect_object(obj):
    graph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(graph)
    mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=graph)
    try:
        # Match the existing export cleanup of cosmetic pointed-tip bevel slivers.
        cleanup = bmesh.new()
        cleanup.from_mesh(mesh)
        bmesh.ops.remove_doubles(cleanup, verts=list(cleanup.verts), dist=1e-6)
        bmesh.ops.dissolve_degenerate(cleanup, edges=list(cleanup.edges), dist=1e-6)
        bmesh.ops.recalc_face_normals(cleanup, faces=list(cleanup.faces))
        cleanup.to_mesh(mesh)
        cleanup.free()
        mesh.update()
        mesh.calc_loop_triangles()
        assert all(math.isfinite(value) for vertex in mesh.vertices for value in vertex.co)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bounds = [[min(vertex.co[axis] for vertex in mesh.vertices),
                   max(vertex.co[axis] for vertex in mesh.vertices)] for axis in range(3)]
        result = {
            "triangles": len(mesh.loop_triangles),
            "zero_area_triangles": sum(triangle.area <= 1e-16 for triangle in mesh.loop_triangles),
            "tiny_triangles": sum(triangle.area <= 1e-10 for triangle in mesh.loop_triangles),
            "vertices": len(mesh.vertices),
            "bounds": bounds,
            "boundary_edges": sum(edge.is_boundary for edge in bm.edges),
            "nonmanifold_edges": sum(not edge.is_manifold for edge in bm.edges),
            "signed_volume": bm.calc_volume(signed=True),
            "materials": [material.name for material in mesh.materials],
            "origin": list(obj.location),
        }
        bm.free()
        return result
    finally:
        evaluated.to_mesh_clear()


def build_revision(folder, key):
    collection = bpy.data.collections.new("MC_CHECK_" + key)
    bpy.context.scene.collection.children.link(collection)
    architecture = load_source(folder / "architecture.py", key + "_architecture")
    mechanisms = load_source(folder / "mechanisms.py", key + "_mechanisms")
    objects = architecture.build_library(collection) + mechanisms.build_library(collection)
    bpy.context.view_layer.update()
    result = {obj["AssetKey"]: inspect_object(obj) for obj in objects}
    for obj in objects:
        obj.name = "CHECK_" + key + "_" + obj["AssetKey"]
    return result


baseline = build_revision(HERE.parent / "bl01", "BL01")
revised = build_revision(HERE, "BL02")
assert baseline.keys() == revised.keys()
changes = {}
for name, record in revised.items():
    assert record["origin"] == baseline[name]["origin"] == [0.0, 0.0, 0.0]
    assert all(material.startswith("MC_BL02_") for material in record["materials"])
    assert record["boundary_edges"] == 0, (name, "open ends")
    assert record["nonmanifold_edges"] == 0, (name, "nonmanifold joins")
    assert record["zero_area_triangles"] == 0, (name, "degenerate triangles")
    assert record["signed_volume"] > 0, (name, "winding")
    changes[name] = {
        "before_triangles": baseline[name]["triangles"],
        "after_triangles": record["triangles"],
        "reduction_percent": round(100 * (1 - record["triangles"] / baseline[name]["triangles"]), 2),
        "before_bounds": baseline[name]["bounds"],
        "after_bounds": record["bounds"],
        "boundary_edges": record["boundary_edges"],
        "nonmanifold_edges": record["nonmanifold_edges"],
        "signed_volume": record["signed_volume"],
        "zero_area_triangles": record["zero_area_triangles"],
        "tiny_triangles": record["tiny_triangles"],
    }
print("MC_BL02_LIBRARY_CHECK " + json.dumps({
    "blender_version": bpy.app.version_string,
    "one_copy_before_triangles": sum(row["triangles"] for row in baseline.values()),
    "one_copy_after_triangles": sum(row["triangles"] for row in revised.values()),
    "assets": changes,
}, sort_keys=True))
