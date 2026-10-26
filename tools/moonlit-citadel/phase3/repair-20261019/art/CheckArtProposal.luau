local fs,luau=require("@lune/fs"),require("@lune/luau")
local path="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/CheckCorrectionClearance54.luau"
local raw=fs.readFile(path)
raw=raw:gsub('model:GetAttribute%("SourceRevision"%)==52','model:GetAttribute("SourceRevision")==54')
raw=raw:gsub('report.baselineModelSource=52','report.baselineModelSource=54')
local replacement=[[
local volumes,views=detail.PrepareVolumes(clearance,layout,config,signs)
local rows=serde.decode("json",read("tools/moonlit-citadel/phase3/repair-20261019/art/proposal01/proposed-actual-part-bounds.json"))
local result=clearance.CheckParts(rows,volumes)
local pass=true
for _,field in {"blocking","headroom","camera","visibility","invalidContactFlags"} do
    if #result[field]>0 then pass=false end
end
local report={pass=pass,routeCombinations=32,protectedVolumes=#volumes,occupiedRows=#rows,
    clearance=result,views=views,actualProposedPartAABBs=true,
    boundary="Conservative actual changed material-part bounding boxes. Hollow meshes may overestimate occupied space; native actual-face and moving-camera proof remain lead work."}
]]
local count
raw,count=raw:gsub("local report=detail%.Check%(clearance,layout,config,plan,metadata,signs%)",replacement)
assert(count==1,"Use the exact existing clearance harness shape")
return luau.load(raw,{debugName="FocusedArtProposalClearance"})()
