--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/expert-hardening-20261013/"
local models=roblox.deserializeModel(fs.readFile(root.."hardening_final_source36_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=36,buildRevision=30,sourcePacketHash="503b5c504c7b34531febe423b9f779c314ef7c6f8c20c823ef796ac118f2c226",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==36 and model:GetAttribute("BuildRevision")==30 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
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
 assert(row.descendants==2594 and row.parts==1629 and row.meshes==1335 and row.colliders==147 and row.floors==135 and row.redContacts==55)
 table.insert(report.models,row)
end
report.complete=true
fs.writeFile(root.."hardening_final_source36_reopen.json",serde.encode("json",report,true))
print("PASS: Source36 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
