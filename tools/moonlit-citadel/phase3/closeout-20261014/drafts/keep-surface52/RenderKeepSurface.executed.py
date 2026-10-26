"""Compare one native-axis material depth correction in an isolated actual assembly."""
import hashlib
import importlib.util
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
SOURCE = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/drafts/crown-refinement/render02/MC_CROWN_REFINEMENT_CANDIDATE.blend"
PLAN = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan51.json"
TRACE = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before/closeout_moving_keepwindows51.json"
HELPER = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/drafts/crown-refinement/RenderCrownRefinement.py"
spec = importlib.util.spec_from_file_location("frozen_render_helpers", HELPER)
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
AXIS, INVERSE = helpers.AXIS, helpers.INVERSE


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def native_camera(collection, name, sample):
    row = list(sample["cf"])
    row[0] -= 4000
    row[1] -= 300
    row[2] -= 2600
    data = bpy.data.cameras.new(name)
    camera = bpy.data.objects.new(name, data)
    collection.objects.link(camera)
    camera.matrix_world = AXIS @ helpers.frame(row)
    data.sensor_fit, data.type, data.clip_start, data.clip_end = "VERTICAL", "PERSP", .05, 3000
    data.angle_y = math.radians(70)
    camera["NativeSource51Frame"] = sample["cf"]
    return camera, row


def window_visibility(scene, windows, cameras):
    graph = bpy.context.evaluated_depsgraph_get()
    result = []
    for camera, row in cameras:
        counts, outcomes = {}, []
        for obj in sorted(windows, key=lambda o: o.name):
            for face in obj.data.polygons:
                verts = [obj.matrix_world @ obj.data.vertices[i].co for i in face.vertices]
                centre = sum(verts, Vector()) / len(verts)
                points = [centre] + [centre * .25 + vertex * .75 for vertex in verts]
                for target in points:
                    delta = target - camera.location
                    hit, point, normal, index, blocker, matrix = scene.ray_cast(graph, camera.location, delta.normalized(), distance=delta.length + .001)
                    label = blocker.get("Source50Unit", blocker.name) if hit else "NoHit"
                    counts[label] = counts.get(label, 0) + 1
                    outcomes.append(label)
        result.append({"camera":camera.name, "sampleCount":len(outcomes), "hitCounts":counts,
                       "outcomeSHA256":hashlib.sha256(json.dumps(outcomes).encode()).hexdigest(),
                       "changedPartHits":counts.get("GrandRearCentralPinnacle", 0)})
    return result


