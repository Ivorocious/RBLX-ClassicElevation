--!strict
assert(game.PlaceId == 85558151074819, "Keyboard Circuit target must be Obby Tournament")
assert(not game:GetService("RunService"):IsRunning(), "Build in Edit mode")
assert(not workspace:FindFirstChild("KeyboardCircuit_P1_C07"), "Inspect C07 before rebuilding")
local storage = game:GetService("ServerStorage")
local archive = storage.DeveloperArchives.KeyboardCircuitP1_Archives
local previous = workspace.KeyboardCircuit_P1_C06
local previousKit = storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01
local serialization = game:GetService("SerializationService")
local function signature(root: Instance): string
	local entries = {}
	for _,object in root:GetDescendants() do
		local path = object:GetFullName():sub(#root:GetFullName() + 2)
		if object:IsA("BasePart") then
			local values = {object.CFrame:GetComponents()}
			for i,v in values do values[i] = string.format("%.4f", if math.abs(v) < .00005 then 0 else v) end
			table.insert(entries, path .. "|" .. tostring(object.Size) .. "|" .. table.concat(values, ",") .. "|" .. tostring(object.Color) .. "|" .. tostring(object.CanCollide) .. "|" .. tostring(object.CanQuery) .. "|" .. tostring(object.CanTouch))
		elseif object:IsA("LuaSourceContainer") then
			table.insert(entries, path .. "|" .. object.Source .. "|" .. (if object:IsA("BaseScript") then tostring(object.Disabled) else "module"))
		elseif object:IsA("TextLabel") then table.insert(entries, path .. "|" .. object.Text) end
	end
	table.sort(entries)
	return table.concat(entries, "\n")
end
for name,root in {C06 = previous, KitC06 = previousKit} do
	local stored = assert(shared.KCNativeExports[name], "Saved C06 engine backup required")
	local reopened = serialization:DeserializeInstancesAsync(buffer.fromstring(stored))[1]
	assert(#root:GetDescendants() == #reopened:GetDescendants() and signature(root) == signature(reopened), "Owner changed " .. name .. "; preserve fresh backup before handoff")
end
local root = Instance.new("Model")
root.Name = "KeyboardCircuit_P1_C07"
root:SetAttribute("CourseId", "keyboard-circuit")
root:SetAttribute("CandidateRevision", "KC_P1_C07")
root:SetAttribute("Phase1Only", true)
root:SetAttribute("KCSessionEnabled", true)
local function snapshot(parent: Instance)
	local originals = storage.CourseBuilders.KeyboardCircuit
	assert(#originals:GetChildren() == 10, "Inspect duplicate or missing Rojo sources")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "SourceSnapshot", parent
	local seen = {}
	for _,original in originals:GetChildren() do
		assert(original:IsA("LuaSourceContainer") and not seen[original.Name])
		seen[original.Name] = true
		local copy = Instance.new(original.ClassName)
		copy.Name, copy.Source = original.Name, original.Source
		if copy:IsA("BaseScript") then copy.Disabled = true end
		copy.Parent = folder
	end
	local config = Instance.new("ModuleScript")
	config.Name, config.Source, config.Parent = "ConfigSnapshot", game.ReplicatedStorage.Config.KeyboardCircuitConfig.Source, folder
	return folder
end
local source = snapshot(root)
assert(require(source.ConfigSnapshot).Revision == "KC_P1_C07", "Rojo must synchronize before construction")
local garden = Instance.new("Folder")
garden.Name, garden.Parent = "StudGardenV2", root
storage.CourseBuilders.StudGardenV2.HazardClock:Clone().Parent = garden
local template = storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true)
assert(template and template:IsA("MeshPart"), "Verified K02 key required")
require(source.Sample).Build(root, Vector3.new(2300, 330, -1300), template)
require(source.RouteStudy).Build(root, Vector3.new(2300, 330, -1850))
local temporary = Instance.new("Folder")
local kit = require(source.Kit).Build(temporary, template)
snapshot(kit)
previous:SetAttribute("NativeBackupSHA256", "1d266d59a58cc65e55f88b77d8aa8f3b17a0e06f92aff31473b57c4a6ee6aa14")
previousKit:SetAttribute("NativeBackupSHA256", "51abb213421012b34490f01bad4d9513a0479a40fb476e22902aa9268698e57c")
previous.Parent = archive
previousKit.Name, previousKit.Parent = "KeyboardCircuit_EditableKit_K01_C06_sources", archive
source.Session.Disabled = false
root.Parent, kit.Parent = workspace, storage.CourseAssetKits
return {candidate = root.Name, descendants = #root:GetDescendants(), kit = kit:GetFullName(), kitDescendants = #kit:GetDescendants(), preserved = {previous:GetFullName(), previousKit:GetFullName()}}
