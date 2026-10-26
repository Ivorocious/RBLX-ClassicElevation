"""Owner critique revision: authored route, asset placements and collision ownership."""
from pathlib import Path
import json, math
ROOT=Path(__file__).resolve().parent
old=json.loads((ROOT.parent/'phase1/manifest.json').read_text())
ASSETS={a['id']:a for a in old['assets']}
extra=ROOT/'manifest13.json'
if extra.exists():
    ASSETS.update({a['id']:a for a in json.loads(extra.read_text())['assets']})
ASSETS.update({a['id']:a for a in json.loads((ROOT/'manifest25.json').read_text())['assets']})
for a in ASSETS.values():
    if 'centerBlender' not in a:
        a['centerBlender']=[(a['boundsBlender']['min'][i]+a['boundsBlender']['max'][i])/2 for i in range(3)]
BUILD='SC_MAP_25'
placements,surfaces,signs,hazards,shots=[],[],[],[],[]
paths={}; links=[]
def mesh(asset,p,yaw=0,scale=(1,1,1),section='Scenery',name=None):
    a=asset if asset.startswith('SC_') else 'SC_'+asset
    r=dict(asset=a,p=list(p),yaw=yaw,scale=list(scale),section=section,name=name or f'{asset}_{len(placements):03}')
    placements.append(r);return r
def surface(name,p,size,section,yaw=0):
    r=dict(name=name,p=list(p),size=list(size),section=section,yaw=yaw);surfaces.append(r);return r
def pad(name,p,w=12,d=12,kind='DockDeck',section='S01',yaw=0):
    h=1.2 if kind in ('DockDeck','ShipDeck','DockRefuge') else 1 if kind=='SurgeCrossing' else 3 if kind=='RockLedge' else 5
    a=ASSETS['SC_'+kind]['dimensionsRobloxXYZ']
    mw,md=(8.5,6.1) if kind=='RockLedge' else (12.8,9.8) if kind=='RefugeShelf' else (a[0],a[2])
    mesh(kind,(p[0],p[1]-h,p[2]),yaw,(w/mw,1,d/md),section,name)
    surface(name,p,(w,1,d),section,yaw)
def support(p,section):
    for x in [-4,4]:mesh('DockPost',(p[0]+x,-5,p[2]),scale=(1,(p[1]+4)/10,1),section=section)
def chain(section,nodes,kind='DockDeck',w=11,d=10):
    paths[section]=[list(p)for p in nodes]
    for i,p in enumerate(nodes):pad(f'{section}_{i:02}',p,w,d,kind,section)
def join(names):
    links.extend([[a,b]for a,b in zip(names,names[1:])])
def sign(text,p,yaw=0,sub=''):
    signs.append(dict(text=text,sub=sub,p=list(p),yaw=yaw))
def hazard(name,p,size,section,kind='static',period=4,amplitude=0,axis='X',phase=0):
    hazards.append(dict(name=name,p=list(p),size=list(size),section=section,kind=kind,period=period,amplitude=amplitude,axis=axis,phase=phase))

checkpoints=[[-108,8,128],[-108,13,8],[-108,13,-66],[0,43,-100],[108,15,-18]]
pad('HarborAssembly',checkpoints[0],36,40,'DockRefuge','S01')
docks=[(-108,10,99),(-110,12,84),(-108,14,69),(-111,16,54),(-108,17,39),(-110,16,24)]
chain('S01',docks,w=12,d=10)
for p in docks:support(p,'S01')
pad('R1_Refuge',checkpoints[1],26,20,'DockRefuge','S01')
hazard('DockRopeSweep',(-115,13.6,77),(3,3,3),'S01','sweep',4.8,4,'X')
hazard('HotCargoBand',(-115,17.45,41),(10,.8,1.25),'S01')
mesh('CargoCrate',(-119,17,42),section='S01')
surface('CargoSide',(-119,21,42),(4,4,4),'S01')
join(['HarborAssembly']+[f'S01_{i:02}'for i in range(len(docks))]+['R1_Refuge'])

