local fs=require("@lune/fs")
local serde=require("@lune/serde")
local roblox=require("@lune/roblox")
local base="docs/artifacts/moonlit-citadel/phase2/evidence/"
local path=base.."MC_P2_C01_R05_red_body01_02_server.rbxm"
local bytes=fs.readFile(path)
assert(serde.hash("sha256",bytes)=="f77d26c613f45ff8e6d5629a78b2924bba47e8bbf4f17444f2921a4e47af061a")
local roots=roblox.deserializeModel(bytes)
local map={}
for _,x in roots do assert(not map[x.Name]);map[x.Name]=x end
local dir=base.."r05-red-body-extracted01/"
assert(not fs.isDir(dir))
fs.writeDir(dir)
local record={native=path,nativeSha256=serde.hash("sha256",bytes),reports={},sources={}}
local function norm(v) return v:gsub("^\239\187\191",""):gsub("\r\n","\n") end
for _,n in {"MC_R05_FocusedProof","MC_R05_FocusedProof02","MC_R05_FocusedProof03","MC_R05_RedBodyProof01","MC_R05_RedBodyProof02"} do
 local x=assert(map[n])
 local fn=n:gsub("^MC_R05_","R05")
 if fn=="R05RedBodyProof01" then fn="R05RedBodyProof" end
 local file="tools/moonlit-citadel/phase2/"..fn..".server.luau"
 assert(norm(x.Source)==norm(fs.readFile(file)),n.." source differs")
 record.sources[#record.sources+1]={native=n,file=file,sha256=serde.hash("sha256",norm(x.Source)),bytes=#norm(x.Source)}
end
local all=assert(map.MoonlitPhase2Evidence)
for _,n in {"MC_P2_C01_R05_RedBody01","MC_P2_C01_R05_RedBody02"} do
 local f=assert(all:FindFirstChild(n))
 local chunks=f:GetChildren()
 table.sort(chunks,function(a,b) return a.Name<b.Name end)
 local a={}
 for i,x in chunks do assert(x.Name==string.format("JSON_%03d",i) and x:IsA("StringValue"));a[i]=x.Value end
 local raw=table.concat(a)
 assert(#raw==f:GetAttribute("JSONBytes"))
 local q=serde.decode("json",raw)
 fs.writeFile(dir..n..".json",raw)
 record.reports[n]={sha256=serde.hash("sha256",raw),bytes=#raw,passed=q.passed,failure=q.failure,candidate=q.candidate}
 if n=="MC_P2_C01_R05_RedBody01" then assert(q.passed==false and q.failure and q.before==nil)
 else
  assert(q.passed==true and q.failure==nil and q.actualClients==1 and q.candidate=="MC_P2_C01_R05")
  assert(#q.initialBodyOverlaps>0 and #q.samples==50)
  assert(q.before.progress.falls==0 and q.after.progress.falls==1 and q.before.progress.checkpoint==0 and q.after.progress.checkpoint==0)
  assert(q.after.diagnostics.stats.hazardHits>q.before.diagnostics.stats.hazardHits and q.after.diagnostics.stats.recoveries>q.before.diagnostics.stats.recoveries)
  record.summary={samples=#q.samples,bodyParts=q.initialBodyOverlaps,raceId=q.entry.raceId,falls=q.after.progress.falls,checkpoint=q.after.progress.checkpoint,horizontalError=q.recoveryHorizontalError,verticalError=q.recoveryVerticalError}
 end
end
fs.writeFile(dir.."receipt.json",serde.encode("json",record,true))
print(serde.encode("json",record,true))

