"""Verified R01 bay construction for bays 1, 2, 4 and 5; Blender 5.2."""
import bmesh
import bpy
import hashlib
import json
import math
import struct
import time
from pathlib import Path
from mathutils import Vector

START = time.monotonic()
ROOT = Path(__file__).resolve().parent
BASE = ROOT.parent / "A01"
TRIM = ROOT.parent / "quality_candidate" / "Q01"
OUT = ROOT / "R01_bays_remaining"
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = json.loads((BASE / "manifest.json").read_text())
INDICES = [1, 2, 4, 5]
OFFSET = Vector((0,0,0))
ANGLE = 0
SPRING, INNER, OUTER = 17.5, 7.6, 9.0
PANEL_WIDTH = 12.4
PANEL_HEIGHT = PANEL_WIDTH * 13.2 / 13.5
PANEL_Z = 14.0
FRAME_WIDTH, FRAME_HEIGHT = PANEL_WIDTH + .7, PANEL_HEIGHT + .7
PLAQUE_Z = 6.6
KEY_HALF_ANGLE = math.radians(6)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = "NONE"
scene.unit_settings.scale_length = 1
materials = {}
for name, color in SOURCE["colors"].items():
    material = bpy.data.materials.new("R01_" + name)
    material.diffuse_color = (*color, 1)
    materials[name] = material


def connected_components(data):
    neighbors = [set() for _ in data.vertices]
    for edge in data.edges:
        a, b = edge.vertices
        neighbors[a].add(b)
        neighbors[b].add(a)
    unvisited = set(range(len(data.vertices)))
    components = []
    while unvisited:
        pending = [min(unvisited)]
        found = set()
        while pending:
            vertex = pending.pop()
            if vertex in found:
                continue
            found.add(vertex)
            pending.extend(neighbors[vertex] - found)
        unvisited.difference_update(found)
        ids = sorted(found)
        faces = [list(face.vertices) for face in data.polygons if face.vertices[0] in found]
        components.append((ids, faces))
    return components


def signature(vertices, faces):
    digest = hashlib.sha256()
    for vertex in vertices:
        digest.update(struct.pack("<3f", *vertex))
    for face in faces:
        digest.update(struct.pack("<I", len(face)))
        digest.update(struct.pack("<" + "I" * len(face), *face))
    return digest.hexdigest()


def subset(data, ids, faces):
    remap = {old: new for new, old in enumerate(ids)}
    vertices = [tuple(data.vertices[i].co) for i in ids]
    return vertices, [[remap[i] for i in face] for face in faces]


def mapped(v):
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    return (OFFSET.x + v[0]*c - v[1]*s, OFFSET.y + v[0]*s + v[1]*c, v[2])