def main():
    assert bpy.app.background
    out = HERE / "render01"
    assert not out.exists(), "Preserve earlier evidence."
    out.mkdir()
    source_sha, plan_sha = sha(SOURCE), sha(PLAN)
    trace = json.loads(TRACE.read_text())
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    if hasattr(bpy.context.preferences.filepaths, "use_save_preview"):
        bpy.context.preferences.filepaths.use_save_preview = False
    scene = bpy.context.scene
    scene.cycles.samples = 12
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1600, 900, 100
    world = list(bpy.data.collections["Final_233_World_Units"].all_objects)
    protected = list(bpy.data.collections["Unchanged_Source49_Visible_Course"].all_objects)
    assert len(world) == 639 and len(protected) == 717
    light = bpy.data.objects["GrandRearCentralPinnacle__StoneLight"]
    assert light.get("AssetKey") == "MC_TL_GrandPinnacle"
    others = [o for o in world if o != light]
    windows = [o for o in world if str(o.get("Source50Unit", "")).startswith("UpperKeepWarmLancet")]
    assert len(windows) == 14
    protected_digest, others_digest, windows_digest = [helpers.geometry_digest(objects) for objects in (protected, others, windows)]
    old_light_matrix = list(v for row in light.matrix_world for v in row)
    old_mesh_digest = helpers.geometry_digest([light])
    collection = bpy.data.collections.new("Keep_Surface52_Comparison")
    scene.collection.children.link(collection)
    cameras = [native_camera(collection, name, sample) for name,sample in (
        ("NativeA", trace["frames"][0]), ("NativeB", max(trace["frames"], key=lambda f: f["cf"][0])))]
    sun = bpy.data.lights["Inspection_Sun"]
    background = scene.world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (.14, .20, .32, 1)
    background.inputs["Strength"].default_value = .55
    sun.energy, sun.color = .8, (.60, .72, 1)
    views = []
    visibility_before = window_visibility(scene, windows, cameras)
    for state in ("source51", "candidate52"):
        if state == "candidate52":
            # Actual native part Z is raw Blender mesh Y; its centre stays exact.
            light.matrix_world = light.matrix_world @ Matrix.Diagonal((1, 1.04, 1, 1))
            light["NativePartLocalScaleOverride"] = (1, 1, 1.04)
            bpy.context.view_layer.update()
        for camera, row in cameras:
            name = state + "-" + camera.name + "-night"
            path = out / (name + ".png")
            scene.camera = camera
            scene.render.filepath = str(path)
            print("RENDER_START " + name, flush=True)
            bpy.ops.render.render(write_still=True)
            views.append({"name":name, "file":path.name, "sha256":sha(path), "bytes":path.stat().st_size,
                          "cameraCourseLocal":row, "verticalFOV":70, "profile":"approximate night"})
            print("RENDER_DONE " + name, flush=True)
    visibility_after = window_visibility(scene, windows, cameras)
    assert visibility_after == visibility_before, "Material depth affected an actual window ray."
    assert helpers.geometry_digest(protected) == protected_digest
    assert helpers.geometry_digest(others) == others_digest
    assert helpers.geometry_digest(windows) == windows_digest
    assert tuple(light.matrix_world.translation) == tuple(Matrix([old_light_matrix[i:i+4] for i in range(0,16,4)]).translation)
    path = out / "MC_KEEP_SURFACE52_CANDIDATE.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    assert sha(SOURCE) == source_sha and sha(PLAN) == plan_sha
    result = {"sourceBlend":str(SOURCE.relative_to(ROOT)), "sourceBlendSHA256":source_sha,
              "sourcePlanSHA256":plan_sha, "sourcePreserved":True,
              "changedObject":light.name, "nativePartLocalScaleOverride":[1,1,1.04],
              "nativeCFrameChanged":False, "oldBlenderMatrix":old_light_matrix,
              "newBlenderMatrix":[v for row in light.matrix_world for v in row],
              "changedMeshDigestBefore":old_mesh_digest, "changedMeshDigestAfter":helpers.geometry_digest([light]),
              "protectedVisibleObjects":len(protected), "protectedGeometryDigest":protected_digest,
              "protectedMoved":False, "all638OtherWorldPartsDigest":others_digest,
              "allOtherWorldPartsMoved":False, "upperKeepWindowMaterialParts":len(windows),
              "upperKeepWindowDigest":windows_digest, "windowsMoved":False,
              "windowVisibilityBefore":visibility_before, "windowVisibilityAfter":visibility_after,
              "resourceDelta":{"units":0,"meshParts":0,"triangles":0}, "views":views,
              "blend":{"file":path.name,"sha256":sha(path),"bytes":path.stat().st_size},
              "studioTouched":False,"liveBlenderTouched":False,"newAssetOrUpload":False,
              "boundary":"Actual saved assembled geometry, unretouched Blender output with approximate night lighting. Identical window ray outcomes and exact preservation hashes do not establish native temporal rendering acceptance.",
              "scriptSHA256":sha(Path(__file__))}
    (out / "keep-surface-render-report.json").write_text(json.dumps(result, indent=2)+"\n")
    print("KEEP_SURFACE52_RENDER_DONE " + json.dumps({"views":len(views),"protectedMoved":False,"windowsMoved":False,"windowRaysUnchanged":True}), flush=True)


if __name__ == "__main__":
    main()
