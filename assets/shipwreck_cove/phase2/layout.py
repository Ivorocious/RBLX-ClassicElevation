"""Measured course layout, Roblox XYZ studs. Shared by Blender and Studio installers."""
from pathlib import Path
import json, math

ROOT = Path(__file__).resolve().parent
KIT = json.loads((ROOT.parent/'phase1/manifest.json').read_text(encoding='utf-8'))
ASSETS = {a['id']: a for a in KIT['assets']}
BUILD = 'SC_MAP_07'
placements, surfaces, paths, signs = [], [], {}, []

def mesh(asset, p, yaw=0, scale=(1,1,1), section='Scenery', name=None):
    row=dict(asset='SC_'+asset, p=list(p), yaw=yaw, scale=list(scale), section=section,
             name=name or f'{asset}_{len(placements):03}')
    placements.append(row)
    return row

def surface(name,p,size,section,yaw=0):
    row=dict(name=name,p=list(p),size=list(size),section=section,yaw=yaw)
    surfaces.append(row)
    return row

def pad(name,p,w=12,d=12,kind='DockDeck',section='S01',yaw=0):
    h=1.2 if kind in ('DockDeck','ShipDeck','DockRefuge') else 1 if kind=='SurgeCrossing' else 3 if kind=='RockLedge' else 5
    a=ASSETS['SC_'+kind]['dimensionsRobloxXYZ']
    mount_width,mount_depth=(8.5,6.1) if kind=='RockLedge' else (12.8,9.8) if kind=='RefugeShelf' else (a[0],a[2])
    mesh(kind,(p[0],p[1]-h,p[2]),yaw,(w/mount_width,1,d/mount_depth),section,name)
    surface(name,p,(w,1,d),section,yaw)
    return p

def chain(section,nodes,kind='DockDeck',w=11,d=12):
    paths[section]=[]
    for i,p in enumerate(nodes):
        pad(f'{section}_{i:02}',p,w,d,kind,section)
        paths[section].append(list(p))

def support(p,section='Scenery'):
    for x in [-4,4]:
        mesh('DockPost',(p[0]+x,-3,p[2]),scale=(1,(p[1]+2)/10,1),section=section)

def sign(text,p,yaw=0,sub=''):
    signs.append(dict(text=text,sub=sub,p=p,yaw=yaw))
    mesh('DockPost',(p[0],p[1]-8,p[2]),scale=(.5,.72,.5),section='Wayfinding')

checkpoints=[[-100,8,112],[-100,10,10],[-100,10,-49],[0,40,-80],[100,14,-18]]
pad('HarborAssembly',(-100,8,117),36,44,'DockRefuge','S01')
mesh('HarborGate',(-100,8,96),section='S01',name='SharedHarborGate')
chain('S01',[(-100,8,82),(-105,9,64),(-97,10,46),(-103,10,28)])
pad('R1_Refuge',checkpoints[1],24,20,'DockRefuge','S01')
for p in paths['S01']:support(p,'S01')
for x,z in [(-107,65),(-95,47)]:
    mesh('CargoCrate',(x,9 if z==65 else 10,z),section='S01')
    surface('CargoHop'+str(z),(x,13 if z==65 else 14,z),(4,4,4),'S01')
for z in [-6,-18,-30]:pad('BatteryDeck'+str(z),(-100,10,z),24 if z==-18 else 14,12,'DockDeck','S01')
pad('R2_Boarding',checkpoints[2],22,22,'DockRefuge','S01')
shots=[]
for i,z in enumerate([-6,-30]):
    pad('BatteryMount'+str(i),(-76,10,z),12,12,'DockDeck','H01')
    mesh('Cannon',(-76,10,z),section='H01',name='Cannon'+str(i))
    mesh('Cannonball',(-82,13.1,z),section='H01',name='Ball'+str(i))
    mesh('MuzzleCue',(-81,13,z),section='H01',name='Fuse'+str(i))
    mesh('FoamRibbon',(-125,.5,z),section='H01',name='Impact'+str(i))
    mesh('DangerStripe',(-100,10.04,z),scale=(1.7,.15,1),section='H01')
    shots.append(dict(name='Ball'+str(i),cue='Fuse'+str(i),impact='Impact'+str(i),start=[-81,13.1,z],finish=[-128,13.1,z],phase=i*1.2))
for z in [8,-18,-47]:
    mesh('CannonCover',(-111,10,z),90,section='H01')
    surface('Cover'+str(z),(-111,17,z),(2,7,8),'H01')
