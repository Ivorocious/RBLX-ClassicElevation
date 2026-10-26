import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parent
source=(ROOT/'assemble_blender.py').read_text()
source=source.replace("'SC_MAP_30']", "'SC_MAP_30','SC_MAP_33']").replace("data['build']=='SC_MAP_30'", "data['build'] in ('SC_MAP_30','SC_MAP_33')").replace("'SC_MAP_31'","'SC_MAP_33'")
source=source.replace('groups={}', '''
with bpy.data.libraries.load(str(ROOT.parents[2]/'docs/artifacts/shipwreck-cove/review33/SC_R_Horizon28_NormalFix33.blend'),link=False) as (src,dst):
    dst.meshes=[name for name in src.meshes if name.startswith('SC_R_Horizon28')]
assert len(dst.meshes)==1 and dst.meshes[0] is not None,'Corrected mountain mesh missing'
meshes['SC_R_Horizon28']=dst.meshes[0]
groups={}
''')
exec(compile(source,str(ROOT/'assemble_blender.py'),'exec'))
