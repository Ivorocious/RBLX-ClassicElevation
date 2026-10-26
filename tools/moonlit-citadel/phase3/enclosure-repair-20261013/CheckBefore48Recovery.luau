--!nonstrict
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local root="docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/"
local models=roblox.deserializeModel(fs.readFile(root.."enclosure_before_source48_models.rbxm"))
assert(#models==2,"Two preserved course models required")
local report={sourceRevision=48,buildRevision=42,sourcePacketHash="dc978a45fda66d27d79b34f2d08458c5a42d8ea8a473e6c8d5f25ab81235eb34",models={}}
for index,model in models do
 assert(model:GetAttribute("SourceRevision")==48 and model:GetAttribute("BuildRevision")==42 and model:GetAttribute("SourcePacketHash")==report.sourcePacketHash)
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
local kits=roblox.deserializeModel(fs.readFile(root.."enclosure_before_source48_kits.rbxm"));assert(#kits==4);report.kits={}for _,kit in kits do table.insert(report.kits,{name=kit.Name,descendants=#kit:GetDescendants()})end
local phase1=roblox.deserializeModel(fs.readFile(root.."enclosure_before_source48_phase1.rbxm"));assert(#phase1==1 and phase1[1].Name=="MoonlitCitadelPhase1_BL02" and #phase1[1]:GetDescendants()==1157);report.phase1Descendants=1157
report.complete=true
fs.writeFile(root.."enclosure_before_source48_reopen.json",serde.encode("json",report,true))
print("PASS: Source48 two-model recovery reopens; both models have matching source/build bindings and complete counts.")
