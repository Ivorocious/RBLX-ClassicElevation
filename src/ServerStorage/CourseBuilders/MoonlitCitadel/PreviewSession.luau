--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PreviewSession = {}
local activeRoots = setmetatable({}, {__mode = "k"})
local soundIds = {Car = "rbxassetid://78959704238630", Lantern = "rbxassetid://89163507250478"}

local function numberAttribute(instance, name, fallback)
	local value = instance:GetAttribute(name)
	assert(value == nil or (typeof(value) == "number" and value == value and math.abs(value) < math.huge), name .. " must be finite")
	return if value == nil then fallback else value
end

local function characterParts(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	return character, humanoid, root
end

local function recoveryFrame(part)
	local frame = part:GetAttribute("RecoveryCFrame")
	return if typeof(frame) == "CFrame" then frame else part.CFrame + Vector3.new(0, part.Size.Y / 2 + 4, 0)
end

local function visibleBodyPlayer(part)
	local character = part.Parent
	if not character or not character:IsA("Model") or part.Name == "HumanoidRootPart" or part.Transparency >= 1 then return nil end
	return Players:GetPlayerFromCharacter(character)
end

local function carProgress(elapsed, record)
	local t = math.max(0, elapsed - record.offset) % record.cycle
	local travelTime = (record.cycle - 2 * record.dwell) / 2
	if t < record.dwell then return 0, "LowDwell" end
	if t < record.dwell + travelTime then return (t - record.dwell) / travelTime, "Rising" end
	if t < record.dwell * 2 + travelTime then return 1, "HighDwell" end
	return 1 - (t - record.dwell * 2 - travelTime) / travelTime, "Descending"
end

local function supportedBy(character, humanoid, root, deck)
	local state = humanoid:GetState()
	if humanoid.Jump or state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then return false end
	if root.Anchored or humanoid.FloorMaterial == Enum.Material.Air then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.RespectCanCollide = true
	local distance = humanoid.HipHeight + root.Size.Y / 2 + 1
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), params)
	if not hit or hit.Instance ~= deck or hit.Normal:Dot(Vector3.yAxis) < 0.95 then return false end
	local localPoint = deck.CFrame:PointToObjectSpace(hit.Position)
	return math.abs(localPoint.X) <= deck.Size.X / 2 and math.abs(localPoint.Z) <= deck.Size.Z / 2
end

