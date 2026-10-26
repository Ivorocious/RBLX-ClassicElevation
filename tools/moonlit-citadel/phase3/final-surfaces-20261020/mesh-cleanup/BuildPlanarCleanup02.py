"""Close every exact same-facing overlap plane on the guarded affected meshes."""
from pathlib import Path
import sys
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
import BuildPlanarCleanup as build
build.OUT=HERE/'proposal02'
build.ALL_EXACT_PLANES=True
build.KIT_NAME='MC_EXPOSED_PLANAR_UNION02'
build.main()
