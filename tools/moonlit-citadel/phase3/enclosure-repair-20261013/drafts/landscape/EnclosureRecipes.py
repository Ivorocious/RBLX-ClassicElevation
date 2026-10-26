"""Pure Roblox-axis terrain recipes; the lead exports through controlled Blender."""
import math
import json
from pathlib import Path

PALETTE = {"Rock": (100,112,116), "RockA": (100,112,116), "RockB": (100,112,116), "Earth": (100,86,68), "Grass": (91,119,75)}
BOTTOM = -130.0
INNER = (-276.0,246.0,-228.0,228.0)
SITE = (-390.0,390.0,-355.0,350.0)

class Mesh:
    def __init__(self):
        self.vertices,self.faces,self.materials = [],[],[]

    def add(self,vertices,faces,material):
        offset=len(self.vertices)
        self.vertices.extend(vertices)
        self.faces.extend(tuple(offset+i for i in face) for face in faces)
        self.materials.extend([material]*len(faces))

    def bounds(self):
        return tuple(min(v[i] for v in self.vertices) for i in range(3)),tuple(max(v[i] for v in self.vertices) for i in range(3))

    def triangles(self):
        return sum(len(face)-2 for face in self.faces)

def ease(value):
    value=max(0,min(1,value))
    return value*value*(3-2*value)

def rounded_rect_distance(x,z,box):
    x0,x1,z0,z1=box
    return math.hypot(max(x0-x,0,x-x1),max(z0-z,0,z-z1))

FOOTING_BEDS = [((-49,33,-75,1),-34)]
FOOTING_CUTS=[]
for record in json.loads((Path(__file__).parent/"FortressSeats.json").read_text()):
    cf,scale=record["frame"],record["scale"]
    x0,z0,x1,z1=record["footprint"]
    corners=[(cf[0]+cf[3]*x*scale[0]+cf[5]*z*scale[2],cf[2]+cf[9]*x*scale[0]+cf[11]*z*scale[2]) for x,z in [(x0,z0),(x0,z1),(x1,z0),(x1,z1)]]
    box=(min(p[0] for p in corners),max(p[0] for p in corners),min(p[1] for p in corners),max(p[1] for p in corners))
    FOOTING_CUTS.append((record["name"],box,record["bottomY"]+record["burialStuds"]))
FOOTING_CUTS.sort(key=lambda item:item[2])
keep_record=next((item for item in FOOTING_CUTS if item[0] in ("MainKeepShell","GrandKeepUnifiedShell")),None)
if keep_record:FOOTING_BEDS=[(keep_record[1],keep_record[2])]

def height(x,z):
    ravine=-74-14*math.sin((x+z)*.025)-12*math.cos((x-z)*.039)
    for bed,seat in FOOTING_BEDS:
        distance=rounded_rect_distance(x,z,bed)
        ravine=max(ravine,seat-42*ease(distance/30))
    west=(-44+(172+18*math.cos(z*.015))*ease((-244-x)/32))
    east=(-44+(188+24*math.cos(z*.014))*ease((x-224)/22))
    north=(-44+(221+17*math.cos(x*.015))*ease((-204-z)/24))
    south=(-44+(118+16*math.cos(x*.018))*ease((z-214)/14))
    near=max(ravine,west,east,north,south)
    outward=max((-276-x)/114,(x-246)/144,(-228-z)/127,(z-228)/122,0)
    peak=220+20*math.sin(x*.018)+21*math.cos(z*.022)
    for px,pz,rise,rx,rz in [(-355,-285,100,100,85),(-120,-325,96,135,65),(330,-290,112,90,75),(-355,255,75,90,100)]:
        peak+=rise*math.exp(-((x-px)/rx)**2-((z-pz)/rz)**2)
    southeast=math.exp(-((x-340)/180)**2-((z-150)/205)**2)
    south_panorama=math.exp(-((x-65)/205)**2-((z-330)/90)**2)
    peak*=1-.59*southeast-.52*south_panorama
    peak=max(105,min(330,peak))
    result=near+(peak-near)*ease(outward)
    for _,box,seat in FOOTING_CUTS:
        distance=rounded_rect_distance(x,z,box)
        if distance<24:
            result=seat+(result-seat)*ease(distance/24)
    # The retained main keep is a higher rock terrace; deep adjacent wings bury into its shoulder.
    keep_box,keep_seat=FOOTING_BEDS[0]
    keep_distance=rounded_rect_distance(x,z,keep_box)
    if keep_distance<12:result=max(result,keep_seat-56*ease(keep_distance/12))
    return round(result,6)