# Four firing lanes alternate sides, with protected broad pockets between volleys.
for i,z in enumerate([-7,-23,-39,-55]):
    pad(f'BatteryDeck{i}',(-108,13,z),18,12,'DockDeck','S01');support((-108,13,z),'S01')
    side=1 if i%2==0 else -1;x=-80 if side==1 else -138
    pad(f'BatteryMount{i}',(x,13,z),12,12,'DockDeck','H01');support((x,13,z),'H01')
    mesh('Cannon',(x,13,z),0 if side==1 else 180,section='H01',name=f'Cannon{i}')
    start=[x-side*5,16.1,z];finish=[-108-side*31,16.1,z]
    mesh('Cannonball',start,section='H01',name=f'Ball{i}')
    mesh('MuzzleCue',start,section='H01',name=f'Fuse{i}')
    mesh('FoamRibbon',(finish[0],.5,z),section='H01',name=f'Impact{i}')
    mesh('DangerStripe',(-108,13.13,z),scale=(2,.5,2),section='H01')
    shots.append(dict(name=f'Ball{i}',cue=f'Fuse{i}',impact=f'Impact{i}',start=start,finish=finish,phase=[0,1.3,3.8,5.1][i]))
    if i<3:
        p=(-119 if i%2==0 else -97,13,z-8)
        pad(f'CoverPocket{i}',p,10,8,'DockDeck','H01')
        mesh('CannonCover',(p[0]+(-4 if i%2==0 else 4),13,p[2]),90,section='H01')
        surface(f'CoverWall{i}',(p[0]+(-4 if i%2==0 else 4),20,p[2]),(1.6,7,7),'H01')
pad('R2_Boarding',checkpoints[2],24,20,'DockRefuge','S01')
join(['R1_Refuge']+[f'BatteryDeck{i}'for i in range(4)]+['R2_Boarding'])
sign('CANNON RUN',[-122,20,5],sub='Watch the fuse  /  jump or wait')

# The interior alternates missing deck jumps, raised beams and timed sweeps.
ship=[(-108,16,-86),(-108,19,-105),(-91,22,-110),(-74,24,-110),(-74,27,-91),(-57,29,-91),(-57,32,-110),(-40,34,-110),(-40,37,-91),(-22,40,-91)]
chain('S02',ship,'ShipDeck',11,12)
pad('R3_Stern',checkpoints[3],24,22,'ShipDeck','S02')
join(['R2_Boarding']+[f'S02_{i:02}'for i in range(len(ship))]+['R3_Stern'])
for i in [2,5,8]:
    x,y,z=ship[i];hazard(f'DeckBurn{i}',(x,y+.45,z),(9,.8,1.1),'S02')
for i in [3,7]:
    x,y,z=ship[i];hazard(f'ShipSweep{i}',(x,y+1.2,z),(8,.65,.65),'S02','sweep',4.5,3,'Z',i*.4)
for x,y in [(-86,20),(-27,38)]:
    mesh('MastYard',(x,y,-100),-10,scale=(1.1,1.25,1.1),section='S02')
    mesh('TornSail',(x,y+13,-100),-10,scale=(1.35,1.25,1),section='S02')
# Smaller staggered tips demand precise rising jumps; there is no scenic stepping-stone bypass.
ribs=[(-93,16,-61),(-83,19,-57),(-73,22,-62),(-63,25,-57),(-53,28,-62),(-43,31,-57),(-33,34,-62),(-23,37,-65),(-14,40,-71),(-6,42,-79)]
paths['X01']=[checkpoints[2]]+[list(p)for p in ribs]+[checkpoints[3]]
for i,p in enumerate(ribs):
    mesh('PlayableRib',(p[0],p[1]-18.6,p[2]-7.2),-90,scale=(.6,1,.6),section='X01',name=f'Rib{i:02}')
    surface(f'Rib{i:02}',p,(2.15,.6,2),'X01')
    mesh('DockPost',(p[0],-5,p[2]-7.2),scale=(.8,max(.3,(p[1]-13.6)/10),.8),section='X01')
join(['R2_Boarding']+[f'Rib{i:02}'for i in range(len(ribs))]+['R3_Stern'])
sign('THE WRECK',[-120,23,-68],sub='Climb through the broken decks')
sign('HULL RIBS',[-120,22,-60],0,sub='Hard jumps  /  gold tips')

cliff=[(20,45,-106),(34,48,-120),(50,51,-130),(67,54,-137),(84,55,-130),(101,53,-116),(116,49,-101),(129,44,-85),(134,39,-66),(127,33,-48),(119,26,-33)]
paths['S03']=[list(p)for p in cliff]
for i,p in enumerate(cliff):
    # Timber spans break the rock rhythm; selected broad turns allow passing.
    timber=i in [3,7]
    pad(f'S03_{i:02}',p,14 if i in [3,5,7,10] else 10,
        8 if timber else 12 if i in [5,10] else 10,
        'ShipDeck' if timber else 'RockLedge','S03')
    if timber:support(p,'S03')
