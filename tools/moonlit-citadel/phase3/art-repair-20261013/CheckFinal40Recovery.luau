--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/final/"
local models=roblox.deserializeModel(fs.readFile(root.."artrepair_final_source40_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=40,buildRevision=34,sourcePacketHash="0a5a0b8ec9816da146b17f503f434e4a94ae53833e3f47a2ccc377a88000bc35",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==40 and model:GetAttribute("BuildRevision")==34 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
 local row={index=index,name=model.Name,descendants=#model:GetDescendants(),parts=0,meshes=0,colliders=0,floors=0,redContacts=0}
 for _,item in model:GetDescendants() do
  if item:IsA("BasePart") then
   row.parts+=1
   if item:IsA("MeshPart") then row.meshes+=1 end
   if item.CanCollide then row.colliders+=1 end
   if item:GetAttribute("MCWalkable")==true then row.floors+=1 end
   if item:GetAttribute("MoonlitHazard")==true then row.redContacts+=1 end
  end
 end
 assert(row.descendants==2698 and row.parts==1696 and row.meshes==1402 and row.colliders==147 and row.floors==135 and row.redContacts==55)
 table.insert(report.models,row)
end
report.complete=true
fs.writeFile(root.."artrepair_final_source40_reopen.json",serde.encode("json",report,true))
print("PASS: Source40 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