def axes(low,high,step,extra=()):
    values={float(low),float(high)}
    current=low+step
    while current<high:
        values.add(float(current));current+=step
    values.update(float(value) for value in extra if low<value<high)
    return sorted(values)

INNER_X=axes(-276,246,16,[-264,-252,-244,-236,-144,-49,-23,7,33,188,216,224,236])
INNER_Z=axes(-228,228,16,[-224,-216,-204,-195,-162,-120,-86,-75,-52,-23,1,58,69,86,92,110,146,171,199,214,216])
OUTER_X=sorted(set(axes(-390,390,24,INNER_X)+axes(-390,-276,16)+axes(246,390,16)))
OUTER_Z=sorted(set(axes(-355,350,24,INNER_Z)+axes(-355,-228,16)+axes(228,350,16)))
OUTER_X=sorted(set(round(edge,3) for edge in OUTER_X+[edge for _,box,_ in FOOTING_CUTS for edge in box[:2] if -390<edge<390]))
OUTER_Z=sorted(set(round(edge,3) for edge in OUTER_Z+[edge for _,box,_ in FOOTING_CUTS for edge in box[2:] if -355<edge<350]))
INNER_X=[x for x in OUTER_X if -276<=x<=246]
INNER_Z=[z for z in OUTER_Z if -228<=z<=228]
SECTORS={
    "MC_EC_InnerRavine":(INNER_X,INNER_Z),
    "MC_EC_WestWoodedCliff":([x for x in OUTER_X if x<=-276],INNER_Z),
    "MC_EC_EastPanoramaSlope":([x for x in OUTER_X if x>=246],INNER_Z),
    "MC_EC_NorthHighRidge":(OUTER_X,[z for z in OUTER_Z if z<=-228]),
    "MC_EC_SouthValleyRidge":(OUTER_X,[z for z in OUTER_Z if z>=228]),
}

