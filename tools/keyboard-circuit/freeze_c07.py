import hashlib
import json
from pathlib import Path

root = Path.cwd()
destination = root / "docs/artifacts/keyboard-circuit/phase1"
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

sources = sorted((root / "src/ServerStorage/CourseBuilders/KeyboardCircuit").glob("*.luau"))
sources += [root / path for path in [
    "src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitFeedback.luau",
    "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPreview.client.luau",
]]
source_rows = sorted([{"path": p.relative_to(root).as_posix(), "sha256": sha(p)} for p in sources], key=lambda r: r["path"])
fingerprint = hashlib.sha256("".join(r["path"] + "\0" + r["sha256"] + "\n" for r in source_rows).encode()).hexdigest()
core = {name: {"sha256": sha(destination / (name + "-native.rbxm")), "bytes": (destination / (name + "-native.rbxm")).stat().st_size} for name in ["C07", "KitC07", "C07Prototype", "KitC07Prototype"]}
hashes = {"revision": "KC_P1_C07", "sourceFingerprint": fingerprint, "sourceFingerprintAlgorithm": "SHA256 of sorted path NUL file-sha LF records", "sources": source_rows, "native": core}
(destination / "C07-native-hashes.json").write_text(json.dumps(hashes, indent=2) + "\n", encoding="utf-8")
files = set(sources)
for pattern in ["C07*.json", "C07*.md", "C07*-native.rbxm", "KitC07*-native.rbxm", "KC_C07_*.png"]:
    files.update(destination.glob(pattern))
files.discard(destination / "C07-evidence-manifest.json")
files.update((destination / "audio/C07").glob("*.json"))
files.add(root / "tools/keyboard-circuit/VerifyC07.luau")
files.add(destination / "reviews/OWNER-IMPROVEMENTS-XHIGH.md")
rows = [{"path": p.relative_to(root).as_posix(), "bytes": p.stat().st_size, "sha256": sha(p)} for p in sorted(files)]
manifest = {"revision": "KC_P1_C07", "sourceFingerprint": fingerprint, "native": core, "files": rows, "limits": "Frozen C07 evidence. Review reports, gate receipts and mutable project tracking are separate."}
(destination / "C07-evidence-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"sourceFingerprint": fingerprint, "native": core, "manifestSha256": sha(destination / "C07-evidence-manifest.json"), "files": len(rows)}))
