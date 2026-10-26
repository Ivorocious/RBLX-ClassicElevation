--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/before/"
local models=roblox.deserializeModel(fs.readFile(root.."artrepair_before_source38_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=38,buildRevision=32,sourcePacketHash="56d992fa0cda21e53736b06f3d409e36911b1b77a9d3b5d9ce9cd1584b0dfc05",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==38 and model:GetAttribute("BuildRevision")==32 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
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
 assert(row.descendants==2611 and row.parts==1637 and row.meshes==1343 and row.colliders==147 and row.floors==135 and row.redContacts==55)
 table.insert(report.models,row)
end
report.complete=true
fs.writeFile(root.."artrepair_before_source38_reopen.json",serde.encode("json",report,true))
print("PASS: Source38 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
