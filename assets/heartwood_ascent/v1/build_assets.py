"""Repeatable Heartwood V1 art; coordinates are Roblox studs converted to Blender Z-up."""
import bpy, bmesh, math, random, json, struct, zlib, hashlib
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
BUILD = 'HA_V1_01'
random.seed(7301)
bpy.ops.wm.read_factory_settings(use_empty=True)
PALETTE = [(126,78,43),(162,108,62),(99,62,37),(181,127,75),
           (39,83,58),(62,111,64),(88,132,59),(121,151,65),
           (245,163,114),(255,207,153),(255,226,173),(228,135,99),
           (239,184,77),(205,155,61),(64,106,92),(186,167,111)]
def png(path):
    n=64; raw=bytearray()
    for y in range(n):
        raw.append(0)
        for x in range(n): raw.extend((*PALETTE[(y//16)*4+x//16],255))
    def chunk(k,v): return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
png(ROOT/'palette.png')
mat=bpy.data.materials.new('HA_OpaquePalette');mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.82
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'palette.png'));tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
records=[]; packages={}
def convert(p): return (p[0],-p[2],p[1])
class Geo:
    def __init__(self): self.v=[];self.f=[];self.c=[]
    def add(self,vertices,faces,color):
        offset=len(self.v);self.v.extend(convert(p) for p in vertices)
        self.f.extend(tuple(offset+i for i in f) for f in faces)
        self.c.extend(color if isinstance(color,list) else [color]*len(faces))
    def tube(self,points,radii,color=0,sides=12):
        ps=[Vector(p) for p in points]; vertices=[]; faces=[]; colors=[]
        for j,p in enumerate(ps):
            d=(ps[min(j+1,len(ps)-1)]-ps[max(0,j-1)]).normalized()
            u=d.cross(Vector((0,1,0)))
            if u.length<.01:u=d.cross(Vector((1,0,0)))
            u.normalize();w=d.cross(u).normalized()
            for i in range(sides):
                a=i*math.tau/sides
                r=radii[j]*(1+.085*math.sin(a*5+j*.58))
                vertices.append(tuple(p+(u*math.cos(a)+w*math.sin(a))*r))
        for j in range(len(ps)-1):
            for i in range(sides):
                faces.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
                colors.append([color,1,2,color,3,color][i%6] if color<4 else color)
        faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(ps)-1)*sides+i for i in range(sides))]); colors.extend([color,color])
        self.add(vertices,faces,colors)
    def leaf(self,center,length,width,yaw,color=5,bend=.3):
        # A closed curved blade has an actual underside and a visible midrib.
        c=Vector(center); direction=Vector((math.cos(yaw),0,math.sin(yaw))); side=Vector((-direction.z,0,direction.x))
        vertices=[]
        for skin in [0,1]:
            for j in range(7):
                t=j/6; half=width*.5*max(.025,math.sin(math.pi*t))
                for k in [-1,0,1]:
                    p=c+direction*(length*t)+side*(half*k)
                    p.y+=math.sin(math.pi*t)*length*bend+(1-abs(k))*.13*width-(.16 if skin else 0)
                    vertices.append(tuple(p))
        faces=[]
        for j in range(6):
            for k in range(2):
                a=j*3+k;faces.extend([(a,a+1,a+4,a+3),(a+21,a+24,a+25,a+22)])
        for j in range(6):
            a=j*3;faces.append((a,a+3,a+24,a+21));a+=2;faces.append((a,a+21,a+24,a+3))
        faces.extend([(0,21,22,1),(1,22,23,2),(18,19,40,39),(19,20,41,40)])
        self.add(vertices,faces,color)
    def blade_cluster(self,center,scale,count=36):
        c=Vector(center)
        for i in range(count):
            lobe=i%5;la=lobe*math.tau/5
            offset=Vector((math.cos(la)*scale*.23,scale*(.13 if lobe%2 else -.12),math.sin(la)*scale*.23))
            a=random.uniform(0,math.tau);r=math.sqrt(random.random())*scale*.33
            p=c+offset+Vector((math.cos(a)*r,random.uniform(-scale*.23,scale*.25),math.sin(a)*r))
            length=scale*random.uniform(.20,.34);width=length*random.uniform(.46,.72)
            direction=Vector((math.cos(a),random.uniform(-.65,.6),math.sin(a))).normalized();side=Vector((-direction.z,0,direction.x)).normalized()
            points=[p,p+direction*length*.5+side*width*.5,p+direction*length+Vector((0,.2,0)),p+direction*length*.5-side*width*.5,p+direction*length*.5+Vector((0,width*.18,0))]
            lower=[q-Vector((0,.12,0)) for q in points]
            self.add([tuple(q) for q in points+lower],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(5,9,6),(6,9,7),(7,9,8),(8,9,5),
                (0,5,6,1),(1,6,7,2),(2,7,8,3),(3,8,5,0)],random.choice([4,5,5,6,7]))
    def flower(self,radius,finish=False):
        for layer,count in [(0,12),(1,9)]:
            for i in range(count):
                a=math.tau*i/count+layer*.21
                c=(math.cos(a)*radius*.64,-.6+layer*.22,math.sin(a)*radius*.64)
                self.leaf(c,radius*(.92 if layer==0 else .76),radius*.7,a,10 if finish else [8,9,11][i%3],.36)
        self.tube([(0,-1.1,0),(0,-.2,0)], [radius*.93,radius*.85],10 if finish else 9,40)
        for i in range(18):
            a=i*2.399;r=radius*math.sqrt((i+.5)/18)*.53
            self.tube([(math.cos(a)*r,.1,math.sin(a)*r),(math.cos(a)*r,.9,math.sin(a)*r)],[.13,.25],12,5)