pad('R4_CaveEntry',checkpoints[4],24,22,'RefugeShelf','S03')
join(['R3_Stern']+[f'S03_{i:02}'for i in range(len(cliff))]+['R4_CaveEntry'])
mesh('R_HeadlandRidge',(0,0,0),name='ConnectedHeadland')
mesh('CavePortal',(67,40,-137),90,(1,1.2,1),name='HeadlandArch')
for i,p in enumerate(cliff):
    if i in [2,6,9]:hazard(f'CliffSweep{i}',(p[0],p[1]+1,p[2]),(8,.65,.65),'S03','sweep',4.2,3,'Z',i*.2)
    if i in [4,8]:hazard(f'CliffDanger{i}',(p[0],p[1]+.4,p[2]),(8,.7,1),'S03')
spar=[(18,40,-87),(28,36,-79),(41,32,-69),(54,28,-59),(67,24,-49),(80,21,-39),(93,18,-29)]
paths['X02']=[checkpoints[3]]+[list(p)for p in spar]+[checkpoints[4]]
for i,p in enumerate(spar):
    yaw=-34+(12 if i%2 else -12)
    mesh('BrokenSpar',(p[0],p[1]-1.88,p[2]),yaw,(.56,1,.64),'X02',f'Spar{i:02}')
    surface(f'Spar{i:02}',p,(8.96,1.88,1.79),'X02',yaw)
    mesh('DockPost',(p[0],-6,p[2]),scale=(1.4,(p[1]+5)/10,1.4),section='X02')
join(['R3_Stern']+[f'Spar{i:02}'for i in range(len(spar))]+['R4_CaveEntry'])
sign('HIGH TIDE CLIFFS',[6,49,-112],sub='Follow the ledges')
sign('BROKEN SPARS',[-5,49,-87],0,sub='Expert shortcut')

# Coherent L-shaped cave: a clear high-ceiling approach, then one visible sea-fed crossing.
cave=[(113,13,1),(120,11,21),(120,10,40),(113,10,58)]
chain('S04_Entry',cave,'RockLedge',13,12)
pad('SurgeEastRefuge',(91,10,58),22,20,'RefugeShelf','H02')
pad('SurgePassage',(69,5,58),18,12,'SurgeCrossing','H02')
pad('SurgeWestRefuge',(46,10,58),24,20,'RefugeShelf','H02')
paths['H02']=[[91,10,58],[69,5,58],[46,10,58]]
join(['R4_CaveEntry']+[f'S04_Entry_{i:02}'for i in range(len(cave))]+['SurgeEastRefuge','SurgePassage','SurgeWestRefuge'])
mesh('LocalSurge',(69,1.5,58),scale=(1.5,1,16/22),section='H02',name='SurgeWater')
mesh('FoamRibbon',(69,1.9,68),scale=(1.5,1,2),section='H02',name='SurgeFoam')
for x in [61,77]:mesh('DangerStripe',(x,5.13,58),90,(1.5,.5,2),'H02')
sign('TIDE CAVE',[102,22,-14],sub='High rock is safe')
sign('WAIT FOR LOW TIDE',[82,18,48],90,sub='Teal shelves are safe')
shore=[(27,8,72),(10,8,86),(-8,8,95),(-27,8,103),(-46,8,112),(-66,8,121),(-85,8,129)]
chain('S04_Shore',shore,'RockLedge',12,11)
join(['SurgeWestRefuge']+[f'S04_Shore_{i:02}'for i in range(len(shore))]+['HarborAssembly'])
for i in [2,5]:
    x,y,z=shore[i];hazard(f'ShoreTimber{i}',(x,y+.45,z),(1,.8,10),'S04_Shore')

# Section-scale rocks are placed behind the route, not across walking surfaces.
for i,(x,z,sx,sy,sz) in enumerate([(-159,62,2.4,1.5,3.2),(-169,-21,2.3,1.9,3),(-162,-115,2.1,1.6,2.8),(-95,-158,2.8,1.8,2),(-18,-161,2.8,2.1,2.5),(68,-177,3.1,2.2,2.2),(144,-144,2.3,2,2.4),(177,-72,2,2.1,3),(174,4,2.1,1.7,2.6),(153,72,2,1.4,2)]):
    mesh('CliffMass',(x,-6,z),i*29,(sx,sy,sz),name=f'CoastBank{i:02}')
