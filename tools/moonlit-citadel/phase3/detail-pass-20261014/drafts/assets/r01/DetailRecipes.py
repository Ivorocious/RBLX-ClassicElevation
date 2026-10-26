"""Closed modular detail geometry; no scene changes occur on import."""
import math

PALETTE = {
    "Stone": (155, 164, 175), "StoneLight": (193, 196, 195), "StoneDark": (109, 121, 140),
    "Slate": (63, 80, 109), "SlateBand": (90, 106, 132), "Iron": (72, 83, 102),
    "Brass": (174, 140, 83), "Wood": (101, 77, 53), "Leaf": (70, 99, 80),
    "Foliage": (70, 117, 67), "Earth": (104, 86, 63), "Flower": (148, 143, 174),
}


def tracked_mesh(a):
    class Mesh(a._Mesh):
        def __init__(self):
            super().__init__()
            self.occupied = []

        def add(self, vertices, faces, color="Stone", smooth=False):
            vertices = list(vertices)
            super().add(vertices, faces, color, smooth)
            self.occupied.append({"low": [min(v[k] for v in vertices) for k in range(3)],
                                  "high": [max(v[k] for v in vertices) for k in range(3)]})
    return Mesh()


def move(g, source, matrix, offset=(0, 0, 0)):
    vertices = [tuple(sum(matrix[k][j] * vertex[j] for j in range(3)) + offset[k] for k in range(3))
                for vertex in source.vertices]
    first = len(g.faces)
    g.add(vertices, source.faces)
    g.colors[first:] = source.colors
    g.smooth[first:] = source.smooth


def beam(g, a, p, q, width, depth, material="Wood"):
    direction = [q[k] - p[k] for k in range(3)]
    length = math.sqrt(sum(v*v for v in direction))
    n = [v / length for v in direction]
    guide = [0, 1, 0] if abs(n[1]) < .95 else [1, 0, 0]
    u = [n[1]*guide[2]-n[2]*guide[1], n[2]*guide[0]-n[0]*guide[2], n[0]*guide[1]-n[1]*guide[0]]
    norm = math.sqrt(sum(v*v for v in u)); u = [v/norm for v in u]
    v = [n[1]*u[2]-n[2]*u[1], n[2]*u[0]-n[0]*u[2], n[0]*u[1]-n[1]*u[0]]
    temporary = a._Mesh(); temporary.box((0, 0, length/2), (width, depth, length), material)
    move(g, temporary, [[u[k], v[k], n[k]] for k in range(3)], p)


def leaf(g, centre, width, height, angle, material="Foliage", tilt=0):
    outline = [(0,-.48),(.48,-.12),(.32,.15),(.45,.45),(.10,.36),(0,.70),
               (-.10,.36),(-.45,.45),(-.32,.15),(-.48,-.12)]
    cosine, sine = math.cos(angle), math.sin(angle)
    vertices = []
    def point(x, y, z):
        return (centre[0]+cosine*x+sine*z, centre[1]+y+tilt*z, centre[2]-sine*x+cosine*z)
    for depth in (-.025, .045):
        vertices.extend(point(x*width, depth, z*height) for x,z in outline)
    vertices.extend([point(0,-.14,0), point(0,.085,0)])
    count = len(outline); faces = []
    for i in range(count):
        j = (i+1)%count
        faces.extend([(2*count,j,i), (2*count+1,count+i,count+j), (i,j,count+j,count+i)])
    g.add(vertices, faces, material)


