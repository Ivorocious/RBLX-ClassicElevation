"""Measure every corrective mount against immutable Source52 mesh faces."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
BASE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/placements'
spec=importlib.util.spec_from_file_location('seat_helpers',BASE/'ResolveDetailSeats.py')
h=importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
META=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/r01/final/combined-occupied-geometry.json'
data=json.loads((HERE/'correction54-seeds.json').read_text())
metadata=json.loads(META.read_text())
bpy.ops.wm.open_mainfile(filepath=str(BASE/'render02/MC_DETAIL53_CANDIDATE.blend'))
world=list(bpy.data.collections['Final_233_World_Units'].all_objects)
objects_by_unit={}
for obj in world:
    objects_by_unit.setdefault(str(obj['Source50Unit']),[]).append(obj)
surfaces={name:h.build_surface(objects)for name,objects in objects_by_unit.items()}
units=[]
failures=[]
changes=[]


def measure(unit,seed):
    support=seed['supportUnit']
    surface=surfaces[support]
    position,front,scale=Vector(seed['seed']),Vector(seed['front']),Vector(seed['scale'])
    asset=seed.get('asset',unit['asset'])
    meta=metadata['assets'][asset]
    low,high=Vector(meta['bounds']['low']),Vector(meta['bounds']['high'])
    points=[]
    if seed['kind']=='horizontal':
        frame=h.get_frame(position,front)
        heights=[]
        for x,z in ((0,0),(low.x*.45,low.z*.45),(low.x*.45,high.z*.45),(high.x*.45,low.z*.45),(high.x*.45,high.z*.45)):
            point=frame@Vector((x*scale.x,0,z*scale.z))
            hit=h.ray(surface,point+Vector((0,600,0)),Vector((0,-1,0)),1200)
            rooted=bool(hit and hit['normal'][1]>.1)
            points.append({'probe':list(point),'hit':hit,'rooted':rooted})
            if rooted:heights.append(hit['point'][1])
        if heights:position.y=min(heights)-.12-low.y*scale.y
        okay=len(heights)==5 and max(heights)-min(heights)<(high.y-low.y)*scale.y*.8
    else:
        if seed['kind']=='gardenWall':
            root_coords=[(x,y)for x in (-11.3,0,11.3)for y in (2.65,4.35,6.05)]
            root_coords += [(x,y)for x in (-8.65,0,8.65)for y in (.02,2.6,5.21)]
            reference=position+Vector((0,4.35*scale.y,0))
        elif seed['kind']=='hoistWall':
            root_coords=[(x,y)for x in (-3.85,0,3.85)for y in (-2.44,-1.8,1.8,2.44)]
            reference=position
        else:
            root_coords=[(x,y)for x in (low.x*.8,0,high.x*.8)for y in (low.y+.25,(low.y+high.y)*.5,high.y-.25)]
            reference=position+Vector((0,(low.y+high.y)*.5*scale.y,0))
        primary=h.ray(surface,reference+front*80,-front,180)
        if not primary or Vector(primary['normal']).dot(front)<.9:
            return None,{'name':unit['name'],'reason':'No outward actual wall face','primary':primary}
        offset=-.07 if asset.endswith('IvyCluster') else .08
        position += front*((Vector(primary['point'])-position).dot(front)+offset)
        frame=h.get_frame(position,front)
        for x,y in root_coords:
            point=frame@Vector((x*scale.x,y*scale.y,0))
            hit=h.ray(surface,point+front*3,-front,8)
            rooted=bool(hit and abs((Vector(hit['point'])-point).dot(front))<.5 and Vector(hit['normal']).dot(front)>.9)
            points.append({'probe':list(point),'hit':hit,'rooted':rooted})
        okay=all(point['rooted']for point in points)
    frame=h.get_frame(position,front)
    result=copy.deepcopy(unit)
    result.update({'asset':asset,'localCF':h.row(frame),'scale':list(scale),'front':list(front),
                   'materialRole':seed.get('materialRole',unit.get('materialRole','AdditiveDetail')),
                   'support':{'unit':support,'kind':seed['kind'],'front':list(front),'samples':points,'verified':okay}})
    return result,None if okay else {'name':unit['name'],'reason':'Incomplete actual mount/root','samples':points}


for old in data['oldUnits']:
    if old['name']in data['removedUnitNames']:continue
    if old['name']in data['changedSeats']:
        result,failure=measure(old,data['changedSeats'][old['name']])
        if result:
            units.append(result)
            changes.append({'name':old['name'],'before':old,'after':result})
        if failure:failures.append(failure)
    else:units.append(old)
for seed in data['newSeats']:
    result,failure=measure(seed,seed)
    if result:units.append(result)
    if failure:failures.append(failure)
counts={'units':len(units),'meshParts':sum(metadata['assets'][u['asset']]['meshParts']for u in units),
        'triangles':sum(metadata['assets'][u['asset']]['triangles']for u in units)}
report={'baseSource':53,'units':units,'counts':counts,'combined':{'units':243+counts['units'],'meshParts':639+counts['meshParts'],'triangles':198722+counts['triangles']},
        'architectureOwnUnits':176+counts['units'],'removedUnitNames':data['removedUnitNames'],'changedUnits':changes,'addedUnitNames':[u['name']for u in data['newSeats']],
        'supportVerified':not failures,'failures':failures,'metadataPath':str(META.relative_to(ROOT)),
        'metadataSHA256':h.sha(META),'baseBlendSHA256':h.sha(BASE/'render02/MC_DETAIL53_CANDIDATE.blend'),
        'old52RecordsChanged':False,'replaced53ArchivedSource':str(BASE/'detail-placement-plan.json'),
        'nativeVerified':False,'ownerAccepted':False}
(HERE/'correction54-placement-plan.json').write_text(json.dumps(report,indent=2)+'\n')
(HERE/'combined-occupied-geometry.json').write_text(json.dumps(metadata,indent=2)+'\n')
print('CORRECTION54_MEASURED '+json.dumps({'counts':counts,'combined':report['combined'],'failed':len(failures),
                                        'failures':[{'name':f['name'],'reason':f['reason']}for f in failures]}),flush=True)
