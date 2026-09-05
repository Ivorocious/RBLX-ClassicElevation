import bpy, math, json, random
from pathlib import Path
from mathutils import Vector, Matrix

OUT = Path(r"C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\ascent")
random.seed(7315)

COLORS = {
    "Bark": (0.24, 0.12, 0.055), "Needles": (0.055, 0.22, 0.12), "Snow": (0.83, 0.91, 0.94),
    "Granite": (0.31, 0.34, 0.34), "Basalt": (0.10, 0.14, 0.16), "Lichen": (0.30, 0.39, 0.20),
    "Limestone": (0.48, 0.45, 0.35), "Ice": (0.33, 0.68, 0.82), "Grass": (0.18, 0.38, 0.12),
    "FlowerWhite": (0.95, 0.93, 0.81), "FlowerYellow": (0.95, 0.62, 0.05), "FlowerPurple": (0.48, 0.20, 0.62),
    "Coal": (0.025, 0.03, 0.035), "Carrot": (0.95, 0.27, 0.035), "Scarf": (0.58, 0.055, 0.045),
}

def mat(name):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color = (*COLORS[name], 1)
    m.roughness = 0.82
    return m

def collection(name):
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    return c

def move_to(obj, col):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    col.objects.link(obj)
    return obj

def cube(col, name, loc, scale, material, rot=(0,0,0), bevel=0):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod=o.modifiers.new('ChippedEdges','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(mat(material)); return move_to(o,col)

def cone(col,name,loc,r1,r2,depth,verts,material,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; o.data.materials.append(mat(material)); return move_to(o,col)

def ico(col,name,loc,scale,material,seed=0,sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=1, location=loc)
    o=bpy.context.object; o.name=name
    rng=random.Random(seed)
    for v in o.data.vertices:
        v.co *= 0.78+rng.random()*0.38
    o.scale=scale; bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat(material)); return move_to(o,col)

def cyl_between(col,name,a,b,r,material,verts=7):
    a,b=Vector(a),Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r*.72, depth=d.length, location=(a+b)/2)
    o=bpy.context.object; o.name=name; o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y')
    o.data.materials.append(mat(material)); return move_to(o,col)

def join_named(col,prefix,material_name):
    objs=[o for o in col.objects if o.type=='MESH' and o.data.materials and o.data.materials[0].name==material_name]
    if not objs:return None
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); objs[0].name=f'{prefix}__{material_name}'
    return objs[0]

def finish(col,name,height):
    for material_name in COLORS: join_named(col,name,material_name)
    meshes=[o for o in col.objects if o.type=='MESH']
    points=[o.matrix_world @ Vector(corner) for o in meshes for corner in o.bound_box]
    low=min(p.z for p in points); high=max(p.z for p in points); factor=height/(high-low)
    for o in meshes:
        inverse=o.matrix_world.inverted()
        for vertex in o.data.vertices:
            world=o.matrix_world @ vertex.co
            world.z=(world.z-low)*factor
            vertex.co=inverse @ world
    triangles=0
    for o in meshes:
        o.data.calc_loop_triangles(); triangles += len(o.data.loop_triangles)
    return {"name":name,"height":height,"parts":sorted(o.name for o in meshes),"triangles":triangles}

def pine(name,height,lean=0,snow=False):
    c=collection(name); trunk_top=(lean,0,height*.72)
    cyl_between(c,'trunk',(0,0,0),trunk_top,.48,'Bark',8)
    # Visible whorled branches support irregular, angular foliage plates.
    for tier in range(5):
        z=height*(.28+tier*.115); radius=(height*(.23-tier*.027))
        cx=lean*(z/(height*.72))
        for branch in range(5):
            ang=branch*math.tau/5+tier*.61
            length=radius*(.78+random.random()*.28)
            tip=(cx+math.cos(ang)*length,math.sin(ang)*length,z-.3-random.random()*.6)
            cyl_between(c,'branch',(cx,0,z),tip,.16,'Bark',6)
            cone(c,'foliage',(tip[0]*.62+cx*.38,tip[1]*.62,z+1.2),radius*.54,radius*.10,4.8,7,'Needles',rot=(0.08*math.sin(ang),0.10*math.cos(ang),ang*.08))
            if snow and tier>=2:
                cone(c,'snow',(tip[0]*.60+cx*.40,tip[1]*.60,z+2.25),radius*.43,0,1.05,7,'Snow')
    cone(c,'crown',(lean*.98,0,height-2.1),height*.105,0,5.2,7,'Needles',rot=(0,lean*.012,0))
    if snow: cone(c,'snowcap',(lean*.98,0,height-.3),height*.08,0,1.4,7,'Snow')
    return finish(c,name,height)

