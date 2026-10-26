from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
work = root / "tools/keyboard-circuit/phase2/work-i08"
files = sorted((work / "sources").glob("*.luau")) + sorted(work.glob("*.luau")) + [
    root / "src/ServerScriptService/Services/StudioDevService.luau",
    root / "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau",
    root / "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
]
entries = [{"path": str(path.relative_to(root)).replace("\\", "/"), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size} for path in files]
result = {"candidate": "KeyboardCircuit_P2_I08_TwoLaps01", "revision": "KC_P2_I08_01", "requiredLaps": 2, "entries": entries, "count": len(entries)}
output = root / "docs/artifacts/keyboard-circuit/phase2/P2-I08-source-freeze-02.json"
output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"frozen": len(entries), "output": str(output)}))
