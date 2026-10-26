import hashlib
import json
from pathlib import Path

root = Path.cwd()
own = Path(__file__).resolve().parent
artifacts = root / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014"
plan_sha = "3b0e592a6695e70a881d30daaa7bfb27915a60bec6acce75e685358b7a7266c2"
packet_sha = "80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617"
assembly_sha = "816d5e4cdeeabbdc3fc5e9fc62758afa5a5eca3aa7737ccd9ee087725b845a4d"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

assert digest(artifacts / "combined-plan52.json") == plan_sha
assert digest(artifacts / "before/closeout_source52_packet.json") == packet_sha
plan = json.loads((artifacts / "combined-plan52.json").read_bytes())
packet = json.loads((artifacts / "before/closeout_source52_packet.json").read_bytes())
assert len(plan["units"]) == 243
assert packet["sourceRevision"] == 52 and packet["buildRevision"] == 46
assert packet["candidate"] == "MC_P3_CLOSEOUT_FC03" and len(packet["records"]) == 30
assert next(row["sha256"] for row in packet["records"] if row["name"] == "WorldAssembly") == assembly_sha
adjusted = [row for row in plan["units"] if row.get("partLocalScaleOverrides")]
assert len(adjusted) == 1 and adjusted[0]["name"] == "GrandRearCentralPinnacle"
overrides = adjusted[0]["partLocalScaleOverrides"]
assert list(overrides) == ["MC_TL_GrandPinnacle__StoneLight"]
assert all(abs(a-b) < 1e-6 for a,b in zip(overrides["MC_TL_GrandPinnacle__StoneLight"], [1, 1, 1.04]))

for name in ("AuditNative52.luau", "RunAudit52.luau"):
    path = own / name
    text = path.read_text(encoding="utf8").replace("PENDING_PLAN_SHA52", plan_sha).replace("PENDING_PACKET_SHA52", packet_sha)
    path.write_text(text, encoding="utf8", newline="")
bindings = json.loads((own / "bindings52.json").read_bytes())
bindings["ready"] = True
bindings["expected"]["packet"] = packet_sha
bindings["planSHA256"] = plan_sha
(own / "bindings52.json").write_text(json.dumps(bindings, indent=2) + "\n", encoding="utf8")

print(json.dumps({"planSHA256": plan_sha, "packetSHA256": packet_sha, "worldAssemblySHA256": assembly_sha, "approvedOverride": overrides}))
