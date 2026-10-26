"""Repeat saved-float and FBX proof for the expanded plane closure."""
from pathlib import Path
HERE=Path(__file__).resolve().parent
source=(HERE/'VerifyPlanarCleanup.py').read_text().replace("OUT=HERE/'proposal01'","OUT=HERE/'proposal02'").replace('MC_EXPOSED_PLANAR_UNION01','MC_EXPOSED_PLANAR_UNION02')
exec(compile(source,str(HERE/'VerifyPlanarCleanup.py'),'exec'))
