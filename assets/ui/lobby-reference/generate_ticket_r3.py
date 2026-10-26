"""Rasterize a new vector ticket shape with stepped shoulders and transparent notches."""
from pathlib import Path
import math
from PIL import Image, ImageDraw

folder = Path(__file__).resolve().parent
path = 'M30 2 H396 Q414 2 414 16 Q414 18 417 18 Q424 18 424 27 V46 C412 47 412 67 424 68 V94 Q424 104 415 104 Q414 104 414 108 Q414 120 398 120 H28 Q12 120 12 108 Q12 104 9 104 Q2 104 2 94 V68 C14 67 14 47 2 46 V27 Q2 18 9 18 Q12 18 12 16 Q12 2 30 2 Z'
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="426" height="122" viewBox="0 0 426 122">
<defs><linearGradient id="paper" x2="0" y2="1"><stop stop-color="#f0e7ff"/><stop offset=".92" stop-color="#d8caff"/><stop offset="1" stop-color="#b9a7ed"/></linearGradient></defs>
<path d="{path}" fill="url(#paper)" stroke="#061f50" stroke-width="4" stroke-linejoin="round"/>
<path d="M29 7H176 M17 18Q17 8 29 7 M7 29V41" fill="none" stroke="#fff" stroke-opacity=".8" stroke-width="2.5" stroke-linecap="round"/>
<path d="M28 114H396" stroke="#fff" stroke-opacity=".28" stroke-width="2"/>
</svg>'''
(folder/'panel-ticket-r3.svg').write_text(svg,encoding='utf-8')

scale=4
points=[]
current=(0,0)
def move(x,y):
    global current
    current=(x,y); points.append(current)
def curve(*controls):
    global current
    start=current
    for i in range(1,33):
        t=i/32; s=1-t
        vertices=[start,*controls]
        degree=len(vertices)-1
        points.append(tuple(sum(math.comb(degree,j)*s**(degree-j)*t**j*v[k] for j,v in enumerate(vertices)) for k in range(2)))
    current=controls[-1]
move(30,2);move(396,2);curve((414,2),(414,16));curve((414,18),(417,18));curve((424,18),(424,27));move(424,46)
curve((412,47),(412,67),(424,68));move(424,94);curve((424,104),(415,104));curve((414,104),(414,108));curve((414,120),(398,120))
move(28,120);curve((12,120),(12,108));curve((12,104),(9,104));curve((2,104),(2,94));move(2,68)
curve((14,67),(14,47),(2,46));move(2,27);curve((2,18),(9,18));curve((12,18),(12,16));curve((12,2),(30,2))
mask=Image.new('L',(426*scale,122*scale),0)
draw=ImageDraw.Draw(mask); scaled=[(round(x*scale),round(y*scale)) for x,y in points]
draw.polygon(scaled,fill=255)
image=Image.new('RGBA',mask.size,(0,0,0,0)); fill=Image.new('RGBA',mask.size)
row=ImageDraw.Draw(fill)
stops=[(0,(240,231,255)),(.92,(216,202,255)),(1,(185,167,237))]
for y in range(fill.height):
    t=y/(fill.height-1)
    a,b=next((a,b) for a,b in zip(stops,stops[1:]) if a[0]<=t<=b[0])
    f=(t-a[0])/(b[0]-a[0]); color=tuple(round(x+(z-x)*f) for x,z in zip(a[1],b[1]))
    row.line((0,y,fill.width,y),fill=(*color,255))
image.paste(fill,(0,0),mask)
draw=ImageDraw.Draw(image)
draw.line(scaled+[scaled[0]],fill=(6,31,80,255),width=4*scale,joint='curve')
draw.line([(29*scale,7*scale),(176*scale,7*scale)],fill=(255,255,255,204),width=2*scale)
draw.line([(7*scale,29*scale),(7*scale,41*scale)],fill=(255,255,255,204),width=2*scale)
image.resize((426,122),Image.LANCZOS).save(folder/'panel-ticket-r3.png')
print('Saved editable ticket SVG and426x122 transparent PNG')
