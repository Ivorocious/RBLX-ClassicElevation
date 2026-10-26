from pathlib import Path

HERE = Path(__file__).resolve().parent
text = (HERE / 'CombineGardenHoistMetadata.py').read_text(encoding='utf8')
text = text.replace("NEW = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02'", "NEW = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/r01/final'")
text = text.replace("(NEW, 'MC_GARDEN_HOIST_DG02.fbx')", "(NEW, 'MC_GARDEN_HOIST_DG02_R01.fbx')")
text = text.replace("sha(NEW / 'MC_GARDEN_HOIST_DG02.fbx')", "sha(NEW / 'MC_GARDEN_HOIST_DG02_R01.fbx')")
text = text.replace("'nativeImportVerified': False,", "'nativeImportVerified': False, 'repairedDG02R01': True, 'allNewFbxFacesExplicitTriangles': True,")
exec(compile(text, str(HERE / 'CombineStableGardenHoistMetadata.py'), 'exec'))
