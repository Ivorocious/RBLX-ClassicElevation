"""Derive small read-only template references from the proven native vertex snapshot."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p/"default.project.json").exists())
path = ROOT/"docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_native_vertices49.json"
data = path.read_bytes()
digest = hashlib.sha256(data).hexdigest()
assert digest == "10da46e53127ed4b8ce8bf8a851145f0118a8ca570463643b6338e5ec0d94e0f"
source = json.loads(data.decode("utf-8"))
assert len(source["parts"]) == 53
result = {"approvedAssetId":"83390081804897","nativeSnapshotSHA256":digest,
          "parts":[{key:row[key] for key in ["name","meshId","cf","size"]} for row in source["parts"]]}
(HERE/"approved-template-metadata49.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"parts":len(result["parts"]),"nativeSnapshotSHA256":digest}))