def facade_niche(a, e):
    g = tracked_mesh(a)
    g.prism(a._pointed(7.2, 10.0, 1.25, 10), -.19, .10, "Stone")
    g.prism(a._pointed(5.5, 8.5, 1.65, 10), -.24, -.20, "StoneDark")
    g.ring(a._pointed(7.6,10.4,1.05,10), a._pointed(6.0,9.0,1.48,10), -.69, -.34, "StoneLight")
    g.ring(a._pointed(6.35,9.28,1.36,10), a._pointed(5.58,8.6,1.57,10), -.77, -.40, "Stone")
    for x in (-4.75,4.75):
        g.box((x,-.67,.42),(2.1,1.52,.84),"StoneLight")
        g.profile([(.81,.89),(1.02,.89),(1.24,.63),(10.75,.63),(11.0,.82),(11.6,.82)],
                  sides=8,color="Stone",center=(x,-.65,0))
        for dx in (-.34,.34):
            g.profile([(1.23,.15),(10.73,.15)], sides=6,color="StoneLight",center=(x+dx,-1.13,0))
        g.profile([(11.58,.94),(11.8,.94),(12.12,.73)],sides=8,color="StoneLight",center=(x,-.65,0))
    g.prism([(-6,12.15),(6,12.15),(6,12.65),(5.75,12.9),(5.75,13.28),(-5.75,13.28),(-5.75,12.9),(-6,12.65)],
            -1.38,.10,"StoneLight")
    for x in (-4.5,-2.25,0,2.25,4.5):
        g.prism([(x-.45,11.85),(x+.45,11.85),(x+.45,12.3),(x-.45,12.3)],-.93,-.38,"StoneDark")
    g.prism([(-1.28,4.8),(0,4.05),(1.28,4.8),(1.08,6.3),(-1.08,6.3)],-.9,-.79,"StoneLight")
    g.tube([(-.65,-1.02,5.35),(0,-1.02,5.95),(.65,-1.02,5.35)],.085,"Stone",sides=6)
    return g,"Back plane Z=-0.10; facade front +Z. Closed pointed blind niche, fluted engaged pilasters and projecting carved cornice. Base-centred pivot."


def quoin_cornice(a,e):
    g=tracked_mesh(a)
    for x in (-2.55,2.55):
        g.box((x,-.42,4.72),(1.52,1.04,8.8),"Stone")
        for i,z in enumerate((1.4,2.8,4.2,5.6,7.0,8.4)):
            width=2.2 if i%2==0 else 1.76
            g.prism([(x-width/2,z-.61),(x+width/2,z-.61),(x+width/2,z+.44),
                     (x+width/2-.18,z+.61),(x-width/2+.18,z+.61),(x-width/2,z+.44)],
                    -1.12,.10,"StoneLight")
    g.box((0,-.85,.43),(8,1.90,.86),"StoneLight")
    g.prism([(-4,9.06),(4,9.06),(4,9.4),(3.8,9.6),(3.8,10),(-3.8,10),(-3.8,9.6),(-4,9.4)],-1.58,.10,"StoneLight")
    g.box((0,-.64,8.96),(7.5,1.32,.18),"StoneDark")
    for x in (-2.7,-1.35,0,1.35,2.7):
        g.prism([(x-.32,8.55),(x+.32,8.55),(x+.46,9.09),(x-.46,9.09)],-1.40,-.76,"Stone")
    return g,"Back plane Z=-0.10; front +Z. Alternating chamfered dressed quoins with mortar gaps, broad footing and corbelled cornice; not a passage."


def slate_dormer(a,e):
    g=tracked_mesh(a)
    g.prism([(-3.45,.02),(3.45,.02),(3.45,4.35),(0,6.48),(-3.45,4.35)],-2.72,2.72,"Stone")
    g.prism([(-4,4.28),(0,6.95),(4,4.28),(4,4.65),(0,7.3),(-4,4.65)],-3.35,3.35,"Slate")
    g.prism(a._pointed(4.35,4.18,.58,8),-2.91,-2.75,"Iron")
    g.ring(a._pointed(5.05,4.76,.38,8),a._pointed(4.42,4.24,.53,8),-3.12,-2.88,"Stone")
    for z,width in ((1.25,3.9),(2.0,3.9),(2.75,3.55),(3.5,2.7)):
        g.prism([(-width/2,z-.12),(width/2,z-.12),(width/2,z+.12),(-width/2,z+.12)],-3.2,-2.94,"Iron")
    for y in (-2.65,-1.35,0,1.35,2.65):
        for side in (-1,1):
            g.tube([(side*.04,y,7.32),(side*3.96,y,4.69)],.055,"Slate",sides=5)
    return g,"Ground/roof pivot centred X/Z, base Y=0. Closed gabled slate dormer with thick roof/eaves and pointed louvred front +Z; seat its low closed base in existing roof."


