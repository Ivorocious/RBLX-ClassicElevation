import hashlib
import json
import re
from pathlib import Path

root = Path.cwd()
verification = (root / "tools/keyboard-circuit/VerifyC07.luau").read_text(encoding="utf-8")
expected = {
    match.group(1): json.loads(match.group(2))
    for match in re.finditer(r'^ \["([^"]+)"\] = ("(?:[^"\\]|\\.)*"),$', verification, re.M)
}
assert len(expected) == 13, len(expected)
destination = root / "docs/artifacts/keyboard-circuit/phase1/history/C07-source-before-C08"
destination.mkdir(parents=True, exist_ok=True)
for name, source in expected.items():
    target = destination / (name + ".luau")
    if target.exists():
        assert target.read_text(encoding="utf-8") == source
    else:
        target.write_text(source, encoding="utf-8", newline="\n")
(destination / "sources.json").write_text(json.dumps(expected, ensure_ascii=False), encoding="utf-8")
print(json.dumps({"saved": len(expected), "location": str(destination)}))
