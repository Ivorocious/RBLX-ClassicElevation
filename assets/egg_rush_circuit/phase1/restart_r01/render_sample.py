"""Render only the saved R01 local Shellworks source poses in isolated Blender."""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[3]
DEFAULT_POSES = REPO / "docs/artifacts/egg-rush-circuit/phase1/restart-r01/sample-poses.json"
ARCHIVES = (
    (ROOT/"candidate_k02/ER_P1_R01_kit.blend", ROOT/"candidate_k02/manifest.json"),
    (ROOT.parent/"candidate_c04/ER_phase1_kit.blend", ROOT.parent/"candidate_c04/manifest.json"),
    (ROOT.parents[1]/"world/candidate_c03/ER_world_kit.blend", ROOT.parents[1]/"world/candidate_c03/manifest.json"),
)
R_TO_B = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
B_TO_R = R_TO_B.transposed()
MATERIALS = {}


def source_frame(values, origin):
    assert len(values) == 12 and all(math.isfinite(v) for v in values)
    position = R_TO_B @ (Vector(values[:3])-origin)
    rotation = Matrix((values[3:6], values[6:9], values[9:12]))
    assert abs(rotation.determinant()-1) < .001, "Expected an orthonormal native CFrame"
    result = (R_TO_B @ rotation @ B_TO_R).to_4x4()
    result.translation = position
    return result


def native_scale(values):
    assert len(values) == 3 and all(math.isfinite(v) and v > 0 for v in values)
    return Matrix.Diagonal((values[0], values[2], values[1], 1))


def material(rgb, neon=False):
    key = tuple(round(v, 6) for v in rgb)+(bool(neon),)
    if key in MATERIALS:
        return MATERIALS[key]
    result = bpy.data.materials.new("Native_"+str(len(MATERIALS)))
    linear = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    result.diffuse_color = (*linear, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*linear, 1)
    shader.inputs["Roughness"].default_value = .77
    if neon:
        shader.inputs["Emission Color"].default_value = (*linear, 1)
        shader.inputs["Emission Strength"].default_value = .8
    MATERIALS[key] = result
    return result


