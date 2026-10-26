local fs,roblox,serde,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/process")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/"
local input=assert(process.args[1],"Pass the corrective native cache RBXM")
local bindingPath=assert(process.args[2],"Pass the exact corrective after-snapshot/cache receipt JSON")
local bindingRaw=fs.readFile(bindingPath)
local bindings=serde.decode("json",bindingRaw)
assert(bindings.baseline52SnapshotSHA256=="3eda16621db02dcfc6235f8e90ce698d7c2d5dab4f5e1957610fa41dee4dcc7a","Immutable before52 reference required")
assert(bindings.source>53 and bindings.snapshotName=="AfterRestoredSnapshot"..bindings.source,"Bind the actual corrected after-snapshot name")
local inputRaw=fs.readFile(input)
assert(serde.hash("sha256",inputRaw)==bindings.cacheSHA256,"Exact cache export hash required")
local folder
local function inspect(item)
    if item.Name==bindings.snapshotName and item:IsA("Folder") then assert(not folder,"Unique final corrective snapshot cache required");folder=item end
end
local roots=roblox.deserializeModel(inputRaw)
for _,root in roots do inspect(root);for _,item in root:GetDescendants() do inspect(item) end end
assert(folder,"Final after-snapshot cache is missing; baseline duplication is not required")
local children=folder:GetChildren();table.sort(children,function(a,b) return a.Name<b.Name end)
local pieces={};for _,item in children do assert(item:IsA("StringValue"));table.insert(pieces,item.Value) end
local raw=table.concat(pieces);local sha=serde.hash("sha256",raw)
assert(#raw==bindings.bytes and sha==bindings.sha256 and #raw==folder:GetAttribute("SnapshotBytes")
    and sha==folder:GetAttribute("SnapshotSHA256"),"Exact native after-snapshot SHA/bytes must match both receipts")
local state=serde.decode("json",raw)
for _,name in {"editable","stored"} do
    assert(state[name].records[""].attrs.SourceRevision==bindings.source,"Cached model identity differs")
end
local output=bindings.output or own..bindings.snapshotName.."-native.json"
fs.writeFile(output,raw)
local report={pass=true,source=bindings.source,snapshotName=bindings.snapshotName,output=output,sha256=sha,bytes=#raw,chunks=#pieces,
    cacheRoots=#roots,cacheSHA256=bindings.cacheSHA256,bindingSHA256=serde.hash("sha256",bindingRaw),
    baseline52SnapshotSHA256=bindings.baseline52SnapshotSHA256,duplicatedBaselineRequired=false,
    editable=state.editable.counts,stored=state.stored.counts,savedCacheOnly=true,studioTouched=false}
fs.writeFile(own.."corrective-native-cache-extraction.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
