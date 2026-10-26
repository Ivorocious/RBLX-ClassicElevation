"""Detail the surfaces seen from the race, keeping the distant city inexpensive."""
import math
import random


def foliage(api,p,r=1.4,seed=0,flowers=False):
    rng=random.Random(seed)
    x,y,z=p
    for i in range(9):
        a=rng.random()*math.tau;rad=r*rng.uniform(.2,.8)
        q=(x+math.cos(a)*rad,y+rng.uniform(0,r*.65),z+math.sin(a)*rad)
        api['sphere']('Leaf' if i%3 else 'LeafLight',q,r*rng.uniform(.35,.6),8,5,(1,.75,1))
        if flowers and i%2==0:
            for j in range(5):
                b=j*math.tau/5
                api['sphere']('Coral' if i%3 else 'Yellow',(q[0]+.19*math.cos(b),q[1]+r*.4,q[2]+.19*math.sin(b)),.17,6,3)


def streetside_facades(api,name,x,z,w,d,h,base):
    box,beam,geo,text=(api[k] for k in ('box','beam','geo','text'))
    route=api['layout'].SURFACES
    seed=sum(map(ord,name));variant=seed%3
    for nx,nz,span,ox,oz in [(1,0,d,x+w/2,z),(-1,0,d,x-w/2,z),(0,1,w,x,z+d/2),(0,-1,w,x,z-d/2)]:
        near=[s for s in route if (s['p'][0]-ox)*nx+(s['p'][2]-oz)*nz>=-2
              and abs((s['p'][0]-ox)*nz-(s['p'][2]-oz)*nx)<span/2+28
              and abs((s['p'][0]-ox)*nx+(s['p'][2]-oz)*nz)<65]
        if not near:continue
        def point(u,y,n=0):return (ox+u*nz+n*nx,y,oz-u*nx+n*nz)
        def plate(mat,u,y,n,su,sy,sn):
            box(mat,point(u,y,n),(sn,sy,su) if nx else (su,sy,sn))
        if name.startswith('Station'):
            # Tall arched station bays replace the residential shutter pattern.
            count=max(1,int(span/16));pitch=span/count
            for y in range(int(base)+13,int(base+h)-8,22):
                for j in range(count):
                    u=-span/2+pitch*(j+.5)
                    verts=[point(u-4.2,y-8,.4),point(u+4.2,y-8,.4)]
                    verts += [point(u+4.2*math.cos(i*math.pi/16),y+3+4.2*math.sin(i*math.pi/16),.4) for i in range(17)]
                    geo('Glass',verts,[tuple(range(len(verts))),tuple(reversed(range(len(verts))))])
                    for side in (-1,1):beam('Cream',point(u+side*4.6,y-8,.55),point(u+side*4.6,y+3,.55),.35,8)
                    for i in range(16):
                        a=i*math.pi/16;b=(i+1)*math.pi/16
                        beam('Cream',point(u+4.6*math.cos(a),y+3+4.6*math.sin(a),.55),
                             point(u+4.6*math.cos(b),y+3+4.6*math.sin(b),.55),.35,8)
                    plate('Cream',u,y-8.2,.6,10,.6,1.2)
                    for uu in (u-1.4,u+1.4):plate('Cream',uu,y-1.5,.58,.22,13,.22)
                    for yy in (y-4,y+1):plate('Cream',u,yy,.58,8.4,.22,.22)
                plate('Terracotta',0,y+9,.3,span,.7,.6)
            for u in (-span/2+.8,span/2-.8):plate('Cream',u,base+h/2,.3,1.7,h,.9)
            continue
        count=max(1,int(span/10));pitch=span/count
        for floor in range(max(1,int(h/11))):
            y=base+6+floor*11
            if y+4>base+h:continue
            # The upper silhouette stays simple when every nearby landing is much lower.
            detailed=min(abs(s['p'][1]+4-y) for s in near)<23
            for j in range(count):
                u=-span/2+pitch*(j+.5);wide=3.5 if variant else 4.2
                plate('Cream',u,y,.18,wide+1,7.4,.5)
                plate('Iron',u,y+.1,.46,wide+.25,6.7,.15)
                plate('Glass' if (j+floor+seed)%5 else 'WindowGlow',u,y+.15,.56,wide,6.3,.10)
                plate('Cream',u,y+.15,.64,.16,6.3,.16)
                plate('Cream',u,y+.2,.64,wide,.18,.16)
                plate('Cream',u,y-3.8,.7,wide+1.6,.65,1.45)
                plate('Cream',u,y+4,.32,wide+1.8,.5,.8)
                if not detailed:continue
                plate('WoodDark',u-wide*.32,y+.2,.59,.4,5.9,.12)
                if (j+floor+variant)%3!=0:
                    for side in (-1,1):
                        uu=u+side*(wide/2+1.1)
                        plate('Teal' if variant!=2 else 'Wood',uu,y,.46,1.4,6.5,.35)
                        for k in range(7):plate('Iron',uu,y-2.5+k*.8,.66,1.05,.1,.12)
                        for yy in (-2.7,2.7):plate('Iron',uu,y+yy,.72,1.4,.16,.12)
                # Window boxes project over the façade, outside the travel corridor.
                if (j*3+floor+seed)%4==0:
                    plate('Terracotta',u,y-3.1,1.3,wide+1,1.3,1.6)
                    plate('Soil',u,y-2.4,1.3,wide+.7,.1,1.3)
                    foliage(api,point(u,y-2.2,1.3),1.5,seed+j*11+floor,True)
                if floor==0 and name.startswith('Market'):
                    plate('Wood',u,base+3.9,.3,6.2,7.7,.4)
                    plate('Glass',u,base+4.2,.55,5.3,6.5,.15)
                    for uu in (u-2.8,u+2.8):plate('Cream',uu,base+4.2,.7,.35,7.8,.35)
                    for yy in (base+.3,base+8.2):plate('Cream',u,yy,.7,6.4,.45,.35)
        # Cornice, corner blocks and a drainpipe provide readable depth close to the player.
        for yy in range(int(base)+11,int(base+h)-2,11):plate('Terracotta',0,yy,.12,span,.3,.3)
        for u in (-span/2+.7,span/2-.7):
            for yy in range(int(base)+2,int(base+h)-1,4):plate('Cream',u,yy,.25,1.45,1.8,.55)
        pu=span/2-2.1
        beam('Iron',point(pu,base+.5,.6),point(pu,base+h-1,.6),.16,10)
        for yy in range(int(base)+4,int(base+h),8):plate('Iron',pu,yy,.5,.7,.24,.6)


