local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local prefix = "tools/keyboard-circuit/phase3/work-m06/"
local baselinePath = "docs/artifacts/keyboard-circuit/phase3/M06-before-checkpoint-fix.rbxm"
local repairPath = prefix .. "ExpertCheckpoints.luau"
local checkpointPath = "src/ServerScriptService/Services/CheckpointService.luau"
local courseServicePath = "src/ServerScriptService/Services/CourseService.luau"
local sourceText = {
	repair = fs.readFile(repairPath),
	checkpointService = fs.readFile(checkpointPath),
	courseService = fs.readFile(courseServicePath),
}
local function environment(extra)
	local result = {print = function() end}
	for key, value in roblox do result[key] = value end
	for key, value in extra or {} do result[key] = value end
	return result
end
local repair = luau.load(sourceText.repair, {environment = environment(), debugName = "ExpertCheckpoints"})()
local baselineBytes = fs.readFile(baselinePath)
local original = roblox.deserializeModel(baselineBytes)[1]
assert(original:IsA("Model") and original:GetAttribute("CourseId") == "keyboard_circuit")
assert(original:GetAttribute("SharedCourseRevision") == "KC_P3_M05_01")
local repaired = original:Clone()
local partProperties = {"CFrame", "Size", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow", "Color", "Material", "Transparency", "Reflectance"}
local records, sourceHashes, partCount, checkpointCount = {}, {}, 0, 0
local originals = repaired:GetDescendants()
table.insert(originals, repaired)
for _, item in originals do
	local record = {item = item, name = item.Name, parent = item.Parent, attributes = item:GetAttributes(), properties = {}}
	if item:IsA("BasePart") then
		partCount += 1
		for _, name in partProperties do record.properties[name] = item[name] end
	end
	if item:IsA("LuaSourceContainer") then
		record.source = item.Source
		sourceHashes[item:GetFullName()] = serde.hash("sha256", item.Source)
	end
	if item:IsA("BaseScript") then record.properties.Disabled = item.Disabled end
	if item:IsA("BasePart") and item.Name:match("^Checkpoint_%d%d%d$") then checkpointCount += 1 end
	table.insert(records, record)
end
local initialCount = #repaired:GetDescendants()
local rootChanges = {ExpertCheckpointRevision = true, ExpertCheckpointTriggers = true, CandidateRevision = true, MapRevision = true}
local function preserved()
	for _, record in records do
		local item = record.item
		assert(item.Name == record.name and item.Parent == record.parent, "Original identity or parent changed: " .. record.name)
		for name, before in record.attributes do
			if item ~= repaired or not rootChanges[name] then assert(item:GetAttribute(name) == before, "Original attribute changed: " .. record.name .. "." .. name) end
		end
		for name, after in item:GetAttributes() do
			if item ~= repaired or not rootChanges[name] then assert(record.attributes[name] == after, "Unexpected attribute: " .. record.name .. "." .. name) end
		end
		for name, before in record.properties do assert(item[name] == before, "Original property changed: " .. record.name .. "." .. name) end
		if record.source then assert(item.Source == record.source, "Original source changed: " .. record.name) end
	end
end
assert(repair.Apply(repaired) == repaired)
preserved()
assert(checkpointCount == 8)
assert(#repaired:GetDescendants() == initialCount + 27, "Repair must add only 25 parts and two folders")
assert(repaired:GetAttribute("SharedCourseRevision") == "KC_P3_M05_01" and repaired:GetAttribute("CandidateRevision") == "KC_P3_M06_01")
local firstResult = roblox.serializeModel({repaired})
assert(repair.Apply(repaired) == repaired)
preserved()
assert(#repaired:GetDescendants() == initialCount + 27 and roblox.serializeModel({repaired}) == firstResult, "Repeated application changed the repair")

local routeDefinitions = {
	X03 = {index = 1, count = 13, recovery = "R1"},
	X02 = {index = 5, count = 12, recovery = "R3"},
}
local function route(course, id)
	local result
	for _, child in course.Obstacles.ExpertRoutes:GetChildren() do
		if child:GetAttribute("ExpertId") == id then assert(not result, "Duplicate Expert route"); result = child end
	end
	return assert(result, "Missing Expert route " .. id)
end
local function primary(course, index) return assert(course.Checkpoints:FindFirstChild(string.format("Checkpoint_%03d", index))) end
local function contact(course, id, index)
	local landing = assert(route(course, id):FindFirstChild("PrecisionLanding" .. index))
	return assert(landing:FindFirstChild("KeyContact"))
end
local function alias(course, id, index)
	local checkpoint = primary(course, routeDefinitions[id].index)
	return assert(checkpoint.AlternateTriggers:FindFirstChild(string.format("%s_%02d", id, index)))
end
local function rootOnContact(support, x, z)
	return support.CFrame:PointToWorldSpace(roblox.Vector3.new(x or 0, support.Size.Y / 2 + 3.3, z or 0))
end
local function contains(trigger, point)
	local localPoint, half = trigger.CFrame:PointToObjectSpace(point), trigger.Size / 2
	return math.abs(localPoint.X) <= half.X + .001 and math.abs(localPoint.Y) <= half.Y + .001 and math.abs(localPoint.Z) <= half.Z + .001
end
local aliases, folders, footprintSamples, geometry = 0, 0, 0, {}
for _, checkpoint in repaired.Checkpoints:GetChildren() do
	local alternatives = checkpoint:FindFirstChild("AlternateTriggers")
	if not alternatives then continue end
	assert(checkpoint:IsA("BasePart") and alternatives:IsA("Folder"))
	folders += 1
	for _, trigger in alternatives:GetChildren() do
		assert(trigger:IsA("Part"), "Alternate folder contains unrelated content")
		aliases += 1
	end
end
assert(aliases == 25 and folders == 2)
for id, definition in routeDefinitions do
	local checkpoint = primary(repaired, definition.index)
	assert(#checkpoint.AlternateTriggers:GetChildren() == definition.count)
	for index = 1, definition.count do
		local support, trigger = contact(repaired, id, index), alias(repaired, id, index)
		assert(support.Anchored and support.CanCollide and support:GetAttribute("Role") == "Walkable")
		assert(trigger.Anchored and not trigger.CanCollide and trigger.CanTouch and not trigger.CanQuery and not trigger.CastShadow and trigger.Transparency == 1)
		local expectedSize = roblox.Vector3.new(support.Size.X, 7, support.Size.Z)
		assert((trigger.Size - expectedSize).Magnitude < .0001, "Trigger footprint differs from actual support: " .. trigger.Name .. " " .. tostring(trigger.Size) .. " != " .. tostring(expectedSize))
		assert((trigger.CFrame.Position - (support.CFrame.Position + roblox.Vector3.new(0, 3.5, 0))).Magnitude < .0001)
		assert(trigger:GetAttribute("ExpertRouteId") == id and trigger:GetAttribute("PrecisionLandingIndex") == index)
		assert(trigger:GetAttribute("CheckpointIndex") == definition.index and trigger:GetAttribute("RecoveryGate") == definition.recovery)
		local copiedPose, safePose = trigger:GetAttribute("RespawnCFrame"), checkpoint:GetAttribute("RespawnCFrame")
		local copiedArea, safeArea = trigger:GetAttribute("RespawnAreaSize"), checkpoint:GetAttribute("RespawnAreaSize")
		assert(typeof(copiedPose) == "CFrame" and typeof(safePose) == "CFrame" and typeof(copiedArea) == "Vector3" and typeof(safeArea) == "Vector3")
		assert((copiedPose.Position - safePose.Position).Magnitude < .0001
			and (copiedPose.RightVector - safePose.RightVector).Magnitude < .0001
			and (copiedPose.UpVector - safePose.UpVector).Magnitude < .0001
			and (copiedPose.LookVector - safePose.LookVector).Magnitude < .0001
			and (copiedArea - safeArea).Magnitude < .0001, "Alias recovery differs from its primary bank: " .. trigger.Name)
		for _, x in {-support.Size.X / 2, 0, support.Size.X / 2} do
			for _, z in {-support.Size.Z / 2, 0, support.Size.Z / 2} do
				local point = rootOnContact(support, x, z)
				local localPoint, half = trigger.CFrame:PointToObjectSpace(point), trigger.Size / 2
				assert(contains(trigger, point), string.format("Actual precision support footprint not covered: %s local=(%.8f, %.8f, %.8f) half=(%.8f, %.8f, %.8f)", trigger.Name, localPoint.X, localPoint.Y, localPoint.Z, half.X, half.Y, half.Z))
				footprintSamples += 1
			end
		end
		table.insert(geometry, {route = id, landing = index, checkpoint = definition.index, supportSize = tostring(support.Size), triggerSize = tostring(trigger.Size)})
	end
end

local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			local entry = {callback = callback, active = true}
			table.insert(callbacks, entry)
			return {Disconnect = function() entry.active = false end}
		end,
		Fire = function(_, ...)
			for _, entry in table.clone(callbacks) do if entry.active then entry.callback(...) end end
		end,
	}
end
local function runner(input)
	local course = input:Clone()
	local workspace, storage, replicated = roblox.Instance.new("Folder"), roblox.Instance.new("Folder"), roblox.Instance.new("Folder")
	workspace.Name, course.Name, course.Parent = "Workspace", "RaceCourse", workspace
	local modulePaths = {}
	for _, folderName in {"Config", "Shared"} do
		local folder = roblox.Instance.new("Folder")
		folder.Name, folder.Parent = folderName, replicated
		for _, name in if folderName == "Config" then {"CourseConfig", "CheckpointConfig"} else {"RaceConstants", "RaceTypes", "ForwardGate"} do
			local module = roblox.Instance.new("ModuleScript")
			module.Name, module.Parent = name, folder
			modulePaths[module] = "src/ReplicatedStorage/" .. folderName .. "/" .. name .. ".luau"
		end
	end
	local warnings, cache = {}, {}
	local loadModule
	loadModule = function(module)
		if cache[module] then return cache[module] end
		cache[module] = luau.load(fs.readFile(assert(modulePaths[module])), {environment = environment({script = module, require = loadModule}), debugName = module.Name})()
		return cache[module]
	end
	local heartbeat = signal()
	local state = {now = 0, active = true, official = true, status = "Racing", raceId = "", serial = 0, splits = {}, laps = {}, finishes = {}}
	local root = {Position = roblox.Vector3.zero, IsA = function(_, name) return name == "BasePart" end}
	local humanoid = {Health = 100}
	local character = {attributes = {}}
	function character:FindFirstChild(name) return if name == "HumanoidRootPart" then root else nil end
	function character:FindFirstChildOfClass(name) return if name == "Humanoid" then humanoid else nil end
	function character:GetAttribute(name) return self.attributes[name] end
	local player = {Name = "ExpertCheckpointProbe", UserId = 1, Character = character}
	local players = {PlayerRemoving = signal(), GetPlayers = function() return {player} end, GetPlayerFromCharacter = function(_, value) return if value == character then player else nil end}
	local services = {ReplicatedStorage = replicated, ServerStorage = storage, Workspace = workspace, Players = players, RunService = {IsStudio = function() return false end, Heartbeat = heartbeat}}
	local game = {GetService = function(_, name) return assert(services[name], "Unexpected service " .. name) end}
	local globals = environment({game = game, require = loadModule, warn = function(message) table.insert(warnings, tostring(message)) end})
	local CourseService = luau.load(sourceText.courseService, {environment = globals, debugName = "CourseService"})()
	assert(#CourseService.ValidateCourseModel(course, true) == 0)
	assert(CourseService.GetActiveCourseId() == "keyboard_circuit" and CourseService.GetRaceFormat() == "LapBased" and CourseService.GetLapCount() == 2)
	local ordered = CourseService.GetOrderedCheckpoints()
	assert(#ordered == 8)
	local proxies, triggers = {}, {}
	local proxy
	proxy = function(part)
		if proxies[part] then return proxies[part] end
		local value = {raw = part, Name = part.Name, CFrame = part.CFrame, Size = part.Size, Touched = signal()}
		function value:IsA(name) return part:IsA(name) end
		function value:IsDescendantOf(parent) return part:IsDescendantOf(parent.raw or parent) end
		function value:GetAttribute(name) return part:GetAttribute(name) end
		function value:FindFirstChild(name)
			local child = part:FindFirstChild(name)
			if name == "AlternateTriggers" and child then
				return {GetChildren = function()
					local result = {}
					for _, item in child:GetChildren() do table.insert(result, proxy(item)) end
					return result
				end}
			end
			return child
		end
		proxies[part] = value
		return value
	end
	local definitions = {}
	for index, definition in ordered do
		assert(definition.index == index)
		table.insert(definitions, {index = index, name = definition.name, part = proxy(definition.part)})
		table.insert(triggers, definition.part)
		local alternatives = definition.part:FindFirstChild("AlternateTriggers")
		if alternatives then for _, trigger in alternatives:GetChildren() do table.insert(triggers, trigger) end end
	end
	local facade = setmetatable({
		GetOrderedCheckpoints = function() return definitions end,
		GetStartPart = function() return proxy(course.Start) end,
		GetFinishPart = function() return proxy(course.Finish) end,
	}, {__index = CourseService})
	local CheckpointService = luau.load(sourceText.checkpointService, {environment = environment({
		game = game, require = loadModule, warn = function(message) table.insert(warnings, tostring(message)) end,
		workspace = {GetServerTimeNow = function() return state.now end},
	}), debugName = "CheckpointService"})()
	CheckpointService.Init({Services = {
		CourseService = facade,
		RaceService = {IsRaceActive = function() return state.active end, GetCurrentRaceId = function() return state.raceId end, GetElapsedRaceTime = function() return state.now end},
		PlayerRaceService = {IsOfficialRacer = function() return state.official end, GetPlayerStatus = function() return state.status end, SetPlayerStatus = function(_, nextStatus) state.status = nextStatus end},
		ResultsService = {
			UpdateCheckpointProgress = function() end,
			RecordCheckpointSplit = function(_, index, name, lap) table.insert(state.splits, {index = index, name = name, lap = lap}) end,
			RecordLapComplete = function(_, lap) table.insert(state.laps, lap) end,
			RecordFinish = function() table.insert(state.finishes, true); return {} end,
		},
	}})
	CheckpointService.Start()
	assert(#warnings == 0, table.concat(warnings, "; "))
	local body = {FindFirstAncestorWhichIsA = function(_, name) assert(name == "Model"); return character end}
	local result = {course = course, state = state}
	function result:newRace()
		state.serial += 1
		state.raceId, state.active, state.official, state.status = "expert-probe-" .. state.serial, true, true, "Racing"
		state.splits, state.laps, state.finishes = {}, {}, {}
		character.attributes.RecoveryUntil = nil
		assert(CheckpointService.GetLatestCheckpointIndex(player) == 0)
	end
	function result:latest() return CheckpointService.GetLatestCheckpointIndex(player) end
	function result:at(point)
		root.Position, state.now = point, state.now + .1
		local hits = 0
		for _, trigger in triggers do
			if trigger.CanTouch and contains(trigger, point) then proxy(trigger).Touched:Fire(body); hits += 1 end
		end
		return hits
	end
	function result:primary(index)
		local target = primary(course, index)
		assert(self:at(target:GetAttribute("RespawnCFrame").Position) >= 1, "Normal bank does not reach its trigger")
	end
	function result:expert(id)
		for index = 1, routeDefinitions[id].count do self:at(rootOnContact(contact(course, id, index))) end
	end
	function result:oneAlias(id, index)
		local trigger, support = alias(course, id, index), contact(course, id, index)
		root.Position, state.now = rootOnContact(support), state.now + .1
		assert(contains(trigger, root.Position), "Independent alias touch is outside the actual pad")
		proxy(trigger).Touched:Fire(body)
	end
	function result:finish()
		for _, z in {1, -1} do
			root.Position = course.Finish.CFrame:PointToWorldSpace(roblox.Vector3.new(0, 0, z))
			state.now += .1
			heartbeat:Fire(.1)
		end
	end
	function result:respawn() return CheckpointService.GetCheckpointRespawnCFrame(player) end
	return result
end
local baseline, fixed = runner(original), runner(repaired)
baseline:newRace()
baseline:expert("X03")
assert(baseline:latest() == 0 and #baseline.state.splits == 0, "Baseline did not reproduce the skipped first checkpoint")
baseline:newRace()
for index = 1, 4 do baseline:primary(index) end
baseline:expert("X02")
assert(baseline:latest() == 4 and #baseline.state.splits == 4, "Baseline did not reproduce the skipped fifth checkpoint")
local regressions = {X03 = {expected = 1, baselineLatest = 0}, X02 = {expected = 5, baselineLatest = 4}}

local originalBanks = {}
for _, item in fixed.course:GetDescendants() do
	if item:IsA("BasePart") and item.Anchored and item.CanCollide and item:GetAttribute("Role") == "SafeRefuge" then
		local id = item:GetAttribute("RecoveryGate")
		if id == "R1" or id == "R3" then
			local checkpoint = primary(fixed.course, if id == "R1" then 1 else 5)
			if (item.CFrame.Position + roblox.Vector3.new(0, 3.5, 0) - checkpoint.CFrame.Position).Magnitude < .001 then originalBanks[id] = item end
		end
	end
end
assert(originalBanks.R1 and originalBanks.R3, "Recovery must refer to real permanent collidable banks")
local independent = {}
for id, definition in routeDefinitions do
	for index = 1, definition.count do
		fixed:newRace()
		for prior = 1, definition.index - 1 do fixed:primary(prior) end
		fixed:oneAlias(id, index)
		assert(fixed:latest() == definition.index and #fixed.state.splits == definition.index, "Alias failed its shared ordinal: " .. id .. ":" .. index)
		local spawn = assert(fixed:respawn())
		local bank = originalBanks[definition.recovery]
		local localPoint = bank.CFrame:PointToObjectSpace(spawn.Position)
		assert(math.abs(localPoint.X) <= bank.Size.X / 2 - 1.49 and math.abs(localPoint.Z) <= bank.Size.Z / 2 - 1.49 and localPoint.Y > 2 and localPoint.Y < 8, "Alias recovery is not on its permanent bank")
		for _, blocked in {"Countdown", "Spectating"} do
			fixed:newRace()
			for prior = 1, definition.index - 1 do fixed:primary(prior) end
			if blocked == "Countdown" then fixed.state.active = false else fixed.state.status = "Spectating" end
			fixed:oneAlias(id, index)
			assert(fixed:latest() == definition.index - 1 and #fixed.state.splits == definition.index - 1, blocked .. " alias counted")
			fixed.state.active, fixed.state.status = true, "Racing"
			fixed:oneAlias(id, index)
			assert(fixed:latest() == definition.index and #fixed.state.splits == definition.index)
		end
		table.insert(independent, {route = id, landing = index, acceptedOrdinal = definition.index, countdownBlocked = true, spectatorBlocked = true, safeBank = definition.recovery, recoveryLocalPosition = tostring(localPoint)})
	end
end
assert(#independent == 25)

fixed:newRace()
fixed:primary(2)
fixed:expert("X02")
assert(fixed:latest() == 0 and #fixed.state.splits == 0, "Later checkpoint advanced before the first")
fixed:expert("X03")
assert(fixed:latest() == 1 and #fixed.state.splits == 1)
fixed:primary(1)
fixed:expert("X03")
assert(fixed:latest() == 1 and #fixed.state.splits == 1, "Primary and aliases double-counted the first ordinal")
for index = 2, 4 do fixed:primary(index) end
fixed:primary(6)
assert(fixed:latest() == 4 and #fixed.state.splits == 4, "Later checkpoint advanced before shortcut checkpoint five")
fixed:expert("X02")
fixed:primary(5)
fixed:expert("X02")
assert(fixed:latest() == 5 and #fixed.state.splits == 5, "Primary and aliases double-counted the fifth ordinal")
fixed:primary(7)
assert(fixed:latest() == 5 and #fixed.state.splits == 5, "Checkpoint seven skipped checkpoint six")
fixed.state.official = false
fixed:primary(6)
assert(fixed:latest() == 5, "Unofficial racer advanced")
fixed.state.official = true
fixed:primary(6)
assert(fixed:latest() == 6)

local runs = {}
for _, plan in {
	{name = "Normal", laps = {{false, false}, {false, false}}},
	{name = "Expert", laps = {{true, true}, {true, true}}},
	{name = "Mixed", laps = {{true, false}, {false, true}}},
} do
	fixed:newRace()
	for lap, choices in plan.laps do
		if choices[1] then fixed:expert("X03") else fixed:primary(1) end
		assert(fixed:latest() == 1)
		for index = 2, 4 do fixed:primary(index) end
		if choices[2] then fixed:expert("X02") else fixed:primary(5) end
		assert(fixed:latest() == 5)
		for index = 6, 8 do fixed:primary(index) end
		assert(fixed:latest() == 8 and #fixed.state.splits == lap * 8)
		fixed:finish()
		assert(#fixed.state.laps == lap and #fixed.state.finishes == if lap == 2 then 1 else 0)
		if lap == 1 then assert(fixed:latest() == 0) end
	end
	assert(#fixed.state.splits == 16 and fixed.state.status == "Finished")
	for sequence, split in fixed.state.splits do
		assert(split.index == (sequence - 1) % 8 + 1 and split.lap == math.ceil(sequence / 8))
	end
	fixed:finish()
	assert(#fixed.state.finishes == 1 and #fixed.state.laps == 2 and #fixed.state.splits == 16, "Finished run counted again")
	table.insert(runs, {path = plan.name, laps = #fixed.state.laps, finishRecords = #fixed.state.finishes, checkpointSplits = #fixed.state.splits, finalStatus = fixed.state.status})
end
preserved()
assert(fs.readFile(checkpointPath) == sourceText.checkpointService and fs.readFile(courseServicePath) == sourceText.courseService, "Shared production service source changed during the probe")
assert(fs.readFile(baselinePath) == baselineBytes, "Native baseline file changed")
local hashes = {nativeBaseline = serde.hash("sha256", baselineBytes), repair = serde.hash("sha256", sourceText.repair), checkpointService = serde.hash("sha256", sourceText.checkpointService), courseService = serde.hash("sha256", sourceText.courseService)}
local report = {
	passed = true, baselinePath = baselinePath, sourceHashes = hashes,
	baselineRegressions = regressions,
	preservation = {originalParts = partCount, originalCheckpoints = checkpointCount, originalInstances = #originals, originalSources = sourceHashes, originalPropertiesAndAttributesUnchanged = true, addedParts = aliases, addedFolders = folders, unchangedSharedRevision = repaired:GetAttribute("SharedCourseRevision"), exactIdempotency = true},
	footprintSamples = footprintSamples, footprintToleranceStuds = .001, actualPrecisionSupports = geometry, independentlyTestedAliases = independent,
	runs = runs, checkpointOrderEnforced = true, primaryAliasDuplicatesBlocked = true, unofficialRacerBlocked = true,
	boundary = "Actual current M05 native baseline and M06 repair module were executed offline in Lune. Actual unchanged CourseService and CheckpointService handled mocked player/body/touch/heartbeat signals. Pad footprint samples use original collidable KeyContact geometry. These are geometry and service-rule regressions, not Roblox physics, jumping ability, human readability, multiplayer or live Play proof.",
}
fs.writeFile(prefix .. "P3-M06-checkpoint-probe-01.json", serde.encode("json", report, true))
print(serde.encode("json", {passed = report.passed, originalParts = partCount, originalSources = (function() local count = 0; for _ in sourceHashes do count += 1 end; return count end)(), aliases = aliases, aliasFolders = folders, independentlyTestedAliases = #independent, footprintSamples = footprintSamples, runs = runs, baselineRegressions = regressions, sourceHashes = hashes, receipt = prefix .. "P3-M06-checkpoint-probe-01.json", boundary = report.boundary}))
