--!strict
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended Edit experience required")
local storage = game:GetService("ServerStorage")
assert(not workspace:FindFirstChild("KeyboardCircuit_P2_C01"), "Inspect existing candidate")
assert(not storage:FindFirstChild("KeyboardCircuit_P2_C01_Prepared"), "Inspect existing preparation")
local builders = assert(storage.CourseBuilders:FindFirstChild("KeyboardCircuitPhase2"), "Rojo Phase2 source missing")
assert(#builders:GetChildren() == 16, "Inspect Phase2 source count")
local origin = Vector3.new(3300,330,-1600)
assert(#workspace:GetPartBoundsInBox(CFrame.new(origin+Vector3.new(0,20,20)),Vector3.new(600,120,540)) == 0,"Candidate space is occupied")
local serialization = game:GetService("SerializationService")
shared.KCPhase2Before = {candidate=buffer.tostring(serialization:SerializeInstancesAsync({workspace.KeyboardCircuit_P1_C08})),kit=buffer.tostring(serialization:SerializeInstancesAsync({storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01}))}
local prepared = Instance.new("Folder")
prepared.Name,prepared.Parent = "KeyboardCircuit_P2_C01_Prepared",storage
prepared:SetAttribute("KCOwnedPhase2Preparation",true)
local template = assert(storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey",true))
assert(#template:GetChildren() == 0,"Inspect imported cap template descendants")
local candidate = require(builders.Course).Build(prepared,origin,template)
local function snapshot(model)
 local folder=Instance.new("Folder")
 folder.Name,folder.Parent="SourceSnapshot",model
 for _,item in builders:GetChildren() do
  local copy=item:Clone()
  if copy:IsA("BaseScript") then copy.Disabled=true end
  copy.Parent=folder
 end
 return folder
end
snapshot(candidate)
local kit=Instance.new("Model")
kit.Name,kit.Parent="KeyboardCircuit_Phase2EditableKit_K02",prepared
kit:SetAttribute("CandidateRevision","KC_KIT_P2_01")
kit:SetAttribute("Phase2Only",true)
kit:SetAttribute("KCPhase2SessionEnabled",false)
kit:SetAttribute("CourseId","keyboard-circuit-phase2-kit")
local parts=require(builders.Parts)
local mechanisms=require(builders.Mechanisms)
for index,method in {"Seesaws","Fallaway","Foundry","Lift","Shuttle","Sweep","Domino","ShiftWindows"} do
 mechanisms[method](kit,template,CFrame.new(index*130,80,0))
end
for index,id in {"O01","O02","O03","O04","O05","O06","O07","O08"} do
 require(builders.StaticPatterns).Build(kit,id,template,CFrame.new(index*130,80,140),({"Creamy","Creamy","Thocky","Thocky","Clacky","Clacky","Clicky","Clicky"})[index])
end
snapshot(kit)
local meshes,legendFailures,mechanismCount=0,{},0
for _,item in candidate:GetDescendants() do
 if item:IsA("MeshPart") then
  meshes+=1
  local visible=0
  for _,gui in item:GetChildren() do if gui:IsA("SurfaceGui") and gui.Enabled then visible+=1 end end
  if visible~=1 or utf8.len(item:GetAttribute("KeyLegend") or "")~=1 then table.insert(legendFailures,item:GetFullName()) end
 end
 if item:GetAttribute("MechanismId") then mechanismCount+=1 end
end
assert(#legendFailures==0 and mechanismCount==8,"Inspect constructed key/mechanism defects")
shared.KCPhase2Prepared={candidate=candidate,kit=kit}
return game:GetService("HttpService"):JSONEncode({revision="KC_P2_C01",prepared=prepared:GetFullName(),candidateDescendants=#candidate:GetDescendants(),kitDescendants=#kit:GetDescendants(),meshes=meshes,mechanisms=mechanismCount,legendFailures=legendFailures,sourceCount=#builders:GetChildren(),stage="Prepared in ServerStorage; not yet installed"})
