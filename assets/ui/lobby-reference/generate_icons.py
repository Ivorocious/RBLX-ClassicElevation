"""Generate isolated, editable lobby icon scenes. Run with Blender --background --python."""
import bpy
import math
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
NAVY = '081E52'

def material(name, value, metallic=0, roughness=.3, glow=.12):
    rgb = tuple(int(value[i:i+2],16)/255 for i in (0,2,4))
    rgb = tuple(v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in rgb)
    m=bpy.data.materials.new(name)
    m.diffuse_color=(*rgb,1)
    m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*rgb,1)
    p.inputs['Metallic'].default_value=metallic
    p.inputs['Roughness'].default_value=roughness
    p.inputs['Emission Color'].default_value=(*rgb,1)
    p.inputs['Emission Strength'].default_value=glow
    if name == 'Navy':
        p.inputs['Roughness'].default_value=.8
        p.inputs['Specular IOR Level'].default_value=.08
    return m

def apply(obj, mat):
    obj.data.materials.append(mat)
    return obj

def bevel(obj,width=.055):
    m=obj.modifiers.new('Soft toy edge','BEVEL');m.width=width;m.segments=4
    n=obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return obj

def poly(name,pts,mat,y=0,depth=.15,edge=.04):
    verts=[(x,y-depth/2,z) for x,z in pts]+[(x,y+depth/2,z) for x,z in pts]
    n=len(pts)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob)
    apply(ob,mat)
    if edge:bevel(ob,edge)
    return ob

def tube(name,pts,mat,r=.04):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.resolution_u=24
    curve.bevel_depth=r;curve.bevel_resolution=5
    sp=curve.splines.new('POLY');sp.points.add(len(pts)-1)
    for p,co in zip(sp.points,pts):p.co=(*co,1)
    ob=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(ob);apply(ob,mat)
    return ob

def circle_line(name,x,y,z,r,mat,width=.04):
    return tube(name,[(x+r*math.cos(i*math.tau/96),y,z+r*math.sin(i*math.tau/96)) for i in range(97)],mat,width)

def disc(name,r,depth,y,z,mat,edge=.025):
    bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=r,depth=depth,location=(0,y,z),rotation=(math.pi/2,0,0))
    ob=bpy.context.object;ob.name=name;apply(ob,mat);bevel(ob,edge)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def sphere(name,loc,scale,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24,location=loc)
    ob=bpy.context.object;ob.name=name;ob.scale=scale;apply(ob,mat)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    scene=bpy.context.scene
    scene.render.engine='CYCLES';scene.cycles.samples=32
    scene.cycles.use_denoising=True
    scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard'
    scene.world=bpy.data.worlds.new('Soft studio');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.72,.85,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.15
    bpy.ops.object.camera_add(location=(0,-10,2.2))
    camera=bpy.context.object;camera.name='Icon camera'
    camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO';camera.data.ortho_scale=3.05;scene.camera=camera
    for name,loc,power,size in [('Large upper left',(-3,-4,6),180,4),('Cool rim',(3,1,3),130,3),('Front fill',(0,-4,0),40,3)]:
        bpy.ops.object.light_add(type='AREA',location=loc)
        light=bpy.context.object;light.name=name;light.data.energy=power;light.data.shape='DISK';light.data.size=size
        light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler()
    return {n:material(n,c,m,r,g) for n,c,m,r,g in [
        ('Navy',NAVY,0,.4,.3),('White','FFFFFF',0,.23,.15),('Pale','DAEAFF',0,.3,.1),
        ('Gold','FFBA00',.35,.25,.2),('GoldLight','FFE851',.2,.23,.15),('Amber','F39200',.2,.3,.15),
        ('Star','FFF1A0',.2,.23,.2),('Red','D92A21',0,.3,.12),('Cyan','00DBFF',.2,.25,.25),('Blue','008BC8',.1,.25,.15)]}

