"""Bounded Source53 detail redistribution; frozen Source52 records remain untouched."""
import copy
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
source=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/placements/detail-placement-plan.json'
old=json.loads(source.read_text())
by_name={unit['name']:copy.deepcopy(unit)for unit in old['units']}
removed=['GateLeftNiche2','GateRightNiche2','GateLeftShrub','GateRightShrub','WestCliffShrubA','WestCliffShrubB','MachineRidgeShrub']
changes={}


def change(name,seed,scale,front=None):
    unit=by_name[name]
    changes[name]={'seed':seed,'scale':scale,'front':front or unit['front'],'kind':'wall','supportUnit':unit['support']['unit']}


for side,x,front in [('Left',-186,[1,0,0]),('Right',-102,[-1,0,0])]:
    change('Gate'+side+'Niche1',[x,-1,100],[2,2.8,1.35])
    change('Gate'+side+'Cornice',[x,39,106],[4.6,.65,1.35])
    change('Gate'+side+'Ivy',[x,4,93],[2.1,3,1.2])
for side,x in [('Left',-177),('Right',-111)]:
    change('Gate'+side+'HighRelief',[x,82,128],[1.4,7.2,1.3],[0,0,1])
for name,z,y,scale in (
    ('WestHighJambNiche',-59.5,6,[1.05,2.65,1.35]),
    ('WestMiddleNorthJambNiche',-59.5,-24,[1.05,2,1.35]),
    ('WestMiddleSouthJambNiche',25.5,-35,[1.05,3.75,1.35]),
    ('WestArrivalNorthJambNiche',21,-55,[1.05,1.3,1.35]),
    ('WestArrivalSouthJambNiche',105,-40,[.95,3.5,1.35]),
    ('WestHighCoping',-95,44.3,[9.75,.1,1.35]),
    ('WestMiddleCoping',-18,27,[12.5,.2,1.35]),
    ('WestArrivalCoping',63,8,[12.5,.45,1.35]),
    ('WestHighIvy',-59.5,-19,[1.6,2.8,1.2]),
    ('WestMiddleIvy',25.5,-52,[1.6,3.5,1.2]),
    ('WestArrivalIvy',105,-72,[1.5,3.3,1.2]),
):
    change(name,[-231.8,y,z],scale)
for name,z in [('WestHighDormer',-82),('WestMiddleDormer',2),('WestArrivalDormer',83)]:
    changes[name]={'seed':[-232.5,0,z],'scale':[1.8]*3,'front':[1,0,0],'kind':'horizontal','supportUnit':by_name[name]['support']['unit']}
change('MachineWallIvy',[196.2,89,-161],[2.4,1.6,1.2])
new=[]
for name,support,seed,front,scale in (
    ('GateLeftPlantedTerrace','MonumentalForwardGate',[-186,-2,96],[1,0,0],[1]*3),
    ('GateRightPlantedTerrace','MonumentalForwardGate',[-102,-2,96],[-1,0,0],[1]*3),
    ('WestHighPlantedTerrace','WestArchHighWing',[-231.8,33.5,-125],[1,0,0],[1]*3),
    ('WestMiddlePlantedTerrace','WestArchHighWing',[-231.8,35.5,-102],[1,0,0],[.9]*3),
    ('WestArrivalPlantedTerrace','WestArchHighWing',[-231.8,34.5,-81],[1,0,0],[.8]*3),
    ('MachinePlantedTerrace','EastUpperDeepWing',[196.2,99,-161],[-1,0,0],[1]*3),
):
    new.append({'name':name,'district':'DT_Gardens','asset':'MC_DG_WallGarden24','library':'DT01','materialRole':'PlantedWallGarden',
                'seed':seed,'scale':scale,'front':front,'kind':'gardenWall','supportUnit':support})
for name,z in [('MachineWestWinch',-157),('MachineEastWinch',-43)]:
    changes[name]={'seed':[193.4,115,z],'scale':[1]*3,'front':[-1,0,0],'kind':'hoistWall','supportUnit':'EastUpperDeepWing',
                   'asset':'MC_DG_WallHoist','materialRole':'WallMountedTimberHoist','pendingMeasuredAsset':True}
report={'baseSource':53,'oldSourcePlanSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'oldUnits':old['units'],'removedUnitNames':removed,'changedSeats':changes,'newSeats':new,
        'expectedNewUnitCount':77,'old52RecordsChanged':False,'measuredNewHoistPending':True}
(HERE/'correction54-seeds.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'oldUnits':78,'removed':len(removed),'changedExisting':len(changes),'newUnits':6,'finalDetails':77}))
