local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Progression = require("./staged/Progression")
local source = fs.readFile("tools/keyboard-circuit/phase2/staged/Session.server.luau")
local checks = 0
local function check(value, message) checks += 1; assert(value, message) end

local function world(count, modelPads)
	local now, objects, tasks, log, players, runtimes = 0, {}, {}, {}, {}, {}
	local function signal()
		local handlers = {}
		return {
			Connect = function(_, callback)
				local connection = {Connected = true, callback = callback}
				function connection:Disconnect() self.Connected = false end
				table.insert(handlers, connection)
				return connection
			end,
			Fire = function(_, ...)
				for _, handler in table.clone(handlers) do if handler.Connected then handler.callback(...) end end
			end,
		}
	end
	local vectorMethods = {}
	local function vector(x, y, z)
		return setmetatable({X = x, Y = y, Z = z}, {
			__index = function(self, name)
				if name == "Magnitude" then return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2) end
				return vectorMethods[name]
			end,
			__add = function(a, b) return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end,
			__sub = function(a, b) return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end,
		})
	end
	local function cframe(x, y, z)
		local cf = {Position = if type(x) == "table" then x else vector(x or 0, y or 0, z or 0), _type = "CFrame"}
		function cf:PointToObjectSpace(point) return point - self.Position end
		return setmetatable(cf, {__mul = function(a, b) return cframe(a.Position + b.Position) end})
	end
	local methods = {}
	local function instance(kind)
		local data = {ClassName = kind, Name = kind, attributes = {}, signals = {}, ChildAdded = signal(), Destroying = signal()}
		if kind == "BindableEvent" then data.Event = signal() end
		local object = setmetatable({_data = data}, {
			__index = function(self, name)
				if methods[name] then return methods[name] end
				if data[name] ~= nil then return data[name] end
				for _, other in objects do if other._data.Parent == self and other._data.Name == name then return other end end
				return nil
			end,
			__newindex = function(_, name, value) data[name] = value end,
		})
		table.insert(objects, object)
		return object
	end
	function methods:IsA(kind) return self.ClassName == kind or (kind == "BasePart" and self.ClassName == "Part") end
	function methods:GetChildren()
		local result = {}
		for _, object in objects do if object.Parent == self then table.insert(result, object) end end
		return result
	end
	function methods:GetDescendants()
		local result = {}
		for _, child in self:GetChildren() do
			table.insert(result, child)
			for _, inner in child:GetDescendants() do table.insert(result, inner) end
		end
		return result
	end
	function methods:FindFirstChild(name)
		for _, child in self:GetChildren() do if child.Name == name then return child end end
		return nil
	end
	function methods:FindFirstChildOfClass(kind)
		for _, child in self:GetChildren() do if child:IsA(kind) then return child end end
		return nil
	end
	function methods:WaitForChild(name, timeout)
		local deadline = now + timeout
		while now < deadline do
			local found = self:FindFirstChild(name)
			if found then return found end
			coroutine.yield(.05)
		end
		return nil
	end
	function methods:GetAttribute(name) return self._data.attributes[name] end
	function methods:SetAttribute(name, value)
		if self._data.attributes[name] == value then return end
		self._data.attributes[name] = value
		table.insert(log, {kind = "attribute", object = self.Name, name = name, value = value})
	end
	function methods:Fire(...) self.Event:Fire(...) end
	function methods:Invoke(...) return self.OnInvoke(...) end
	function methods:PivotTo(cf)
		self.pivots = (self.pivots or 0) + 1
		local root = self:FindFirstChild("HumanoidRootPart")
		if root then root.Position = cf.Position end
		table.insert(log, {kind = "recovery", character = self.Name, position = cf.Position})
	end
	local function child(parent, name, kind)
		local object = instance(kind)
		object.Name, object.Parent = name, parent
		return object
	end
	local candidate = instance("Model")
	candidate.Name = "KeyboardCircuit_P2_C01"
	candidate:SetAttribute("Origin", vector(0, 330, 0))
	candidate:SetAttribute("KCPhase2SessionEnabled", true)
	candidate:SetAttribute("KCPhase2RunId", 1)
	local pads = child(candidate, "RecoveryPads", "Folder")
	for index, name in {"F00", "CP1", "CP2", "CP3"} do
		local parent = pads
		if modelPads then
			parent = child(pads, name, "Model")
			parent:SetAttribute("Columns", 4)
			parent:SetAttribute("Rows", 4)
			parent:SetAttribute("GridPitchX", 2.6)
			parent:SetAttribute("GridPitchZ", 2.6)
			child(parent, "Key_1_1", "Part"):SetAttribute("Pressable", true)
		end
		local pad = child(parent, if modelPads then "BankContact" else name, "Part")
		pad.Anchored = true
		pad:SetAttribute("SpawnCFrame", cframe(index * 50, 333, 0))
		pad:SetAttribute("Role", "Recovery")
		pad:SetAttribute("RecoveryGate", name)
	end
	local gates = child(candidate, "Gates", "Folder")
	for _, name in {"F00", "CP1", "CP2", "CP3", "F01"} do
		local gate = child(gates, name, "Part")
		gate.CFrame, gate.Size = cframe(0, 330, 0), vector(20, 10, 10)
		gate.CFrame.gateId = name
	end
	local support = instance("Part")
	support:SetAttribute("Role", "Walkable")
	local function addParts(character)
		local root = child(character, "HumanoidRootPart", "Part")
		root.Anchored, root.Position = false, vector(100, 333, 100)
		local humanoid = child(character, "Humanoid", "Humanoid")
		humanoid.Health, humanoid.FloorMaterial = 100, "Plastic"
		return root, humanoid
	end
	local function character(player, missing)
		local current = instance("Model")
		current.Name = "Character" .. player.UserId
		player.Character = current
		if not missing then addParts(current) end
		return current
	end
	for index = 1, count or 1 do
		local player = instance("Player")
		player.Name, player.UserId, player.CharacterAdded = "Player" .. index, index, signal()
		player:SetAttribute("OnboardingReady", true)
		character(player)
		table.insert(players, player)
	end
	local playerService = {PlayerRemoving = signal()}
	function playerService:GetPlayers() return players end
	function playerService:GetPlayerByUserId(id) return players[id] end
	function playerService:GetPlayerFromCharacter(character)
		for _, player in players do if player.Character == character then return player end end
		return nil
	end
	local run = {Heartbeat = signal()}
	function run:IsStudio() return true end
	function run:IsServer() return true end
	local workspace = {}
	function workspace:GetServerTimeNow() return now end
	function workspace:Raycast() return {Instance = support} end
	function workspace:GetPartsInPart() return {} end
	local mechanism = {}
	function mechanism.Start(_, eligible, recover)
		local runtime = {eligible = eligible, recover = recover, stopped = 0}
		function runtime.Diagnostics() return {stopped = runtime.stopped} end
		function runtime.Stop() runtime.stopped += 1; table.insert(log, {kind = "runtimeStop"}) end
		table.insert(runtimes, runtime)
		table.insert(log, {kind = "runtimeStart"})
		return runtime
	end
	local crossing, crossingPlayer = nil, 1
	local forward = {}
	function forward.Crossed(cf, _, previous, current)
		local character = players[crossingPlayer].Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if previous ~= nil and cf.gateId == crossing and root and current == root.Position then crossing = nil; return true end
		return false
	end
	local snapshot = child(candidate, "SourceSnapshot", "Folder")
	for name, implementation in {Progression = Progression, ForwardGate = forward, MechanismRuntime = mechanism} do
		child(snapshot, name, "ModuleScript").implementation = implementation
	end
	local script = child(snapshot, "Session", "Script")
	local services = {Players = playerService, RunService = run, Workspace = workspace, HttpService = {JSONEncode = function() return "mock snapshot" end}}
	local environment = setmetatable({
		game = {GetService = function(_, name) return services[name] end}, script = script,
		require = function(module) return module.implementation end, Instance = {new = instance},
		CFrame = {new = cframe}, Vector3 = {new = vector, zero = vector(0, 0, 0)},
		RaycastParams = {new = function() return {} end}, OverlapParams = {new = function() return {} end},
		Enum = {RaycastFilterType = {Include = "Include"}, Material = {Air = "Air"}},
		typeof = function(value) return if type(value) == "table" and value._type then value._type else type(value) end,
		task = {spawn = function(callback) table.insert(tasks, {co = coroutine.create(callback), at = now}) end},
	}, {__index = getfenv(0)})
	luau.load(source, {environment = environment})()
	local function tick(seconds)
		now += seconds or .1
		run.Heartbeat:Fire(seconds or .1)
		local pending = table.clone(tasks)
		table.clear(tasks)
		for _, item in pending do
			if item.at <= now then
				local ok, wait = coroutine.resume(item.co)
				assert(ok, wait)
				if coroutine.status(item.co) ~= "dead" then item.at = now + wait; table.insert(tasks, item) end
			else table.insert(tasks, item) end
		end
	end
	return {
		candidate = candidate, players = players, runtimes = runtimes, log = log, tick = tick,
		fire = function(name, ...) candidate.StudioProbeControls[name]:Fire(...) end,
		state = function() return candidate.StudioProbeControls.State:Invoke() end,
		respawn = function(index, missing)
			local current = character(players[index], missing)
			players[index].CharacterAdded:Fire(current)
			return current
		end,
		addParts = addParts, cross = function(name, index) crossing, crossingPlayer = name, index or 1 end,
	}
