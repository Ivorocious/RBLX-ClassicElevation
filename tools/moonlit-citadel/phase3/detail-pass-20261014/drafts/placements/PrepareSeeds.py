"""Bounded additive seats for the existing Source52 fortress."""
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
seeds=[]


def wall(name,asset,support,point,front,scale=1,district=None):
    seeds.append(dict(name=name,asset='MC_DT_'+asset,supportUnit=support,seed=point,front=front,
                      scale=[scale]*3 if isinstance(scale,(float,int)) else scale,
                      district=district or 'DT_'+support,kind='wall'))


def seat(name,asset,support,x,z,front=[0,0,1],scale=1,district='DT_Roofs'):
    seeds.append(dict(name=name,asset='MC_DT_'+asset,supportUnit=support,seed=[x,0,z],front=front,
                      scale=[scale]*3 if isinstance(scale,(float,int)) else scale,district=district,kind='horizontal'))


for side,x,front in [('Left',-186,[1,0,0]),('Right',-102,[-1,0,0])]:
    for index,y,z in [(1,3,116),(2,25,98)]:
        wall('Gate'+side+'Niche'+str(index),'FacadeNiche','MonumentalForwardGate',[x,y,z],front,.92,'DT_Gate')
    wall('Gate'+side+'Cornice','QuoinCornice','MonumentalForwardGate',[x,32,106],front,[1.5,1.3,1],'DT_Gate')
    wall('Gate'+side+'Heraldry','HeraldicBanner','MonumentalForwardGate',[x,11,88],front,.85,'DT_Gate')
    wall('Gate'+side+'Ivy','IvyCluster','MonumentalForwardGate',[x,-12,108],front,[1.15,2,1],'DT_Gate')
for name,support,z,y in [
    ('WestHighJamb','WestArchHighWing',-62,14),
    ('WestMiddleNorthJamb','WestArchMiddleWing',-60,-2),
    ('WestMiddleSouthJamb','WestArchMiddleWing',24,-9),
    ('WestArrivalNorthJamb','WestArrivalWing',21,-13),
    ('WestArrivalSouthJamb','WestArrivalWing',105,-10),
    ('WestCurtainHigh','WestSteppedCurtain1',-124,-9),
]:
    wall(name+'Niche','FacadeNiche',support,[-231.8,y,z],[1,0,0],.70,'DT_West')
for name,support,z,y in [
    ('WestHighCoping','WestArchHighWing',-61,29),
    ('WestMiddleCoping','WestArchMiddleWing',23,13),
    ('WestArrivalCoping','WestArrivalWing',104,-1),
    ('WestCurtainRelief','WestSteppedCurtain2',-48,-12),
]:
    wall(name,'QuoinCornice',support,[-231.8,y,z],[1,0,0],[1.0,1.2,.85],'DT_West')
for name,support,z,y in [('WestHighBanner','WestArchHighWing',-145,-3),('WestMiddleBanner','WestArchMiddleWing',24,-31)]:
    wall(name,'HeraldicBanner',support,[-231.8,y,z],[1,0,0],.85,'DT_West')
for name,support,z,y in [('WestHighIvy','WestArchHighWing',-61,-19),('WestMiddleIvy','WestArchMiddleWing',24,-36),('WestArrivalIvy','WestArrivalWing',21,-44)]:
    wall(name,'IvyCluster',support,[-231.8,y,z],[1,0,0],[.9,1.8,.9],'DT_West')
for name,support,x,y in [('GalleryOneNorth','Gallery1EnclosedBody',-59,53),('GalleryTwoSouth','Gallery2EnclosedBody',41,57),('GalleryThreeNorth','Gallery3EnclosedBody',49,61),('GalleryThreeSouth','Gallery3EnclosedBody',95,61)]:
    wall(name+'Niche','FacadeNiche',support,[x,y,59.0],[0,0,-1],.54,'DT_Gallery')
for name,support,x,y in [('GalleryOneCornice','Gallery1EnclosedBody',-59,65),('GalleryThreeCornice','Gallery3EnclosedBody',95,72)]:
    wall(name,'QuoinCornice',support,[x,y,59.0],[0,0,-1],[.75,.65,.8],'DT_Gallery')
for index,x,y in [(1,-13,51),(2,-5,66)]:
    wall('GalleryHeraldry'+str(index),'HeraldicBanner','Gallery'+str(index)+'EnclosedBody',[x,y,59.0],[0,0,-1],.70,'DT_Gallery')
for index,x,y in [(1,-59,51),(2,-5,55),(3,49,59)]:
    wall('GalleryIvy'+str(index),'IvyCluster','Gallery'+str(index)+'EnclosedBody',[x,y,59.0],[0,0,-1],[.62,.85,.75],'DT_Gallery')
for index,z in [(1,-158),(2,-42)]:
    wall('MachineJambNiche'+str(index),'FacadeNiche','EastUpperDeepWing',[206.2,84,z],[-1,0,0],.9,'DT_Lifts')
    wall('MachineJambCornice'+str(index),'QuoinCornice','EastUpperDeepWing',[206.2,99,z],[-1,0,0],[1.15,.8,1],'DT_Lifts')
    wall('MachineHeraldry'+str(index),'HeraldicBanner','EastUpperDeepWing',[206.2,63,z],[-1,0,0],.9,'DT_Lifts')
