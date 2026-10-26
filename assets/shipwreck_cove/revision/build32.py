import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parent
source=(ROOT/'assemble_blender.py').read_text()
source=source.replace("'SC_MAP_30']", "'SC_MAP_30','SC_MAP_32']").replace("data['build']=='SC_MAP_30'", "data['build'] in ('SC_MAP_30','SC_MAP_32')").replace("'SC_MAP_31'","'SC_MAP_32'")
exec(compile(source,str(ROOT/'assemble_blender.py'),'exec'))
