"""R01/R06 and FrontWing R04; Blender 5.2, isolated entrance package only."""
import bpy
import bmesh
import hashlib
import json
import math
import time
from pathlib import Path
from mathutils import Vector

START = time.monotonic()
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = HERE / "R01_entrance"
OUT.mkdir(parents=True, exist_ok=True)
A01 = ROOT / "assets/grand_arcade/A01/GrandArcade_A01.blend"
C01 = ROOT / "assets/grand_arcade/connection_candidate/GrandArcadeConnection_C01.blend"
FLOOR_ORIGIN = (1552, 370, -892.5)
STAGE_PIVOT = (1552, 374.2, -942)
STAGE_OFFSET = Vector((0, 49.5, 4.2))
SEAM_SETBACK = .0001
POST_HALF = .71
POST_DEPTH = 27.2
POST_X = 9.45
SOURCE_BEAM_WIDTH = {"Ivory": 1.7, "Pale": 1.3, "Gold": 1.12}
COLORS = {
    "Ivory": (.94, .88, .75), "Pale": (.99, .96, .88),
    "Gold": (.88, .59, .14), "FloorA": (.85, .81, .70),
    "FloorB": (.83, .79, .68), "DeepBlue": (.045, .12, .17),
}
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = "NONE"
scene.unit_settings.scale_length = 1
exported = []
context_objects = []
checks = {}
replacements = []
materials = {}
for name, color in COLORS.items():
    material = bpy.data.materials.new("R01_" + name)
    material.diffuse_color = (*color, 1)
    materials[name] = material


def load_objects(path, names):
    wanted = list(names)
    with bpy.data.libraries.load(str(path), link=False) as (source, loaded):
        assert set(wanted) <= set(source.objects), (str(path), wanted)
        loaded.objects = list(wanted)
    result = dict(zip(wanted, loaded.objects))
    for name, obj in result.items():
        obj.name = "Input__" + name
    return result


def points(obj, shift=Vector()):
    return [obj.matrix_world @ vertex.co + shift for vertex in obj.data.vertices]


def components(obj):
    neighbors = [set() for _ in obj.data.vertices]
    for edge in obj.data.edges:
        a, b = edge.vertices
        neighbors[a].add(b)
        neighbors[b].add(a)
    pending = set(range(len(neighbors)))
    result = []
    while pending:
        root = min(pending)
        pending.remove(root)
        group, stack = {root}, [root]
        while stack:
            for index in neighbors[stack.pop()]:
                if index in pending:
                    pending.remove(index)
                    group.add(index)
                    stack.append(index)
        result.append(sorted(group))
    return result


def mesh_checks(obj):
    obj.data.calc_loop_triangles()
    vs = points(obj)
    faces = [list(face.vertices) for face in obj.data.polygons]
    edge_count = {}
    for face in faces:
        for a, b in zip(face, face[1:] + face[:1]):
            edge = tuple(sorted((a, b)))
            edge_count[edge] = edge_count.get(edge, 0) + 1
    closed = all(value == 2 for value in edge_count.values())
    finite = all(math.isfinite(component) for point in vs for component in point)
    degenerate = 0
    volumes = []
    for group in components(obj):
        group_set = set(group)
        origin = sum((vs[i] for i in group), Vector()) / len(group)
        volume = 0
        for triangle in obj.data.loop_triangles:
            if triangle.vertices[0] not in group_set:
                continue
            a, b, c = [vs[i] - origin for i in triangle.vertices]
            degenerate += int((b-a).cross(c-a).length < 1e-9)
            volume += a.dot(b.cross(c)) / 6
        volumes.append(volume)
    return {"vertices": len(vs), "triangles": len(obj.data.loop_triangles),
            "closed": closed, "finite": finite, "degenerateTriangles": degenerate,
            "componentSignedVolumes": volumes, "outward": all(v > 1e-8 for v in volumes)}


