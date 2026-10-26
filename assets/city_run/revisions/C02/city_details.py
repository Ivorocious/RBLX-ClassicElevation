"""Large architectural and street details kept beside the shared route builder."""
import math


def facade(api,name,x,z,w,d,h,base,detail):
    box,beam,geo=api['box'],api['beam'],api['geo']
    variant=sum(ord(c) for c in name)%4
    roof=base+h
    if variant==0:
        ridge=roof+min(w*.27,10)
        geo('Teal',[(x-w/2-1,roof,z-d/2-1),(x+w/2+1,roof,z-d/2-1),(x, ridge,z-d/2-1),
                    (x-w/2-1,roof,z+d/2+1),(x+w/2+1,roof,z+d/2+1),(x,ridge,z+d/2+1)],
            [(2,1,0),(3,4,5),(0,3,5,2),(1,2,5,4),(0,1,4,3)])
    elif variant==1:
        for zz in (-d/2,d/2):box('Cream',(x,roof+1.6,z+zz),(w+1,3.2,.8))
        for xx in (-w/2,w/2):box('Cream',(x+xx,roof+1.6,z),(.8,3.2,d))
        box('Brick',(x-w*.25,roof+3,z-d*.2),(4,6,4))
        box('Iron',(x-w*.25,roof+6.2,z-d*.2),(5,.5,5))
    elif variant==2:
        box('Cream',(x,roof+1,z),(w+2,1,d+2))
        box('Roof',(x+w*.18,roof+3,z-d*.14),(w*.42,5,d*.45))
        box('Cream',(x+w*.18,roof+5.7,z-d*.14),(w*.44,.7,d*.47))
    else:
        for yy,scale in ((1,1),(3,.82),(5,.64)):
            box('Terracotta',(x,roof+yy,z),(w*scale,2,d*scale))
    if not detail:return
    # Ground-floor shop bays break the repeated residential window grid.
    face=z+d/2+.55
    for xx in (x-w*.28,x+w*.28):
        box('Iron',(xx,base+4.1,face),(6.5,8,.35))
        box('Glass',(xx,base+4.5,face+.22),(5.5,6.8,.14))
        box('Cream',(xx,base+1,face+.3),(7,.5,1.2))
    if variant in (1,3):
        for yy in range(18,int(h)-8,22):
            bay=x+w*.23
            box('Cream',(bay,base+yy-3,face+1.4),(9,.65,3.4))
            api['railing']((bay-4,base+yy-2.7,face+3),(bay+4,base+yy-2.7,face+3),2.7,False)
            box('Teal' if variant==1 else 'Coral',(bay,base+yy+3.5,face+1.4),(10,.5,3.8))
    for xx in (x-w/2+.7,x+w/2-.7):
        box('Cream',(xx,base+h/2,face-.1),(1.1,h-.5,.6))


