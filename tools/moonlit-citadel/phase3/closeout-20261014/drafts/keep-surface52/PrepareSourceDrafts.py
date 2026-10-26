"""Copy the frozen staging modules and add the one proved material-part adjustment."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
STAGE = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/stage52"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    sources = {}
    for name in ("SceneryRevisions.luau", "WorldAssembly.luau"):
        path = STAGE / name
        data = path.read_bytes()
        assert b"\r" not in data, "Retain the staged LF format."
        sources[name] = data
    scenery = sources["SceneryRevisions.luau"].decode()
    marker = '    CrownSouthJoinedScreen = {asset = "MC_P3_CrownScreen", shift = v(0, -3, 0)},\n'
    assert scenery.count(marker) == 1
    scenery = scenery.replace(marker, marker + '    GrandRearCentralPinnacle = {asset = "MC_TL_GrandPinnacle",\n'
        '        partLocalScaleOverrides = {MC_TL_GrandPinnacle__StoneLight = v(1, 1, 1.04)}},\n')
    marker = '    if edit.shift then revised.localCF += edit.shift end\n'
    assert scenery.count(marker) == 1
    scenery = scenery.replace(marker, marker + '    if edit.partLocalScaleOverrides then\n'
        '        assert(data.library == "TL01", "Keep surface adjustment requires the verified tower library")\n'
        '        revised.partLocalScaleOverrides = edit.partLocalScaleOverrides\n'
        '    end\n')
    marker = '"CrownSouthJoinedScreen"}\n'
    assert scenery.count(marker) == 1
    scenery = scenery.replace(marker, '"CrownSouthJoinedScreen", "GrandRearCentralPinnacle"}\n')
    assembly = sources["WorldAssembly.luau"].decode()
    marker = 'local function place(parent, data, frame, library)\n'
    assert assembly.count(marker) == 1
    assembly = assembly.replace(marker, marker + '\tlocal overrides = data.partLocalScaleOverrides\n'
        '\tif overrides then\n'
        '\t\tassert(data.name == "GrandRearCentralPinnacle" and data.asset == "MC_TL_GrandPinnacle"\n'
        '\t\t\tand data.library == "TL01" and type(overrides) == "table", "Unexpected material-part adjustment")\n'
        '\t\tlocal count = 0\n'
        '\t\tfor name, factor in overrides do\n'
        '\t\t\tassert(name == "MC_TL_GrandPinnacle__StoneLight" and factor == Vector3.new(1, 1, 1.04),\n'
        '\t\t\t\t"Material-part adjustment differs from the proved native depth axis")\n'
        '\t\t\tcount += 1\n'
        '\t\tend\n'
        '\t\tassert(count == 1, "Provide exactly the proved keep material-part adjustment")\n'
        '\tend\n'
        '\tlocal adjusted = 0\n')
    marker = '\t\tpart.Size *= data.scale\n'
    assert assembly.count(marker) == 1
    assembly = assembly.replace(marker, marker + '\t\tlocal factor = overrides and overrides[part.Name]\n'
        '\t\tif factor then\n'
        '\t\t\tassert(part:IsA("MeshPart") and part:GetAttribute("SourceMaterial") == "StoneLight",\n'
        '\t\t\t\t"Keep material adjustment requires the verified StoneLight mesh")\n'
        '\t\t\t-- Native part Z is the proved depth axis; leave its frame and centre exact.\n'
        '\t\t\tpart.Size *= factor\n'
        '\t\t\tadjusted += 1\n'
        '\t\tend\n')
    marker = '\tmodel.WorldPivot = frame\n'
    assert assembly.count(marker) == 1
    assembly = assembly.replace(marker, '\tassert(not overrides or adjusted == 1, "The proved keep material part was not found exactly once")\n'+marker)
    results = {"SceneryRevisions.luau":scenery, "WorldAssembly.luau":assembly}
    records = []
    for name, text in results.items():
        output = HERE / name
        assert not output.exists(), "Preserve existing drafts."
        data = text.encode()
        output.write_bytes(data)
        records.append({"file":name,"sha256":sha(data),"bytes":len(data),
                        "sourceStageFile":str((STAGE/name).relative_to(ROOT)),"sourceStageSHA256":sha(sources[name])})
        assert (STAGE/name).read_bytes() == sources[name]
    (HERE / "source-drafts.json").write_text(json.dumps({"drafts":records,"productionEdited":False,
        "overrideSemantics":"Native part local Size.Z multiplier 1.04 after authorScale; CFrame remains unchanged."}, indent=2)+"\n")
    print(json.dumps(records, indent=2))


if __name__ == "__main__":
    main()
