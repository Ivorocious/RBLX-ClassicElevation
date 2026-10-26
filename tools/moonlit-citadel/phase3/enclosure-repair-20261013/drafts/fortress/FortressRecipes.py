"""Closed, reusable fortress units in Roblox XYZ; no Blender side effects."""
import math
PALETTE={"Stone":(155,164,175),"StoneLight":(193,196,195),"StoneDark":(109,121,140),"Slate":(63,80,109),"Iron":(72,83,102)}
class Mesh:
 def __init__(self): self.vertices=[];self.faces=[];self.materials=[];self.occupied=[]
 def add(self,vertices,faces,material):
  offset=len(self.vertices);self.vertices.extend(vertices);self.faces.extend(tuple(i+offset for i in face) for face in faces);self.materials.extend([material]*len(faces))
 def proxy(self,low,high):self.occupied.append({"low":list(low),"high":list(high)})
 def box(self,low,high,material="Stone"):
  x,y,z=low;X,Y,Z=high
  self.add([(x,y,z),(X,y,z),(X,Y,z),(x,Y,z),(x,y,Z),(X,y,Z),(X,Y,Z),(x,Y,Z)],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],material);self.proxy(low,high)
 def prism(self,profile,z0,z1,material):
  profile=[tuple(round(c,8) for c in point) for point in profile]
  profile=[point for index,point in enumerate(profile) if point!=profile[index-1]]
  n=len(profile);self.add([(x,y,z) for z in (z0,z1) for x,y in profile],[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],material)
  self.proxy((min(p[0] for p in profile),min(p[1] for p in profile),z0),(max(p[0] for p in profile),max(p[1] for p in profile),z1))
 def bounds(self):return [min(p[i] for p in self.vertices) for i in range(3)],[max(p[i] for p in self.vertices) for i in range(3)]
 def metadata(self):
  lo,hi=self.bounds();return {"parts":len(set(self.materials)),"triangles":sum(len(f)-2 for f in self.faces),"center":[(lo[i]+hi[i])/2 for i in range(3)],"size":[hi[i]-lo[i] for i in range(3)],"occupied":self.occupied}

def bastion():
 m=Mesh()
 sections=[("StoneLight",[(0,32,30),(8.01,32,30)]),
  ("Stone",[(7.99,31.99,29.99),(14,28,26),(120.01,27.99,25.99)]),
  ("StoneLight",[(119.99,28,26),(126,30,28),(132.01,30,28)]),
  ("Stone",[(131.99,29.99,27.99),(138,25,23),(176.01,24.99,22.99)]),
  ("StoneLight",[(175.99,25,23),(182,28,26),(186.01,28,26)]),
  ("Slate",[(185.99,27.99,25.99),(220,4,4),(224,.8,.8)])]
 # Each color section is a closed component; its cap is buried inside the adjacent section.
 for material,rings in sections:
  points=[]
  for y,x,z in rings:points.extend([(-x,y,-z*.65),(-x*.65,y,-z),(x*.65,y,-z),(x,y,-z*.65),(x,y,z*.65),(x*.65,y,z),(-x*.65,y,z),(-x,y,z*.65)])
  faces=[(7,6,5,4,3,2,1,0),tuple(range((len(rings)-1)*8,len(rings)*8))]
  faces.extend((r*8+i,r*8+(i+1)%8,(r+1)*8+(i+1)%8,(r+1)*8+i) for r in range(len(rings)-1) for i in range(8))
  m.add(points,[tuple(reversed(face)) for face in faces],material)
 for y0,y1,x,z in [(0,14,32,30),(14,120.01,28,26),(119.99,138,30,28),(131.99,186.01,30,28),(185.99,224,28,26)]:m.proxy((-x,y0,-z),(x,y1,z))
 for side in (-1,1):
  for x in (-11,11):m.prism([(x-2,61),(x+2,61),(x+2,91),(x,98),(x-2,91)],side*26.04-.04,side*26.04+.04,"StoneDark")
 return m

def arch_front(m,half,side,top,edge,apex,z0,z1,jambs=True):
 segments=20;step=side*2/segments;inner=[]
 for index in range(segments):
  x0=-side+index*step;x1=x0+step;lower=edge+(apex-edge)*(1-max(abs(x0),abs(x1))/side)
  inner.extend([(x0,lower),(x1,lower)]);m.proxy((x0,lower,z0),(x1,top,z1))
 profile=([(-half,0),(-side,0)]+inner+[(side,0),(half,0),(half,top),(-half,top)]) if jambs else inner+[(side,top),(-side,top)]
 before=len(m.occupied);m.prism(profile,z0,z1,"StoneLight");m.occupied.pop()
 if jambs:m.proxy((-half,0,z0),(-side,top,z1));m.proxy((side,0,z0),(half,top,z1))

