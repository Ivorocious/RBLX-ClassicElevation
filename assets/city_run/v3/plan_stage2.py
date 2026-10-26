"""Plan scenery replacement from preserved source footprints, leaving course objects intact."""
from pathlib import Path
import json,re,math
ROOT=Path(__file__).resolve().parent
OUT=ROOT.parents[2]/'docs/artifacts/city-run/v3/stage2'
inv=json.loads((OUT/'source-inventory.json').read_text());manifest=json.loads((ROOT/'stage1-manifest.json').read_text());assets={a['id']:a for a in manifest['assets']};colliders=json.loads((OUT/'course-colliders.json').read_text())
plan=[];remove=[];caps=[]
def add(asset,pos,size=None,yaw=0,label='',category='Architecture'):
 plan.append(dict(asset=asset,pos=pos,size=size or assets[asset]['dimensionsRobloxXYZ'],yaw=yaw,label=label,category=category))
def shape(r,asset,roof=False):
 lo,hi=r['min'],r['max'];cx=(lo[0]+hi[0])/2;cz=(lo[2]+hi[2])/2;w=hi[0]-lo[0];d=hi[2]-lo[2];y=max(0,lo[1]);h=hi[1]-y
 # Source trims may overhang the structural footprint; reserve a small visual margin.
 if roof:
  w=max(5,w-1.2);d=max(5,d-1.2)
  limit=y+h
  for name,x,py,z,sx,sy,sz in colliders:
   if sy>4 or 'Kill' in name or 'Hazard' in name:continue
   if abs(x-cx)<w/2+min(sx/2,3) and abs(z-cz)<d/2+min(sz/2,3) and y<py<limit:
    limit=py-sy/2-.4
  if limit<y+h: caps.append({'name':r['name'],'oldTop':y+h,'newTop':limit})
  h=max(3,limit-y)
  roofh=min(6,h*.07);add(asset,[cx,y,cz],[w,h-roofh,d],label=r['name'])
  add('V3_FlatRoof_Broad' if h<35 else ('V3_MansardRoof' if len(plan)%3 else 'V3_GableRoof_Wide'),[cx,y+h-roofh,cz],[w+.2,roofh,d+.2],label=r['name']+'_roof',category='Roofs')
 else:add(asset,[cx,y,cz],[max(.5,w),max(.5,h),max(.5,d)],label=r['name'],category='Props')
 remove.append(r['path'])
exclude={'C13_FinalStation','C13_Depot','C13_MainHall','C13_RiversidePortal','C13_StationBase','MarketCloseFronts'}
building=re.compile(r'^(CitySkyline|CityInfill|CityC10|MarketHouse|MarketBackdrop_|CourtHouse|RoofHouse|OuterBlock|DistantBlock|NorthRoofFrame|SouthRoofWaterHouse|RailwayHotel|RenovationEast|RenovationNorth|RenovationWest|Construction_RenovationBlock|CourtUpperGallery|C13_(East|South|Expert|WestWing|NorthGallery|TerraceFoundation|TowerFoundation|TrackOffice))')
for r in inv['decoration']+inv['context']:
 n=r['name']
 if r['col'] or n in exclude:continue
 if n.startswith('CitySkyline'):
  shape(r,'V3_Skyline_'+str(1+len(plan)%4))
 elif building.match(n):
  if n.startswith('C13_'):a='V3_Terminal_Wing'
  elif 'Court' in n:a=['V3_LoggiaResidence','V3_CourtyardGallery'][len(plan)%2]
  elif 'Depot' in n or 'Renovation' in n:a=['V3_Brick_Broad','V3_Blue_Narrow','V3_AtelierHall'][len(plan)%3]
  else:a=['V3_Ochre_Narrow','V3_Coral_Wide','V3_Sage_Wide','V3_Cream_Tall','V3_Blue_Narrow'][len(plan)%5]
  shape(r,a,True)
 elif n.startswith('C13_Surface_') or n.startswith('DistrictRoofs_') or n.startswith('RoofGarden_'):
  shape(r,'V3_Terminal_Wing' if n.startswith('C13_') else 'V3_ShopBase',True)
 elif re.match(r'^(Tree[0-9]|MarketTree)',n):shape(r,'V3_Tree')
 elif 'Planter' in n:shape(r,'V3_Planter')
 elif re.match(r'^(Lamp|MarketLamp)',n):shape(r,'V3_Lamp')
 elif re.match(r'^Bench',n):shape(r,'V3_Bench')
 elif n.startswith('Depot_Parked'):shape(r,'V3_TrainCar')
 elif n=='WaterTankB':shape(r,'V3_WaterTank')
 elif n.startswith('Roof_ServiceBox'):shape(r,'V3_MaterialsStock')
