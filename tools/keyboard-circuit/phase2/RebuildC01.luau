--!strict
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and not game:GetService("RunService"):IsRunning(), "Intended Edit experience required")
local storage = game:GetService("ServerStorage")
local owned = assert(shared.KCPhase2Prepared, "Inspect Phase2 ownership")
local oldCandidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local oldKit = assert(storage.CourseAssetKits:FindFirstChild("KeyboardCircuit_Phase2EditableKit_K02"))
assert(owned.candidate == oldCandidate and owned.kit == oldKit, "Do not replace unowned models")
assert(oldCandidate:GetAttribute("Phase2Only") == true and oldKit:GetAttribute("Phase2Only") == true)
local prepared = assert(storage:FindFirstChild("KeyboardCircuit_P2_C01_Prepared"))
assert(prepared:GetAttribute("KCOwnedPhase2Preparation") == true)
assert(not prepared:FindFirstChild("Iteration02Sources"), "Inspect an existing rebuild before retry")
local builders = assert(storage.CourseBuilders:FindFirstChild("KeyboardCircuitPhase2"))
assert(#builders:GetChildren() == 16)
local origin = Vector3.new(3300, 330, -1600)
local exclude = OverlapParams.new()
exclude.FilterType, exclude.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {oldCandidate}
assert(#workspace:GetPartBoundsInBox(CFrame.new(origin + Vector3.new(0, 20, 20)), Vector3.new(600, 120, 540), exclude) == 0, "Owner work occupies the candidate region")
local template = assert(storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true))
assert(template:IsA("MeshPart") and #template:GetChildren() == 0)
local fresh = builders:Clone()
fresh.Name = "Iteration02Sources"
for _, item in fresh:GetChildren() do if item:IsA("BaseScript") then item.Disabled = true end end
fresh.Parent = prepared
local candidate = require(fresh.Course).Build(prepared, origin, template)
local function snapshot(model)
 local folder = Instance.new("Folder")
 folder.Name, folder.Parent = "SourceSnapshot", model
 for _, item in fresh:GetChildren() do
  local copy = item:Clone()
  if copy:IsA("BaseScript") then copy.Disabled = true end
  copy.Parent = folder
 end
 return folder
end
snapshot(candidate)
local kit = Instance.new("Model")
kit.Name, kit.Parent = "KeyboardCircuit_Phase2EditableKit_K02", prepared
kit:SetAttribute("CandidateRevision", "KC_KIT_P2_01")
kit:SetAttribute("Phase2Only", true)
kit:SetAttribute("KCPhase2SessionEnabled", false)
kit:SetAttribute("CourseId", "keyboard-circuit-phase2-kit")
local mechanisms = require(fresh.Mechanisms)
for index, method in {"Seesaws", "Fallaway", "Foundry", "Lift", "Shuttle", "Sweep", "Domino", "ShiftWindows"} do
 mechanisms[method](kit, template, CFrame.new(index * 130, 80, 0))
end
for index, id in {"O01", "O02", "O03", "O04", "O05", "O06", "O07", "O08"} do
 require(fresh.StaticPatterns).Build(kit, id, template, CFrame.new(index * 130, 80, 140), ({"Creamy", "Creamy", "Thocky", "Thocky", "Clacky", "Clacky", "Clicky", "Clicky"})[index])
end
snapshot(kit)
local meshes, mechanismsFound, sequences, failures = 0, 0, 0, {}
for _, item in candidate:GetDescendants() do
 if item:GetAttribute("SequenceId") then sequences += 1 end
 if item:GetAttribute("MechanismId") then mechanismsFound += 1 end
 if item:IsA("MeshPart") then
  meshes += 1
  local visible = 0
  for _, child in item:GetChildren() do if child:IsA("SurfaceGui") and child.Enabled then visible += 1 end end
  if visible ~= 1 or utf8.len(item:GetAttribute("KeyLegend") or "") ~= 1 then table.insert(failures, item:GetFullName()) end
 end
end
assert(#failures == 0 and mechanismsFound == 8 and sequences == 16)
assert(#candidate.RouteEdges:GetChildren() == 25 and #candidate.RecoveryPads:GetChildren() == 4)
local archive = storage:FindFirstChild("KeyboardCircuitPhase2Archive")
if not archive then archive = Instance.new("Folder"); archive.Name, archive.Parent = "KeyboardCircuitPhase2Archive", storage; archive:SetAttribute("KCOwnedPhase2Archive", true) end
assert(archive:GetAttribute("KCOwnedPhase2Archive") == true and not archive:FindFirstChild("C01_InitialPreflight"))
local initial = Instance.new("Folder")
initial.Name, initial.Parent = "C01_InitialPreflight", archive
initial:SetAttribute("Reason", "Preserved initial native preflight before geometry repairs")
for _, model in {oldCandidate, oldKit} do
 for _, item in model:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
 model.Parent = initial
end
candidate:SetAttribute("ConstructionIteration", 2)
candidate.Parent = workspace
candidate.SourceSnapshot.Session.Disabled = false
kit.Parent = storage.CourseAssetKits
shared.KCPhase2Prepared = {candidate = candidate, kit = kit}
return game:GetService("HttpService"):JSONEncode({revision = "KC_P2_C01", iteration = 2, candidate = candidate:GetFullName(), kit = kit:GetFullName(), archive = initial:GetFullName(), candidateDescendants = #candidate:GetDescendants(), kitDescendants = #kit:GetDescendants(), meshes = meshes, mechanisms = mechanismsFound, sequences = sequences, legendFailures = failures, sourceCount = #fresh:GetChildren(), ownerCameraSaved = shared.KCPhase2OwnerCamera ~= nil, c08Descendants = #workspace.KeyboardCircuit_P1_C08:GetDescendants()})
