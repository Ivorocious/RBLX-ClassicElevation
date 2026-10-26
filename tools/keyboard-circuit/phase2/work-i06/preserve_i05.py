from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
package = root / "docs/artifacts/keyboard-circuit/phase2"
manifest = package / "P2-C01-I05-FROZEN.json"
archive = package / "history/I05-freeze"
data = json.loads(manifest.read_text(encoding="utf-8"))
assert data["candidate"] == "KC_P2_C01-I05-UI01"
assert len(data["entries"]) == 173

for entry in data["entries"]:
    source = root / entry["path"]
    content = source.read_bytes()
    assert len(content) == entry["bytes"]
    assert hashlib.sha256(content).hexdigest() == entry["sha256"], entry["path"]

for entry in data["entries"]:
    source = root / entry["path"]
    target = archive / entry["path"]
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        assert target.read_bytes() == source.read_bytes(), target
    else:
        target.write_bytes(source.read_bytes())

copy = archive / manifest.name
if copy.exists():
    assert copy.read_bytes() == manifest.read_bytes()
else:
    copy.write_bytes(manifest.read_bytes())

for entry in data["entries"]:
    content = (archive / entry["path"]).read_bytes()
    assert hashlib.sha256(content).hexdigest() == entry["sha256"], entry["path"]

print(json.dumps({"candidate": data["candidate"], "entries": len(data["entries"]),
    "bytes": sum(row["bytes"] for row in data["entries"]),
    "archive": str(archive),
    "manifestSha256": hashlib.sha256(copy.read_bytes()).hexdigest(), "verified": True}))
