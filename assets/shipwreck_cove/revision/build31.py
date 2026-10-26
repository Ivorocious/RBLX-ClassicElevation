import bpy,json,bmesh
from pathlib import Path
ROOT=Path(__file__).resolve().parent
source=(ROOT/'assemble_blender.py').read_text()
source=source.replace("'SC_MAP_30']", "'SC_MAP_30','SC_MAP_31']").replace("data['build']=='SC_MAP_30'", "data['build'] in ('SC_MAP_30','SC_MAP_31')")
exec(compile(source,str(ROOT/'assemble_blender.py'),'exec'))
names=['ConnectedShoreBank','ShoreEntry28']+[f'Beach{i}' for i in range(6)]+[f'ShoreDuneFacet{i}' for i in range(3)]
rows=[]
for name in names:
    ob=bpy.data.objects[name]
    mesh=ob.data.copy()
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
    bmesh.ops.dissolve_limit(bm,angle_limit=.001,verts=list(bm.verts),edges=list(bm.edges),delimit=set())
    bm.to_mesh(mesh);bm.free();mesh.calc_loop_triangles()
    triangles=[]
    for face in mesh.loop_triangles:
        points=[ob.matrix_world@mesh.vertices[v].co for v in face.vertices]
        normal=(points[1]-points[0]).cross(points[2]-points[0]).normalized()
        if normal.z>.2:
            triangles.append([[round(p.x,5),round(p.z,5),round(-p.y,5)] for p in points])
    rows.append(dict(name=name,triangles=triangles))
(ROOT/'shore31.json').write_text(json.dumps(rows))
def lua(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(str(k))+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
    return json.dumps(v)
(ROOT.parents[2]/'src/ServerStorage/CourseBuilders/ShipwreckCove/ShoreGeometry.luau').write_text('-- Upper faces exported from Blender by build31.py.\nreturn '+lua(rows)+'\n')
print('shore triangles',sum(len(r['triangles']) for r in rows))
