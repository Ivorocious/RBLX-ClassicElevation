"""Classify exact overlap witnesses using only supported course-height eyes."""
import json
from pathlib import Path

import bpy
from mathutils import Vector

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if (p/'default.project.json').exists())
meta=json.loads((OWN/'surface-objects54-bound.json').read_text(encoding='utf8'))
raw=json.loads((OWN/'coplanar-triangle-candidates.json').read_text(encoding='utf8'))
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json').read_text(encoding='utf8'))['editable']['records']
objects=meta['objects']
bpy.ops.wm.open_mainfile(filepath=str(ROOT/meta['sourceBlend']))
graph=bpy.context.evaluated_depsgraph_get()
scene=bpy.context.scene
eyes=[]


def vec(point):return Vector((point[0],-point[2],point[1]))


for path,record in native.items():
    if record['class']!='Part' or record['attrs'].get('MCWalkable')is not True:continue
    props=record['props']
    cf=props['CFrame']['value'];size=props.get('Size',props.get('size'))['value']
    p=Vector(cf[:3])-Vector((4000,300,2600))
    right=Vector((cf[3],cf[6],cf[9]));up=Vector((cf[4],cf[7],cf[10]));back=Vector((cf[5],cf[8],cf[11]))
    if up.y<.98:continue
    for x,z in ((0,0),(-1,-1),(-1,1),(1,-1),(1,1)):
        eye=p+up*(size[1]/2+5.5)+right*x*max(0,size[0]/2-2)+back*z*max(0,size[2]/2-2)
        eyes.append({'path':path,'point':eye,'blender':vec(eye)})
eyes.extend({'path':'AcceptedCrownStanding','point':Vector(point),'blender':vec(point)}for point in ((6,155.5,-18),(-8,155.5,-30)))
visible=[];rays=0
for pair in raw['pairs']:
    a,b=objects[pair['a']],objects[pair['b']]
    names={a['name'],b['name']}
    found=[]
    for witness in pair['witnesses']:
        point,normal=Vector(witness['point']),Vector(witness['normal'])
        targets=sorted((eye for eye in eyes if normal.dot(eye['point']-point)>.05 and .5<(eye['point']-point).length<180),
                       key=lambda eye:(eye['point']-point).length)[:24]
        for eye in targets:
            endpoint=vec(point);delta=endpoint-eye['blender'];rays+=1
            hit,location,hitnormal,index,blocker,matrix=scene.ray_cast(graph,eye['blender'],delta.normalized(),distance=delta.length+.03)
            if hit and blocker.name in names and abs((location-eye['blender']).length-delta.length)<.035:
                found.append({'eye':list(eye['point']),'support':eye['path'],'point':list(point),
                              'normal':list(normal),'distance':delta.length,'firstVisiblePart':blocker.name,'faceWitness':witness})
                break
        if len(found)>=3:break
    if found:
        colorA,colorB=native[a['nativePath']]['props']['Color']['value'],native[b['nativePath']]['props']['Color']['value']
        materialA,materialB=native[a['nativePath']]['props']['Material']['value'],native[b['nativePath']]['props']['Material']['value']
        contrast=sum((x-y)**2 for x,y in zip(colorA,colorB))**.5
        row={**pair,'visibleWitnesses':found,'colorDifference':contrast,
             'materials':[materialA,materialB],
             'differentNativeAppearance':contrast>.02 or materialA!=materialB,
             'samePart':pair['a']==pair['b']}
        visible.append(row)
visible.sort(key=lambda row:(row['differentNativeAppearance'],not row['samePart'],row['area']),reverse=True)
report={'scope':'Actual triangle overlap witnesses with first-visible-surface rays from supported course eyes; no native moving-render proof',
        'objects':len(objects),'triangles':meta['triangles'],'candidatePairs':len(raw['pairs']),'visiblePairs':len(visible),
        'routeEyes':len(eyes),'rays':rays,'differentAppearancePairs':sum(row['differentNativeAppearance']for row in visible),
        'pairs':visible,'studioTouched':False,'liveBlenderTouched':False}
(OWN/'visible-overlap-findings.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('VISIBLE_OVERLAP '+json.dumps({k:v for k,v in report.items()if k!='pairs'}),flush=True)
print('TOP '+json.dumps([{'paths':row['paths'],'area':row['area'],'gap':row['minimumGap'],'differentAppearance':row['differentNativeAppearance'],
                         'point':row['visibleWitnesses'][0]['point'],'eye':row['visibleWitnesses'][0]['eye']}for row in visible[:20]]),flush=True)
