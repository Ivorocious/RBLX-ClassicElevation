local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local luau = require("@lune/luau")

local root = "docs/artifacts/moonlit-citadel/phase2/"
local candidate = assert(process.args[1], "Provide the frozen candidate ID")
local label = assert(process.args[2], "Provide a fresh recovery label, such as recovery01")
assert(candidate:match("^MC_P2_[%w_]+$"), "Invalid candidate ID")
assert(label:match("^[%w_]+$"), "Use an alphanumeric recovery label")
local sourcePath = process.args[3] or root .. candidate .. "_" .. label .. "_sources.rbxl"
local nativePath = process.args[4] or root .. candidate .. "_native.rbxm"
local checkOnly = process.args[5] == "--check"
assert(process.args[5] == nil or checkOnly, "Fifth argument must be --check")
local output = root .. candidate .. "_" .. label .. "_standalone.rbxl"
local libraryOutput = root .. candidate .. "_" .. label .. "_library.rbxm"
local receiptPath = root .. candidate .. "_" .. label .. "_recovery_receipt.json"
assert(not fs.isFile(output) and not fs.isFile(libraryOutput) and not fs.isFile(receiptPath), "Preserve earlier recovery files; choose a fresh label")

local hashes = {}
for _, path in {"tools/moonlit-citadel/phase2/fixture.project.json", "tools/moonlit-citadel/phase2/PrepareFixture.luau"} do
	hashes[path] = serde.hash("sha256", fs.readFile(path))