mesh('CoveWater',(0,-3.5,0),scale=(20.4,1,20.4))
for p in [(-120,8,135),(-93,8,138),(-120,13,8),(-118,13,-68)]:mesh('CargoBarrel',p)
for p in checkpoints[:3]:support(p,'S01')

# Open bow-to-stern shell surrounds the course; missing planks remain real jumps.
mesh('R_GroundedHullUnderbody',(0,0,0),section='S02',name='GroundedHullUnderbody')
for asset,x,y in [('HullBow',-104,3),('HullMid',-65.36,13.35),('HullStern',-26.72,23.7)]:
    r=mesh('R_'+asset,(x,y,-100),-90,(1.55,1.25,2),'S02')
    r['pitch']=15
for i,(x,y) in enumerate([(-107,2),(-69,12),(-28,22)]):
    mesh('R_SeaRockFlat',(x,-6,-105),i*47,(2.7,(y+9)/6,3.2),name=f'KeelReef{i}')
    mesh('R_SeaRockSpire',(x,-6,-120),i*37,(1.9,(y+11)/18,1.8),name=f'KeelCrag{i}')
for row in placements:
    if row['asset']=='SC_Cannon':row['asset']='SC_R_CannonFourWheel'
for i,p in enumerate(checkpoints):
    mesh('R_CheckpointBeacon',(p[0],p[1],110 if i==0 else p[2]+(-8 if i==3 else 8)),
        scale=(1.6,1.2,1) if i==0 else (1,1,1),section='Wayfinding',name=f'CheckpointBeacon{i}')
for s in signs:
    mesh('R_PirateSignboard',(s['p'][0],s['p'][1]-8,s['p'][2]),s['yaw'],(1.25,1,1),section='Wayfinding')

# Keep the cave shell high above the walking route, with an open sightline to the sea-fed surge.
mesh('R_CaveChamber',(120,0,22),0,(1.15,1.5,1.6),'S04','CaveApproach')
mesh('R_CaveTideBend',(79,0,58),-90,(1.1,1.4,2.25),'S04','TideChamber')
mesh('R_CurlingWave',(69,-2,66),90,(.48,.85,1.1),'H02','SurgeWave')
# Wet channel sides ground the local surge; both remain beyond its walking footprint.
for z in [46,70]:
    mesh('R_SeaRockFlat',(69,-4,z),0,(1.45,1.3,.6),'S04',f'WetChannel{z}')
    placements[-1]['tint']=[105,133,125]
# Broad rock at the roof join seals the outside silhouette without filling the chamber.
mesh('R_SeaRockFlat',(119,33,44),0,(3,.8,2.2),'Scenery')

# Shelves meet submerged rock instead of hanging over an empty air gap.
for row in placements:
    if row['name'] in ['SurgeEastRefuge','SurgeWestRefuge','R4_CaveEntry']:
        top=row['p'][1]+5
        width=22 if row['name']=='SurgeEastRefuge' else 24
        depth=22 if row['name']=='R4_CaveEntry' else 20
        row['asset']='SC_R_CaveRefuge'
        row['p'][1]=-4
        row['scale']=[width/12,(top+4)/10,depth/10]
    if row['name']=='SurgePassage':
        row['p'][1]=-4
        row['scale'][1]=9
    if row['name'].startswith('S04_Entry_'):
        top=row['p'][1]+3
        row['p'][1]=-4
        row['scale'][1]=(top+4)/3
    if row['section'] in ['H02','S04_Entry'] and row['asset'] in ['SC_RefugeShelf','SC_RockLedge','SC_SurgeCrossing']:
        row['tint']=[204,218,210]

# Layered shore banks ground the cliffs, with mossy shelves and sparse growth.
for i,(x,z) in enumerate([(-157,70),(-164,-13),(-157,-108),(-85,-160),(-6,-160),(76,-166),(167,-118),(178,-51),(169,24)]):
    mesh('R_SeaRockFlat',(x,-5,z),i*19,(3.2,2.1,2.8),name=f'CoastFoot{i}')
