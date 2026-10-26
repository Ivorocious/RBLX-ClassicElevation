"""Derive the bounded HA04 kit while retaining the accepted mechanics assets."""
from pathlib import Path

root = Path(__file__).resolve().parent
source = (root.parent / 'v2/build_assets.py').read_text()
source = source.replace('Heartwood HA03 form correction', 'Heartwood HA04 connected form correction')
source = source.replace("BUILD = 'HA_V1_03'", "BUILD = 'HA_V1_04'")
source = source.replace('7303', '7304').replace('heartwood-HA03.blend', 'heartwood-HA04.blend')
start = source.index('def shell(')
end = source.index('for i in range(16):', start)
source = source[:start] + '''def shell(g,theta0,theta1,rows):
    dense=[]
    for j in range(len(rows)-1):
        first,last=rows[j],rows[j+1]
        count=max(1,math.ceil((last[0]-first[0])/9))
        for k in range(count):
            t=k/count;dense.append(tuple(first[d]*(1-t)+last[d]*t for d in range(3)))
    dense.append(rows[-1]);v=[];n=9
    for y,outer,inner in dense:
        for skin,rad in enumerate((outer,inner)):
            for k in range(n):
                a=theta0+(theta1-theta0)*k/(n-1)
                twist=.035*math.sin(y/90)+.018*math.sin(a*3+y/57)
                shape=1+.045*math.sin(a*3)+.022*math.cos(a*5+y/60)
                flute=math.sin(a*34-y*.021)+.45*math.sin(a*63+y*.035)
                clearance=max(0,min(1,(210-y)/25))
                r=rad*shape+(3.3+1.5*flute if skin else 2.5*flute-5*clearance)
                v.append((math.cos(a+twist)*r,y,math.sin(a+twist)*r-5*max(0,y)/458))
    f=[];colors=[];stride=n*2
    for j in range(len(dense)-1):
        for k in range(n-1):
            a=j*stride+k
            f.append((a,a+1,a+stride+1,a+stride));colors.append(0 if k%5 else 2)
            a+=n
            f.append((a,a+stride,a+stride+1,a+1));colors.append(0 if k%4 else 2)
        for k in (0,n-1):
            a=j*stride+k
            f.append((a,a+stride,a+stride+n,a+n));colors.append(0)
    for j in (0,len(dense)-1):
        for k in range(n-1):
            a=j*stride+k
            f.append((a,a+n,a+n+1,a+1));colors.append(0)
    g.add(v,f,colors)
    # Ribs remain behind the original inner wall, preserving the route opening.
    for skin in (0,1):
        points=[];radii=[]
        for y,outer,inner in dense:
            a=(theta0+theta1)/2+.075*math.sin(y/63+theta0*2)
            twist=.035*math.sin(y/90)+.018*math.sin(a*3+y/57)
            shape=1+.045*math.sin(a*3)+.022*math.cos(a*5+y/60)
            clearance=max(0,min(1,(210-y)/25))
            radius=(inner*shape+6.4 if skin else outer*shape+2.8-8*clearance)
            points.append((math.cos(a+twist)*radius,y,math.sin(a+twist)*radius-5*max(0,y)/458))
            radii.append(2.7 if skin else 4.7)
        g.tube(points,radii,0,8)
''' + source[end:]
source = source.replace('def shelf(name,width,length,depth,n=28,tip=False):', 'def shelf(name,width,length,depth,n=28,tip=False,variant=0):')
source = source.replace("warp=1+(.015 if tip else .045)*math.sin(a*3+.3)", "warp=1+(.015 if tip else .045)*math.sin(a*(3+variant)+.3+variant*.7)")
source = source.replace("scale=[1,.92,.48][layer]", "scale=[1,.90-.04*variant,.48+.04*variant][layer]")
source = source.replace("shelf('HA_ShelfWide',24,30,6.5)", "shelf('HA_ShelfWide',24,30,6.5)\nshelf('HA_ShelfWideB',24,30,6.5,variant=1)\nshelf('HA_ShelfWideC',24,30,6.5,variant=2)")
start = source.index('def shelf(')
end = source.index("shelf('HA_ShelfWide'", start)
source = source[:start] + '''def shelf(name,width,length,depth,n=28,tip=False,variant=0):
    g=Geo();v=[];f=[];colors=[]
    for layer in range(3):
        for i in range(n):
            a=math.tau*i/n
            x=math.copysign(abs(math.cos(a))**.43,math.cos(a))*width/2
            z=math.copysign(abs(math.sin(a))**.43,math.sin(a))*length/2
            warp=1+(.015 if tip else .045)*math.sin(a*(3+variant)+.3+variant*.7)
            scale=[1,.90-.04*variant,.48+.04*variant][layer]
            y=[0,-depth*.32,-depth][layer];px=x*warp*scale;pz=z*warp*scale
            if variant==1 and layer>0:
                px=x*warp*(.76+.10*math.cos(a+.7) if layer==1 else .24)-width*(.04 if layer==1 else .13)
                pz=z*warp*(.83 if layer==1 else .55)
                y=-depth*(.14+.24*(.5+.5*math.cos(a-.8))) if layer==1 else -depth
            elif variant==2 and layer>0:
                px=x*warp*(.60+.22*abs(math.sin(a)) if layer==1 else .62)
                pz=z*warp*(.70 if layer==1 else .18)+length*(.025 if layer==1 else .08)
                y=-depth*(.40+.08*math.sin(a*3)) if layer==1 else -depth
            v.append((px,y,pz))
    center=len(v);v.append((0,0,0))
    bottom=len(v);v.append((-width*.13 if variant==1 else 0,-depth,length*.08 if variant==2 else 0))
    for i in range(n):
        j=(i+1)%n
        f.append((center,i,j));colors.append(0)
        for layer in range(2):
            f.append((layer*n+i,(layer+1)*n+i,(layer+1)*n+j,layer*n+j));colors.append(0)
        f.append((bottom,2*n+j,2*n+i));colors.append(2)
    g.add(v,f,colors)
    if not tip:
        for i in range(9):
            a=i*2.399
            if variant==0:
                center=(math.cos(a)*width*.40,-depth*.5,math.sin(a)*length*.40);radii=(width*.10,depth*.20,length*.13)
            elif variant==1:
                center=(-width*.22+math.cos(a)*width*.09,-depth*.53,math.sin(a)*length*.28);radii=(width*.06,depth*.27,length*.10)
            else:
                center=(math.cos(a)*width*.28,-depth*.64,length*.06+math.sin(a)*length*.12);radii=(width*.11,depth*.16,length*.09)
            ellipsoid(g,center,radii,0,8,4,i)
    if variant:
        reference=json.loads((ROOT/'HA04-before-final-form-manifest.json').read_text())
        bounds=next(row for row in reference['objects'] if row['name']==name)
        # Fit only the underside so normalization preserves the exact original top ring.
        for axis in (0,1):
            lower=[p[axis] for p in g.v if p[2]<-.001];minimum=min(lower);maximum=max(lower)
            low=bounds['bounds_min'][axis];high=bounds['bounds_max'][axis]
            g.v=[tuple(low+(p[axis]-minimum)*(high-low)/(maximum-minimum) if k==axis and p[2]<-.001 else p[k] for k in range(3)) for p in g.v]
    object_from(name,g,'structure')
''' + source[end:]
start = source.index('for variant in range(3):')
end = source.index('def petal(', start)
source = source[:start] + '''def attached_cluster(g,center,scale,count):
    c=Vector(center)
    for i in range(count):
        a=i*2.399;layer=i%3
        p=c+Vector((math.cos(a)*scale*.11,(layer-1)*scale*.10,math.sin(a)*scale*.11))
        d=Vector((math.cos(a),.10+.12*math.sin(i),math.sin(a))).normalized()
        side=Vector((-d.z,0,d.x)).normalized()
        length=scale*(.39+.06*math.sin(i*1.7));width=length*.65
        points=[p,p+d*length*.5+side*width*.5,p+d*length+Vector((0,scale*.045,0)),p+d*length*.5-side*width*.5,p+d*length*.5+Vector((0,width*.16,0))]
        lower=[q-Vector((0,.12,0)) for q in points]
        g.add([tuple(q) for q in points+lower],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(5,9,6),(6,9,7),(7,9,8),(8,9,5),
            (0,5,6,1),(1,6,7,2),(2,7,8,3),(3,8,5,0)],[4,5,5,6][i%4])

for variant in range(3):
    g=Geo();count=[28,24,22][variant]
    attached_cluster(g,(0,-1 if variant==2 else 0,0),8,count)
    for i in range(5 if variant<2 else 4):
        a=i*2.399+variant;drop=-i*.55 if variant==2 else 0
        ellipsoid(g,(math.cos(a)*1.8,drop,math.sin(a)*1.8),(2.4,1.15,2.2),[4,5,6][i%3],6,3,i)
    object_from(['HA_FoliageMassA','HA_FoliageMassB','HA_HangingMass'][variant],g,'foliage')

def forest(name,height,radius,tiers,leaves,variant):
    g=Geo();points=[];radii=[]
    for j in range(12):
        t=j/11
        points.append((math.sin(t*2.7+variant)*radius*.09,height*t,math.sin(t*3.1+variant*.7)*radius*.08))
        radii.append(radius*(.15*(1-t)+.02))
    g.tube(points,radii,0,10 if tiers>3 else 7)
    for i in range(4):
        a=i*math.tau/4+variant
        g.tube([(math.cos(a)*radius*.40,0,math.sin(a)*radius*.40),(math.cos(a)*radius*.19,3,math.sin(a)*radius*.19),points[1]],[1.6,4,radius*.1],0,6)
    for tier in range(tiers):
        t=.47+.43*tier/max(1,tiers-1);y=height*t
        for side in range(2):
            a=tier*2.399+side*math.pi+variant;reach=radius*(.82-.30*tier/max(1,tiers-1))
            inner=(points[int(t*11)][0],y,points[int(t*11)][2])
            tip=(inner[0]+math.cos(a)*reach,y+height*.025,inner[2]+math.sin(a)*reach)
            g.tube([inner,(inner[0]+math.cos(a)*reach*.5,y+height*.06,inner[2]+math.sin(a)*reach*.5),tip],[radius*.045,radius*.033,1.1],0,6)
            center=(tip[0]*.80,tip[1]+3,tip[2]*.80)
            attached_cluster(g,center,radius*.65,leaves)
            ellipsoid(g,center,(radius*.46,height*.075,radius*.44),5,6,3,tier+side)
    attached_cluster(g,(points[-1][0],height-5,points[-1][2]),radius*.8,leaves)
    reference=json.loads((ROOT/'HA04-before-final-form-manifest.json').read_text())
    bounds=next(row for row in reference['objects'] if row['name']==name)
    # Preserve the tested horizontal forest envelope while filling the crown volume.
    for axis in (0,1):
        minimum=min(p[axis] for p in g.v);maximum=max(p[axis] for p in g.v)
        low=bounds['bounds_min'][axis];high=bounds['bounds_max'][axis]
        g.v=[tuple(low+(p[axis]-minimum)*(high-low)/(maximum-minimum) if k==axis else p[k] for k in range(3)) for p in g.v]
    object_from(name,g,'foliage')
forest('HA_ForestNearA',330,64,5,13,0)
forest('HA_ForestNearB',335,65,5,13,1.7)
forest('HA_ForestMid',260,55,4,7,.8)
forest('HA_ForestFar',220,38,3,4,2.2)
g=Geo()
ellipsoid(g,(0,-180,0),(820,10,800),15,40,8)
ellipsoid(g,(0,-147,0),(310,68,295),15,32,10)
ellipsoid(g,(0,-89,0),(130,44,125),15,24,8)
object_from('HA_ForestGround',g,'structure')

''' + source[end:]
(root/'build_assets.py').write_text(source)
print('Generated HA04 source; baseline route asset definitions retained.')
