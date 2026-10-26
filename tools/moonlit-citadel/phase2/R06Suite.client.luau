--!nonstrict
-- Install only in the unpublished owned fixture, with the matching existing shared-flow tools.
local Players, RunService, HttpService = game:GetService("Players"), game:GetService("RunService"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 0 and game.GameId == 0)
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
assert(Config.CandidateId == "MC_P2_C01_R06", "This draft must not produce R05-labelled evidence")
local tools = game.ReplicatedStorage:WaitForChild("MoonlitPhase2Tools")
local Suite, Probe = require(tools.R06ClientSuite), require(tools.R06ClientProbe)
local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "MC_P2_C01_R06_Verification", player:WaitForChild("PlayerGui")
folder:SetAttribute("OwnedMoonlitTest", true)
local observed = {candidate = Config.CandidateId, evidenceKind = "Independent actual client airborne observation",
	limits = "Airborne observations do not prove jumps are physically required or establish human pacing.", flights = {}}
local airborne, currentFlight, sampleConnection = false, nil, nil
local function xyz(v) return {v.X, v.Y, v.Z} end
local function bodyEnvelope(character, root)
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	local count = 0
	for _, part in character:GetChildren() do
		if not part:IsA("BasePart") or part.Name == "HumanoidRootPart" or part.Transparency >= 1 or not part.CanQuery then continue end
		count += 1
		for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
			local point = root.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2))
			low = Vector3.new(math.min(low.X, point.X), math.min(low.Y, point.Y), math.min(low.Z, point.Z))
			high = Vector3.new(math.max(high.X, point.X), math.max(high.Y, point.Y), math.max(high.Z, point.Z))
		end end end
	end
	return {low = xyz(low), high = xyz(high), count = count, at = workspace:GetServerTimeNow(), root = xyz(root.Position)}
end
local function save(name, value)
	local encoded = HttpService:JSONEncode(value)
	local count = math.ceil(#encoded / 140000)
	for index = 1, count do
		local key = name .. string.format("_%03d", index)
		local item = folder:FindFirstChild(key) or Instance.new("StringValue")
		item.Name, item.Value, item.Parent = key, encoded:sub((index-1)*140000+1, index*140000), folder
	end
	folder:SetAttribute(name .. "Chunks", count)
	folder:SetAttribute(name .. "Bytes", #encoded)
end
local ok, reason = xpcall(function()
	local deadline = os.clock() + 660
	repeat
		assert(os.clock() < deadline, "R06 readiness timeout")
		assert(not tools:GetAttribute("R06VerificationFailure"), tools:GetAttribute("R06VerificationFailure"))
		task.wait(.1)
	until tools:GetAttribute("R06VerificationReady") and player:GetAttribute("ArrivalPhase") == "Ready"
		and player:GetAttribute("ArrivalOpen") == false
	local schedule = {{name="NNN"}, {name="NNE"}, {name="NEN"}, {name="NEE"},
		{name="ENN"}, {name="ENE"}, {name="EEN"}, {name="EEE"}}
	folder:SetAttribute("ReadyAt", workspace:GetServerTimeNow())
	sampleConnection = RunService.Heartbeat:Connect(function()
		local trial = Probe.Current()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not trial or trial.state ~= "Running" or not humanoid or not root then return end
		local air = humanoid.FloorMaterial == Enum.Material.Air
		local now = workspace:GetServerTimeNow()
		if air and not airborne then
			currentFlight = {raceId = trial.raceId, section = trial.section, start = now,
				takeoff = xyz(root.Position), positiveVerticalTakeoff = root.AssemblyLinearVelocity.Y > 1,
				apexY = root.Position.Y, samples = 0}
			table.insert(observed.flights, currentFlight)
		elseif not air and airborne and currentFlight then
			currentFlight.endedAt, currentFlight.landing = now, xyz(root.Position)
			currentFlight.duration = now - currentFlight.start
			currentFlight = nil
		end
		if currentFlight then
			if root.Position.Y >= currentFlight.apexY then
				currentFlight.apexY = root.Position.Y
				currentFlight.apexBody = bodyEnvelope(character, root)
			end
			currentFlight.samples += 1
		end
		airborne = air
	end)
	Suite.Start(schedule, {watchdogSeconds = 3600, goalTolerance = .25})
	while true do
		local suite, trial = Suite.Current(), Probe.Current()
		save("Suite", suite); save("Airborne", observed)
		if trial then save("Trial", trial) end
		folder:SetAttribute("State", suite.state)
		folder:SetAttribute("CurrentTrial", suite.currentTrial)
		folder:SetAttribute("CompletedTrials", #suite.trials)
		if suite.state == "Complete" or suite.state == "Failed" then break end
		task.wait(1)
	end
end, debug.traceback)
if sampleConnection then sampleConnection:Disconnect() end
if not ok then folder:SetAttribute("Failure", tostring(reason)); Suite.Stop(tostring(reason)); warn(reason) end