def surface_detail(api,s,x,y,z,w,d):
    box,beam,geo=api['box'],api['beam'],api['geo']
    style=s['style']
    if style in ('deck','work','scaffold'):
        # Individual top boards and end bolts remain flush with the walking plane.
        count=max(2,round(w/1.1));pitch=w/count
        for i in range(count):
            xx=x-w/2+pitch*(i+.5)
            box('WoodLight' if i%4 else 'WoodDark',(xx,y+.015,z),(pitch-.055,.04,d-.1))
        for xx in (x-w/2+.28,x+w/2-.28):
            for zz in (z-d/2+.35,z+d/2-.35):
                api['cylinder']('Iron',(xx,y+.05,zz),.10,.06,8)
        for zz in (-d/2+.1,d/2-.1):box('Iron',(x,y-.52,z+zz),(w,.55,.2))
    elif style=='awning':
        # Scalloped valance is below the flat, rigid canopy used for the jump.
        color=['Teal','Coral','Yellow'][sum(map(ord,s['name']))%3]
        n=max(2,int(w/1.8));pitch=w/n
        for i in range(n):
            a=x-w/2+i*pitch;b=a+pitch
            verts=[(a,y-.4,z+d/2+.16),(b,y-.4,z+d/2+.16)]
            verts += [(a+pitch*t/8,y-1.2-.55*math.sin(math.pi*t/8),z+d/2+.16) for t in range(8,-1,-1)]
            geo(color if i%2 else 'Cream',verts,[tuple(range(len(verts))),tuple(reversed(range(len(verts))))])
    elif style in ('balcony','roof','stone'):
        for zz in (-d/2+.16,d/2-.16):box('Cream',(x,y-.35,z+zz),(w,.28,.35))
        for xx in (-w/2+.16,w/2-.16):box('Cream',(x+xx,y-.35,z),(.35,.28,d))


