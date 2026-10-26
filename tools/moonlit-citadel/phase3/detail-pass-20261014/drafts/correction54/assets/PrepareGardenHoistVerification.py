from pathlib import Path

HERE = Path(__file__).resolve().parent
text = (HERE / 'VerifyGardenKit.py').read_text(encoding='utf8')
for old, new in (
    ('correction54/dg01', 'correction54/dg02'),
    ('MC_WALL_GARDEN_DG01', 'MC_GARDEN_HOIST_DG02'),
    ('BuildGardenKit.py', 'BuildGardenHoistKit.py'),
    ('DG01_Export_Material_Parts', 'DG02_Export_Material_Parts'),
    ('len(saved)==3', 'len(saved)==6'), ('len(actual)==3', 'len(actual)==6'),
    ('==1662', '==3258'), ("'parts':3,'triangles':1662", "'parts':6,'triangles':3258"),
    ('garden-readonly-roundtrip.json', 'garden-hoist-readonly-roundtrip.json')):
    text = text.replace(old, new)
(HERE / 'VerifyGardenHoistKit.py').write_text(text, encoding='utf8', newline='\n')
