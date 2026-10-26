import hashlib
import json
from pathlib import Path

root = Path.cwd()
own = Path(__file__).resolve().parent
before = root / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before"
current_file = before / "closeout_current_otherwork.json"
packet_file = before / "closeout_source52_packet.json"
packet_bytes = packet_file.read_bytes()
assert hashlib.sha256(packet_bytes).hexdigest() == "80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617"
current = json.loads(current_file.read_text(encoding="utf8"))
packet = json.loads(packet_bytes)
assert packet["sourceRevision"] == 52 and packet["buildRevision"] == 46 and len(packet["records"]) == 30
assert packet["candidate"] == "MC_P3_CLOSEOUT_FC03"
specs = {name: {"name": name, "expectedSHA256": digest, "normalization": "lf", "expectedFrom": "Fresh post-Race-Flow native source inventory"}
         for name, digest in current["sources"].items()}
for row in packet["records"]:
    assert hashlib.sha256(row["source"].encode("utf8")).hexdigest() == row["sha256"]
    folder = "ReplicatedStorage.Config" if row["name"] == "MoonlitCitadelAmbienceConfig" else "ServerStorage.CourseBuilders.MoonlitCitadelCourse"
    name = folder + "." + row["name"]
    specs[name] = {"name": name, "expectedSHA256": row["sha256"], "normalization": "lf", "expectedFrom": "Final Source52 packet"}
assert len(specs) == 1035
result = {"schema": 1, "requiredSources": len(specs), "specs": [specs[name] for name in sorted(specs)],
          "packetSHA256": hashlib.sha256(packet_bytes).hexdigest(), "freshNativeSourceCount": len(current["sources"]),
          "inputHashes": {str(path.relative_to(root)).replace("\\", "/"): hashlib.sha256(path.read_bytes()).hexdigest()
                          for path in (current_file, packet_file)}}
(own / "source-specs52.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf8")
print(json.dumps({"requiredSources": len(specs), "freshNativeSourceCount": len(current["sources"]), "packetRecords": len(packet["records"])}))
