"""Durable Source48 behavior hashes; native model comparison remains lead-owned."""
import argparse
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())


def current():
    path = ROOT / "tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/source_baseline.py"
    spec = importlib.util.spec_from_file_location("protected_source_pattern", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    state = module.current()
    state["requiredNativeIdentity"] = {"candidate": "MC_P3_TOWER_LANDSCAPE_TL05", "source": 48, "build": 42,
                                       "packet": "dc978a45fda66d27d79b34f2d08458c5a42d8ea8a473e6c8d5f25ab81235eb34"}
    state["scope"] = "Exact existing protected source pattern and accepted arrow tail; filesystem only."
    return state


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["capture", "compare"])
    parser.add_argument("--baseline", default="source48-protected-sources.json")
    args = parser.parse_args()
    path = (HERE / args.baseline).resolve()
    assert path.is_relative_to(HERE)
    state = current()
    if args.mode == "capture":
        assert not path.exists(), "Keep original baseline; use a fresh filename if explicitly needed."
        path.write_text(json.dumps(state, indent=2)+"\n", encoding="utf-8")
        print(json.dumps({"captured_source_entries": len(state["files"]), "native_compared": False}))
    else:
        baseline = json.loads(path.read_text(encoding="utf-8"))
        names = set(baseline["files"]) | set(state["files"])
        changed = [n for n in sorted(names) if baseline["files"].get(n) != state["files"].get(n)]
        report = {"passed": not changed, "checked": len(names), "changed": changed, "native_compared": False}
        (HERE / "protected-source-comparison.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
        print(json.dumps(report))
        raise SystemExit(bool(changed))


if __name__ == "__main__":
    main()
