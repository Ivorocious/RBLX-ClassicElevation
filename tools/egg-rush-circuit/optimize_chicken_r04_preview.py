"""Reduce the generated review GIF without changing its timing or pose sequence."""
from pathlib import Path
import hashlib
import json
from PIL import Image

folder=Path(__file__).resolve().parents[2]/"docs/artifacts/egg-rush-circuit/phase2/chicken-r04/views"
path=folder/"chicken-peck-cycle.gif"
old_size=path.stat().st_size
frames,durations=[],[]
with Image.open(path) as source:
    source.seek(20)
    palette=source.convert("RGB").resize((640,448),resample=3).quantize(colors=64)
    for index in range(source.n_frames):
        source.seek(index)
        frames.append(source.convert("RGB").resize((640,448),resample=3).quantize(palette=palette,dither=0))
        durations.append(source.info["duration"])
temporary=folder/"chicken-peck-cycle.optimized.gif"
frames[0].save(temporary,save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=True,disposal=2)
with Image.open(temporary) as check:
    assert check.n_frames>=30
    elapsed=0
    for index in range(check.n_frames):
        check.seek(index);elapsed+=check.info["duration"]
    assert elapsed==17250
    count=check.n_frames
temporary.replace(path)
manifest_path=folder/"animation-preview.json"
manifest=json.loads(manifest_path.read_text())
manifest.update(frames=count,size=[640,448],paletteColors=64,bytes=path.stat().st_size,
                sha256=hashlib.sha256(path.read_bytes()).hexdigest(),unoptimizedBytes=old_size)
manifest_path.write_text(json.dumps(manifest,indent=2)+"\n")
print(json.dumps(manifest))
