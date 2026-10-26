"""Apply the existing source and FBX checks to the separate district add-on."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
source = (ROOT / 'audit_assets.py').read_text()
source = source.replace("ROOT=Path(__file__).resolve().parent;OUT=ROOT.parents[2]/'docs/artifacts/city-run/v3'", "ROOT=Path(__file__).resolve().parent/'district_addon01';OUT=ROOT")
source = source.replace('CityRun_V3_AssetKit', 'CityRun_DistrictAddon')
exec(compile(source, str(ROOT / 'audit_assets.py'), 'exec'))
