from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[4]
folder = root / "docs/artifacts/keyboard-circuit/phase2"
freeze = json.loads((folder / "P2-I08-source-freeze-02.json").read_text(encoding="utf-8"))
native = json.loads((folder / "P2-I08-native-source-agreement-01.json").read_text(encoding="utf-8"))
frozen = {row["path"]: row["sha256"] for row in freeze["entries"]}
changed = [path for path, sha in frozen.items() if hashlib.sha256((root / path).read_bytes()).hexdigest() != sha]
globals = {
    "ServerScriptService.Services.StudioDevService": "src/ServerScriptService/Services/StudioDevService.luau",
    "StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController": "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau",
    "StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview": "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
}
sources = root / "tools/keyboard-circuit/phase2/work-i08/sources"
by_name = {path.name.removesuffix(".server.luau").removesuffix(".client.luau").removesuffix(".luau"): str(path.relative_to(root)).replace("\\", "/") for path in sources.glob("*.luau")}
mismatches = []
for row in native["rows"]:
    path = globals[row["path"]] if row["path"] in globals else by_name[row["name"]]
    if row["sha256"] != frozen[path]:
        mismatches.append({"native": row["path"], "path": path})
result = {"passed": not changed and not mismatches and len(native["rows"]) == 19, "candidate": freeze["candidate"], "revision": freeze["revision"], "frozenInputs": len(frozen), "nativeSources": len(native["rows"]), "changedInputs": changed, "nativeMismatches": mismatches}
(folder / "P2-I08-freeze-agreement-02.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps(result))
assert result["passed"]
