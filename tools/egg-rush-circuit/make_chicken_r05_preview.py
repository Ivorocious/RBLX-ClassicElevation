"""Assemble the rendered native-pose sequence and discard its verified intermediates."""
from pathlib import Path
import hashlib
import json
from PIL import Image

root=Path(__file__).resolve().parents[2]
folder=root/"docs/artifacts/egg-rush-circuit/phase2/chicken-r05/views"
frames=sorted((folder/"animation").glob("frame_*.png"))
assert len(frames)==208
palette=Image.open(frames[20]).convert("RGB").quantize(colors=96)
images=[]
for path in frames[:-1]:
    with Image.open(path) as source:
        images.append(source.convert("RGB").quantize(palette=palette,dither=0))
durations=[(round((i+1)*1725/207)-round(i*1725/207))*10 for i in range(207)]
target=folder/"chicken-peck-cycle.gif"
images[0].save(target,save_all=True,append_images=images[1:],duration=durations,loop=0,optimize=True,disposal=2)
with Image.open(target) as check:
    assert 30<=check.n_frames<=207
    encoded_frames=check.n_frames
    elapsed=0
    for i in range(check.n_frames):
        check.seek(i);elapsed+=check.info["duration"]
    assert elapsed==17250
report={"sourceSamples":208,"frames":encoded_frames,"seconds":elapsed/1000,"bytes":target.stat().st_size,
        "sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
        "boundary":"Blender reconstruction of208 sampled native controller poses; not a Studio recording"}
(folder/"animation-preview.json").write_text(json.dumps(report,indent=2)+"\n")
for path in frames:
    assert path.resolve().is_relative_to((folder/"animation").resolve()) and path.name.startswith("frame_")
    path.unlink()
(folder/"animation").rmdir()
print(json.dumps(report))
