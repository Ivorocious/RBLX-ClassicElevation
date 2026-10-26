"""Lead-run TL01 recipe. Coordinates are Roblox-local studs; no scene deletion or export."""
import bpy

PALETTE = {"Stone": (124,134,149), "StoneLight": (185,190,193), "Slate": (43,60,86)}

class Unit:
    def __init__(self, name):
        self.name = name
        self.geometry = {role: [[], []] for role in PALETTE}

    def append(self, role, vertices, faces):
        target_vertices, target_faces = self.geometry[role]
        offset = len(target_vertices)
        target_vertices.extend((x, -z, y) for x,y,z in vertices)
        target_faces.extend(tuple(offset + index for index in face) for face in faces)

    def box(self, role, low, high):
        x0,y0,z0 = low
        x1,y1,z1 = high
        points = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
                  (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
        self.append(role, points, [(0,3,2,1),(4,5,6,7),(0,1,5,4),
                                   (3,7,6,2),(0,4,7,3),(1,2,6,5)])

    def octagonal_loft(self, role, levels):
        vertices = []
        for y,width,depth in levels:
            x,z = width/2,depth/2
            cut = min(width,depth)*.18
            vertices.extend([(x-cut,y,-z),(-x+cut,y,-z),(-x,y,-z+cut),
                             (-x,y,z-cut),(-x+cut,y,z),(x-cut,y,z),(x,y,z-cut),(x,y,-z+cut)])
        faces = [tuple(reversed(range(8)))]
        for layer in range(len(levels)-1):
            for side in range(8):
                following = (side+1)%8
                faces.append((layer*8+side,layer*8+following,(layer+1)*8+following,(layer+1)*8+side))
        faces.append(tuple((len(levels)-1)*8+side for side in range(8)))
        self.append(role,vertices,faces)

    def weathered_step(self, role, low_y, high_y, low_width, high_width, low_depth, high_depth):
        points = [(-low_width/2,low_y,0),(low_width/2,low_y,0),
                  (low_width/2,low_y,low_depth),(-low_width/2,low_y,low_depth),
                  (-high_width/2,high_y,0),(high_width/2,high_y,0),
                  (high_width/2,high_y,high_depth),(-high_width/2,high_y,high_depth)]
        self.append(role,points,[(1,2,3,0),(7,6,5,4),(4,5,1,0),(5,6,2,1),(6,7,3,2),(7,4,0,3)])

    def lancet(self, x, bottom, width, height, front_z):
        points = [(x-width/2,bottom,front_z),(x+width/2,bottom,front_z),
                  (x+width/2,bottom+height*.72,front_z),(x,bottom+height,front_z),
                  (x-width/2,bottom+height*.72,front_z)]
        points.extend((px,py,front_z-.06) for px,py,_ in points[:])
        faces = [(0,1,2,3,4),(9,8,7,6,5)]
        faces.extend(((side+1)%5,side,side+5,(side+1)%5+5) for side in range(5))
        self.append("Slate",points,faces)

    def build(self, parent):
        collection = bpy.data.collections.new(self.name)
        parent.children.link(collection)
        for role,(vertices,faces) in self.geometry.items():
            if not faces:
                continue
            mesh = bpy.data.meshes.new(self.name + "__" + role)
            mesh.from_pydata(vertices,[],faces)
            mesh.update()
            obj = bpy.data.objects.new(mesh.name,mesh)
            collection.objects.link(obj)
            obj.location = (0,0,0)
            obj["AssetName"],obj["SourceMaterial"] = self.name,role
            obj["PivotConvention"] = "base origin, Roblox front +Z; Blender(X,-Z,Y)"
            material = bpy.data.materials.get("TL01_" + role) or bpy.data.materials.new("TL01_" + role)
            material.diffuse_color = tuple(channel/255 for channel in PALETTE[role]) + (1,)
            obj.data.materials.append(material)
        return collection

def grand_pinnacle():
    unit = Unit("MC_TL_GrandPinnacle")
    unit.box("Stone",(-12,0,-10),(12,8,10))
    unit.box("Stone",(-10,8,-8),(10,46,8))
    unit.octagonal_loft("StoneLight",[(46,23,18),(50,16,14)])
    unit.octagonal_loft("Stone",[(49.99,16,14),(70,16,14)])
    unit.octagonal_loft("StoneLight",[(70,18,16),(73,18,16)])
    unit.octagonal_loft("Slate",[(72.99,18,16),(91,7,6),(103,3,3)])
    unit.octagonal_loft("StoneLight",[(102.99,3,3),(112,.3,.3)])
    for x in (-8.8,8.8):
        unit.box("StoneLight",(x-.7,8,-8),(x+.7,46,8))
    for x in (-5,0,5):
        unit.lancet(x,19,2.4,20,8.035)
    for x in (-4,4):
        unit.lancet(x,55,1.6,11,7.035)
    return unit

def flank_pinnacle():
    unit = Unit("MC_TL_FlankPinnacle")
    unit.box("StoneLight",(-6,0,-6),(6,4,6))
    unit.octagonal_loft("Stone",[(4,10,10),(32,10,10)])
    for x in (-4,4):
        unit.box("StoneLight",(x-.5,4,-5),(x+.5,32,5))
    unit.octagonal_loft("StoneLight",[(32,12,12),(35,12,12)])
    unit.octagonal_loft("Slate",[(34.99,12,12),(51,4.2,4.2),(59,.7,.7)])
    unit.octagonal_loft("StoneLight",[(58.99,.7,.7),(62,.15,.15)])
    unit.lancet(0,12,1.8,13,5.035)
    return unit

def stepped_buttress():
    unit = Unit("MC_TL_SteppedButtress")
    unit.box("Stone",(-4,.01,0),(4,26,12))
    unit.weathered_step("Slate",25.99,33,8,6,12,8)
    unit.box("Stone",(-3,32.99,0),(3,115.98,8))
    unit.weathered_step("Slate",115.99,126,6,4.6,8,5)
    unit.box("Stone",(-2.3,125.99,0),(2.3,155.99,5))
    unit.box("StoneLight",(-4,0,0),(4,3,12))
    unit.box("StoneLight",(-3,113,0),(3,116,8))
    unit.box("StoneLight",(-2.3,153,0),(2.3,156,5))
    return unit

def build_tl01():
    parent = bpy.data.collections.new("MoonlitCitadel_TowerLandscape_TL01")
    bpy.context.scene.collection.children.link(parent)
    return [unit.build(parent) for unit in (grand_pinnacle(),flank_pinnacle(),stepped_buttress())]

# The lead calls build_tl01() in the controlled Blender session, inspects and exports each edit unit.
