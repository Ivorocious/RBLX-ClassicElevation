--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/tower-landscape-20261013/before/"
local models=roblox.deserializeModel(fs.readFile(root.."towerland_final_source47_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=47,buildRevision=41,sourcePacketHash="b416292abd43faa58ed6e48de004efa07bc7e7e6955d5573c85e4a66cd2a1ea7",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==47 and model:GetAttribute("BuildRevision")==41 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
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
 assert(row.descendants==2549 and row.parts==1611 and row.meshes==1317 and row.colliders==147 and row.floors==135 and row.redContacts==55)
 table.insert(report.models,row)
end
report.complete=true
fs.writeFile(root.."towerland_final_source47_reopen.json",serde.encode("json",report,true))
print("PASS: Source47 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
