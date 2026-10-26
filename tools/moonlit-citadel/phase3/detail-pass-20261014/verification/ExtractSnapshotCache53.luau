local fs,roblox,serde,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/process")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local input=assert(process.args[1],"Pass the serialized owned snapshot recovery folder")
local prefix=process.args[2] or own
local rawFile=fs.readFile(input)
local folders={}
local function inspect(item)
    if item:IsA("Folder") and (item.Name=="FreshBaseline52" or item.Name=="AfterSnapshot53") then
        assert(not folders[item.Name],"Unique named snapshot cache required");folders[item.Name]=item
    end
end
for _,root in roblox.deserializeModel(rawFile) do inspect(root);for _,item in root:GetDescendants() do inspect(item) end end
assert(folders.FreshBaseline52,"The complete fresh baseline cache is required")
local report={pass=true,input=input,inputSHA256=serde.hash("sha256",rawFile),snapshots={},savedReadOnly=true,studioTouched=false}
for name,folder in folders do
    local children=folder:GetChildren();table.sort(children,function(a,b) return a.Name<b.Name end)
    local pieces={};for _,item in children do assert(item:IsA("StringValue"));table.insert(pieces,item.Value) end
    local raw=table.concat(pieces);local hash=serde.hash("sha256",raw)
    assert(#raw==folder:GetAttribute("SnapshotBytes") and hash==folder:GetAttribute("SnapshotSHA256"),"Snapshot cache hash/byte receipt differs")
    local state=serde.decode("json",raw)
    local output=prefix..name.."-native.json"
    fs.writeFile(output,raw)
    table.insert(report.snapshots,{name=name,path=output,bytes=#raw,sha256=hash,chunks=#pieces,editable=state.editable.counts,stored=state.stored.counts})
end
fs.writeFile(prefix.."snapshot-cache53-extraction.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
