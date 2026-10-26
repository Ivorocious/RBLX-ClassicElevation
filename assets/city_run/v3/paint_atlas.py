"""Author the shared opaque painted atlas; no downloaded texture dependencies."""
from pathlib import Path
import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
OUT=Path(__file__).resolve().parent
T=256
PALETTE={
'cream':(224,210,177),'ochre':(197,148,84),'coral':(186,112,87),'sage':(126,153,133),
'sky':(136,164,167),'slate':(78,96,106),'terracotta':(149,88,66),'teal':(49,117,118),
'iron':(49,64,68),'wood':(119,83,53),'leaf':(79,113,73),'leaflight':(123,145,88),
'gold':(203,161,73),'ink':(37,53,61),'stone':(169,161,143),'brick':(170,103,77)}
SPECIAL=['window_teal','window_brown','window_plain','arch_glass','shop_glass','roof_tile','wood_plank','metal_panel','mural','stripes_cream','stripes_teal','clock','sign_market','sign_depot','sign_terminal','sign_courtyard']
NAMES=list(PALETTE)+SPECIAL
rng=random.Random(20260916)
fontpath=Path('C:/Windows/Fonts/arialbd.ttf')
def font(n): return ImageFont.truetype(str(fontpath),n)
def painted(rgb,seed):
 r=random.Random(seed); small=Image.new('L',(16,16));small.putdata([r.randrange(105,151) for _ in range(256)])
 noise=small.resize((T,T),Image.BICUBIC).filter(ImageFilter.GaussianBlur(5))
 im=Image.new('RGB',(T,T)); pp=im.load();nn=noise.load()
 for y in range(T):
  for x in range(T):
   q=(nn[x,y]-128)*.72+(1-y/255)*12-5
   pp[x,y]=tuple(max(0,min(255,round(c+q))) for c in rgb)
 d=ImageDraw.Draw(im,'RGB')
 for _ in range(40):
  x=r.randrange(T);y=r.randrange(T);v=r.randint(-4,4)
  d.line((x,y,min(255,x+r.randrange(5,24)),y+r.randrange(-2,3)),fill=tuple(max(0,min(255,c+v)) for c in rgb),width=1)
 return im
atlas=Image.new('RGB',(2048,1024))
for k,name in enumerate(NAMES):
 rgb=PALETTE.get(name,(224,210,177));im=painted(rgb,k);d=ImageDraw.Draw(im)
 if name.startswith('window') or name in ('arch_glass','shop_glass'):
  d.rectangle((12,8,244,248),fill=(177,163,136));d.rectangle((20,14,238,241),fill=(235,222,189));d.rectangle((30,23,228,233),fill=(33,57,66))
  if name=='arch_glass':
   d.rectangle((30,23,228,95),fill=PALETTE['cream']);d.pieslice((30,23,228,171),180,360,fill=(33,57,66));d.rectangle((30,95,228,233),fill=(33,57,66))
  d.polygon([(38,34),(122,34),(122,213),(38,172)],fill=(66,99,108));d.polygon([(136,34),(218,34),(218,176),(136,217)],fill=(57,86,93))
  if name=='arch_glass': d.polygon([(30,23),(78,23),(30,83)],fill=PALETTE['cream']);d.polygon([(180,23),(228,23),(228,83)],fill=PALETTE['cream'])
  d.rectangle((123,26,133,232),fill=(220,201,158));d.rectangle((31,132,227,140),fill=(220,201,158));d.rectangle((22,237,242,248),fill=(246,228,184))
  if name in ('window_teal','window_brown'):
   col=PALETTE['teal' if name=='window_teal' else 'wood']
   for a,b in [(8,61),(199,249)]:
    d.rectangle((a,17,b,229),fill=col)
    for y in range(30,225,18):d.line((a+5,y,b-4,y),fill=tuple(max(0,c-17) for c in col),width=3);d.line((a+5,y+4,b-4,y+4),fill=tuple(min(255,c+13) for c in col),width=2)
 elif name=='brick':
  for y in range(0,T,32):
   d.line((0,y,256,y),fill=(185,143,110),width=3)
   for x in range(-64 if (y//32)%2 else 0,256,96):d.line((x,y,x,y+32),fill=(185,143,110),width=2)
 elif name=='roof_tile':
  im=painted(PALETTE['terracotta'],k);d=ImageDraw.Draw(im)
  for y in range(0,T,43):
   d.line((0,y,256,y),fill=(102,62,51),width=4)
   for x in range(-22 if (y//43)%2 else 0,T,44):d.arc((x,y-15,x+43,y+36),0,180,fill=(192,126,85),width=4)
 elif name=='wood_plank':
  im=painted(PALETTE['wood'],k);d=ImageDraw.Draw(im)
  for x in range(0,T,64):
   d.line((x,0,x,256),fill=(70,55,43),width=3);d.line((x+5,0,x+5,256),fill=(161,116,71),width=2)
   for y in (17,239):d.ellipse((x+11,y,x+14,y+3),fill=(43,50,49))
 elif name=='metal_panel':
  im=painted(PALETTE['slate'],k);d=ImageDraw.Draw(im)
  for x in range(8,T,48):d.line((x,0,x,256),fill=(112,128,128),width=3);d.line((x+4,0,x+4,256),fill=(51,71,79),width=2)
 elif name=='mural':
  im=painted((174,185,157),k);d=ImageDraw.Draw(im)
  d.ellipse((164,20,224,80),fill=(225,184,86));d.polygon([(0,215),(61,100),(119,179),(159,132),(256,222)],fill=(93,128,119));d.polygon([(0,235),(105,179),(181,203),(256,161),(256,256),(0,256)],fill=(65,106,112));d.arc((36,50,220,300),190,288,fill=(224,213,179),width=15)
 elif name.startswith('stripes'):
  im=painted(PALETTE['cream'],k);d=ImageDraw.Draw(im);col=PALETTE['gold' if name.endswith('cream') else 'teal']
  for x in range(0,T,64): d.rectangle((x,0,x+31,255),fill=col)
 elif name=='clock':
  im=painted(PALETTE['cream'],k);d=ImageDraw.Draw(im);d.ellipse((8,8,248,248),fill=(229,217,181),outline=PALETTE['iron'],width=8)
  for i in range(12):
   a=i*math.tau/12;d.line((128+94*math.sin(a),128-94*math.cos(a),128+108*math.sin(a),128-108*math.cos(a)),fill=PALETTE['iron'],width=5)
  d.line((75,94,128,128,172,65),fill=PALETTE['iron'],width=7);d.ellipse((122,122,134,134),fill=PALETTE['iron'])
 elif name.startswith('sign'):
  im=painted(PALETTE['teal'] if name!='sign_depot' else PALETTE['slate'],k);d=ImageDraw.Draw(im);d.rectangle((8,60,248,196),outline=(214,184,114),width=3)
  word={'sign_market':'MARKET','sign_depot':'DEPOT','sign_terminal':'RIVERSIDE','sign_courtyard':'COURTYARD'}[name]
  d.text((128,127),word,font=font(27 if len(word)>7 else 36),anchor='mm',fill=(242,225,186))
 atlas.paste(im,((k%8)*T,(k//8)*T))
atlas.save(OUT/'painted_atlas.png')
import json
(OUT/'atlas.json').write_text(json.dumps({'size':[2048,1024],'tileSize':256,'tiles':{n:[(i%8)*T,(i//8)*T,T,T] for i,n in enumerate(NAMES)},'opaque':True,'seed':20260916},indent=2))
print('Atlas authored: 32 shared tiles, 2048x1024 RGB, fully opaque')

