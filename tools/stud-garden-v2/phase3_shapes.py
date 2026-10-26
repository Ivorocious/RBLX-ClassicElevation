"""Closed, palette-batched garden geometry in course-local Roblox coordinates."""
from collections import Counter, defaultdict
import math
import random

PALETTE = {
    'leaf': '#4B923B', 'lime': '#83BC43', 'light_leaf': '#AED65D',
    'deep_leaf': '#327747', 'grass': '#74A73B', 'teal': '#53BFC5',
    'teal_light': '#8ADDD7', 'teal_dark': '#3BA6AF', 'pink': '#ED83B5',
    'pink_light': '#FFADCC', 'pink_dark': '#CD6499', 'flower_pink': '#FF85B8',
    'flower_cream': '#FFF1CB', 'flower_gold': '#FFCC42', 'stem': '#4A833B',
    'soil': '#775035', 'timber': '#B98242', 'timber_light': '#DEA65C',
    'timber_dark': '#825935', 'cream': '#FFF0C9', 'roof': '#7BA94B',
    'roof_dark': '#47834C', 'terra': '#C77249', 'orange': '#F79A30',
    'pale_orange': '#FFC060', 'red': '#DC7565', 'black': '#323A31',
    'white': '#FFF3DE', 'sun_center': '#996432', 'sun_deep': '#764B2D',
    'clover': '#93CF4D', 'clover_light': '#B0DD69',
}


