--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/tower-landscape-20261013/before/"
local models=roblox.deserializeModel(fs.readFile(root.."towerland_final_source46_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=46,buildRevision=40,sourcePacketHash="63d3fb04f68f72e5e6351f23432882aadc905f112d9c8e5a4d1e8046a09c9e8b",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==46 and model:GetAttribute("BuildRevision")==40 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
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
fs.writeFile(root.."towerland_final_source46_reopen.json",serde.encode("json",report,true))
print("PASS: Source46 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