def chimney_vent(a,e):
    g=tracked_mesh(a)
    g.profile([(0,2.2),(.45,2.2),(.74,1.52),(6.63,1.42),(6.9,1.7)],sides=8,color="Stone")
    for z in (.65,3.3,6.78):
        g.profile([(z-.14,1.75),(z+.14,1.75)],sides=8,color="StoneLight")
    for x in (-1.35,1.35):
        for y in (-1.35,1.35):
            g.box((x,y,7.53),(.42,.42,1.62),"StoneLight")
    for side in (-1,1):
        for x in (-.6,0,.6):
            g.tube([(x,side*1.43,6.97),(x,side*1.43,8.3)],.075,"Iron",sides=6)
        for y in (-.6,0,.6):
            g.tube([(side*1.43,y,6.97),(side*1.43,y,8.3)],.075,"Iron",sides=6)
    g.profile([(8.27,2.57),(8.51,2.57),(9.76,.6),(10.0,.28)],sides=4,color="Slate")
    return g,"Ground/roof pivot centred X/Z, base Y=0. Tapered masonry chimney with an actual open supported vent and closed pitched hood; all bars and cap parts are solid."


def heraldic_banner(a,e):
    g=tracked_mesh(a)
    g.box((0,.02,9.08),(.65,.24,2.0),"Iron")
    g.tube([(0,-.11,9.35),(0,-.92,9.35),(0,-1.7,9.98),(0,-2.25,10.3)],.14,"Iron",sides=8)
    g.tube([(-2.7,-2.25,10.3),(2.7,-2.25,10.3)],.14,"Iron",sides=8)
    for x in (-2.72,2.72):
        g.profile([(10.18,.22),(10.32,.29),(10.65,.12)],sides=8,color="Brass",center=(x,-2.25,0))
    columns,rows=8,8;vertices=[]
    for back in (False,True):
        for j in range(rows):
            t=j/(rows-1)
            for i in range(columns):
                x=-2.15+4.3*i/(columns-1)
                bottom=.72+1.10*(1-abs(x)/2.15)
                z=10.12*(1-t)+bottom*t
                y=-2.25-.34*math.sin(1.6*x+3*t)*math.sin(math.pi*t/2)+(0.095 if back else 0)
                vertices.append((x,y,z))
    count=columns*rows;faces=[]
    for j in range(rows-1):
        for i in range(columns-1):
            k=j*columns+i;faces.extend([(k,k+1,k+columns+1,k+columns),(count+k+columns,count+k+columns+1,count+k+1,count+k)])
    border=list(range(columns))+[j*columns+columns-1 for j in range(1,rows)]+list(range(count-2,count-columns-1,-1))+[j*columns for j in range(rows-2,0,-1)]
    for i,k in enumerate(border):
        n=border[(i+1)%len(border)];faces.append((k,count+k,count+n,n))
    g.add(vertices,faces,"SlateBand",smooth=True)
    crescent=[]
    for i in range(19):
        theta=math.radians(65+230*i/18);crescent.append((1.1*math.cos(theta),5.65+1.1*math.sin(theta)))
    for i in range(19):
        theta=math.radians(267-174*i/18);crescent.append((.57+.99*math.cos(theta),5.65+.99*math.sin(theta)))
    g.prism(crescent,-2.78,-2.67,"Brass")
    return g,"Back plate reaches Z=-0.14; front +Z. Solid waving swallowtail cloth with crescent heraldry, forged curved cantilever and brass finials. No texture, transparency or animation needed."


def ivy_cluster(a,e):
    g=tracked_mesh(a)
    path=[(0,-.13,0),(.32,-.2,2),(-.25,-.32,4),(.18,-.28,6),(-.12,-.25,8),(.34,-.3,10),(.1,-.25,11.55)]
    g.tube(path,.095,"Wood",sides=6)
    for j in range(6):
        z=1.3+j*1.72
        for side in (-1,1):
            reach=2.75+.28*math.sin(j*1.7)
            points=[(0,-.27,z),(side*1.05,-.40,z+.42),(side*reach,-.43,z+.97)]
            g.tube(points,.055,"Wood",sides=5)
            for i in range(3):
                fraction=(i+.65)/3
                centre=(side*reach*fraction,-.48-.05*(i%2),z+.97*fraction)
                leaf(g,centre,.91,1.20,side*(-.55+.27*i),"Leaf" if (j+i)%3==0 else "Foliage",tilt=.12)
    return g,"Base-centred wall pivot; front +Z. One branching woody vine with 36 thick three-lobed leaves, two green tones and restrained wall projection; no alpha cards."


