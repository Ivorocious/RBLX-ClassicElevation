local fs=require("@lune/fs")
local serde=require("@lune/serde")
local roblox=require("@lune/roblox")
local base="docs/artifacts/moonlit-citadel/phase2/evidence/"
local path=base.."MC_P2_C01_R05_routes_focused03_client.rbxm"
local bytes=fs.readFile(path)
assert(serde.hash("sha256",bytes)=="a511d10a33ea9e3a546e4e243142c507e60265350967ad48e7918fc6ae4441e7")
local roots=roblox.deserializeModel(bytes)
local map={}
for _,x in roots do assert(not map[x.Name]);map[x.Name]=x end
local dir=base.."r05-focused03-extracted02/"
assert(not fs.isDir(dir))
fs.writeDir(dir)
local record={native=path,nativeSha256=serde.hash("sha256",bytes),failures={},sources={}}
local function norm(v) return v:gsub("^\239\187\191",""):gsub("\r\n","\n") end
for _,n in {"MC_P2_C01_R05_FocusedRouteProof","MC_P2_C01_R05_FocusedRouteProof02"} do
 local x=assert(map[n])
 record.failures[n]=x:GetAttributes()
 assert(x:GetAttribute("Failure") and #x:GetChildren()==0)
end
for _,n in {"","02","03"} do
 local name="MC_R05_FocusedProof"..n
 local x=assert(map[name])
 local file="tools/moonlit-citadel/phase2/R05FocusedProof"..n..".client.luau"
 assert(norm(x.Source)==norm(fs.readFile(file)),name.." source differs")
 record.sources[#record.sources+1]={native=name,file=file,sha256=serde.hash("sha256",norm(x.Source)),bytes=#norm(x.Source)}
end
local f=assert(map.MC_P2_C01_R05_FocusedRouteProof03)
assert(f:GetAttribute("State")=="Complete" and f:GetAttribute("Failure")==nil)
local reports={}
for _,n in {"Suite","Trial"} do
 local count=f:GetAttribute(n.."Chunks")
 local a={}
 for i=1,count do a[i]=f[string.format(n.."_%03d",i)].Value end
 local raw=table.concat(a)
 assert(#raw==f:GetAttribute(n.."Bytes"))
 reports[n]=serde.decode("json",raw)
 fs.writeFile(dir..n..".json",raw)
 record[n]={bytes=#raw,sha256=serde.hash("sha256",raw),chunks=count}
end
assert(reports.Suite.state=="Complete" and #reports.Suite.trials==1 and reports.Suite.trials[1].name=="EEE")
assert(reports.Trial.state=="Complete" and reports.Trial.failure==nil and reports.Trial.candidate=="MC_P2_C01_R05")
record.attributes=f:GetAttributes()
record.trialKeys={}
for k in reports.Trial do table.insert(record.trialKeys,k) end
table.sort(record.trialKeys)
record.summary={state=reports.Trial.state,raceId=reports.Trial.raceId,steps=#reports.Trial.steps,trials=#reports.Suite.trials}
fs.writeFile(dir.."receipt.json",serde.encode("json",record,true))
print(serde.encode("json",record,true))

