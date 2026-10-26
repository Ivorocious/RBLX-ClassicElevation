"""Reconstruct native snapshot geometry in a separate, headless Blender process."""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[4]
OUTPUT = ROOT / 'docs/artifacts/keyboard-circuit/phase3/views-m04'
OUTPUT.mkdir(parents=True, exist_ok=True)
arguments = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
parser = argparse.ArgumentParser()
parser.add_argument('--scene-sha256', required=True)
parser.add_argument('--views', nargs='*', default=[])
args = parser.parse_args(arguments)
native_scene_path = OUTPUT.parent / 'P3-M04-native-scene-01.json'
native_scene_bytes = native_scene_path.read_bytes()
native_scene_sha256 = hashlib.sha256(native_scene_bytes).hexdigest()
if native_scene_sha256 != args.scene_sha256.lower():
    raise ValueError('Native M04 scene does not match the supplied hash')
data = json.loads(native_scene_bytes)
if data['candidate'] != 'KeyboardCircuit_P3_M04_01' or data['revision'] != 'KC_P3_M04_01':
    raise ValueError('Final renderer requires the native M04 candidate')
if len(data['parts']) != 8808 or any('.ArchiveBackdrop.' in part['path'] for part in data['parts']):
    raise ValueError('M04 must contain the expected 8,808 native parts and no physical archive enclosure')
sky_directory = ROOT / 'assets/sky/keyboard-archive'
panorama_path = sky_directory / 'panorama-source.png'
texture_manifest_path = sky_directory / 'texture-manifest.json'
upload_status_path = sky_directory / 'upload-status.json'
texture_manifest = json.loads(texture_manifest_path.read_bytes())
upload_status = json.loads(upload_status_path.read_bytes())
sky_faces = {}
for property_name, face in texture_manifest['roblox_faces'].items():
    face_path = sky_directory / face['file']
    face_hash = hashlib.sha256(face_path.read_bytes()).hexdigest()
    if face_hash != face['sha256'] or upload_status['faces'][property_name]['file'] != face['file']:
        raise ValueError(f'Archive sky face does not match its uploaded reference: {property_name}')
    sky_faces[property_name] = {'file': face_path.relative_to(ROOT).as_posix(), 'sha256': face_hash,
                                'assetId': upload_status['faces'][property_name]['assetId']}
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
conversion = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
origin = Vector(data['origin'])
materials = {}

def linear_color(color):
    return tuple(x / 12.92 if x <= .04045 else ((x + .055) / 1.055) ** 2.4 for x in color)

def material(color, glass=False, alpha=1, emission=0, gui=False):
    key = tuple(round(x, 4) for x in color) + (glass, round(alpha, 4), emission, gui)
    if key not in materials:
        mat = bpy.data.materials.new('Paint')
        mat.diffuse_color = (*color, 1)
        mat.use_nodes = True
        shader = mat.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value = (*((0, 0, 0) if gui else linear_color(color)), 1)
        shader.inputs['Roughness'].default_value = .75
        shader.inputs['Alpha'].default_value = alpha
        if emission or gui:
            shader.inputs['Emission Color'].default_value = (*linear_color(color), 1)
            shader.inputs['Emission Strength'].default_value = 1 if gui else emission
        else:
            tint = (88/112, 103/112, 1)
            shader.inputs['Emission Color'].default_value = (*(value*tint[index] for index,value in enumerate(linear_color(color))), 1)
            shader.inputs['Emission Strength'].default_value = .4
        if glass:
            shader.inputs['Transmission Weight'].default_value = .8
            shader.inputs['Roughness'].default_value = .12
        materials[key] = mat
    return materials[key]

with bpy.data.libraries.load(str(ROOT / 'assets/keyboard_circuit/K02/KC_OrdinaryKey.blend'), link=False) as (source, target):
    target.objects = source.objects