def wing():
 m=Mesh();m.box((-50,0,-32),(-34,82,32));m.box((34,0,-32),(50,82,32));m.box((-34,0,-31.9),(34,82,-24.1))
 arch_front(m,34,34,82,56,76,24,32,False)
 m.prism([(-52,82),(52,82),(52,85),(0,104),(-52,85)],-34,34,"Slate")
 m.box((-34,83,-31),(34,106,-5))
 m.prism([(-36,106),(36,106),(36,109),(0,124),(-36,109)],-33,-3,"Slate")
 for side in (-1,1):
  for z in (-25,8):m.box((side*50-1.5,0,z-3),(side*50+1.5,73,z+3),"StoneLight")
 for x in (-20,0,20):m.prism([(x-2,91),(x+2,91),(x+2,101),(x,105),(x-2,101)],-4.96,-4.88,"StoneDark")
 return m

def gate():
 m=Mesh();arch_front(m,62,42,126,72,108,-22,22)
 for side in (-1,1):m.box((side*52-13,0,-24),(side*52+13,18,24));m.box((side*52-11,18,-24),(side*52+11,26,24),"StoneLight")
 m.prism([(-66,126),(66,126),(66,129),(0,150),(-66,129)],-25,25,"Slate")
 for side in (-1,1):m.box((side*52-4,26,22),(side*52+4,116,28),"StoneLight")
 return m

def rampart():
 m=Mesh();m.prism([(-48,0),(48,0),(48,32),(-48,32)],-10,10,"Stone")
 m.box((-50,32,-11),(50,36,11),"StoneLight")
 for x in range(-48,49,16):m.box((x-4,36,-10),(x+4,48,10))
 for x in (-32,0,32):m.box((x-3,0,-12),(x+3,29,-10),"StoneDark")
 return m

def court():
 m=Mesh();m.box((-55,0,-45),(55,12,45));m.box((-50,12,-40),(50,42,40));m.box((-47,42,-37),(47,66,37));m.box((-49,66,-39),(49,70,39),"StoneLight")
 # Courts stay behind tall enclosing parapets and are outside reachable route regions.
 for side in (-1,1):m.box((side*45-4,70,-37),(side*45+4,84,37))
 m.box((-41,69.95,-37),(41,84.05,-30));m.box((-41,69.95,30),(41,84.05,37))
 for x in (-36,-18,0,18,36):m.box((x-3,84,-37),(x+3,90,-30),"Slate")
 return m

def hood():
 m=Mesh()
 for side in (-1,1):
  m.box((side*92-14,0,-25),(side*92+14,182,25))
  m.box((side*92-16,0,-27),(side*92+16,14,27),"StoneLight")
  m.box((side*92-12,182,-23),(side*92+12,262,23))
  m.box((side*92-15,248,-25),(side*92+15,266,25),"StoneLight")
 m.box((-92,266,-25),(92,274,25),"Iron")
 m.prism([(-110,274),(110,274),(110,278),(0,310),(-110,278)],-29,29,"Slate")
 for z in (-22,22):m.box((-76,260,z-2),(76,266,z+2),"Iron")
 return m

def bracket():
 m=Mesh();m.box((-3,-20,18),(3,3,24));m.box((-2,-2,0),(2,2,24),"Iron")
 m.add([(x,y,z) for x in (-2,2) for y,z in [(-2,12),(-2,18),(-16,18)]],[(2,1,0),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)],"Iron");m.proxy((-2,-16,12),(2,-2,18))
 m.box((-4,-21,18),(4,-18,25));m.box((-1.5,-14,17),(1.5,-2,20),"Iron")
 return m

BUILDERS={"MC_ER_Bastion":bastion,"MC_ER_SteppedWing":wing,"MC_ER_ForwardGate":gate,"MC_ER_Rampart":rampart,"MC_ER_RaisedCourt":court,"MC_ER_LiftHood":hood,"MC_ER_LanternBracket":bracket}
def build_recipes():return {name:builder() for name,builder in BUILDERS.items()}