def terrain(name):
    xs,zs=SECTORS[name]
    mesh=Mesh()
    mesh.vertices=[(x,height(x,z),z) for z in zs for x in xs]
    n=len(xs)
    top_triangles=[]
    occupied=[]
    for row in range(len(zs)-1):
        for column in range(n-1):
            a=row*n+column;b=a+1;c=a+n;d=c+1
            pairs=[(a,c,d),(a,d,b)] if (row+column)%2==0 else [(a,c,b),(b,c,d)]
            for face in pairs:
                points=[mesh.vertices[index] for index in face]
                x=sum(p[0] for p in points)/3;z=sum(p[2] for p in points)/3
                highest=max(p[1] for p in points)
                slope=max(abs(points[i][1]-points[j][1])/max(1,math.hypot(points[i][0]-points[j][0],points[i][2]-points[j][2])) for i in range(3) for j in range(i))
                outside=x<-276 or x>246 or z<-228 or z>228
                material="Grass" if outside and slope<1.28 and highest>8 else "Earth" if outside and slope<1.75 and highest>0 else "Rock"
                mesh.faces.append(face);mesh.materials.append(material)
                top_triangles.append(points)
                occupied.append({"low":[min(p[0] for p in points),BOTTOM,min(p[2] for p in points)],
                                 "high":[max(p[0] for p in points),highest,max(p[2] for p in points)],"top":points})
    # Clockwise in XZ gives the outward-facing side loop; the top triangles point +Y.
    perimeter=list(range(n))+[row*n+n-1 for row in range(1,len(zs))]+list(range((len(zs)-1)*n+n-2,(len(zs)-1)*n-1,-1))+[row*n for row in range(len(zs)-2,0,-1)]
    base=[]
    for index in perimeter:
        x,_,z=mesh.vertices[index]
        base.append(len(mesh.vertices));mesh.vertices.append((x,BOTTOM,z))
    for i,index in enumerate(perimeter):
        following=(i+1)%len(perimeter)
        mesh.faces.append((index,perimeter[following],base[following],base[i]));mesh.materials.append("Rock")
    bottom_center=len(mesh.vertices)
    mesh.vertices.append(((xs[0]+xs[-1])/2,BOTTOM,(zs[0]+zs[-1])/2))
    for i,index in enumerate(base):
        mesh.faces.append((bottom_center,index,base[(i+1)%len(base)]));mesh.materials.append("Rock")
    if name=="MC_EC_InnerRavine":
        split_z=zs[len(zs)//2]
        mesh.materials=[("RockA" if sum(mesh.vertices[index][2] for index in face)/len(face)<=split_z else "RockB") if index<len(top_triangles) else "Rock" for index,face in enumerate(mesh.faces)]
    return mesh,{"xs":xs,"zs":zs,"heights":[[height(x,z) for x in xs] for z in zs],"occupied":occupied,"topTriangles":top_triangles}

def build_recipes():
    recipes={name:terrain(name)[0] for name in SECTORS}
    recipes.update(single_tree_recipes())
    return recipes

def single_tree_recipes():
    from Source48TreeRecipes import Mesh as TreeMesh
    broad=TreeMesh()
    broad.profile((0,0,0),[(-2,.9,.85),(0,.75,.72),(15.6,.55,.50),(22.5,.27,.24)],8,"Wood")
    broad.ellipsoid((0,22,0),(9,8,10),14,7,"Foliage")
    pine=TreeMesh()
    pine.profile((0,0,0),[(-2,.8,.75),(0,.65,.62),(32,.2,.18)],8,"Wood")
    for tier in range(4):
        base=4+tier*27/4;width=7.3*(1-tier*.13);top=min(34,base+30*.44)
        if tier==3:top=34
        pine.profile((0,0,0),[(base,width*.28,width*.28),(base+.6,width,width),(top-.5,.5,.5),(top,.05,.05)],10,"Needles")
    return {"MC_EC_SlopeBroadleaf":broad,"MC_EC_SlopePine":pine}

def sample_height(name,x,z):
    xs,zs=SECTORS[name]
    column=next(i for i in range(len(xs)-1) if xs[i]<=x<=xs[i+1])
    row=next(i for i in range(len(zs)-1) if zs[i]<=z<=zs[i+1])
    a=(xs[column],height(xs[column],zs[row]),zs[row]);b=(xs[column+1],height(xs[column+1],zs[row]),zs[row])
    c=(xs[column],height(xs[column],zs[row+1]),zs[row+1]);d=(xs[column+1],height(xs[column+1],zs[row+1]),zs[row+1])
    faces=[(a,c,d),(a,d,b)] if (row+column)%2==0 else [(a,c,b),(b,c,d)]
    for a,b,c in faces:
        denominator=(b[2]-c[2])*(a[0]-c[0])+(c[0]-b[0])*(a[2]-c[2])
        u=((b[2]-c[2])*(x-c[0])+(c[0]-b[0])*(z-c[2]))/denominator
        w=((c[2]-a[2])*(x-c[0])+(a[0]-c[0])*(z-c[2]))/denominator
        t=1-u-w
        if min(u,w,t)>=-.00001:return u*a[1]+w*b[1]+t*c[1]
    raise ValueError("Tree root outside triangulated terrain")
