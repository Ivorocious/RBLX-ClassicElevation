import hashlib
import json
from pathlib import Path

root = Path.cwd()
own = Path(__file__).resolve().parent
fixtures = json.loads((own / "audit-fixtures51.json").read_text(encoding="utf8"))
assert fixtures["pass"] and all(fixtures["fixtures"].values())
for path, expected in fixtures["inputHashes"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
specs = json.loads((own / "source-specs51.json").read_text(encoding="utf8"))
for path, expected in specs["inputHashes"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
templates = json.loads((own / "approved-templates51.json").read_text(encoding="utf8"))
for path, expected in templates["inputHashes"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
files = ["GeometryAudit49.luau", "ExpectedAppearance51.luau", "AuditNative51.luau", "RunAudit51.luau",
         "approved-templates51.json", "source-specs51.json", "audit-fixtures51.json", "NATIVE_AUDIT_INSTRUCTIONS.md"]
report = {"preparedOnly": True, "nativeLiveCompared": False, "offlineFixturesPass": True,
          "candidate": "MC_P3_CLOSEOUT_FC02", "source": 51, "build": 45,
          "expected": {"units": 243, "meshes": 639, "triangles": 198722}, "requiredNativeSources": 1035,
          "inputsUnchanged": True,
          "files": {name: hashlib.sha256((own / name).read_bytes()).hexdigest() for name in files}}
(own / "verification-freeze51.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
print(json.dumps(report))
