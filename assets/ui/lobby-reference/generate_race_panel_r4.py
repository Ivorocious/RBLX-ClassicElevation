"""Draw a rounded race panel with a sculpted blue spine, ready for Roblox 9-slice."""
from pathlib import Path
from PIL import Image, ImageDraw

folder = Path(__file__).resolve().parent
svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="426" height="190" viewBox="0 0 426 190">
<defs>
<linearGradient id="blue" x2="1" y2="0"><stop stop-color="#0c59ed"/><stop offset=".45" stop-color="#3c9bff"/><stop offset=".8" stop-color="#1777ff"/><stop offset="1" stop-color="#134adc"/></linearGradient>
<linearGradient id="cream" x2="0" y2="1"><stop stop-color="#fffbed"/><stop offset=".95" stop-color="#fff9e7"/><stop offset="1" stop-color="#e5dcca"/></linearGradient>
<clipPath id="body"><rect x="2" y="2" width="422" height="186" rx="21"/></clipPath>
</defs>
<g clip-path="url(#body)">
<rect x="2" y="2" width="422" height="186" rx="21" fill="url(#blue)"/>
<rect x="20" y="2" width="404" height="186" fill="url(#cream)"/>
<path d="M21 3V187" stroke="#063da4" stroke-width="2"/>
<path d="M7 30Q7 8 28 7" fill="none" stroke="#8fd9ff" stroke-width="3" stroke-linecap="round"/>
<path d="M8 43L13 47L8 77L9 55L6 55Z" fill="#fff"/>
<path d="M7 85V163Q7 180 20 182" fill="none" stroke="#51b7ff" stroke-opacity=".65" stroke-width="2"/>
<path d="M29 7H401Q419 7 419 23" fill="none" stroke="#fff" stroke-opacity=".65" stroke-width="2"/>
</g>
<rect x="2" y="2" width="422" height="186" rx="21" fill="none" stroke="#061f50" stroke-width="3.5"/>
</svg>'''
(folder / 'race-panel-r4.svg').write_text(svg, encoding='utf-8')
scale = 4
image = Image.new('RGBA', (426*scale, 190*scale), (0,0,0,0))
mask = Image.new('L', image.size, 0)
d = ImageDraw.Draw(mask)
d.rounded_rectangle((2*scale,2*scale,424*scale,188*scale), radius=21*scale, fill=255)
fill = Image.new('RGBA', image.size, (255,249,231,255))
draw = ImageDraw.Draw(fill)
blue = [(12,89,237),(60,155,255),(23,119,255),(19,74,220)]
for x in range(2*scale,21*scale):
    t=(x-2*scale)/(19*scale); index=min(2,int(t*3)); f=t*3-index
    rgb=tuple(round(a+(b-a)*f) for a,b in zip(blue[index],blue[index+1]))
    draw.line((x,0,x,190*scale), fill=(*rgb,255))
draw.line((21*scale,0,21*scale,190*scale),fill=(6,61,164,255),width=2*scale)
for y in range(188*scale):
    t=y/(188*scale); f=max(0,(t-.95)/.05)
    rgb=tuple(round(a+(b-a)*f) for a,b in zip((255,249,231),(229,220,202)))
    draw.line((22*scale,y,426*scale,y),fill=(*rgb,255))
image.paste(fill,(0,0),mask)
draw = ImageDraw.Draw(image)
draw.rounded_rectangle((2*scale,2*scale,424*scale,188*scale), radius=21*scale, outline=(6,31,80,255), width=round(3.5*scale))
draw.arc((7*scale,7*scale,49*scale,49*scale),180,270,fill=(143,217,255,255),width=3*scale)
draw.line((7*scale,29*scale,7*scale,41*scale),fill=(143,217,255,255),width=3*scale)
draw.polygon([(x*scale,y*scale) for x,y in [(8,43),(13,47),(8,77),(9,55),(6,55)]],fill=(255,255,255,255))
draw.line((7*scale,85*scale,7*scale,165*scale),fill=(81,183,255,255),width=2*scale)
draw.line((29*scale,7*scale,401*scale,7*scale),fill=(255,255,255,255),width=2*scale)
image.resize((426,190),Image.LANCZOS).save(folder / 'race-panel-r4.png')
print('Saved editable race panel SVG and 426x190 transparent PNG')