sign('CANNON CROSSING',[-108,16,12],sub='Watch the fuse • jump or wait')

# Main ship route climbs inside a broad split shell; its exterior ribs share both endpoints.
mesh('BoardingRamp',(-100,9,-64),90,section='S02',name='BoardingRamp')
surface('BoardingRamp',(-100,12.65,-64),(13.12,1,8),'S02',90)['roll']=23.83
chain('S02',[(-100,15.3,-74),(-100,18,-92),(-83,20,-94),(-66,22,-94),(-66,25,-76),(-49,27,-76),(-49,30,-94),(-32,32,-94),(-32,35,-76),(-15,37,-76)],'ShipDeck',12,12)
pad('R3_Stern',checkpoints[3],22,20,'ShipDeck','S02')
for i,x in enumerate([-106,-90,-74,-58,-42,-26,-10]):
    mesh('CliffShoulder',(x,-7,-85),scale=(1,1.2,1.3),section='Scenery')
for x,base in [(-86,8),(-26,20)]:
    for yaw in [-90,90]:
        if x==-86 and yaw==-90:continue
        row=mesh('HullSide',(x,base,-85),yaw,scale=(1.35,1,3.25),section='S02')
        row['pitch']=15 if yaw==-90 else -15
for x,length in [(-110,4),(-76,32)]:
    row=mesh('HullSide',(x,8+(x+86)*math.tan(math.radians(15)),-85),-90,scale=(1.35,1,length/16),section='S02')
    row['pitch']=15
mesh('HullBow',(-114,2,-85),-90,scale=(1.35,1,1),section='S02')
mesh('SternTransom',(0,27,-85),-90,scale=(1.35,1,1),section='S02')
for x,y in [(-82,20),(-24,36)]:
    mesh('MastYard',(x,y,-85),-15,section='S02')
    mesh('TornSail',(x,y+9,-85),-15,scale=(1.35,1,1),section='S02')
ribs=[(-88,13,-50),(-78,16,-48),(-68,19,-51),(-58,22,-49),(-48,25,-52),(-38,28,-50),(-28,31,-53),(-18,34,-51),(-8,37,-57),(-2,40,-67)]
paths['X01']=[checkpoints[2]]+[list(p) for p in ribs]+[checkpoints[3]]
for i,p in enumerate(ribs):
    mesh('PlayableRib',(p[0],p[1]-18.6,p[2]-12),-90,section='X01',name=f'Rib{i:02}')
    surface(f'Rib{i:02}',p,(3.6,.6,3.2),'X01')
    mesh('CliffShoulder',(p[0],p[1]-30,p[2]+17),scale=(.75,1,.75),section='Scenery')
# Broken shell strips tie the playable ribs into the wreck while retaining open gaps.
for i in [0,1,3,4,6,7]:
    a,b=ribs[i],ribs[i+1]
    row=mesh('HullSide',((a[0]+b[0])/2,(a[1]+b[1])/2-18.6,(a[2]+b[2])/2-12),-90,
             scale=(1,.94,.44),section='S02',name=f'RibShell{i:02}')
    row['pitch']=16
sign('HULL RIBS',[-93,16,-45],sub='Expert • narrow landings')
sign('BROKEN GALLEON',[-110,18,-57],-90,sub='Interior climb')

cliff=[(17,41,-83),(30,43,-96),(44,45,-107),(59,45,-116),(75,44,-121),(91,43,-116),(106,41,-106),(119,39,-94),(128,36,-79),(128,33,-62),(119,29,-46),(111,23,-32)]
chain('S03',cliff,'RockLedge',11,11)
pad('R4_CaveEntry',checkpoints[4],24,20,'RefugeShelf','S03')
for i,p in enumerate(cliff):
    mesh('CliffMass',(p[0]+(7 if i>7 else 0),p[1]-35,p[2]-8),yaw=i*17,scale=(1,1.1,1),section='Scenery')
for i in [2,7]:
    # The timber span owns the walking face while the cliff remains a distant supporting mass.
    name=f'S03_{i:02}'
    row=next(r for r in placements if r['name']==name)
    row['asset']='SC_ShipDeck'; row['scale']=[11/12,1,11/16];row['p'][1]=cliff[i][1]-1.2