for i in [1,4,6,9]:
    p=cliff[i]
    mesh('R_Shrub',(p[0]+5,p[1]-2,p[2]-8),i*23,(1.2,.8,1.1),name=f'CliffGrowth{i}')
    mesh('R_SeaRockFlat',(p[0]+5,p[1]-7,p[2]-8),i*19,(1.5,1,1.4),name=f'CliffGrowthShelf{i}')
for row in placements:
    if row['asset']=='SC_CliffMass':
        index=placements.index(row)
        row['tint']=[[226,235,214],[232,222,201],[211,226,221]][index%3]
        if row['name'].startswith('CoastBank') and int(row['name'][-2:])%2==0:
            row['asset']='SC_R_SeaRockTall'
            row['scale']=[row['scale'][0]*2.65,row['scale'][1]*32/14,row['scale'][2]*2.1]

# Warm irregular beaches contrast against limestone and frame the low return.
mesh('R_ShoreBank',(0,0,0),section='Scenery',name='ConnectedShoreBank')
placements[:]=[r for r in placements if not r['name'].startswith('S04_Shore_')]
for i,(a,b) in enumerate(zip(shore,shore[1:])):
    dx,dz=b[0]-a[0],b[2]-a[2]
    surface(f'ShoreWalk{i}',((a[0]+b[0])/2,8,(a[2]+b[2])/2),
            (math.hypot(dx,dz)+1,1,12),'S04_Shore',math.degrees(math.atan2(-dz,dx)))
for i,(x,z,s) in enumerate([(-131,128,1.8),(-140,64,1),(-136,33,.8),(23,92,1.3),(60,88,1.3),(130,75,1.6)]):
    mesh('R_SandIsland',(x,-4,z),i*23,(s,2,s),name=f'Beach{i}')
    mesh('R_FanPalm',(x,3,z),i*41,(1.3,1.3,1.3),name=f'BeachPalm{i}')
    mesh('R_Shrub',(x-4,3,z+3),i*19,(1.5,1.1,1.5))
    mesh('R_GrassClump',(x+5,3,z+2),i*61,(1,1,1))
for i,(x,z,y) in enumerate([(-129,103,3),(-148,52,3),(37,84,3),(138,71,3)]):
    mesh('R_FanPalm',(x,y,z),i*57,(1.5,1.1+i*.12,1.5),name=f'LeaningPalm{i}')
# Low facets follow the outer bank, leaving the flat return corridor fully visible.
for i,(x,z) in enumerate([(18,103),(-24,122),(-62,137)]):
    r=mesh('R_SandWedge',(x,-1,z),-153+i*7,(1.1,2,.65),'Scenery',f'ShoreDuneFacet{i}')
    r['tint']=[224,199,156]
for i,(x,z) in enumerate([(26,109),(-33,138)]):
    r=mesh('R_SandWedge',(x,-4,z),-151+i*13,(1.05,1.3,.7),'Scenery',f'WetSandEdge{i}')
    r['tint']=[185,156,115]
mesh('R_FanPalm',(-17,-1.5,126),31,(.72,.9,.72),'Scenery','ShorePalmCluster')
mesh('R_Shrub',(-57,3,136),24,(1.1,.8,1),'Scenery','ShoreShrubCluster')
mesh('R_GrassClump',(21,4,99),-21,(1,1,1),'Scenery','ShoreGrassCluster')

# Wet rock seams meet the cave walls below the dry shelf tops.
for i,(x,z) in enumerate([(100,29),(139,39),(75,77),(60,39)]):
    r=mesh('R_SeaRockFlat',(x,-4,z),i*23,(1.1,1.5,.8),'Scenery',f'CaveFootSeam{i}')
    r['tint']=[150,173,163]

# The cove-facing arch leg rests on a rock stack joined to the headland slope.
mesh('R_SeaRockTall',(67,-4,-123),11,(1.8,3.2,1.2),'Scenery','ArchSeaStack')
mesh('R_SeaRockFlat',(67,28,-130),-17,(1.7,2.2,1.8),'Scenery','ArchSlopeJoin')
for i,(x,z,y) in enumerate([(-162,-115,45.2),(-95,-158,51.6),(68,-177,64.4),(144,-144,58),(177,-72,61.2),(174,4,48.4)]):
    mesh('R_FanPalm',(x,y,z),i*31,(1.3,1.5,1.3),name=f'CoastPalm{i}')
    mesh('R_SandWedge',(x,y-2.8,z),i*22,(.8,1,.8))
