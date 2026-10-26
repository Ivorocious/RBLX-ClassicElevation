local fs, luau, roblox = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local checks = 0
local function check(value, message)
	checks += 1
	assert(value, message)
end
local environment = {}
for name, value in roblox do environment[name] = value end
local nativeCFrame = table.clone(roblox.CFrame)
-- Bundled Lune lookAt reverses target Z; use Roblox's forward/right/up basis.
function nativeCFrame.lookAt(origin, target, up)
	local look = (target-origin).Unit
	local right = look:Cross(up or roblox.Vector3.yAxis).Unit
	return roblox.CFrame.fromMatrix(origin, right, right:Cross(look), -look)
end
environment.CFrame = nativeCFrame
local lookDirection = roblox.Vector3.new(-57, 0, -36).Unit
check((nativeCFrame.lookAt(roblox.Vector3.zero, lookDirection).LookVector-lookDirection).Magnitude < 1e-6, "native lookAt direction")
local authoring = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/Authoring.luau"), { environment = environment })()
local course = authoring.Build()
local mechanismCounts, warnings, mechanismByPart = {}, {}, {}
local function minimum(instance, name, bound)
	local value = instance:GetAttribute(name)
	check(typeof(value) == "number" and value == value and value >= bound and value < math.huge,
		instance.Name .. " invalid " .. name)
