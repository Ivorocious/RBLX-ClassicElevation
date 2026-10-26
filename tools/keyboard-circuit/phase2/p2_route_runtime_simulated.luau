local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local V, C, Enum = roblox.Vector3, roblox.CFrame, roblox.Enum
roblox.implementMethod("Model", "GetPivot", function(model) return if model.PrimaryPart then model.PrimaryPart.CFrame * model.PrimaryPart.PivotOffset else model.WorldPivotData or C.identity end)
roblox.implementMethod("Model", "PivotTo", function(model, target)
	local delta = target * model:GetPivot():Inverse()
	for _,item in model:GetDescendants() do if item:IsA("BasePart") then item.CFrame = delta * item.CFrame end end
	model.WorldPivotData = target
end)
local networkOwnerCalls = 0
roblox.implementMethod("BasePart", "SetNetworkOwner", function(_, owner) assert(owner == nil); networkOwnerCalls += 1 end)
local candidate = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_mechanism_fixture.rbxm"))[1]
local source = candidate.Source
for _,name in {"Motion", "Mechanisms", "MechanismRuntime"} do
	local item = source:FindFirstChild(name) or roblox.Instance.new("ModuleScript")
	item.Name, item.Source, item.Parent = name, fs.readFile("tools/keyboard-circuit/phase2/staged/" .. name .. ".luau"), source
end
local character = roblox.Instance.new("Model")
character.Name = "SimulatedEligibleCharacter"
local root = roblox.Instance.new("Part")
root.Name, root.Parent, root.Size = "HumanoidRootPart", character, V.new(2, 2, 1)
local head = roblox.Instance.new("Part")
head.Name, head.Parent, head.Size = "Head", character, V.new(2, 1, 1)
local humanoid = roblox.Instance.new("Humanoid")
humanoid.Health, humanoid.FloorMaterial, humanoid.Parent = 100, Enum.Material.Plastic, character
local player = {Character = character}
local connected, now, queryCalls, forcedContacts, recoveries = {}, 0, 0, false, {}
local services = {}
services.Players = {GetPlayers = function() return {player} end}
services.RunService = {IsServer = function() return true end, Heartbeat = {Connect = function(_, callback)
	local connection = {connected = true, callback = callback}
	function connection:Disconnect() self.connected = false end
	table.insert(connected, connection)
	return connection
end}}
services.Workspace = {
	GetServerTimeNow = function() return now end,
	GetPartsInPart = function(_, _, params)
		queryCalls += 1
		assert(params.RespectCanCollide == false and params.FilterDescendantsInstances[1] == character)
		return if forcedContacts then {head} else {}
	end,
	Raycast = function(_, position, direction, params)
		for _,part in params.FilterDescendantsInstances do
			local point = part.CFrame:PointToObjectSpace(position)
			if part.CanCollide and math.abs(point.X) <= part.Size.X / 2 and math.abs(point.Z) <= part.Size.Z / 2 and point.Y >= part.Size.Y / 2 and point.Y + direction.Y <= part.Size.Y / 2 then return {Instance = part} end
		end
		return nil
	end,
}
local game = {GetService = function(_, name) return services[name] end}
local cache = {}
local function loadModule(item)
	if cache[item] then return cache[item] end
	local env = {script = item, game = game, require = loadModule, RaycastParams = {new = function() return {} end}, OverlapParams = {new = function() return {} end}}
	for key, value in roblox do env[key] = value end
	cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
	return cache[item]
end
local Runtime, Mechanisms = loadModule(source.MechanismRuntime), loadModule(source.Mechanisms)
local units, starts, sliders = {}, {}, {}
for _,unit in candidate:GetChildren() do
	local kind = unit:GetAttribute("MechanismKind")
	if not kind then continue end
	units[kind] = unit
	for _,item in unit:GetDescendants() do if item:IsA("Model") and item:GetAttribute("KCMover") then starts[item] = item:GetPivot() end end
	if kind == "Lift" or kind == "Shuttle" then unit.Slider.CurrentPosition = 0; table.insert(sliders, unit) end
end
local function recover(_, reason) table.insert(recoveries, reason); return true end
local function connectionCount()
	local count = 0
	for _,connection in connected do if connection.connected then count += 1 end end
	return count
