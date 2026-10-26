local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local prefix = "tools/keyboard-circuit/phase3/work-m05/"
local compiled = 0
for _, file in {"StandardCourse.luau", "CourseRuntime.server.luau", "MechanismRuntime.luau"} do
	luau.load(fs.readFile(prefix .. "sources/" .. file), {debugName = file})
	compiled += 1
end
local function environment(extra)
	local result = {print = function() end, warn = function() end}
	for key, value in roblox do result[key] = value end
	for key, value in extra or {} do result[key] = value end
	return result
end
local adapter = luau.load(fs.readFile(prefix .. "sources/StandardCourse.luau"), {environment = environment(), debugName = "StandardCourse"})()
local original = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase3/KC_P3_M04_01_Native.rbxm"))[1]
local originalCount = #original:GetDescendants()
local course = original:Clone()
local preserved = {}
for _, item in course:GetDescendants() do
	if item:IsA("BasePart") then preserved[item] = {frame = item.CFrame, size = item.Size, collidable = item.CanCollide} end
end
local recoveryPoses = {}
for _, id in {"F00", "R1", "CP1", "R2", "CP2", "R3", "CP3", "R4"} do recoveryPoses[id] = course.RecoveryPads[id].BankContact:GetAttribute("SpawnCFrame") end
local finalRecovery = course.RecoveryPads:FindFirstChild("F01")
if finalRecovery then
	recoveryPoses.F01 = finalRecovery.BankContact:GetAttribute("SpawnCFrame")
else
	local heading = course.Gates.F01.CFrame.LookVector
	local position = course.CheckpointBays.F01:GetAttribute("TopPosition") - heading * 8 + roblox.Vector3.new(0, 3.3, 0)
	recoveryPoses.F01 = roblox.CFrame.lookAt(position, position + heading)
