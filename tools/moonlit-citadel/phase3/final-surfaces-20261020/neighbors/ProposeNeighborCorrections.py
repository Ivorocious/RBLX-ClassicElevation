"""Stage guarded inert-material operations for a whole-scene candidate rescan."""
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-records.json').read_text(encoding='utf8'))['editable']['records']
findings=json.loads((OWN/'inter-unit-visibility56.json').read_text(encoding='utf8'))['pairs']
ops={}
OUT=OWN/'proposal01';OUT.mkdir(exist_ok=True)


def prop(row,key):
    value=row['props'].get(key,row['props'].get(key.lower()))
    return value.get('value') if isinstance(value,dict) else value


def edit(path,size=(0,0,0),shift=(0,0,0),reason=''):
    record=native[path]
    assert record['class']=='MeshPart' and prop(record,'Anchored')is True
    assert all(prop(record,p)is False for p in('CanCollide','CanQuery','CanTouch')),path
    assert record['attrs'].get('MCWalkable')is not True and record['attrs'].get('MoonlitHazard')is not True,path
    op=ops.setdefault(path,{'path':path,'meshId':prop(record,'MeshId'),'asset':record['attrs'].get('SourceAsset'),'material':record['attrs'].get('SourceMaterial'),
      'beforeSize':prop(record,'Size'),'beforeCFrame':prop(record,'CFrame'),'afterSize':prop(record,'Size')[:],'afterCFrame':prop(record,'CFrame')[:],
      'flags':{'Anchored':True,'CanCollide':False,'CanQuery':False,'CanTouch':False},'reasons':[]})
    op['afterSize']=(np.array(op['afterSize'])+size).tolist()
    op['afterCFrame'][:3]=(np.array(op['afterCFrame'][:3])+shift).tolist()
    op['reasons'].append(reason)
    assert min(op['afterSize'])>.04,(path,op['afterSize'])


def world(unit,material):
    candidates=[p for p,r in native.items()if '/'+unit+'/'in p and p.startswith('Decoration/Phase3World/')and r['class']=='MeshPart'and r['attrs'].get('SourceMaterial')==material]
    assert len(candidates)==1,(unit,material,candidates)
    return candidates[0]


edit(world('CrownBaseUnifiedShell','StoneLight'),size=(.16,0,0),reason='Give both crown/keep side planes0.08stud relief; retain earlier frontZ separation.')
for i in range(1,4):edit(world(f'Gallery{i}EnclosedBody','StoneDark'),shift=(0,0,-.08),reason='Recess gallery-body dark strip from neighboring stone face.')
edit(world('CrownEmblemLowerPier','Stone'),size=(0,0,-.16),reason='Recess both narrow pier faces from broad apron andFoot3.')
for unit in('CrownSouthScreenFoot1','CrownWestScreenFoot1'):
    edit(world(unit,'StoneLight'),size=(-.16,-.16,-.16),reason='Recess apron side,end,bottom faces from joined screen and engaged pilasters.')
edit(world('CrownWestScreenFoot1','StoneDark'),size=(-.16,0,0),reason='Separate rear end from northern engaged post trim.')
edit(world('WestArrivalNorthJambNiche','StoneLight'),shift=(0,0,.08),reason='Lift niche material off shared wing plane.')
edit(world('WestHighJambNiche','StoneLight'),shift=(.08,0,0),reason='Lift niche material off neighboring slate plane.')
for i in(1,2):edit(world(f'Gallery{i}PlanterShelf-1','StoneLight'),size=(0,.16,0),reason='Give planting plinth top relief above next foundation while preserving basin embedding.')
edit(world('NorthWestRaisedCourt','Stone'),shift=(0,0,-.08),reason='Recess large same-material court wall from neighboring stepped hall; avoid moving toward existing light trim.')
edit(world('EastUpperDeepWing','Stone'),shift=(.08,0,0),reason='Separate overlapping east deep-wing side faces.')
for p,r in native.items():
    if p.startswith('Decoration/Phase3World/')and '/WestSteppedCurtain2/'in p and r['class']=='MeshPart':
        edit(p,shift=(.08,0,0),reason='Move complete inert middle rampart material group to provide relief at both neighboring wings.')

# Each guide has only one confirmed risky outward normal; red hazard geometry remains exact.
guide_directions={}
for pair in findings:
    if pair['state']!='supported-route-visible':continue
    for path in pair['paths']:
        if not path.endswith('/MC_GuideIron__Iron'):continue
        witnesses=[w for w in pair['visibleWitnesses']if w['witness']['gap']<.025]
        if not witnesses:continue
        normal=np.array(witnesses[0]['witness']['normalA']);normal/=np.linalg.norm(normal)
        if path in guide_directions:assert np.dot(normal,guide_directions[path])>.999,path
        guide_directions[path]=normal
for p,n in guide_directions.items():edit(p,shift=n*.08,reason='Separate inert guide from unchanged visible red hazard along its measured outward plane normal.')

for p,r in native.items():
    if '/MovingCars/'in p and p.endswith('/MC_CarIronBrass__Brass'):
        edit(p,size=(-.16,-.16,-.16),reason='Separate all moving-car brass boundary faces from iron; earlierZ-only relief missed horizontal faces.')
    if '/UpperBrace/'in p and '/BraceSkin/'in p and p.endswith('/MC_ExpertCorbel__StoneDark'):
        edit(p,size=(-.16,0,-.16),reason='Recess brace trim side/end faces from the separate floor skirt.')
    if '/GalleryExpertShortcut_LiftNeedle1_Red40/'in p and p.endswith('/MC_GuideIron__Brass'):
        edit(p,shift=(0,-.08,0),reason='Recess two gold guide bases below floor overlaps while retaining prior correction.')

floor_groups={
 'Obstacles/ArchCatchReturn/Ramp_2':.08,
 'Obstacles/LiftCatchReturn/Ramp_2':.08,
 'Obstacles/LiftCatchReturn/Ramp_3':-.08,
 'Obstacles/GalleryExpertShortcut/LiftNeedle1':.08,
 'Obstacles/GalleryExpertApproach/BetweenBandRail2':.08,
 'Obstacles/GalleryExpertApproach/BetweenBandRail3':.08,
 'Obstacles/GalleryExpertApproach/EntryRail':.08,
}
for group,dy in floor_groups.items():
    selected=[p for p,r in native.items()if p.startswith(group+'/StoneSkin/')and r['class']=='MeshPart']
    assert len(selected)==2,(group,selected)
    for p in selected:edit(p,shift=(0,dy,0),reason='Separate intersecting floor-skin layers by0.08stud; actual contact and route geometry stay exact.')

result={'candidate':'neighbors-proposal01','scope':'Uninstalled inert material-piece operations from current56; internal-agent operations remain separate until supplied.',
 'count':len(ops),'operations':list(ops.values()),'guideTargets':len(guide_directions),'floorGroups':floor_groups,
 'limits':'Candidate requires fresh global inter-unit scan, internal-unit closure and lead native route/support checks; size/pose only; no mesh,flag,arrow,Contact,RedContact,floor terrain,veil changes.'}
(OUT/'operations.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps({'count':len(ops),'guideTargets':len(guide_directions),'floorGroups':len(floor_groups)}))
