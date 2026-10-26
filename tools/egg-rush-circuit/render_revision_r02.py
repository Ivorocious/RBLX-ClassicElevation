"""Reconstruct the inspected native candidate in isolated, background Blender."""
from __future__ import annotations

import argparse
from collections import Counter
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector


REPO = Path(__file__).resolve().parents[2]
DEFAULT_INPUT = REPO / "docs/artifacts/egg-rush-circuit/phase2/revision-r02/candidate-visual.json"
DEFAULT_OUTPUT = DEFAULT_INPUT.parent / "views"
SOURCE_LIBRARIES = (
    "assets/egg_rush_circuit/phase1/candidate_c04/ER_phase1_kit.blend",
    "assets/egg_rush_circuit/world/candidate_c03/ER_world_kit.blend",
    "assets/egg_rush_circuit/phase1/restart_r01/candidate_k02/ER_P1_R01_kit.blend",
    "assets/egg_rush_circuit/guardian_sweep/candidate_c03/GuardianSweepTail.blend",
)
R_TO_B = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
B_TO_R = R_TO_B.transposed()
SOURCE_TO_NATIVE_MESH = Matrix.Diagonal((-1, 1, -1))
R01_LIBRARY = "assets/egg_rush_circuit/phase1/restart_r01/candidate_k02/ER_P1_R01_kit.blend"
MATERIALS = {}
MESH_CACHE = {}


def native_frame(values):
    if len(values) != 12 or not all(math.isfinite(v) for v in values):
        raise ValueError("A native CFrame must contain 12 finite numbers")
    rotation = Matrix((values[3:6], values[6:9], values[9:12]))
    if abs(rotation.determinant() - 1) > .003:
        raise ValueError("Native CFrame rotation is not orthonormal")
    frame = (R_TO_B @ rotation @ B_TO_R).to_4x4()
    frame.translation = R_TO_B @ Vector(values[:3])
    return frame


def material(rgb, alpha=1.0, missing=False):
    if missing:
        rgb, alpha = (1, .03, .65), .7
    key = tuple(round(float(v), 5) for v in rgb) + (round(alpha, 4),)
    if key in MATERIALS:
        return MATERIALS[key]
    mat = bpy.data.materials.new("NativeColor_%03d" % len(MATERIALS))
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    mat.diffuse_color = (*linear, alpha)
    mat.use_nodes = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*linear, 1)
    shader.inputs["Roughness"].default_value = .8
    shader.inputs["Alpha"].default_value = alpha
    if alpha < .999 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    MATERIALS[key] = mat
    return mat


def mesh_data(name, vertices, faces):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    return mesh


def load_sources(required):
    sources, archive_counts = {}, {}
    source_collection = bpy.data.collections.new("AuthorSources_Hidden")
    bpy.context.scene.collection.children.link(source_collection)
    for relative in SOURCE_LIBRARIES:
        blend = REPO / relative
        if not blend.is_file():
            archive_counts[relative] = {"exists": False, "loaded": 0}
            continue
        with bpy.data.libraries.load(str(blend), link=False) as (available, destination):
            names = tuple(name for name in available.objects if name in required and name not in sources
                          and (not name.startswith(("ER_GuardianBody__", "ER_GuardianTail__"))
                               or relative == R01_LIBRARY))
            destination.objects = list(names)
        objects = [obj for obj in destination.objects if obj is not None]
        for obj in objects:
            source_collection.objects.link(obj)
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        loaded = 0
        for original_name, obj in zip(names, objects):
            if obj.type != "MESH":
                continue
            evaluated = obj.evaluated_get(depsgraph)
            mesh = evaluated.to_mesh()
            vertices = [B_TO_R @ (evaluated.matrix_world @ vertex.co) for vertex in mesh.vertices]
            if not vertices:
                evaluated.to_mesh_clear()
                continue
            lower = Vector(tuple(min(vertex[axis] for vertex in vertices) for axis in range(3)))
            upper = Vector(tuple(max(vertex[axis] for vertex in vertices) for axis in range(3)))
            center, dimensions = (lower + upper) / 2, upper - lower
            normalized = [tuple((vertex[axis] - center[axis]) / dimensions[axis]
                                if dimensions[axis] > 1e-7 else 0 for axis in range(3))
                          for vertex in vertices]
            faces = [tuple(polygon.vertices) for polygon in mesh.polygons]
            sources[original_name] = {"vertices": normalized, "faces": faces,
                                      "library": relative, "source_dimensions": list(dimensions)}
            evaluated.to_mesh_clear()
            loaded += 1
        archive_counts[relative] = {"exists": True, "loaded": loaded}
    source_collection.hide_render = True
    source_collection.hide_viewport = True
    if required and not sources:
        raise RuntimeError("None of the requested native mesh names resolved to author source geometry")
    return sources, archive_counts