source_key = max((obj for obj in target.objects if obj and obj.type == 'MESH'), key=lambda obj: len(obj.data.vertices))
key_points = [Vector((point.x, point.z, -point.y)) for point in (source_key.matrix_world @ vertex.co for vertex in source_key.data.vertices)]
low = Vector(tuple(min(v[i] for v in key_points) for i in range(3)))
high = Vector(tuple(max(v[i] for v in key_points) for i in range(3)))
center, size = (low + high) / 2, high - low
key_vertices = [tuple((v[i] - center[i]) / size[i] for i in range(3)) for v in key_points]
key_faces = [tuple(poly.vertices) for poly in source_key.data.polygons]
box = [(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,-.5),(.5,.5,-.5),(-.5,.5,.5),(.5,.5,.5)]
box_faces = [(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]
font = bpy.data.fonts.load('C:/Windows/Fonts/arialbd.ttf')
symbol_font = bpy.data.fonts.load('C:/Windows/Fonts/seguisym.ttf')
labels, rectangles = {}, {}
for label in data['labels']:
    labels.setdefault(label['partPath'], []).append(label)
for rectangle in data.get('rectangles', []):
    rectangles.setdefault(rectangle['partPath'], []).append(rectangle)

def surface(part, item, depth):
    face = item['face']
    if face == 'Top':
        basis = Matrix(((1,0,0),(0,0,1),(0,-1,0)))
        offset = Vector((0,part['size'][1]/2+depth,0))
        width,height = part['size'][0],part['size'][2]
    elif face in ('Front','Back'):
        sign = 1 if face == 'Back' else -1
        basis = Matrix(((sign,0,0),(0,1,0),(0,0,sign)))
        offset = Vector((0,0,sign*(part['size'][2]/2+depth)))
        width,height = part['size'][0],part['size'][1]
    else:
        return None
    x,y = item['center']
    offset += basis @ Vector(((x-.5)*width,(.5-y)*height,0))
    angle = -item['rotation']
    turn = Matrix(((math.cos(angle),-math.sin(angle),0),(math.sin(angle),math.cos(angle),0),(0,0,1)))
    return basis @ turn, offset, width*item['size'][0],height*item['size'][1]

mesh_count = 0
visible_parts = 0
preview_effects = {'Underlight': 0, 'WaveBar': 0}
discarded_invisible_parts = 0
for part in data['parts']:
    effect_kind = part.get('effectKind')
    if not effect_kind and '.ArchiveEffectParts.Underlights.' in part['path']:
        effect_kind = 'Underlight'
    if not effect_kind and '.ArchiveEffectParts.LandmarkWaves.' in part['path']:
        effect_kind = 'WaveBar'
    transparency = part['transparency']
    if effect_kind == 'Underlight':
        transparency = part.get('activeTransparency', .24)
        preview_effects['Underlight'] += 1
    elif effect_kind == 'WaveBar':
        transparency = .58
        preview_effects['WaveBar'] += 1
    elif transparency >= .9:
        discarded_invisible_parts += 1
        continue
    cf = part['cf']
    rotation,position = Matrix((cf[3:6],cf[6:9],cf[9:12])),Vector(cf[:3])-origin
    vertices,faces = (key_vertices,key_faces) if part['class']=='MeshPart' else (box,box_faces)
    if part['shape']=='Cylinder':
        vertices=[(x,math.cos(i*math.tau/32)*.5,math.sin(i*math.tau/32)*.5) for x in (-.5,.5) for i in range(32)]
        faces=[tuple(range(31,-1,-1)),tuple(range(32,64))]+[(i,(i+1)%32,(i+1)%32+32,i+32) for i in range(32)]
    vertices=[conversion @ (rotation @ Vector(tuple(v[i]*part['size'][i] for i in range(3)))+position) for v in vertices]
    mesh=bpy.data.meshes.new(part['name'])
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(part['path'],mesh)
    scene.collection.objects.link(obj)
    obj.data.materials.append(material(part['color'],part['material']=='Glass',1-transparency,1.35 if part['material']=='Neon' else 0))
    if hasattr(obj, 'visible_shadow'):
        obj.visible_shadow = part.get('castShadow', not '.ArchiveBackdrop.' in part['path'])
    visible_parts += 1
    mesh_count += part['class']=='MeshPart'
    for index,item in enumerate(rectangles.get(part['path'],[])):
        layout=surface(part,item,.03)
        if not layout:
            continue
        basis,offset,width,height=layout
        corners=[(-.5,-.5,0),(.5,-.5,0),(.5,.5,0),(-.5,.5,0)]
        verts=[conversion @ (position+rotation @ (offset+basis @ Vector((x*width,y*height,z)))) for x,y,z in corners]
        mesh=bpy.data.meshes.new('GuiRectangle')
        mesh.from_pydata(verts,[],[(0,1,2,3)])
        obj=bpy.data.objects.new(item['path'],mesh)
        scene.collection.objects.link(obj)
        mesh.materials.append(material(item['color'],gui=True))
    for index,label in enumerate(labels.get(part['path'],[])):
        layout=surface(part,label,.05)
        if not layout:
            continue
        basis,offset,width,height=layout
        curve=bpy.data.curves.new('Legend','FONT')
        curve.body=label['text']
        curve.align_x=label['align'].upper()
        curve.align_y='CENTER'
        curve.font=symbol_font if any(ord(c)>127 for c in label['text']) else font
        lines=label['text'].splitlines() or ['']
        curve.size=min(width/max(.61*max(map(len,lines)),1),height/max(len(lines),1))*.9
        if label['align']=='Left':
            offset += basis @ Vector((-width/2,0,0))
        elif label['align']=='Right':
            offset += basis @ Vector((width/2,0,0))
        text=bpy.data.objects.new(part['path']+'_Legend_'+str(index),curve)
        scene.collection.objects.link(text)
        text.rotation_euler=(conversion @ rotation @ basis).to_euler()
        text.location=conversion @ (position+rotation @ offset)
        curve.materials.append(material(label['color'],gui=True))

scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.cycles.use_denoising = True
scene.render.threads_mode, scene.render.threads = 'FIXED', 4
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'Standard'
scene.view_settings.exposure = .1
world = bpy.data.worlds.new('Offline Actual Archive Sky')
world.use_nodes = True
sky_nodes, sky_links = world.node_tree.nodes, world.node_tree.links
coordinates = sky_nodes.new('ShaderNodeTexCoord')
mapping = sky_nodes.new('ShaderNodeMapping')
mapping.vector_type = 'VECTOR'
mapping.inputs['Rotation'].default_value = (0, 0, -math.pi / 2)
environment_texture = sky_nodes.new('ShaderNodeTexEnvironment')
environment_texture.image = bpy.data.images.load(str(panorama_path))
environment_texture.projection = 'EQUIRECTANGULAR'
environment_texture.interpolation = 'Linear'
sky_links.new(coordinates.outputs['Generated'], mapping.inputs['Vector'])
sky_links.new(mapping.outputs['Vector'], environment_texture.inputs['Vector'])
sky_links.new(environment_texture.outputs['Color'], sky_nodes['Background'].inputs['Color'])
sky_nodes['Background'].inputs['Strength'].default_value = 1
scene.world = world
light_data = bpy.data.lights.new('Offline Broad Course Fill', 'AREA')
light_data.energy, light_data.shape, light_data.size = 75000, 'DISK', 570
light_data.color = (106/255,118/255,125/255)
light = bpy.data.objects.new('Offline Broad Course Fill', light_data)
scene.collection.objects.link(light)
light.location = conversion @ Vector((0,92,0))
light.rotation_euler = (conversion @ Vector((0,-1,0))).to_track_quat('-Z','Y').to_euler()
offline_bloom = False
try:
    tree = bpy.data.node_groups.new('Offline Gentle Archive Bloom', 'CompositorNodeTree')
    tree.interface.new_socket(name='Image', in_out='OUTPUT', socket_type='NodeSocketColor')
    scene.compositing_node_group = tree
    layers = tree.nodes.new('CompositorNodeRLayers')
    glow = tree.nodes.new('CompositorNodeGlare')
    for choice in ('FOG_GLOW', 'Fog Glow', 'BLOOM', 'Bloom'):
        try:
            glow.inputs['Type'].default_value = choice
            break
        except (TypeError, ValueError, RuntimeError):
            continue
    else:
        raise ValueError('Offline gentle glow mode is unavailable')
    for choice in ('HIGH', 'High'):
        try:
            glow.inputs['Quality'].default_value = choice
            break
        except (TypeError, ValueError, RuntimeError):
            continue
    if hasattr(glow, 'threshold'):
        glow.threshold = 1.25
    if hasattr(glow, 'mix'):
        glow.mix = -.94
    if 'Threshold' in glow.inputs:
        glow.inputs['Threshold'].default_value = 1.25
    if 'Strength' in glow.inputs:
        glow.inputs['Strength'].default_value = .08
    composite = tree.nodes.new('NodeGroupOutput')
    tree.links.new(layers.outputs['Image'], glow.inputs['Image'])
    tree.links.new(glow.outputs['Image'], composite.inputs['Image'])
    offline_bloom = True
except (AttributeError, TypeError, ValueError, RuntimeError):
    scene.compositing_node_group = None
camera_data = bpy.data.cameras.new('Offline Evidence Camera')
camera = bpy.data.objects.new('Offline Evidence Camera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
def find_part(path):
    matches = [part for part in data['parts'] if part['path'] == path]
    if len(matches) != 1:
        raise ValueError(f'Expected one native part at {path}; found {len(matches)}')
    return matches[0]
def point(p):
    return Vector(p['cf'][:3])-origin
def approach_view(name,sign_path,host_path,distance=20,height=6):
    sign,host=find_part(sign_path),find_part(host_path)
    target=point(sign)
    eye=point(host)+Vector((0,height,0))
    return {'name':name,'eye':list(eye),'target':list(target),'lens':30,'signPath':sign_path,'hostPath':host_path,'heightAboveContactCenter':height,'cameraAboveBankCenter':True}
views=[
    approach_view('start-station','MapEnvironment.Wayfinding.CheckpointStation_F00.HardwareCase','CheckpointBays.F00.BankContact',24),
    approach_view('normal-expert-choice','MapEnvironment.Wayfinding.CheckpointStation_R1.HardwareCase','Districts.S01_CreamyCloudbank.H02_SpacebarSeesaws.ExitBank.BankContact',22),
    approach_view('checkpoint-shuttle-exit','MapEnvironment.Wayfinding.CheckpointStation_R3.HardwareCase','Districts.S03_ClackyCarriage.H06_CarriageShuttle.ExitBank.BankContact',30,7),
    approach_view('falling-key-warning','MapEnvironment.HazardIndicators.H04_Warning1_Entry.DisplayPanel','Districts.S02_ThockySwitchworks.H04_FallingKeyFoundry.EntryBank.BankContact',22,6),
    {'name':'repaired-brackets','eye':[45,47,82],'target':list((point(find_part('Districts.S03_ClackyCarriage.O05.BracketLeft.BankContact'))+point(find_part('Districts.S03_ClackyCarriage.O05.BracketRight.BankContact')))/2),'lens':34},
    {'name':'archive-skybox-overview','eye':[-315,82,300],'target':[15,14,-12],'lens':22,'usesSkyEnvironment':True,'overviewAboveCourse':True},
]
shuttle_view = views[2]
shuttle_view['additionalSignPath'] = 'MapEnvironment.HazardIndicators.H06_ExitWarning_Exit.DisplayPanel'
shuttle_view['target'] = list((Vector(shuttle_view['target']) + point(find_part(shuttle_view['additionalSignPath']))) / 2)
shuttle_view['eye'] = list(point(find_part(shuttle_view['hostPath'])) + Vector((0, 7, 0)))
shuttle_view['lens'] = 24
shuttle_view['cameraAboveBankCenter'] = True
foundry_boards = sorted((part for part in data['parts'] if part['path'].startswith('MapEnvironment.HazardIndicators.H04_') and part['name']=='DisplayPanel'), key=lambda part:part['path'])
if len(foundry_boards) != 3:
    raise ValueError(f'Expected three current Foundry warning boards, found {len(foundry_boards)}')
views[3]['target'] = list(sum((point(part) for part in foundry_boards),Vector((0,0,0)))/len(foundry_boards))
views[3]['additionalSignPaths'] = [part['path'] for part in foundry_boards]
views[3]['lens'] = 26
requested_views = set(args.views)
unknown_views = requested_views - {view['name'] for view in views}
if unknown_views:
    raise ValueError(f'Unknown review views: {sorted(unknown_views)}')
for view in views:
    if requested_views and view['name'] not in requested_views:
        continue
    camera.location = conversion @ Vector(view['eye'])
    target = conversion @ Vector(view['target'])
    camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera_data.type = 'ORTHO' if 'ortho' in view else 'PERSP'
    camera_data.lens = view.get('lens', 34)
    if 'ortho' in view:
        camera_data.ortho_scale = view['ortho']
    scene.render.filepath = str((OUTPUT / (view['name']+'.png')).resolve())
    bpy.ops.render.render(write_still=True)
    print('MAP_VIEW '+view['name'], flush=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str((OUTPUT.parent / 'KC_P3_M04_01_Offline.blend').resolve()))
rendered_views = [view['name'] for view in views if not requested_views or view['name'] in requested_views]
lighting_profile = {'Ambient':[88,103,112],'OutdoorAmbient':[106,118,125],'Brightness':1.25,'ClockTime':19.2,'ExposureCompensation':.1,'EnvironmentDiffuseScale':.55,'EnvironmentSpecularScale':.18,'BloomIntensity':.08,'BloomThreshold':1.25}
limits = [data['limits'],'The world environment uses the actual selected archive panorama; no physical archive shelf, roof, wall or floor geometry is added. The uploaded cube faces additionally include seam/pole normalization and Roblox front/back/pole transforms, so this panorama preview is not pixel-identical native sky or orientation proof.','Offline lighting uses an approximate Blender ambient model, not a calibrated Roblox render. Opaque materials include a .4-strength ambient tint. The broad area fill exists only in this artifact; the native course adds no dynamic lights.','SurfaceGui colors are rendered unlit and fonts use Arial/Segoe substitutes; rounding, exact wrapping, draw-distance cutoffs and LightInfluence are approximations.','Only authorized underlight anchors and the .8-stud resting landmark bars are shown as static illustrative effects. USB startup/lap states, moving pulses, key-reactive animation and the subtle low depth plane are omitted; actual activation/restoration must be verified natively.','The overview displays all static illustrative anchors together. Actual runtime cosmetic visibility is distance/quality bounded. No FPS, device, multiplayer or human timing result is inferred.','Edit warning labels retain their exported STOPPED state. Owner-positioned native board transforms are preserved.']
sky_environment = {'panorama':panorama_path.relative_to(ROOT).as_posix(),'panoramaSha256':hashlib.sha256(panorama_path.read_bytes()).hexdigest(),'textureManifest':texture_manifest_path.relative_to(ROOT).as_posix(),'textureManifestSha256':hashlib.sha256(texture_manifest_path.read_bytes()).hexdigest(),'uploadStatus':upload_status_path.relative_to(ROOT).as_posix(),'uploadStatusSha256':hashlib.sha256(upload_status_path.read_bytes()).hexdigest(),'uploadedFaces':sky_faces,'projection':'EQUIRECTANGULAR','blenderMappingRotationDegrees':[0,0,-90],'nativeSkyboxOrientationDegrees':[0,0,0],'coordinates':'Native (x,y,z) becomes Blender (x,-z,y); the environment vector rotates -90 degrees around Blender Z. Native cubemap orientation is separately verified in Studio.','physicalEnclosureParts':0}
manifest = {'candidate':data['candidate'],'revision':data['revision'],'offline':True,'views':views,'renderedViews':rendered_views,'nativePartCount':len(data['parts']),'visiblePartCount':visible_parts,'discardedInvisibleNativeParts':discarded_invisible_parts,'visibleMeshParts':mesh_count,'nativeLabelCount':len(data['labels']),'nativeRectangleCount':len(data.get('rectangles',[])),'staticIllustrativeEffectParts':preview_effects,'keyMeshVertices':len(key_vertices),'keyMeshFaces':len(key_faces),'meshSource':'assets/keyboard_circuit/K02/KC_OrdinaryKey.blend','meshSourceSha256':hashlib.sha256((ROOT/'assets/keyboard_circuit/K02/KC_OrdinaryKey.blend').read_bytes()).hexdigest(),'sourceScene':native_scene_path.relative_to(ROOT).as_posix(),'sourceSceneSha256':native_scene_sha256,'rendererSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'skyEnvironment':sky_environment,'nativeLightingProfile':lighting_profile,'offlineLighting':{'ambientRadianceColor':[88/255,103/255,112/255],'opaqueAmbientTint':[88/112,103/112,1],'opaqueAmbientStrength':.4,'worldStrength':1,'broadAreaEnergy':75000,'broadAreaSize':570,'bloomApproximated':offline_bloom,'threads':4,'samples':16},'limits':limits}
manifest['outputHashes'] = {name:hashlib.sha256((OUTPUT/(name+'.png')).read_bytes()).hexdigest() for name in rendered_views}
(OUTPUT / 'render-manifest.json').write_text(json.dumps(manifest,indent=2))

