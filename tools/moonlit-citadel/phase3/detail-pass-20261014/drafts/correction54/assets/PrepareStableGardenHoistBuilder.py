from pathlib import Path

HERE = Path(__file__).resolve().parent
text = (HERE / 'BuildGardenHoistKit.py').read_text(encoding='utf8')
text = text.replace('GardenHoistRecipe.py', 'StableGardenHoistRecipe.py')
text = text.replace('MC_P3_GARDEN_HOIST_DG02', 'MC_P3_GARDEN_HOIST_DG02_R01')
text = text.replace('MC_GARDEN_HOIST_DG02.', 'MC_GARDEN_HOIST_DG02_R01.')
text = text.replace("'DG02_", "'DG02R01_")
text = text.replace("paths.extend([HERE/'GardenRecipe.py',", "paths.extend([HERE/'GardenHoistRecipe.py', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/manifest.json', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/MC_GARDEN_HOIST_DG02.fbx', HERE/'garden-hoist-final-freeze.json', HERE/'GardenRecipe.py',")
text = text.replace('    topology=[mesh_audit(obj) for obj in exported.objects]', '''    for obj in exported.objects:
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='BEAUTY',ngon_method='BEAUTY')
        bm.to_mesh(obj.data);bm.free();obj.data.update(calc_edges=True)
    topology=[mesh_audit(obj) for obj in exported.objects]
    assert all(len(face.vertices)==3 for obj in exported.objects for face in obj.data.polygons)''')
text = text.replace("manifest={'candidate':BUILD", "manifest={'exportAllFacesExplicitTriangles':True,'curveRepair':'Only one Iron wheel and six Brass coils use fixed axial torus frames; all other actual vertex geometry is preserved.', 'candidate':BUILD")
(HERE / 'BuildStableGardenHoistKit.py').write_text(text, encoding='utf8', newline='\n')