def primitive_geometry(shape):
    shape = str(shape).lower()
    if "ball" in shape or "sphere" in shape:
        vertices, faces = [], []
        segments, rings = 20, 10
        for ring in range(rings + 1):
            phi = math.pi * ring / rings
            for step in range(segments):
                theta = math.tau * step / segments
                vertices.append((.5 * math.sin(phi) * math.cos(theta),
                                 .5 * math.cos(phi), .5 * math.sin(phi) * math.sin(theta)))
        for ring in range(rings):
            for step in range(segments):
                a = ring * segments + step
                b = ring * segments + (step + 1) % segments
                faces.append((a, b, b + segments, a + segments))
        return vertices, faces
    if "cylinder" in shape:
        segments = 24
        vertices = [(x, .5 * math.cos(step * math.tau / segments),
                     .5 * math.sin(step * math.tau / segments))
                    for x in (-.5, .5) for step in range(segments)]
        faces = [tuple(reversed(range(segments))), tuple(range(segments, segments * 2))]
        faces += [(i, (i + 1) % segments, (i + 1) % segments + segments, i + segments)
                  for i in range(segments)]
        return vertices, faces
    if "wedge" in shape:
        vertices = [(-.5, -.5, -.5), (.5, -.5, -.5), (-.5, -.5, .5),
                    (.5, -.5, .5), (-.5, .5, .5), (.5, .5, .5)]
        faces = [(0, 2, 3, 1), (2, 4, 5, 3), (0, 1, 5, 4), (0, 4, 2), (1, 3, 5)]
        return vertices, faces
    vertices = [(x * .5, y * .5, z * .5) for z in (-1, 1) for y in (-1, 1) for x in (-1, 1)]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1),
             (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return vertices, faces


def add_part(record, sources, index, collection):
    name = record["name"]
    size = record["size"]
    is_mesh = bool(record.get("meshId")) or name in sources
    missing = is_mesh and name not in sources
    source_key = name if name in sources else "primitive:" + str(record.get("shape", "Block"))
    key = (source_key, tuple(round(float(v), 5) for v in size))
    if key not in MESH_CACHE:
        if name in sources:
            vertices, faces = sources[name]["vertices"], sources[name]["faces"]
        else:
            vertices, faces = primitive_geometry("Block" if missing else record.get("shape", "Block"))
        local_axes = SOURCE_TO_NATIVE_MESH if name in sources else Matrix.Identity(3)
        scaled = [tuple(R_TO_B @ local_axes @ Vector(tuple(vertex[axis] * size[axis] for axis in range(3))))
                  for vertex in vertices]
        MESH_CACHE[key] = mesh_data("CandidateGeometry_%04d" % len(MESH_CACHE), scaled, faces)
    obj = bpy.data.objects.new("%04d_%s" % (index, name), MESH_CACHE[key])
    collection.objects.link(obj)
    obj.matrix_world = native_frame(record["cf"])
    obj["NativePath"] = record.get("path", name)
    obj["Reconstruction"] = "MISSING_SOURCE_BOUNDING_BOX" if missing else ("SOURCE_MESH" if is_mesh else "NATIVE_PRIMITIVE")
    mat = material(record.get("color", (.7, .7, .7)), 1 - record.get("transparency", 0), missing)
    if not obj.data.materials:
        obj.data.materials.append(mat)
    obj.material_slots[0].link = "OBJECT"
    obj.material_slots[0].material = mat
    return obj, is_mesh, missing


def add_studs(record, collection):
    width, height, depth = record["size"]
    if height > 7 or width < 1 or depth < 1:
        return 0
    spacing = max(2, math.sqrt(width * depth / 100))
    nx, nz = max(1, int(width / spacing)), max(1, int(depth / spacing))
    vertices, faces = [], []
    for ix in range(nx):
        x = (ix - (nx - 1) / 2) * spacing
        for iz in range(nz):
            z = (iz - (nz - 1) / 2) * spacing
            start = len(vertices)
            for y in (height / 2, height / 2 + .075):
                vertices += [tuple(R_TO_B @ Vector((x + .23 * math.cos(j * math.tau / 8), y,
                                                    z + .23 * math.sin(j * math.tau / 8)))) for j in range(8)]
            faces.append(tuple(start + 8 + j for j in range(8)))
            faces += [(start + j, start + (j + 1) % 8, start + 8 + (j + 1) % 8, start + 8 + j) for j in range(8)]
    if not faces:
        return 0
    obj = bpy.data.objects.new("SparseApproximateStuds_" + record["name"], mesh_data("SparseStudGeometry", vertices, faces))
    collection.objects.link(obj)
    obj.matrix_world = native_frame(record["cf"])
    obj.data.materials.append(material(record["color"]))
    obj["Reconstruction"] = "SPARSE_APPROXIMATE_SURFACE_STUDS"
    return nx * nz


def look_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    if hasattr(scene, "eevee") and hasattr(scene.eevee, "taa_render_samples"):
        scene.eevee.taa_render_samples = 16
    scene.render.resolution_x, scene.render.resolution_y = 1500, 1050
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("NeutralBlueStudio")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (.76, .84, .92, 1)
    background.inputs["Strength"].default_value = .75
    for name, position, energy, light_size in (
            ("StudioKey", (-120, -180, 240), 950000, 150),
            ("StudioFill", (160, 90, 180), 450000, 160)):
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy, light_data.size = energy, light_size
        light = bpy.data.objects.new(name, light_data)
        scene.collection.objects.link(light)
        light.location = position
        look_at(light, (0, 0, 10))
    camera_data = bpy.data.cameras.new("ReviewCamera")
    camera_data.type = "ORTHO"
    camera_data.clip_end = 3000
    camera = bpy.data.objects.new("ReviewCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return scene, camera


def render_views(scene, camera, output):
    views = [
        ("00-whole-course", (0, 15, 6), (300, 330, 390), 395),
        ("01-nestyard", (-77, 5, 90), (70, 72, 68), 128),
        ("02-egg-rollers", (-115, 10, -32), (62, 66, 68), 115),
        ("03-shellworks", (-29, 20, -109), (64, 70, 68), 112),
        ("04-incubator", (72, 29, -66), (78, 72, 88), 122),
        ("05-rookery", (111, 32, 33), (68, 68, 70), 116),
        ("06-shell-spill", (60, 10, 119), (70, 68, 72), 120),
        ("07-guardian-head-tail", (77, 35, 48), (45, 55, 130), 112),
    ]
    records = []
    for name, target, offset, scale in views:
        camera.location = R_TO_B @ (Vector(target) + Vector(offset))
        look_at(camera, R_TO_B @ Vector(target))
        camera.data.ortho_scale = scale
        path = output / (name + ".png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        records.append({"name": name, "path": str(path), "target_roblox": target,
                        "offset_roblox": offset, "ortho_scale": scale})
    return records


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    data = json.loads(args.input.read_text(encoding="utf-8-sig"))
    args.output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    visible = [record for record in data["parts"] if record.get("transparency", 0) < .95]
    required = {record["name"] for record in visible if record.get("meshId")}
    sources, archives = load_sources(required)
    collection = bpy.data.collections.new("NativeCandidateReconstruction")
    bpy.context.scene.collection.children.link(collection)
    counts, missing, studies = Counter(), Counter(), 0
    for index, record in enumerate(visible):
        obj, is_mesh, failed = add_part(record, sources, index, collection)
        counts["source_mesh_parts" if is_mesh and not failed else "missing_mesh_boxes" if failed else "native_primitive_parts"] += 1
        if failed:
            missing[record["name"]] += 1
        if record.get("studs") and not is_mesh and record.get("route", True):
            studies += add_studs(record, collection)
    scene, camera = setup_scene()
    scene["EvidenceBoundary"] = "Offline geometry reconstruction from native candidate export and inspected Blender source meshes; not a native Studio render or gameplay proof."
    scene["Candidate"] = data.get("candidate", "unknown")
    blend_path = args.output / "candidate-reconstruction.blend"
    scene.render.use_file_extension = True
    bpy.context.preferences.filepaths.save_version = 0
    views = render_views(scene, camera, args.output)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    summary = {
        "candidate": data.get("candidate"), "input": str(args.input), "blend": str(blend_path),
        "evidence_boundary": scene["EvidenceBoundary"], "parts_in_export": len(data["parts"]),
        "visible_parts_reconstructed": len(visible), "counts": dict(counts),
        "unique_source_meshes": len(sources), "missing_source_meshes": dict(missing),
        "source_libraries": archives, "approximate_surface_studs": studies,
        "source_mapping": "Evaluated source world vertices converted to Roblox axes, centered and normalized per-object bounding box, scaled to native Size, rotated 180 degrees around local Y to match imported MeshPart axes, then placed by native course-local CFrame.",
        "source_version_overrides": {"GuardianBody": R01_LIBRARY, "GuardianTail": R01_LIBRARY},
        "source_version_evidence": "Native GuardianBody and GuardianTail per-material sizes match the R01 source dimensions times 3.6 to floating-point precision; older C04 shares names but has different geometry.",
        "import_axis_evidence": "Body model placement yaw +90 versus native mesh yaw -90, and sweep placement yaw -70 versus native mesh yaw +110, both establish the imported local Y180 rotation.",
        "mesh_sources": {name: {"library": record["library"], "source_dimensions_roblox": record["source_dimensions"]}
                         for name, record in sorted(sources.items())},
        "guardian_native_opacity": {record["name"]: record.get("transparency", 0) for record in visible
                                    if record["name"].startswith("ER_GuardianSweepTail__")},
        "transparency_boundary": "Parts with transparency >= 0.95 omitted; remaining transparency uses Blender material alpha.",
        "views": views,
    }
    all_corners = [obj.matrix_world @ Vector(corner) for obj in collection.objects
                   if obj.type == "MESH" and obj.get("Reconstruction") != "SPARSE_APPROXIMATE_SURFACE_STUDS"
                   for corner in obj.bound_box]
    roblox_corners = [B_TO_R @ corner for corner in all_corners]
    summary["bounds_roblox"] = {
        "min": [min(corner[axis] for corner in roblox_corners) for axis in range(3)],
        "max": [max(corner[axis] for corner in roblox_corners) for axis in range(3)],
    }
    summary["course_pivot_native_world"] = data.get("pivot")
    (args.output / "reconstruction-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print("RECONSTRUCTION_SUMMARY " + json.dumps({"counts": dict(counts), "missing": dict(missing), "views": len(views)}))


if __name__ == "__main__":
    main()
