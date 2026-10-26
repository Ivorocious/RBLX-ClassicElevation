import hashlib
import json
from pathlib import Path

own = Path(__file__).resolve().parent
modules = []
for name in ("GeometryAudit52", "PartAdjustmentOracle52", "ExpectedAppearance52", "AuditNative52", "RunAudit52"):
    source = (own / (name + ".luau")).read_text(encoding="utf8").replace("\r\n", "\n")
    modules.append({"name": name, "source": source, "sha256": hashlib.sha256(source.encode("utf8")).hexdigest()})
packet = {"schema": 1, "candidate": "MC_P3_CLOSEOUT_FC03", "sourceRevision": 52, "buildRevision": 46,
          "expected": {"units": 243, "meshes": 639, "triangles": 198722}, "modules": modules,
          "productionMutation": False, "readOnlyAuditFunctions": True}
path = own / "helperpacket52.json"
path.write_text(json.dumps(packet, separators=(",", ":"), ensure_ascii=False), encoding="utf8")
print(json.dumps({"bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                  "modules": [{"name": r["name"], "sha256": r["sha256"]} for r in modules]}))
