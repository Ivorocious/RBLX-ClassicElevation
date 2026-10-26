"""One closed wall-rooted garden; no scene mutation on import."""
import math

PALETTE={'Stone':(155,164,175),'Earth':(104,86,63),'Foliage':(70,117,67)}
ASSET='MC_DG_WallGarden24'


def solid_leaf(g,centre,width,height,angle=0):
    outline=[(-.14,0),(-.5,.32),(-.43,.84),(0,1),(.43,.84),(.5,.32)]
    c,s=math.cos(angle),math.sin(angle)
    def point(x,y,z):return (centre[0]+c*x+s*z,centre[1]+y,centre[2]-s*x+c*z)
    vertices=[point(x*width,depth,z*height) for depth in (0,.09) for x,z in outline]
    vertices.extend([point(0,-.15,.45*height),point(0,.13,.45*height)])
    faces=[]
    for i in range(6):
        j=(i+1)%6;faces.extend([(12,j,i),(13,6+i,6+j),(i,j,6+j,6+i)])
    g.add(vertices,faces,'Foliage')


def side_corbel(g,x):
    profile=[(.10,0),(-.45,.38),(-.86,1.7),(-2.0,3.25),(-3.65,4.6),(-3.8,5.22),(.10,5.22)]
    vertices=[(x+offset,y,z) for offset in (-1.16,1.16) for y,z in profile]
    n=len(profile);faces=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    g.add(vertices,faces,'Stone')


def stone_bowl(g):
    n=16;vertices=[]
    rings=[(12,2.05,6.35,.18),(10.76,1.54,6.00,.10),(10.5,1.50,4.87,.08),(9.63,1.06,5.03,.06)]
    for rx,ry,z,wave in rings:
        for i in range(n):
            theta=math.tau*i/n
            vertices.append((rx*math.cos(theta),-1.95+ry*math.sin(theta),z+wave*math.cos(3*theta)))
    faces=[]
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),
                      (i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
    g.add(vertices,faces,'Stone')


def earth_bed(g):
    n=16;vertices=[]
    for rx,ry,z in ((9.8,1.1,5.03),(10.86,1.55,5.98),(8.75,1.3,6.55),(4.1,.65,6.83)):
        for i in range(n):
            theta=math.tau*i/n
            vertices.append((rx*math.cos(theta),-1.95+ry*math.sin(theta),z+.06*math.cos(3*theta)))
    vertices.append((0,-1.95,7.04))
    faces=[tuple(reversed(range(n)))]
    for ring in range(3):
        for i in range(n):
            j=(i+1)%n;faces.append((ring*n+i,ring*n+j,(ring+1)*n+j,(ring+1)*n+i))
    for i in range(n):faces.append((3*n+i,3*n+(i+1)%n,4*n))
    g.add(vertices,faces,'Earth')


def build_recipes(a,e):
    class Mesh(a._Mesh):
        def __init__(self):super().__init__();self.occupied=[]
        def add(self,vertices,faces,color='Stone',smooth=False):
            vertices=list(vertices);super().add(vertices,faces,color,smooth)
            self.occupied.append({'low':[min(v[k] for v in vertices) for k in range(3)],
                                  'high':[max(v[k] for v in vertices) for k in range(3)]})
    g=Mesh()
    for x in (-8.65,0,8.65):side_corbel(g,x)
    g.box((0,-.08,4.35),(22.6,.36,3.4),'Stone')
    stone_bowl(g);earth_bed(g)
    for j,(x,y,top) in enumerate(((-7.15,-1.72,9.12),(0,-1.35,9.60),(7.15,-2.15,9.25))):
        g.tube([(x,y,6.02),(x-.16,y-.10,7.22),(x+.14,y-.13,8.25),(x,y,top)],.12,'Earth',sides=6)
        for level in range(3):
            z=6.46+level*.7
            for side in (-1,1):
                base=(x+side*(.68+.12*level),y-.12-.10*level,z)
                g.tube([(x,y,z+.16),base],.058,'Earth',sides=5)
                solid_leaf(g,base,2.35,1.76,side*(.7-.13*level))
    for j,x in enumerate((-9.1,-3.2,3.15,9.0)):
        path=[(x,-3.85,6.32),(x+.3,-4.04,5.52),(x-.16,-4.12,4.15),(x+.23,-4.06,2.72),(x,-3.98,1.3)]
        g.tube(path,.068,'Earth',sides=5)
        for level in range(3):
            solid_leaf(g,(x+(.17 if level%2 else -.18),-4.12,2.08+level*1.12),1.16,1.12,(-1 if (j+level)%2 else 1)*.5)
    notes=('24-wide wall-rooted garden. Backing plane intended RobloxZ=-0.10; front+Z/basepivot0. '
           'Three deep sloped corbels support a rough nonplanar stone bowl, convex earth bed, broad rooted plants and hanging vines. '
           'No exposed horizontal decorative deck; allgeometryopaque/noncolliding. Place only against verified old vertical wall faces.')
    return [(ASSET,g,notes)]