def boulder(name,material,seed,lichen=False):
    c=collection(name); ico(c,'body',(0,0,2.25),(3.0,2.5,2.75),material,seed,2)
    if lichen:
        for i in range(5): ico(c,'lichen',(-1.4+i*.65,.4+math.sin(i)*.8,4.25),(0.48,.18,.18),'Lichen',seed+i,1)
    return finish(c,name,5)

def pillar(name,lean,seed):
    c=collection(name)
    # Broken octagonal shaft segments leave a readable chipped silhouette.
    cone(c,'shaft',(0,0,8.1),1.55,1.28,14.7,8,'Limestone',rot=(0,lean,0))
    cone(c,'base',(0,0,.65),2.35,2.1,1.3,8,'Limestone')
    cone(c,'capital',(math.sin(lean)*15.1,0,15.15),2.15,1.75,1.6,8,'Limestone',rot=(0,lean,0))
    for i in range(3): ico(c,'chips',(-1+i,0.7-i*.35,16.1+i*.12),(.7,.5,.45),'Limestone',seed+i,1)
    return finish(c,name,18)

def ice_tooth(name,height,seed):
    c=collection(name)
    cone(c,'tooth',(0,0,height/2),2.25,.08,height,5,'Ice',rot=(.04*(seed%3),-.06*(seed%2),.12))
    cone(c,'spur',(1.6,.2,height*.28),1.0,0,height*.48,5,'Ice',rot=(0,.28,0))
    return finish(c,name,height)

def plant(name,flowers=False):
    c=collection(name)
    for i in range(12):
        a=i*2.399; r=.15+(i%5)*.16; h=1.15+(i%4)*.23
        cube(c,'blade',(math.cos(a)*r,math.sin(a)*r,h/2),(.055,.18,h/2),'Grass',rot=(.14*math.sin(a),.14*math.cos(a),a))
    if flowers:
        flower_mats=['FlowerWhite','FlowerYellow','FlowerPurple']
        for i in range(6):
            a=i*2.14; r=.25+(i%3)*.24; h=1.45+(i%4)*.14
            cyl_between(c,'stem',(math.cos(a)*r,math.sin(a)*r,0),(math.cos(a)*r,math.sin(a)*r,h),.025,'Grass',5)
            for p in range(4):
                pa=p*math.tau/4
                cone(c,'petal',(math.cos(a)*r+math.cos(pa)*.13,math.sin(a)*r+math.sin(pa)*.13,h),.14,0,.07,4,flower_mats[i%3],rot=(math.pi/2,0,pa))
    return finish(c,name,2)

def root_log():
    name='RootLog'; c=collection(name)
    cyl_between(c,'log',(-3,0,1.2),(3,0,1.55),1.05,'Bark',9)
    for side in (-1,1):
        base=(side*2.8,0,1.35)
        for i in range(4):
            ang=i*math.tau/4+.3
            cyl_between(c,'root',base,(side*(3.7+random.random()),math.sin(ang)*1.8,.15),.28,'Bark',6)
    for x in (-1.7,0,1.8): cone(c,'cutbranch',(x,.6,2.0),.32,.18,1.2,7,'Bark',rot=(math.pi/2,.2,0))
    return finish(c,name,3.4)

def snowman():
    name='Snowman'; c=collection(name)
    for z,r in ((1.65,1.65),(4.0,1.35),(6.05,1.05)): ico(c,'snow',(0,0,z),(r,r,r),'Snow',30+int(z*10),2)
    for x in (-.38,.38): ico(c,'eye',(x,-.91,6.3),(.13,.10,.13),'Coal',4,1)
    cone(c,'nose',(0,-1.32,6.02),.20,0,1.0,7,'Carrot',rot=(math.pi/2,0,0))
    cyl_between(c,'armL',(-1.05,0,4.7),(-2.5,.2,5.7),.09,'Bark',6); cyl_between(c,'armR',(1.05,0,4.7),(2.55,-.1,5.45),.09,'Bark',6)
    cone(c,'scarf',(0,0,5.16),1.16,1.16,.34,12,'Scarf'); cube(c,'scarfTail',(.75,.1,4.58),(.28,.12,.75),'Scarf',rot=(0,.2,.18))
    return finish(c,name,7)

