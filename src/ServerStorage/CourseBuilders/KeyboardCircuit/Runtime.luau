--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(script.Parent:FindFirstChild("ConfigSnapshot") or game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig)
local Clock = require(script.Parent.Parent.StudGarden.HazardClock)
local DropState = require(script.Parent.DropState)
local Runtime = {}

function Runtime.Start(candidate: Model, eligible: (Player) -> boolean, recover: (Player, string) -> boolean)
	assert(RunService:IsServer(), "Keyboard Circuit contact and motion must run on the server")
	assert(candidate:GetAttribute("Phase1Only") == true, "Isolated Phase 1 candidate required")
	local sample = candidate.S02_ThockySwitchworks
	local foundry = sample.H04_FallingKeyFoundry
	local drops = {}
	for i = 1, 3 do
		local model = foundry["Drop" .. i]
		local contacts = {}
		for _,part in model:GetDescendants() do if part:IsA("BasePart") and part:GetAttribute("Role") == "Lethal" then table.insert(contacts, part) end end
		local warnings = {}
		for _,key in foundry.CrossingBank:GetChildren() do
			if key:GetAttribute("DropWarningIndex") == i then table.insert(warnings, key.Legend.DropWarning) end
		end
		table.insert(drops, {model = model, shapes = contacts, start = model:GetPivot(), warning = foundry["Warning" .. i], warningFrames = warnings, offset = model:GetAttribute("CycleOffset"), wasWarning = nil, lastState = nil})
	end
	local sliders = {sample.H05_SpringLift, candidate.H06_EarlyProof.H06_CarriageShuttle}
	local starts = {}
	for _,unit in sliders do
		local bank = unit.RideableBank
		starts[unit] = bank:GetPivot()
		for _,v in bank:GetDescendants() do if v:IsA("BasePart") then v.Anchored = false end end
		bank.PrimaryPart:SetNetworkOwner(nil)
		unit.Slider.Enabled = true
	end
	local lift, shuttle = sliders[1], sliders[2]
	lift.Slider.Speed, shuttle.Slider.Speed = Config.LiftSpeed, 6
	local boardingRay = RaycastParams.new()
	boardingRay.FilterType, boardingRay.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {lift.RideableBank}
	boardingRay.RespectCanCollide = true
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.RespectCanCollide = false
	local clock = Clock.New(Workspace:GetServerTimeNow())
	local characters = {}
	local warningColor, idleWarningColor = Color3.fromRGB(255, 215, 38), Color3.fromRGB(157, 126, 40)
	local active, contacts, bodyChecks, pivotCalls, stationarySweeps, movingSweeps = true, 0, 0, 0, 0, 0
	local liftState, liftAt = "Waiting", 0
	local lastLiftState, lastLiftBoarding, lastLiftExit, lastShuttleBoarding, lastShuttleExit
	local connection: RBXScriptConnection
	local function onBody(body: BasePart)
		if body:FindFirstAncestorWhichIsA("Accessory") then return end
		local character = body:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if player and eligible(player) and recover(player, "FoundryContact") then contacts += 1 end
	end
	local function checkShapes(drop)
		if #characters == 0 then return end
		for _,shape in drop.shapes do
			for _,body in Workspace:GetPartsInPart(shape, params) do onBody(body) end
			bodyChecks += 1
		end
	end
	connection = RunService.Heartbeat:Connect(function()
		local old, now, advanced = Clock.Step(clock, Workspace:GetServerTimeNow())
		if not advanced then return end
		table.clear(characters)
		local players = Players:GetPlayers()
		for _,player in players do if eligible(player) and player.Character then table.insert(characters, player.Character) end end
		params.FilterDescendantsInstances = characters
		for _,drop in drops do
			local state, alpha = DropState.Get(now, drop.offset, Config)
			local isWarning = state == "Warning"
			if isWarning ~= drop.wasWarning then
				drop.wasWarning = isWarning
				drop.warning.Color = if isWarning then warningColor else idleWarningColor
				for _,frame in drop.warningFrames do
					frame.BackgroundTransparency = if isWarning then .45 else 1
					frame.UIStroke.Color = drop.warning.Color
				end
			end
			if state ~= drop.lastState then drop.lastState = state; drop.model:SetAttribute("CycleState", state) end
			local previous = drop.model:GetPivot()
			local destination = drop.start * CFrame.new(0, -Config.DropDistance * alpha, 0)
			if previous == destination then
				stationarySweeps += 1
				checkShapes(drop)
			else
				movingSweeps += 1
				local distance = (destination.Position - previous.Position).Magnitude
				local steps = math.max(1, math.ceil(distance / .35))
				for step = 0, steps do
					drop.model:PivotTo(previous:Lerp(destination, step / steps))
					pivotCalls += 1
					checkShapes(drop)
				end
			end
		end
		if lift.Slider.Speed ~= Config.LiftSpeed then lift.Slider.Speed = Config.LiftSpeed end
		if liftState == "Waiting" then
			for _,player in players do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
				if eligible(player) and root and root:IsA("BasePart") and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air and Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), boardingRay) then liftState, liftAt = "Boarding", now; break end
			end
		elseif liftState == "Boarding" and now - liftAt >= Config.LiftBoardDwell then liftState, liftAt = "Rising", now
		elseif liftState == "Rising" and math.abs(lift.Slider.CurrentPosition - 8) < .2 then liftState, liftAt = "HighDwell", now
		elseif liftState == "HighDwell" and now - liftAt >= Config.LiftHighDwell then liftState, liftAt = "Returning", now
		elseif liftState == "Returning" and math.abs(lift.Slider.CurrentPosition) < .2 then liftState, liftAt = "Waiting", now end
		local liftTarget = if liftState == "Rising" or liftState == "HighDwell" then 8 else 0
		if lift.Slider.TargetPosition ~= liftTarget then lift.Slider.TargetPosition = liftTarget end
		if liftState ~= lastLiftState then lastLiftState = liftState; lift:SetAttribute("CycleState", liftState) end
		local liftBoarding, liftExit = liftState == "Waiting" or liftState == "Boarding", liftState == "HighDwell"
		if liftBoarding ~= lastLiftBoarding then lastLiftBoarding = liftBoarding; lift:SetAttribute("BoardingWindow", liftBoarding) end
		if liftExit ~= lastLiftExit then lastLiftExit = liftExit; lift:SetAttribute("ExitWindow", liftExit) end
		local shuttleTime = now % Config.ShuttlePeriod
		if shuttle.Slider.Speed ~= 6 then shuttle.Slider.Speed = 6 end
		local shuttleTarget = if shuttleTime >= Config.ShuttleDepart and shuttleTime < Config.ShuttleReturn then 24 else 0
		if shuttle.Slider.TargetPosition ~= shuttleTarget then shuttle.Slider.TargetPosition = shuttleTarget end
		local shuttlePosition = shuttle.Slider.CurrentPosition
		local shuttleBoarding, shuttleExit = math.abs(shuttlePosition) < .2, math.abs(shuttlePosition - 24) < .2
		if shuttleBoarding ~= lastShuttleBoarding then lastShuttleBoarding = shuttleBoarding; shuttle:SetAttribute("BoardingWindow", shuttleBoarding) end
		if shuttleExit ~= lastShuttleExit then lastShuttleExit = shuttleExit; shuttle:SetAttribute("ExitWindow", shuttleExit) end
		candidate:SetAttribute("KCElapsed", now)
	end)
	local controller = {}
	function controller.Diagnostics()
		return {active = active, elapsed = clock.elapsed, contacts = contacts, bodyChecks = bodyChecks, pausedStalls = clock.pausedStalls,
			pivotCalls = pivotCalls, stationarySweeps = stationarySweeps, movingSweeps = movingSweeps,
			liftPosition = sliders[1].Slider.CurrentPosition, shuttlePosition = sliders[2].Slider.CurrentPosition}
	end
	function controller.Stop()
		if not active then return end
		active = false
		connection:Disconnect()
		for _,unit in sliders do
			local bank = unit.RideableBank
			local ray = RaycastParams.new()
			ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {bank}
			for _,player in Players:GetPlayers() do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if eligible(player) and root and root:IsA("BasePart") and Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), ray) then recover(player, "MechanismStop") end
			end
			unit.Slider.Enabled = false
			for _,v in bank:GetDescendants() do if v:IsA("BasePart") then v.Anchored = true; v.AssemblyLinearVelocity = Vector3.zero; v.AssemblyAngularVelocity = Vector3.zero end end
			bank:PivotTo(starts[unit])
			unit.Slider.TargetPosition = 0
			unit:SetAttribute("CycleState", "Stopped")
			unit:SetAttribute("BoardingWindow", false)
			unit:SetAttribute("ExitWindow", false)
		end
		for _,drop in drops do drop.model:PivotTo(drop.start); drop.model:SetAttribute("CycleState", "Stopped") end
		candidate:SetAttribute("KCElapsed", 0)
	end
	return controller
end

return Runtime