def herb_shrub(a,e):
    g=tracked_mesh(a)
    mound=a._Mesh();mound.profile([(0,2.65),(.18,3.2),(.53,2.75),(.68,1.7)],sides=12,color="Earth")
    move(g,mound,[[1.18,0,0],[0,.88,0],[0,0,1]])
    for j,(x,y,height) in enumerate(((-1.9,.15,3.45),(1.45,.68,4.1),(.2,-1.4,3.7))):
        g.tube([(x,y,.48),(x-.12,y,1.6),(x+.15,y,height)],.075,"Wood",sides=5)
        for level in range(3):
            z=1.12+level*.85
            for side in (-1,1):
                centre=(x+side*(.48+.13*level),y-.08,z+.27)
                g.tube([(x,y,z),centre],.04,"Wood",sides=5)
                leaf(g,centre,1.25,1.04,side*.86,"Foliage",tilt=.12)
        for k in range(3):
            cx=x+(k-1)*.42;cy=y-.22+k*.12;top=height+.24*(k%2)
            g.tube([(x,y,height-.65),(cx,cy,top)],.035,"Wood",sides=5)
            for petal in range(5):
                angle=math.tau*petal/5
                leaf(g,(cx+.16*math.cos(angle),cy-.08,top+.13*math.sin(angle)),.35,.42,angle,"Flower")
    return g,"Ground pivot centred X/Z, bottom Y=0. Closed low earth pocket, three herb/shrub stems, broad thick leaves and nine restrained five-petal flower clusters."


def yard_winch(a,e):
    g=tracked_mesh(a)
    for x in (-3.25,3.25):
        for side in (-1,1):
            beam(g,a,(x,side*2.15,.12),(x,side*.42,5.38),.65,.62)
        beam(g,a,(x,-1.63,1.3),(x,1.63,1.3),.42,.55)
        g.box((x,0,4.03),(.85,1.55,.88),"Wood")
    for y in (-2.12,2.12):
        g.box((0,y,.21),(7.7,.65,.42),"Wood")
    drum=a._Mesh();drum.profile([(0,1.28),(.18,1.28),(.25,1.04),(3.55,1.04),(3.62,1.28),(3.8,1.28)],sides=12,color="Wood")
    move(g,drum,[[0,0,1],[0,1,0],[-1,0,0]],(-1.9,0,3.63))
    g.tube([(-4.08,0,3.63),(3.78,0,3.63)],.19,"Iron",sides=8)
    for x in (-1.45,-.85,-.25,.35,.95,1.5):
        circle=[(x,1.08*math.cos(math.tau*i/16),3.63+1.08*math.sin(math.tau*i/16)) for i in range(16)]
        g.tube(circle,.075,"Brass",sides=5,closed=True)
    wheel=[(-4.07,1.50*math.cos(math.tau*i/16),3.63+1.50*math.sin(math.tau*i/16)) for i in range(16)]
    g.tube(wheel,.115,"Iron",sides=6,closed=True)
    for i in range(6):
        angle=math.tau*i/6;g.tube([(-4.07,0,3.63),(-4.07,1.49*math.cos(angle),3.63+1.49*math.sin(angle))],.07,"Iron",sides=5)
    g.tube([(-4.07,1.49,3.63),(-4.4,1.49,3.63)],.12,"Wood",sides=8)
    for x in (-1.65,1.65):
        g.box((x,2.67,.84),(.20,1.30,1.45),"Wood")
    for y in (2.09,3.25):
        g.box((0,y,.84),(3.5,.18,1.45),"Wood")
    g.box((0,2.67,.20),(3.5,1.30,.22),"Wood")
    g.tube([(.45,2.64,.3),(.65,2.64,2.5)],.07,"Iron",sides=6)
    g.prism([(.3,2.1),(1.04,2.18),(1.18,2.75),(.54,2.64)],2.57,2.71,"Iron")
    return g,"Ground pivot centred X/Z, bottom Y=0. Static raked timber winch with flanged drum, six rope coils, forged handwheel/crank and open tool crate. No gameplay mechanism or collision."


FACTORIES={"MC_DT_FacadeNiche":facade_niche,"MC_DT_QuoinCornice":quoin_cornice,
           "MC_DT_SlateDormer":slate_dormer,"MC_DT_ChimneyVent":chimney_vent,
           "MC_DT_HeraldicBanner":heraldic_banner,"MC_DT_IvyCluster":ivy_cluster,
           "MC_DT_HerbShrub":herb_shrub,"MC_DT_YardWinch":yard_winch}


def build_recipes(a,e):
    return [(name,*factory(a,e)) for name,factory in FACTORIES.items()]
