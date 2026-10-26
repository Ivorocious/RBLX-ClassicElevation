import hashlib
import json
from pathlib import Path

root = Path.cwd()
own = Path(__file__).resolve().parent
fixtures = json.loads((own / "audit-fixtures50.json").read_text(encoding="utf8"))
assert fixtures["pass"] and all(fixtures["fixtures"].values())
for path, expected in fixtures["inputHashes"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
specs = json.loads((own / "source-specs50.json").read_text(encoding="utf8"))
for path, expected in specs["inputHashes"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
templates = json.loads((own / "approved-templates50.json").read_text(encoding="utf8"))
for path, expected in templates["inputHashes"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
files = ["GeometryAudit49.luau", "ExpectedAppearance50.luau", "AuditNative50.luau", "RunAudit50.luau",
         "approved-templates50.json", "source-specs50.json", "audit-fixtures50.json", "NATIVE_AUDIT_INSTRUCTIONS.md"]
report = {"preparedOnly": True, "nativeLiveCompared": False, "offlineFixturesPass": True,
          "candidate": "MC_P3_CLOSEOUT_FC01", "source": 50, "build": 44,
          "expected": {"units": 233, "meshes": 609, "triangles": 197402}, "requiredNativeSources": 1035,
          "inputsUnchanged": True,
          "files": {name: hashlib.sha256((own / name).read_bytes()).hexdigest() for name in files}}
(own / "verification-freeze50.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
print(json.dumps(report))