class GardenShapes:
    def __init__(self, seed=65105):
        self.rng = random.Random(seed)
        self.pieces = []
        self.counts = Counter()
        self.group = 'unassigned'
        self.kind = 'foliage'

    def emit(self, color, vertices, faces, detail='solid'):
        self.pieces.append({'group': self.group, 'kind': self.kind,
                            'color': color, 'vertices': vertices, 'faces': faces,
                            'detail': detail})

    def box(self, center, size, color, angle=0, detail='solid'):
        x, y, z = center
        sx, sy, sz = (v / 2 for v in size)
        c, s = math.cos(angle), math.sin(angle)
        vertices = [(x+c*dx-s*dz, y+dy, z+s*dx+c*dz)
                    for dy in (-sy, sy) for dz in (-sz, sz) for dx in (-sx, sx)]
        self.emit(color, vertices, [(0,1,3,2),(4,6,7,5),(0,4,5,1),
                                    (2,3,7,6),(0,2,6,4),(1,5,7,3)], detail)
        if detail=='solid':
            self.pieces[-1]['primitive']={'shape':'Block','center':center,'size':size,'yaw':angle}

    def cylinder(self, center, radius, depth, color, sides=12, top_radius=None,
                 detail='solid', normal=(0,1,0)):
        import numpy as np
        if detail=='stud' and (radius<.7 or self.kind=='ground studs'):
            sides=min(sides,8)
        normal = np.array(normal, dtype=float)
        normal /= np.linalg.norm(normal)
        axis = np.array((0,0,1)) if abs(normal[2]) < .9 else np.array((1,0,0))
        right = np.cross(normal, axis); right /= np.linalg.norm(right)
        across = np.cross(normal, right)
        center = np.array(center)
        top_radius = radius if top_radius is None else top_radius
        vertices = [tuple(center+normal*h+(right*math.cos(i*math.tau/sides)+
                    across*math.sin(i*math.tau/sides))*r)
                    for h,r in ((-depth/2,radius),(depth/2,top_radius))
                    for i in range(sides)]
        faces = [tuple(range(sides-1,-1,-1)),tuple(range(sides,sides*2))]
        faces += [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
        self.emit(color,vertices,faces,detail)
        if detail=='solid':
            self.pieces[-1]['primitive']={'shape':'Cylinder','center':tuple(center),'radius':radius,
                'topRadius':top_radius,'depth':depth,'normal':tuple(normal)}

    def rod(self,a,b,radius,color,end_radius=None,sides=10):
        import numpy as np
        a,b=np.array(a),np.array(b)
        self.cylinder(tuple((a+b)/2),radius,float(np.linalg.norm(b-a)),color,
                      sides,end_radius,normal=tuple(b-a))

    def studs(self, center, width, depth, color, pitch=3.2, radius=.78,
              height=.34, angle=0, predicate=None):
        nx,nz=max(1,int((width-radius*2)/pitch)+1),max(1,int((depth-radius*2)/pitch)+1)
        c,s=math.cos(angle),math.sin(angle)
        for ix in range(nx):
            for iz in range(nz):
                dx,dz=(ix-(nx-1)/2)*pitch,(iz-(nz-1)/2)*pitch
                pos=(center[0]+c*dx-s*dz,center[1]+height/2,center[2]+s*dx+c*dz)
                if predicate and not predicate(pos): continue
                self.cylinder(pos,radius,height,color,12,detail='stud')
                self.counts['raised_studs']+=1

    def stud_box(self,center,size,color,angle=0,pitch=3.2,radius=.78):
        self.box(center,size,color,angle)
        self.studs((center[0],center[1]+size[1]/2,center[2]),size[0]-.4,
                   size[2]-.4,color,pitch,radius,angle=angle)

    def leaf(self, x,y,z,length,width,angle,color):
        c,s=math.cos(angle),math.sin(angle)
        thick=min(.9,width*.12)
        local=[(0,0,0),(.28*length,.18,-width*.48),(.72*length,.05,-width*.39),
               (length,-.08,0),(.72*length,.05,width*.39),(.28*length,.18,width*.48)]
        local += [(a,b-thick,d) for a,b,d in local]
        local += [(.45*length,.75,0)]
        vertices=[(x+c*a-s*d,y+b,z+s*a+c*d) for a,b,d in local]
        self.emit(color,vertices,[(i,(i+1)%6,12) for i in range(6)]+
                  [(6,7,8,9,10,11)]+[(i,i+6,(i+1)%6+6,(i+1)%6) for i in range(6)])
        if width>=4:
            for fraction in (.29,.61):
                self.cylinder((x+c*length*fraction,y+.78,z+s*length*fraction),
                              min(.65,width*.13),.26,color,10,detail='stud')
                self.counts['raised_studs']+=1

    def bush(self,x,z,width=9,top=2.1,theme='green'):
        self.counts['bushes']+=1
        palette=('deep_leaf','leaf','lime') if theme=='green' else ('teal_dark','teal','teal_light')
        base=-2.8
        for j,(dx,dz,w,low,high) in enumerate([(-.18,-.12,.72,base,top-1.1),
                (.19,.12,.68,base,top-1.6),(-.06,.1,.58,base+1.3,top-.35)]):
            h=high-low
            self.stud_box((x+dx*width,low+h/2,z+dz*width),(w*width,h,w*width*.78),
                          palette[j],angle=(-.12,.1,.03)[j],pitch=2.8,radius=.59)

    def flower(self,x,z,height=14,size=1.8,color='flower_pink',base=-2.8):
        self.counts['flowers']+=1
        self.cylinder((x,base+height/2,z),.28*size,height,'stem',10)
        for angle,y in ((.7,height*.37),(3.8,height*.59)):
            self.leaf(x,base+y,z,3.4*size,2.25*size,angle,'leaf')
        for i in range(5):
            angle=i*math.tau/5+.2
            center=(x+math.cos(angle)*1.45*size,base+height,z+math.sin(angle)*1.45*size)
            self.box(center,(1.9*size,1.15*size,1.5*size),color,angle)
            self.cylinder((center[0],center[1]+.68*size,center[2]),.47*size,.28*size,color,12,detail='stud')
        self.cylinder((x,base+height+.78*size,z),.95*size,.78*size,'flower_gold',12)
        self.cylinder((x,base+height+1.25*size,z),.57*size,.22*size,'flower_gold',12,detail='stud')

    def tree(self,x,z,height=43,candy=False,pink=False):
        self.counts['trees']+=1
        bark='pink_dark' if candy else 'timber_dark'
        colors=('pink_dark','pink','pink_light') if pink else (('teal_dark','teal','teal_light') if candy else ('deep_leaf','leaf','lime'))
        base=-2.8
        self.rod((x,base,z),(x+.5,base+height-10,z),1.8,bark,1.2)
        for dx,dz in ((-6,-3),(6,3),(-2,6)):
            self.rod((x,base+height-23,z),(x+dx,base+height-8,z+dz),1.1,bark,.7)
        # Overlapping thick lobes form a crown rather than stacked flat shelves.
        crowns=[(-7,-3,-7,11,7.5),(4,-6,-6,13,8.5),(8,3,-5,11,8),
                (-4,6,-3,13,8.5),(0,-1,1,15,8.5),(-5,-4,5,10,6),(4,3,7,10,6)]
        for i,(dx,dz,dy,w,h) in enumerate(crowns):
            self.stud_box((x+dx,base+height+dy,z+dz),(w,h,w*.9),colors[min(i//3,2)],
                          pitch=4.2,radius=1.08)

    def bamboo(self,x,z,height=40):
        self.counts['bamboo_clumps']+=1
        base=-2.8
        for i,(dx,dz,m) in enumerate([(-3,-2,1),(3,-1,.8),(0,3,.93)]):
            h=height*m; radius=1.95+(i==0)*.3
            self.cylinder((x+dx,base+h/2,z+dz),radius,h,'lime',12)
            for yy in range(7,int(h),7):
                self.cylinder((x+dx,base+yy,z+dz),radius+.17,.48,'light_leaf',12)
            self.cylinder((x+dx,base+h+.2,z+dz),radius*.62,.4,'light_leaf',12,detail='stud')
            for j in range(2):
                self.leaf(x+dx,base+h*.64+j*6,z+dz,7.5,3.0,i*2+j*2.3,'leaf')

    def sunflower(self,x,z,height=34,size=1.65,face=-.5):
        import numpy as np
        self.counts['sunflowers']+=1
        base=-2.8
        self.cylinder((x,base+height/2,z),.65*size,height,'stem',12)
        for j,side in enumerate((-1,1)):
            self.leaf(x,base+height*(.36+j*.16),z,8*size,4.8*size,face+side*1.6,'leaf')
        normal=np.array((math.sin(face),.22,math.cos(face)));normal/=np.linalg.norm(normal)
        right=np.array((math.cos(face),0,-math.sin(face)))
        up=np.cross(normal,right)
        center=np.array((x,base+height,z))
        for i in range(11):
            a=i*math.tau/11
            p=center+(right*math.cos(a)+up*math.sin(a))*4.6*size
            self.cylinder(tuple(p),2.1*size,1.8*size,'flower_gold',8,normal=normal)
        self.cylinder(tuple(center),3.7*size,2.4*size,'sun_center',14,normal=normal)
        for ax,ay in ((0,0),(-1.7,-1.0),(1.7,-1.0),(0,1.9),(-1.65,1.25),(1.65,1.25)):
            p=center+(right*ax+up*ay+normal*1.35)*size
            self.cylinder(tuple(p),.55*size,.45*size,'sun_deep',10,detail='stud',normal=normal)

    def clover(self,x,z,height=13,size=1):
        self.counts['clovers']+=1
        base=-2.8
        self.cylinder((x,base+height/2,z),.44*size,height,'stem',10)
        for i in range(4):
            a=i*math.tau/4+.25
            p=(x+math.cos(a)*3.5*size,base+height+i*.08,z+math.sin(a)*3.5*size)
            self.cylinder(p,3.4*size,.95*size,'clover_light',10)
            self.cylinder((p[0],p[1]+.65*size,p[2]),.72*size,.4*size,'clover',12,detail='stud')

    def pumpkin(self,x,z,size=1,base=-2.8):
        self.counts['pumpkins']+=1
        rings=[(.25,.38),(1.0,.84),(2.7,1),(4.4,.85),(5.0,.4)]
        vertices=[(x+math.cos(i*math.tau/16)*r*3.5*size*(1 if i%2 else .91),
                   base+y*size,z+math.sin(i*math.tau/16)*r*3.5*size*(1 if i%2 else .91))
                  for y,r in rings for i in range(16)]
        faces=[tuple(range(15,-1,-1)),tuple(range(64,80))]
        faces += [(j*16+i,j*16+(i+1)%16,(j+1)*16+(i+1)%16,(j+1)*16+i)
                  for j in range(4) for i in range(16)]
        self.emit('orange',vertices,faces)
        self.cylinder((x,base+5.5*size,z),.55*size,1.3*size,'stem',8)
        self.leaf(x,base+5.1*size,z,3.5*size,2.2*size,.45,'leaf')

    def prune_buried_studs(self,clearance=.4):
        import numpy as np
        boxes=defaultdict(list)
        for p in self.pieces:
            if p['detail']=='solid' and len(p['vertices'])==8 and len(p['faces'])==6:
                v=np.array(p['vertices']);axes=np.array((v[1]-v[0],v[4]-v[0],v[2]-v[0]))
                lengths=np.linalg.norm(axes,axis=1)
                if np.all(lengths>clearance*2) and np.max(np.abs((axes/lengths[:,None])@(axes/lengths[:,None]).T-np.eye(3)))<1e-5:
                    boxes[p['group']].append((v[0],axes/lengths[:,None],lengths))
        kept=[];removed=[]
        for p in self.pieces:
            buried=False
            if p['detail']=='stud':
                vertices=np.array(p['vertices'])
                for origin,axes,lengths in boxes[p['group']]:
                    positions=(vertices-origin)@axes.T
                    if np.all(positions>clearance) and np.all(positions<lengths-clearance):
                        buried=True;break
            if buried:removed.append(p)
            else:kept.append(p)
        self.pieces=kept
        self.counts['raised_studs']=sum(p['detail']=='stud' for p in kept)
        self.counts['buried_studs_omitted']=len(removed)
        return len(removed)