mesh('CavePortal',(66,38,-130),section='Scenery',name='HeadlandArch')
spar=[(17,36,-67),(36,32,-55),(55,28,-43),(74,23,-31),(91,18,-23)]
paths['X02']=[checkpoints[3]]+[list(p)for p in spar]+[checkpoints[4]]
for i,p in enumerate(spar):
    yaw=-32+(8 if i%2 else -8)
    mesh('BrokenSpar',(p[0],p[1]-1.88,p[2]),yaw,section='X02',name=f'Spar{i:02}')
    surface(f'Spar{i:02}',p,(16,1.88,2.8),'X02',yaw)
    mesh('CliffShoulder',(p[0],p[1]-17,p[2]+6),scale=(.8,1,.8),section='Scenery')
    mesh('CliffShoulder',(p[0],-5,p[2]+6),scale=(.8,max(1,(p[1]-10)/15),.8),section='Scenery')
sign('CLIFFSIDE ESCAPE',[7,46,-88],sub='Main route follows the headland')
sign('BROKEN SPARS',[9,45,-72],-32,sub='Expert • across the inlet')

# Cave entry runs south, turns west across the local surge, and reveals the southern shore.
cave=[(113,12,0),(117,10,18),(111,8,36),(104,7,53)]
chain('S04_Entry',cave,'RockLedge',12,12)
pad('SurgeEastRefuge',(91,8,58),22,20,'RefugeShelf','H02')
pad('SurgePassage',(69,5,58),18,12,'SurgeCrossing','H02')
pad('SurgeWestRefuge',(46,8,58),24,20,'RefugeShelf','H02')
paths['H02']=[[91,8,58],[69,5,58],[46,8,58]]
mesh('LocalSurge',(69,1.5,58),scale=(1.5,1,16/22),section='H02',name='SurgeWater')
mesh('FoamRibbon',(69,1.9,68),scale=(1.5,1,2),section='H02',name='SurgeFoam')
for x in [64,74]:mesh('DangerStripe',(x,5.03,58),90,scale=(1.5,.15,2),section='H02')
for z in [-2,20,42]:
    mesh('CaveWall',(133,0,z),90,section='S04')
    mesh('CaveWall',(96,0,z),90,section='S04')
    mesh('CaveRoof',(114,26,z),90,scale=(1.2,1,1.9),section='S04')
for x in [43,64,85,106]:
    mesh('CaveWall',(x,0,40),section='S04')
    mesh('CaveRoof',(x,23,58),scale=(.7,1,1.8),section='S04')
    if x!=64:mesh('CliffShoulder',(x,-3,80),scale=(1.1,1.1,1),section='Scenery')
mesh('CavePortal',(113,1,-7),section='S04',name='CaveEntryArch')
mesh('CavePortal',(34,0,60),90,section='S04',name='DaylightExitArch')
sign('TIDE CAVES',[102,20,-9],sub='Foam rises before the surge')
sign('WAIT ON HIGH ROCK',[91,14,51],90,sub='Cross on dry stone')
shore=[(28,8,70),(15,9,82),(-2,8,90),(-20,8,97),(-39,9,102),(-58,8,110),(-76,8,118)]
chain('S04_Shore',shore,'RockLedge',13,12)
paths['S04_Shore'].append([-100,8,117])
sign('HARBOR',[18,15,83],90,sub='Three laps • one finish')

# Economical close scenery: large banks support the route, sparse palms frame views.
for x,z in [(-139,80),(-141,47),(-139,11),(-145,-26),(-145,-65),(-143,-100),(-118,-132),(-82,-135),(-43,-138),(-8,-131),(24,-141),(62,-151),(99,-141),(144,-114),(154,-77),(158,-40),(157,0),(153,36),(133,81)]:
    mesh('CliffMass',(x,-4,z),yaw=(x+z)%35,scale=(1.2,1.15,1.2))
for x,z in [(17,106),(-20,125),(-58,135),(-94,144),(-133,117),(50,92),(97,91)]:
    mesh('CliffShoulder',(x,-6,z),yaw=x%32,scale=(1.3,1,1.4))
for x,z in [(-138,50),(-141,-65),(-82,-135),(62,-151),(154,-40),(133,81),(-58,135),(-133,117)]:
    y=32.8 if z<85 else 9
    mesh('Palm',(x,y,z),yaw=x%70)
