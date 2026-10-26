"""Owner critique pass; derives from the frozen 27 layout without regenerating it."""
import json, math, importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parent
data=json.loads((ROOT/'layout27.json').read_text())
assets={}
for file in [ROOT.parent/'phase1/manifest.json',ROOT/'manifest13.json',ROOT/'manifest25.json',ROOT/'manifest26.json',ROOT/'manifest27.json',ROOT/'manifestHorizon27.json',ROOT/'manifest28.json',ROOT/'manifest28b.json']:
    assets.update({a['id']:a for a in json.loads(file.read_text())['assets']})
for a in assets.values():
    if 'centerBlender' not in a:
        a['centerBlender']=[(a['boundsBlender']['min'][k]+a['boundsBlender']['max'][k])/2 for k in range(3)]
spec=importlib.util.spec_from_file_location('routes28',ROOT/'routes28.py')
routes=importlib.util.module_from_spec(spec);spec.loader.exec_module(routes)
routes.apply(data,assets)
P,S=data['placements'],data['surfaces']
def mesh(asset,name,p,scale=(1,1,1),yaw=0,section='Scenery'):
    row=dict(asset=asset,name=name,p=list(p),scale=list(scale),yaw=yaw,section=section);P.append(row);return row
def surface(name,p,size,section):
    S.append(dict(name=name,p=list(p),size=list(size),yaw=0,section=section))

# The owner removed instructional signboards. Checkpoint identity remains.
data['signs']=[]
P[:]=[p for p in P if p['asset']!='SC_R_PirateSignboard']
data['hazards']=[h for h in data['hazards'] if h['section']!='S04_Shore']

# A level carriage sits below the route; the trajectory leaves its elevated bore.
muzzle=assets['SC_R_NavalCannon28']['muzzleLocalRobloxXYZ']
for i,shot in enumerate(data['shots']):
    gun=next(p for p in P if p['name']==f'Cannon{i}')
    gun['asset']='SC_R_NavalCannon28';gun['p'][1]=3.4
    direction=-1 if i%2==0 else 1
    shot['start']=[gun['p'][0]+direction*abs(muzzle[0]),3.4+muzzle[1],gun['p'][2]]
    shot['finish']=[-145 if direction<0 else -72,-3.3,gun['p'][2]]
    distance=abs(shot['finish'][0]-shot['start'][0])
    shot['arcHeight']=(math.tan(math.radians(35))*distance-(shot['finish'][1]-shot['start'][1]))/4
    for p in P:
        if p['name']==f'BatteryMount{i}':p['p'][1]=2.17
        if p['asset']=='SC_DockPost' and abs(p['p'][0]-gun['p'][0])<7 and abs(p['p'][2]-gun['p'][2])<6:
            p['scale'][1]=(2.17-p['p'][1])/assets['SC_DockPost']['dimensionsRobloxXYZ'][1]
        if p['name'] in (shot['name'],shot['cue']):p['p']=list(shot['start'])
        if p['name']==shot['impact']:p['p']=list(shot['finish'])

# Two distinct crossings share a safe middle island; the second exits the cave.
P[:]=[p for p in P if p['section']!='H02']
S[:]=[p for p in S if p['section']!='H02']
data['links']=[e for e in data['links'] if not any(n.startswith('Surge') for n in e)]
refuges=[('SurgeEastRefuge',91),('SurgeMiddleRefuge',46),('SurgeWestRefuge',0)]
for name,x in refuges:
    mesh('SC_R_CaveRefuge',name,(x,-4,58),(2,1.4,2),section='H02')
    surface(name,(x,10,58),(24,1,20),'H02')
data['surges']=[]
for i,x in enumerate((69,23),1):
    group=f'Surge{i}'
    mesh('SC_SurgeCrossing',group+'Passage',(x,-4,58),(1.125,9,1.25),section='H02')
    surface(group+'Passage',(x,5,58),(18,1,15),'H02')
    mesh('SC_LocalSurge','SurgeWater',(x,1.5,58),(1.5,1,1),section=group)
    mesh('SC_FoamRibbon','SurgeFoam',(x,4.8,69),(1.5,1,2),section=group)
    mesh('SC_R_Wave28B','SurgeWave',(x,5,69),section=group)
    data['surges'].append(dict(name=group,center=[x,8,58],size=[18,12,22],phase=(i-1)*7,floor=5))
chain=['Cave26Stone06','SurgeEastRefuge','Surge1Passage','SurgeMiddleRefuge','Surge2Passage','SurgeWestRefuge','ShoreEntry28','S04_Shore_02']
surface('ShoreEntry28',(0,8,78),(14,1,16),'S04_Shore')
mesh('SC_R_SandIsland','ShoreEntry28', (0,0,78),(1,2,1.1),section='S04_Shore')
data['links'] += list(map(list,zip(chain,chain[1:])))
data['testRoutes']['waves']=chain[1:]
data['checkpoints'].append([0,10,58])
mesh('SC_R_CheckpointBeacon','CheckpointBeacon5',(0,10,66),section='Wayfinding')
# A solid rock bank closes the old shore shortcut around the second crossing.
mesh('SC_R_SeaRockTall','WaveShoreBank28',(40,-7,80),(4.6,2.5,2),0,'H02')
surface('WaveShoreBarrier28',(40,27,78),(44,34,12),'H02')
obsolete={'S04_Shore_00','ShoreWalk0'}
S[:]=[p for p in S if p['name'] not in obsolete]
data['links']=[e for e in data['links'] if not any(n in obsolete for n in e)]
for side in (-1,1):
    mesh('SC_R_SeaRockTall',f'WaveBank28_{side}',(23,-5,58+side*21),(2.2,1.5,1.4),37*side,'H02')

