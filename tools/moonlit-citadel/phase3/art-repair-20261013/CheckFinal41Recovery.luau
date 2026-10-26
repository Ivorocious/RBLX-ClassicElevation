--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/source41/final/"
local models=roblox.deserializeModel(fs.readFile(root.."artrepair_final_source41_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=41,buildRevision=35,sourcePacketHash="69cc1ca6694b9a35d92f8999eb4b3dd056a9403020d7e5e265fb387fb2be61f3",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==41 and model:GetAttribute("BuildRevision")==35 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
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
 assert(row.descendants==2702 and row.parts==1699 and row.meshes==1405 and row.colliders==147 and row.floors==135 and row.redContacts==55)
 table.insert(report.models,row)
end
report.complete=true
fs.writeFile(root.."artrepair_final_source41_reopen.json",serde.encode("json",report,true))
print("PASS: Source41 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
