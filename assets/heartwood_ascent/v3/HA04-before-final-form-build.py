"""Heartwood HA04 connected form correction; preserves HA02 route coordinates and baseline assets."""
from pathlib import Path
import math, random, json, hashlib
ROOT=Path(__file__).resolve().parent
base=(ROOT.parent/'v1'/'build_assets.py').read_text()
prefix=base.split("for i,a in enumerate([-.3")[0]
prefix=prefix.replace("BUILD = 'HA_V1_01'","BUILD = 'HA_V1_04'")
prefix=prefix.replace("[color,1,2,color,3,color][i%6] if color<4 else color","(1 if i%13==0 and j%7==0 else color) if color<4 else color")
exec(prefix,globals())
random.seed(7304)

def ellipsoid(g,center,radius,color=0,segments=12,rings=7,phase=0):
    c=Vector(center);rx,ry,rz=radius;v=[tuple(c+Vector((0,ry,0)))]
    for j in range(1,rings):
        b=math.pi*j/rings
        for i in range(segments):
            a=math.tau*i/segments
            wobble=1+.055*math.sin(a*3+b*4+phase)+.035*math.cos(a*5-b*3)
            v.append(tuple(c+Vector((rx*math.sin(b)*math.cos(a)*wobble,ry*math.cos(b)*wobble,rz*math.sin(b)*math.sin(a)*wobble))))
    bottom=len(v);v.append(tuple(c-Vector((0,ry,0))));f=[]
    for i in range(segments):f.append((0,1+i,1+(i+1)%segments))
    for j in range(rings-2):
        for i in range(segments):
            a=1+j*segments+i;b=1+j*segments+(i+1)%segments
            f.append((a,a+segments,b+segments,b))
    for i in range(segments):f.append((bottom,bottom-segments+(i+1)%segments,bottom-segments+i))
    g.add(v,f,color)

levels=[(-9,112,72),(0,108,70),(18,98,66),(36,91,63),(60,85,61),(85,82,59),(110,79,56),(140,76,53),(175,68,47),(210,58,34),(260,50,25),(310,41,18),(360,32,13),(400,26,9),(442,20,5),(458,12,2)]
def open_band(theta,y):
    theta=theta%math.tau
    if y<38 and 2.5<theta<3.65:return True
    if 4<y<170 and 1.15<theta<1.98:return True
    if 38<y<94 and 5.16<theta<5.97:return True
    if 101<y<187 and 1.99<theta<3.15:return True
    return False
def shell(g,theta0,theta1,rows):
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
for i in range(16):
    a=math.tau*i/16;b=math.tau*(i+1)/16
    runs=[];run=[]
    for j in range(len(levels)-1):
        y=(levels[j][0]+levels[j+1][0])/2
        if not open_band((a+b)/2,y):
            if not run:run.append(levels[j])
            run.append(levels[j+1])
        elif run:runs.append(run);run=[]
    if run:runs.append(run)
    for k,rows in enumerate(runs):
        g=Geo();shell(g,a,b,rows);object_from(f'HA_Hollow_{i:02d}_{k:02d}',g,'structure')

for i in range(9):
    a=math.tau*i/9+.17;g=Geo();points=[];radii=[]
    for j in range(19):
        t=j/18;r=73+174*t;angle=a+.12*math.sin(t*math.pi)
        points.append((math.cos(angle)*r,19-88*t+13*math.sin(t*math.pi),math.sin(angle)*r))
        radii.append(27*(1-t)+4)
    g.tube(points,radii,0,18)
    object_from(f'HA_Buttress_{i:02d}',g,'structure')

branches=[
([(-46,132,36),(-70,147,36),(-109,154,28),(-141,170,20)],[18,15,10,4]),
([(56,48,-33),(78,57,-43),(101,62,-14),(111,66,28)],[18,14,10,5]),
([(48,67,56),(73,70,78),(60,77,94),(20,80,101)],[17,14,12,7]),
([(-37,111,72),(-65,118,116),(-107,121,111),(-128,126,75),(-96,130,48),(-67,132,56)],[17,13,11,10,9,6]),
([(38,226,-32),(87,261,-49),(147,291,-46),(195,310,-32)],[23,20,14,5]),
([(-28,268,21),(-77,301,50),(-132,329,55),(-185,343,27)],[23,19,13,5]),
([(18,344,-19),(66,377,-20),(118,408,-8)],[20,14,5]),
([(-12,383,17),(-49,417,35),(-91,447,28)],[17,12,4])]
for i,(ps,rs) in enumerate(branches):
    dense=[];radii=[]
    for j in range(len(ps)-1):
        for k in range(6):
            t=k/6;p0=Vector(ps[max(0,j-1)]);p1=Vector(ps[j]);p2=Vector(ps[j+1]);p3=Vector(ps[min(len(ps)-1,j+2)])
            p=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
            dense.append(tuple(p));radii.append(rs[j]*(1-t)+rs[j+1]*t)
    dense.append(ps[-1]);radii.append(rs[-1])
    g=Geo();g.tube(dense,radii,0,18);object_from(f'HA_Bough_{i:02d}',g,'structure')

