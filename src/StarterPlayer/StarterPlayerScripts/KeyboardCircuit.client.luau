--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local RaceConfig = require(game:GetService("ReplicatedStorage").Config.RaceConfig)
local player = Players.LocalPlayer

type ClientRun = {
	course: Model,
	snapshot: Folder,
	character: Model,
	playerGui: PlayerGui,
	modules: {[string]: ModuleScript},
	archive: boolean,
	feedback: any,
	effects: any,
	effectsModule: any,
	effectsStarting: boolean,
	readinessConnection: RBXScriptConnection?,
}

local current: ClientRun? = nil
local scriptAlive = true
local unavailableCharacter: Model? = nil
local refreshing, refreshPending = false, false
local watches: {[Instance]: {RBXScriptConnection}} = {}
local characterConnections: {RBXScriptConnection} = {}
local generalConnections: {RBXScriptConnection} = {}
local general: Instance? = nil
local refresh: () -> ()

local function stopEffects(run: ClientRun)
	local effects = run.effects
	run.effects = nil
	if effects then pcall(effects.Stop) end
end

local function stop()
	local run = current
	current = nil
	if not run then return end
	if run.readinessConnection then run.readinessConnection:Disconnect() end
	stopEffects(run)
	if run.feedback then pcall(run.feedback.Stop) end
end

local function wantsEffects(run: ClientRun): boolean
	if not scriptAlive or current ~= run or not run.archive or not general
		or general.Parent ~= script.Parent or general:GetAttribute("KCArchiveYielded") ~= run.course.Name
		or run.course.Parent ~= Workspace or run.course.Name ~= "RaceCourse"
		or player.Character ~= run.character or player:GetAttribute("ArrivalOpen") == true then return false end
	local root = run.character:FindFirstChild("HumanoidRootPart")
	local humanoid = run.character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
	local function inside(model: Model): boolean
		local frame, size = model:GetBoundingBox()
		local point = frame:PointToObjectSpace(root.Position)
		local half = size / 2 + RaceConfig.LobbyAmbiencePadding
		return math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z
	end
	local lobby = Workspace:FindFirstChild(RaceConfig.LobbyModelName)
	return inside(run.course) and not (lobby and lobby:IsA("Model") and inside(lobby))
end

local function syncEffects(run: ClientRun)
	if not wantsEffects(run) then stopEffects(run); return end
	if run.effects or run.effectsStarting or not run.feedback then return end
	run.effectsStarting = true
	local ok, effects = pcall(run.effectsModule.Start, run.course, run.feedback)
	run.effectsStarting = false
	if not ok then
		warn("[KeyboardCircuit] Effects could not start: " .. tostring(effects))
		return
	end
	if not wantsEffects(run) then pcall(effects.Stop); return end
	run.effects = effects
	local ready, state = pcall(run.feedback.Readiness)
	if ready then effects.NotifyReady(state) end
end

local function findCourse(): Model?
	local found: Model? = nil
	for _, child in Workspace:GetChildren() do
		if child.Name ~= "RaceCourse" then continue end
		if found or not child:IsA("Model") then return nil end
		found = child
	end
	if not found or found:GetAttribute("CourseId") ~= "keyboard_circuit"
		or found:GetAttribute("SharedCourseEnabled") ~= true then return nil end
	local info = found:FindFirstChild("CourseInfo")
	return if info and info:GetAttribute("CourseId") == "keyboard_circuit" then found else nil
end

local function getModules(snapshot: Folder, archive: boolean): {[string]: ModuleScript}?
	local modules: {[string]: ModuleScript} = {}
	local names = {"KeyboardCircuitAudio", "KeyboardCircuitFeedback", "ConfigSnapshot"}
	if archive then table.insert(names, "ArchiveEffects"); table.insert(names, "ArchiveSkyConfig") end
	for _, name in names do
		local module = snapshot:FindFirstChild(name)
		if not module or not module:IsA("ModuleScript") then return nil end
		modules[name] = module
	end
	return modules
end

local function start(run: ClientRun)
	local Feedback = require(run.modules.KeyboardCircuitFeedback)
	run.effectsModule = if run.archive then require(run.modules.ArchiveEffects) else nil
	if not scriptAlive or current ~= run or findCourse() ~= run.course
		or run.snapshot.Parent ~= run.course or player.Character ~= run.character then return end
	local feedback = Feedback.Start(run.course)
	if current ~= run or findCourse() ~= run.course or player.Character ~= run.character
		or run.snapshot.Parent ~= run.course then pcall(feedback.Stop); return end
	run.feedback = feedback
	syncEffects(run)
	local elapsed = 0
	run.readinessConnection = RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if current ~= run or elapsed < .2 then return end
		elapsed = 0
		if not run.effects then return end
		local ready, state = pcall(feedback.Readiness)
		if ready then run.effects.NotifyReady(state) else stopEffects(run) end
	end)
end