def coin(m):
    disc('Navy silhouette',1.1,.22,0,0,m['Navy'])
    disc('Pale rim',1.01,.08,-.145,.02,m['Star'])
    disc('Golden rim',.96,.10,-.22,.02,m['Gold'])
    disc('Recessed amber face',.79,.035,-.285,.02,m['Amber'])
    disc('Golden center',.73,.035,-.31,.04,m['Gold'])
    circle_line('Inner bright ring',0,-.35,.04,.77,m['GoldLight'],.018)
    pts=[(0, .64),(.15,.18),(.61,.04),(.15,-.1),(0,-.55),(-.15,-.1),(-.61,.04),(-.15,.18)]
    poly('Compass star bevel',pts,m['Amber'],-.385,.06,.025)
    poly('Compass star',[(x*.94,z*.94+.02) for x,z in pts],m['Star'],-.44,.055,.024)
    poly('Star shaded facet',[(0,.61),(.14,.18),(.57,.04),(0,.04)],m['GoldLight'],-.48,.015,.008)
    tube('Upper rim shine',[(.96*math.cos(t),-.29,.02+.96*math.sin(t)) for t in [math.pi*.22+i*.009 for i in range(70)]],m['White'],.025)

def racer(m):
    sphere('Shoulder dark border',(0,.08,-.72),(1.13,.57,.40),m['Navy'])
    sphere('White shoulders',(0,-.06,-.68),(1.02,.49,.32),m['White'])
    bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=.68,depth=1.33,location=(0,0,.18))
    ob=bpy.context.object;ob.name='Head navy border';apply(ob,m['Navy']);bevel(ob,.18)
    for p in ob.data.polygons:p.use_smooth=True
    bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=.625,depth=1.26,location=(0,-.28,.22))
    ob=bpy.context.object;ob.name='Smiling white cylinder';apply(ob,m['White']);bevel(ob,.16)
    for p in ob.data.polygons:p.use_smooth=True
    for x in [-.2,.2]:sphere('Eye',(x,-.88,.36),(.049,.035,.105),m['Navy'])
    pts=[(.22*math.cos(t),-.906,.20-.23*math.sin(t)) for t in [i*math.pi/40 for i in range(41)]]
    tube('Smile',pts,m['Navy'],.039)

def trophy(m):
    for sign in [-1,1]:
        pts=[(sign*x,.02,z) for x,z in [(.64,.75),(.95,.76),(1.00,.63),(.98,.24),(.85,.02),(.60,-.10)]]
        tube('Handle outline',pts,m['Navy'],.12)
        tube('Golden handle',[(x,-.08,z) for x,y,z in pts],m['Gold'],.066)
    bowl=[(-.76,.94),(.76,.94),(.69,.23),(.54,-.06),(.25,-.25),(-.25,-.25),(-.54,-.06),(-.69,.23)]
    poly('Cup outline',bowl,m['Navy'],0,.28,.11)
    inner=[(x*.88,z*.90+.025) for x,z in bowl]
    poly('Golden cup',inner,m['Gold'],-.19,.22,.1)
    tube('Cup top bright lip',[(-.66,-.33,.83),(.66,-.33,.83)],m['GoldLight'],.06)
    poly('Stem outline',[(-.17,-.15),(.17,-.15),(.17,-.68),(.43,-.84),(-.43,-.84),(-.17,-.68)],m['Navy'],0,.25,.05)
    poly('Golden stem',[(-.09,-.17),(.09,-.17),(.09,-.66),(.33,-.82),(-.33,-.82),(-.09,-.66)],m['Gold'],-.18,.20,.04)
    poly('Base outline',[(-.54,-.79),(.54,-.79),(.54,-1.03),(-.54,-1.03)],m['Navy'],-.07,.34,.075)
    poly('Golden base',[(-.45,-.82),(.45,-.82),(.45,-.95),(-.45,-.95)],m['Gold'],-.29,.12,.045)
    medal=disc('Cup medallion',.21,.04,-.35,.34,m['GoldLight']);medal.scale.z=1.13
    tube('Left cup shine',[(-.48,-.34,.67),(-.46,-.34,.34),(-.36,-.34,.12)],m['Star'],.048)