def shelf(name,width,length,depth,n=28,tip=False,variant=0):
    g=Geo();v=[];f=[];colors=[]
    for layer in range(3):
        for i in range(n):
            a=math.tau*i/n
            x=math.copysign(abs(math.cos(a))**.43,math.cos(a))*width/2
            z=math.copysign(abs(math.sin(a))**.43,math.sin(a))*length/2
            warp=1+(.015 if tip else .045)*math.sin(a*(3+variant)+.3+variant*.7)
            scale=[1,.90-.04*variant,.48+.04*variant][layer]
            v.append((x*warp*scale,[0,-depth*.32,-depth][layer],z*warp*scale))
    center=len(v);v.append((0,0,0))
    bottom=len(v);v.append((0,-depth,0))
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
            ellipsoid(g,(math.cos(a)*width*.40,-depth*.5,math.sin(a)*length*.40),(width*.10,depth*.20,length*.13),0,8,4,i)
    object_from(name,g,'structure')
shelf('HA_ShelfWide',24,30,6.5)
shelf('HA_ShelfWideB',24,30,6.5,variant=1)
shelf('HA_ShelfWideC',24,30,6.5,variant=2)
shelf('HA_ShelfTip',6,5.5,3.5,24,True)

g=Geo();v=[];f=[]
for j in range(13):
    t=j/12;z=-15+30*t
    for i in range(20):
        a=-math.pi/2+math.tau*i/20
        v.append((math.sin(a)*6,0 if math.cos(a)>=0 else math.cos(a)*(6+.9*math.sin(t*math.pi)),z))
for j in range(12):
    for i in range(20):
        a=j*20+i;f.append((a,j*20+(i+1)%20,(j+1)*20+(i+1)%20,a+20))
f.extend([tuple(range(19,-1,-1)),tuple(240+i for i in range(20))])
g.add(v,f,0);object_from('HA_RootSpan',g,'structure')

g=Geo()
for i in range(18):
    a=math.tau*i/18
    ellipsoid(g,(math.cos(a)*3.7,math.sin(a)*5.5,0),(1.9,2.0,2.6),0,10,6,i)
g.tube([(-5,-5,2),(-3,-2,2.5),(0,4,2.2),(3,7,2)],[2.6,3,2.6,1.2],0,14)
object_from('HA_HeartwoodSocket',g,'structure')

def attached_cluster(g,center,scale,count):
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

def petal(g,radius,a,layer,color,finish):
    c=Vector((math.cos(a)*radius*.58,-.8+layer*.15,math.sin(a)*radius*.58))
    d=Vector((math.cos(a),0,math.sin(a)));side=Vector((-math.sin(a),0,math.cos(a)))
    length=radius*(.95 if layer==0 else .77);width=radius*(.72 if layer==0 else .58)
    entrance=finish and abs(math.atan2(math.sin(a-.40),math.cos(a-.40)))<.65
    rise=radius*(-.80 if entrance else .45)
    v=[]
    for skin in (0,1):
        for j in range(10):
            t=j/9;half=width*.5*max(.025,math.sin(math.pi*t))
            for k in (-1,0,1):
                p=c+d*(length*t)+side*(half*k)
                p.y+=rise*t**1.7+math.sin(math.pi*t)*radius*.10+(1-abs(k))*.02*radius-(.18 if skin else 0)
                v.append(tuple(p))
    f=[]
    for j in range(9):
        for k in range(2):
            b=j*3+k;f.extend([(b,b+1,b+4,b+3),(b+30,b+33,b+34,b+31)])
        b=j*3;f.extend([(b,b+3,b+33,b+30),(b+2,b+32,b+35,b+5)])
    f.extend([(0,30,31,1),(1,31,32,2),(27,28,58,57),(28,29,59,58)])
    g.add(v,f,color)
for name,radius,finish in [('HA_BloomBroad',11,False),('HA_BloomSmall',3,False),('HA_Sanctuary',17,True)]:
    g=Geo()
    for layer,count in ((0,12),(1,10)):
        for i in range(count):
            a=math.tau*i/count+layer*.23
            petal(g,radius,a,layer,10 if finish else [8,9,10][i%3],finish)
    g.tube([(0,-1.4,0),(0,.03,0)],[radius*.88,radius*.84],10 if finish else 9,40)
    for i in range(20):
        a=i*2.399;r=radius*math.sqrt((i+.5)/20)*.46
        g.tube([(math.cos(a)*r,.1,math.sin(a)*r),(math.cos(a)*r,.85,math.sin(a)*r)],[.12,.21],12,5)
    object_from(name,g,'flowers')

for package,objs in packages.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objs:obj.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.export_scene.fbx(filepath=str(ROOT/(package+'.fbx')),use_selection=True,object_types={'MESH'},
        path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y',add_leaf_bones=False)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'heartwood-HA04.blend'))
summary={'build':BUILD,'seed':7304,'units':'Roblox studs before import normalization','objects':records,
         'triangles':sum(x['triangles'] for x in records),'packages':{},
         'preserved':'HA02 route positions, movement settings, leaf/pod assets; corrective art only'}
for name in packages:
    p=ROOT/(name+'.fbx');summary['packages'][name]={'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(ROOT/'asset-manifest.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'build':BUILD,'objects':len(records),'triangles':summary['triangles'],'packages':list(packages)}),flush=True)
