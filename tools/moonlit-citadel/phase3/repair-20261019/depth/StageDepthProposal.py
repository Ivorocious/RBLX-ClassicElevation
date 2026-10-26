"""Write a local substitution proposal; production source is read only."""
import difflib
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
SOURCE = ROOT / "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse"
spec = importlib.util.spec_from_file_location("depth_recipe", HERE / "DepthChasmRecipe.py")
recipe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recipe)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text, before, after):
    assert text.count(before) == 1, before
    return text.replace(before, after)


def main():
    manifest_path = HERE / "dp01f/manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert manifest["fbxRoundtripOrientedTrianglesExact"] and manifest["export_triangles"] == 18060
    data = recipe.build()
    selected = [index + 1 for index in data["retainedOriginalTopIndices"]]
    runs = []
    for index in selected:
        if runs and runs[-1][1] + 1 == index:
            runs[-1][1] = index
        else:
            runs.append([index, index])
    lines = ["--!nonstrict", "local Terrain = require(script.Parent.EnclosureGeometry)", "local v = Vector3.new", "local occupied = {}", "local retained = {}"]
    lines.extend("for index = %d, %d do retained[index] = true end" % tuple(run) for run in runs)
    lines.extend([
        "for index, source in Terrain.MC_EC_InnerRavine.occupied do",
        "    if not retained[index] then continue end",
        "    table.insert(occupied, {low=v(source.low.X,-700,source.low.Z), high=source.high, top=source.top})",
        "end",
        "assert(#occupied == 12759, \"Frozen Source54 support/top triangle selection changed\")",
        "return {",
        "    Asset=\"MC_DP_InnerChasm\", LibraryName=\"MoonlitCitadel_Depth_DP01Library\",",
        "    Candidate=\"MC_DEPTH_DP01\", OriginalAsset=\"MC_EC_InnerRavine\",",
        "    AssetGeometry={MC_DP_InnerChasm={parts=2,triangles=18060,",
        "        center=v(-15,-289.1279125,0),size=v(522,821.744175,456),bottomY=-700,occupied=occupied}},",
        "    RetainedOriginalTopTriangles=12759, RemovedUnsupportedBedTriangles=16505,",
        "    MaterialColors={RockTop=Color3.fromRGB(100,112,116),DeepRock=Color3.fromRGB(53,69,91)},",
        "}", "",
    ])
    depth_path = HERE / "DepthPlan.proposed.luau"
    depth_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    replacements = {}
    env_path = SOURCE / "EnvironmentPlan.luau"
    original_env = env_path.read_text(encoding="utf-8")
    env = replace_once(original_env, "local Woods=require(script.Parent.WoodlandPlacements)", "local Woods=require(script.Parent.WoodlandPlacements)\nlocal Depth=require(script.Parent.DepthPlan)")
    env = replace_once(env, "groundBaseY=-130,", "groundBaseY=-700,")
    env = replace_once(env, "site={low=v(-390,-130,-355)", "site={low=v(-390,-700,-355)")
    env = replace_once(env, 'Geometry[asset] or Existing[asset],"Missing measured landscape geometry"', 'Geometry[asset] or Existing[asset] or Depth.AssetGeometry[asset],"Missing measured landscape geometry"')
    env = replace_once(env, 'local library=if Geometry[asset] then "ER01"', 'local library=if Depth.AssetGeometry[asset] then "DP01" elseif Geometry[asset] then "ER01"')
    env = replace_once(env, 'add("JoinedRavineRidges",asset,asset,CFrame.identity,Vector3.one,"RidgeRockSoilGrass")',
                       'local visual=if asset==Depth.OriginalAsset then Depth.Asset else asset\n\t\tadd("JoinedRavineRidges",asset,visual,CFrame.identity,Vector3.one,"RidgeRockSoilGrass")')
    env = replace_once(env, "Environment.AssetGeometry=Geometry", "Environment.AssetGeometry=table.clone(Geometry)\nfor asset,meta in Depth.AssetGeometry do Environment.AssetGeometry[asset]=meta end")
    env = replace_once(env, "counts.foundationBeds=Geometry.MC_EC_InnerRavine", "counts.foundationBeds=Geometry.MC_EC_InnerRavine\n\tcounts.depthChasm={asset=Depth.Asset,retainedSupportTopTriangles=Depth.RetainedOriginalTopTriangles,removedBedTriangles=Depth.RemovedUnsupportedBedTriangles,fallYLocalUnchanged=-23}")
    replacements[env_path] = env
    assembly_path = SOURCE / "WorldAssembly.luau"
    original_assembly = assembly_path.read_text(encoding="utf-8")
    assembly = replace_once(original_assembly, "local Environment = require(script.Parent.EnvironmentPlan)", "local Environment = require(script.Parent.EnvironmentPlan)\nlocal Depth = require(script.Parent.DepthPlan)")
    assembly = replace_once(assembly, 'if source == "Rock" or source == "RockA" or source == "RockB" then',
                            'if data.library == "DP01" then part.Color,part.Material = assert(Depth.MaterialColors[source]),Enum.Material.Rock\n\telseif source == "Rock" or source == "RockA" or source == "RockB" then')
    assembly = replace_once(assembly, 'local libraries = {DT01 = kits.MoonlitCitadel_Detail_DT02Library,', 'local libraries = {DP01 = kits.MoonlitCitadel_Depth_DP01Library, DT01 = kits.MoonlitCitadel_Detail_DT02Library,')
    assembly = replace_once(assembly, 'assert(libraries.DT01:GetAttribute("AxisVerified")', 'assert(libraries.DP01:GetAttribute("AxisVerified") == true, "Verify native chasm triangle surfaces before assembly")\n    assert(libraries.DT01:GetAttribute("AxisVerified")')
    assembly = replace_once(assembly, 'if data.library == "DT01" then "MC_P3_DETAIL_KIT_DT01"', 'if data.library == "DP01" then "MC_DEPTH_DP01" elseif data.library == "DT01" then "MC_P3_DETAIL_KIT_DT01"')
    replacements[assembly_path] = assembly
    patches = []
    for path, text in replacements.items():
        target = HERE / (path.stem + ".proposed.luau")
        target.write_text(text, encoding="utf-8", newline="\n")
        patches.extend(difflib.unified_diff(path.read_text(encoding="utf-8").splitlines(True), text.splitlines(True),
                                          fromfile=path.relative_to(ROOT).as_posix(), tofile=path.relative_to(ROOT).as_posix()))
    (HERE / "depth-substitution.patch").write_text("".join(patches), encoding="utf-8", newline="\n")
    proposal = {
        "status": "Staged only; native import/appearance/fall verification pending",
        "baseSource": 54, "baseBuild": 48, "freshPairedModelSha256": "c7cb26d6c08ffd1251844fb5076396ab846069f9247e971abec92dac8506d158",
        "unitPath": "Decoration/Phase3World/JoinedRavineRidges/MC_EC_InnerRavine",
        "preserveUnitName": "MC_EC_InnerRavine", "originalAsset": "MC_EC_InnerRavine", "newAsset": recipe.ASSET,
        "newLibrary": "MoonlitCitadel_Depth_DP01Library", "localCF": [0,0,0,1,0,0,0,1,0,0,0,1], "scale": [1,1,1],
        "courseOrigin": [4000,300,2600], "basePivot": [0,0,0], "nativeMeshFacesRequired": True,
        "fallYLocalUnchanged": -23, "collidersUnchanged": True, "recoveryUnchanged": True,
        "newPartProperties": {"Anchored": True, "CanCollide": False, "CanQuery": False, "CanTouch": False, "Transparency": 0, "Material": "Rock"},
        "newParts": manifest["export_parts"], "deltaPerCourse": {"units": 0, "meshes": -1, "triangles": -12656},
        "combinedBudgetFrom54": {"units": 320, "meshes": 880, "triangles": 270288, "architectureUnits": 253},
        "retainOriginals": "Keep original ER01 library immutable and archive the original three unit parts/model before substitution; never delete them.",
        "mistAdded": False, "ambienceSourceChanged": False,
        "sourcePaths": {"newDepthPlan": str(depth_path.relative_to(ROOT)),
                        "modified": [str(p.relative_to(ROOT)) for p in replacements]},
        "hashes": {str(p.relative_to(ROOT)): sha(p) for p in [manifest_path, depth_path, HERE / "EnvironmentPlan.proposed.luau", HERE / "WorldAssembly.proposed.luau", HERE / "depth-substitution.patch"]},
    }
    (HERE / "native-substitution-proposal.json").write_text(json.dumps(proposal, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"stagedOnly": True, "retainedTopIndexRuns": len(runs), "combinedBudget": proposal["combinedBudgetFrom54"]}))


if __name__ == "__main__":
    main()
