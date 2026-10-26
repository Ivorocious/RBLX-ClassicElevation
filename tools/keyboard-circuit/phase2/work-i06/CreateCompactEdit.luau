--!strict
local RunService, Storage = game:GetService("RunService"), game:GetService("ServerStorage")
assert(RunService:IsStudio() and not RunService:IsRunning())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local original = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
assert(original:GetAttribute("ConstructionIteration") == 5)
local name, holderName = "KeyboardCircuit_P2_PacingI06_01", "KCP2PacingI06_01_Sources"
assert(not workspace:FindFirstChild(name) and not Storage:FindFirstChild(holderName), "Inspect existing prototype before retry")
local origin = Vector3.new(7500, 330, -1600)
assert(#workspace:GetPartBoundsInBox(CFrame.new(origin), Vector3.new(600, 120, 540)) == 0, "Prototype space is occupied")
local overrides = assert(shared.KCP2CompactOverrides13)
for _, key in {"Parts", "StaticPatterns", "Layout", "Course"} do assert(type(overrides[key]) == "string") end
local originalTexts = {}
for _, item in original.SourceSnapshot:GetChildren() do originalTexts[item.Name] = item.Source end
local holder = Instance.new("Folder")
holder.Name, holder.Parent = holderName, Storage
holder:SetAttribute("KCOwnedPhase2Preparation", true)
holder:SetAttribute("Purpose", "Separate compact timing prototype; original I05 remains installed")
local sources = original.SourceSnapshot:Clone()
sources.Name, sources.Parent = "Sources", holder
assert(#sources:GetChildren() == 16)
for _, item in sources:GetChildren() do
	if item:IsA("BaseScript") then item.Disabled = true end
	if overrides[item.Name] then item.Source = overrides[item.Name] end
end
local template = assert(Storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true))
assert(template:IsA("MeshPart"))
local prototype = require(sources.Course).Build(holder, origin, template)
prototype.Name = name
prototype:SetAttribute("ConstructionIteration", 6)
prototype:SetAttribute("PrototypeOnly", true)
prototype:SetAttribute("PrototypeRevision", "KC_P2_I06_COMPACT_01")
local snapshot = sources:Clone()
snapshot.Name, snapshot.Parent = "SourceSnapshot", prototype
local sequences, mechanisms = 0, 0
for _, item in prototype:GetDescendants() do
	if item:GetAttribute("SequenceId") then sequences += 1 end
	if item:GetAttribute("MechanismId") then mechanisms += 1 end
	if item:IsA("BaseScript") then assert(item.Disabled) end
end
assert(sequences == 16 and mechanisms == 8 and #prototype.RouteEdges:GetChildren() == 25)
assert(#prototype.RecoveryPads:GetChildren() == 4 and #prototype.ExpertRoutes:GetChildren() == 2)
for _, branch in prototype.ExpertRoutes:GetChildren() do
	assert(branch:GetAttribute("PrecisionLandings") == (if branch:GetAttribute("ExpertId") == "X01" then 10 else 7))
end
assert(prototype:GetAttribute("TargetRaceSecondsMax") == 360 and prototype:GetAttribute("TargetExpertRaceSecondsMax") == 180)
for _, item in original.SourceSnapshot:GetChildren() do assert(item.Source == originalTexts[item.Name]) end
assert(workspace.KeyboardCircuit_P2_C01 == original)
prototype.Parent = workspace
snapshot.Session.Disabled = false
shared.KCP2CompactEdit13 = {candidate = prototype, holder = holder, sources = sources, original = original, originalTexts = originalTexts}
return game:GetService("HttpService"):JSONEncode({created = true, prototype = prototype:GetFullName(), origin = {origin.X, origin.Y, origin.Z},
	sequences = sequences, mechanisms = mechanisms, sources = #snapshot:GetChildren(), descendants = #prototype:GetDescendants(), originalIteration = original:GetAttribute("ConstructionIteration"),
	boundary = "Separate compact course installed in Edit for owner Dev Tools testing; original I05 preserved, no whole-place save."})