end
adapter.Apply(course)
assert(#original:GetDescendants() == originalCount and not original:FindFirstChild("CourseInfo"), "Frozen original changed")
for part, before in preserved do
	assert(part:IsDescendantOf(course) and part.CFrame == before.frame and part.Size == before.size and part.CanCollide == before.collidable, "Original geometry changed: " .. part.Name)
end
local adaptedCount = #course:GetDescendants()
assert(adapter.Apply(course) == course and #course:GetDescendants() == adaptedCount, "Adapter must be idempotent")
assert(course.SourceSnapshot and course.Obstacles.Districts and course.Decoration.MapEnvironment and course.RouteMarkers.Gates)
assert(course.Start.Spawn.CFrame == recoveryPoses.F00 and course.Finish.CFrame == course.RouteMarkers.Gates.F00.CFrame)
assert(course.Finish:GetAttribute("RequireForwardCrossing") and course.CourseInfo:GetAttribute("LapCount") == 2)
local lethal, mechanisms = 0, 0
for _, item in course:GetDescendants() do
	if item:GetAttribute("MechanismId") then mechanisms += 1 end
	if item:IsA("BasePart") and item:GetAttribute("Role") == "Lethal" then
		lethal += 1
		assert(item:GetAttribute("HazardType") == "Kill" and item.CanTouch and item.CanQuery)
	end
	if item:IsA("BaseScript") then assert(item.Disabled, "Prototype script can still start") end
end
assert(mechanisms == 8 and lethal == 17)
local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			local entry = {callback = callback, active = true}
			table.insert(callbacks, entry)
			return {Disconnect = function() entry.active = false end}
		end,
		Fire = function(_, ...) for _, entry in table.clone(callbacks) do if entry.active then entry.callback(...) end end end,
	}
end
local workspace = roblox.Instance.new("Folder")
workspace.Name = "Workspace"
course.Name, course.Parent = "RaceCourse", workspace
local storage, replicated = roblox.Instance.new("Folder"), roblox.Instance.new("Folder")
local modulePaths = {}
for _, folderName in {"Config", "Shared"} do
	local root = roblox.Instance.new("Folder")
	root.Name, root.Parent = folderName, replicated
	for _, name in if folderName == "Config" then {"CourseConfig", "CheckpointConfig"} else {"RaceConstants", "RaceTypes", "ForwardGate"} do
		local module = roblox.Instance.new("ModuleScript")
		module.Name, module.Parent = name, root
		modulePaths[module] = "src/ReplicatedStorage/" .. folderName .. "/" .. name .. ".luau"
	end
end
local cache = {}
local loadModule
loadModule = function(module)
	if cache[module] then return cache[module] end
	cache[module] = luau.load(fs.readFile(modulePaths[module]), {environment = environment({script = module, require = loadModule}), debugName = module.Name})()
	return cache[module]
end
local heartbeat = signal()
local run = {IsStudio = function() return false end, Heartbeat = heartbeat}
local now, active, official, status, raceId = 0, false, true, "Racing", "probe-race-1"
local character = {attributes = {}}
local root = {Position = roblox.Vector3.zero, IsA = function(_, name) return name == "BasePart" end}
local humanoid = {Health = 100}
function character:FindFirstChild(name) return if name == "HumanoidRootPart" then root else nil end
function character:FindFirstChildOfClass(name) return if name == "Humanoid" then humanoid else nil end
function character:GetAttribute(name) return self.attributes[name] end
local player = {Name = "ProbeRacer", UserId = 1, Character = character}
local players = {PlayerRemoving = signal(), GetPlayers = function() return {player} end, GetPlayerFromCharacter = function(_, candidate) return if candidate == character then player else nil end}
local game = {GetService = function(_, name) return ({ReplicatedStorage = replicated, ServerStorage = storage, Workspace = workspace, RunService = run, Players = players})[name] end}
local globals = environment({game = game, require = loadModule})
local CourseService = luau.load(fs.readFile("src/ServerScriptService/Services/CourseService.luau"), {environment = globals, debugName = "CourseService"})()
local warnings = CourseService.ValidateCourseModel(course, true)
assert(#warnings == 0, serde.encode("json", warnings))
assert(CourseService.GetActiveCourseId() == "keyboard_circuit" and CourseService.GetRaceFormat() == "LapBased" and CourseService.GetLapCount() == 2)
assert(#CourseService.GetOrderedCheckpoints() == 8 and #CourseService.GetFallZones() == 5 and CourseService.GetMainFallZone() == course.FallZones.FallZone_Main)
local checkpoints = CourseService.GetOrderedCheckpoints()
local proxies = {}
local function proxy(part)
	if proxies[part] then return proxies[part] end
	local value = {Name = part.Name, CFrame = part.CFrame, Size = part.Size, Touched = signal()}
	function value:GetAttribute(name) return part:GetAttribute(name) end
	function value:FindFirstChild(name) return part:FindFirstChild(name) end
	proxies[part] = value
	return value
end
local definitions = {}
for index, definition in checkpoints do
	assert(definition.index == index)
	assert(definition.part:GetAttribute("RespawnCFrame") == recoveryPoses[adapter.CheckpointOrder[index]])
	table.insert(definitions, {index = index, name = definition.name, part = proxy(definition.part)})
end
local facade = setmetatable({GetOrderedCheckpoints = function() return definitions end, GetStartPart = function() return proxy(course.Start) end, GetFinishPart = function() return proxy(course.Finish) end}, {__index = CourseService})
local laps, finishes, splits = {}, {}, {}
local Results = {
	UpdateCheckpointProgress = function() end,
	RecordCheckpointSplit = function(_, index, _, lap) table.insert(splits, {index = index, lap = lap}) end,
	RecordLapComplete = function(_, lap) table.insert(laps, lap) end,
	RecordFinish = function() table.insert(finishes, true); return {} end,
}
local checkpointGlobals = environment({game = game, require = loadModule, workspace = {GetServerTimeNow = function() return now end}})
local CheckpointService = luau.load(fs.readFile("src/ServerScriptService/Services/CheckpointService.luau"), {environment = checkpointGlobals, debugName = "CheckpointService"})()
CheckpointService.Init({Services = {
	CourseService = facade,
	RaceService = {IsRaceActive = function() return active end, GetCurrentRaceId = function() return raceId end, GetElapsedRaceTime = function() return now end},
	PlayerRaceService = {IsOfficialRacer = function() return official end, GetPlayerStatus = function() return status end, SetPlayerStatus = function(_, value) status = value end},
	ResultsService = Results,
}})
CheckpointService.Start()
local body = {FindFirstAncestorWhichIsA = function() return character end}
local function touch(index) definitions[index].part.Touched:Fire(body) end
local function sample(position) root.Position = position; now += .1; heartbeat:Fire(.1) end
local function cross(gate, forward, distance)
	distance = distance or 1
	sample(gate.CFrame:PointToWorldSpace(roblox.Vector3.new(0, 0, if forward then distance else -distance)))
	sample(gate.CFrame:PointToWorldSpace(roblox.Vector3.new(0, 0, if forward then -distance else distance)))
end
touch(1); assert(CheckpointService.GetLatestCheckpointIndex(player) == 0, "Countdown touch counted")
active, official = true, false
touch(1); assert(CheckpointService.GetLatestCheckpointIndex(player) == 0, "Unofficial touch counted")
official, status = true, "Spectating"
touch(1); assert(CheckpointService.GetLatestCheckpointIndex(player) == 0, "Spectator touch counted")
status = "Racing"
touch(2); assert(CheckpointService.GetLatestCheckpointIndex(player) == 0, "Checkpoint skip counted")
cross(course.Finish, true); assert(#laps == 0, "Finish before checkpoints counted")
for index = 1, 7 do touch(index) end
assert(CheckpointService.GetLatestCheckpointIndex(player) == 7 and #splits == 7)
cross(course.Finish, true); assert(#laps == 0, "R4 bypassed the final encounters and lap-return bank")
touch(8)
assert(CheckpointService.GetLatestCheckpointIndex(player) == 8 and #splits == 8)
cross(course.RouteMarkers.Gates.F01, true); assert(#laps == 0, "F01 closed the lap before the return")
cross(course.Finish, false); assert(#laps == 0, "Backward finish counted")
cross(course.Finish, true, 20); assert(#laps == 0, "Large finish teleport counted")
cross(course.Finish, true); assert(#laps == 1 and #finishes == 0 and CheckpointService.GetLatestCheckpointIndex(player) == 0)
for index = 1, 8 do touch(index) end
character.attributes.RecoveryUntil = now + 1
cross(course.Finish, true); assert(#laps == 1, "Recovery teleport counted as finish")
character.attributes.RecoveryUntil = nil
cross(course.Finish, true)
assert(#laps == 2 and #finishes == 1 and #splits == 16 and status == "Finished")
cross(course.Finish, true); assert(#finishes == 1, "Repeated finish counted")
raceId, status = "probe-race-2", "Racing"
assert(CheckpointService.GetLatestCheckpointIndex(player) == 0)
touch(2); assert(CheckpointService.GetLatestCheckpointIndex(player) == 0)
touch(1); assert(CheckpointService.GetLatestCheckpointIndex(player) == 1)
players.PlayerRemoving:Fire(player)
assert(CheckpointService.GetLatestCheckpointIndex(player) == 0)

local runtimeHeartbeat, starts, stops, recoveries = signal(), 0, 0, 0
local inWorkspace, selected, raceActive, mechanismActive = true, true, false, true
local runtimeCourse = {attributes = {SharedCourseEnabled = true}, Destroying = signal(), AncestryChanged = signal()}
function runtimeCourse:IsA(name) return name == "Model" end
function runtimeCourse:IsDescendantOf() return inWorkspace end
function runtimeCourse:GetAttribute(name) return self.attributes[name] end
function runtimeCourse:SetAttribute(name, value) self.attributes[name] = value end
function runtimeCourse:WaitForChild(name)
	assert(name == "SourceSnapshot")
	return {WaitForChild = function(_, module) assert(module == "MechanismRuntime"); return "MechanismRuntime" end}
end
local currentEligible, currentRecover
local runtimeServices = {
	CourseService = {GetActiveCourse = function() return if selected then runtimeCourse else nil end},
	RaceService = {IsRaceActive = function() return raceActive end, GetCurrentRaceId = function() return raceId end},
	PlayerRaceService = {IsOfficialRacer = function() return official end, GetPlayerStatus = function() return status end},
	RespawnService = {RecoverPlayer = function() recoveries += 1; return true end},
	MechanismRuntime = {Start = function(candidate, eligible, recover)
		assert(candidate == runtimeCourse)
		starts, mechanismActive, currentEligible, currentRecover = starts + 1, true, eligible, recover
		local stopped = false
		return {
			IsActive = function() return mechanismActive end,
			Diagnostics = function() return {failure = if mechanismActive then nil else "Fixture failure"} end,
			Stop = function() if not stopped then stopped = true; stops += 1 end end,
		}
	end},
}
local runtimeGame = {GetService = function(_, name)
	if name == "RunService" then return {IsServer = function() return true end, Heartbeat = runtimeHeartbeat} end
	if name == "ReplicatedStorage" then return replicated end
	if name == "ServerScriptService" then return {WaitForChild = function() return {WaitForChild = function(_, service) return service end} end} end
	error("Unexpected runtime service " .. name)
end}
local runtimeGlobals = environment({
	game = runtimeGame, script = {Parent = runtimeCourse}, workspace = {GetServerTimeNow = function() return now end},
	require = function(module) return if type(module) == "string" then assert(runtimeServices[module]) else loadModule(module) end,
})
luau.load(fs.readFile(prefix .. "sources/CourseRuntime.server.luau"), {environment = runtimeGlobals, debugName = "CourseRuntime"})()
runtimeHeartbeat:Fire(); assert(starts == 0, "Mechanisms started in Countdown")
raceActive, status, official = true, "Racing", true
runtimeHeartbeat:Fire(); runtimeHeartbeat:Fire()
assert(starts == 1 and runtimeCourse.attributes.KCCourseRuntimeActive and currentEligible(player))
status = "Spectating"; assert(not currentEligible(player) and not currentRecover(player, "Probe"))
status, official = "Racing", false; assert(not currentEligible(player))
official = true
character.attributes.RecoveryUntil = now + 1; assert(not currentEligible(player))
character.attributes.RecoveryUntil = nil
assert(currentRecover(player, "Probe") and recoveries == 1)
selected = false; runtimeHeartbeat:Fire(); assert(stops == 1 and not runtimeCourse.attributes.KCCourseRuntimeActive)
selected = true; runtimeHeartbeat:Fire(); assert(starts == 2)
mechanismActive = false
runtimeHeartbeat:Fire(); runtimeHeartbeat:Fire()
assert(starts == 2 and stops == 2 and runtimeCourse.attributes.KCCourseRuntimeFailure == "Fixture failure" and not runtimeCourse.attributes.KCCourseRuntimeActive)
raceActive = false; runtimeHeartbeat:Fire()
raceActive = true; runtimeHeartbeat:Fire(); assert(starts == 3)
raceId = "runtime-race-3"; runtimeHeartbeat:Fire(); assert(starts == 4 and stops == 3)
runtimeCourse.Destroying:Fire(); runtimeCourse.Destroying:Fire(); runtimeHeartbeat:Fire()
assert(starts == 4 and stops == 4 and not runtimeCourse.attributes.KCCourseRuntimeActive)
print(serde.encode("json", {passed = true, compiledSources = compiled, frozenDescendants = originalCount, preservedParts = (function() local n = 0; for _ in preserved do n += 1 end; return n end)(), checkpoints = 8, laps = #laps, finishRecords = #finishes, checkpointSplits = #splits, mechanisms = mechanisms, lethalParts = lethal, fallZones = 5, sharedCourseWarnings = #warnings, runtimeStarts = starts, runtimeStops = stops, limits = "Offline frozen-model geometry and actual shared service/runtime logic with signal/player mocks; no Roblox physics, sound, multiplayer, UI or device proof."}, true))
