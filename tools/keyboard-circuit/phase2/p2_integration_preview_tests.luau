local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Readiness = require("./staged/Phase2Readiness")
local source = fs.readFile("tools/keyboard-circuit/phase2/staged/KeyboardCircuitPhase2Preview.client.luau")
luau.load(fs.readFile("tools/keyboard-circuit/phase2/p2_integration_runtime_probe.luau"))
local checks = 0
local function check(value, message) checks += 1; assert(value, message) end

local function world(delay, safe, actualFeedback)
	local now, objects, queue, controllers, warnings = 0, {}, {}, {}, {}
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
	local methods = {}
	local function instance(className)
		local data = {ClassName = className, Name = className, attributes = {}, signals = {}, Parent = nil, Destroying = signal(), ChildAdded = signal(), ChildRemoved = signal(), DescendantAdded = signal(), DescendantRemoving = signal()}
		local object = setmetatable({_data = data}, {
			__index = function(self, name)
				if methods[name] then return methods[name] end
				if data[name] ~= nil then return data[name] end
				for _, object in objects do if object._data.Parent == self and object._data.Name == name then return object end end
				return nil
			end,
			__newindex = function(_, name, value) data[name] = value end,
		})
		table.insert(objects, object)
		return object
	end
	function methods:IsA(className) return self.ClassName == className or (className == "BasePart" and self.ClassName == "Part") end
	function methods:GetChildren()
		local result = {}
		for _, object in objects do if object.Parent == self then table.insert(result, object) end end
		return result
	end
	function methods:FindFirstChild(name)
		for _, child in self:GetChildren() do if child.Name == name then return child end end
		return nil
	end
	function methods:FindFirstChildOfClass(className)
		for _, child in self:GetChildren() do if child:IsA(className) then return child end end
		return nil
	end
	function methods:IsDescendantOf(parent)
		local current = self.Parent
		while current do if current == parent then return true end; current = current.Parent end
		return false
	end
	function methods:GetAttribute(name) return self._data.attributes[name] end
	function methods:GetAttributeChangedSignal(name)
		if not self._data.signals[name] then self._data.signals[name] = signal() end
		return self._data.signals[name]
	end
	function methods:SetAttribute(name, value)
		if self._data.attributes[name] == value then return end
		self._data.attributes[name] = value
		self:GetAttributeChangedSignal(name):Fire()
	end
	function methods:Destroy()
		if self._data.destroyed then return end
		self._data.destroyed = true
		self.Destroying:Fire()
		self.Parent = nil
	end
	function methods:GetState() return "Running" end
	function methods:Move() self.moves = (self.moves or 0) + 1 end
	local function child(parent, name, kind)
		local object = instance(kind)
		object.Name, object.Parent = name, parent
		return object
	end
	local workspace = instance("Workspace")
	local player = instance("Player")
	local playerGui = child(player, "PlayerGui", "PlayerGui")
	player.CharacterAdded, player.CharacterRemoving = signal(), signal()
	local function character()
		local current = instance("Model")
		local root = child(current, "HumanoidRootPart", "Part")
		root.Position = {}
		local humanoid = child(current, "Humanoid", "Humanoid")
		humanoid.Health, humanoid.FloorMaterial = 100, "Plastic"
		player.Character = current
		return current
	end
	character()
	local baseline = child(workspace, "KeyboardCircuit_P1_C08", "Model")
	baseline:SetAttribute("CourseId", "keyboard-circuit")
	baseline:SetAttribute("KCSessionEnabled", true)
	local candidate = child(workspace, "KeyboardCircuit_P2_C01", "Model")
	candidate:SetAttribute("CourseId", "keyboard-circuit-phase2")
	candidate:SetAttribute("KCPhase2PreviewEnabled", true)
	candidate:SetAttribute("KCPhase2RunId", 1)
	local pads = child(candidate, "RecoveryPads", "Folder")
	local pad = child(pads, "F00", "Part")
	pad.Anchored = true
	local mechanism = child(candidate, "MovingShuttle", "Part")
	mechanism.Anchored = true
	local snapshot = child(candidate, "SourceSnapshot", "Folder")
	local feedback = {}
	function feedback.Start()
		local began = now
		local controller = {active = true, stopped = 0, polls = 0}
		function controller.Readiness()
			assert(controller.active, "old feedback polled after Stop")
			controller.polls += 1
			local ready = now - began >= delay
			return {state = if ready then "ready" else "loading", loaded = if ready then 8 else 0, total = 8}
		end
		function controller.Stop() controller.active = false; controller.stopped += 1 end
		function controller.Diagnostics() return {totals = {}, audio = {}, readiness = controller.Readiness()} end
		function controller.IsResolved() return controller.Readiness().state ~= "loading" end
		table.insert(controllers, controller)
		return controller
	end
	for name, value in {KeyboardCircuitFeedback = feedback, KeyboardCircuitAudio = {}, Phase2Readiness = Readiness, ConfigSnapshot = {AudioReadyTimeout = 10}} do
		child(snapshot, name, "ModuleScript").value = value
	end
	local script = instance("LocalScript")
	local actions = {OtherScreen = true, KeyboardCircuitLoading55 = true}
	local renders = {}
	local cas = {}
	function cas:BindActionAtPriority(name, callback) actions[name] = callback end
	function cas:UnbindAction(name)
		assert(string.sub(name, 1, #"KeyboardCircuitPhase2Loading_") == "KeyboardCircuitPhase2Loading_", "foreign movement action changed")
		actions[name] = nil
	end
	local run = {}
	function run:IsStudio() return true end
	function run:IsClient() return true end
	run.PreRender = signal()
	function run:BindToRenderStep(name, _, callback) renders[name] = callback end
	function run:UnbindFromRenderStep(name) renders[name] = nil end
	function workspace:Raycast()
		return {Normal = {Y = 1}, Instance = if safe then pad else mechanism}
	end
	local tasks = {}
	local function schedule(callback, due)
		table.insert(queue, {co = coroutine.create(callback), due = due})
	end
	function tasks.spawn(callback) schedule(callback, now) end
	function tasks.delay(seconds, callback) schedule(callback, now + seconds) end
	function tasks.wait(seconds) return coroutine.yield(seconds) end
	local mockOs = table.clone(os)
	mockOs.clock = function() return now end
	local services = {RunService = run, Players = {LocalPlayer = player}, Workspace = workspace, ContextActionService = cas, ProximityPromptService = {PromptTriggered = signal()}}
	local environment = setmetatable({
		game = {GetService = function(_, name) return services[name] end},
		Workspace = workspace, script = script, require = function(module) return module.value end,
		Instance = {new = instance}, task = tasks, os = mockOs, warn = function(message) table.insert(warnings, message) end,
		RaycastParams = {new = function() return {} end},
		Vector2 = {new = function(...) return {...} end}, Vector3 = {new = function(...) return {...} end, zero = {}},
		UDim = {new = function(...) return {...} end}, UDim2 = {new = function(...) return {...} end}, Color3 = {fromRGB = function(...) return {...} end},
		Enum = {RaycastFilterType = {Include = "Include"}, HumanoidStateType = {Jumping = "Jumping", Freefall = "Freefall"}, Material = {Air = "Air"}, Font = {FredokaOne = "FredokaOne"}, ContextActionResult = {Sink = "Sink"}, PlayerActions = {CharacterForward = 1, CharacterBackward = 2, CharacterLeft = 3, CharacterRight = 4, CharacterJump = 5}, RenderPriority = {Input = {Value = 100}}},
	}, {__index = getfenv(0)})
	local p1Controller
	if actualFeedback then
		local modules = instance("Folder")
		local feedbackScript = child(modules, "KeyboardCircuitFeedback", "ModuleScript")
		child(modules, "KeyboardCircuitAudio", "ModuleScript").value = {Start = feedback.Start}
		local feedbackEnvironment = table.clone(environment)
		feedbackEnvironment.script = feedbackScript
		local implementation = luau.load(fs.readFile("src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitFeedback.luau"), {environment = feedbackEnvironment})()
		local oldSnapshot = child(baseline, "SourceSnapshot", "Folder")
		child(oldSnapshot, "ConfigSnapshot", "ModuleScript").value = {AudioReadyTimeout = 10}
		p1Controller = implementation.Start(baseline)
		snapshot.KeyboardCircuitFeedback.value = implementation
	end
	luau.load(source, {environment = environment})()
	local function tick(seconds)
		now += seconds
		for _, callback in table.clone(renders) do callback() end
		local current = table.clone(queue)
		table.clear(queue)
		for _, item in current do
			if item.due <= now then
				local ok, wait = coroutine.resume(item.co)
				assert(ok, wait)
				if coroutine.status(item.co) ~= "dead" then item.due = now + wait; table.insert(queue, item) end
			else table.insert(queue, item) end
		end
	end
	local function holding()
		for name in actions do if string.find(name, "KeyboardCircuitPhase2Loading_", 1, true) then return true end end
		return false
	end
	return {
		tick = tick, holding = holding, actions = actions, controllers = controllers, warnings = warnings,
		candidate = candidate, player = player, script = script, playerGui = playerGui,
		p1Controller = p1Controller,
		opt = function(name) player:SetAttribute("KCPhase2Candidate", name or candidate.Name) end,
		safe = function(value) safe = value end,
		respawn = function()
			player.CharacterRemoving:Fire(player.Character)
			player.Character = nil
			local nextCharacter = character()
			player.CharacterAdded:Fire(nextCharacter)
		end,
	}
end

local first, second = world(1, true), world(4, true)
first.tick(.1)
check(#first.controllers == 0 and not first.holding(), "installation alone cannot start or hold preview")
first.opt("KeyboardCircuit_P1_C08")
check(#first.controllers == 0, "accepted sample never selected")
first.opt(); second.opt()
first.tick(.1); second.tick(.1)
check(first.holding() and second.holding(), "two clients start independently on stable pads")
first.tick(1); second.tick(1)
check(not first.holding() and second.holding(), "one ready client cannot release the other")
check(first.actions.OtherScreen and first.actions.KeyboardCircuitLoading55, "readiness preserves other screens and C08 controls")
first.player:SetAttribute("KCPhase2Lap", 2)
first.player:SetAttribute("KCPhase2NextGate", "CP2")
check(first.playerGui:FindFirstChild("KeyboardCircuitPhase2Lap").Progress.Text == "Lap 2 of 3 · 1/3 checkpoints", "lap display follows server participant attributes")
first.player:SetAttribute("KCPhase2Finished", true)
check(first.playerGui:FindFirstChild("KeyboardCircuitPhase2Lap").Progress.Text == "Course complete · 3 laps", "completion display follows server finish attribute")
second.safe(false); second.tick(.1)
check(not second.holding(), "live mechanism support releases movement immediately")
local live = world(100, false)
live.opt(); live.tick(.1)
check(not live.holding(), "arrival already on moving mechanism cannot lock movement")
live.tick(10)
check(not live.holding() and live.playerGui:FindFirstChild("KeyboardCircuitPhase2Status"):GetAttribute("ReadinessState") == "degraded", "stalled clips allow degraded play within bound")

local restart = world(4, true)
restart.opt(); restart.tick(.1)
local old = restart.controllers[1]
restart.candidate:SetAttribute("KCPhase2RunId", 2)
restart.tick(.1)
check(old.stopped == 1 and not old.active and #restart.controllers == 2, "restart stops old feedback before fresh generation")
check(restart.holding(), "restarted participant can load on stable recovery pad")
restart.respawn(); restart.tick(.1)
check(restart.controllers[2].stopped == 1 and #restart.controllers == 3, "respawn clears old feedback without a replay queue")
restart.player:SetAttribute("KCPhase2Candidate", nil)
restart.tick(.1)
check(not restart.holding() and restart.controllers[3].stopped == 1, "leaving preview releases only its own control ownership")
restart.tick(20)
check(not restart.holding(), "old asynchronous tasks cannot reacquire after cancellation")

local removal = world(5, true)
removal.opt(); removal.tick(.1)
removal.candidate:SetAttribute("KCPhase2PreviewEnabled", false)
removal.tick(.1)
check(not removal.holding() and removal.controllers[1].stopped == 1, "candidate stop cancels loading")
removal.script:Destroy()
removal.candidate:SetAttribute("KCPhase2PreviewEnabled", true)
removal.opt(); removal.tick(20)
check(#removal.controllers == 1 and not removal.holding(), "destroyed preview cannot restart from stale subscriptions")
local coexist = world(2, true, true)
coexist.opt(); coexist.tick(.1)
check(#coexist.controllers == 2 and coexist.controllers[1].active, "actual C08 feedback keeps P1 running while P2 starts")
coexist.candidate:SetAttribute("KCPhase2RunId", 2)
coexist.tick(.1)
check(coexist.controllers[1].active and coexist.controllers[2].stopped == 1 and #coexist.controllers == 3, "P2 restart stops only its candidate identity")
coexist.player:SetAttribute("KCPhase2Candidate", nil)
coexist.tick(.1)
check(coexist.p1Controller.Diagnostics().active and coexist.controllers[1].stopped == 0, "P2 exit cannot stop unrelated accepted P1 feedback")
for _, state in {first, second, live, restart, removal} do
	check(state.actions.OtherScreen and state.actions.KeyboardCircuitLoading55, "all cleanup paths preserve foreign actions")
	check(#state.warnings == 0, "controlled lifecycle has no preview error")
end
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_integration_preview_receipt.json", require("@lune/serde").encode("json", {
	passed = true, checks = checks,
	scope = "actual staged preview source in mocked Roblox services; no engine, audible playback, device, crowd or FPS proof",
	cases = {"opt in isolation", "two independent local startup contexts", "control ownership", "stable pad and live mechanism support", "deadline degradation", "restart generation", "loading respawn", "cancellation", "script teardown", "authoritative lap label", "accepted C08 controller coexistence"},
}, true))
print(checks .. " Phase2 preview mocked lifecycle checks passed")