for i,p in enumerate(cliff):
    if i%2==0:
        mesh('R_SeaRockSpire',(p[0]+13,p[1]-35,p[2]-11),i*31,(1.4,1.8,1.5))
for i,(x,z) in enumerate([(-133,15),(-141,-37),(-142,-77),(-121,-124),(-62,-136),(13,-125),(148,-29),(145,29)]):
    mesh('R_SeaRockTall',(x,-5,z),i*21,(1.4,1.8,1.4))

# Each small island streams as one assembly to preserve its silhouette.
for i,(x,z,s) in enumerate([(-350,-220,3.4),(270,-290,4.2),(310,220,3.2),(-320,100,2.6),(60,-350,3.5),(-260,280,3.1)]):
    section=f'DistantIsland{i}'
    mesh('R_SandIsland',(x,-6,z),i*42,(s*2,2,s*2),section,name=f'DistantIsland{i}')
    mesh('R_SeaRockTall',(x,-5,z),i*51,(s*3,s*1.5,s*3),section,name=f'DistantPeak{i}')
    mesh('R_SeaRockSpire',(x+s*12,-5,z+14),i*22,(s*2,s*.9,s*2),section)
    for j in [-1,1]:mesh('R_FanPalm',(x+j*30,1,z+25),j*38,(2,2,2),section,name=f'IslandPalm{i}_{j}')
for i,(x,z) in enumerate([(-40,40),(15,10),(30,53),(-64,78),(-12,-18),(70,12),(-210,40),(215,110),(180,-220),(-320,185)]):
    mesh('FoamRibbon',(x,-3.1,z),i*29,(1.5,.4,.5),name=f'SeaGlint{i}')

def lua(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(x)for k,x in v.items())+'}'
    if isinstance(v,(list,tuple)):return '{'+','.join(lua(x)for x in v)+'}'
    if isinstance(v,bool):return str(v).lower()
    if v is None:return 'nil'
    return json.dumps(v,ensure_ascii=False)