# Fixed and falling cave formations use the same refined limestone mesh.
for p in P:
    if p['asset']=='SC_R_Stalactite27':p['asset']='SC_R_Stalactite28'
data['falling']=[h for h in data['falling'] if h['kind']=='stalactite' and h['top'][0]>100]
for h in data['falling']:h['asset']='SC_R_Stalactite28'
for i,(x,y,z,bottom) in enumerate([(108,32,17,13),(131,35,37,12),(108,34,45,11)]):
    data['falling'].append(dict(name=f'FallingSpike28_{i}',kind='stalactite',asset='SC_R_Stalactite28',top=[x,y,z],bottom=[x,bottom+3.5,z],radius=2,period=6.8,warning=1.5,fallTime=.6,hold=.5,phase=i*1.8))
for i,(x,z) in enumerate([(101,12),(137,15),(139,32),(103,36),(133,48),(101,52)]):
    p=mesh('SC_R_Stalactite28',f'FloorSpike28_{i}',(x,-3,z),(.8,.9,.8),i*39,'S04');p['pitch']=180

# Reused broad crowns overlap above the route; trunks stay at the beach edges.
P[:]=[p for p in P if p['name'].startswith('DropPalm27_') is False]
for p in P:
    if p['name'].startswith('BeachPalm') and p['p'][1]<15:p['asset']='SC_R_Palm28';p['scale']=[1.1,1.2,1.1]
for i in range(19):
    t=i/18;x=15-104*t;z=83+47*t;side=-1 if i%2 else 1
    root=(x+side*3,7.6,z+side*(8+1.5*math.sin(i*2)))
    sc=.95+.22*(.5+.5*math.sin(i*1.7))
    mesh('SC_R_Palm28',f'GrovePalm28_{i}',root,(sc,1.15+(.15*(i%3)),sc),i*137.5,'S04_Shore')
    data['falling'].append(dict(name=f'FallingCoconut28_{i}',kind='coconut',top=[x,36+(i%3)*2,z],bottom=[x,8.8,z],radius=1.1,period=6.8+(i%4)*.6,warning=1.5,fallTime=.65,hold=.4,phase=i*.73,spread=3,seed=410+i))

# Separate concentric ridges keep old islands readable, with gaps covered by the outer tier.
P[:]=[p for p in P if not p['name'].startswith('HorizonRidge27_')]
ridge=assets['SC_R_Horizon28']['dimensionsRobloxXYZ']
for tier,count,radius in [(0,18,520),(1,20,700)]:
    for i in range(count):
        angle=(i+tier*.5+.16*math.sin(i*2.13+tier))*2*math.pi/count
        distance=radius+29*math.sin(i*1.73+tier*2)
        width=2*radius*math.sin(math.pi/count)*(1.42+.12*math.sin(i*1.37))
        height=(92 if tier==0 else 164)*(1+.34*math.sin(i*1.7+tier)+.16*math.cos(i*2.9))
        yaw=90-math.degrees(angle)+(180 if i%3==1 else 0)+9*math.sin(i*2.6)
        p=mesh('SC_R_Horizon28',f'Horizon28_{tier}_{i}',(distance*math.cos(angle),-12,distance*math.sin(angle)),(width/ridge[0],height/ridge[1],(1.2 if tier==0 else 1.7)*(1+.23*math.cos(i))),yaw,f'DistantIsland28_{tier}_{i}')
        shade=round(5*math.sin(i*1.4))
        p['tint']=[v+shade for v in ([217,222,208] if tier==0 else [165,188,190])]

ground=json.loads((ROOT/'grounding28.json').read_text())
for p in P:
    if p['name'] in ground['placements']:p['p']=ground['placements'][p['name']]
for h in data['falling']:
    if h['name'] in ground['falling']:
        row=ground['falling'][h['name']]
        h['top'],h['bottom']=row['top'],row['bottom']
wreck_ground=json.loads((ROOT/'grounding-wreck28.json').read_text())
for p in P:
    if p['name'] in wreck_ground['cargo']:
        p['p']=wreck_ground['cargo'][p['name']]['suggestedP']
data['braces']=[dict(name='WreckBrace28_'+name.split('_')[-1],a=row['suggestedTimberBrace']['startAtHullOrRock'],b=row['suggestedTimberBrace']['topAtPlankUnderside']) for name,row in wreck_ground['planks'].items()]

data['build']='SC_MAP_28';data['kitBuild']='SC_KIT_28'
data['resource']=dict(visuals=len(P),visualTriangles=sum(assets[p['asset']]['triangles'] for p in P),colliders=len(S),timberBraces=len(data['braces']))
# Working ceilings, not claims about mobile frame rate.
assert data['resource']['visualTriangles']<=120000,data['resource']
assert len(P)+len(S)+300<=1600
assert len(data['falling'])<=32
def lua(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(str(k))+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
    if isinstance(v,bool):return 'true' if v else 'false'
    if v is None:return 'nil'
    return json.dumps(v)
dest=ROOT.parents[2]/'src/ServerStorage/CourseBuilders/ShipwreckCove'
(ROOT/'layout28.json').write_text(json.dumps(data,indent=2))
(ROOT/'layout.json').write_text(json.dumps(data,indent=2))
(dest/'Layout.luau').write_text('-- Generated by assets/shipwreck_cove/revision/layout28.py\nreturn '+lua(data)+'\n')
(dest/'Kit.luau').write_text('return '+lua(assets)+'\n')
print(data['resource'])
