"""Bind actual final files for the additive saved-model reopen check."""
import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
ART = ROOT / "docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014"


def entry(path):
    path = ROOT / path if not path.is_absolute() else path
    return {"path":str(path.relative_to(ROOT)).replace("\\","/"),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--plan",required=True,type=Path)
    parser.add_argument("--packet",required=True,type=Path)
    parser.add_argument("--dt-library",required=True,type=Path)
    parser.add_argument("--dt-library-name",required=True)
    parser.add_argument("--dt-manifest",type=Path,default=ROOT/"assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/manifest.json")
    parser.add_argument("--architecture",required=True,type=int)
    parser.add_argument("--detail-candidate")
    parser.add_argument("--candidate-models",type=Path,default=ART/"final/source53-models.rbxm")
    parser.add_argument("--candidate-modules",type=Path,default=ART/"final/source53-modules.rbxm")
    parser.add_argument("--durable-root",type=Path,default=ROOT/"src/ServerStorage/CourseBuilders/MoonlitCitadelCourse")
    args=parser.parse_args()
    plan=json.loads((ROOT/args.plan).read_text(encoding="utf-8"))
    packet_path=ROOT/args.packet
    packet=json.loads(packet_path.read_text(encoding="utf-8"))
    manifest_path=ROOT/args.dt_manifest
    manifest=json.loads(manifest_path.read_text(encoding="utf-8"))
    costs={}
    for part in manifest["export_parts"]:
        counts=costs.setdefault(part["asset"],{"meshes":0,"triangles":0})
        counts["meshes"]+=1;counts["triangles"]+=part["triangles"]
    additions=[u for u in plan["units"] if u["library"]=="DT01"]
    assert len(plan["units"])==243+len(additions)
    delta={"units":len(additions),"meshes":sum(costs[u["asset"]]["meshes"] for u in additions),
           "triangles":sum(costs[u["asset"]]["triangles"] for u in additions)}
    expected={"source":packet["sourceRevision"],"build":packet["buildRevision"],"candidate":packet["candidate"],
        "packet":entry(packet_path)["sha256"],"units":243+delta["units"],"meshes":639+delta["meshes"],
        "triangles":198722+delta["triangles"],"architecture":args.architecture}
    assert expected["source"]==53 and expected["architecture"]<=260 and expected["units"]<=350 and expected["meshes"]<=900 and expected["triangles"]<=420000
    inputs={
        "baselineModels":ART/"before/source52-models.rbxm", "baselineModules":ART/"before/source52-modules.rbxm",
        "candidateModels":args.candidate_models,"candidateModules":args.candidate_modules,
        "plan":args.plan,"packet":args.packet,"verifiedDT01":args.dt_library,"dtManifest":manifest_path,
        "baseLibraries":ROOT/"docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_before_source48_kits.rbxm",
        "verifiedER01":ROOT/"docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm",
        "approvedER01Metadata":ROOT/"tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json",
    }
    durable={}
    for row in packet["records"]:
        path=ROOT/"src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau" if row["name"]=="MoonlitCitadelAmbienceConfig" else args.durable_root/(row["name"]+".luau")
        path=ROOT/path if not path.is_absolute() else path
        assert path.read_text(encoding="utf-8").replace("\r\n","\n")==row["source"],"Bind the intended current durable source"
        durable[row["name"]]=str(path.relative_to(ROOT)).replace("\\","/")
    result={"ready":True,"expected":expected,"inputs":{k:entry(p) for k,p in inputs.items()},
        "durableFiles":durable,"dtLibraryName":args.dt_library_name,
        "detailAttributes":{"":{"Phase3DetailsApplied":True},"Decoration/Phase3World":{
            "DetailCandidate":args.detail_candidate or packet["candidate"],"DetailUnits":delta["units"],"DetailMeshes":delta["meshes"],"DetailTriangles":delta["triangles"]}},
        "output":str((HERE/"saved-detail53-reopen.json").relative_to(ROOT)).replace("\\","/")}
    output=HERE/"bindings53.json"
    assert not output.exists(),"Preserve previous final bindings"
    output.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps({"file":str(output.relative_to(ROOT)),"sha256":entry(output)["sha256"],"expected":expected}))


if __name__=="__main__": main()