# Terminal's enormous base is divided into reusable frontage bays, avoiding stretched window art.
for r in inv['decoration']:
 if r['name']=='C13_StationBase':
  remove.append(r['path'])
  for ix in range(5):
   for iz in range(6):
    if ix in [0,4] or iz in [0,5]:add('V3_Terminal_Wing',[3715+ix*30,0,68+iz*30],[30,74.5,30],label=f'TerminalBase_{ix}_{iz}')
  add('V3_FlatRoof_Broad',[3775,72.5,143],[150,2.5,180],label='TerminalBaseRoof',category='Roofs')
 if r['name']=='C13_MainHall':
  remove.append(r['path'])
  for z in [92,122,152,182]:add('V3_AtelierHall',[3785,74.5,z],[64,24.5,30],label='MainHall')
  add('V3_BarrelRoof',[3785,99,137],[66,8,122],label='MainHallRoof',category='Roofs')
 if r['name']=='C13_FinalStation':
  # Preserve finish sign and colonnade while replacing the massive distant clock and wings.
  pass
# Near-route district cues: placed on non-traversed shoulders, never on checkpoints.
for z in [224,202,119]:
 add('V3_Shopfront',[3297,0,z],[16,12,2.5],90,'MarketFront')
 add('V3_Awning_12',[3300.3,10,z],yaw=90,label='MarketAwning',category='Props')
for x,z in [(3400,-293),(3587,-293)]:add('V3_WorksiteHoarding',[x,64,z],yaw=90,label='WorksiteEdge',category='Props')
for x,z in [(3430,-290),(3600,-285)]:add('V3_MaterialsStock',[x,64,z],label='WorksiteStock',category='Props')
add('V3_MuralPanel',[3260,27,-48],[30,18,1.06],90,'CourtyardMural',category='Props')
add('V3_ServiceStock',[3719,74,-190],yaw=180,label='DepotStock',category='Props')
# Broad mural supplies a courtyard landmark without adding geometry to the jump lane.
add('V3_MuralPanel',[3401.7,55,-95],[26,16,1.06],270,'CourtEastMural',category='Props')
# Low-cost perimeter silhouettes close long views; all remain outside the course footprint.
for i,(x,z,h) in enumerate([(3210,-170,95),(3210,0,85),(3170,170,80),(3380,335,80),(3600,335,100),(3900,300,110),(3960,125,120),(3930,-90,100),(3810,-355,115),(3510,-388,115),(3270,-330,100)]):
 add('V3_Skyline_'+str(i%4+1),[x,0,z],[70,h,45],label='Perimeter_'+str(i),category='Architecture')
result={'build':'V3_STAGE2_02' ,'source':'Original footprint inventory; Optimized gameplay clone','placements':plan,'replacePaths':sorted(set(remove)),'heightCaps':caps,'scope':'Scenery only; dynamic gameplay and route markers retained'}
(ROOT/'stage2-layout.json').write_text(json.dumps(result,indent=2));print(json.dumps({'placements':len(plan),'replacedModels':len(set(remove)),'clearanceHeightCaps':len(caps),'triangles':sum(assets[p['asset']]['triangles']for p in plan)}))