end

local anchored = world()
local lockedRoot = anchored.players[1].Character.HumanoidRootPart
lockedRoot.Anchored = true
anchored.fire("Begin", 1)
check(anchored.state().participants["1"] == nil, "anchored Begin creates no participant")
check(anchored.players[1]:GetAttribute("KCPhase2Candidate") == nil and lockedRoot.Anchored, "anchored Begin preserves arrival lock and no opt in")
check(not anchored.players[1].Character.pivots, "anchored Begin never teleports")
lockedRoot.Anchored = false
anchored.players[1]:SetAttribute("OnboardingReady", false)
anchored.fire("Begin", 1)
check(anchored.state().participants["1"] == nil, "explicit false onboarding rejects Begin even unanchored")
check(anchored.players[1]:GetAttribute("OnboardingReady") == false, "Begin never releases foreign readiness")
anchored.players[1]:SetAttribute("OnboardingReady", nil)
anchored.fire("Begin", 1)
check(anchored.state().participants["1"] ~= nil, "unset readiness remains supported")

local stopped = world()
stopped.fire("Begin", 1)
stopped.fire("Stop")
local state = stopped.state()
check(not state.active and stopped.players[1]:GetAttribute("KCPhase2Candidate") == nil, "Stop clears preview opt in")
local afterStop = stopped.respawn(1)
stopped.tick(.1)
check(not afterStop.pivots and stopped.players[1]:GetAttribute("KCPhase2Candidate") == nil, "stopped respawn cannot teleport or opt in again")
check(not stopped.runtimes[1].recover(stopped.players[1], "LateHazard", true), "old hazard recovery cannot run after Stop")
stopped.fire("Begin", 1)
check(stopped.players[1]:GetAttribute("KCPhase2Candidate") == nil, "Begin cannot reactivate stopped Session")
local startLog = #stopped.log
stopped.fire("Restart")
check(stopped.state().active and stopped.candidate:GetAttribute("KCPhase2RunId") == 2, "stopped Session supports explicit Restart")
check(afterStop.pivots == 1 and stopped.players[1]:GetAttribute("KCPhase2Candidate") == stopped.candidate.Name, "Restart recovers living participant before reopting in")
local recovered, changedRun
for index = startLog + 1, #stopped.log do
	local item = stopped.log[index]
	if item.kind == "recovery" then recovered = index end
	if item.kind == "attribute" and item.name == "KCPhase2RunId" then changedRun = index end
