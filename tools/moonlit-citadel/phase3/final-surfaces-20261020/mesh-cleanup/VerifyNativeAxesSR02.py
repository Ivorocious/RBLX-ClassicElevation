"""Repeat independent actual native axes proof for the full plane closure kit."""
from pathlib import Path
HERE=Path(__file__).resolve().parent
source=(HERE/'VerifyNativeAxes57.py').read_text().replace('native-import57.json','native-import-sr02-57.json').replace("OUT=HERE/'proposal01'","OUT=HERE/'proposal02'").replace('native-axes-proof57.json','native-axes-proof-sr02-57.json').replace("native['assetId']","native.get('assetId','99796608028640')")
exec(compile(source,str(HERE/'VerifyNativeAxes57.py'),'exec'))
