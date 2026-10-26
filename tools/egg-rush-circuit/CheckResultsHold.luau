local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819)
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "EggRushService", "CheckpointService"} do
	services[name] = require(game.ServerScriptService.Services[name])
end
local receipt = Instance.new("StringValue")
receipt.Name = "EggRushResultsHoldReceipt"
receipt.Parent = game.ServerStorage
local report = {ok = false, limits = "One actual racer placed on the far-end tray before Studio EndRace; observes Results support, not full race or crowd behavior"}
local root, humanoid, owner, automatic, moveConnection
local ok, failure = xpcall(function()
	local course = assert(services.CourseService.GetActiveCourse())
	assert(course:GetAttribute("EROwned") and course:GetAttribute("CourseId") == "egg_rush_circuit" and services.RaceService.IsRaceActive())
	local player = assert(game.Players:GetPlayers()[1])
	local character = assert(player.Character)
	root, humanoid = character.HumanoidRootPart, character:FindFirstChildOfClass("Humanoid")
	owner, automatic = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
	root:SetNetworkOwner(nil)
	moveConnection = RunService.PreSimulation:Connect(function() humanoid:Move(Vector3.zero, false); humanoid.Jump = false end)
	local tray = course.Obstacles.Mechanisms.SidewaysTray
	local deck = tray.TrayContact
	local deadline = os.clock() + 15
	repeat RunService.Heartbeat:Wait() until tray:GetAttribute("ERState") == "Exit" or os.clock() > deadline
	assert(tray:GetAttribute("ERState") == "Exit", "No far-end tray window")
	assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, 2))
	local top = deck.Position + Vector3.new(0, deck.Size.Y/2, 0)
	local setup = top + Vector3.new(0, humanoid.HipHeight + root.Size.Y/2 + .15, 0)
	report.setup = {kind = "InitialTeleport", position = {setup.X, setup.Y, setup.Z}, inspectionCheckpoint = 2}
	character:PivotTo(CFrame.new(setup))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
	local function support()
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y/2 + .7), 0), params)
		return hit and hit.Instance
	end
	local stable = 0
	deadline = os.clock() + 1
	repeat
		RunService.Heartbeat:Wait()
		stable = if support() == deck and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < 2 then stable + 1 else 0
	until stable >= 2 or os.clock() > deadline
	assert(stable >= 2 and tray:GetAttribute("ERState") == "Exit", "Tray setup did not settle in the far-end window")
	local before = deck.CFrame
	assert(services.RaceService.ApplyStudioAction("EndRace"))
	deadline = os.clock() + 1
	repeat RunService.Heartbeat:Wait() until services.EggRushService.GetDiagnostics().holding or os.clock() > deadline
	local first = services.EggRushService.GetDiagnostics()
	assert(first.holding and services.RaceService.GetRaceState() == "Results", "Results did not hold mechanisms")
	report.samples = {}
	local began = os.clock()
	repeat
		RunService.Heartbeat:Wait()
		local diagnostics = services.EggRushService.GetDiagnostics()
		local positionError = (deck.Position - before.Position).Magnitude
		local _, angle = (deck.CFrame.Rotation * before.Rotation:Inverse()):ToAxisAngle()
		assert(diagnostics.holding and diagnostics.stats.frames == first.stats.frames, "Mechanism clock advanced during Results")
		assert(positionError < .001 and math.abs(angle) < .0001 and deck.AssemblyLinearVelocity.Magnitude < .001, "Occupied tray moved/reset during Results")
		assert(support() == deck and humanoid.FloorMaterial ~= Enum.Material.Air, "Results removed rider support")
		table.insert(report.samples, {seconds = os.clock() - began, support = support():GetFullName(), positionError = positionError,
			velocity = deck.AssemblyLinearVelocity.Magnitude, rootY = root.Position.Y, status = services.PlayerRaceService.GetPlayerStatus(player)})
	until os.clock() - began >= .75
	report.candidateId, report.userId, report.raceId = course:GetAttribute("CandidateId"), player.UserId, first.raceId
	report.heldFrames, report.seconds = first.stats.frames, os.clock() - began
	report.ok = true
end, debug.traceback)
if moveConnection then moveConnection:Disconnect() end
if root and root.Parent then
	if automatic then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(owner) end
end
if not ok then report.failure = failure end
receipt.Value = game.HttpService:JSONEncode(report)