def critique25():
    global placements,surfaces,links,hazards
    # Keep the old layout above as the recovery reference; replace only this critique's sections.
    old_names={f'S01_{i:02}' for i in range(len(docks))}|{f'BatteryDeck{i}' for i in range(4)}
    old_names|={'CargoSide'}|{f'CoverPocket{i}' for i in range(3)}|{f'CoverWall{i}' for i in range(3)}
    old_names|={f'S04_Entry_{i:02}' for i in range(4)}
    surfaces[:]=[r for r in surfaces if r['name'] not in old_names]
    placements[:]=[r for r in placements if r['name'] not in old_names and r['name'] not in ['CaveApproach','TideChamber']
                  and not(r['section']=='H01' and r['asset'] in ['SC_CannonCover','SC_DangerStripe'])
                  and not(r['section']=='S01' and r['asset'] in ['SC_CargoCrate','SC_DockPost'])]
    links[:]=[r for r in links if not any(n in old_names for n in r)]
    hazards[:]=[r for r in hazards if r['section']!='S01']
    for i,(x,y,z) in enumerate(docks):
        for j,offset in enumerate(([-8,0,8] if i%2==0 else [-7.5,0,7,14])):
            name=f'S01_{i:02}' if j==1 else f'DockCluster{i}_{j}'
            p=(x+offset,y+(.3 if j%2 else 0),z+[1.2,0,-1,.7][j])
            pad(name,p,5.2,8,'DockDeck','S01')
            mesh('DockPost',(p[0],-5,p[2]),scale=(.65,(p[1]+3.8)/10,.65),section='S01')
            if (i,j) in [(1,0),(3,3),(4,0)]:hazard(f'RedCargo{i}_{j}',(p[0],p[1]+1.5,p[2]),(2.8,3,2.8),'S01')
        if i in [0,2,4]:
            mesh('R_DockBrace25',(x,-3,z),scale=(1, (y+1.8)/9.5,1),section='S01')
    join(['HarborAssembly']+[f'S01_{i:02}' for i in range(len(docks))]+['R1_Refuge'])
    for i,z in enumerate([-7,-23,-39,-55]):
        offsets=[-8,0,8] if i==0 else [-10,-3.2,3.7,10.4] if i%2 else [-12,-6,0,6,12]
        for j,dx in enumerate(offsets):
            name=f'BatteryDeck{i}' if j==len(offsets)//2 else f'BatteryCluster{i}_{j}'
            p=(-108+dx,13+(.35 if j%2 else 0),z+[1.3,-.8,.4,-1.4,1][j])
            pad(name,p,4.6,7,'DockDeck','S01')
            mesh('DockPost',(p[0],-5,p[2]),scale=(.7,(p[1]+3.8)/10,.7),section='S01')
    join(['R1_Refuge']+[f'BatteryDeck{i}' for i in range(4)]+['R2_Boarding'])
    for row in placements:
        if row['asset']=='SC_R_CannonFourWheel':row['asset']='SC_R_NavalCannon25'
    for shot in shots:
        shot['finish'][1]=-3.3
        next(p for p in placements if p['name']==shot['impact'])['p'][1]=-3.25
    for x,z in [(-122,132),(-94,132),(-122,116),(-94,116)]:
        mesh('DockPost',(x,-5,z),scale=(1.4,1.18,1.4),section='S01')
    for z in [118,136]:mesh('R_DockBrace25',(-108,-3,z),scale=(2.6,1,1),section='S01')
    for x,z,yaw in [(-123,124,20),(-96,140,-12)]:
        mesh('CargoCrate',(x,8,z),yaw,(.75,.75,.75),'S01')
        mesh('CargoBarrel',(x+2,8,z+3),yaw,(.65,.65,.65),'S01')
    for x,z in [(-122,113),(-94,113)]:mesh('R_Lantern25',(x,10,z),section='S01')
    for p in [checkpoints[1],checkpoints[2]]:support(p,'S01')

    # Six/five stones across each shallow arc; no submerged column appears climbable.
    cave_rows=[(112,13,-1),(119,12,10),(124,11,21),(124,10.5,32),(118,10,43),(108,10,51)]
    primary=[];crumble=[]
    for i,(x,y,z) in enumerate(cave_rows):
        count=5 if i%2==0 else 6
        for j in range(count):
            dx=(j-(count-1)/2)*5.2
            name=f'CaveStone_{i}_{j}';p=(x+dx,y,z+[.6,-.7,.2,-.4,1,-.9][j])
            pad(name,p,3.9,5.4,'RockLedge','S04_Entry',yaw=((i*17+j*11)%24)-12)
            row=placements[-1];row['p'][1]=-4;row['scale'][1]=(y+4)/3
            row['tint']=[182,195,180] if j%2 else [204,205,183]
            crumble.append(name)
            if j==count//2:primary.append(name)
    join(['R4_CaveEntry']+primary+['SurgeEastRefuge'])
    for asset in ['CaveMouth25','CaveVault25','CaveSurge25']:mesh('R_'+asset,(0,0,0),section='S04')
    # Remove the broad rectangular roof join and old wall feet that belonged to the L shell.
    placements[:]=[r for r in placements if not (r['asset']=='SC_R_SeaRockFlat' and r['p']==[119,33,44])
                  and not r['name'].startswith('CaveFootSeam')]
    for i,(x,z,y) in enumerate([(104,-5,30),(140,13,34),(142,35,31),(117,59,33),(88,75,29),(59,76,28)]):
        mesh('R_HangingVine25',(x,y+2,z),i*33,(1.4,1.6,1.4),'S04',f'CaveVine{i}')
    for i,(x,y,z) in enumerate([(97,16,-6),(148,15,22),(102,14,40),(91,12,78),(45,12,79)]):
        mesh('R_SeaRockFlat',(x,y-5,z),i*41,(.65,.8,.65),'S04',f'LampShelf{i}')
        mesh('R_Lantern25',(x,y,z),section='S04',name=f'CaveLamp{i}')

    # Varied low-cost horizon silhouettes; palms sit on exposed sand rather than inside rock.
    for r in placements:
        if r['section'].startswith('DistantIsland') and r['asset']=='SC_R_FanPalm':
            index=int(r['section'].replace('DistantIsland',''))
            island=next(p for p in placements if p['name']==f'DistantIsland{index}')
            r['p']=[island['p'][0]+(-37 if r['p'][0]<island['p'][0] else 37),1,island['p'][2]+48]
    for i,(x,z,s,yaw) in enumerate([(-450,-40,2.2,17),(420,-90,2.8,45),(90,360,3.1,91),(-100,-420,2.1,130)]):
        sec=f'DistantIsland{6+i}'
        mesh('R_SandIsland',(x,-6,z),yaw,(s*2,2,s*1.6),sec)
        for j in range(2+i%2):mesh('R_SeaRockSpire',(x-18+j*20,-5,z-10+j*7),yaw+j*47,(1.8,1.3+j*.4,1.8),sec)
        mesh('R_FanPalm',(x+23,1,z+28),yaw,(1.5,1.7,1.5),sec)
        mesh('R_Shrub',(x+20,1,z+26),yaw,(2,1.2,2),sec)
        if i in [0,2]:
            mesh('R_HullBow',(x-22,-5,z+32),yaw,(.85,.85,.85),sec)
            mesh('MastYard',(x-22,1,z+32),yaw,(.65,.75,.65),sec)
            mesh('TornSail',(x-22,10,z+32),yaw,(.65,.65,.65),sec)
    return crumble

