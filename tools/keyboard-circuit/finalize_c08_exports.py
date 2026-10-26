import hashlib
import json
from pathlib import Path

root = Path.cwd().resolve()
phase = root / "docs/artifacts/keyboard-circuit/phase1"
native = phase / "native"
native.mkdir(exist_ok=True)
expected = json.loads((phase / "C08-native-verification.json").read_text(encoding="utf-8"))["native"]
files = {
    "C08": "KeyboardCircuit_P1_C08.rbxm",
    "KitC08": "KeyboardCircuit_EditableKit_K01_C08.rbxm",
    "C07BeforeC08": "KeyboardCircuit_P1_C07_before_C08.rbxm",
    "KitC07BeforeC08": "KeyboardCircuit_EditableKit_K01_C07_before_C08.rbxm",
}
report = {"revision": "KC_P1_C08", "serializer": "Roblox SerializationService", "files": {}}
for name, filename in files.items():
    transfer = root / "tools/keyboard-circuit/transfers" / (name + ".hex")
    destination = native / filename
    if transfer.exists():
        data = bytes.fromhex(transfer.read_text(encoding="ascii"))
    else:
        assert name in {"C07BeforeC08", "KitC07BeforeC08"}, "Current C08 requires a fresh transfer"
        data = destination.read_bytes()
    assert len(data) == expected[name]["bytes"]
    assert data.startswith(b"<roblox!")
    if destination.exists():
        if destination.read_bytes() != data:
            preserved = phase / "history/C08-before-readiness/docs/artifacts/keyboard-circuit/phase1/native" / filename
            assert name in {"C08", "KitC08"} and preserved.read_bytes() == destination.read_bytes(), "Existing export differs: " + filename
            destination.write_bytes(data)
    else:
        with destination.open("xb") as stream:
            stream.write(data)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    report["files"][name] = {"path": destination.relative_to(root).as_posix(), "bytes": len(data), "sha256": digest, "nativeRoundTrip": expected[name]["roundTrip"]}
    if transfer.exists():
        assert transfer.resolve().is_relative_to(root / "tools/keyboard-circuit/transfers")
        transfer.unlink()
report["passed"] = True
(phase / "C08-export-verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps(report))
