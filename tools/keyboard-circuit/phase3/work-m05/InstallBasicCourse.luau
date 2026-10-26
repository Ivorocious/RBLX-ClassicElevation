assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818, "Wrong experience")
assert(not game:GetService("RunService"):IsRunning(), "Edit installation only")
local Storage = game:GetService("ServerStorage")
local baseline = Storage.DeveloperArchives:FindFirstChild("KeyboardCircuitLatestBaseline")
local original = assert(workspace:FindFirstChild("KeyboardCircuit_P3_M04_01") or (baseline and baseline:FindFirstChild("KeyboardCircuit_P3_M04_01")), "Expected existing M04 map")
assert(original:IsA("Model") and original:GetAttribute("MapRevision") == "KC_MAP_M04_01")
local previous = Storage.CourseLibrary:FindFirstChild("Course_KeyboardCircuit")
assert(not previous or previous:GetAttribute("SharedCourseRevision") == "KC_P3_M05_01", "A different Keyboard Circuit course already exists")
assert(shared.KCM05CleanupReceipt and shared.KCM05CleanupReceipt.finished, "Old history cleanup is not complete")
local prepared = Instance.new("Folder")
prepared.Name, prepared.Parent = "KeyboardCircuitM05Preparation", Storage
local function module(name, source)
	local item = Instance.new("ModuleScript")
	item.Name, item.Source, item.Parent = name, source, prepared
	return item
end
local adapter = require(module("StandardCourse", packet.adapter))
local presentation = require(module("Presentation", packet.presentation))
local course = original:Clone()
adapter.Apply(course)
local materialReport = presentation.Apply(course)
assert(materialReport.killParts == 17, "Unexpected lethal part count")
local snapshot = assert(course:FindFirstChild("SourceSnapshot"))
for _, item in snapshot:GetChildren() do
	if not packet.sources[item.Name] then item:Destroy() end
end
for name, source in packet.sources do
	local item = snapshot:FindFirstChild(name)
	assert(item and item:IsA("ModuleScript"), "Runtime dependency missing: " .. name)
	item.Source = source
end
assert(#snapshot:GetChildren() == 11, "Unexpected runtime source count")
local runtime = Instance.new("Script")
runtime.Name, runtime.Source, runtime.Disabled = "CourseRuntime", packet.runtime, false
runtime.Parent = course
local CourseService = require(game.ServerScriptService.Services.CourseService)
local warnings = CourseService.ValidateCourseModel(course, true)
assert(#warnings == 0, table.concat(warnings, "; "))
local function find(path)
	local node = game
	for name in path:gmatch("[^.]+") do node = assert(node:FindFirstChild(name), path) end
	return node
end
for path, source in packet.globals do
	local item = find(path)
	assert(item:IsA("LuaSourceContainer"))
	item.Source = source
end
find("StarterPlayer.StarterPlayerScripts.KeyboardCircuitPreview").Disabled = true
find("StarterPlayer.StarterPlayerScripts.KeyboardCircuit").Disabled = false
local archive = baseline or Instance.new("Folder")
archive.Name, archive.Parent = "KeyboardCircuitLatestBaseline", Storage.DeveloperArchives
archive:SetAttribute("DiskRecovery", "docs/artifacts/keyboard-circuit/phase3/m05-recovery/M04-before-basic-handoff.rbxm")
for _, item in original:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
original:SetAttribute("KCPhase2SessionEnabled", false)
original:SetAttribute("KCPhase2PreviewEnabled", false)
original.Parent = archive
if previous then previous:Destroy() end
course.Parent = Storage.CourseLibrary
prepared:Destroy()
local receipt = {revision=adapter.Revision, path=course:GetFullName(), courseId=course.CourseInfo:GetAttribute("CourseId"), laps=course.CourseInfo:GetAttribute("LapCount"), checkpoints=course.CourseInfo:GetAttribute("CheckpointCount"), runtimeModules=#snapshot:GetChildren(), neon=materialReport.killParts, descendants=#course:GetDescendants(), baseline=original:GetFullName(), changedGlobals=5, sharedLogic=true, customLapGui=false}
shared.KCM05InstallReceipt = receipt
return game.HttpService:JSONEncode(receipt)