end
check(recovered and changedRun and recovered < changedRun, "supported Restart recovery precedes preview generation")

local refused = world(2)
refused.fire("Begin", 1); refused.fire("Begin", 2)
local firstPivots, secondPivots = refused.players[1].Character.pivots, refused.players[2].Character.pivots
local locked = refused.players[2].Character.HumanoidRootPart
locked.Anchored = true
local before = #refused.log
refused.fire("Restart")
check(#refused.log == before, "refused active restart has no attribute/runtime/recovery writes")
check(#refused.runtimes == 1 and refused.runtimes[1].stopped == 0 and refused.candidate:GetAttribute("KCPhase2RunId") == 1, "refused restart preserves runtime and run ID")
check(refused.players[1].Character.pivots == firstPivots and refused.players[2].Character.pivots == secondPivots and locked.Anchored, "preflight refuses before moving any participant")
check(refused.players[2]:GetAttribute("KCPhase2Candidate") == refused.candidate.Name, "refused restart preserves preview generation and current selection")
locked.Anchored = false
refused.players[2]:SetAttribute("OnboardingReady", false)
before = #refused.log
refused.fire("Restart")
check(#refused.log == before and refused.players[2]:GetAttribute("OnboardingReady") == false, "false-ready restart is unchanged and preserves foreign readiness")
refused.fire("Stop")
before = #refused.log
refused.fire("Restart")
check(#refused.log == before and not refused.state().active and refused.players[2]:GetAttribute("KCPhase2Candidate") == nil, "refused stopped restart stays stopped without opt in")

local dead = world(2)
dead.fire("Begin", 1); dead.fire("Begin", 2)
dead.tick(.1); dead.cross("CP1"); dead.tick(.1)
local beforeRecovery = dead.state().participants["1"].recoveryGate
check(beforeRecovery == "CP1", "normal checkpoint retained before death")
dead.players[1].Character.Humanoid.Health = 0
dead.fire("Stop"); dead.fire("Restart")
check(dead.state().active and dead.candidate:GetAttribute("KCPhase2RunId") == 2, "dead character does not block other racers restarting")
local fresh = dead.respawn(1)
dead.tick(.1)
check(fresh.pivots == 1 and dead.state().participants["1"].recoveryGate == "CP1", "later CharacterAdded recovers dead participant to retained checkpoint")
check(dead.players[1]:GetAttribute("KCPhase2Candidate") == dead.candidate.Name, "running respawn keeps participant opt in")
dead.players[1].Character = nil
dead.fire("Restart")
check(dead.candidate:GetAttribute("KCPhase2RunId") == 3, "absent character does not block Restart")

local queued = world()
queued.fire("Begin", 1)
local pendingCharacter = queued.respawn(1, true)
queued.tick(.1)
queued.fire("Stop")
queued.addParts(pendingCharacter)
queued.fire("Restart")
local count = #queued.state().recoveries
queued.tick(.1)
check(#queued.state().recoveries == count and pendingCharacter.pivots == 1, "old pending respawn cannot replay after Stop and Restart")
check(queued.state().recoveries[count].reason == "SessionRestart", "only explicit Restart performs queued character recovery")
queued.tick(.1); queued.cross("CP1"); queued.fire("Restart"); queued.tick(.1)
check(queued.state().participants["1"].nextGate == "CP1", "restart clears old crossing sample before next gate")

local modelPad = world(1, true)
modelPad.fire("Begin", 1)
check(modelPad.players[1].Character.pivots == 1 and modelPad.state().participants["1"] ~= nil, "model recovery bank supports Begin")
local contact = modelPad.candidate.RecoveryPads.CP1.BankContact
check(contact.Name == "BankContact" and contact.Parent.Name == "CP1" and contact.Parent:GetAttribute("Columns") == 4, "contact retains bank name and grid-bearing parent")
check(contact.Parent.Key_1_1:GetAttribute("Pressable") == true and contact:GetAttribute("RecoveryGate") == "CP1", "recovery bank retains pressable keys and contact metadata")
modelPad.tick(.1); modelPad.cross("CP1"); modelPad.tick(.1)
check(modelPad.runtimes[1].recover(modelPad.players[1], "ModelPadRetry", true), "checkpoint retry resolves model BankContact")
check(modelPad.players[1].Character.HumanoidRootPart.Position.X == 91 and modelPad.state().participants["1"].recoveryGate == "CP1", "retry uses model contact SpawnCFrame without advancing")
modelPad.fire("Stop"); modelPad.fire("Restart")
check(modelPad.candidate:GetAttribute("KCPhase2RunId") == 2 and modelPad.players[1]:GetAttribute("KCPhase2Candidate") == modelPad.candidate.Name, "model pads support safe stopped Restart")
contact:SetAttribute("SpawnCFrame", nil)
local modelPivots = modelPad.players[1].Character.pivots
check(not modelPad.runtimes[2].recover(modelPad.players[1], "MissingModelSpawn", true) and modelPad.players[1].Character.pivots == modelPivots, "model contact without SpawnCFrame cannot recover")
local modelLog = #modelPad.log
modelPad.fire("Restart")
check(#modelPad.log == modelLog and modelPad.candidate:GetAttribute("KCPhase2RunId") == 2, "invalid model recovery pad refuses restart before mutation")

fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_integration_session_receipt.json", require("@lune/serde").encode("json", {
	passed = true, checks = checks,
	scope = "actual staged Session source with mocked Roblox services; no Studio runtime claims",
	cases = {"anchored Begin rejection", "explicit false onboarding rejection", "stopped respawn and stale hazard callbacks", "stopped opt-in", "safe Restart ordering", "unchanged refused Restart", "dead/absent participant Restart", "retained-checkpoint respawn", "pending respawn invalidation", "crossing history clear", "model recovery BankContact", "retained grid parent and pressable keys", "legacy BasePart recovery fixture"},
}, true))
print(checks .. " Phase2 Session mocked lifecycle checks passed")
