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
            ellipsoid(g,center,(radius*.32,height*.035,radius*.31),5,6,3,tier+side)
    attached_cluster(g,(points[-1][0],height-5,points[-1][2]),radius*.8,leaves)
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