def mesh_object(name, vertices, faces, mat, transform=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if transform is not None:
        obj.matrix_world = transform
    return obj


def box(name, dimensions, transform, mat):
    a, b, c = (v/2 for v in dimensions)
    vertices = [(x*a, y*b, z*c) for z in (-1, 1) for y in (-1, 1) for x in (-1, 1)]
    return mesh_object(name, vertices,
                       [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
                        (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)], mat, transform)


def load_author_sources(required):
    available, manifests = {}, {}
    for blend_path, manifest_path in ARCHIVES:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifests[str(blend_path)] = dict(manifest=manifest_path, data=data)
        for record in data["assets"]:
            if record["name"] not in available:
                available[record["name"]] = (blend_path, record)
    missing = required-set(available)
    assert not missing, "No admitted source archive for: "+", ".join(sorted(missing))
    grouped = defaultdict(list)
    for name in sorted(required):
        grouped[available[name][0]].append(name)
    sources = {}
    for blend_path, names in grouped.items():
        collection_names = ["AUTHOR_"+name for name in names]
        with bpy.data.libraries.load(str(blend_path), link=False) as (source, destination):
            absent = set(collection_names)-set(source.collections)
            assert not absent, f"Missing original source collections in {blend_path}: {sorted(absent)}"
            destination.collections = collection_names
        collections = dict(zip(names, destination.collections))
        for name in names:
            collection = collections[name]
            parts = [obj for obj in collection.all_objects if obj.type == "MESH"
                     and obj.name.startswith("ER_"+name+"__")]
            record = available[name][1]
            assert len(parts) == len(record["parts"]), (name, "source/material part count mismatch")
            assert not any(obj.parent for obj in parts), (name, "unexpected source object parent")
            assert all(obj.location.length < .0001 and obj.rotation_euler.to_matrix().is_identity
                       and (obj.scale-Vector((1, 1, 1))).length < .0001 for obj in parts), (name, "inspect source transforms")
            sources[name] = parts
    return sources, grouped


def add_art(data, sources, origin):
    count = 0
    for index, record in enumerate(data["art"]):
        frame = source_frame(record["pivotCFrame"], origin) @ native_scale(record["scale"])
        for source in sources[record["asset"]]:
            obj = source.copy()
            obj.data = source.data
            obj.name = f"Sample_{index:03d}_{source.name}"
            bpy.context.scene.collection.objects.link(obj)
            obj.hide_viewport = False
            obj.hide_render = False
            obj.hide_set(False)
            obj.matrix_world = frame @ source.matrix_basis
            obj["OfflineSourcePath"] = record["path"]
            obj["OfflineAsset"] = record["asset"]
            count += 1
    return count


def stud_patch(name, size, frame, mat):
    width, height, depth = size
    vertices, faces = [], []
    count_x = max(1, int(math.floor(width)))
    count_y = max(1, int(math.floor(depth)))
    for ix in range(count_x):
        x = (ix-(count_x-1)/2)
        for iy in range(count_y):
            y = (iy-(count_y-1)/2)
            if abs(x)+.2 > width/2 or abs(y)+.2 > depth/2:
                continue
            start = len(vertices)
            for z in (height/2, height/2+.07):
                vertices += [(x+.2*math.cos(j*math.tau/12), y+.2*math.sin(j*math.tau/12), z)
                             for j in range(12)]
            faces += [tuple(start+12+j for j in range(12))]
            faces += [(start+j, start+(j+1)%12, start+12+(j+1)%12, start+12+j)
                      for j in range(12)]
    if faces:
        return mesh_object(name+"_ApproximateStuds", vertices, faces, mat, frame)
    return None


def choice_text(record, frame):
    text = record["name"][len("Choice_"):]
    font = bpy.data.curves.new("ChoiceText", "FONT")
    font.body, font.align_x, font.align_y = text, "CENTER", "CENTER"
    font.size = .58
    obj = bpy.data.objects.new("OfflineLabel_"+text, font)
    bpy.context.scene.collection.objects.link(obj)
    font.materials.append(material((1, 240/255, 202/255)))
    depth = record["size"][2]
    text_frame = Matrix(((-1, 0, 0, 0), (0, 0, 1, depth/2+.015),
                         (0, 1, 0, 0), (0, 0, 0, 1)))
    obj.matrix_world = frame @ text_frame
    bpy.context.view_layer.update()
    if obj.dimensions.x > record["size"][0]-.5:
        ratio = (record["size"][0]-.5)/obj.dimensions.x
        obj.scale *= ratio


def add_native(data, origin):
    count = 0
    for record in data["nativeParts"]:
        transparency = record.get("transparency", 0)
        if transparency >= .95:
            continue
        assert transparency < .05, (record["name"], "unexpected translucent local source part")
        frame = source_frame(record["cframe"], origin)
        x, y, z = record["size"]
        mat = material(record["color"], "Neon" in record.get("material", ""))
        obj = box(record["name"], (x, z, y), frame, mat)
        obj["OfflineSourcePath"] = record["path"]
        count += 1
        if "Studs" in record.get("topSurface", ""):
            stud_patch(record["name"], record["size"], frame, mat)
        if record["name"].startswith("Choice_"):
            choice_text(record, frame)
    return count


def add_marker(position):
    mat = material((.58, .62, .69))
    units = [((-.5, 0, 1.1), (.8, .9, 2.2)), ((.5, 0, 1.1), (.8, .9, 2.2)),
             ((0, 0, 3.3), (2, 1, 2.2)), ((0, 0, 4.95), (1.1, 1, 1.1)),
             ((-1.4, 0, 3.3), (.7, .9, 2.1)), ((1.4, 0, 3.3), (.7, .9, 2.1))]
    for index, (offset, size) in enumerate(units):
        box("PreviewOnly_ScaleMarker_"+str(index), size,
            Matrix.Translation(position+Vector(offset)), mat)


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.render.resolution_x, scene.render.resolution_y = 2048, 1365
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.world = bpy.data.worlds.new("OfflineNeutralWorld")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.55, .62, .7, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .8
    light_data = bpy.data.lights.new("LocalSampleKey", "AREA")
    light_data.energy, light_data.size = 170000, 90
    light = bpy.data.objects.new("LocalSampleKey", light_data)
    scene.collection.objects.link(light)
    light.location = (-85, 80, 95)
    light.rotation_euler = (Vector((-45, 120, 14))-light.location).to_track_quat("-Z", "Y").to_euler()
    camera_data = bpy.data.cameras.new("OfflineSampleCamera")
    camera = bpy.data.objects.new("OfflineSampleCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    scene.render.use_stamp = True
    for option in ("date", "time", "render_time", "frame", "frame_range", "memory", "hostname", "camera", "lens", "scene", "marker", "filename", "sequencer_strip"):
        attribute = "use_stamp_"+option
        if hasattr(scene.render, attribute):
            setattr(scene.render, attribute, False)
    scene.render.use_stamp_note = True
    scene.render.stamp_note_text = "OFFLINE SOURCE ASSEMBLY | ER_P1_R01 Shellworks | Not Studio or playable proof"
    scene.render.stamp_font_size = 16
    return camera


def fit_oblique(camera):
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.hide_render]
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    low = Vector([min(p[i] for p in points) for i in range(3)])
    high = Vector([max(p[i] for p in points) for i in range(3)])
    target = (low+high)/2
    camera.data.type = "ORTHO"
    camera.location = target+Vector((-105, -110, 92))
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    inverse = camera.matrix_world.inverted()
    projected = [inverse @ p for p in points]
    width = max(p.x for p in projected)-min(p.x for p in projected)
    height = max(p.y for p in projected)-min(p.y for p in projected)
    scene = bpy.context.scene
    camera.data.ortho_scale = max(width, height*scene.render.resolution_x/scene.render.resolution_y)*1.12


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--poses", type=Path, default=DEFAULT_POSES)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--decision", action="store_true", help="Also render a player decision-height perspective.")
    parser.add_argument("--save-blend", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    out = args.out.resolve()
    if out.exists() and any(out.iterdir()):
        raise RuntimeError("Fresh empty/absent preview output directory required.")
    data = json.loads(args.poses.read_text(encoding="utf-8"))
    assert data["candidateId"] == "ER_P1_R01" and data["phase"] == 1
    assert len(data["art"]) > 0 and len(data["mechanisms"]) == 9
    assert all("Shellworks_R01" in record["path"] or ".Mechanisms." in record["path"]
               for record in data["art"]), "Only local sample art is allowed"
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    origin = Vector(data["origin"])
    sources, grouped = load_author_sources({r["asset"] for r in data["art"]})
    art_parts = add_art(data, sources, origin)
    native_parts = add_native(data, origin)
    decision = R_TO_B @ (Vector(data["decisionPoint"])-origin)
    add_marker(decision)
    bpy.context.view_layer.update()
    camera = setup_scene()
    bpy.context.view_layer.update()
    fit_oblique(camera)
    scene = bpy.context.scene
    scene.render.filepath = str(out/"Shellworks_R01_offline_oblique.png")
    bpy.ops.render.render(write_still=True)
    if args.decision:
        for obj in scene.objects:
            if obj.name.startswith("PreviewOnly_ScaleMarker_"):
                obj.hide_render = True
        camera.data.type, camera.data.lens = "PERSP", 30
        camera.location = decision+Vector((-4.5, 0, 4.7))
        target = decision+Vector((28, 1, 2))
        camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(out/"Shellworks_R01_offline_decision.png")
        bpy.ops.render.render(write_still=True)
    if args.save_blend:
        bpy.ops.wm.save_as_mainfile(filepath=str(out/"Shellworks_R01_offline.blend"))
    source_paths = [Path(p) if Path(p).is_absolute() else REPO/p for p in data.get("sourcePaths", [])]
    receipt = dict(candidate="ER_P1_R01", evidence="Offline source assembly; not Studio/playable proof",
                   poses=str(args.poses.resolve()), posesSHA256=hashlib.sha256(args.poses.read_bytes()).hexdigest(),
                   sourceSHA256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths},
                   archiveSHA256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in grouped},
                   authorCollections={str(p): ["AUTHOR_"+name for name in names] for p, names in grouped.items()},
                   artModels=len(data["art"]), artMaterialParts=art_parts, nativeVisibleParts=native_parts,
                   mechanismPose="Exact open rest frames from saved Sample output; runtime not started",
                   marker="Preview-only5.5-stud scale marker on saved fork decisionPoint",
                   approximations="Native Studs surfaces approximated with low broad discs; SurfaceGui choice text re-created from part names; neutral offline lighting",
                   outputFiles=[p.name for p in sorted(out.iterdir())],
                   caveat="No native import, contact, moving-camera, traversal, crowd, FPS or owner-acceptance result follows from this render.")
    (out/"offline-render-receipt.json").write_text(json.dumps(receipt, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(dict(artModels=len(data["art"]), artParts=art_parts, nativeParts=native_parts,
                          previews=receipt["outputFiles"])), flush=True)


if __name__ == "__main__":
    main()