function PreviewSession.Start(rootModel: Model, options)
	assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(), "Moonlit preview requires Studio server Play")
	assert(rootModel:IsA("Model") and rootModel:IsDescendantOf(Workspace), "Preview root must be a Workspace Model")
	assert(rootModel.Name ~= "RaceCourse" and rootModel:GetAttribute("RuntimeActiveCourse") ~= true, "Use an isolated preview root")
	assert(not activeRoots[rootModel], "This preview root already has a session")
	options = options or {}
	local areas, cars, lanterns, hazards, sounds = {}, {}, {}, {}, {}
	local enrolled, connections = {}, {}
	local elapsed, stopped, scanTime = 0, false, 0
	local stats = {recoveries = 0, carriedSteps = 0, finishes = 0, maxLanternSweepSteps = 0}
	local function validateModel(model, contactName)
		assert(model:IsA("Model") and model.PrimaryPart and model.PrimaryPart.Name == contactName, model.Name .. " needs " .. contactName .. " PrimaryPart")
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then assert(part.Anchored, model.Name .. " parts must be anchored") end
		end
		return model.PrimaryPart
	end
	for _, name in {"RoughRoute", "UpperSample", "LanternStudy"} do
		local area = rootModel:FindFirstChild(name)
		assert(area, "Missing area " .. name)
		local start, finish, checkpoints = area:FindFirstChild("Start"), area:FindFirstChild("Finish"), area:FindFirstChild("Checkpoints")
		assert(start and start:IsA("BasePart") and finish and finish:IsA("BasePart") and checkpoints and checkpoints:IsA("Folder"), name .. " needs Start/Finish/Checkpoints")
		local center, size = area:GetAttribute("BoundsCenter"), area:GetAttribute("BoundsSize")
		assert(typeof(center) == "Vector3" and typeof(size) == "Vector3" and math.min(size.X, size.Y, size.Z) > 0, name .. " needs valid bounds")
		local ordered = {}
		for _, cp in checkpoints:GetChildren() do
			if cp:IsA("BasePart") then table.insert(ordered, cp) end
		end
		table.sort(ordered, function(a, b) return numberAttribute(a, "CheckpointIndex", 0) < numberAttribute(b, "CheckpointIndex", 0) end)
		for index, cp in ordered do assert(cp:GetAttribute("CheckpointIndex") == index, name .. " checkpoints must be numbered from 1") end
		assert(typeof(area:GetAttribute("FallY")) == "number", name .. " needs FallY")
		areas[name] = {root = area, start = start, finish = finish, checkpoints = ordered, center = center, size = size, fallY = numberAttribute(area, "FallY", 0)}
	end
	for _, folder in rootModel:GetDescendants() do
		if folder:IsA("Folder") and folder.Name == "MovingCars" then
			for _, model in folder:GetChildren() do
				if not model:IsA("Model") then continue end
				local deck = validateModel(model, "Deck")
				local travel = model:GetAttribute("Travel")
				assert(typeof(travel) == "Vector3" and travel.X == 0 and travel.Z == 0 and travel.Y > 0, model.Name .. " needs vertical upward Travel")
				assert(deck.CanCollide and deck.CanQuery and deck.CFrame.UpVector:Dot(Vector3.yAxis) > 0.999, model.Name .. " needs a level colliding Deck")
				local cycle, dwell = numberAttribute(model, "CycleSeconds", 14), numberAttribute(model, "DwellSeconds", 2)
				assert(dwell >= 0 and cycle > 2 * dwell, "Car cycle must contain travel time")
				local weightReference = model:FindFirstChild("Counterweight")
				local weight = if weightReference and weightReference:IsA("ObjectValue") then weightReference.Value else nil
				if weight then assert(weight:IsA("Model") and weight.PrimaryPart and weight:IsDescendantOf(rootModel) and not weight:IsDescendantOf(model), "Weight must be a separate scoped model"); validateModel(weight, weight.PrimaryPart.Name) end
				local contacts = {}
				for _, part in model:GetDescendants() do if part:IsA("BasePart") and part.CanCollide then table.insert(contacts, part) end end
				table.insert(cars, {model = model, deck = deck, contacts = contacts, start = model:GetPivot(), travel = travel, cycle = cycle, dwell = dwell,
					offset = math.max(0, numberAttribute(model, "PhaseSeconds", 0)), weight = weight, weightStart = weight and weight:GetPivot(), passengers = 0, phase = "LowDwell"})
			end
		elseif folder:IsA("Folder") and folder.Name == "SwingLanterns" then
			for _, model in folder:GetChildren() do
				if not model:IsA("Model") then continue end
				local cage = validateModel(model, "CageContact")
				local pivot, rest = model:GetAttribute("PivotPosition"), model:GetAttribute("RestCFrame")
				local visibleCage=model:FindFirstChild("CageAndCore")
				assert(typeof(pivot) == "Vector3" and cage.CanQuery and visibleCage, "Lantern needs pivot and visible cage geometry")
				local visibleParts = {}
				for _, part in visibleCage:GetDescendants() do
					if part:IsA("BasePart") then table.insert(visibleParts, part) end
				end
				for _, part in model:GetDescendants() do if part:IsA("BasePart") then assert(not part.CanCollide, "Lantern must recover without physical fling") end end
				local cycle = numberAttribute(model, "CycleSeconds", 6)
				assert(cycle > 0, "Lantern cycle must be positive")
				local axis = model:GetAttribute("SwingAxis") or Vector3.zAxis
				assert(typeof(axis) == "Vector3" and axis.Magnitude > .99 and axis.Magnitude < 1.01, "Lantern needs a unit swing axis")
				table.insert(lanterns, {model = model, cage = cage, start = model:GetPivot(), rest = if typeof(rest) == "CFrame" then rest else model:GetPivot(),
					visibleParts=visibleParts, pivot = pivot, axis = axis.Unit, angle = math.rad(numberAttribute(model, "SwingAngleDegrees", 32)), cycle = cycle, offset = math.max(0, numberAttribute(model, "PhaseSeconds", 0))})
			end
		elseif folder:IsA("BasePart") and folder:GetAttribute("PreviewHazard") == true then
			assert(folder.CanQuery, "PreviewHazard must be queryable")
			table.insert(hazards, folder)
		end
	end
	local session = {}
	local function teleport(player, frame)
		local character, _, root = characterParts(player)
		if not character then return false end
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		character:PivotTo(frame)
		return true
	end
	local function recover(player, reason, force)
		local progress = enrolled[player]
		if not progress or (not force and elapsed < progress.immuneUntil) then return end
		if teleport(player, progress.recovery) then
			progress.immuneUntil, progress.lastRecovery, progress.recoveries = elapsed + 0.75, reason, progress.recoveries + 1
			stats.recoveries += 1
		end
	end
	local function overlapParameters()
		local characters = {}
		for player in enrolled do
			if player.Parent ~= Players then enrolled[player] = nil
			elseif player.Character then table.insert(characters, player.Character) end
		end
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, characters
		return params, #characters
	end
	local function scanHazard(part, params, reason)
		for _, hit in Workspace:GetPartsInPart(part, params) do
			local player = visibleBodyPlayer(hit)
			if player then recover(player, reason) end
		end
	end
	local function addSound(part, id, volume, speed)
		if options.SoundEnabled == false then return nil end
		local sound = Instance.new("Sound")
		sound.Name, sound.SoundId, sound.Volume, sound.PlaybackSpeed = "MoonlitPreviewCue", id, volume, speed
		sound.Looped, sound.RollOffMaxDistance, sound.RollOffMinDistance = true, 50, 6
		sound.Parent = part
		table.insert(sounds, sound)
		return sound
	end
	for _, hazard in hazards do
		table.insert(connections, hazard.Touched:Connect(function(hit)
			local player = visibleBodyPlayer(hit)
			if not player or not enrolled[player] then return end
			local params = OverlapParams.new()
			params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {hit}
			if #Workspace:GetPartsInPart(hazard, params) > 0 then recover(player, "RedContact") end
		end))
	end
	for _, record in cars do record.sound = addSound(record.deck, soundIds.Car, 0.10, 0.65) end
	for _, record in lanterns do record.sound = addSound(record.cage, soundIds.Lantern, 0.12, 0.75) end
	function session:Enter(player: Player, areaName: string)
		assert(not stopped and player:IsA("Player") and player.Parent == Players, "Valid Studio player required")
		local area = areas[areaName]
		assert(area, "Unknown preview area")
		if not teleport(player, recoveryFrame(area.start)) then return false end
		enrolled[player] = {area = area, areaName = areaName, checkpoint = 0, recovery = recoveryFrame(area.start), immuneUntil = elapsed + 0.75, recoveries = 0, finished = false, character = player.Character}
		return true
	end
	local function restoreTransforms()
		for _, record in cars do
			record.model:PivotTo(record.start)
			for _, part in record.contacts do part.AssemblyLinearVelocity = Vector3.zero end
			if record.weight then record.weight:PivotTo(record.weightStart) end
			record.passengers, record.phase = 0, "LowDwell"
		end
		for _, record in lanterns do record.model:PivotTo(record.start) end
		for _, sound in sounds do sound:Stop() end
	end
	function session:Reset()
		assert(not stopped, "Session stopped")
		elapsed, scanTime = 0, 0
		restoreTransforms()
		for player, progress in enrolled do self:Enter(player, progress.areaName) end
	end
	function session:Stop()
		if stopped then return end
		stopped = true
		for _, connection in connections do connection:Disconnect() end
		restoreTransforms()
		for _, sound in sounds do sound:Destroy() end
		table.clear(enrolled)
		activeRoots[rootModel] = nil
	end
	function session:GetReport()
		local report = {running = not stopped, elapsed = elapsed, stats = table.clone(stats), players = {}, cars = {}, sounds = {}}
		for player, progress in enrolled do table.insert(report.players, {userId = player.UserId, area = progress.areaName, checkpoint = progress.checkpoint, finished = progress.finished, recoveries = progress.recoveries, lastRecovery = progress.lastRecovery}) end
		for _, record in cars do table.insert(report.cars, {name = record.model:GetFullName(), phase = record.phase, passengers = record.passengers, cycle = record.cycle, dwell = record.dwell}) end
		for _, sound in sounds do table.insert(report.sounds, {id = sound.SoundId, loaded = sound.IsLoaded, playing = sound.IsPlaying, timePosition = sound.TimePosition}) end
		return report
	end
	activeRoots[rootModel] = session
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not rootModel:IsDescendantOf(Workspace) then session:Stop(); return end
		local previousTime = elapsed
		elapsed += dt
		for _, record in cars do
			local riders = {}
			for player in enrolled do
				local character, humanoid, root = characterParts(player)
				if character and supportedBy(character, humanoid, root, record.deck) then table.insert(riders, {character = character, root = root}) end
			end
			local alpha, phase = carProgress(elapsed, record)
			local target = record.start + record.travel * alpha
			local current = record.model:GetPivot()
			local delta = target * current:Inverse()
			local displacement = target.Position - current.Position
			local carryParams = RaycastParams.new()
			carryParams.FilterType, carryParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
			local safeRiders = {}
			for _, rider in riders do
				local exclusions = {rider.character, record.model}
				if record.weight then table.insert(exclusions, record.weight) end
				carryParams.FilterDescendantsInstances = exclusions
				local bodyFrame, bodySize = rider.character:GetBoundingBox()
				local overlap = OverlapParams.new()
				overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, exclusions
				local blocked = false
				if displacement.Magnitude > 0.001 then
					blocked = Workspace:Blockcast(bodyFrame, bodySize, displacement, carryParams) ~= nil
					for _, part in Workspace:GetPartBoundsInBox(delta * bodyFrame, bodySize * 0.98, overlap) do
						if part.CanCollide then blocked = true; break end
					end
				end
				if blocked then
					local player = Players:GetPlayerFromCharacter(rider.character)
					if player then recover(player, "BlockedCarCarry", true) end
				else table.insert(safeRiders, rider) end
			end
			if displacement.Magnitude > 0 then record.model:PivotTo(target) end
			-- Floor velocity lets ordinary character physics follow the anchored deck without repeated character teleports.
			local velocity = if dt > 0 then displacement / dt else Vector3.zero
			for _, part in record.contacts do
				if part.AssemblyLinearVelocity ~= velocity then part.AssemblyLinearVelocity = velocity end
			end
			if record.weight and displacement.Magnitude > 0 then record.weight:PivotTo(record.weightStart - record.travel * alpha) end
			record.phase, record.passengers = phase, #safeRiders
			for _, rider in safeRiders do
				stats.carriedSteps += 1
			end
			if record.sound then
				local moving = phase == "Rising" or phase == "Descending"
				if moving and not record.sound.IsPlaying then record.sound:Play() elseif not moving then record.sound:Stop() end
			end
		end
		local params, count = overlapParameters()
		for _, record in lanterns do
			local radius = (record.rest.Position - record.pivot).Magnitude + record.cage.Size.Magnitude / 2
			local steps = math.clamp(math.ceil(dt * 2 * math.pi / record.cycle * math.abs(record.angle) * radius / 0.5), 1, 64)
			stats.maxLanternSweepSteps = math.max(stats.maxLanternSweepSteps, steps)
			for step = 1, steps do
				local t = math.max(0, previousTime + dt * step / steps - record.offset)
				local angle = math.sin(t * 2 * math.pi / record.cycle) * record.angle
				record.model:PivotTo(CFrame.new(record.pivot) * CFrame.fromAxisAngle(record.axis, angle) * CFrame.new(-record.pivot) * record.rest)
				if count > 0 and #Workspace:GetPartBoundsInBox(record.cage.CFrame,record.cage.Size+Vector3.one*.04,params)>0 then
					for _, part in record.visibleParts do scanHazard(part, params, "LanternCage") end
				end
			end
			if record.sound and not record.sound.IsPlaying then record.sound:Play() end
		end
		scanTime += dt
		if scanTime < 0.08 then return end
		scanTime = 0
		if count > 0 then for _, hazard in hazards do scanHazard(hazard, params, "RedContact") end end
		for player, progress in enrolled do
			local character, _, root = characterParts(player)
			if not character then continue end
			if progress.character ~= character then
				progress.character = character
				teleport(player, progress.recovery)
				progress.immuneUntil = elapsed + 0.75
			end
			local area = progress.area
			local offset = root.Position - area.center
			if root.Position.Y < area.fallY or math.abs(offset.X) > area.size.X / 2 or math.abs(offset.Y) > area.size.Y / 2 or math.abs(offset.Z) > area.size.Z / 2 then recover(player, "FallBounds"); continue end
			local playerParams = OverlapParams.new()
			playerParams.FilterType, playerParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {character}
			local nextCheckpoint = area.checkpoints[progress.checkpoint + 1]
			if nextCheckpoint and #Workspace:GetPartsInPart(nextCheckpoint, playerParams) > 0 then
				progress.checkpoint += 1
				local frame = nextCheckpoint:GetAttribute("RecoveryCFrame")
				progress.recovery = if typeof(frame) == "CFrame" then frame else recoveryFrame(area.start)
			end
			if not progress.finished and progress.checkpoint == #area.checkpoints and #Workspace:GetPartsInPart(area.finish, playerParams) > 0 then progress.finished = true; stats.finishes += 1 end
		end
	end))
	return session
end

return PreviewSession
