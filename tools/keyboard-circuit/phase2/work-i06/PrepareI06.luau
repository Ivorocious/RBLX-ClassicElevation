--!strict
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and not game:GetService("RunService"):IsRunning(), "Intended Edit experience required")
local storage = game:GetService("ServerStorage")
local oldCandidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local oldKit = assert(storage.CourseAssetKits:FindFirstChild("KeyboardCircuit_Phase2EditableKit_K02"))
local owned = assert(shared.KCPhase2Prepared)
assert(owned.candidate == oldCandidate and owned.kit == oldKit and oldCandidate:GetAttribute("ConstructionIteration") == 5)
local prepared = assert(storage:FindFirstChild("KeyboardCircuit_P2_C01_Prepared"))
assert(prepared:GetAttribute("KCOwnedPhase2Preparation") == true)
assert(not prepared:FindFirstChild("Iteration06"), "Inspect existing preparation before retry")
local overrides = assert(shared.KCP2I06GeometryOverrides)
assert(type(overrides.Parts) == "string" and type(overrides.StaticPatterns) == "string")
local builders = assert(storage.CourseBuilders:FindFirstChild("KeyboardCircuitPhase2"))
assert(#builders:GetChildren() == 16)
local holder = Instance.new("Folder")
holder.Name, holder.Parent = "Iteration06", prepared
holder:SetAttribute("KCOwnedPhase2Preparation", true)
holder:SetAttribute("Purpose", "O07 arrow form and O05 bracket marking; inactive reviewable preparation")
local fresh = builders:Clone()
fresh.Name, fresh.Parent = "Sources", holder
for _, item in fresh:GetChildren() do
    if item:IsA("BaseScript") then item.Disabled = true end
    if overrides[item.Name] then item.Source = overrides[item.Name] end
end
local origin = Vector3.new(3300, 330, -1600)
local template = assert(storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true))
assert(template:IsA("MeshPart") and #template:GetChildren() == 0)
local candidate = require(fresh.Course).Build(holder, origin, template)
candidate:SetAttribute("ConstructionIteration", 6)
local function snapshot(model: Model)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "SourceSnapshot", model
    for _, item in fresh:GetChildren() do
        local copy = item:Clone()
        if copy:IsA("BaseScript") then copy.Disabled = true end
        copy.Parent = folder
    end
end
snapshot(candidate)
local kit = Instance.new("Model")
kit.Name, kit.Parent = "KeyboardCircuit_Phase2EditableKit_K02", holder
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
local sequences, encountered, caps, parts, colliders = 0, 0, 0, 0, 0
for _, item in candidate:GetDescendants() do
    if item:GetAttribute("SequenceId") then sequences += 1 end
    if item:GetAttribute("MechanismId") then encountered += 1 end
    if item:IsA("BasePart") then parts += 1; if item.CanCollide then colliders += 1 end end
    if item:IsA("MeshPart") then
        caps += 1
        local visible = 0
        for _, child in item:GetChildren() do if child:IsA("SurfaceGui") and child.Enabled then visible += 1 end end
        assert(visible == 1 and utf8.len(item:GetAttribute("KeyLegend") or "") == 1)
    end
    if item:IsA("BaseScript") then assert(item.Disabled, "Prepared scripts must remain inactive") end
end
assert(sequences == 16 and encountered == 8 and #candidate.RouteEdges:GetChildren() == 25 and #candidate.RecoveryPads:GetChildren() == 4)
assert(workspace.KeyboardCircuit_P2_C01 == oldCandidate and storage.CourseAssetKits.KeyboardCircuit_Phase2EditableKit_K02 == oldKit)
shared.KCP2I06Prepared = {holder = holder, sources = fresh, candidate = candidate, kit = kit, previous = oldCandidate, previousKit = oldKit}
return game:GetService("HttpService"):JSONEncode({candidate = "KC_P2_C01-I06-UI01", installed = false, prepared = holder:GetFullName(),
    candidateDescendants = #candidate:GetDescendants(), kitDescendants = #kit:GetDescendants(), sourceCount = #fresh:GetChildren(),
    sequences = sequences, mechanisms = encountered, caps = caps, parts = parts, colliders = colliders,
    previousIteration = oldCandidate:GetAttribute("ConstructionIteration"), previousPreservedInPlace = true,
    boundary = "Inactive geometry/source preparation in ServerStorage; no native traversal, readability or timing pass"})
