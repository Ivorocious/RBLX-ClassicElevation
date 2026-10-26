"""Render raised compass facets, a curved trophy and a two-tone key in editable scenes."""
from pathlib import Path
import math
import bpy

folder = Path(__file__).resolve().parent
base = (folder / 'generate_icons.py').read_text().split('\nfor name, build in ')[0]
base = base.replace("tube('White handle',[(x,y-.08,z) for x,y,z in arc],m['White'],.053)","tube('White handle',[(x,y-.08,z) for x,y,z in arc],m['White'],.080)")
base = base.replace("[(x,-.41,.53),(x,-.41,.31)],m['White'],.053)","[(x,-.41,.53),(x,-.41,.31)],m['White'],.080)")
scope = {'__file__': str(folder / 'generate_icons.py')}
exec(compile(base, str(folder / 'generate_icons.py'), 'exec'), scope)
poly, tube, disc, bevel, apply = [scope[n] for n in ('poly', 'tube', 'disc', 'bevel', 'apply')]

def setup():
    mats = scope['setup']()
    bpy.context.scene.cycles.samples = 48
    bpy.data.objects['Large upper left'].data.energy = 240
    bpy.data.objects['Cool rim'].data.energy = 85
    bpy.data.objects['Front fill'].data.energy = 40
    white = mats['White'].node_tree.nodes['Principled BSDF']
    white.inputs['Roughness'].default_value = .38
    white.inputs['Emission Strength'].default_value = .45
    gold = mats['Gold'].node_tree.nodes['Principled BSDF']
    gold.inputs['Metallic'].default_value = .2
    gold.inputs['Emission Strength'].default_value = .3
    return mats

def coin(m):
    disc('Navy silhouette', 1.08, .24, .02, 0, m['Navy'], .035)
    disc('Amber outer bevel', 1.01, .13, -.13, .02, m['Amber'], .035)
    disc('Golden raised rim', .96, .10, -.23, .02, m['GoldLight'], .035)
    disc('Recessed amber face', .81, .03, -.295, .02, m['Amber'], .015)
    disc('Warm gold field', .755, .03, -.324, .02, m['Gold'], .015)
    scope['circle_line']('Inner rim gleam', 0, -.355, .02, .79, m['GoldLight'], .025)
    points = [(0,.67),(.145,.165),(.63,.02),(.145,-.125),(0,-.61),(-.145,-.125),(-.63,.02),(-.145,.165)]
    poly('Star amber edge', points, m['Amber'], -.402, .05, .010)
    face = [(x*.94, -.465, z*.94+.02) for x,z in points]
    center = (0, -.63, .03)
    colors = ['Star','GoldLight','Gold','Amber','Gold','GoldLight','Star','Star']
    for i, material in enumerate(colors):
        mesh = bpy.data.meshes.new('Raised ray facet')
        mesh.from_pydata([face[i], face[(i+1)%8], center], [], [(0,1,2)])
        mesh.update()
        ob = bpy.data.objects.new('Compass facet '+str(i+1), mesh)
        bpy.context.collection.objects.link(ob)
        apply(ob, m[material])
    tube('Rim upper left glint', [(.965*math.cos(t),-.303,.02+.965*math.sin(t)) for t in [1.9+i*.009 for i in range(66)]], m['White'], .028)

