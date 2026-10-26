"""Bind an actual corrective detail candidate to the unchanged fresh Source52 baseline."""
import argparse
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/"default.project.json").exists())
ART=ROOT/"docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014"


def read(path):
    path=ROOT/path
    return json.loads(path.read_text(encoding="utf-8"))


def entry(path):
    path=ROOT/path
    return {"path":path.relative_to(ROOT).as_posix(),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    parser=argparse.ArgumentParser()
    for name in ("plan","packet","models","modules","detail-library","combined-manifest","occupied-metadata"):
        parser.add_argument("--"+name,required=True,type=Path)
    parser.add_argument("--detail-library-name",required=True)
    parser.add_argument("--target-source",required=True,type=int)
    parser.add_argument("--architecture",required=True,type=int)
    parser.add_argument("--detail-candidate")
    parser.add_argument("--durable-root",type=Path,default=ROOT/"src/ServerStorage/CourseBuilders/MoonlitCitadelCourse")
    parser.add_argument("--output",type=Path,default=HERE/"bindings54.json")
    parser.add_argument("--native-library-proof",type=Path)
    args=parser.parse_args()
    plan,packet,manifest,metadata=map(read,(args.plan,args.packet,args.combined_manifest,args.occupied_metadata))
    assert packet["sourceRevision"]==args.target_source and args.target_source>53
    costs,partnames={},set()
    for part in manifest["export_parts"]:
        assert part["name"] not in partnames,"Ambiguous combined template material name"
        partnames.add(part["name"])
        cost=costs.setdefault(part["asset"],{"meshes":0,"triangles":0})
        cost["meshes"]+=1;cost["triangles"]+=part["triangles"]
    additions=[u for u in plan["units"] if u["library"]=="DT01"]
    assert 0<len(additions)<=90 and len(plan["units"])==243+len(additions)
    for unit in additions:
        assert unit["asset"] in costs and metadata["assets"][unit["asset"]]["occupied"],"Every new detail binds measured combined geometry"
    delta={"units":len(additions),"meshes":sum(costs[u["asset"]]["meshes"] for u in additions),
           "triangles":sum(costs[u["asset"]]["triangles"] for u in additions)}
    expected={"source":packet["sourceRevision"],"build":packet["buildRevision"],"candidate":packet["candidate"],
        "packet":entry(args.packet)["sha256"],"units":243+delta["units"],"meshes":639+delta["meshes"],
        "triangles":198722+delta["triangles"],"architecture":args.architecture}
    assert expected["architecture"]<=260 and expected["units"]<=350 and expected["meshes"]<=900 and expected["triangles"]<=420000
    inputs={"baselineModels":ART/"before/source52-models.rbxm","baselineModules":ART/"before/source52-modules.rbxm",
        "candidateModels":args.models,"candidateModules":args.modules,"plan":args.plan,"packet":args.packet,
        "verifiedDT01":args.detail_library,"dtManifest":args.combined_manifest,"occupiedMetadata":args.occupied_metadata,
        "baseLibraries":ROOT/"docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_before_source48_kits.rbxm",
        "verifiedER01":ROOT/"docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm",
        "approvedER01Metadata":ROOT/"tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json",
        "baselinePacket52":ROOT/"docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before/closeout_source52_packet.json",
        "baselineDurableInventory":ART/"before/current-source-all.json"}
    if args.native_library_proof:
        proof=read(args.native_library_proof)
        assert proof["pass"],"Bind actual verified combined native library proof"
        inputs["nativeLibraryProof"]=args.native_library_proof
    durable={}
    for row in packet["records"]:
        assert hashlib.sha256(row["source"].encode("utf-8")).hexdigest()==row["sha256"]
        path=ROOT/"src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau" if row["name"]=="MoonlitCitadelAmbienceConfig" else ROOT/args.durable_root/(row["name"]+".luau")
        assert path.read_text(encoding="utf-8").replace("\r\n","\n")==row["source"],"Exact staged/durable packet source required"
        durable[row["name"]]=path.relative_to(ROOT).as_posix()
    result={"ready":True,"expected":expected,"inputs":{k:entry(v) for k,v in inputs.items()},"durableFiles":durable,
        "dtLibraryName":args.detail_library_name,"logicalDetailLibrary":"DT01",
        "detailAttributes":{"":{"Phase3DetailsApplied":True},"Decoration/Phase3World":{
            "DetailCandidate":args.detail_candidate or packet["candidate"],"DetailUnits":delta["units"],"DetailMeshes":delta["meshes"],"DetailTriangles":delta["triangles"]}},
        "output":(HERE/"saved-correction-reopen.json").relative_to(ROOT).as_posix(),
        "baseline52SnapshotSHA256":"3eda16621db02dcfc6235f8e90ce698d7c2d5dab4f5e1957610fa41dee4dcc7a",
        "retained53Status":"Held, with its original reviews/proofs archived separately"}
    output=ROOT/args.output
    assert not output.exists(),"Preserve prior corrective bindings"
    output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"file":output.relative_to(ROOT).as_posix(),"sha256":entry(output)["sha256"],"expected":expected}))


if __name__=="__main__":main()