mesh('CoveWater',(0,-3.5,0),scale=(20.4,1,20.4))
for p in [(-113,8,130),(-86,8,125),(-109,10,9),(-113,10,-50)]:mesh('CargoBarrel',p)
for p in [(-100,8,117),(-100,10,10),(-100,10,-49)]:support(p,'S01')
for z in [-6,-18,-30]:support((-100,10,z),'S01')
for x in [-110,-90]:mesh('DockPost',(x,-3,-18),scale=(1,1.2,1),section='S01')
for z in [-6,-30]:support((-76,10,z),'H01')
for x,z in [(-142,80),(-142,27),(-147,-31),(-138,-99),(-94,-139),(-35,-143),(24,-144),(82,-146),(147,-105),(155,-51),(154,5),(142,58)]:
    mesh('CliffShoulder',(x,-6,z),yaw=(x+z)%20,scale=(2.2,1.6,2.4))
for p in shore:
    mesh('CliffShoulder',(p[0],p[1]-20,p[2]+5),scale=(.9,1.05,1.05))
for x in [-114,-86]:
    for z in [100,116,134]:mesh('DockPost',(x,-3,z),scale=(1,1,1),section='S01')
for x in [-108,-92]:
    for z in [3,17,-57,-41]:mesh('DockPost',(x,-3,z),scale=(1,1.2,1),section='S01')
# Large headland masses join the cave roof to the surrounding bank.
for x,z in [(132,5),(131,34),(106,44),(85,39)]:
    mesh('CliffShoulder',(x,25,z),yaw=x%25,scale=(1.1,1,1.1))

# Broad overlapping banks create one asymmetric coastline behind the close route-facing kit.
for i,(x,z,sx,sy,sz) in enumerate([
    (-169,69,2.1,1.25,3),(-173,-8,2.3,1.7,3.3),(-158,-87,2.6,1.45,3.5),
    (-101,-157,3.2,1.6,2.3),(-21,-169,3.2,2.1,2.6),(63,-177,3.5,2.45,2.8),
    (143,-148,2.8,2.1,3),(178,-74,2.6,2.5,3.8),(182,7,2.8,2.15,3.7),
    (161,73,2.5,1.7,2.7)]):
    mesh('CliffMass',(x,-6,z),yaw=13+i*23,scale=(sx,sy,sz),name=f'CoastBank{i:02}')
for i,row in enumerate([r for r in placements if r['asset']=='SC_CliffMass' and r['name'].startswith('CliffMass') and r['p'][1]==-4]):
    # Change the skyline rather than repeating identical column tops; retain palm sockets.
    if not any(abs(row['p'][0]-x)<2 and abs(row['p'][2]-z)<2 for x,z in [(-138,50),(-141,-65),(-82,-135),(62,-151),(154,-40),(133,81)]):
        row['scale'][1]*=[.8,1.3,.95,1.45][i%4]
for i,(x,z) in enumerate([(-120,131),(-84,145),(-46,144),(-9,132),(25,115),(59,101)]):
    mesh('CliffShoulder',(x,-12,z),yaw=i*29,scale=(2.2,1.05,2.3),name=f'ShoreBank{i:02}')

data=dict(build=BUILD,kitBuild='SC_KIT_04',origin=[-1500,80,0],placements=placements,surfaces=surfaces,
          paths=paths,checkpoints=checkpoints,signs=signs,shots=shots,
          gate=[-100,8,96],surge=dict(center=[69,6,58],size=[18,8,16],cycle=12,warning=2.5,active=3.0,drain=1.5),
          resource=dict(visuals=len(placements),visualTriangles=sum(ASSETS[p['asset']]['triangles']for p in placements),colliders=len(surfaces)))
assert data['resource']['visualTriangles']<115000
assert len(placements)+len(surfaces)+100<1200
ROOT.mkdir(parents=True,exist_ok=True)
(ROOT/'layout.json').write_text(json.dumps(data,indent=2))

def lua(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(x)for k,x in v.items())+'}'
    if isinstance(v,(list,tuple)):return '{'+','.join(lua(x)for x in v)+'}'
    if isinstance(v,bool):return str(v).lower()
    if v is None:return 'nil'
    return json.dumps(v,ensure_ascii=False)
dest=ROOT.parents[2]/'src/ServerStorage/CourseBuilders/ShipwreckCove'
dest.mkdir(parents=True,exist_ok=True)
(dest/'Layout.luau').write_text('-- Generated by assets/shipwreck_cove/phase2/layout.py\nreturn '+lua(data)+'\n',encoding='utf-8')
(dest/'Kit.luau').write_text('-- Verified SC_KIT_04 dimensions and mounting metadata.\nreturn '+lua(ASSETS)+'\n',encoding='utf-8')
print(json.dumps(data['resource']))