def dress_sections(api):
    owner,box,beam,sphere,text=(api[k] for k in ('owner','box','beam','sphere','text'))
    geo,railing,planter=api['geo'],api['railing'],api['planter']

    def lamp(x,y,z):
        box('Stone',(x,y+.3,z),(1.6,.6,1.6))
        beam('Iron',(x,y,z),(x,y+9,z),.16)
        box('Iron',(x,y+9,z),(1.5,2,1.5))
        box('Light',(x,y+9,z),(1.1,1.5,1.1))
        box('Iron',(x,y+10.1,z),(1.9,.3,1.9))

    def tree(x,y,z,r=6):
        box('Terracotta',(x,y+1,z),(r*1.6,2,r*1.5))
        box('Soil',(x,y+2.1,z),(r*1.45,.2,r*1.35))
        beam('Wood',(x,y+2,z),(x+.5,y+11,z),.65,8)
        for dx,dz in ((-2,1),(2,-1),(0,2)):
            beam('Wood',(x,y+7,z),(x+dx,y+13,z+dz),.3)
            sphere('LeafLight' if dx==0 else 'Leaf',(x+dx,y+14,z+dz),r,9,5,(1,.8,1))

    def crate(x,y,z,w=3):
        box('Wood',(x,y+w/2,z),(w,w,w))
        for yy in (.3,w-.3):box('Cream',(x,y+yy,z+w/2+.02),(w,.24,.12))
        beam('Terracotta',(x-w/2,y+.2,z+w/2+.1),(x+w/2,y+w-.2,z+w/2+.1),.13,4)

    def stall(x,y,z,color):
        for xx in (-4.5,4.5):
            for zz in (-2.4,2.4):beam('Wood',(x+xx,y,z+zz),(x+xx,y+8,z+zz),.2)
        box('Wood',(x,y+2.4,z),(10,4.8,5))
        box('Cream',(x,y+4.9,z),(10.5,.3,5.5))
        box(color,(x,y+8,z),(12,.5,8))
        for xx in range(-5,6,2):box('Cream',(x+xx,y+8.3,z),(.8,.08,8))
        box(color,(x,y+7.3,z+4),(12,1.8,.25))
        for i in range(4):
            box('Wood',(x-3+i*2,y+5.2,z),(1.7,.5,3))
            for zz in (-.8,0,.8):sphere(['Coral','Yellow','LeafLight'][i%3],(x-3+i*2,y+5.8,z+zz),.55,7,4)

    def floor_arrow(x,y,z,dx,dz,color):
        points=[(-.6,-2),(.6,-2),(.6,.3),(1.7,.3),(0,2.5),(-1.7,.3),(-.6,.3)]
        geo(color,[(x+u*dz+v*dx,y,z-u*dx+v*dz) for u,v in points],[tuple(range(7)),tuple(reversed(range(7)))])

    for cp,location,main,expert in [(2,(-159,29,69),'MAIN  <','EXPERT  ^'),(4,(-102,82,-255),'MAIN  ^','EXPERT  >'),(8,(207,86,70),'MAIN  >','EXPERT  <')]:
        owner('BranchDirections'+str(cp),'Climb' if cp==2 else 'Roof' if cp==4 else 'Station')
        x,y,z=location
        for dx in (-6,6):beam('Iron',(x+dx,y-2,z),(x+dx,y+10,z),.2)
        box('Teal',(x,y+9,z),(17,3,.6))
        box('Yellow',(x,y+5.5,z),(17,3,.6))
        for front,rotation in ((.4,0),(-.4,math.pi)):
            text(main,(x,y+9,z+front),1.6,'Cream',rotation)
            text(expert,(x,y+5.5,z+front),1.45,'Iron',rotation)
        if cp==2:
            floor_arrow(-157,29.12,80,-1,0,'Teal');floor_arrow(-150,29.13,74,0,-1,'Yellow')
        elif cp==8:
            floor_arrow(212,86.12,57,1,0,'Teal');floor_arrow(199,86.13,57,-1,0,'Yellow')
        else:
            floor_arrow(-92,82.12,-252,0,-1,'Teal');floor_arrow(-84,82.13,-244,1,0,'Yellow')

    owner('MarketLife','Market')
    # The arrival arch is ahead of the starting camera, clear of the loading landings.
    for x in (-193,-147):
        box('Brick',(x,12,196),(3.2,24,3.2))
        box('Cream',(x,24,196),(4.4,1,4.4))
    box('Teal',(-170,26,196),(49,4,.8))
    text('MARKET STREET',(-170,26,196.5),3,'Cream')
    text('MARKET STREET',(-170,26,195.5),3,'Cream',math.pi)
    for x,y,z,c in [(-190,0,226,'Coral'),(-150,0,230,'Teal'),(-191,0,211,'Yellow'),(-144,0,214,'Coral'),(-205,0,130,'Teal')]:
        stall(x,y,z,c)
        crate(x-7,y,z+1)
    for x,z in [(-191,261),(-148,264),(-210,185),(-135,185)]:tree(x,0,z,5)
    for x,z in [(-185,244),(-154,244),(-188,202),(-152,202),(-200,140)]:lamp(x,0,z)
    for z in (235,216):
        beam('Iron',(-204,28,z),(-138,28,z),.08)
        for i in range(12):
            x=-201+i*5.2
            geo(['Coral','Teal','Yellow'][i%3],[(x,28,z),(x+3,28,z),(x+1.5,24.5,z)],[(0,1,2),(2,1,0)])

    owner('CourtyardLife','Climb')
    # A second mural face presents the courtyard identity before the viaduct.
    box('Teal',(-242,45,38),(.4,29,45))
    for i in range(11):
        z=18+i*3.6
        geo(['Cream','Yellow','Coral'][i%3],[(-241.7,31,z),(-241.7,51+(i%3)*2,z+3),(-241.7,37,z+7)],[(0,1,2),(2,1,0)])
    for x,z,y in [(-249,70,27),(-249,28,39),(-249,-52,54),(-96,33,30),(-96,-66,50)]:
        box('Cream',(x,y,z),(10,.8,14))
        railing((x+5,y+.4,z-6),(x+5,y+.4,z+6),3,False)
        for zz in (-4,4):planter((x+3,y+.4,z+zz),3)
    for z,y in ((68,54),(-77,67)):
        beam('Iron',(-240,y,z),(-101,y,z),.07)
        for i in range(9):
            x=-235+i*6
            box(['Cream','Teal','Coral'][i%3],(x,y-1.7,z),(3.4,3.4,.12))
    for x,z in [(-235,30),(-107,60),(-239,-111)]:tree(x,0,z,7)

    owner('RoofGardenLife','Roof')
    # Raised side pennants identify the safe landing beyond each ball without moving the hazards.
    for x,z in [(-20,-264),(19,-264),(66,-264),(-1,-225)]:
        beam('Teal',(x,82,z),(x,89,z),.14)
        box('Teal',(x+1.1,88,z),(2.2,2,.2))
    for x,z in [(-171,-325),(-153,-325),(86,-324),(110,-326),(128,-220)]:
        planter((x,86 if x<0 else 88 if z<-300 else 78,z),10)
    # A pergola frames the garden away from both wrecking-ball envelopes.
    for x in (122,142):
        for z in (-269,-255):beam('Wood',(x,72,z),(x,96,z),.3)
    for x in range(121,145,4):beam('Wood',(x,96,-272),(x,96,-252),.2)
    for x,z in [(128,-262),(137,-264)]:planter((x,78,z),6)
    for x in (-82,95):
        box('Wood',(x,64.5,-310),(9,1,6))
        for dx in (-3,0,3):crate(x+dx,65,-310,2.5)

    owner('DepotLife','Rail')
    box('Brick',(146,77,-159),(8,4,124))
    box('Cream',(146,79.4,-159),(9,.7,125))
    for z in (-205,-169,-133,-98):
        lamp(146,79.7,z)
        box('Teal',(147,91,z),(1,3,10))
    for x in (152,179):
        for z in (-220,-190):beam('Iron',(x,74,z),(x,95,z),.28)
    box('Teal',(165.5,95,-205),(31,1,34))
    box('Cream',(165.5,96,-205),(30,.4,33))
    # Sign faces point toward racers approaching from the north.
    text('WAIT FOR CLEAR', (205,96,-28.45),.95,'Cream',math.pi)
    text('RAIL CROSSING', (205,99,-28.45),1.15,'Cream',math.pi)
    for x in (197.5,212.5):
        railing((x,82,-44),(x,82,-23),5,True)
    # Light faces exist on both sides of the frame; runtime flashes the Red material group.
    owner('SignalGantry','Rail')
    for x in (195,215):
        sphere('Red',(x,95,-28.75),.72,10,6)
        sphere('Red',(x,92.9,-28.75),.72,10,6)
    owner('DepotLife','Rail')
    for x in (192,218):lamp(x,82,-40)

    owner('StationArrival','Station')
    # Tower foundations connect to the terrace instead of ending beyond its edge.
    box('Brick',(195,65,274),(38,130,34))
    box('Cream',(195,130.5,274),(40,1,36))
    for x in (158,232):
        box('Brick',(x,130,243),(2,4,30))
        box('Cream',(x,132.2,243),(2.7,.5,31))
        for z in (229,244,256):lamp(x,132.5,z)
    for x in (166,224):
        for z in (237,253):planter((x,132,z),7)
    # A side pavilion leaves the shared finish corridor and its sky open.
    for x in (235,256):
        for z in (229,257):
            box('Cream',(x,70,z),(2.4,140,2.4))
            beam('Iron',(x,132,z),(x,148,z),.22)
    box('Teal',(245.5,148,243),(25,1,31))
    box('Glass',(245.5,148.7,243),(21,.2,27))
    for z in range(229,258,5):box('Cream',(245.5,149,z),(25,.35,.45))
    for x in (171,219):
        box('Wood',(x,134,249),(8,.7,2.6))
        for dx in (-3,3):box('Iron',(x+dx,133,249),(.35,2,.4))
    # Scaffold crossheads land visibly in the station wall at every expert platform.
    owner('StationScaffoldTies','Station')
    for s in api['layout'].SURFACES:
        if not s['name'].startswith('X03'):continue
        x,y,z=s['p'];w,_,d=s['size']
        for zz in (z-d/2+.35,z+d/2-.35):
            beam('Iron',(x-w/2,y-1,zz),(204,y-1,zz),.28)
            beam('Iron',(x-w/2,y-1,zz),(204,y-5,zz),.18)
