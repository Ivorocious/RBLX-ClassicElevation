local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local prefix = "tools/keyboard-circuit/phase3/work-m05/"
local sources = {
	client = "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuit.client.luau",
	ambience = "src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau",
}
local allSignals, deferred, warnings = {}, {}, {}
local function signal()
	local value = {listeners = {}}
	function value:Connect(callback)
		local connection = {Connected = true}
		function connection:Disconnect() self.Connected = false end
		table.insert(self.listeners, {callback = callback, connection = connection})
		return connection
	end
	function value:Fire(...)
		for _, listener in table.clone(self.listeners) do
			if listener.connection.Connected then listener.callback(...) end
		end
	end
	function value:DisconnectAll()
		for _, listener in self.listeners do listener.connection:Disconnect() end
	end
	table.insert(allSignals, value)
	return value
end

local methods, nodeMeta = {}, {}
local function node(className, name)
	local object = setmetatable({fields = {ClassName = className, Name = name or className}, children = {}, attributes = {}, properties = {}, attributeSignals = {}}, nodeMeta)
	for _, name in {"ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "Destroying"} do object.fields[name] = signal() end
	if className == "Humanoid" then object.fields.Health, object.fields.Died = 100, signal() end
	if className == "LocalScript" or className == "ColorCorrectionEffect" then object.fields.Enabled = true end
	return object
end
function methods:IsA(className)
	return self.ClassName == className or className == "Instance"
		or className == "BasePart" and self.ClassName == "Part"
		or className == "PostEffect" and self.ClassName == "ColorCorrectionEffect"
end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
	local result = {}
	for _, child in self.children do
		table.insert(result, child)
		for _, descendant in child:GetDescendants() do table.insert(result, descendant) end
	end
	return result
end
function methods:FindFirstChild(name)
	for _, child in self.children do if child.Name == name then return child end end
	return nil
end
function methods:FindFirstChildOfClass(className)
	for _, child in self.children do if child:IsA(className) then return child end end
	return nil
end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:SetAttribute(name, value)
	if self.attributes[name] == value then return end
	self.attributes[name] = value
	if self.attributeSignals[name] then self.attributeSignals[name]:Fire() end
end
function methods:GetAttributeChangedSignal(name)
	self.attributeSignals[name] = self.attributeSignals[name] or signal()
	return self.attributeSignals[name]
end
function methods:GetPropertyChangedSignal(name)
	self.properties[name] = self.properties[name] or signal()
	return self.properties[name]
end
function methods:GetBoundingBox() return self.frame, self.size end
function methods:Destroy()
	self.Destroying:Fire()
	for _, child in self:GetChildren() do child:Destroy() end
	self.Parent = nil
	for _, value in self.fields do if type(value) == "table" and value.DisconnectAll then value:DisconnectAll() end end
	for _, value in self.properties do value:DisconnectAll() end
	for _, value in self.attributeSignals do value:DisconnectAll() end
end
nodeMeta.__index = function(self, key)
	if methods[key] then return methods[key] end
	if self.fields[key] ~= nil then return self.fields[key] end
	return self:FindFirstChild(key)
end
nodeMeta.__newindex = function(self, key, value)
	if key == "Parent" then
		local previous = self.fields.Parent
		if previous == value then return end
		local branch = {self}
		for _, descendant in self:GetDescendants() do table.insert(branch, descendant) end
		local ancestor = previous
		while ancestor do
			for _, object in branch do ancestor.DescendantRemoving:Fire(object) end
			ancestor = ancestor.Parent
		end
		if previous then
			local index = table.find(previous.children, self)
			if index then table.remove(previous.children, index) end
		end
		self.fields.Parent = value
		if previous then previous.ChildRemoved:Fire(self) end
		if value then
			table.insert(value.children, self)
			value.ChildAdded:Fire(self)
			ancestor = value
			while ancestor do
				for _, object in branch do ancestor.DescendantAdded:Fire(object) end
				ancestor = ancestor.Parent
			end
		end
	else
		local previous = self.fields[key]
		self.fields[key] = value
		if previous ~= value and self.properties[key] then self.properties[key]:Fire() end
	end
end
local function flush()
	local count = 0
	while #deferred > 0 do
		count += 1
		assert(count <= 100, "Unexpected deferred retry loop")
		table.remove(deferred, 1)()
	end
end
local Workspace, Lighting = node("Workspace"), node("Lighting")
Lighting.Brightness = 3.25
local baselineSky, baselineAtmosphere = node("Sky"), node("Atmosphere")
baselineSky.SkyboxUp, baselineSky.Parent = "baseline-sky", Lighting
baselineAtmosphere.Density, baselineAtmosphere.Parent = .12, Lighting
local player, playerGui, playerScripts = node("Player"), node("PlayerGui"), node("PlayerScripts")
playerGui.Parent, playerScripts.Parent = player, player
player.CharacterAdded, player.CharacterRemoving = signal(), signal()
local Players, RunService, ReplicatedStorage = {LocalPlayer = player}, {Heartbeat = signal()}, node("ReplicatedStorage")
function RunService:IsStudio() return false end
local configFolder = node("Folder", "Config")
configFolder.Parent = ReplicatedStorage
for _, name in {"RaceConfig", "ClassicAscentAmbienceConfig", "CityRunAmbienceConfig", "ShipwreckAmbienceConfig", "StudGardenAmbienceConfig"} do
	local module = node("ModuleScript", name)
	module.Parent = configFolder
end
local generalScript, clientScript = node("LocalScript", "ClassicAscentAmbience"), node("LocalScript", "KeyboardCircuitPhase2Preview")
generalScript.Parent, clientScript.Parent = playerScripts, playerScripts
local lobby = node("Model", "Lobby")
lobby.frame, lobby.size, lobby.Parent = roblox.CFrame.new(), roblox.Vector3.new(50, 30, 50), Workspace
local function makeCharacter(complete)
	local character = node("Model", "TestPlayer")
	character.Parent = Workspace
	if complete then
		local root, humanoid = node("Part", "HumanoidRootPart"), node("Humanoid")
		root.Position, root.Parent, humanoid.Parent = roblox.Vector3.new(), character, character
	end
	return character
end
player.Character = makeCharacter(true)
local function setPosition(x)
	player.Character.HumanoidRootPart.Position = roblox.Vector3.new(x, 5, 0)
end
local function makeCourse(id, archive)
	local course, info, start = node("Model", "RaceCourse"), node("Folder", "CourseInfo"), node("Part", "Start")
	course.frame, course.size = roblox.CFrame.new(1000, 5, 0), roblox.Vector3.new(300, 100, 300)
	course:SetAttribute("CourseId", id)
	course:SetAttribute("SharedCourseEnabled", true)
	course:SetAttribute("KCArchiveAmbience", archive)
	info:SetAttribute("CourseId", id)
	info.Parent, start.Position, start.Parent = course, roblox.Vector3.new(1000, 5, 0), course
	return course
end
local function makeSnapshot(course)
	local snapshot = node("Folder", "SourceSnapshot")
	for _, name in {"KeyboardCircuitAudio", "KeyboardCircuitFeedback", "ConfigSnapshot", "ArchiveEffects", "ArchiveSkyConfig"} do
		local module = node("ModuleScript", name)
		module.Parent = snapshot
	end
	snapshot.Parent = course
	return snapshot
end
local stats = {feedbackStarts = 0, feedbackStops = 0, effectsStarts = 0, effectsStops = 0, readiness = 0, maximumFeedback = 0, maximumEffects = 0}
local feedbackActive, effectsActive, archiveBaselines = 0, 0, {}
local Feedback = {}
function Feedback.Start(course)
	stats.feedbackStarts += 1
	feedbackActive += 1
	stats.maximumFeedback = math.max(stats.maximumFeedback, feedbackActive)
	assert(course.Name == "RaceCourse" and course:GetAttribute("CourseId") == "keyboard_circuit")
	local folder = node("Folder", "KeyboardCircuitAudition")
	folder.Parent = player:FindFirstChildOfClass("PlayerGui")
	local alive = true
	return {
		Readiness = function() return {state = "ready", loaded = 8, total = 8} end,
		Stop = function()
			if not alive then return end
			alive = false
			feedbackActive -= 1
			stats.feedbackStops += 1
			folder:Destroy()
		end,
	}
end
local Effects = {}
function Effects.Start(course, feedback)
	assert(generalScript:GetAttribute("KCArchiveYielded") == course.Name, "Archive started before general baseline restore")
	assert(feedback and feedbackActive == 1, "Archive lost feedback handle")
	local baseline = Lighting.Brightness
	table.insert(archiveBaselines, baseline)
	stats.effectsStarts += 1
	effectsActive += 1
	stats.maximumEffects = math.max(stats.maximumEffects, effectsActive)
	local world, probes = node("Folder", "KeyboardCircuitArchiveVisuals"), node("Folder", "KeyboardCircuitArchiveEffects")
	world.Parent, probes.Parent = Workspace, player:FindFirstChildOfClass("PlayerGui")
	local token, alive = "owner/" .. stats.effectsStarts, true
	player:SetAttribute("KCArchiveLightingOwner", token)
	Lighting.Brightness = .75
	return {
		NotifyReady = function(state)
			assert(state.state == "ready" and state.loaded == 8)
			stats.readiness += 1
		end,
		Stop = function()
			if not alive then return end
			alive = false
			stats.effectsStops += 1
			effectsActive -= 1
			world:Destroy()
			probes:Destroy()
			Lighting.Brightness = baseline
			if player:GetAttribute("KCArchiveLightingOwner") == token then player:SetAttribute("KCArchiveLightingOwner", nil) end
		end,
	}
end
local profileIds = {
	ClassicAscentAmbienceConfig = "classic_ascent",
	CityRunAmbienceConfig = "city_run",
	ShipwreckAmbienceConfig = "shipwreck_cove",
	StudGardenAmbienceConfig = "stud_garden_v2",
}
local function loadModule(module)
	if module.Name == "RaceConfig" then return {LobbyModelName = "Lobby", LobbyAmbiencePadding = roblox.Vector3.new(8, 12, 8)} end
	if module.Name == "KeyboardCircuitFeedback" then return Feedback end
	if module.Name == "ArchiveEffects" then return Effects end
	if profileIds[module.Name] then
		return {
			CourseId = profileIds[module.Name], ActivationDistance = 500,
			Lighting = {Brightness = 2.2}, Atmosphere = {Density = .2},
			Sky = {SkyboxUp = "city-sky"}, ColorCorrection = {Contrast = .05},
		}
	end
	error("Unexpected module: " .. tostring(module.Name))
end
local services = {Players = Players, RunService = RunService, Workspace = Workspace, Lighting = Lighting, ReplicatedStorage = ReplicatedStorage}
local function execute(path, localScript)
	local env = {
		game = {GetService = function(_, name) return assert(services[name], "Unexpected service " .. name) end},
		workspace = Workspace, script = localScript, require = loadModule,
		Instance = {new = node}, task = {defer = function(callback) table.insert(deferred, callback) end},
		warn = function(message) table.insert(warnings, tostring(message)) end,
	}
	for key, value in roblox do if key ~= "Instance" then env[key] = value end end
	luau.load(fs.readFile(path), {environment = env, debugName = path})()
end
local city = makeCourse("city_run", false)
city.Parent = Workspace
execute(sources.ambience, generalScript)
execute(sources.client, clientScript)
local checks = {}
local function check(name, condition)
	assert(condition, name)
	table.insert(checks, name)
end
local function tick()
	RunService.Heartbeat:Fire(.5)
	flush()
end
tick()
check("Loaded ordinary client stays quiet in Lobby", feedbackActive == 0 and effectsActive == 0 and Lighting.Brightness == 3.25)
setPosition(1000)
tick()
check("Existing City Run applies its normal profile", Lighting.Brightness == 2.2 and baselineSky.SkyboxUp == "city-sky")

city.Parent = nil
local course = makeCourse("keyboard_circuit", true)
makeSnapshot(course)
course.Parent = Workspace
check("Shared course automatically starts feedback without prototype enrollment or Studio", feedbackActive == 1 and effectsActive == 0 and player:GetAttribute("KCPhase2Candidate") == nil)
tick()
check("Archive waits for general baseline restore", effectsActive == 1 and archiveBaselines[1] == 3.25 and not Lighting.CourseColor.Enabled)
check("No custom ScreenGui or progression attributes are created", playerGui:FindFirstChildOfClass("ScreenGui") == nil and player:GetAttribute("KCPhase2Lap") == nil)

setPosition(0)
tick()
check("Leaving to Lobby restores baseline while course remains selected", effectsActive == 0 and feedbackActive == 1 and Lighting.Brightness == 3.25 and player:GetAttribute("KCArchiveLightingOwner") == nil)
local feedbackStarts = stats.feedbackStarts
setPosition(1000)
tick()
check("Re-entering starts fresh effects without duplicate feedback", effectsActive == 1 and stats.feedbackStarts == feedbackStarts and stats.effectsStarts == 2)
player:SetAttribute("ArrivalOpen", true)
check("Opening arrival immediately stops Archive effects", effectsActive == 0 and Lighting.Brightness == 3.25)
player:SetAttribute("ArrivalOpen", false)
tick()

local oldCharacter = player.Character
oldCharacter.Humanoid.Health = 0
oldCharacter.Humanoid.Died:Fire()
check("Death immediately releases effects and feedback", effectsActive == 0 and feedbackActive == 0 and Lighting.Brightness == 3.25)
tick()
player.CharacterRemoving:Fire(oldCharacter)
player.Character = nil
oldCharacter.Parent = nil
flush()
local fresh = makeCharacter(false)
player.Character = fresh
player.CharacterAdded:Fire(fresh)
check("Incomplete respawn does not start feedback early", feedbackActive == 0)
local root, humanoid = node("Part", "HumanoidRootPart"), node("Humanoid")
root.Position, root.Parent = roblox.Vector3.new(1000, 5, 0), fresh
check("Respawn still waits for a living Humanoid", feedbackActive == 0)
humanoid.Parent = fresh
tick()
check("Completed respawn automatically recovers", feedbackActive == 1 and effectsActive == 1)

local snapshot = course.SourceSnapshot
snapshot.ConfigSnapshot.Parent = nil
check("Removing required runtime source stops old resources immediately", feedbackActive == 0 and effectsActive == 0)
flush()
local config = node("ModuleScript", "ConfigSnapshot")
config.Parent = snapshot
check("Reassembled runtime source restarts exactly once", feedbackActive == 1 and effectsActive == 1)

snapshot.Parent = nil
flush()
check("SourceSnapshot removal stops the old run", feedbackActive == 0 and effectsActive == 0)
makeSnapshot(course)
check("SourceSnapshot replacement recovers", feedbackActive == 1 and effectsActive == 1)
course.Name = "RetiredCourse"
check("Retiring active model stops feedback and effects", feedbackActive == 0 and effectsActive == 0)
course.Name = "RaceCourse"
check("Restoring active model name recovers", feedbackActive == 1 and effectsActive == 1)
local duplicate = makeCourse("keyboard_circuit", true)
duplicate.Parent = Workspace
check("Ambiguous RaceCourse copies fail closed", feedbackActive == 0 and effectsActive == 0)
duplicate.Parent = nil
check("Removing duplicate recovers one active run", feedbackActive == 1 and effectsActive == 1)

course:SetAttribute("SharedCourseEnabled", false)
check("Disabled shared course stops client resources", feedbackActive == 0 and effectsActive == 0)
course:SetAttribute("SharedCourseEnabled", true)
check("Shared course enable recovers", feedbackActive == 1 and effectsActive == 1)
playerGui.Parent = nil
check("PlayerGui removal cleans existing run", feedbackActive == 0 and effectsActive == 0)
playerGui = node("PlayerGui")
playerGui.Parent = player
check("Replacement PlayerGui recovers", feedbackActive == 1 and effectsActive == 1)

course:Destroy()
flush()
check("Destroying selected course releases resources", feedbackActive == 0 and effectsActive == 0 and Lighting.Brightness == 3.25)
city.Parent = Workspace
tick()
check("Archive hands control back to actual City Run profile", Lighting.Brightness == 2.2 and Lighting.CourseColor.Enabled and baselineSky.SkyboxUp == "city-sky" and baselineAtmosphere.Density == .2)
setPosition(0)
tick()
check("Existing map restores original Lobby object references and values", Lighting.Brightness == 3.25 and baselineSky.Parent == Lighting and baselineSky.SkyboxUp == "baseline-sky" and baselineAtmosphere.Parent == Lighting and baselineAtmosphere.Density == .12)
clientScript:Destroy()
generalScript:Destroy()
flush()
local listeners = 0
for _, event in allSignals do
	for _, listener in event.listeners do if listener.connection.Connected then listeners += 1 end end
end
check("Script destruction disconnects lifecycle listeners", listeners == 0)
check("No duplicate resources or client startup warnings", stats.maximumFeedback == 1 and stats.maximumEffects == 1 and #warnings == 0)
for _, value in archiveBaselines do assert(value == 3.25, "Archive captured another map profile as its baseline") end
local hashes = {}
for name, path in sources do hashes[name] = serde.hash("sha256", fs.readFile(path)) end
local report = {passed = true, checks = checks, stats = stats, sourceHashes = hashes, remainingListeners = listeners,
	boundary = "Actual assigned LocalScripts executed in Lune with mocked Roblox signals, hierarchy, feedback and effect controllers. Checks prove client control flow and resource calls. Native asset loading, key feel, real shared HUD, physics and Studio appearance still require Play verification."}
fs.writeFile(prefix .. "client-lifecycle-result.json", serde.encode("json", report, true))
print(serde.encode("json", report))