end
check(course:GetAttribute("EROwned") == true and course:GetAttribute("CourseId") == "egg_rush_circuit", "owned course identity")
check(course.CourseInfo:GetAttribute("RaceFormat") == "LapBased" and course.CourseInfo:GetAttribute("LapCount") == 3, "three-lap service metadata")
check(#course.Checkpoints:GetChildren() == 4, "exactly four ordered checkpoints")
for i = 1, 4 do
	local checkpoint = course.Checkpoints:FindFirstChild(string.format("Checkpoint_%03d", i))
	check(checkpoint and checkpoint:IsA("BasePart") and checkpoint.CanTouch, "checkpoint trigger " .. i)
	check(typeof(checkpoint:GetAttribute("RespawnCFrame")) == "CFrame", "checkpoint recovery " .. i)
end
for _, model in course:GetDescendants() do
	local kind = model:GetAttribute("ERMechanism")
	if kind == nil then continue end
	check(model:IsA("Model"), "mechanism model")
	mechanismCounts[kind] = (mechanismCounts[kind] or 0) + 1
	minimum(model, "WarningSeconds", .8)
	minimum(model, "MoveSeconds", .5)
	local warningRef = model:FindFirstChild("Warning")
	check(warningRef and warningRef:IsA("ObjectValue"), "fixed warning reference " .. model.Name)
	local warning = warningRef.Value
	check(warning and warning:IsA("BasePart") and warning:IsDescendantOf(course)
		and not warning:IsDescendantOf(model) and warning.Transparency < 1, "visible fixed warning " .. model.Name)
	check(not warnings[warning], "independent warning per mechanism")
	warnings[warning] = true
	local supports, contacts = 0, 0
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		mechanismByPart[part] = model
		check(part.Anchored, "server-controlled anchored mechanism")
		if part:GetAttribute("ERSupport") == true then
			supports += 1
			check(part.CanCollide and part.CanQuery, "queryable physical support")
		end
		if part:GetAttribute("ERLethal") == true then
			contacts += 1
			check(part.CanQuery and not part.CanCollide and part.Transparency < 1, "visible non-flinging moving contact")
		end
		if kind == "ShellLip" or kind == "Tray" then
			check(not part.CanCollide or part:GetAttribute("ERSupport") == true, "all moving collision has support velocity")
		else
			check(not part.CanCollide, "egg/tail cannot fling")
		end
	end
	if kind == "ShellLip" then
		check(supports > 0 and contacts == 0, "playable nonlethal shell lip")
		minimum(model, "ClosedSeconds", .1); minimum(model, "OpenSeconds", .5)
		minimum(model, "ClosedAngleDegrees", 1); minimum(model, "ClosingWarningSeconds", .8)
	elseif kind == "Tray" then
		check(supports > 0 and contacts == 0, "playable nonlethal tray")
		minimum(model, "BoardSeconds", .5); minimum(model, "ExitSeconds", .5)
		minimum(model, "ClosingWarningSeconds", .8)
	elseif kind == "EggRoller" then
		check(contacts > 0 and supports == 0, "visible moving egg contact")
		minimum(model, "RestSeconds", .5); minimum(model, "RollTurns", 0)
		check(model:GetAttribute("RollTurns") <= 8, "bounded egg roll")
		check(warning:FindFirstChild("WarningSound") and warning.WarningSound.SoundId ~= "", "authored audible egg cue")
	elseif kind == "Tail" then
		check(contacts > 0 and supports == 0, "visible moving tail contact")
		minimum(model, "RestSeconds", .5); minimum(model, "FarWaitSeconds", .5)
		minimum(model, "SweepAngleDegrees", 1); minimum(model, "ClosingWarningSeconds", .8)
	else
		error("unsupported authored mechanism " .. tostring(kind))
	end
	if kind == "Tray" or kind == "EggRoller" then
		local travel = model:GetAttribute("Travel")
		check(typeof(travel) == "Vector3" and travel.Magnitude > 0 and travel.Magnitude <= 200, "bounded local travel")
		if kind == "Tray" then check(math.abs(travel.Y) < .001, "level sideways tray") end
	end
	if kind ~= "Tray" then
		local axis = model:GetAttribute("RotationAxis")
		check(typeof(axis) == "Vector3" and math.abs(axis.Magnitude - 1) < .001, "unit local hinge/rolling axis")
	end
end
check(mechanismCounts.EggRoller == 2 and mechanismCounts.ShellLip == 9
	and mechanismCounts.Tray == 1 and mechanismCounts.Tail == 1, "all required encounters retained")
check(course.Routes:FindFirstChild("E3_MovingCrown") and #course.Routes.E3_MovingCrown:GetChildren() == 5, "five dedicated Expert moving lips")
for _, branch in {"E1_RimSprint", "E2_ChuteCut", "E3_CrownApproach", "E4_RoostCut"} do
	check(course.Routes:FindFirstChild(branch) ~= nil, "branch retained " .. branch)
end
check(course:GetAttribute("CandidateId") == "ER_P2_C15_JUMPS", "jump-spacing candidate identity")
check(#course.Routes.S4_IncubatorApproach:GetChildren() == 6, "existing six-pad Incubator approach retained")
local transfer = course.Obstacles.Mechanisms.SidewaysTray
check(transfer.TrayContact.Size == roblox.Vector3.new(12,1,18), "wide tray with 18-stud side exit edge")
check(course.Obstacles.Tray_BoardPocket.Size == roblox.Vector3.new(24,2,8), "wide shared boarding wait")
check(course.Obstacles.Tray_ReceivePocket.Size == roblox.Vector3.new(18,2,10), "wide sideways receiving wait")
check(transfer:GetAttribute("Travel") == roblox.Vector3.new(0,0,21), "unchanged full tray travel")
check(transfer:GetAttribute("BoardSeconds")+transfer:GetAttribute("WarningSeconds")+2*transfer:GetAttribute("MoveSeconds")
	+transfer:GetAttribute("ExitSeconds")+transfer:GetAttribute("ClosingWarningSeconds") == 12.5, "unchanged shared tray cycle")
local approachB = course.Routes.S4_TrayApproachB
check(#approachB:GetChildren() == 3 and approachB:GetAttribute("FromPad") == "S4_IncubatorApproach_005"
	and approachB:GetAttribute("ToPad") == "Tray_BoardPocket", "three distinct alternate landings after shared red hop")
for _, ref in approachB:GetChildren() do
	check(ref.Value.Parent == course.Obstacles.S4_TrayApproachB and ref.Value.Size == roblox.Vector3.new(8,2,4), "alternate ordinary landing dimensions")
end
check(course.Obstacles.Incubator_RedHop:GetAttribute("ERPadName") == "S4_IncubatorApproach_004"
	and course.Obstacles.Incubator_RedHop:GetAttribute("ERNextPadName") == "S4_IncubatorApproach_005", "both approaches follow original red gap")
local traversalEnvironment = table.clone(environment)
traversalEnvironment.game = {GetService=function() return {} end}
local traversal = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/NativeTraversal.luau"), {environment=traversalEnvironment})()
local mainPoints = traversal.Points(course,"Normal","Incubator")
local alternatePoints = traversal.Points(course,"Normal","IncubatorAlternate")
check(#alternatePoints == #mainPoints+2, "alternate replaces final main approach pad with three landings")
for i=1,6 do check(mainPoints[i].part == alternatePoints[i].part, "shared red-hop prefix "..i) end
for i=1,3 do check(alternatePoints[i+6].part == approachB[string.format("%03d",i)].Value, "alternate ordered landing "..i) end
for i=8,#mainPoints do check(mainPoints[i].part == alternatePoints[i+2].part, "unchanged shared tray and exit suffix "..i) end
check(alternatePoints[11].waitKind == "Tray" and alternatePoints[12].waitKind == "SideExit", "alternate retains actual carry and sideways exit guards")
local staticRed = 0
for _, part in course:GetDescendants() do
	if part:IsA("BasePart") and part:GetAttribute("ERLethal") == true and not mechanismByPart[part] then
		staticRed += 1
		check(part.Transparency < 1 and part.CanQuery and part.Material == roblox.Enum.Material.Neon, "visible neon-red fixed hazard")
	end
end
check(staticRed == 4, "four intended fixed red hazard groups")

local gate = luau.load(fs.readFile("src/ReplicatedStorage/Shared/ForwardGate.luau"), { environment = environment })()
local frame, size = course.Finish.CFrame, course.Finish.Size
check(course.Finish:GetAttribute("RequireForwardCrossing") == true, "forward-only lap gate")
check(gate.Crossed(frame, size, frame * roblox.Vector3.new(0, 0, 1), frame * roblox.Vector3.new(0, 0, -1), .1), "authored forward gate crossing")
check(not gate.Crossed(frame, size, frame * roblox.Vector3.new(0, 0, -1), frame * roblox.Vector3.new(0, 0, 1), .1), "reverse gate crossing rejected")
check(not gate.Crossed(frame, size, frame * roblox.Vector3.new(0, 0, 30), frame * roblox.Vector3.new(0, 0, -1), .1), "teleport gate crossing rejected")

local runtime = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/Runtime.luau"), {
	environment = { game = { GetService = function() return {} end } },
})()
local settings = {closed=2, warning=1, move=2, open=3, closingWarning=1, board=2, exit=3, rest=2, phase=0}
local expected = {
	ShellLip = {{0,"Closed",0},{2,"Warning",0},{3,"Opening",0},{4,"Opening",.5},{5,"Open",1},{8,"ClosingWarning",1},{9,"Closing",1},{10,"Closing",.5},{11,"Closed",0}},
	Tray = {{0,"Boarding",0},{2,"DepartureWarning",0},{3,"Travel",0},{5,"Exit",1},{8,"ReturnWarning",1},{9,"Returning",1},{11,"Boarding",0}},
	EggRoller = {{0,"Clear",0},{2,"Warning",0},{3,"Rolling",0},{4,"Rolling",.5},{5,"Clear",0}},
	Tail = {{0,"Rest",0},{2,"Warning",0},{3,"Sweeping",0},{5,"FarWait",1},{8,"ReturnWarning",1},{9,"Returning",1},{11,"Rest",0}},
}
for kind, samples in expected do
	for _, sample in samples do
		local alpha, state = runtime.Sample(kind, settings, sample[1])
		check(state == sample[2] and math.abs(alpha-sample[3]) < 1e-7, kind .. " timed pose at " .. sample[1])
	end
	settings.phase = 1.25
	local a, s = runtime.Sample(kind, settings, 3)
	settings.phase = 0
	local b, q = runtime.Sample(kind, settings, 4.25)
	check(math.abs(a-b) < 1e-7 and s == q, kind .. " common phase advance")
end

local callbacks = {}
local heartbeat = {}
function heartbeat:Connect(callback)
	local connection = { Connected = true, callback = callback }
	function connection:Disconnect() self.Connected = false end
	table.insert(callbacks, connection)
	return connection
end
local now = 0
local function tick()
	now += .05
	for _, connection in table.clone(callbacks) do
		if connection.Connected then connection.callback(.05) end
	end
end
local players, workspace = {}, { Gravity = 196.2 }
local roster = {}
function players:GetPlayers() return roster end
local server = true
local runService = { Heartbeat = heartbeat, IsServer = function() return server end }
local starts, stops, callbacksAtStart = 0, 0, {}
local failNext, selfStop, holds = false, false, 0
local runtimeToken, constantsToken = {}, {}
local mockRuntime = {}
function mockRuntime.Start(target, eligible, recover)
	starts += 1
	if failNext then failNext = false; error("Injected start failure") end
	table.insert(callbacksAtStart, {target=target, eligible=eligible, recover=recover})
	local stopped, holding = false, false
	return {
		Stop = function() if not stopped then stopped = true; stops += 1 end end,
		Hold = function() if not holding then holding = true; holds += 1 end end,
		Resume = function() holding = false end,
		Diagnostics = function() return {bound = not stopped and not selfStop, holding = holding} end,
	}
end
local game = {
	ServerStorage = {CourseBuilders = {EggRush = {Runtime = runtimeToken}}},
	ReplicatedStorage = {Shared = {RaceConstants = constantsToken}},
}
function game:GetService(name)
	return ({Players=players, RunService=runService, Workspace=workspace})[name]
end
local service = luau.load(fs.readFile("src/ServerScriptService/Services/EggRushService.luau"), {
	environment = {game=game, os={clock=function() return now end}, warn=function() end, require=function(token)
		if token == runtimeToken then return mockRuntime end
		assert(token == constantsToken)
		return {PlayerRaceStatus={Racing="Racing"}}
	end},
})()
local currentCourse, raceId, active = nil, "race-A", false
local official, statuses = {}, {}
local recover = function() return true end
local function mockCourse(id, owned, connected)
	return {
		connected=connected,
		GetAttribute=function(_, name) return ({CourseId=id, EROwned=owned})[name] end,
		IsDescendantOf=function(self, ancestor) return self.connected and ancestor == workspace end,
	}
end
local function character(speed, jumpHeight, jumpPower)
	local model, humanoid = {}, {WalkSpeed=speed, UseJumpPower=true, JumpHeight=jumpHeight, JumpPower=jumpPower, Health=100}
	humanoid.Parent = model
	function model:FindFirstChildOfClass(class) return if class == "Humanoid" then humanoid else nil end
	return model, humanoid
end
local racerCharacter, racerHumanoid = character(22, 5, 60)
local spectatorCharacter, spectatorHumanoid = character(19, 4, 58)
local racer = {Parent=players, Character=racerCharacter}
local spectator = {Parent=players, Character=spectatorCharacter}
local unofficial = {Parent=players, Character=spectatorCharacter}
roster = {racer, spectator, unofficial}
official[racer], official[spectator], official[unofficial] = true, true, false
statuses[racer], statuses[spectator], statuses[unofficial] = "Racing", "Spectating", "Racing"
local context = {Services={
	CourseService={GetActiveCourse=function() return currentCourse end},
	RaceService={IsRaceActive=function() return active end, GetCurrentRaceId=function() return raceId end},
	PlayerRaceService={IsOfficialRacer=function(player) return official[player] end, GetPlayerStatus=function(player) return statuses[player] end},
	RespawnService={RecoverPlayer=recover},
}}
service.Init(context)
service.Start(); service.Start()
check(#callbacks == 1, "idempotent service Start")
tick()
check(starts == 0, "idle service does not start runtime")
active = true
currentCourse = mockCourse("stud_garden_v2", true, true); tick()
check(starts == 0, "other course ignored")
currentCourse = mockCourse("egg_rush_circuit", false, true); tick()
check(starts == 0, "unowned model ignored")
currentCourse = mockCourse("egg_rush_circuit", true, false); tick()
check(starts == 0, "stored model ignored")
currentCourse.connected = true; tick()
check(starts == 1 and stops == 0, "owned active course bound once")
check(racerHumanoid.WalkSpeed == 16 and not racerHumanoid.UseJumpPower and racerHumanoid.JumpHeight == 7.2, "participant movement applied")
check(spectatorHumanoid.WalkSpeed == 19 and spectatorHumanoid.UseJumpPower, "spectator movement preserved")
check(callbacksAtStart[1].eligible(racer), "official racer eligible")
check(not callbacksAtStart[1].eligible(spectator) and not callbacksAtStart[1].eligible(unofficial), "spectator/unofficial contact excluded")
check(callbacksAtStart[1].recover == recover, "server recovery callback passed unchanged")
check(service.GetDiagnostics().movementProfiles == 1 and service.GetDiagnostics().gravityMatches, "scoped movement diagnostics")
tick()
check(starts == 1, "ordinary tick does not restart hazards")
raceId = "race-B"
check(not callbacksAtStart[1].eligible(racer), "stale race immediately ineligible")
tick()
check(starts == 2 and stops == 1 and service.GetDiagnostics().raceId == "race-B", "new race rebinds same course")
local replacementCharacter, replacementHumanoid = character(9, 3, 40)
racer.Character = replacementCharacter; tick()
check(racerHumanoid.WalkSpeed == 22 and racerHumanoid.UseJumpPower and racerHumanoid.JumpHeight == 5 and racerHumanoid.JumpPower == 60, "old character profile restored")
check(replacementHumanoid.WalkSpeed == 16 and replacementHumanoid.JumpHeight == 7.2, "replacement character profile applied")
replacementHumanoid.Health = 0; tick()
check(replacementHumanoid.WalkSpeed == 9 and replacementHumanoid.JumpHeight == 3, "dead character profile released")
replacementHumanoid.Health = 100; tick()
statuses[racer] = "Finished"; tick()
check(replacementHumanoid.WalkSpeed == 9 and service.GetDiagnostics().movementProfiles == 0, "finish restores movement")
statuses[racer] = "Racing"; tick()
active = false
check(not callbacksAtStart[2].eligible(racer), "race end immediately ineligible")
tick()
check(stops == 1 and service.GetDiagnostics().bound and service.GetDiagnostics().holding and holds == 1
	and replacementHumanoid.WalkSpeed == 9, "race end holds occupied mechanism poses and restores movement")
active = true; raceId = ""; tick()
check(starts == 2, "empty race identity rejected")
raceId = "race-C"; tick()
check(starts == 3, "next race starts")
currentCourse = mockCourse("city_run", true, true)
check(not callbacksAtStart[3].eligible(racer), "course replacement immediately ineligible")
tick()
check(stops == 3 and replacementHumanoid.WalkSpeed == 9, "course replacement restores movement")
currentCourse = mockCourse("egg_rush_circuit", true, true); tick()
service.Stop(); service.Stop()
check(stops == 4 and replacementHumanoid.WalkSpeed == 9 and replacementHumanoid.UseJumpPower, "idempotent Stop restores movement")
tick()
check(starts == 4, "disconnected service remains stopped")
server = false
check(not pcall(service.Start), "client service start rejected")
server = true
service.Start(); tick()
check(starts == 5, "service can restart after Stop")
service.Stop()
check(workspace.Gravity == 196.2 and replacementHumanoid.WalkSpeed == 9, "no global gravity change and final restoration")
failNext = true
service.Start(); tick()
check(starts == 6 and not service.GetDiagnostics().bound and service.GetDiagnostics().raceId == ""
	and service.GetDiagnostics().startFailure ~= "", "failed runtime start leaves binding uncommitted")
tick()
check(starts == 6, "failed start retries are bounded")
now += 1; tick()
check(starts == 7 and service.GetDiagnostics().bound and service.GetDiagnostics().startFailure == "", "failed runtime start recovers on retry")
selfStop = true; tick(); selfStop = false; tick()
check(starts >= 8 and service.GetDiagnostics().bound, "self-stopped controller is rebound")
service.Stop()
check(replacementHumanoid.WalkSpeed == 9 and replacementHumanoid.UseJumpPower, "retry lifecycle restores movement")
print("Egg Rush: " .. checks .. " authored-contract, gate, cycle and service lifecycle checks passed; native physics not simulated")
