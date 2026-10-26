from pathlib import Path
import shutil
root=Path('assets/city_run/v3');out=Path('docs/artifacts/city-run/v3');snap=out/'round01';snap.mkdir(exist_ok=True)
for p in out.glob('kit_*.png'):shutil.copy2(p,snap/p.name)
for p in [root/'manifest.json',out/'asset-audit.json']:shutil.copy2(p,snap/p.name)
p=root/'paint_atlas.py';s=p.read_text(encoding='utf-8-sig').replace('(nn[x,y]-128)*.22+(1-y/255)*5-2','(nn[x,y]-128)*.72+(1-y/255)*12-5');p.write_text(s)
p=root/'build_asset_kit.py';s=p.read_text(encoding='utf-8-sig').replace("BUILD='V3_KIT_01'","BUILD='V3_KIT_02'")
s=s.replace("ob['V3AssetId']=name;", "bpy.context.view_layer.objects.active=ob\n  if family in ('Architecture','Landmarks','Roofs'):\n   mod=ob.modifiers.new('Soft silhouette edges','BEVEL');mod.width=.055;mod.segments=1;mod.limit_method='ANGLE'\n   bpy.ops.object.modifier_apply(modifier=mod.name);mesh=ob.data\n  ob['V3AssetId']=name;")
s=s.replace("for z in (1,h-1):g.box((0,0,z),(w+.7,d+.7,.9),'cream')", "for z in (1,h-1):g.box((0,0,z),(w+.7,d+.7,.9),'cream')\n g.box((0,0,h-.35),(w+1.1,d+1.1,.7),'cream')\n g.box((0,-d/2-.13,1),(w,.25,2),'stone')")
s=s.replace("for sign in (-1,1):g.window(x,sign*(d/2+.045),z,5.8,8, 'arch_glass' if terminal else window,0 if sign==-1 else math.pi)", "for sign in (-1,1):\n    pane='arch_glass' if terminal else window\n    if z==7 and sign==-1:pane='shop_glass' if abs(x)<5 else 'arch_glass'\n    g.window(x,sign*(d/2+.045),z,5.8,10 if z==7 else 8,pane,0 if sign==-1 else math.pi)\n    if z>7:g.box((x,sign*(d/2+.24),z-4.2),(6,.5,.3),'cream')")
insert="""
# Alternative facade grammars and district anchors share the same texture/material.
for name,col,w in [('LoggiaResidence','cream',30),('CourtyardGallery','ochre',24)]:
 g=Geo();g.box((0,0,24),(w,20,48),col)
 for z in (1,24,47):g.box((0,0,z),(w+1,21,.8),'cream')
 for x in (-w/2+.5,0,w/2-.5):g.box((x,-10.2,24),(.65,.5,48),'cream')
 for z in (8,20,32,43):
  for x in (-w/3,0,w/3):g.window(x,-10.05,z,7,9,'arch_glass' if name=='LoggiaResidence' else 'window_brown');g.box((x,-10.4,z-4.6),(7.4,.8,.4),'cream')
  for sign in (-1,1):
   for y in (-5,5):g.window(sign*(w/2+.05),y,z,6,8,'window_plain',math.pi/2 if sign==1 else -math.pi/2)
  for x in (-w/3,0,w/3):g.window(x,10.05,z,6,8,'window_plain',math.pi)
 g.finish('V3_'+name,'Architecture','Mid','Alternative vertical-pier facade grammar.')
g=Geo();g.box((0,0,5),(24,20,10),'brick');g.box((0,0,10),(25,21,1),'cream')
for x in (-8,0,8):g.window(x,-10.08,5,6,8,'shop_glass')
g.finish('V3_ShopBase','Openings','Close','Independent grounded shop level.')
g=Geo();g.arch(18,13,3,1.5,'sage');g.box((0,0,13),(20,4,.7),'cream');g.window(0,-1.56,11.2,8,2.1,'sign_courtyard');g.finish('V3_GardenPortal','Landmarks')
g=Geo();g.cyl((0,0,0),5,.65,'stone',12);g.cyl((0,0,.65),4.5,1.1,'cream',12);g.cyl((0,0,1.8),1.2,3,'stone',10);g.cyl((0,0,4.8),2.4,.6,'cream',12);g.finish('V3_CourtyardFountain','Street','Close','Dry sculptural fountain; no transparent water or particles.')
g=Geo()
for x in (-10,-3.3,3.3,10):g.box((x,0,6),(1.2,1.5,12),'cream');g.box((x,0,.45),(1.8,2,.9),'stone');g.box((x,0,11.6),(1.8,2,.8),'stone')
g.box((0,0,12.5),(24,3,1.5),'cream');g.finish('V3_TerminalColonnade','Landmarks')
g=Geo();w=25;d=21
vs=[(-w/2,-d/2,0),(w/2,-d/2,0),(w/2,d/2,0),(-w/2,d/2,0),(-8,-6,5),(8,-6,5),(8,6,5),(-8,6,5)]
g.add(vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'slate');g.finish('V3_MansardRoof','Roofs','Mid')
g=Geo();profile=[(-12,0),(12,0)]+[(12*math.cos(i*math.pi/10),4*math.sin(i*math.pi/10))for i in range(11)]
# Deduplicate the right base corner before extruding the shallow barrel.
profile=[(-12,0)]+[(12*math.cos(i*math.pi/10),4*math.sin(i*math.pi/10))for i in range(11)]
profile=profile[:-1];n=len(profile);vs=[(x,y,z)for y in (-10,10)for x,z in profile]
g.add(vs,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n)for i in range(n)],'metal_panel');g.finish('V3_BarrelRoof','Roofs','Mid')
"""
s=s.replace('# Export every unique mesh once;',insert+'\n# Export every unique mesh once;')
s=s.replace("g.add(vs,fs,'iron');g.finish('V3_WreckingBallSkin'", "g.add(vs,fs,'iron');g.beam((-.65,0,9.8),(-.65,0,11.8),.45,'iron');g.beam((.65,0,9.8),(.65,0,11.8),.45,'iron');g.beam((-.65,0,11.8),(.65,0,11.8),.45,'iron');g.finish('V3_WreckingBallSkin'")
s=s.replace("g.box((0,0,h*.8),(w*.87,l*.62,h*.4),col)", "g.add([(-w*.43,-l*.31,h*.6),(w*.43,-l*.31,h*.6),(w*.43,l*.31,h*.6),(-w*.43,l*.31,h*.6),(-w*.38,-l*.22,h),(w*.38,-l*.22,h),(w*.38,l*.22,h),(-w*.38,l*.22,h)],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],col)")
# Glass follows the sloped cabin and cannot float beyond the roof prism.
s=s.replace("g.window(0,y,h*.8,w*.73,h*.3,'shop_glass',0 if y<0 else math.pi)", "g.add([(-w*.34,y,h*.62),(w*.34,y,h*.62),(w*.34,y*.71,h*.97),(-w*.34,y*.71,h*.97)],[(0,1,2,3)],'shop_glass')")
s=s.replace("g.window(x,y,h*.8,3,h*.3,'window_plain',math.pi/2 if x>0 else -math.pi/2)", "g.window(x*.92,y,h*.8,3,h*.3,'window_plain',math.pi/2 if x>0 else -math.pi/2)")
s=s.replace("g.box((0,-l/2-.02,h*.4),(w*.9,.2,.45),'cream');", "g.box((0,-l/2-.02,h*.4),(w*.9,.2,.45),'cream')\n for x in (-w*.3,w*.3):g.box((x,-l/2-.15,h*.48),(w*.16,.25,.7),'gold')\n if name=='TrainCar':g.box((0,l/2+1,h*.45),(w*.6,2,h*.6),'ink');g.box((0,-l/2-.8,1),(2,1.6,.6),'iron')\n g.box((0,-l/2-.1,h*.26),(w*.55,.22,.6),'iron');")
s=s.replace("g.box((0,0,h+2),(w*.6,d*.6,3),'stone')", "g.box((0,0,h+2),(w*.6,d*.6,3),'stone')\n if i==0:g.box((-w*.2,0,h+5),(w*.45,d*.6,6),'stone')\n elif i==1:g.cyl((0,0,h+3),4,7,'slate',8)\n elif i==2:g.box((0,0,h+6),(w*.6,d*.7,8),'sky');g.box((0,0,h+11),(w*.32,d*.4,3),'cream')\n else:\n  for x in (-w*.3,w*.3):g.box((x,0,h+5),(w*.22,d*.6,6),'sage')")
p.write_text(s)
print('Updated V3_KIT_02 builder and preserved round01 evidence')