def cover_outcrop():
    name='SnowCoverOutcrop'; c=collection(name)
    for i,(x,y,z,s) in enumerate(((-2,0,2.2,(2.7,2.0,2.4)),(1.5,.2,3.0,(2.8,2.1,3.2)),(0,1.0,5.4,(2.0,1.6,2.7)))):
        ico(c,'rock',(x,y,z),s,'Granite',90+i,2)
        ico(c,'snow',(x,y-.08,z+s[2]*.76),(s[0]*.78,s[1]*.82,.38),'Snow',100+i,1)
    return finish(c,name,8)

def build():
    previous_scene=bpy.context.window.scene
    old=bpy.data.scenes.get('AscentPropsV5')
    if old: bpy.data.scenes.remove(old,do_unlink=True)
    scene=bpy.data.scenes.new('AscentPropsV5'); bpy.context.window.scene=scene
    props=[pine('PineA',22),pine('PineWind',20,lean=3.8),pine('PineSnow',25,lean=1.0,snow=True),
           boulder('GraniteBoulder','Granite',11),boulder('BasaltBoulder','Basalt',21),boulder('LichenBoulder','Granite',31,True),
           pillar('RuinPillarA',.04,41),pillar('RuinPillarB',-.12,51),ice_tooth('IceToothA',7,1),ice_tooth('IceToothB',8,2),
           plant('GrassClump'),plant('Wildflowers',True),root_log(),snowman(),cover_outcrop()]
    source_objects=[o for c in scene.collection.children for o in c.objects if o.type=='MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in source_objects:o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=str(OUT/'AscentProps.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
    colors={o.name:list(o.data.materials[0].diffuse_color[:3]) for o in source_objects if o.data.materials}
    manifest={'scene':'AscentPropsV5','authorUnits':'studs','props':props,'colors':colors}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    gallery=bpy.data.scenes.get('AscentPropsGallery') or bpy.data.scenes.new('AscentPropsGallery')
    for o in list(gallery.objects): bpy.data.objects.remove(o,do_unlink=True)
    gallery.world=bpy.data.worlds.new('AscentGalleryWorld') if not gallery.world else gallery.world
    gallery.world.color=(0.035,0.045,0.055)
    gallery_positions={
        'PineA':(-24,14),'PineWind':(-12,14),'PineSnow':(0,14),'RuinPillarA':(12,14),'RuinPillarB':(24,14),
        'GraniteBoulder':(-24,0),'BasaltBoulder':(-12,0),'LichenBoulder':(0,0),'IceToothA':(12,0),'IceToothB':(24,0),
        'GrassClump':(-24,-14),'Wildflowers':(-12,-14),'RootLog':(0,-14),'Snowman':(12,-14),'SnowCoverOutcrop':(24,-14),
    }
    for p in props:
        gx,gy=gallery_positions[p['name']]
        for source in source_objects:
            if source.name.startswith(p['name']+'__'):
                duplicate=source.copy(); duplicate.data=source.data
                duplicate.name='Gallery_'+source.name; duplicate.matrix_world=Matrix.Translation((gx,gy,0)) @ source.matrix_world
                gallery.collection.objects.link(duplicate)
    camera_data=bpy.data.cameras.new('GalleryCamera'); camera=bpy.data.objects.new('GalleryCamera',camera_data); gallery.collection.objects.link(camera)
    camera.location=(42,-108,62); target=Vector((0,2,8)); camera.rotation_euler=(target-Vector(camera.location)).to_track_quat('-Z','Y').to_euler(); camera.data.lens=58
    gallery.camera=camera; gallery.render.engine='BLENDER_WORKBENCH'; gallery.display.shading.light='STUDIO'; gallery.display.shading.studio_light='paint.sl'; gallery.display.shading.show_shadows=True
    gallery.render.resolution_x=1400; gallery.render.resolution_y=900; gallery.render.resolution_percentage=100
    gallery.render.filepath=str(OUT/'AscentProps_preview.png'); gallery.render.image_settings.file_format='PNG'
    bpy.context.window.scene=gallery; bpy.ops.render.render(write_still=True); bpy.context.window.scene=scene
    # Keep the existing source scene in the saved file and leave this kit active.
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'AscentProps.blend'))
    return {'props':len(props),'objects':len(source_objects),'triangles':{p['name']:sum(len(o.data.polygons) for o in source_objects if o.name.startswith(p['name']+'__')) for p in props}}

RESULT=build()
