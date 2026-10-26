"""Inspect actual frozen supports for the bounded art correction."""
import json
from pathlib import Path

import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
BASE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/placements'
import importlib.util
spec=importlib.util.spec_from_file_location('seat_helpers',BASE/'ResolveDetailSeats.py')
h=importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
bpy.ops.wm.open_mainfile(filepath=str(BASE/'render02/MC_DETAIL53_CANDIDATE.blend'))
objects=list(bpy.data.collections['Final_233_World_Units'].all_objects)
units={}
for obj in objects:
    units.setdefault(str(obj['Source50Unit']),[]).append(obj)
terrain=[obj for obj in objects if str(obj['Source50Unit']).startswith('MC_EC_')]
surfaces={'all_world':h.build_surface(objects),'terrain':h.build_surface(terrain)}
probes=[]
for x in (-194,-178,-170,-154,-144,-130,-118,-106,-94):
    for z in (128,138,150,160):
        origin=Vector((x,600,z))
        probes.append({'area':'gate','x':x,'z':z,'terrain':h.ray(surfaces['terrain'],origin,Vector((0,-1,0)),1200),
                       'world':h.ray(surfaces['all_world'],origin,Vector((0,-1,0)),1200)})
for x in (140,154,164,176,184,194,206,218):
    for z in (-160,-148,-130,-112,-96,-72,-44):
        origin=Vector((x,600,z))
        probes.append({'area':'machine','x':x,'z':z,'terrain':h.ray(surfaces['terrain'],origin,Vector((0,-1,0)),1200),
                       'world':h.ray(surfaces['all_world'],origin,Vector((0,-1,0)),1200)})
rows=[]
for name in ('MonumentalForwardGate','WestArchHighWing','WestArchMiddleWing','WestArrivalWing','JoinedDoubleLiftHall','EastUpperDeepWing','UpperMachineEaveCornice'):
    for obj in units[name]:
        points=[h.INVERSE@(obj.matrix_world@vertex.co)for vertex in obj.data.vertices]
        low=[min(point[a]for point in points)for a in range(3)]
        high=[max(point[a]for point in points)for a in range(3)]
        rows.append({'unit':name,'object':obj.name,'low':low,'high':high})
cornice=h.build_surface(units['UpperMachineEaveCornice'])
cornice_probes=[]
for x in (189.5,191,192,193,195):
    for z in (-150,-142,-135,-58,-50,-42):
        cornice_probes.append({'x':x,'z':z,'hit':h.ray(cornice,Vector((x,150,z)),Vector((0,-1,0)),100)})
result={'probes':probes,'objectBounds':rows,'machineCorniceProbes':cornice_probes}
(HERE/'support-probes54.json').write_text(json.dumps(result,indent=2)+'\n')
print('SUPPORT_PROBES54 '+json.dumps({'gateTerrain':[[r['x'],r['z'],None if not r['terrain'] else round(r['terrain']['point'][1],2)]for r in probes if r['area']=='gate'],
                                    'machineCornice':[[r['x'],r['z'],None if not r['hit'] else round(r['hit']['point'][1],2)]for r in cornice_probes]}),flush=True)
