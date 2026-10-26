--!strict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local name, holderName = "KeyboardCircuit_P2_I09_Experience02", "KCP2I09ExperienceSources02"
assert(not workspace:FindFirstChild(name) and not Storage:FindFirstChild(holderName), "Inspect any partial build before retry")
local baseline = assert(workspace:FindFirstChild("KeyboardCircuit_P2_I09_Experience01"))
assert(baseline:GetAttribute("PrototypeRevision") == "KC_P2_I09_01")
local inputs = assert(shared.KCI09Inputs)
local holder = Instance.new("Folder")
holder.Name, holder.Parent = holderName, Storage
holder:SetAttribute("KCOwnedPhase2Preparation", true)
local sources = Instance.new("Folder")
sources.Name, sources.Parent = "Sources", holder
for sourceName, data in inputs do
 local item = Instance.new(data.class)
 item.Name, item.Source = sourceName, data.source
 if item:IsA("BaseScript") then item.Disabled = true end
 item.Parent = sources
end
assert(#sources:GetChildren() == 16)
local template = assert(Storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true))
assert(template:IsA("MeshPart"))
local origin = baseline:GetAttribute("Origin")
local candidate = require(sources.Course).Build(holder, origin, template)
candidate.Name = name
candidate:SetAttribute("ConstructionIteration", 9)
candidate:SetAttribute("PrototypeOnly", true)
candidate:SetAttribute("PrototypeRevision", "KC_P2_I09_02")
local snapshot = sources:Clone()
snapshot.Name, snapshot.Parent = "SourceSnapshot", candidate
local sequenceCount, mechanismCount, capCount = 0, 0, 0
for _,item in candidate:GetDescendants() do
 if item:GetAttribute("SequenceId") then sequenceCount += 1 end
 if item:GetAttribute("MechanismId") then mechanismCount += 1 end
 if item:IsA("BaseScript") then assert(item.Disabled) end
end
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
for _,branch in candidate.ExpertRoutes:GetChildren() do
 for _,landing in branch:GetChildren() do
  local contact = landing:FindFirstChild("KeyContact")
  if contact then
   capCount += 1
   local others = {}
   for _,part in candidate:GetDescendants() do
    if part:IsA("BasePart") and part.CanCollide and part ~= contact then
     local point = part.CFrame:PointToObjectSpace(contact.Position)
     if math.abs(point.X) <= part.Size.X / 2 and math.abs(point.Z) <= part.Size.Z / 2 and point.Y <= part.Size.Y / 2 and point.Y >= -8 then table.insert(others, part:GetFullName()) end
    end
   end
   assert(#others == 0, "Precision landing masked by another contact: " .. Http:JSONEncode(others))
  end
 end
end
assert(sequenceCount == 16 and mechanismCount == 8 and capCount == 25 and #candidate.ExpertRoutes:GetChildren() == 2 and #candidate.RouteEdges:GetChildren() == 25)
assert(candidate:GetAttribute("RequiredLaps") == 2)
local archive = Storage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses
assert(not archive:FindFirstChild(baseline.Name))
local oldSources = {}
for _,item in baseline.SourceSnapshot:GetChildren() do oldSources[item.Name] = item.Source end
for _,item in baseline:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
baseline.Parent = archive
for _,item in baseline.SourceSnapshot:GetChildren() do assert(item.Source == oldSources[item.Name]) end
candidate.Parent = workspace
snapshot.Session.Disabled = false
shared.KCP2I09Build = {candidate = candidate, holder = holder, inputs = inputs}
return Http:JSONEncode({created = true, course = candidate:GetFullName(), sources = #snapshot:GetChildren(), requiredLaps = 2, sequences = sequenceCount, mechanisms = mechanismCount, expertBranches = 2, precisionCaps = capCount, descendants = #candidate:GetDescendants(), previous = baseline:GetFullName()})
