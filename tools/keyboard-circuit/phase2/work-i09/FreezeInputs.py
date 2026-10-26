from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parents[4]
work = root / "tools/keyboard-circuit/phase2/work-i09"
files = sorted((work / "sources").glob("*.luau")) + sorted(work.glob("*.luau")) + [
    root / "src/ServerScriptService/Services/StudioDevService.luau",
    root / "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau",
    root / "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
]
entries = [{"path": str(path.relative_to(root)).replace("\\", "/"), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size} for path in files]
result = {"candidate": "KeyboardCircuit_P2_I09_Experience02", "revision": "KC_P2_I09_02", "requiredLaps": 2, "entries": entries, "count": len(entries)}
output = root / "docs/artifacts/keyboard-circuit/phase2" / (sys.argv[1] if len(sys.argv) > 1 else "P2-I09-source-freeze-01.json")
output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"frozen": len(entries), "output": str(output)}))