def cup(name, profile, mat, scale=1, y=0):
    count = 96
    vertices = []
    for radius,z in profile:
        for i in range(count):
            angle = math.tau*i/count
            vertices.append((radius*scale*math.cos(angle), y+radius*.46*math.sin(angle), z))
    faces = []
    for row in range(len(profile)-1):
        for i in range(count):
            j = (i+1)%count
            faces.append((row*count+i,row*count+j,(row+1)*count+j,(row+1)*count+i))
    faces.append(tuple((len(profile)-1)*count+i for i in range(count)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    apply(ob, mat)
    for face in mesh.polygons: face.use_smooth=True
    return ob

def bezier(points, count=48):
    a,b,c,d = points
    result = []
    for i in range(count+1):
        t=i/count; s=1-t
        result.append(tuple(s**3*a[k]+3*s*s*t*b[k]+3*s*t*t*c[k]+t**3*d[k] for k in range(3)))
    return result

def trophy(m):
    for sign in (-1,1):
        arc = bezier([(sign*.58,.045,.73),(sign*1.18,.045,1.02),(sign*1.09,.045,-.05),(sign*.48,.045,-.14)])
        tube('Sweeping handle navy edge', arc, m['Navy'], .092)
        tube('Golden curved handle', [(x,y-.095,z) for x,y,z in arc], m['GoldLight'], .050)
    profile = [(.18,-.30),(.30,-.24),(.43,-.13),(.55,.06),(.65,.34),(.70,.64),(.71,.90)]
    cup('Curved navy cup silhouette', [(r,z-.015) for r,z in profile], m['Navy'], 1.075, .04)
    cup('Curved golden bowl', profile, m['Gold'], 1, -.065)
    tube('Cup rim navy', [(-.76,-.065,.91),(.76,-.065,.91)], m['Navy'], .075)
    tube('Cup rim golden lip', [(-.69,-.13,.92),(.69,-.13,.92)], m['GoldLight'], .044)
    poly('Stem outline',[(-.16,-.23),(.16,-.23),(.16,-.67),(.40,-.81),(-.40,-.81),(-.16,-.67)],m['Navy'],.045,.21,.045)
    poly('Golden stem',[(-.09,-.23),(.09,-.23),(.09,-.65),(.31,-.79),(-.31,-.79),(-.09,-.65)],m['Gold'],-.09,.15,.035)
    poly('Base outline',[(-.50,-.76),(.50,-.76),(.50,-1.02),(-.50,-1.02)],m['Navy'],.02,.28,.065)
    poly('Golden foot',[(-.41,-.79),(.41,-.79),(.41,-.93),(-.41,-.93)],m['GoldLight'],-.17,.13,.040)
    disc('Medallion recess', .205, .03, -.37, .34, m['Amber'], .012)
    disc('Medallion highlight', .17, .03, -.397, .35, m['GoldLight'], .014)
    glint = bezier([(-.49,-.325,.69),(-.50,-.35,.48),(-.43,-.31,.21),(-.31,-.27,.08)], 32)
    tube('Left bowl curved shine', glint, m['Star'], .035)

def key(m):
    root=bpy.data.objects.new('Tilted cyan key',None)
    bpy.context.collection.objects.link(root)
    shaft=[(-.12,.18),(.14,.18),(.14,-.97),(-.12,-.97),(-.12,-.79),(-.34,-.79),(-.34,-.57),(-.12,-.57),(-.12,-.35),(-.34,-.35),(-.34,-.14),(-.12,-.14)]
    for name,mat,scale,y,offset in [('Navy edge','Navy',1,0,(0,0)),('Blue lower bevel','Blue',.84,-.13,(0,0)),('Cyan face','Cyan',.68,-.22,(-.015,.026))]:
        cx=sum(x for x,z in shaft)/len(shaft); cz=sum(z for x,z in shaft)/len(shaft)
        pts=[(cx+(x-cx)*scale+offset[0],cz+(z-cz)*scale+offset[1]) for x,z in shaft]
        poly(name,pts,m[mat],y,.13,.027).parent=root
    outer=[(-.05,1.18),(.05,1.18),(.60,.60),(.60,.50),(.05,-.08),(-.05,-.08),(-.60,.50),(-.60,.60)]
    inner=[(-.02,.89),(.02,.89),(.31,.57),(.31,.53),(.02,.21),(-.02,.21),(-.31,.53),(-.31,.57)]
    def ring(name,outer,inner,y,mat):
        n=len(outer)
        vertices=[(x,y-.055,z) for x,z in outer+inner]+[(x,y+.055,z) for x,z in outer+inner]
        faces=[]
        for i in range(n):
            j=(i+1)%n
            faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
        ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);apply(ob,m[mat]);bevel(ob,.025);ob.parent=root
    ring('Bow navy border',outer,inner,-.13,'Navy')
    ring('Bow blue bevel',[(x*.94,(z-.55)*.94+.55) for x,z in outer],[(x*1.06,(z-.55)*1.06+.55) for x,z in inner],-.235,'Blue')
    ring('Bow cyan face',[(x*.83-.023,(z-.55)*.83+.585) for x,z in outer],[(x*1.2-.023,(z-.55)*1.2+.585) for x,z in inner],-.315,'Cyan')
    tube('Key white glint',[(-.42,-.397,.65),(-.24,-.397,.86),(-.09,-.397,1.00)],m['White'],.023).parent=root
    root.rotation_euler.y=.30

for name,build in [('coin-r3',coin),('trophy-r3',trophy),('key-r3',key),('shop-bag-r3',scope['bag']),('racer-r3',scope['racer'])]:
    mats=setup()
    build(mats)
    bpy.context.scene.render.filepath=str(folder/(name+'.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/(name+'.blend')))
    bpy.ops.render.render(write_still=True)
    print('ICON_COMPLETE '+name,flush=True)
