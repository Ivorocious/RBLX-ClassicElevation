from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parents[4]
folder = root / "docs/artifacts/keyboard-circuit/phase2"
freeze_name = sys.argv[1] if len(sys.argv) > 1 else "P2-I09-source-freeze-01.json"
output_name = sys.argv[2] if len(sys.argv) > 2 else "P2-I09-freeze-agreement-01.json"
freeze = json.loads((folder / freeze_name).read_text(encoding="utf-8"))
native = json.loads((folder / "P2-I09-native-source-agreement-01.json").read_text(encoding="utf-8"))
frozen = {row["path"]: row["sha256"] for row in freeze["entries"]}
changed = [path for path, sha in frozen.items() if hashlib.sha256((root / path).read_bytes()).hexdigest() != sha]
globals = {
    "ServerScriptService.Services.StudioDevService": "src/ServerScriptService/Services/StudioDevService.luau",
    "StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController": "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau",
    "StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview": "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
}
sources = root / "tools/keyboard-circuit/phase2/work-i09/sources"
by_name = {path.name.removesuffix(".server.luau").removesuffix(".client.luau").removesuffix(".luau"): str(path.relative_to(root)).replace("\\", "/") for path in sources.glob("*.luau")}
mismatches = []
for row in native["rows"]:
    path = globals[row["path"]] if row["path"] in globals else by_name[row["name"]]
    if row["sha256"] != frozen[path]:
        mismatches.append({"native": row["path"], "path": path})
result = {"passed": not changed and not mismatches and len(native["rows"]) == 19, "candidate": freeze["candidate"], "revision": freeze["revision"], "frozenInputs": len(frozen), "nativeSources": len(native["rows"]), "changedInputs": changed, "nativeMismatches": mismatches}
(folder / output_name).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps(result))
assert result["passed"]
