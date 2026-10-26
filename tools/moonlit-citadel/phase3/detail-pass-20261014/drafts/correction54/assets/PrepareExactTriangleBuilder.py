from pathlib import Path

HERE = Path(__file__).resolve().parent
text = (HERE / 'BuildStableGardenHoistKit.py').read_text(encoding='utf8')
old = '''    for obj in exported.objects:
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='BEAUTY',ngon_method='BEAUTY')
        bm.to_mesh(obj.data);bm.free();obj.data.update(calc_edges=True)'''
new = '''    for obj in exported.objects:
        source=obj.data;source.calc_loop_triangles()
        mesh=bpy.data.meshes.new(source.name+'_ExplicitLoopTriangles')
        mesh.from_pydata([tuple(vertex.co) for vertex in source.vertices],[],[tuple(face.vertices) for face in source.loop_triangles])
        for material_slot in source.materials:mesh.materials.append(material_slot)
        for face,source_triangle in zip(mesh.polygons,source.loop_triangles):
            face.material_index=source_triangle.material_index
            face.use_smooth=source.polygons[source_triangle.polygon_index].use_smooth
        mesh.update(calc_edges=True);obj.data=mesh'''
assert old in text
text = text.replace(old,new)
(HERE / 'BuildExactTriangleGardenHoistKit.py').write_text(text, encoding='utf8', newline='\n')