end
local function read(path)
	path = path:gsub("\\", "/")
	assert(not path:find("%.%.") and (path:sub(1, #root) == root or path:match("^docs/artifacts/moonlit%-citadel/phase1/")), "Inputs must be saved Moonlit evidence")
	local bytes = fs.readFile(path)
	hashes[path] = serde.hash("sha256", bytes)
	return bytes
end
local function normalized(source)
	return source:gsub("^\239\187\191", ""):gsub("\r\n", "\n")
end
local function at(parent, path)
	for name in path:gmatch("[^/]+") do parent = assert(parent:FindFirstChild(name), "Missing source instance " .. path) end
	return parent
end
local function relative(item, parent)
	local names = {}
	while item ~= parent do table.insert(names, 1, item.Name); item = item.Parent end
	return table.concat(names, "/")
end
local toolSources = {
	["ReplicatedStorage/MoonlitPhase2Tools/ClientProbe"] = "ClientProbe.luau",
	["ReplicatedStorage/MoonlitPhase2Tools/ClientSuite"] = "ClientSuite.luau",
	["ReplicatedStorage/MoonlitPhase2Tools/ContactCases"] = "ContactCases.luau",
	["ReplicatedStorage/MoonlitPhase2Tools/BoundaryCases"] = "BoundaryCases.luau",
	["ReplicatedStorage/MoonlitPhase2Tools/PrivateResetCase"] = "PrivateResetCase.luau",
	["ServerScriptService/MoonlitPhase2Probe"] = "BootstrapProbe.server.luau",
}
for _, name in {"ServerProbe", "CapacityCheck", "ContactCases", "TrialControl", "CapacityCases", "BoundaryCases", "PrivateResetCase"} do
	toolSources["ServerStorage/MoonlitPhase2Tools/" .. name] = name .. ".luau"
end
local function sourceFile(item, place)
	local path = relative(item, place)
	if toolSources[path] then return "tools/moonlit-citadel/phase2/" .. toolSources[path] end
	local stem = "src/" .. path
	local suffix = if item:IsA("LocalScript") then ".client.luau" elseif item:IsA("Script") then ".server.luau" else ".luau"
	if fs.isFile(stem .. suffix) then return stem .. suffix end
	assert(fs.isFile(stem .. "/init" .. suffix), "No durable source mapping for " .. path)
	return stem .. "/init" .. suffix
end
local function checkSources(place)
	local mappings = {}
	for _, item in place:GetDescendants() do
		if not item:IsA("LuaSourceContainer") then continue end
		local path = sourceFile(item, place)
		local bytes = fs.readFile(path)
		assert(normalized(item.Source) == normalized(bytes), "Rojo source is stale: " .. path)
		assert(luau.load(item.Source), "Saved source does not compile: " .. path)
		hashes[path] = serde.hash("sha256", bytes)
		table.insert(mappings, {instancePath = relative(item, place), sourcePath = path, sha256 = hashes[path]})
	end
	assert(#mappings > 0, "Empty source place")
	return mappings
end

local place = roblox.deserializePlace(read(sourcePath))
local sources = checkSources(place)
local config = at(place, "ReplicatedStorage/Config/MoonlitCitadelCourseConfig")
assert(config.Source:match('CandidateId%s*=%s*"([^"]+)"') == candidate, "Config and requested candidate differ")
local storage = place:GetService("ServerStorage")
local workspace = place:GetService("Workspace")
assert(not workspace:FindFirstChild("RaceCourse"), "Use a clean Rojo source place, not a prior recovery place")

for _, model in roblox.deserializeModel(read(root .. "baseline/MC_P2_original_library.rbxm")) do
	assert(storage:FindFirstChild(model.Name) == nil, "Duplicate native library")
	model.Parent = storage
end
local library = assert(storage:FindFirstChild("CourseLibrary"))
local preservedNames = {"Course_ClassicCircuit", "Course_ClassicPointToPoint", "SGV2_Phase3_F04", "Course_KeyboardCircuit", "Course_ShipwreckCove", "Course_CityRun"}
assert(#library:GetChildren() == 6, "Expected the six original native courses")
for _, name in preservedNames do assert(library:FindFirstChild(name), "Missing preserved course " .. name) end
for _, model in roblox.deserializeModel(read(root .. "baseline/MC_P2_shared_lobby_arcade.rbxm")) do
	assert(workspace:FindFirstChild(model.Name) == nil, "Duplicate shared lobby/arcade")
	model.Parent = workspace
end
assert(workspace:FindFirstChild("Lobby") and workspace:FindFirstChild("GrandArcade"), "Shared scenery is incomplete")

local kits = storage:FindFirstChild("CourseAssetKits") or roblox.Instance.new("Folder")
kits.Name, kits.Parent = "CourseAssetKits", storage
for _, assetLibrary in roblox.deserializeModel(read("docs/artifacts/moonlit-citadel/phase1/MC_BL02_library_native.rbxm")) do
	assert(kits:FindFirstChild(assetLibrary.Name) == nil, "Duplicate BL02 asset library")
	assetLibrary.Parent = kits
end
assert(kits:FindFirstChild("MoonlitCitadel_BL02Library"), "Missing approved Blender library")

local recovery = roblox.Instance.new("Folder")
recovery.Name, recovery.Parent = "MoonlitPhase2FixtureRecovery", storage
local phase1 = roblox.Instance.new("Folder")
phase1.Name, phase1.Parent = "PreservedPhase1Fixture", recovery
for _, model in roblox.deserializeModel(read(root .. "baseline/MC_P2_preconversion_fixture.rbxm")) do
	model.Parent = phase1
	if model:GetAttribute("PreviewEnabled") ~= nil then model:SetAttribute("PreviewEnabled", false) end
	if model:IsA("BaseScript") then model.Disabled = true end
	for _, item in model:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
end

local nativeRoots = roblox.deserializeModel(read(nativePath))
assert(#nativeRoots == 1 and nativeRoots[1]:IsA("Model"), "Native course export must contain one Model")
local course = nativeRoots[1]
assert(course:GetAttribute("CandidateId") == candidate and course:GetAttribute("CourseId") == "moonlit_citadel", "Native candidate identity differs")
for _, name in {"CourseInfo", "Start", "Finish", "Checkpoints", "Obstacles", "FallZones", "RouteMarkers", "Decoration", "Bounds"} do
	assert(course:FindFirstChild(name), "Native course is incomplete: " .. name)
end
for _, item in course:GetDescendants() do assert(not item:IsA("LuaSourceContainer"), "Course geometry must use durable shared services") end
course.Name, course.Parent = "Course_MoonlitCitadel", library
local editable = course:Clone()
editable.Name = "RaceCourse"
editable:SetAttribute("RuntimeActiveCourse", nil)
editable:SetAttribute("SourceCourseId", nil)
editable:SetAttribute("ManualEditing", true)
editable.Parent = workspace

local scripts = place:GetService("ServerScriptService")
for _, name in {"MoonlitCitadelPreview", "MoonlitPhase2Probe"} do at(scripts, name).Disabled = true end
local starter = place:GetService("StarterPlayer")
starter.CharacterWalkSpeed = 16
starter.CharacterUseJumpPower = false
starter.CharacterJumpHeight = 7.2
starter.CharacterMaxSlopeAngle = 45
workspace.Gravity = 196.2
local function checkStructure(saved)
	local savedStorage = saved:GetService("ServerStorage")
	local savedWorkspace = saved:GetService("Workspace")
	local savedLibrary = assert(savedStorage:FindFirstChild("CourseLibrary"))
	assert(#savedLibrary:GetChildren() == 7, "Recovery must have exactly seven library courses")
	for _, name in preservedNames do assert(savedLibrary:FindFirstChild(name), "Lost original course " .. name) end
	for _, target in {savedLibrary.Course_MoonlitCitadel, savedWorkspace.RaceCourse} do
		assert(target:GetAttribute("CandidateId") == candidate and target:GetAttribute("CourseId") == "moonlit_citadel", "Recovery identity mismatch")
	end
	assert(savedWorkspace.RaceCourse:GetAttribute("RuntimeActiveCourse") ~= true, "Editable geometry must be archived on Play")
	assert(not savedWorkspace:FindFirstChild("MoonlitCitadelPhase1_BL02"), "P1 preview would duplicate colliding course geometry")
	assert(savedStorage.MoonlitPhase2Tools:FindFirstChild("CapacityCases"), "Missing durable capacity cases")
	assert(saved:GetService("ServerScriptService").MoonlitCitadelPreview.Disabled and saved:GetService("ServerScriptService").MoonlitPhase2Probe.Disabled, "Authoring startup must stay quiet")
end
checkStructure(place)
local receipt = {candidate = candidate, checkOnly = checkOnly, file = output, libraryFile = libraryOutput, sources = sources, hashes = hashes,
	library = 7, preservedCourses = preservedNames, editableCoursePath = "Workspace/RaceCourse",
	diagnosticsDisabled = true, phase1RecoveryPath = "ServerStorage/MoonlitPhase2FixtureRecovery/PreservedPhase1Fixture",
	movement = {walkSpeed = 16, useJumpPower = false, jumpHeight = 7.2, maxSlopeAngle = 45, gravity = 196.2},
	limits = "Saved-file checks only; native Avatar Settings, live Rojo, gameplay, crowd traffic, FPS and publication are not proved"}
if not checkOnly then
	fs.writeFile(output, roblox.serializePlace(place))
	fs.writeFile(libraryOutput, roblox.serializeModel({library}))
	local saved = roblox.deserializePlace(fs.readFile(output))
	checkStructure(saved)
	-- Recovery copies contain preserved P1 scripts; verify current scripts through their explicit source paths.
	for _, entry in sources do assert(normalized(at(saved, entry.instancePath).Source) == normalized(fs.readFile(entry.sourcePath)), "Saved source mismatch " .. entry.sourcePath) end
	receipt.hashes[output] = serde.hash("sha256", fs.readFile(output))
	receipt.hashes[libraryOutput] = serde.hash("sha256", fs.readFile(libraryOutput))
	fs.writeFile(receiptPath, serde.encode("json", receipt, true))
end
print(serde.encode("json", receipt, true))
