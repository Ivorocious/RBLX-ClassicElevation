import hashlib
import json
import re
from pathlib import Path

root = Path.cwd()
own = Path(__file__).resolve().parent
artifacts = root / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def load(path):
    return json.loads(path.read_bytes())

bindings = load(own / "bindings52.json")
assert bindings["ready"]
plan51, plan52 = [load(artifacts / f"combined-plan{number}.json") for number in (51, 52)]
assert digest(artifacts / "combined-plan52.json") == bindings["planSHA256"]
clean_units = [{key: value for key, value in row.items() if key != "partLocalScaleOverrides"} for row in plan52["units"]]
assert clean_units == plan51["units"], "Any placement/scale/role alteration must be rejected"
packets = [load(artifacts / f"before/closeout_source{number}_packet.json") for number in (51, 52)]
old = {row["name"]: row for row in packets[0]["records"]}
new = {row["name"]: row for row in packets[1]["records"]}
assert old.keys() == new.keys() and len(new) == 30
changed = sorted(name for name in old if old[name]["source"] != new[name]["source"])
assert changed == ["SceneryRevisions", "WorldAssembly", "WorldPlan"]
for row in new.values():
    assert hashlib.sha256(row["source"].encode("utf8")).hexdigest() == row["sha256"]
assert digest(artifacts / "before/closeout_source52_packet.json") == bindings["expected"]["packet"]
for number in (51, 52):
    for record in (own.parent / f"verification{number}" / f"approved-templates{number}.json",):
        assert len(load(record)["templates"]) == 36
templates = load(own / "approved-templates52.json")
old_templates = load(own.parent / "verification51/approved-templates51.json")
assert templates["templates"] == old_templates["templates"] and templates["uniqueTemplateParts"] == 101
old_appearance = (own.parent / "verification51/ExpectedAppearance51.luau").read_text(encoding="utf8")
new_appearance = (own / "ExpectedAppearance52.luau").read_text(encoding="utf8")
strip_hash = lambda text: re.sub(r'Appearance.WorldAssemblySHA256 = "[a-f0-9]+"', 'Appearance.WorldAssemblySHA256 = "BOUND"', text)
assert strip_hash(old_appearance) == strip_hash(new_appearance), "Appearance rules must remain identical"

for name in ("source-specs52.json", "approved-templates52.json", "part-override52-focused-check.json", "geometry-override52-fixtures.json"):
    report = load(own / name)
    for path, expected in report["inputHashes"].items():
        assert digest(root / path) == expected, path
focused = load(own / "part-override52-focused-check.json")
fixtures = load(own / "geometry-override52-fixtures.json")
assert focused["pass"] and focused["finalPlan52Bound"] and focused["scannedRows"] == 1 and focused["uniqueVolumes"] == 1586
assert fixtures["pass"] and all(fixtures["fixtures"].values()) and all(focused["fixtures"].values())
assert load(own / "source-specs52.json")["requiredSources"] == 1035
helper = load(own / "helperpacket52.json")
assert len(helper["modules"]) == 5 and helper["sourceRevision"] == 52
for module in helper["modules"]:
    raw = (own / (module["name"] + ".luau")).read_text(encoding="utf8")
    assert raw == module["source"] and hashlib.sha256(raw.encode("utf8")).hexdigest() == module["sha256"]
files = sorted(path.name for path in own.iterdir() if path.is_file() and path.name != "verification-freeze52.json")
report = {"preparedOnly": True, "nativeLiveCompared": False, "candidate": "MC_P3_CLOSEOUT_FC03", "source": 52, "build": 46,
          "expected": bindings["expected"], "planSHA256": bindings["planSHA256"], "requiredNativeSources": 1035,
          "placementScaleRolePreservation51": True, "approvedTemplateIdentitiesAppearancePreserved": True,
          "appearanceRulesIdentical51": True, "packetChangedNamesFrom51": changed,
          "focusedOverrideFixturesPass": True, "correctedBoundingRowPass": True,
          "otherCourseLibraryModels": 4, "workspaceLobbyGrandArcadeProofSeparate": True,
          "savedReopenAndExactWorldDeltaPreparedOnly": True,
          "files": {name: digest(own / name) for name in files}}
(own / "verification-freeze52.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
print(json.dumps({key: value for key, value in report.items() if key != "files"}))
