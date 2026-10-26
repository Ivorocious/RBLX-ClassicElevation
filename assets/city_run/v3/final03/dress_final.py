import json
from pathlib import Path
F=Path('assets/city_run/v3/final03');p=F/'layout.json';d=json.loads(p.read_text());d['build']='V3_FINAL_03C'
for path in ['Context.DepthIllusionKit','Context.01_CloserFloorDepthFade']:
 if path not in d['replacePaths']: d['replacePaths'].append(path)
d['scope']='Scenery correction; preserved terminal consolidated per building; unused distant depth sample kit excluded, active horizon fade retained'
d['placements']=[r for r in d['placements'] if r['label'] not in {'RoofReservoir','RoofVentA','RoofVentB','CourtyardLandmark','FinishGardenLeft','FinishGardenRight'}]
def add(asset,pos,size,label,yaw=0):
 d['placements'].append(dict(asset=asset,pos=pos,size=size,label=label,yaw=yaw,category='Props'))
add('V3_WaterTank',[3310,92.99,-158],[8.4,13,8.4],'RoofReservoir')
add('V3_Chimney',[3338,92.99,-154],[4.8,6.3,4.8],'RoofVentA')
add('V3_Chimney',[3364,92.99,-163],[4.8,6.3,4.8],'RoofVentB')
add('V3_MuralPanel',[3265.4,27,-77],[24,12,1.06],'CourtyardLandmark',90)
add('V3_Planter',[3669,132.3,244],[8,5,3],'FinishGardenLeft')
add('V3_Planter',[3721,132.3,244],[8,5,3],'FinishGardenRight')
# Shallow visual trims stay on existing building faces and away from course platforms.
a=[]
def box(n,pos,size,color,material='SmoothPlastic'):
 a.append(dict(name=n,pos=pos,size=size,color=color,material=material))
navy=[27,43,55];bronze=[132,88,47];cream=[231,220,197];warm=[255,214,126]
box('RoofRearParapet',[3337.62,93.5,-141.3],[87,1.5,.55],cream)
box('RoofWestParapet',[3294.15,93.5,-161.24],[.55,1.5,40],cream)
box('RoofEastParapet',[3381.05,93.5,-161.24],[.55,1.5,40],cream)
for label,x,z,w,depth,y in [('Hall',3785,137,68,118,78),('EastArrival',3884,60,36,37,80),('EastArcade',3889,119,40,40,84),('EastCorner',3883,183,38,44,86)]:
 box(label+'PlinthFront',[x,y,z-depth/2-.15],[w,3.2,.32],navy)
 box(label+'PlinthSide',[x-w/2-.15,y,z],[.32,3.2,depth],navy)
 box(label+'BronzeFront',[x,y+1.7,z-depth/2-.2],[w,.2,.4],bronze)
for i,(x,y,z) in enumerate([(3865.5,94,46),(3865.5,94,72),(3868.5,103,107),(3868.5,103,131),(3679,145,260.7),(3711,145,260.7)]):
 if i<4:
  box('LanternBack'+str(i),[x-.35,y,z],[.65,3.7,2.4],navy)
  box('LanternGlow'+str(i),[x-.72,y,z],[.14,2.65,1.35],warm,'Neon')
 else:
  box('LanternBack'+str(i),[x,y,z-.35],[2.4,3.7,.65],navy)
  box('LanternGlow'+str(i),[x,y,z-.72],[1.35,2.65,.14],warm,'Neon')
d['accentParts']=a
p.write_text(json.dumps(d,indent=2));print(len(d['placements']),len(a))
