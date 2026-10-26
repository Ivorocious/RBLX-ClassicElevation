"""Fetch only the public recordings selected from Creator Store for local audition."""
import json
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen

destination = Path("docs/artifacts/keyboard-circuit/phase1/audio/C07")
destination.mkdir(exist_ok=True)
assets = {
    "Creamy_down": "136185332283213", "Creamy_up": "84458483180547",
    "Thocky_down": "140067773632575", "Thocky_up": "73995464860692",
    "Clacky_down": "138741356128554", "Clacky_up": "134668651361926",
    "Clicky_down": "118137355838031", "Clicky_up": "72521239166699",
}
results = {}
for name, asset_id in assets.items():
    try:
        with urlopen(f"https://assetdelivery.roblox.com/v1/asset/?id={asset_id}", timeout=15) as response:
            data = response.read()
        if not data.startswith(b"OggS"):
            results[name] = {"id": asset_id, "status": "not_ogg", "bytes": len(data)}
            continue
        (destination / f"{name}.ogg").write_bytes(data)
        results[name] = {"id": asset_id, "status": "downloaded", "bytes": len(data)}
    except HTTPError as error:
        results[name] = {"id": asset_id, "status": "http_error", "code": error.code}
    except Exception as error:
        results[name] = {"id": asset_id, "status": "error", "error": str(error)}
(destination / "delivery.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
print(json.dumps(results))
