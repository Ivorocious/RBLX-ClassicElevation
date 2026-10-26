--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PromptService = game:GetService("ProximityPromptService")
local Audio = require(script.Parent.KeyboardCircuitAudio)
local Feedback = {}
local running = setmetatable({}, {__mode = "k"})

function Feedback.Start(candidate: Model)
	assert(RunService:IsClient(), "Key feedback belongs to the local client")
	if running[candidate] then return running[candidate] end
	local existing = Feedback.Get(candidate)
	if existing then return existing end
	local snapshot = candidate:FindFirstChild("SourceSnapshot")
	local Config = require(if snapshot then snapshot.ConfigSnapshot else game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig)
	local localPlayer = Players.LocalPlayer
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "KeyboardCircuitAudition", localPlayer.PlayerGui
	local identity = Instance.new("ObjectValue")
	identity.Name, identity.Value, identity.Parent = "Candidate", candidate, folder
	local audio = Audio.Start(folder, Config)
	local states, contacts, occupied, ownKeys = {}, {}, {}, {}
	local active, nearbyAt, ownAudioAt, releaseAudioAt, nearbyAudioAt = true, 0, 0, 0, 0
	local totals = {entries = 0, releases = 0, coalesced = 0, releaseCoalesced = 0, visualWrites = 0, warningWrites = 0, createdVisuals = 0, restoredVisuals = 0}
	local visualCamera = Workspace.CurrentCamera
	local ray = RaycastParams.new()
	ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
	local banks = setmetatable({}, {__mode = "k"})
	local function keyAt(hit: RaycastResult, position: Vector3): BasePart?
		local support = hit.Instance
		local link = support:FindFirstChild("PressKey")
		if link and link:IsA("ObjectValue") and link.Value and link.Value:IsA("BasePart") then
			return if link.Value:IsDescendantOf(candidate) and link.Value:GetAttribute("Pressable") then link.Value else nil
		end
		if support.Name ~= "BankContact" then return nil end
		local bank = support.Parent
		if not bank then return nil end
		local data = banks[bank]
		if not data then
			data = {columns = bank:GetAttribute("Columns"), rows = bank:GetAttribute("Rows"), pitchX = bank:GetAttribute("GridPitchX"), pitchZ = bank:GetAttribute("GridPitchZ"), keys = {}}
			if typeof(data.columns) ~= "number" or typeof(data.rows) ~= "number" or typeof(data.pitchX) ~= "number" or typeof(data.pitchZ) ~= "number" then return nil end
			if data.columns < 1 or data.rows < 1 or data.pitchX <= 0 or data.pitchZ <= 0 then return nil end
			for _,child in bank:GetChildren() do if child:IsA("BasePart") and child:GetAttribute("Pressable") then data.keys[child.Name] = child end end
			banks[bank] = data
		end
		local point = support.CFrame:PointToObjectSpace(position)
		local x = math.clamp(math.floor(point.X / data.pitchX + data.columns / 2) + 1, 1, data.columns)
		local z = math.clamp(math.floor(point.Z / data.pitchZ + data.rows / 2) + 1, 1, data.rows)
		return data.keys["Key_" .. x .. "_" .. z]
	end
	local function groundedFeet(player: Player)
		local fresh, slots = {}, {}
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return character, fresh, slots, false end
		local feet = {
			Left = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),
			Right = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg"),
		}
		for name,foot in feet do if foot:IsA("BasePart") then slots[name] = true end end
		if not next(slots) then slots.Root = true end
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then return character, fresh, slots, false end
		if humanoid.FloorMaterial == Enum.Material.Air then return character, fresh, slots, true end
		local support = Workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
		if not support then return character, fresh, slots, true end
		for name,foot in feet do
			if not slots[name] then continue end
			local sole = foot.CFrame:PointToWorldSpace(Vector3.new(0, -foot.Size.Y / 2, 0))
			local hit = Workspace:Raycast(sole + Vector3.new(0, 1.2, 0), Vector3.new(0, -2.2, 0), ray)
			if hit and hit.Normal.Y > .5 and math.abs((sole - hit.Position):Dot(hit.Normal)) < .85 then
				local key = keyAt(hit, sole)
				if key then fresh[name] = key end
			end
		end
		if slots.Root then
			local key = keyAt(support, root.Position)
			if key then fresh.Root = key end
		end
		return character, fresh, slots, true
	end
	local function restore(state)
		for _,item in state.visuals do
			if item.original.Parent then item.original.LocalTransparencyModifier = item.transparency end
			for _,gui in item.guis do if gui.original.Parent then gui.original.Enabled = gui.enabled end end
			item.clone:Destroy()
			totals.restoredVisuals += 1
		end
		table.clear(state.visuals)
	end
	local function makeVisuals(key: BasePart)
		local visuals = {}
		if not visualCamera then return visuals end
		local originals, seen = {key}, {[key] = true}
		for _,link in key:GetChildren() do
			if link:IsA("ObjectValue") and (link.Name == "PressBody" or link.Name == "PressCompanion") and link.Value and link.Value:IsA("BasePart") and not seen[link.Value] then
				seen[link.Value] = true
				table.insert(originals, link.Value)
			end
		end
		for _,original in originals do
			if not original:IsDescendantOf(candidate) then continue end
			local visual = original:Clone()
			visual.Name = "LocalKeyPress"
			for _,child in visual:GetChildren() do
				if child:IsA("Constraint") or child:IsA("WeldConstraint") or child:IsA("JointInstance") or child:IsA("ObjectValue") then child:Destroy() end
			end
			visual.Anchored, visual.CanCollide, visual.CanTouch, visual.CanQuery = true, false, false, false
			visual.LocalTransparencyModifier = 0
			visual.Parent = visualCamera
			local guis = {}
			for _,gui in original:GetChildren() do
				if gui:IsA("SurfaceGui") then
					table.insert(guis, {original = gui, enabled = gui.Enabled})
					gui.Enabled = false
				end
			end
			local legend = original:FindFirstChild("Legend")
			local warning = if legend then legend:FindFirstChild("DropWarning") else nil
			local clonedLegend = visual:FindFirstChild("Legend")
			local clonedWarning = if clonedLegend then clonedLegend:FindFirstChild("DropWarning") else nil
			table.insert(visuals, {
				original = original, clone = visual, transparency = original.LocalTransparencyModifier, guis = guis,
				warning = warning, clonedWarning = clonedWarning,
				warningStroke = if warning then warning:FindFirstChildOfClass("UIStroke") else nil,
				clonedStroke = if clonedWarning then clonedWarning:FindFirstChildOfClass("UIStroke") else nil,
				lastPose = nil, lastAmount = nil, lastDepth = nil, warningTransparency = nil, warningColor = nil,
			})
			original.LocalTransparencyModifier = 1
			totals.createdVisuals += 1
		end
		return visuals
	end
	local function createState(key: BasePart)
		local state = {key = key, held = false, amount = 0, from = 0, changed = os.clock(), visuals = makeVisuals(key), occupants = 0, ownPressed = false}
		states[key] = state
		return state
	end
	local function sample(player: Player, now: number, distance: number)
		local character, fresh, slots, canRetain = groundedFeet(player)
		local previous = contacts[player]
		if not character then contacts[player] = nil; return end
		if not previous or previous.character ~= character then previous = {character = character, feet = {}, keys = {}} end
		local feet, keys = {}, {}
		for name,key in fresh do
			if key:IsDescendantOf(candidate) then feet[name] = {key = key, last = now} end
		end
		-- Grace covers a missed support sample, not an extra old cell after the foot moves.
		for name,old in previous.feet do
			if not feet[name] and slots[name] and canRetain and old.key:IsDescendantOf(candidate) and now - old.last < Config.ContactGrace then feet[name] = old end
		end
		for _,foot in feet do keys[foot.key] = true end
		local own = player == localPlayer
		for key in keys do
			if not previous.keys[key] then
				totals.entries += 1
				if (own and now - ownAudioAt >= Config.OwnAudioInterval) or (not own and now - nearbyAudioAt >= Config.NearbyAudioInterval) then
					audio.Play(key:GetAttribute("KeyFamily"), "down", if own then Config.OwnVolume else Config.NearbyVolume * (1 - distance / Config.NearbyRadius), not own, key)
					if own then ownAudioAt = now else nearbyAudioAt = now end
				else totals.coalesced += 1 end
			end
		end
		contacts[player] = {character = character, feet = feet, keys = keys}
	end
	local controller
	local render = RunService.PreRender:Connect(function()
		if not candidate.Parent or not folder.Parent then controller.Stop(); return end
		if not audio.IsResolved() then return end
		local now = os.clock()
		if visualCamera ~= Workspace.CurrentCamera then
			visualCamera = Workspace.CurrentCamera
			for key,state in states do
				restore(state)
				if key:IsDescendantOf(candidate) then state.visuals = makeVisuals(key) end
			end
		end
		sample(localPlayer, now, 0)
		if now - nearbyAt >= .08 then
			nearbyAt = now
			local character = localPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			for _,player in Players:GetPlayers() do
				if player == localPlayer then continue end
				local other = player.Character
				local otherRoot = if other then other:FindFirstChild("HumanoidRootPart") else nil
				local distance = if root and root:IsA("BasePart") and otherRoot and otherRoot:IsA("BasePart") then (root.Position - otherRoot.Position).Magnitude else math.huge
				if distance < Config.NearbyRadius then sample(player, now, distance) else contacts[player] = nil end
			end
		end
		table.clear(occupied)
		table.clear(ownKeys)
		for player,contact in contacts do
			local humanoid = contact.character:FindFirstChildOfClass("Humanoid")
			if not player.Parent or player.Character ~= contact.character or not humanoid or humanoid.Health <= 0 then contacts[player] = nil; continue end
			for key in contact.keys do
				if key:IsDescendantOf(candidate) then
					occupied[key] = (occupied[key] or 0) + 1
					if player == localPlayer then ownKeys[key] = true end
				end
			end
		end
		for key,count in occupied do
			local state = states[key] or createState(key)
			state.occupants = count
			if not state.held then
				state.held, state.from, state.changed, state.ownPressed = true, state.amount, now, ownKeys[key] == true
			elseif ownKeys[key] then state.ownPressed = true end
		end
		for key,state in states do
			if not key:IsDescendantOf(candidate) then restore(state); states[key] = nil; continue end
			if not occupied[key] and state.held then
				state.held, state.from, state.changed, state.occupants = false, state.amount, now, 0
				totals.releases += 1
				local character = localPlayer.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				local distance = if root and root:IsA("BasePart") then (root.Position - key.Position).Magnitude else math.huge
				if distance < 8 then
					local last = if state.ownPressed then releaseAudioAt else nearbyAudioAt
					local interval = if state.ownPressed then Config.ReleaseAudioInterval else Config.NearbyAudioInterval
					if now - last >= interval then
						local volume = if state.ownPressed then Config.ReleaseVolume else Config.NearbyVolume * (Config.ReleaseVolume / Config.OwnVolume) * (1 - distance / Config.NearbyRadius)
						audio.Play(key:GetAttribute("KeyFamily"), "up", volume, not state.ownPressed, key)
						if state.ownPressed then releaseAudioAt = now else nearbyAudioAt = now end
					else totals.releaseCoalesced += 1 end
				end
			end
			local duration = if state.held then Config.PressAttack else Config.PressRelease
			local progress = math.clamp((now - state.changed) / duration, 0, 1)
			local eased = if state.held then 1 - (1 - progress) ^ 3 else progress * progress * (3 - 2 * progress)
			state.amount = state.from + ((if state.held then 1 else 0) - state.from) * eased
			local depth = key:GetAttribute("PressDepth") or Config.PressDepth
			for _,item in state.visuals do
				if not item.original:IsDescendantOf(candidate) then continue end
				local pose = item.original.CFrame
				if item.lastPose ~= pose or item.lastAmount ~= state.amount or item.lastDepth ~= depth then
					item.clone.CFrame = pose * CFrame.new(0, -depth * state.amount, 0)
					item.lastPose, item.lastAmount, item.lastDepth = pose, state.amount, depth
					totals.visualWrites += 1
				end
				if item.warning and item.clonedWarning then
					local transparency = item.warning.BackgroundTransparency
					if item.warningTransparency ~= transparency then
						item.clonedWarning.BackgroundTransparency = transparency
						item.warningTransparency = transparency
						totals.warningWrites += 1
					end
					if item.warningStroke and item.clonedStroke then
						local color = item.warningStroke.Color
						if item.warningColor ~= color then
							item.clonedStroke.Color = color
							item.warningColor = color
							totals.warningWrites += 1
						end
					end
				end
			end
			if not state.held and progress == 1 then restore(state); states[key] = nil end
		end
	end)
	local prompt = PromptService.PromptTriggered:Connect(function(trigger: ProximityPrompt)
		if audio.IsResolved() and trigger:IsDescendantOf(candidate) then
			local family = trigger:GetAttribute("AuditionFamily")
			if typeof(family) == "string" then audio.Audition(family) end
		end
	end)
	controller = {
		AwaitReady = audio.AwaitReady,
		Readiness = audio.Readiness,
		Diagnostics = function()
			local result = audio.Diagnostics()
			result.active, result.held = active, {}
			for name,value in totals do result.totals[name] = value end
			for key,state in states do table.insert(result.held, {key = key:GetFullName(), amount = state.amount, held = state.held, occupants = state.occupants, visuals = #state.visuals}) end
			return result
		end,
		Audition = function(family: string)
			if audio.IsResolved() then audio.Audition(family) end
		end,
		Stop = function()
			if not active then return end
			active = false
			running[candidate] = nil
			render:Disconnect(); prompt:Disconnect()
			for _,state in states do restore(state) end
			table.clear(states); table.clear(contacts); table.clear(occupied); table.clear(ownKeys)
			audio.Stop()
			folder:Destroy()
		end,
	}
	if RunService:IsStudio() then
		for name,callback in {Diagnostics = controller.Diagnostics, Audition = controller.Audition, StopFeedback = controller.Stop} do
			local probe = Instance.new("BindableFunction")
			probe.Name, probe.OnInvoke, probe.Parent = name, callback, folder
		end
	end
	running[candidate] = controller
	return controller
end

function Feedback.Get(candidate: Model)
	if running[candidate] then return running[candidate] end
	local folder = Players.LocalPlayer.PlayerGui:FindFirstChild("KeyboardCircuitAudition")
	local identity = if folder then folder:FindFirstChild("Candidate") else nil
	if not identity or not identity:IsA("ObjectValue") or identity.Value ~= candidate or not folder:FindFirstChild("Diagnostics") then return nil end
	return {
		AwaitReady = function(cancelled: (() -> boolean)?)
			while folder.Parent do
				local status = folder.Diagnostics:Invoke().readiness
				if status.state ~= "loading" then return status end
				if cancelled and cancelled() then status.state = "cancelled"; return status end
				task.wait(.05)
			end
			return {state = "stopped"}
		end,
		Readiness = function() return folder.Diagnostics:Invoke().readiness end,
		Diagnostics = function() return folder.Diagnostics:Invoke() end,
		Audition = function(family: string) folder.Audition:Invoke(family) end,
		Stop = function() if folder.Parent then folder.StopFeedback:Invoke() end end,
	}
end

return Feedback