def bag(m):
    pts=[(-.79,.49),(.79,.49),(.90,-.94),(.77,-1.02),(-.77,-1.02),(-.90,-.94)]
    poly('Bag navy outline',pts,m['Navy'],.07,.3,.10)
    poly('Red bag edge',[(x*.92,z*.94) for x,z in pts],m['Red'],-.12,.22,.095)
    poly('White bag',[(x*.81,z*.86) for x,z in pts],m['White'],-.26,.18,.075)
    arc=[(.37*math.cos(t),-.32,.50+.55*math.sin(t)) for t in [i*math.pi/64 for i in range(65)]]
    tube('Handle navy outline',arc,m['Navy'],.117)
    tube('Handle red rim',[(x,y-.045,z) for x,y,z in arc],m['Red'],.088)
    tube('White handle',[(x,y-.08,z) for x,y,z in arc],m['White'],.053)
    for x in [-.37,.37]:tube('Handle foot',[(x,-.41,.53),(x,-.41,.31)],m['White'],.053)
    tube('Left bag highlight',[(-.62,-.365,.22),(-.64,-.365,-.62)],m['White'],.028)

def key(m):
    shaft=[(-.18,.18),(.20,.18),(.20,-.98),(-.18,-.98),(-.18,-.77),(-.46,-.77),(-.46,-.49),(-.18,-.49),(-.18,-.25),(-.46,-.25)]
    root=bpy.data.objects.new('Tilted cyan key',None);bpy.context.collection.objects.link(root)
    for pts,name in [(shaft,'Shaft')]:
        ob=poly(name+' navy edge',pts,m['Navy'],0,.24,.055);ob.parent=root
        # Face inset uses smaller bevel and a slightly scaled silhouette.
        cx=sum(x for x,z in pts)/len(pts);cz=sum(z for x,z in pts)/len(pts)
        face=[(cx+(x-cx)*.84,cz+(z-cz)*.84) for x,z in pts]
        ob=poly(name+' cyan face',face,m['Cyan'],-.17,.12,.035);ob.parent=root
    def bow(name,outer,inner,y,mat):
        n=len(outer)
        vs=[(x,y-.055,z) for x,z in outer+inner]+[(x,y+.055,z) for x,z in outer+inner]
        fs=[]
        for i in range(n):
            j=(i+1)%n
            fs.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.update()
        ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);apply(ob,mat);bevel(ob,.025);ob.parent=root
    outside=[(-.48,1.06),(.48,1.06),(.68,.82),(.68,.23),(.47,.03),(-.48,.03),(-.68,.23),(-.68,.82)]
    inside=[(-.22,.81),(.22,.81),(.37,.67),(.37,.43),(.22,.28),(-.22,.28),(-.37,.43),(-.37,.67)]
    bow('Bow navy outline',outside,inside,-.13,m['Navy'])
    bow('Bow cyan face',[(x*.88,(z-.55)*.88+.55) for x,z in outside],[(x*1.12,(z-.55)*1.12+.55) for x,z in inside],-.225,m['Cyan'])
    root.rotation_euler.y=.40
    tube('Key upper shine',[(-.39,-.27,.87),(-.25,-.27,.95),(.15,-.27,.95)],m['White'],.025).parent=root

def gear(m):
    n=48
    pts=[]
    for i in range(n):
        a=math.tau*i/n
        r=1.03 if i%6 in [1,2,3,4] else .84
        pts.append((r*math.cos(a),r*math.sin(a)))
    verts=[]
    for y in [-.12,.12]:
        verts += [(x,y,z) for x,z in pts]
        verts += [(.36*math.cos(i*math.tau/n),y,.36*math.sin(i*math.tau/n)) for i in range(n)]
    faces=[]
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
    mesh=bpy.data.meshes.new('Gear hollow mesh');mesh.from_pydata(verts,[],faces);mesh.update()
    ob=bpy.data.objects.new('Navy eight tooth gear',mesh);bpy.context.collection.objects.link(ob);apply(ob,m['Navy']);bevel(ob,.045)
    tube('Upper edge blue gleam',[(-.60,-.18,.59),(-.42,-.18,.75),(-.23,-.18,.77)],m['Blue'],.018)

for name, build in [('coin',coin),('racer',racer),('trophy',trophy),('shop-bag',bag),('key',key),('settings-gear',gear)]:
    m=setup();build(m)
    bpy.context.scene.render.filepath=str(OUT/(name+'.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(name+'.blend')))
    bpy.ops.render.render(write_still=True)
    print('ICON_COMPLETE '+name,flush=True)
