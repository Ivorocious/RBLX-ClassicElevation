import json
import math
from pathlib import Path

points=[]
for i in range(19):
    theta=math.radians(65+230*i/18);points.append((1.1*math.cos(theta),5.65+1.1*math.sin(theta)))
for i in range(19):
    theta=math.radians(267-174*i/18);points.append((.57+.99*math.cos(theta),5.65+.99*math.sin(theta)))

def orient(a,b,c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])

crossings=[]
for i in range(len(points)):
    a,b=points[i],points[(i+1)%len(points)]
    for j in range(i+1,len(points)):
        if j in {i,(i+1)%len(points)} or i==(j+1)%len(points):
            continue
        c,d=points[j],points[(j+1)%len(points)]
        if orient(a,b,c)*orient(a,b,d)<-1e-12 and orient(c,d,a)*orient(c,d,b)<-1e-12:
            crossings.append({'edgeA':i,'edgeB':j,'a':a,'b':b,'c':c,'d':d})
report={'asset':'MC_DT_HeraldicBanner','part':'MC_DT_HeraldicBanner__Brass','contourVertices':len(points),
        'properSelfCrossings':crossings,'pass':not crossings,
        'scope':'Exact recipe crescent cap contour only; finials and all other kit solids excluded. No production or uploaded file modified.'}
(Path(__file__).resolve().parent/'badge-contour-check.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
