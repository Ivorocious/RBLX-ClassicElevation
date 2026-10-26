"""Taper only the nine exposed knot cylinders, retaining F03's full scene."""
import hashlib
import json
import math
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/artifacts/stud-garden-v2'
OUT = BASE / 'phase3/f04'
OUT.mkdir(exist_ok=True)
(OUT / 'source').mkdir(exist_ok=True)
(OUT / 'views').mkdir(exist_ok=True)
source_path = BASE / 'phase2/round3/offline-r305/geometry.json'
data = json.loads(source_path.read_text())
bpy.ops.wm.open_mainfile(filepath=str(BASE / 'phase3/f03/SGV2_Phase3_F03.blend'))
scene = bpy.context.scene
records = []
objects = []
origin = np.array((9200, 80, 3500))
parts = [p for p in data['parts'] if 'RootKnot' in p['path'] and p['name'] in ('CrossRoot', 'RootFork')]
assert len(parts) == 9
for index, part in enumerate(parts):
    cf = np.array(part['cf'])
    position, rotation = cf[:3] - origin, cf[3:].reshape(3, 3)
    length, diameter, _ = part['size']
    radius = diameter / 2
    sides = 16
    local = [(-length/2, 0, 0)]
    local += [(x, radius*math.cos(i*math.tau/sides), radius*math.sin(i*math.tau/sides))
              for x in (-length*.28, length*.28) for i in range(sides)]
    local += [(length/2, 0, 0)]
    points = np.array([position + rotation @ np.array(v) for v in local])
    faces = []
    for i in range(sides):
        j = (i+1) % sides
        faces.extend([(0, 1+j, 1+i), (1+i, 1+j, 1+sides+j),
                      (1+i, 1+sides+j, 1+sides+i), (33, 1+sides+i, 1+sides+j)])
    name = f'F04__Knot_{index+1:02d}'
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([(x, -z, y) for x, y, z in points], [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    assert not any(e.is_boundary or not e.is_manifold for e in bm.edges)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    color = part['color']
    material = bpy.data.materials.new(name + '_Color')
    material.use_nodes = True
    shader = material.node_tree.nodes['Principled BSDF']
    shader.inputs['Base Color'].default_value = tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in color)+(1,)
    shader.inputs['Roughness'].default_value = .48
    obj.data.materials.append(material)
    objects.append(obj)
    hidden = []
    for old in scene.objects:
        if old.name.startswith(part['path']) and (np.array((old.location.x, old.location.z, -old.location.y))-position).dot(np.array((old.location.x, old.location.z, -old.location.y))-position) < .01:
            old.hide_render = True
            old.hide_viewport = True
            hidden.append(old.name)
    # Reference meshes can have baked world vertices and identity transforms.
    if not hidden:
        for old in scene.objects:
            if old.name.startswith(part['path']) and old.type == 'MESH':
                coords = np.array([tuple(old.matrix_world @ v.co) for v in old.data.vertices])
                center = (coords.min(axis=0)+coords.max(axis=0))/2
                if np.linalg.norm(np.array((center[0], center[2], -center[1]))-position) < .05:
                    old.hide_render = True
                    old.hide_viewport = True
                    hidden.append(old.name)
    assert len(hidden) == 1, (part['path'], hidden)
    convex_error = 0
    for polygon in mesh.polygons:
        normal = np.array(tuple(polygon.normal))
        vertex = np.array(tuple(mesh.vertices[polygon.vertices[0]].co))
        convex_error = max(convex_error, max(float((np.array(tuple(v.co))-vertex).dot(normal)) for v in mesh.vertices))
    assert convex_error < .0001
    assert max(abs(v[0]) for v in local) <= length/2+.00001
    assert max(math.hypot(v[1],v[2]) for v in local) <= radius+.00001
    records.append(dict(name=name, sourcePath=part['path'], sourceCf=part['cf'], sourceSize=part['size'],
        color=color, hex='#'+''.join(f'{round(c*255):02x}' for c in color), triangles=len(mesh.polygons),
        exportBoundsRoblox=[points.min(axis=0).tolist(), points.max(axis=0).tolist()],
        localVertices=local, faces=[list(p.vertices) for p in mesh.polygons],
        convexPlaneError=convex_error, hiddenOffline=hidden, preservedCentralFraction=.56,
        originalTop=float(position[1]+radius), replacementTop=float(points[:,1].max())))

bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    obj.select_set(True)
for name in ('CalO', 'CalX', 'CalY', 'CalZ'):
    bpy.data.objects[name].select_set(True)
bpy.context.view_layer.objects.active = objects[0]
fbx = OUT / 'SGV2_Phase3_F04_Knots.fbx'
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={'MESH'},
    apply_unit_scale=True, axis_forward='-Z', axis_up='Y', path_mode='COPY', embed_textures=False, bake_anim=False)
manifest = dict(candidate='SGV2_Phase3_F04', parent='SGV2_Phase3_F03', parentFingerprint='470ecc4d',
    sourceGeometrySha256=hashlib.sha256(source_path.read_bytes()).hexdigest(),
    fbxSha256=hashlib.sha256(fbx.read_bytes()).hexdigest(), fbxBytes=fbx.stat().st_size,
    meshes=records, meshCount=9, addedTriangles=sum(r['triangles'] for r in records),
    target=[11800,80,3500], limits=['Nine convex knot meshes replace nine cylinder contacts only.',
    'The three GrowthKnot balls and bark stripes remain exact, preserving maximum crest height.',
    'Convexity and cylinder containment are geometric checks, not avatar contact or gameplay proof.'])
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2))
(OUT / 'source/build_phase3_knots.py').write_bytes(Path(__file__).read_bytes())
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'SGV2_Phase3_F04.blend'))
scene.cycles.samples=16
scene.render.threads=8
scene.render.resolution_x=1600
scene.render.resolution_y=1000
scene.render.resolution_percentage=100
scene.camera.data.type='PERSP'
scene.camera.data.lens=27
for name, eye, target in [('08-grove-reverse',(79,15,-53),(74,14,-106)),
                          ('09-grove-root-detail',(162,16,-113),(124,8,-106)),
                          ('17-orchard-knot-close',(46,17,-127),(31,11,-139)),
                          ('18-grove-knot-close',(83,15,-90),(68,10,-103))]:
    camera=scene.camera
    camera.location=Vector((eye[0],-eye[2],eye[1]))
    target=Vector((target[0],-target[2],target[1]))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/'views'/f'{name}.png')
    bpy.ops.render.render(write_still=True)
    print('F04_VIEW '+name, flush=True)
print(json.dumps(dict(meshes=9, addedTriangles=manifest['addedTriangles'], fbxBytes=manifest['fbxBytes'])), flush=True)