def make_mesh(name, material, vertices, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.materials.append(materials[material])
    data.update()
    assert not data.validate(), "Unexpected geometry repair: " + name
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    exported.append(obj)
    report = mesh_checks(obj)
    assert report["closed"] and report["finite"] and report["outward"], (name, report)
    assert report["degenerateTriangles"] == 0, (name, report)
    checks[name] = report
    return obj


stage_names = ["Platform__Floor"] + [f"FrontWing{side}__{mat}" for side in (-1, 1) for mat in SOURCE_BEAM_WIDTH]
stage_sources = load_objects(A01, stage_names)
connection_sources = load_objects(C01, ["UpperLanding__FloorA", "UpperLanding__FloorB"])
stage_floor = stage_sources["Platform__Floor"]
floor_points = points(stage_floor, STAGE_OFFSET)
floor_top = max(point.z for point in floor_points)
ellipse = [(point.x, point.y) for point in floor_points if abs(point.z-floor_top) < 1e-6]
assert len(ellipse) == 96
front_boundary = sorted((x, y) for x, y in ellipse if y <= 49.5 + 1e-6)


def boundary_depth(x):
    for (x0, y0), (x1, y1) in zip(front_boundary, front_boundary[1:]):
        if x0-1e-7 <= x <= x1+1e-7:
            return y0 + (y1-y0)*(x-x0)/(x1-x0)
    raise AssertionError("Floor boundary lookup outside stage width")


def trimmed_polygon(x0, x1, near, far):
    xs = [x0] + [x for x, _ in front_boundary if x0 < x < x1] + [x1]
    extra = []
    for a, b in zip(xs, xs[1:]):
        ha, hb = boundary_depth(a)-SEAM_SETBACK, boundary_depth(b)-SEAM_SETBACK
        if (ha-far)*(hb-far) < 0:
            extra.append(a+(b-a)*(far-ha)/(hb-ha))
    xs = sorted(xs + extra)
    top = [(x, min(far, boundary_depth(x)-SEAM_SETBACK)) for x in reversed(xs)]
    assert min(y for _, y in top) > near
    return [(x0, near), (x1, near)] + top


floor_report = []
for material in ("FloorA", "FloorB"):
    source = connection_sources["UpperLanding__" + material]
    source_points = points(source)
    vertices, faces = [], []
    changed, preserved = 0, 0
    for group in components(source):
        ps = [source_points[i] for i in group]
        x0, x1 = min(v.x for v in ps), max(v.x for v in ps)
        near, far = min(v.y for v in ps), max(v.y for v in ps)
        low, high = min(v.z for v in ps), max(v.z for v in ps)
        if far < min(boundary_depth(x0), boundary_depth(x1), boundary_depth(0) if x0 <= 0 <= x1 else math.inf):
            remap = {old: len(vertices)+i for i, old in enumerate(group)}
            vertices.extend(tuple(source_points[i]) for i in group)
            faces.extend(tuple(remap[i] for i in face.vertices) for face in source.data.polygons if face.vertices[0] in remap)
            preserved += 1
        else:
            polygon = trimmed_polygon(x0, x1, near, far)
            start, count = len(vertices), len(polygon)
            vertices.extend((x, y, h) for h in (low, high) for x, y in polygon)
            faces.append(tuple(start+i for i in range(count-1, -1, -1)))
            faces.append(tuple(start+count+i for i in range(count)))
            faces.extend((start+i, start+(i+1)%count, start+(i+1)%count+count, start+i+count) for i in range(count))
            changed += 1
    obj = make_mesh("UpperLanding__"+material, material, vertices, faces)
    floor_report.append({"mesh": obj.name, "preservedTileComponents": preserved,
                         "trimmedTileComponents": changed, "topHeightC01": max(v[2] for v in vertices)})
    replacements.append({"mesh": obj.name, "target": "Workspace.Lobby.GrandArcadeConnection.Architecture."+obj.name,
                         "scope": "Complete merged tile material only; other UpperLanding materials stay in place"})
assert sum(item["trimmedTileComponents"] for item in floor_report) == 4
assert sum(item["preservedTileComponents"] for item in floor_report) == 8


join_report = []
for side in (-1, 1):
    old_tip = math.radians(256 if side < 0 else 284)
    angle_delta = math.acos(POST_X/50)
    new_tip = math.pi+angle_delta if side < 0 else math.tau-angle_delta
    terminal_ry = 22.3/abs(math.sin(new_tip))
    for material, width in SOURCE_BEAM_WIDTH.items():
        name = f"FrontWing{side}__{material}"
        source = stage_sources[name]
        checks[name+"_source"] = mesh_checks(source)
        vertices = [tuple(point) for point in points(source, STAGE_OFFSET)]
        assert len(vertices) == 164
        old_indices = list(range(160, 164)) if side < 0 else list(range(4))
        faces = [tuple(face.vertices) for face in source.data.polygons if set(face.vertices) != set(old_indices)]
        original_z = [vertices[index][2] for index in old_indices]
        last = old_indices
        for step in range(1, 7):
            u = step/6
            smooth = u*u*(3-2*u)
            angle = old_tip+(new_tip-old_tip)*u
            ry = 22+(terminal_ry-22)*smooth
            end_width = width+(1.3-width)*smooth if material == "Ivory" else width
            new = []
            for index, offset in enumerate((-end_width/2, end_width/2, -end_width/2, end_width/2)):
                new.append(len(vertices))
                vertices.append(((50+offset)*math.cos(angle), (ry+offset)*math.sin(angle)+49.5, original_z[index]))
            faces.extend((last[a], last[b], new[b], new[a]) for a, b in ((0,1), (1,3), (3,2), (2,0)))
            last = new
        faces.append(tuple(last[i] for i in (0,1,3,2)))
        obj = make_mesh(name, material, vertices, faces)
        for index in last:
            x, y, z = vertices[index]
            assert abs(x-side*POST_X) < POST_HALF-.02, (name, "Tip exceeds post width", x)
            assert abs(y-POST_DEPTH) < POST_HALF-.02, (name, "Tip exceeds post depth", y)
            assert 4.2-1e-6 <= z <= 7.4, (name, "Tip exceeds post height", z)
        assert vertices[:164] == [tuple(point) for point in points(source, STAGE_OFFSET)]
        replacements.append({"mesh": name, "target": "Workspace.GrandArcade."+name,
                             "scope": "Complete affected material beam; 41 original rings preserved, only closed terminal extension added"})
    join_report.append({"side": side, "oldStageCenter": [side*50*abs(math.cos(old_tip)), -22*abs(math.sin(old_tip))],
                       "newStageCenter": [side*POST_X, -22.3], "newC01Center": [side*POST_X, POST_DEPTH],
                       "terminalPostWorldBodyCenter": [1552+side*POST_X, 375.8, -919.7],
                       "existingPostSize": [1.42, 3.2, 1.42], "beamTipContainedInExistingPost": True,
                       "bridgeCapStageHeights": {"Pale": [2.8,3.03], "Gold": [3.03,3.10]},
                       "curvedCapStageHeights": {"Pale": [2.53,2.87], "Gold": [2.85,2.95]},
                       "terminalPostHeadStageHeights": {"Pale": [3.13,3.33], "Gold": [3.32,3.40]}})


for key, p in {"Origin": (0,0,0), "Right": (10,0,0), "Up": (0,0,10), "Forward": (0,-10,0)}.items():
    vertices = [(p[0]+x*.06, p[1]+y*.06, p[2]+z*.06) for x,y,z in
                [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    marker = make_mesh("Marker"+key+"__DeepBlue", "DeepBlue", vertices,
                       [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    marker.hide_render = True


def polygon_area(polygon):
    return abs(sum(x0*y1-y0*x1 for (x0,y0),(x1,y1) in zip(polygon, polygon[1:]+polygon[:1])))/2 if len(polygon) > 2 else 0


def clip_inside(polygon, boundary):
    result = list(polygon)
    for (ax,ay), (bx,by) in zip(boundary, boundary[1:]+boundary[:1]):
        if not result:
            break
        output = []
        previous = result[-1]
        dp = (bx-ax)*(previous[1]-ay)-(by-ay)*(previous[0]-ax)
        for current in result:
            dc = (bx-ax)*(current[1]-ay)-(by-ay)*(current[0]-ax)
            if (dc >= 0) != (dp >= 0):
                fraction = dp/(dp-dc)
                output.append((previous[0]+fraction*(current[0]-previous[0]), previous[1]+fraction*(current[1]-previous[1])))
            if dc >= 0:
                output.append(current)
            previous, dp = current, dc
        result = output
    return result


def floor_overlap(objects):
    overlap = 0
    for obj in objects:
        if obj.name.split(".")[0] not in ("UpperLanding__FloorA", "UpperLanding__FloorB"):
            continue
        vs = points(obj)
        high = max(point.z for point in vs)
        obj.data.calc_loop_triangles()
        for triangle in obj.data.loop_triangles:
            ps = [vs[i] for i in triangle.vertices]
            if all(abs(v.z-high) < 1e-5 for v in ps):
                overlap += polygon_area(clip_inside([(v.x,v.y) for v in ps], ellipse))
    return overlap


overlap = floor_overlap(exported)
assert overlap < 1e-8, overlap
bpy.ops.object.select_all(action="DESELECT")
for obj in exported:
    obj.select_set(True)
bpy.context.view_layer.objects.active = exported[0]
fbx = OUT / "GrandArcade_R01_Entrance.fbx"
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={"MESH"},
                         axis_forward="-Z", axis_up="Y", apply_unit_scale=True, add_leaf_bones=False)
before_import = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=str(fbx), use_custom_normals=False)
imported = [obj for obj in bpy.data.objects if obj not in before_import and obj.type == "MESH"]
assert len(imported) == len(exported) == 12
roundtrip = {}
for obj in imported:
    name = obj.name.split(".")[0]
    report = mesh_checks(obj)
    assert report["closed"] and report["finite"] and report["outward"] and report["degenerateTriangles"] == 0, (name, report)
    reference = next(item for item in exported if item.name == name)
    a, b = points(reference), points(obj)
    assert len(a) == len(b), "FBX vertex count changed: " + name
    distance = max(max(min((p-q).length for q in b) for p in a),
                   max(min((p-q).length for q in a) for p in b))
    assert distance < .00003, ("FBX position changed", name, distance)
    report["maximumRoundtripPositionDifferenceStuds"] = distance
    roundtrip[name] = report
export_overlap = floor_overlap(imported)
assert export_overlap < 1e-8, export_overlap
for obj in imported:
    bpy.data.objects.remove(obj, do_unlink=True)


def add_context(path, names, shift=Vector()):
    loaded = load_objects(path, names)
    for name, source in loaded.items():
        obj = bpy.data.objects.new("Context__"+name, source.data.copy())
        obj.matrix_world = source.matrix_world
        obj.location += shift
        scene.collection.objects.link(obj)
        context_objects.append(obj)


add_context(A01, ["Platform__Floor", "Platform__Pale", "Platform__Ivory", "Platform__Gold", "Platform__Stone",
                  "FrontWing-1__Navy", "FrontWing1__Navy"], STAGE_OFFSET)
add_context(C01, [f"{section}__{mat}" for section in ("LowerLanding", "Ramp", "UpperLanding")
                  for mat in ("Cream", "Pale", "Gold", "Stone", "DeepBlue")]
                  + ["PortalPosts__Cream", "PortalPosts__Pale", "PortalPosts__Gold",
                     "Ramp__FloorA", "Ramp__FloorB", "LowerLanding__FloorA", "LowerLanding__FloorB"])
scene.world = bpy.data.worlds.new("EntranceReviewWorld")
scene.world.color = (.48,.60,.68)
cam_data = bpy.data.cameras.new("EntranceReviewCamera")
cam = bpy.data.objects.new("EntranceReviewCamera", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.cavity_type = "BOTH"
scene.display.shading.background_type = "WORLD"
scene.view_settings.view_transform = "Standard"
scene.render.resolution_x = 1200
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
views = {
    "entrance-player": ((0,12,9.4),(0,29,5.3),False,35),
    "entrance-reverse": ((0,35,9.4),(0,22,5.5),False,35),
    "left-joint": ((-18,19,10),(-10,27.7,6),False,28),
    "right-joint": ((18,19,10),(10,27.7,6),False,28),
    "floor-seam": ((0,23,24),(0,25.4,4.2),True,22),
}
for name, (position, target, ortho, size) in views.items():
    cam.location = position
    cam.rotation_euler = (Vector(target)-cam.location).to_track_quat("-Z","Y").to_euler()
    cam_data.type = "ORTHO" if ortho else "PERSP"
    cam_data.ortho_scale = size
    cam_data.lens = size
    scene.render.filepath = str(OUT / (name+".png"))
    bpy.ops.render.render(write_still=True)
blend = OUT / "GrandArcade_R01_Entrance.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
report = {
    "revision": "R01_entrance", "issues": ["R01", "R06", "R04 FrontWing solids"],
    "axes": "All export geometry uses C01 axes: X right, Y stageward, Z up; native (x,z,-y).",
    "floorOrigin": FLOOR_ORIGIN, "expectedStagePivot": STAGE_PIVOT,
    "sourceFiles": [{"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in (A01,C01)],
    "colors": COLORS, "replacementMapping": replacements, "meshChecks": checks,
    "exportRoundtripChecks": roundtrip, "meshCountIncludingFourMarkers": len(exported),
    "triangles": sum(checks[obj.name]["triangles"] for obj in exported),
    "floors": floor_report, "stageFrontBoundaryC01": front_boundary,
    "seamSetbackStuds": SEAM_SETBACK, "sourceFloorTriangleStageOverlapArea": overlap,
    "roundtripFloorTriangleStageOverlapArea": export_overlap, "joins": join_report,
    "preserved": {"originalCurveRingsPerBeam": 41, "curvedNavyBalusterMeshes": "untouched",
                  "C01OtherMaterials": "untouched, including merged UpperLanding Cream floor/guards and all PortalPosts",
                  "collisionChanges": 0, "floorWidthStuds": 18, "parapetClearWidthStuds": 17.8,
                  "rampRunStuds": 16, "rampRiseStuds": 4.2, "upperLandingTopWorldY": 374.2},
    "nativeRemaining": ["Verify import single-sided solids from both sides", "Inspect seam from shallow player views",
                        "Inspect both post joints and existing guard-collider agreement; candidate does not alter native collision",
                        "Walk repaired join both ways at center and both usable edges with jumping disabled"],
    "nativeProof": "Not installed, uploaded or playtested by this worker. Blender checks are geometry evidence only.",
    "elapsedSeconds": round(time.monotonic()-START,2),
    "outputs": [{"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size} for path in (fbx,blend)],
}
(OUT / "entrance-manifest.json").write_text(json.dumps(report, indent=2))
print("ENTRANCE_REPAIR " + json.dumps({"meshes": len(exported), "triangles": report["triangles"],
                                        "overlapArea": overlap, "elapsedSeconds": report["elapsedSeconds"]}))
