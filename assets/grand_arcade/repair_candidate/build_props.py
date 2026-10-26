"""Repair lamp-roof normals without changing current mesh dimensions or placements."""
import bpy
import bmesh
import hashlib
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent / 'R01_props'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
scene.unit_settings.system = 'NONE'
scene.unit_settings.scale_length = 1
source = ROOT / 'A01' / 'GrandArcade_A01.blend'
names = [f'Lamp{i}__Gold' for i in range(1, 7)]
with bpy.data.libraries.load(str(source), link=False) as (available, requested):
    assert all(name in available.objects for name in names)
    requested.objects = names
exported = []
records = {}
for obj in requested.objects:
    scene.collection.objects.link(obj)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    assert not any(not edge.is_manifold for edge in bm.edges), obj.name
    assert not any(face.calc_area() < 1e-10 for face in bm.faces), obj.name
    unseen = set(bm.verts)
    volumes = []
    while unseen:
        seed = unseen.pop()
        vertices = {seed}
        frontier = [seed]
        while frontier:
            vertex = frontier.pop()
            for edge in vertex.link_edges:
                neighbor = edge.other_vert(vertex)
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    vertices.add(neighbor)
                    frontier.append(neighbor)
        faces = {face for vertex in vertices for face in vertex.link_faces}
        volume = 0.0
        for face in faces:
            points = [loop.vert.co for loop in face.loops]
            for index in range(1, len(points) - 1):
                volume += points[0].dot(points[index].cross(points[index + 1])) / 6
        assert volume > 0, (obj.name, volume)
        volumes.append(volume)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.calc_loop_triangles()
    records[obj.name] = {'triangles': len(obj.data.loop_triangles), 'closedComponents': len(volumes), 'positiveVolumes': volumes,
                         'bounds': [[min(v.co[a] for v in obj.data.vertices) for a in range(3)], [max(v.co[a] for v in obj.data.vertices) for a in range(3)]]}
    exported.append(obj)
material = bpy.data.materials.new('CalibrationNavy')
material.diffuse_color = (.025, .055, .12, 1)
for name, p in [('Origin', (0, 0, 0)), ('Right', (10, 0, 0)), ('Up', (0, 0, 10)), ('Forward', (0, -10, 0))]:
    bpy.ops.mesh.primitive_cube_add(size=.12, location=p)
    obj = bpy.context.object
    obj.name = 'R01Marker' + name + '__Navy'
    obj.data.materials.append(material)
    obj.hide_render = True
    exported.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in exported:
    obj.select_set(True)
bpy.context.view_layer.objects.active = exported[0]
fbx = OUT / 'GrandArcade_R01_Props.fbx'
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True, add_leaf_bones=False)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'GrandArcade_R01_Props.blend'))
report = {'revision': 'R01-props', 'source': str(source), 'meshes': records, 'calibrationPrefix': 'R01Marker',
          'fbxSha256': hashlib.sha256(fbx.read_bytes()).hexdigest(),
          'planterRelocation': {'sourceCenters': [[-46, -7, 0], [46, -7, 0]], 'targetCenters': [[-40, -7, 0], [40, -7, 0]]},
          'outerLampRelocation': {'sourceCenters': [[-46, -7, 1.5], [46, -7, 1.5]], 'targetCenters': [[-45, 0, 0], [45, 0, 0]]},
          'preservation': 'Only normals change in exported Gold meshes; install uses current placement deltas for retained bridge lamps.'}
(OUT / 'props-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
