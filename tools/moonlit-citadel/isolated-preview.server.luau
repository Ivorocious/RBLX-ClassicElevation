--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

assert(RunService:IsStudio() and RunService:IsServer(), "Moonlit fixture requires a local Studio server")
assert(game.PlaceId == 0 and game.GameId == 0, "Moonlit fixture refuses published place/universe identities")

local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local Preview = require(game.ServerStorage.CourseBuilders.MoonlitCitadel.PreviewSession)
local root = workspace:WaitForChild(Config.BlenderRootName, 15)
assert(root and root:IsA("Model"), "Saved Moonlit Blender sample is missing")
assert(root:GetAttribute("CandidateId") == Config.BlenderCandidateId and root:GetAttribute("PreviewOnly") == true,
	"This fixture requires the commissioned Blender preview sample")

local connections, watched = {}, {}
local session, selectedPlayer
local reportElapsed = 0

local function publish()
	if session then root:SetAttribute("PreviewReport", HttpService:JSONEncode(session:GetReport())) end
end

local function clearVelocity(player)
	local character = player.Character
	if not character then return end
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
	end
end

local function stop()
	if session then session:Stop() end
	for _, player in Players:GetPlayers() do clearVelocity(player) end
	root:SetAttribute("PreviewState", "Stopped")
	publish()
end

local function fail(reason)
	if session then pcall(function() session:Stop() end) end
	for _, player in Players:GetPlayers() do clearVelocity(player) end
	root:SetAttribute("PreviewState", "Failed")
	root:SetAttribute("PreviewFailure", tostring(reason))
	pcall(publish)
	warn("Moonlit isolated fixture: " .. tostring(reason))
end

local function requestedArea()
	local name = root:GetAttribute("RequestedArea") or "UpperSample"
	assert(name == "UpperSample" or name == "RoughRoute" or name == "LanternStudy", "Unknown RequestedArea")
	return name
end

local function prepareCharacter(player)
	local deadline = os.clock() + 20
	while player.Parent == Players and os.clock() < deadline do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local bodyRoot = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and bodyRoot and bodyRoot:IsA("BasePart") then
			humanoid.WalkSpeed, humanoid.UseJumpPower, humanoid.JumpHeight, humanoid.MaxSlopeAngle = 16, false, 7.2, 89
			return true
		end
		task.wait(0.05)
	end
	error("Real player character did not become ready: " .. player.Name)
end

local function watch(player)
	if watched[player] then return end
	watched[player] = true
	table.insert(connections, player.CharacterAdded:Connect(function()
		task.spawn(function()
			local ok, reason = pcall(prepareCharacter, player)
			if not ok then fail(reason) end
		end)
	end))
end

local function start()
	assert(selectedPlayer and selectedPlayer.Parent == Players, "No selected real player")
	prepareCharacter(selectedPlayer)
	if not session or root:GetAttribute("PreviewState") ~= "Running" then session = Preview.Start(root) end
	assert(session:Enter(selectedPlayer, requestedArea()), "Preview player entry failed")
	root:SetAttribute("PreviewFailure", nil)
	root:SetAttribute("PreviewState", "Running")
	publish()
end

local ok, reason = xpcall(function()
	workspace.Gravity = 196.2
	game.Lighting.ClockTime = 14.5
	root:SetAttribute("FixtureScope", "Local unpublished Studio sample; shared race flow is absent")
	root:SetAttribute("FixturePlaceId", game.PlaceId)
	root:SetAttribute("FixtureUniverseId", game.GameId)
	root:SetAttribute("PreviewEnabled", true)
	root:SetAttribute("PreviewFailure", nil)
	root:SetAttribute("PreviewState", "WaitingForPlayer")
	root:SetAttribute("RequestedArea", requestedArea())
	local sampleStart = root.UpperSample:FindFirstChild("Start")
	assert(sampleStart and sampleStart:IsA("BasePart"), "Upper sample start is missing")
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.CFrame = "IsolatedPreviewSpawn", Vector3.new(1, 0.2, 1), sampleStart.CFrame
	spawn.Anchored, spawn.Transparency, spawn.CanCollide, spawn.CanTouch, spawn.CanQuery = true, 1, false, false, false
	spawn.Neutral, spawn.Duration = true, 0
	spawn.Parent = workspace

	selectedPlayer = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	watch(selectedPlayer)
	prepareCharacter(selectedPlayer)
	start()
	for _, player in Players:GetPlayers() do
		watch(player)
		if player ~= selectedPlayer then prepareCharacter(player); assert(session:Enter(player, requestedArea())) end
	end
	table.insert(connections, Players.PlayerAdded:Connect(function(player)
		watch(player)
		task.spawn(function()
			local accepted, entryReason = pcall(function()
				prepareCharacter(player)
				if root:GetAttribute("PreviewState") == "Running" then assert(session:Enter(player, requestedArea())) end
			end)
			if not accepted then fail(entryReason) end
		end)
	end))
	table.insert(connections, root:GetAttributeChangedSignal("PreviewCommand"):Connect(function()
		local accepted, commandReason = xpcall(function()
			local command = root:GetAttribute("PreviewCommand")
			if command == "Stop" then stop()
			elseif command == "Reset" then assert(root:GetAttribute("PreviewState") == "Running", "Start preview before Reset"); session:Reset(); publish()
			elseif command == "Enter" then
				selectedPlayer = Players:GetPlayers()[1]
				start()
			end
		end, debug.traceback)
		root:SetAttribute("PreviewCommand", nil)
		if not accepted then fail(commandReason) end
	end))
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		reportElapsed += dt
		if reportElapsed < 0.2 or root:GetAttribute("PreviewState") ~= "Running" then return end
		reportElapsed = 0
		local accepted, reportReason = pcall(publish)
		if not accepted then fail(reportReason) end
	end))
	table.insert(connections, script.Destroying:Connect(function()
		stop()
		for _, connection in connections do connection:Disconnect() end
	end))
end, debug.traceback)
if not ok then fail(reason) end