CRUMBLE=critique25()
# One focused review pass: scenery contacts and silhouettes; tested primary jumps stay fixed.
for p in placements:
    if p['name']=='LeaningPalm0':p['p']=[-140,3,112]
    if p['name']=='IslandPalm3_-1':p['p']=[-340,1,119]
    if p['name']=='IslandPalm5_1':p['p']=[-245,1,294]
    if p['name']=='R_FanPalm_415':p['p']=[-440,1,-29]
    if p['name']=='BeachPalm0':p['yaw']=110;p['scale']=[1.05,1.3,1.05]
    if p['name'].startswith('LampShelf'):
        top=p['p'][1]+4.8
        p['p'][1]=-4;p['scale'][1]=(top+4)/6
        p['tint']=[157,168,158]
    if p['name']=='DistantPeak0':p['scale'][1]*=.55
    if p['name']=='DistantPeak2':p['scale'][0]*=.65;p['scale'][1]*=1.3
    if p['name']=='DistantPeak4':p['scale'][0]*=1.25;p['scale'][1]*=.7
    if p['name'].startswith('BatteryCluster'):
        p['tint']=[[219,208,185],[187,171,150],[230,218,190]][len(p['name'])%3]
for i,(x,y,z,sx,sy,sz) in enumerate([(104,34,-14,1.1,1,1.4),(124,40,4,1.4,1.2,1.7),
        (132,39,27,1.5,1.1,1.6),(114,40,48,1.6,1.3,1.4),(86,34,60,1.8,1,1.4),(53,31,59,1.4,1.2,1.6)]):
    p=mesh('R_SeaRockFlat',(x,y,z),i*37,(sx,sy,sz),'S04',f'CaveRoofFacet25_{i}')
    p['tint']=[188+i*4,195+i*3,180+i*3]
for i,(x,z,h) in enumerate([(94,-8,25),(100,8,29),(148,16,27),(146,36,25),(101,32,25),(94,48,24),(73,82,22),(48,79,20)]):
    p=mesh('R_SeaRockSpire',(x,-4,z),i*41,(.65,h/18,.65),'S04',f'CaveWallRidge25_{i}')
    p['tint']=[153+i*5,169+i*4,160+i*3]
if (ROOT/'grounding25.json').exists():
    grounded={r['name']:r['y'] for r in json.loads((ROOT/'grounding25.json').read_text())['adjustments']}
    for p in placements:
        if p['name'] in grounded and p['asset'] in ['SC_R_FanPalm','SC_R_HangingVine25']:p['p'][1]=grounded[p['name']]

def finish():
    data=dict(build=BUILD,kitBuild='SC_KIT_25',origin=[-1500,80,0],placements=placements,surfaces=surfaces,paths=paths,links=links,checkpoints=checkpoints,signs=signs,shots=shots,hazards=hazards,crumble=CRUMBLE,gate=[-108,8,110],surge=dict(center=[69,6,58],size=[18,8,16]),resource=dict(visuals=len(placements),visualTriangles=sum(ASSETS[p['asset']]['triangles']for p in placements),colliders=len(surfaces)))
    assert data['resource']['visualTriangles']<115000
    assert len(placements)+len(surfaces)+200<1200
    (ROOT/'layout.json').write_text(json.dumps(data,indent=2))
    dest=ROOT.parents[2]/'src/ServerStorage/CourseBuilders/ShipwreckCove'
    (dest/'Layout.luau').write_text('-- Generated by assets/shipwreck_cove/revision/layout.py\nreturn '+lua(data)+'\n',encoding='utf-8')
    (dest/'Kit.luau').write_text('return '+lua(ASSETS)+'\n',encoding='utf-8')
    print(json.dumps(data['resource']))

if __name__=='__main__':finish()