def create(name, material, vertices, faces, repair_normals=True, local=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata([mapped(v) if local else v for v in vertices], [], faces)
    data.materials.append(materials[material])
    data.update()
    assert not data.validate(), "Invalid geometry: " + name
    if repair_normals:
        bm = bmesh.new()
        bm.from_mesh(data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(data)
        bm.free()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj["Material"] = material
    return obj


def box(name, mat, center, size):
    x, y, z = center
    a, b, c = [v / 2 for v in size]
    vertices = [(x + dx*a, y + dy*b, z + dz*c) for dx, dy, dz in [
        (-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
        (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    faces = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    return create(name, mat, vertices, faces)


def extrusion(name, mat, polygon, front, depth):
    count = len(polygon)
    vertices = [(x, y, z) for y in [front, front + depth] for x, z in polygon]
    faces = [tuple(range(count)), tuple(range(2*count - 1, count - 1, -1))]
    faces += [(i, i + count, (i + 1) % count + count, (i + 1) % count) for i in range(count)]
    return create(name, mat, vertices, faces)


def arc(name, mat, inner, outer, start, end, front, depth):
    segments = max(4, math.ceil((end - start) / math.radians(4)))
    angles = [start + (end - start) * i / segments for i in range(segments + 1)]
    vertices = [(r*math.cos(a), y, SPRING + r*math.sin(a))
                for y in [front, front + depth] for r in [inner, outer] for a in angles]
    ring = segments + 1
    faces = []
    for i in range(segments):
        faces += [(i,i+1,ring+i+1,ring+i),
                  (2*ring+i,3*ring+i,3*ring+i+1,2*ring+i+1),
                  (i,2*ring+i,2*ring+i+1,i+1),
                  (ring+i,ring+i+1,3*ring+i+1,3*ring+i)]
    faces += [(0,ring,3*ring,2*ring),
              (segments,2*ring+segments,3*ring+segments,ring+segments)]
    return create(name, mat, vertices, faces)


def rectangle_ring(name, mat, outer_width, outer_height, inner_width, inner_height, z, front, depth):
    vertices = []
    for y in [front, front + depth]:
        for width, height in [(inner_width, inner_height), (outer_width, outer_height)]:
            vertices += [(x*width/2, y, z + zz*height/2) for x, zz in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    faces = []
    for i in range(4):
        j = (i + 1) % 4
        faces += [(i,j,4+j,4+i),(8+i,12+i,12+j,8+j),
                  (i,8+i,8+j,j),(4+i,4+j,12+j,12+i)]
    return create(name, mat, vertices, faces)


def validate(obj):
    data = obj.data
    assert all(math.isfinite(value) for vertex in data.vertices for value in vertex.co)
    data.calc_loop_triangles()
    assert all(triangle.area > 1e-9 for triangle in data.loop_triangles), obj.name
    component_reports = []
    for ids, faces in connected_components(data):
        vertices, mapped_faces = subset(data, ids, faces)
        temporary = bpy.data.meshes.new("Validation")
        temporary.from_pydata(vertices, [], mapped_faces)
        bm = bmesh.new()
        bm.from_mesh(temporary)
        boundary = sum(edge.is_boundary for edge in bm.edges)
        nonmanifold = sum(not edge.is_manifold for edge in bm.edges)
        volume = bm.calc_volume(signed=True)
        assert boundary == 0 and nonmanifold == 0 and volume > 1e-8, (obj.name, boundary, nonmanifold, volume)
        component_reports.append({"vertices": len(vertices), "faces": len(faces),
                                  "boundaryEdges": boundary, "nonManifoldEdges": nonmanifold,
                                  "signedVolume": volume})
        bm.free()
        bpy.data.meshes.remove(temporary)
    return component_reports


exported = []
mesh_info = {}
preservation = []
display_changes = []
for index in INDICES:
    bay = SOURCE["bays"][index-1]
    OFFSET = Vector(bay["p"])
    ANGLE = bay["angle"]
    base_prefix = "Bay" + str(index)
    trim_prefix = base_prefix + "Trim"
    loaded = {}
    for blend, names in [
        (BASE / "GrandArcade_A01.blend", [name for name in SOURCE["meshes"] if name.startswith(base_prefix + "__")]),
        (TRIM / "GrandArcade_Q01_Trim.blend", [trim_prefix + "__" + mat for mat in ["Pale", "Ivory", "Gold", "Navy", "Silver", "Bronze"]]),
    ]:
        with bpy.data.libraries.load(str(blend), link=False) as (available, requested):
            assert all(name in available.objects for name in names)
            requested.objects = names
        for obj in requested.objects:
            scene.collection.objects.link(obj)
            loaded[obj.name] = obj

    replacement_names = [base_prefix + "__" + mat for mat in ["Navy","Ivory","Gold","Pale"]]
    replacement_names += [trim_prefix + "__" + mat for mat in ["Pale","Gold"]]
    kept_by_group = {}
    bay_preservation = []
    for name in replacement_names:
        original = loaded[name]
        assert all(abs(original.matrix_world[row][col] - (1 if row == col else 0)) < 1e-6
                   for row in range(4) for col in range(4)), name
        material = name.split("__")[-1]
        kept = []
        record = {"mesh": name, "sourceComponents": [], "preservedComponents": [], "removedComponents": []}
        for ordinal, (ids, faces) in enumerate(connected_components(original.data)):
            vertices, mapped_faces = subset(original.data, ids, faces)
            low = [min(v[axis] for v in vertices) for axis in range(3)]
            high = [max(v[axis] for v in vertices) for axis in range(3)]
            if name == base_prefix + "__Ivory":
                remove = low[2] > 17.4
            elif name == base_prefix + "__Pale":
                remove = low[2] > 23
            elif name == trim_prefix + "__Pale":
                remove = high[2] > 18 or (high[0] - low[0] > 10 and low[2] > 5)
            else:
                remove = high[2] > 5
            detail = {"ordinal": ordinal, "bounds": [low, high], "vertices": len(vertices),
                      "faces": len(mapped_faces), "sha256": signature(vertices, mapped_faces)}
            record["sourceComponents"].append(detail)
            record["removedComponents" if remove else "preservedComponents"].append(detail)
            if not remove:
                obj = create("Preserved_" + name + "_" + str(ordinal), material, vertices,
                             mapped_faces, repair_normals=False, local=False)
                assert signature([tuple(v.co) for v in obj.data.vertices],
                                 [list(face.vertices) for face in obj.data.polygons]) == detail["sha256"]
                kept.append(obj)
        kept_by_group[name] = kept
        bay_preservation.append(record)
        original.hide_render = True
        original.hide_viewport = True

    new = {name: [] for name in replacement_names}
    ends = [(0, math.pi/2 - KEY_HALF_ANGLE), (math.pi/2 + KEY_HALF_ANGLE, math.pi)]
    for side, (start, end) in enumerate(ends):
        new[base_prefix + "__Ivory"].append(arc("IvoryArch_" + str(side), "Ivory", INNER, OUTER, start, end, -.50, 1.70))
        new[base_prefix + "__Gold"].append(arc("GoldReveal_" + str(side), "Gold", INNER, 7.78, start, end, -.70, .20))
        new[trim_prefix + "__Pale"].append(arc("OuterMolding_" + str(side), "Pale", 8.86, 9.12, start, end, -.69, .19))
    new[base_prefix + "__Pale"].append(arc("SeatedKeystone", "Pale", INNER, 9.12,
                                      math.pi/2 - KEY_HALF_ANGLE, math.pi/2 + KEY_HALF_ANGLE, -.72, 1.92))
    polygon = [(-INNER,0),(INNER,0),(INNER,SPRING)]
    polygon += [(INNER*math.cos(j*math.pi/48), SPRING + INNER*math.sin(j*math.pi/48)) for j in range(1,49)]
    new[base_prefix + "__Navy"].append(extrusion("RecessedOpaqueBacking", "Navy", polygon, .90, .40))
    new[base_prefix + "__Navy"].append(box("PanelBacking", "Navy", (0,-.64,PANEL_Z), (PANEL_WIDTH+.10,.24,PANEL_HEIGHT+.10)))
    new[base_prefix + "__Navy"].append(box("RacePlaque", "Navy", (0,-.70,PLAQUE_Z), (PANEL_WIDTH+.12,.32,1.65)))
    new[trim_prefix + "__Pale"].append(rectangle_ring("OnePanelCasing", "Pale", FRAME_WIDTH, FRAME_HEIGHT,
                                             PANEL_WIDTH, PANEL_HEIGHT, PANEL_Z, -1.08, .30))
    new[trim_prefix + "__Gold"].append(rectangle_ring("PanelGoldFace", "Gold", PANEL_WIDTH+.18, PANEL_HEIGHT+.18,
                                             PANEL_WIDTH, PANEL_HEIGHT, PANEL_Z, -1.11, .03))
    new[trim_prefix + "__Gold"].append(rectangle_ring("PlaqueGoldFace", "Gold", PANEL_WIDTH+.36, 1.77,
                                             PANEL_WIDTH, 1.55, PLAQUE_Z, -.99, .13))
    preservation.extend(bay_preservation)
    for name in replacement_names:
        members = kept_by_group[name] + new[name]
        bpy.ops.object.select_all(action="DESELECT")
        for obj in members:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = members[0]
        bpy.ops.object.join()
        obj = bpy.context.object
        obj.name = "R01_" + name
        obj.data.calc_loop_triangles()
        checks = validate(obj)
        merged_signatures = []
        for ids, faces in connected_components(obj.data):
            vertices, mapped_faces = subset(obj.data, ids, faces)
            merged_signatures.append(signature(vertices, mapped_faces))
        preserved_record = next(row for row in preservation if row["mesh"] == name)
        assert all(row["sha256"] in merged_signatures for row in preserved_record["preservedComponents"]), name
        preserved_record["verifiedAfterMerge"] = True
        mesh_info[obj.name] = {"replaces": "Workspace.GrandArcade." + ("QualityTrimQ01." if "Trim__" in name else "") + name,
            "material": name.split("__")[-1], "triangles": len(obj.data.loop_triangles), "components": checks,
            "bounds": [[min(v.co[axis] for v in obj.data.vertices) for axis in range(3)],
                       [max(v.co[axis] for v in obj.data.vertices) for axis in range(3)]]}
        exported.append(obj)
    display_changes.extend([
        {"path":"Workspace.GrandArcade.Displays."+base_prefix+".MapPanel", "sourceP":mapped((0,-.82,PANEL_Z)),
         "sourceAngle":ANGLE,"nativeSize":[PANEL_WIDTH,PANEL_HEIGHT,.035],"sourceSize":[PANEL_WIDTH,.035,PANEL_HEIGHT],
         "unchangedCanvasSize":[600,590],"aspectRatio":"13.5:13.2","uniformArtworkScale":PANEL_WIDTH/13.5},
        {"path":"Workspace.GrandArcade.Displays."+base_prefix+".Plaque","sourceP":mapped((0,-.88,PLAQUE_Z)),
         "sourceAngle":ANGLE,"nativeSize":[PANEL_WIDTH,1.55,.035],"sourceSize":[PANEL_WIDTH,.035,1.55],
         "unchangedCanvasSize":[650,90]}])
OFFSET, ANGLE = Vector((0,0,0)), 0

calibration = {}
for key, p in [("Origin", (0,0,0)),("Right",(10,0,0)),("Up",(0,0,10)),("Forward",(0,-10,0))]:
    obj = box("R01Marker" + key + "__Navy", "Navy", p, (.12,.12,.12))
    obj.hide_render = True
    obj.hide_viewport = True
    calibration[key.lower()] = obj.name
    mesh_info[obj.name] = {"material": "Navy", "section": "Calibration", "triangles": 12}
    exported.append(obj)

corner_z = PANEL_Z + FRAME_HEIGHT/2
radial_clearance = INNER - math.hypot(FRAME_WIDTH/2, max(0,corner_z - SPRING))
minimum_polygon_clearance = INNER * math.cos(math.radians(4)/2) - math.hypot(FRAME_WIDTH/2, corner_z - SPRING)
assert minimum_polygon_clearance > .40
report = {"revision": "R01_bays_remaining", "state": "Blender_candidate_only",
    "base": "A01 + Q01", "bayIndices": INDICES, "colors": SOURCE["colors"], "units": SOURCE["units"],
    "durableSourceChanges": ["assets/grand_arcade/build_stage.py bay definitions",
        "assets/grand_arcade/quality_candidate/build_trim.py bay trim definitions",
        "src/ServerStorage/CourseBuilders/GrandArcade/Builder.luau display size and height defaults"],
    "futureManifestMigration": {"preserveOriginalOutputs": True,
        "bayPositions": "In A01/manifest.json and native Manifest.luau, set each bay.screen[3] to 14 and bay.plaque[3] to 6.6. Retain horizontal coordinates, angle and every slot record.",
        "meshRecords": "Update only changed bay mesh records from reviewed exports after a controlled future rebuild. Existing A01/Q01 asset outputs were retained during this repair.",
        "trimApertureStuds": [PANEL_WIDTH,PANEL_HEIGHT],
        "builderDefaults": "Native Builder already uses reviewed dimensions and heights with the original GUI canvases. Do not rerun the original whole-stage installers over the repaired live stage."},
    "sourceHashes": {str(path.relative_to(ROOT.parent)): hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in [BASE/"GrandArcade_A01.blend",TRIM/"GrandArcade_Q01_Trim.blend"]},
    "meshes": mesh_info, "meshCount": len(exported), "calibration": calibration, "preservation": preservation,
    "dimensions": {"springHeight": SPRING, "innerRadius": INNER, "outerRadius": OUTER,
                   "ringDepth": 1.7, "keystoneSectorDegrees": 12, "keystoneRadialRange": [INNER,9.12],
                   "casingOuterSize": [FRAME_WIDTH,.30,FRAME_HEIGHT], "upperCornerRadialClearance": radial_clearance,
                   "upperCornerPolygonClearanceLowerBound": minimum_polygon_clearance,
                   "plaqueCasingGap": PANEL_Z-FRAME_HEIGHT/2-(PLAQUE_Z+1.77/2)},
    "displayChanges": display_changes,
    "preserveNative": ["MapPanel.Display.Artwork", "MapPanel.Display.Fallback", "Plaque.Display.Title",
                       "Slot1", "Slot2", "Slot3", "Rank1", "Rank2", "Rank3", "HostSpot", "collision"],
    "colliderChanges": 0, "slotChanges": 0,
    "previewLimit": "Only the four remaining bays are exported. The already installed center bay is excluded. Blender checks do not verify Roblox imported appearance or native UI readability."}
(OUT/"bay-manifest.json").write_text(json.dumps(report, indent=2))
bpy.ops.object.select_all(action="DESELECT")
for obj in exported:
    obj.hide_viewport = False
    obj.select_set(True)
bpy.context.view_layer.objects.active = exported[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/"GrandArcade_R01_BaysRemaining.fbx"), use_selection=True,
    object_types={"MESH"},axis_forward="-Z",axis_up="Y",apply_unit_scale=True,add_leaf_bones=False)
before_import = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=str(OUT/"GrandArcade_R01_BaysRemaining.fbx"), use_image_search=False)
round_trip_objects = [obj for obj in bpy.data.objects if obj not in before_import]
round_trip = {obj.name: validate(obj) for obj in round_trip_objects if obj.type == "MESH"}
assert len(round_trip) == len(exported), [(obj.name,obj.type) for obj in round_trip_objects]
for obj in round_trip_objects:
    bpy.data.objects.remove(obj, do_unlink=True)
(OUT/"fbx-validation.json").write_text(json.dumps({"state":"passed", "meshes":len(round_trip),
    "checks":"Finite vertices, nondegenerate triangles, closed manifold components and positive signed volumes after FBX reimport.",
    "components":round_trip, "limitation":"Blender FBX round trip only; actual Roblox import still requires native views."},indent=2))

bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"GrandArcade_R01_BaysRemaining.blend"))
build_report = {"state":"remaining_bays_ready_for_native_import", "bayIndices":INDICES,
    "meshes":len(exported),"triangles":sum(row["triangles"] for row in mesh_info.values()),
    "closedOutwardComponents":sum(len(row.get("components",[])) for row in mesh_info.values()),
    "preservedComponents":sum(len(row["preservedComponents"]) for row in preservation),
    "elapsedSeconds":round(time.monotonic()-START,2),
    "files":{path.name:{"bytes":path.stat().st_size,"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
             for path in OUT.iterdir() if path.suffix in [".blend",".fbx",".json"] and path.name!="build-report.json"}}
(OUT/"build-report.json").write_text(json.dumps(build_report,indent=2))
print("R01_BAYS_REMAINING "+json.dumps(build_report))
