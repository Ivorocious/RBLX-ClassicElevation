import hashlib
import json
import shutil
from pathlib import Path

root = Path.cwd().resolve()
phase = root / "docs/artifacts/keyboard-circuit/phase1"
destination = phase / "history/C08-before-readiness"
assert not destination.exists(), "Preservation already exists; inspect before rerunning"
manifest = json.loads((phase / "C08-evidence-manifest.json").read_text(encoding="utf-8"))
for item in manifest["files"]:
    source = root / item["path"]
    data = source.read_bytes()
    assert hashlib.sha256(data).hexdigest() == item["sha256"], item["path"]
    target = destination / item["path"]
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
for name in ["C08-evidence-manifest.json", "C08-freeze-verification.json"]:
    shutil.copy2(phase / name, destination / name)
receipt = {
    "candidate": "KC_P1_C08",
    "preservedFiles": len(manifest["files"]) + 2,
    "manifestSha256": hashlib.sha256((phase / "C08-evidence-manifest.json").read_bytes()).hexdigest(),
    "ownerCheckpointAccepted": True,
    "acceptanceBasis": "Owner checkpoint conveyed by the Course Ideation chat; current Phase 1 build accepted before the readiness fix.",
    "phase2": "on hold pending fresh five-judge gate and final pass",
    "passed": True,
}
(destination / "preservation.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps(receipt))