def object_from(name,geo,package,origin=(0,0,0)):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(geo.v,[],geo.f);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.location=convert(origin)
    mesh.materials.append(mat);uv=mesh.uv_layers.new(name='PaletteUV')
    for poly,color in zip(mesh.polygons,geo.c):
        for idx in poly.loop_indices: uv.data[idx].uv=((color%4+.5)/4,1-(color//4+.5)/4)
        poly.use_smooth=True
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    mesh.calc_loop_triangles()
    assert len(mesh.vertices)>0 and all(math.isfinite(x) for v in mesh.vertices for x in v.co)
    assert all(poly.area>1e-8 for poly in mesh.polygons),name+' has degenerate faces'
    record={'name':name,'package':package,'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles),'position':origin,
            'bounds_min':[min(v.co[i] for v in mesh.vertices) for i in range(3)],'bounds_max':[max(v.co[i] for v in mesh.vertices) for i in range(3)]}
    records.append(record);packages.setdefault(package,[]).append(obj);return obj

for i,a in enumerate([-.3,.45,1.45,2.6,3.15,4.6]):
    g=Geo();points=[];radii=[]
    for j in range(36):
        y=-5+j*12.5;radius=(66-23*min(y,210)/210) if y<210 else max(7,43-(y-210)*.14)
        angle=a+.14*math.sin(j*.18+i)+max(0,y-210)*.002
        points.append((math.cos(angle)*radius,y,math.sin(angle)*radius-8*j/36))
        radii.append((17+4*math.sin(min(y,210)*math.pi/230)) if y<210 else max(4,20-(y-210)*.065))
    g.tube(points,radii)
    for k in range(3):
        ridge=[(p[0]+math.cos(a+k*.6)*r*.86,p[1],p[2]+math.sin(a+k*.6)*r*.86) for p,r in zip(points,radii)]
        g.tube(ridge,[r*.11 for r in radii],1 if k%2==0 else 2,6)
    object_from('HA_Trunk_%02d'%i,g,'structure')
branches=[([(-32,115,30),(-51,134,39),(-78,145,39),(-109,157,28),(-135,167,24)],[14,14,11,8,3]),
          ([(35,67,-26),(65,74,-20),(97,80,10),(98,85,43)],[13,10,7,3]),
          ([(38,80,36),(62,87,64),(58,98,88),(26,108,91),(0,111,90)],[12,10,8,6,3]),
          ([(-19,115,35),(-40,119,88),(-65,125,119),(-113,131,112),(-127,133,75),(-99,137,49),(-68,137,59)],[12,9,8,7,7,6,4]),
          ([(24,225,-12),(62,249,-21),(101,281,-16),(150,302,-18)],[15,13,9,3]),
          ([(-16,270,18),(-49,305,39),(-102,333,37),(-152,339,12)],[14,13,8,3]),
          ([(10,344,-15),(52,373,-12),(98,401,-7)],[12,9,3]),
          ([(-10,383,9),(-43,409,23),(-77,429,18)],[10,7,2])]
for i,(points,radii) in enumerate(branches):
    g=Geo();dense=[];rs=[]
    for j in range(len(points)-1):
        for k in range(5):
            t=k/5;p0=Vector(points[max(0,j-1)]);p1=Vector(points[j]);p2=Vector(points[j+1]);p3=Vector(points[min(len(points)-1,j+2)])
            p=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
            dense.append(tuple(p));rs.append(radii[j]*(1-t)+radii[j+1]*t)
    dense.append(points[-1]);rs.append(radii[-1]);g.tube(dense,rs)
    for k in range(3):g.tube([(p[0],p[1]+r*.84,p[2]+(k-1)*r*.28) for p,r in zip(dense,rs)],[max(.3,r*.12) for r in rs],1,6)
    object_from('HA_Bough_%02d'%i,g,'structure')
    for j,p in enumerate(points[2:]):
        canopy=Geo();canopy.blade_cluster((0,0,0),random.uniform(52,72) if i>=4 else 24,260 if i>=4 else 100)
        side=Vector((0,-3,14 if j%2 else -14)) if i<4 else Vector((0,6,0))
        object_from('HA_Canopy_%02d_%02d'%(i,j),canopy,'structure',tuple(Vector(p)+side))
for i,point in enumerate([(0,438,-6),(-22,434,10),(22,432,-9),(1,447,1)]):
    g=Geo();g.blade_cluster((0,0,0),57,240);object_from('HA_Crown_%02d'%i,g,'structure',point)
for i in range(9):
    a=math.tau*i/9;g=Geo();ps=[];rs=[]
    for j in range(14):
        t=j/13;r=45+130*t
        arch=42 if i in [3,5] else (16+4*(i%3))
        ps.append((math.cos(a+.22*math.sin(t*4))*r,arch*math.sin(t*math.pi)+2*(1-t),math.sin(a+.22*math.sin(t*4))*r))
        rs.append((13 if i in [3,5] else 18)*(1-t)+2)
    g.tube(ps,rs);object_from('HA_Root_%02d'%i,g,'structure')
g=Geo();g.blade_cluster((0,0,0),9,44);object_from('HA_FoliageCluster',g,'foliage')
g=Geo()
for i in range(12):g.leaf((0,0,0),7*(1-i*.025),2.7,i*math.tau/12,5+i%3,.24)
object_from('HA_Fern',g,'foliage')
for name,radius,finish in [('HA_BloomBroad',11,False),('HA_BloomSmall',3,False),('HA_Sanctuary',17,True)]:
    g=Geo();g.flower(radius,finish);object_from(name,g,'flowers')
g=Geo();g.leaf((-6,0,0),12,12,0,5,.035);object_from('HA_FoldingLeaf',g,'leaf')
g=Geo();g.tube([(0,-4,0),(0,-3,0),(0,0,0),(0,3,0),(0,4.2,0)],[.3,1.8,3,1.5,.12],9,14)
object_from('HA_Seedpod',g,'pod')

for package,objs in packages.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objs:obj.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.export_scene.fbx(filepath=str(ROOT/(package+'.fbx')),use_selection=True,object_types={'MESH'},
        path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y',add_leaf_bones=False)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'heartwood-v1.blend'))
summary={'build':BUILD,'seed':7301,'units':'one Blender unit is one Roblox stud before import normalization',
         'objects':records,'triangles':sum(x['triangles'] for x in records),'packages':{}}
for name in packages:
    p=ROOT/(name+'.fbx');summary['packages'][name]={'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(ROOT/'asset-manifest.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'build':BUILD,'objects':len(records),'triangles':summary['triangles'],'packages':list(packages)}),flush=True)
