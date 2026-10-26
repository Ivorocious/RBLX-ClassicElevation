"""Test small physical decorative part corrections against the measured overlap witnesses."""
import hashlib
import json
from pathlib import Path

import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if (p/'default.project.json').exists())
meta=json.loads((OWN/'surface-objects54-bound.json').read_text(encoding='utf8'))
findings=json.loads((OWN/'visible-overlap-findings.json').read_text(encoding='utf8'))
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json').read_text(encoding='utf8'))['editable']['records']
arrays=np.load(OWN/'surface-triangles54.npz')
triangles,owners=arrays['triangles'],arrays['owners']
objects=meta['objects']
ORIGIN=np.array((4000,300,2600))
adjustments={}


def prop(record,key):
    result=record['props'].get(key,record['props'].get(key.lower()))
    return result.get('value')if isinstance(result,dict)else result


for row in objects:
    path=row['nativePath'];record=native[path]
    size=np.array(prop(record,'Size'));delta=None;translation=None;family=None
    if path.endswith('/MC_FloorStone__Floor'):
        delta=np.array((-.08,0,-.08));family='floor-body-lateral-inset'
    elif path.endswith('/MC_WindowFrame__Stone'):
        delta=np.array((-.12,-.12,0));family='window-substrate-jamb-cap-inset'
    elif '/WestArchMiddleWing/'in path:
        translation=np.array((-.08,0,0));family='west-middle-wing-seating'
    elif path.endswith('/MC_ER_LanternBracket__Iron') and 'WheelSupport'in path:
        translation=np.array((0,0,.06));family='wheel-bracket-iron-face-relief'
    if family:
        assert prop(record,'CanCollide')is False and prop(record,'CanTouch')is False,(path,'must remain visual only')
        item={'family':family,'nativePath':path,'nativeCFrameBefore':prop(record,'CFrame'),'nativeSizeBefore':size.tolist(),
              'canCollideBefore':prop(record,'CanCollide'),'canTouchBefore':prop(record,'CanTouch'),
              'canQueryBefore':prop(record,'CanQuery'),'candidateOnly':True}
        if delta is not None:
            assert np.all(size+delta>.1)
            item['nativeSizeAfter']=(size+delta).tolist();item['nativeCFrameUnchanged']=True
        else:
            item['courseLocalPositionDelta']=translation.tolist();item['nativeSizeUnchanged']=True
        adjustments[row['index']]=item


def transformed(index,triangle):
    item=adjustments.get(index)
    if not item:return triangle
    if 'courseLocalPositionDelta'in item:return triangle+np.array(item['courseLocalPositionDelta'])
    cf=np.array(item['nativeCFrameBefore']);rotation=cf[3:].reshape(3,3)
    local=(triangle+ORIGIN-cf[:3])@rotation
    local*=np.array(item['nativeSizeAfter'])/np.array(item['nativeSizeBefore'])
    return local@rotation.T+cf[:3]-ORIGIN


checks=[]
for pair in findings['pairs']:
    if not pair['differentNativeAppearance']:continue
    paths=pair['paths']
    floor=all('MC_FloorStone__'in path for path in paths)and paths[0].rsplit('/',1)[0]==paths[1].rsplit('/',1)[0]
    window=all('MC_WindowFrame__'in path for path in paths)
    west=all('MC_ER_SteppedWing__'in path for path in paths)and any('/WestArchMiddleWing/'in path for path in paths)
    bracket=all('MC_ER_LanternBracket__'in path for path in paths)
    if not(floor or window or west or bracket):continue
    gaps=[]
    for witness in pair['visibleWitnesses']:
        proof=witness['faceWitness'];i,j=proof['triangleIndices']
        a=transformed(int(owners[i]),triangles[i].copy());b=transformed(int(owners[j]),triangles[j].copy())
        normal=np.cross(a[1]-a[0],a[2]-a[0]);normal/=np.linalg.norm(normal)
        distances=(b-a[0])@normal
        gaps.append(0. if distances.min()<=0<=distances.max() else float(np.abs(distances).min()))
    checks.append({'paths':paths,'family':'floor'if floor else 'window'if window else 'west'if west else 'bracket',
                   'beforeMinimumGap':pair['minimumGap'],'afterMinimumVisibleWitnessGap':min(gaps),
                   'pass':min(gaps)>.025,'witnesses':len(gaps)})
families={family:{'pairs':sum(r['family']==family for r in checks),
                  'minimumGap':min((r['afterMinimumVisibleWitnessGap']for r in checks if r['family']==family),default=None),
                  'pass':all(r['pass']for r in checks if r['family']==family)}for family in ('floor','window','west','bracket')}
report={'scope':'Proposed physical decorative Size/position changes only; test existing actual visible face witnesses, not a native installation or complete new-intersection clearance',
        'pass':all(row['pass']for row in checks),'families':families,'operations':list(adjustments.values()),'pairChecks':checks,
        'productionChanged':False,'studioTouched':False,'nativeAcceptancePending':True,
        'rootMustCheck':['Apply to an isolated native candidate/recovery, inspect moving views, and check nearby support/appearance before permanent integration',
                         'Preserve all contact/collider/hazard geometry and movement attributes',
                         'Keep original approved libraries; bind durable Moonlit-only per-part corrections to exact source before applying',
                         'Recheck resized skins against neighbouring visual skins, especially GalleryExpertAfter1/BetweenBandRail2']}
(OWN/'physical-separation-proposal.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':report['pass'],'families':families,'operations':len(adjustments),
                  'counts':{family:sum(row['family']==family for row in adjustments.values())for family in sorted({row['family']for row in adjustments.values()})},
                  'failures':[row for row in checks if not row['pass']]}))
