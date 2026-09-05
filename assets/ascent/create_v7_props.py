import bpy, math, random, json
from pathlib import Path
from mathutils import Vector, Matrix

BASE = Path(__file__).resolve().parent
exec((BASE / 'create_ascent_props.py').read_text().split('RESULT=build()')[0])
OUT = BASE / 'v7'
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new('AscentV7SculptedProps')
bpy.context.window.scene = scene
COLORS.update({'Cedar': (.12,.29,.16), 'Fern': (.23,.41,.14), 'SummitRock': (.27,.32,.34)})
random.seed(7007)

def massif():
    c = collection('AlpineMassif')
    verts, faces, snow_faces = [], [], []
    n = 33
    for y in range(n):
        for x in range(n):
            u, v = x/(n-1)*2-1, y/(n-1)*2-1
            envelope = max(0, 1-max(abs(u),abs(v))**1.5)
            peaks = max(1.1-math.hypot((u+.22)*1.5,(v-.1)*1.6), .83-math.hypot((u-.36)*1.8,(v+.05)*2), .7-math.hypot((u+.15)*2,(v+.5)*2))
            ridges = .06*math.sin(u*25+v*8)+.035*math.cos(v*31-u*12)
            z = max(0, peaks+ridges)*envelope*140
            verts.append((u*96,v*78,z))
    for y in range(n-1):
        for x in range(n-1):
            a=y*n+x; b=a+1; d=a+n; e=d+1
            faces.extend([(a,b,e),(a,e,d)] if (x+y)%2 else [(a,b,d),(b,e,d)])
    mesh=bpy.data.meshes.new('ErodedRidgeMesh'); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new('AlpineMassif__SummitRock',mesh); c.objects.link(obj); mesh.materials.append(mat('SummitRock'))
    for poly in mesh.polygons: poly.use_smooth=False
    for f in faces:
        ps=[Vector(verts[i]) for i in f]
        normal=(ps[1]-ps[0]).cross(ps[2]-ps[0]).normalized()
        if min(p.z for p in ps)>56 and abs(normal.z)>.35:
            snow_faces.append(f)
    snow_mesh=bpy.data.meshes.new('SnowFields'); snow_mesh.from_pydata([(x,y,z+.25) for x,y,z in verts],[],snow_faces); snow_mesh.update()
    snow_obj=bpy.data.objects.new('AlpineMassif__Snow',snow_mesh); c.objects.link(snow_obj); snow_mesh.materials.append(mat('Snow'))
    return finish(c,'AlpineMassif',150)

def cedar():
    c=collection('Cedar'); height=24
    cyl_between(c,'trunk',(0,0,0),(1.1,.3,22),.48,'Bark',10)
    for tier in range(6):
        z=6+tier*2.55; radius=6.4-tier*.7
        for j in range(5):
            a=j*math.tau/5+tier*.87
            end=(math.cos(a)*radius+.06*z,math.sin(a)*radius,z-.6)
            cyl_between(c,'branch',(.06*z,0,z),end,.12,'Bark',7)
            for k in range(2):
                p=Vector(end)*(.72+k*.19); p.z=z+.5+k*.3
                ico(c,'spray',p,(radius*.37,1.15,1.4),'Cedar',tier*31+j*5+k,2)
    cone(c,'tip',(1.1,.3,22.5),1.7,0,5,10,'Cedar')
    return finish(c,'Cedar',24)

def fern():
    c=collection('Fern'); verts=[]; faces=[]
    for frond in range(9):
        a=frond*math.tau/9
        for i in range(1,8):
            t=i/8; r=t*2.2; z=math.sin(t*math.pi*.8)*1.25
            center=Vector((math.cos(a)*r,math.sin(a)*r,z))
            prev_t=(i-1)/8; previous=(math.cos(a)*prev_t*2.2,math.sin(a)*prev_t*2.2,math.sin(prev_t*math.pi*.8)*1.25)
            cyl_between(c,'stem',previous,center,.022,'Fern',5)
            for side in (-1,1):
                width=(1-t)*.7+.08
                tip=center+Vector((math.cos(a+side*.8)*width,math.sin(a+side*.8)*width,.08))
                offset=Vector((-math.sin(a)*.1,math.cos(a)*.1,0))
                idx=len(verts); verts.extend([center-offset,tip,center+offset]); faces.append((idx,idx+1,idx+2))
    mesh=bpy.data.meshes.new('FernFronds');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('Fern__Fern',mesh);c.objects.link(obj);mesh.materials.append(mat('Fern'))
    return finish(c,'Fern',1.6)

props=[massif(),cedar(),fern()]
objects=[o for c in scene.collection.children for o in c.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'AscentV7Props.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
manifest={'props':props,'colors':{o.name:list(o.data.materials[0].diffuse_color[:3]) for o in objects}}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
gallery=bpy.data.scenes.new('AscentV7Gallery');gallery.world=bpy.data.worlds.new('V7GalleryWorld');gallery.world.color=(.06,.08,.1)
for o in objects:
    q=o.copy();q.data=o.data;gallery.collection.objects.link(q)
    if o.name.startswith('AlpineMassif'): q.matrix_world=Matrix.Translation((-18,10,0)) @ Matrix.Scale(.20,4) @ o.matrix_world
    elif o.name.startswith('Cedar'): q.matrix_world=Matrix.Translation((16,0,0)) @ o.matrix_world
    else: q.matrix_world=Matrix.Translation((19,-13,0)) @ Matrix.Scale(4,4) @ o.matrix_world
camera_data=bpy.data.cameras.new('Camera');camera=bpy.data.objects.new('Camera',camera_data);gallery.collection.objects.link(camera)
camera.location=(60,-104,62);camera.rotation_euler=(Vector((0,2,10))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=110;gallery.camera=camera
gallery.render.engine='BLENDER_WORKBENCH';gallery.display.shading.light='STUDIO';gallery.display.shading.color_type='MATERIAL';gallery.display.shading.show_shadows=True
gallery.render.resolution_x=1400;gallery.render.resolution_y=850;gallery.render.resolution_percentage=100;gallery.render.filepath=str(OUT/'preview.png')
bpy.context.window.scene=gallery;bpy.ops.render.render(write_still=True)
bpy.context.window.scene=scene;bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'AscentV7Props.blend'))
print(json.dumps({'props':props,'output':str(OUT)}))