wall('MachineWallIvy','IvyCluster','EastUpperDeepWing',[206.2,31,-158],[-1,0,0],[1.1,2,.9],'DT_Lifts')
for side,x in [('Left',-35),('Right',19)]:
    wall('Keep'+side+'Niche','FacadeNiche','GrandKeepUnifiedShell',[x,27,-11],[0,0,1],.9,'DT_GrandKeep')
    wall('Keep'+side+'Cornice','QuoinCornice','GrandKeepUnifiedShell',[x,83,-11],[0,0,1],[1.3,1.2,1],'DT_GrandKeep')
for name,x,y in [('KeepLowerLeftIvy',-43,-14),('KeepRightIvy',26,8)]:
    wall(name,'IvyCluster','GrandKeepUnifiedShell',[x,y,-11],[0,0,1],[.85,2,.85],'DT_GrandKeep')
wall('CrownWestLowIvy','IvyCluster','CrownRaisedFloorCarrier',[-28,137,-39],[-1,0,0],[.5,.55,.6],'DT_Crown')
for name,support,x,z,front,s in [
    ('WestHighDormer','WestArchHighWing',-232,-82,[1,0,0],1.0),
    ('WestMiddleDormer','WestArchMiddleWing',-232,2,[1,0,0],1.0),
    ('WestArrivalDormer','WestArrivalWing',-232,83,[1,0,0],1.0),
    ('GalleryOneDormer','Gallery1SeatedRoof',-49,63,[0,0,-1],.88),
    ('GalleryThreeDormer','Gallery3SeatedRoof',85,63,[0,0,-1],.88),
    ('UpperMachineDormer','EastUpperDeepWing',212,-75,[-1,0,0],1.0),
    ('RearMachineDormer','RearMachineSteppedHall',134,-197,[0,0,1],1.0),
    ('KeepNorthWestDormer','KeepNorthWestDeepWing',-48,-87,[0,0,1],.9),
]:
    seat(name,'SlateDormer',support,x,z,front,s)
for name,support,x,z,s in [
    ('WestHighChimney','WestArchHighWing',-285,-115,.82),
    ('WestMiddleChimney','WestArchMiddleWing',-285,-31,.78),
    ('GalleryOneChimney','Gallery1SeatedRoof',-23,76,.72),
    ('GalleryTwoChimney','Gallery2SeatedRoof',31,76,.72),
    ('MachineChimney','EastUpperDeepWing',267,-115,.78),
    ('KeepNorthWestChimney','KeepNorthWestDeepWing',-70,-125,.85),
]:
    seat(name,'ChimneyVent',support,x,z,scale=s)
for name,support,x,z,s in [
    ('KeepLeftShrub','MC_EC_InnerRavine',-39,-5,.9),
    ('KeepRightShrub','MC_EC_InnerRavine',25,-5,.9),
    ('WestCliffShrubA','MC_EC_WestWoodedCliff',-310,-92,.7),
    ('WestCliffShrubB','MC_EC_WestWoodedCliff',-309,12,.7),
    ('GateLeftShrub','MC_EC_InnerRavine',-193,130,.9),
    ('GateRightShrub','MC_EC_InnerRavine',-95,130,.9),
    ('GalleryOneShrub','Gallery1LeftCarvedBasin',-16.2,58.2,.29),
    ('GalleryTwoShrub','Gallery2LeftCarvedBasin',37.8,58.2,.29),
    ('GalleryThreeShrub','Gallery3LeftCarvedBasin',91.8,58.2,.29),
    ('MachineRidgeShrub','MC_EC_InnerRavine',230,-43,.8),
]:
    seat(name,'HerbShrub',support,x,z,scale=s,district='DT_LowerGreenery')
for name,x,z in [('MachineWestWinch',14,-135),('MachineEastWinch',210,-95)]:
    seat(name,'YardWinch','JoinedDoubleLiftHall',x,z,scale=.82,district='DT_Lifts')
wall('GateLeftHighRelief','QuoinCornice','MonumentalForwardGate',[-196,65,128],[0,0,1],[1.1,1.3,1],'DT_Gate')
wall('GateRightHighRelief','QuoinCornice','MonumentalForwardGate',[-92,65,128],[0,0,1],[1.1,1.3,1],'DT_Gate')
assert len(seeds)==78,len(seeds)
manifest=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01/occupied-geometry.json'
meta=json.loads(manifest.read_text())['assets']
costs=Counter(s['asset']for s in seeds)
totals={'units':len(seeds),'meshParts':sum(meta[k]['meshParts']*v for k,v in costs.items()),'triangles':sum(meta[k]['triangles']*v for k,v in costs.items())}
report={'baseSource':52,'seeds':seeds,'totals':totals,'combined':{'units':243+totals['units'],'meshParts':639+totals['meshParts'],'triangles':198722+totals['triangles']},'assetCounts':costs,'assetMetadataSHA256':hashlib.sha256(manifest.read_bytes()).hexdigest(),'measuredSupportPending':True,'geometryChanged':False}
(HERE/'seat-seeds.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'units':len(seeds),'totals':totals,'combined':report['combined']}))