def hero_sets(api):
    owner,box,beam,text,geo=(api[k] for k in ('owner','box','beam','text','geo'))
    owner('MarketCloseFronts','Market')
    # Bespoke shop windows face into the opening street at the player's height.
    for x,z,nx,name,color in [(-189.3,245,1,'BAKERY','Coral'),(-146.3,242,-1,'GROCER','Teal'),(-201.3,204,1,'CAFE','Yellow')]:
        for dz in (-5,0,5):
            box('WoodDark',(x,9,z+dz),(.5,11,4.3))
            box('Glass',(x+nx*.3,9.4,z+dz),(.15,9.3,3.6))
            box('Cream',(x+nx*.45,9.4,z+dz),(.2,.22,3.7))
            box('Cream',(x+nx*.45,9.4,z+dz),(.2,9.4,.22))
            box('WoodLight',(x+nx*.65,4.3,z+dz),(1.4,.5,4.8))
        box(color,(x+nx*.5,16,z),(.7,3.6,17))
        text(name,(x+nx*.95,16,z),2.4,'Cream',math.atan2(nx,0))
        for dz in (-6,6):
            box('Terracotta',(x+nx*1.5,4,z+dz),(2.5,2.5,4))
            foliage(api,(x+nx*1.5,5.4,z+dz),2,11+int(z)+dz,True)
        # Rounded striped shelter frames the path without roofing over it.
        for band in range(10):
            za=z-8.5+band*1.7;zb=za+1.7
            for step in range(7):
                a=step*math.pi/14;b=(step+1)*math.pi/14
                u=nx*(.5+3.2*math.sin(a));v=nx*(.5+3.2*math.sin(b))
                ya=15-2.4*(1-math.cos(a));yb=15-2.4*(1-math.cos(b))
                geo(color if band%2 else 'Cream',[(x+u,ya,za),(x+v,yb,za),(x+v,yb,zb),(x+u,ya,zb)],[(0,1,2,3),(3,2,1,0)])

    owner('CourtyardCloseLife','Climb')
    for x,y,z,nx in [(-242.2,43,43,1),(-242.2,54,-81,1),(-104.1,42,18,-1),(-104.1,61,-82,-1)]:
        # Deep window/door bays and planted rails mark the residential courtyard.
        box('Cream',(x+nx*1.8,y-3.5,z),(4.4,.8,15))
        for dz in (-5,0,5):
            box('Iron',(x+nx*.5,y+1,z+dz),(.8,8,3.5))
            box('Glass',(x+nx*.95,y+1,z+dz),(.15,7,2.7))
            box('Cream',(x+nx*1.05,y+1,z+dz),(.15,7,.18))
        api['railing']((x+nx*4,y-3,z-7),(x+nx*4,y-3,z+7),3,False)
        for dz in (-5,5):
            box('Wood',(x+nx*3,y-2.6,z+dz),(2,1.5,3))
            foliage(api,(x+nx*3,y-1.8,z+dz),1.7,int(y+z+dz),True)

    owner('CourtyardMuralGallery','Climb')
    box('Brick',(-178,18,-6),(64,36,3))
    box('Cream',(-178,36.5,-6),(66,1,4))
    box('Teal',(-178,21,-4.35),(58,26,.2))
    api['sphere']('Yellow',(-190,27,-4.15),5.5,24,12,(1,1,.025))
    for i in range(10):
        height=7+(i*7)%12;xx=-204+i*5.8
        box('Coral' if i%2 else 'Cream',(xx,8+height/2,-4.05),(5,height,.15))
        for yy in range(10,8+height,4):box('Teal',(xx,yy,-3.93),(1.3,1.8,.1))
    text('UPTOWN',(-173,28,-3.9),4,'Cream')
    for x in (-211,-145):beam('Iron',(x,0,-6),(x,37,-6),.3)

    # The central mass is between the swing planes and clear of both route corridors.
    api['building']('RenovationCourtyardHouse',0,-282,24,25,98,'Plaster',detail=True)
    api['building']('NorthRoofFrame',-27,-340,34,27,106,'Terracotta',detail=True)
    owner('RenovationCloseDetail','Roof')
    for x in (-10,10):
        box('Cream',(x,99.3,-282),(1,2.6,25))
        for z in (-291,-273):
            box('Terracotta',(x,99.8,z),(3,1.4,5))
            foliage(api,(x,100.6,z),2,int(x+z),True)
    for x in (-10,0,10):
        box('Iron',(x,78,-268.9),(5,8,.35))
        box('Glass',(x,78,-268.6),(4.1,7,.2))
    for z in (-292,-282,-272):
        beam('Iron',(-13,62,z),(-13,100,z),.35)
    for yy in (70,82,94):
        beam('Iron',(-13,yy,-294),(-13,yy,-270),.3)
        beam('Iron',(-13,yy,-294),(-13,yy+10,-282),.18)

    owner('StationNearFacade','Station')
    # Large inset bays make the final wall a station frontage, not a blank tower support.
    for x in (171,182,208,219):
        box('Cream',(x,139,259.5),(8,14,.7))
        box('Iron',(x,139,260),(6.6,12,.4))
        box('Glass',(x,139,260.25),(5.8,11,.18))
        for dx in (-1.5,1.5):box('Cream',(x+dx,139,260.4),(.22,11,.22))
        for yy in (136,141):box('Cream',(x,yy,260.4),(6,.22,.22))
        box('Cream',(x,146.4,259.5),(9,1.1,1.2))
        box('Brick',(x,65,258),(9,130,4))
    for x in (162,228):
        box('Terracotta',(x,133,240),(5,2,8))
        foliage(api,(x,134.3,240),3.1,int(x),True)
    for x in (176,215):
        beam('Iron',(x,132,225),(x,144,225),.18,10)
        box('Teal',(x,142,225),(4,4,.3))
        text('R',(x,142,224.78),2.7,'Cream',math.pi)

    owner('StationArrivalWings','Station')
    for x,width,height,z in [(170,22,26,267),(220,22,32,270)]:
        box('Brick',(x,66,z),(width,132,18))
        box('Cream',(x,132,z),(width+1,1,19))
        box('Brick',(x,132+height/2,z),(width,height,18))
        box('Cream',(x,132+height,z),(width+2,1.4,20))
        box('Teal',(x,134+height,z),(width+3,2.6,21))
        front=z-9.3
        for dx in (-6,6):
            box('Cream',(x+dx,143,front),(7.6,18,.6))
            box('Iron',(x+dx,143,front-.4),(6.3,16,.3))
            box('Glass',(x+dx,143,front-.62),(5.5,15,.14))
            for side in (-1,1):box('Cream',(x+dx+side*1.45,143,front-.8),(.2,15,.2))
            for yy in (138,143,148):box('Cream',(x+dx,yy,front-.8),(5.6,.22,.2))
            for i in range(16):
                a=i*math.pi/16;b=(i+1)*math.pi/16
                beam('Cream',(x+dx+3.7*math.cos(a),152+3.7*math.sin(a),front-.3),
                     (x+dx+3.7*math.cos(b),152+3.7*math.sin(b),front-.3),.45,8)
        for dx in (-width/2+.7,width/2-.7):
            box('Cream',(x+dx,145,front),(1.4,27,1))
        box('Iron',(x,159 if height>28 else 151,front+.9),(width-1,1,2))
