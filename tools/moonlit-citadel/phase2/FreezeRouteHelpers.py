from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[3]
output = root / "docs/artifacts/moonlit-citadel/phase2/MC_P2_R06_route_commands02.json"
items = [
    ("tools/moonlit-citadel/phase2/R06RouteCommand.server.luau", "Script", "ServerScriptService/R06RouteCommandServer"),
    ("tools/moonlit-citadel/phase2/R06RouteCommand.client.luau", "LocalScript", "Players/ThisisIvorrovI/PlayerGui/R06RouteCommandClient"),
    ("docs/artifacts/moonlit-citadel/phase2/revision06/review_route/R06CatchRouteRunner.luau", "ModuleScript", "ReplicatedStorage/MoonlitPhase2Tools/R06CatchRouteRunner"),
    ("docs/artifacts/moonlit-citadel/phase2/revision06/review_route/R06NoJumpRepresentative.luau", "ModuleScript", "ServerStorage/MoonlitPhase2Tools/R06NoJumpRepresentative"),
    ("docs/artifacts/moonlit-citadel/phase2/revision06/review_route/R06NoJumpRepresentative.luau", "ModuleScript", "ReplicatedStorage/MoonlitPhase2Tools/R06NoJumpRepresentative"),
]
rows = []
for path, kind, target in items:
    data = (root / path).read_bytes()
    source = data.decode("utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
    rows.append({"path": path, "className": kind, "target": target, "source": source,
                 "rawSha256": hashlib.sha256(data).hexdigest(),
                 "normalizedSha256": hashlib.sha256(source.encode()).hexdigest()})
packet = {"candidate": "MC_P2_C01_R06", "originalPlaceId": 85558151074819,
          "originalGameId": 10191126818, "originalCreatorId": 86069177,
          "installDisabled": True, "activateOnlyAfterOrdinaryExport": True, "scripts": rows}
encoded = (json.dumps(packet, indent=2, ensure_ascii=False) + "\n").encode()
with output.open("xb") as file:
    file.write(encoded)
print(json.dumps({"path": str(output), "sha256": hashlib.sha256(encoded).hexdigest(), "bytes": len(encoded), "targets": len(rows)}))
