local c=game.ServerStorage.EggRushChickenR05_20261026.Candidate_ChickenR05_C01
local pivot=c:GetPivot()
local out={candidate=c:GetAttribute("CandidateId"),pivot={pivot:GetComponents()},parts={}}
for _,p in ipairs(c:GetDescendants()) do
 if p:IsA("BasePart") and p.Transparency<.95 then
  local ancestor=p:FindFirstAncestorWhichIsA("Model")
  table.insert(out.parts,{name=p.Name,path=p:GetFullName():sub(#c:GetFullName()+2),cf={pivot:ToObjectSpace(p.CFrame):GetComponents()},
   size={p.Size.X,p.Size.Y,p.Size.Z},color={p.Color.R,p.Color.G,p.Color.B},transparency=p.Transparency,
   meshId=p:IsA("MeshPart") and p.MeshId or nil,shape=p:IsA("Part") and p.Shape.Name or p.ClassName,
   studs=p.TopSurface==Enum.SurfaceType.Studs,collide=p.CanCollide,route=p:GetAttribute("ERRoute"),asset=ancestor and ancestor:GetAttribute("ERAsset")})
 end
end
local raw=game.HttpService:JSONEncode(out)
local parent=game.ServerStorage.EggRushChickenR05_20261026
local name="VisualSnapshot_"..out.candidate
assert(not parent:FindFirstChild(name),"Preserve the earlier exact snapshot")
local snapshot=Instance.new("Folder")
snapshot.Name,snapshot.Parent=name,parent
local chunks={}
for i=1,#raw,45000 do
 local chunk=Instance.new("StringValue")
 chunk.Name=string.format("Chunk_%03d",#chunks+1)
 chunk.Value,chunk.Parent=raw:sub(i,i+44999),snapshot
 table.insert(chunks,chunk.Name)
end
return game.HttpService:JSONEncode({candidate=out.candidate,folder=name,parts=#out.parts,bytes=#raw,chunks=chunks})
