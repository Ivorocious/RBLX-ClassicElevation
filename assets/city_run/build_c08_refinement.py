"""Add city depth and quieter expert-route supports without changing collision."""
import json
import sys
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT))
source = (OUT/'build_city.py').read_text().split('objects=[];meshinfo={}')[0]
source = source.replace('owner("Route_"+s["section"]+f"_{i//5:03}",s["section"],s["p"])',
                        'owner("EditableSurface_"+s["name"],s["section"],s["p"])')
source = source.replace('    box(mat,(x,y-.6,z),(w,1.2,d))',
    '    if style=="sign":box("Cream",(x,y-.14,z),(w,.28,d))\n    else:box(mat,(x,y-.6,z),(w,1.2,d))')
source = source.replace('box(accent,(x,y-2,z),(w,2.7,d*.7))', 'box(accent,(x,y-1.1,z),(w*.88,1.6,d*.5))')
source = source.replace('box("Yellow",(x,y-2,z+d*.36),(w*.45,.3,.1))',
                        'box("Yellow",(x,y-1.1,z+d*.26),(w*.4,.18,.1))')
source = source.replace('beam("Iron",(x,y-1,z),(targetx,y-1,targetz),.23)',
                        'beam("Iron",(x,y-.65,z),(targetx,y-.65,targetz),.12)')
source = source.replace('beam("Iron",(x,y-1,z),(targetx,y-4,targetz),.18)',
                        'beam("Iron",(x,y-.65,z),(targetx,y-2.8,targetz),.10)')
api = {'__file__':str(OUT/'build_city.py')}
exec(compile(source,str(OUT/'build_city.py'),'exec'),api)
for key in list(api['groups']):
    if key[0] in ('StationScaffoldFrame','StationScaffoldTies'):
        del api['groups'][key]
owner, box, beam = (api[k] for k in ('owner','box','beam'))
owner('StationScaffoldFrame','Station')
for z in (95,135,175):
    top=min(128.5,89+(z-57)*46/127)
    box('Brick',(201,(75+top)/2,z),(2.1,top-75,2.4))
    box('Cream',(201,top,z),(3.2,.7,3.4))
beam('Rail',(201,84.6,57),(201,130.6,184),.22,8)
owner('StationScaffoldTies','Station')
for s in api['layout'].SURFACES:
    if not s['name'].startswith('X03') or s['name']=='X03_00_00':
        continue
    x,y,z=s['p']
    beam('Rail',(x-1.8,y-.9,z),(201,y-.9,z),.19)
    beam('Rail',(x,y-.9,z),(201,y-3,z),.12)

infill = [
    (-50,-185,32,32,56),(-10,-165,30,32,68),(32,-139,34,32,52),
    (80,-168,40,34,61),(118,-133,35,31,58),(-46,-99,30,35,48),
    (20,-68,38,38,66),(82,-53,36,35,53),(-45,66,30,32,51),
    (32,49,38,34,60),(92,37,32,32,63),
]
for i,(x,z,w,d,h) in enumerate(infill):
    api['building'](f'CityInfill_{i:02}',x,z,w,d,h,['Brick','Plaster','Terracotta'][i%3],detail=True)
    # These facades face distant course views, beyond the builder's close-detail radius.
    owner(f'CityInfill_{i:02}','Scenery',(x,0,z))
    for y in range(7,h-4,11):
        for dx in range(-int(w/2)+5,int(w/2)-2,9):
            box('Cream',(x+dx,y,z+d/2+.15),(4.3,6,.3))
            box('Glass',(x+dx,y,z+d/2+.36),(3.5,5.2,.12))
            box('Cream',(x+dx,y,z+d/2+.47),(.17,5.2,.12))
    for y in range(11,h-2,11):box('Cream',(x,y,z+d/2+.1),(w,.4,.4))

for name,color in {'SkylineFar':(.36,.44,.48),'SkylineMid':(.49,.53,.52),'SkylineGlass':(.27,.35,.38)}.items():
    api['COLORS'][name]=color
    m=bpy.data.materials.new(name)
    m.diffuse_color=(*color,1)
    api['MATS'][name]=m

for row,(zbase,step,count) in enumerate([(-469,48,18),(-550,64,14)]):
    for i in range(count):
        x=-420+i*step+(18 if row else 0)
        z=zbase-(i%3)*7
        w=step-4+(i%2)*2
        h=(100+(i*17)%58) if row==0 else (145+(i*23)%44)
        name=f'CitySkyline_{row}_{i:02}'
        api['building'](name,x,z,w,35 if row else 39,h,
            'SkylineFar' if row else ['Terracotta','SkylineMid','Plaster','Brick'][i%4],detail=False)
        owner(name,'Scenery',(x,0,z))
        for y in range(9,h-5,13):
            for dx in range(-int(w/2)+5,int(w/2)-2,9):
                box('SkylineGlass',(x+dx,y,z+(17.7 if row else 19.7)),(3.1,5,.18))
        if row:
            for (comp,mat),chunks in list(api['groups'].items()):
                if comp==name and mat in ('Cream','Teal','Terracotta','Roof','Brick','Iron'):
                    del api['groups'][(comp,mat)]
                    api['groups'].setdefault((comp,'SkylineMid'),[]).extend(chunks)

for i,(x,z,h) in enumerate([(345,-245,114),(389,-230,138),(366,-154,103),(414,-142,127)]):
    name=f'CitySkylineNear_{i:02}'
    api['building'](name,x,z,31,33,h,['Plaster','Terracotta','Brick','SkylineMid'][i],detail=False)
    owner(name,'Scenery',(x,0,z))
    for y in range(9,h-4,12):
        for dx in (-9,0,9):
            box('Cream',(x+dx,y,z+16.7),(4.1,6,.3))
            box('Glass',(x+dx,y,z+16.95),(3.3,5.2,.15))

prefixes=('EditableSurface_X01','StationScaffoldFrame','StationScaffoldTies','CityInfill_','CitySkyline','Marker')
scene=api['scene']
scene.name='CityRun_C08_03_CityDepth'
objects,meshinfo=[],{}
for (comp,mat),chunks in api['groups'].items():
    if not comp.startswith(prefixes):continue
    for i,(vs,fs) in enumerate(chunks):
        name=f'{comp}__{mat}__{i:02}'
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(vs,[],fs)
        mesh.materials.append(api['MATS'][mat])
        mesh.update();mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles)<20000,name
        obj=bpy.data.objects.new(name,mesh)
        scene.collection.objects.link(obj);objects.append(obj)
        meshinfo[name]={'material':mat,'component':comp,'triangles':len(mesh.loop_triangles)}
for obj in scene.objects:obj.select_set(False)
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C08_refinement.fbx'),use_selection=True,object_types={'MESH'},
    axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False)
used={v['component'] for v in meshinfo.values()}
data={'revision':'C08_03','colors':api['COLORS'],'meshes':meshinfo,'components':{k:v for k,v in api['components'].items() if k in used}}
(OUT/'manifest_C08_refinement.json').write_text(json.dumps(data,indent=2))
def luau(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+luau(x) for k,x in v.items())+'}'
    if isinstance(v,(list,tuple)):return '{'+','.join(luau(x) for x in v)+'}'
    if isinstance(v,str):return json.dumps(v)
    return str(v).lower()
(OUT.parents[1]/'src/ServerStorage/CourseBuilders/CityRun/C08RefinementManifest.luau').write_text('--!strict\nreturn '+luau(data)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C08_refinement.blend'))
print(json.dumps({'meshes':len(objects),'triangles':sum(v['triangles'] for v in meshinfo.values())}))