end
local rider = units.Lift.RideableBank
local function supportPosition() return rider.BankContact.CFrame.Position + V.new(0, 3.125, 0) end
root.CFrame = C.new(supportPosition())
local controller = Runtime.Start(candidate, function() return true end, recover)
assert(Runtime.Start(candidate, function() error("Duplicate Start must retain callbacks") end, recover) == controller)
assert(connectionCount() == 1)
local history, maxQueries = {}, 0
local function pulse(dt, followLift)
	now += dt
	for _,unit in sliders do
		if not unit.Slider.Enabled then continue end
		local slider = unit.Slider
		local nextPosition = slider.CurrentPosition + math.clamp(slider.TargetPosition - slider.CurrentPosition, -slider.Speed * dt, slider.Speed * dt)
		slider.CurrentPosition = nextPosition
		unit.RideableBank:PivotTo(starts[unit.RideableBank] + Mechanisms.GetFrame(unit):VectorToWorldSpace((if unit:GetAttribute("MechanismKind") == "Lift" then V.yAxis else V.xAxis) * nextPosition))
	end
	if followLift then root.CFrame = C.new(supportPosition()) end
	local before = queryCalls
	for _,connection in connected do if connection.connected then connection.callback() end end
	maxQueries = math.max(maxQueries, queryCalls - before)
	for kind, unit in units do
		history[kind] = history[kind] or {}
		history[kind][unit:GetAttribute("CycleState")] = true
	end
end
for _ = 1, 960 do pulse(1 / 60, true) end
local diagnostics = controller.Diagnostics()
assert(diagnostics.active and diagnostics.errors == 0, serde.encode("json", diagnostics))
for _,state in {"Boarding", "Rising", "HighDwell", "Returning", "Waiting"} do assert(history.Lift[state], "Missing lift state " .. state) end
for _,state in {"Boarding", "Outbound", "Exit", "Returning"} do assert(history.Shuttle[state], "Missing shuttle state " .. state) end
assert(diagnostics.peakQueries == maxQueries and maxQueries <= diagnostics.maxQueriesPerFrame)
forcedContacts = true
pulse(1 / 60, true)
forcedContacts = false
assert(#recoveries >= 1, "Body contact must call the server recovery callback")
local elapsed = controller.Diagnostics().elapsed
local beforeStallQueries = queryCalls
pulse(.5, true)
assert(controller.Diagnostics().elapsed == elapsed, "Stall must freeze the shared clock")
local stationaryStallQueries = queryCalls - beforeStallQueries
assert(stationaryStallQueries == 10 and controller.Diagnostics().stalledContactFrames == 1, "Frozen motion must still check all ten stationary lethal shapes")
local replacement = controller.Reset()
assert(not controller.Diagnostics().active and replacement.Diagnostics().active and connectionCount() == 1)
controller = replacement
for _ = 1, 120 do pulse(1 / 60, true) end
controller.Stop()
controller.Stop()
assert(connectionCount() == 0 and not controller.Diagnostics().active)
local restoredActors = 0
for actor, start in starts do
	local current = actor:GetPivot()
	assert((current.Position - start.Position).Magnitude < .001)
	local _, angle = current:ToObjectSpace(start):ToAxisAngle()
	assert(math.abs(angle) < .001)
	for _,item in actor:GetDescendants() do if item:IsA("BasePart") then assert(item.Anchored) end end
	restoredActors += 1
end
assert(table.find(recoveries, "MechanismReset"), "Stopping a supported rider must request recovery")
local output = {status = "passed", simulated = true, heartbeatConnectionsAtStart = 1, heartbeatConnectionsAfterReset = 1, heartbeatConnectionsAfterStop = 0, restoredActors = restoredActors, recoveryCallbacks = #recoveries, explicitServerOwnershipCalls = networkOwnerCalls, runtimeQueries = diagnostics.bodyQueries, peakRuntimeQueriesPerFrame = diagnostics.peakQueries, stationaryStallQueries = stationaryStallQueries, diagnostics = diagnostics, cycleHistory = history, limits = "Actual staged runtime source in Lune with mocked Players, Heartbeat, raycast/overlap queries and ideal servo progress. This proves source control flow and lifecycle assertions only; it does not prove Roblox spatial contact, carrying, multiplayer, FPS, devices or human traversal."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_runtime_simulated_receipt.json", serde.encode("json", output, true))
print(serde.encode("json", output, true))