local function refreshOnce()
	local course = findCourse()
	local character = player.Character
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or character == unavailableCharacter or not character.Parent or not playerGui
		or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then course = nil end
	local snapshot = if course then course:FindFirstChild("SourceSnapshot") else nil
	local archive = course ~= nil and course:GetAttribute("KCArchiveAmbience") == true
	local modules = if snapshot and snapshot:IsA("Folder") then getModules(snapshot, archive) else nil
	if not modules then course = nil end
	local run = current
	if course and run and run.course == course and run.snapshot == snapshot and run.character == character
		and run.playerGui == playerGui and run.archive == archive then
		local matching = true
		for name, module in modules :: {[string]: ModuleScript} do
			if run.modules[name] ~= module then matching = false; break end
		end
		if matching then syncEffects(run); return end
	end
	stop()
	if not course then return end
	run = {
		course = course, snapshot = snapshot :: Folder, character = character :: Model,
		playerGui = playerGui :: PlayerGui, modules = modules :: {[string]: ModuleScript},
		archive = archive, feedback = nil, effects = nil, effectsModule = nil,
		effectsStarting = false, readinessConnection = nil,
	}
	current = run
	local ok, problem = pcall(start, run)
	if not ok then
		if current == run then stop() end
		warn("[KeyboardCircuit] Feedback could not start: " .. tostring(problem))
	end
end

refresh = function()
	if not scriptAlive then return end
	refreshPending = true
	if refreshing then return end
	refreshing = true
	repeat
		refreshPending = false
		local ok, problem = pcall(refreshOnce)
		if not ok then stop(); warn("[KeyboardCircuit] Client refresh failed: " .. tostring(problem)) end
	until not refreshPending or not scriptAlive
	refreshing = false
end

local function watchCourse(child: Instance)
	if not child:IsA("Model") or watches[child] then return end
	local connections = {
		child:GetPropertyChangedSignal("Name"):Connect(refresh),
		child:GetAttributeChangedSignal("CourseId"):Connect(refresh),
		child:GetAttributeChangedSignal("SharedCourseEnabled"):Connect(refresh),
		child:GetAttributeChangedSignal("KCArchiveAmbience"):Connect(refresh),
	}
	local watchedInfo: Instance? = nil
	local infoConnection: RBXScriptConnection? = nil
	local function watchInfo()
		local info = child:FindFirstChild("CourseInfo")
		if info == watchedInfo then return end
		if infoConnection then infoConnection:Disconnect() end
		watchedInfo = info
		infoConnection = if info then info:GetAttributeChangedSignal("CourseId"):Connect(refresh) else nil
		if infoConnection then table.insert(connections, infoConnection) end
	end
	table.insert(connections, child.DescendantAdded:Connect(function(item)
		if item.Name == "CourseInfo" then watchInfo(); refresh()
		elseif item.Name == "SourceSnapshot" or item:IsA("ModuleScript") then refresh() end
	end))
	table.insert(connections, child.DescendantRemoving:Connect(function(item)
		if current and current.course == child and (item.Name == "CourseInfo" or item == current.snapshot or item:IsA("ModuleScript")) then
			stop()
			task.defer(refresh)
		end
	end))
	watches[child] = connections
	watchInfo()
end

local function watchCharacter(character: Model?)
	for _, connection in characterConnections do connection:Disconnect() end
	table.clear(characterConnections)
	if not character then return end
	local deathConnection: RBXScriptConnection? = nil
	local function watchHumanoid()
		if deathConnection then deathConnection:Disconnect() end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		deathConnection = if humanoid then humanoid.Died:Connect(refresh) else nil
		if deathConnection then table.insert(characterConnections, deathConnection) end
	end
	table.insert(characterConnections, character.ChildAdded:Connect(function(child)
		if child:IsA("Humanoid") then watchHumanoid() end
		if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then refresh() end
	end))
	table.insert(characterConnections, character.ChildRemoved:Connect(function(child)
		if child:IsA("Humanoid") then watchHumanoid() end
		if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then refresh() end
	end))
	table.insert(characterConnections, character.Destroying:Connect(function()
		unavailableCharacter = character
		stop()
	end))
	watchHumanoid()
end

local function watchGeneral()
	for _, connection in generalConnections do connection:Disconnect() end
	table.clear(generalConnections)
	general = script.Parent:FindFirstChild("ClassicAscentAmbience")
	if general then table.insert(generalConnections, general:GetAttributeChangedSignal("KCArchiveYielded"):Connect(refresh)) end
	refresh()
end

local connections = {
	Workspace.ChildAdded:Connect(function(child)
		watchCourse(child)
		if child.Name == "RaceCourse" then refresh() end
	end),
	Workspace.ChildRemoved:Connect(function(child)
		local watched = watches[child]
		if watched then for _, connection in watched do connection:Disconnect() end; watches[child] = nil end
		if child.Name == "RaceCourse" then refresh() end
	end),
	player.CharacterRemoving:Connect(function(character)
		unavailableCharacter = character
		watchCharacter(nil)
		stop()
	end),
	player.CharacterAdded:Connect(function(character)
		unavailableCharacter = nil
		watchCharacter(character)
		refresh()
	end),
	player.ChildAdded:Connect(function(child) if child:IsA("PlayerGui") then refresh() end end),
	player.ChildRemoved:Connect(function(child) if child:IsA("PlayerGui") then refresh() end end),
	player:GetAttributeChangedSignal("ArrivalOpen"):Connect(refresh),
	script.Parent.ChildAdded:Connect(function(child) if child.Name == "ClassicAscentAmbience" then watchGeneral() end end),
	script.Parent.ChildRemoved:Connect(function(child) if child == general then watchGeneral() end end),
}
script.Destroying:Connect(function()
	scriptAlive = false
	stop()
	for _, connection in connections do connection:Disconnect() end
	for _, watched in watches do for _, connection in watched do connection:Disconnect() end end
	for _, connection in characterConnections do connection:Disconnect() end
	for _, connection in generalConnections do connection:Disconnect() end
end)
for _, child in Workspace:GetChildren() do watchCourse(child) end
watchCharacter(player.Character)
watchGeneral()
