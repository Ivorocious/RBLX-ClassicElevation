assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer(), "Studio server only")
assert(game.PlaceId == 0 and game.GameId == 0, "Owned local fixture only")
local config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local root = workspace[config.BlenderRootName]
assert(root:GetAttribute("CandidateId") == config.BlenderCandidateId, "Current candidate required")
local player = assert(game.Players:GetPlayers()[1], "Real player required")
local http = game:GetService("HttpService")
local function progress()
	for _, row in http:JSONDecode(root:GetAttribute("PreviewReport")).players do
		if row.userId == player.UserId then return row end
	end
	error("Player is not enrolled")
end
root:SetAttribute("RequestedArea", "LanternStudy")
root:SetAttribute("PreviewCommand", "Enter")
task.wait(.5)
assert(root:GetAttribute("PreviewState") == "Running", "Preview is not running")
local tests = {}
for index = 1, 3 do
	local pad = assert(root.LanternStudy["NormalWait" .. index].PrimaryPart)
	local character = player.Character
	local body = character.HumanoidRootPart
	character.Humanoid:Move(Vector3.zero, false)
	body.AssemblyLinearVelocity, body.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	character:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 4, 0)))
	task.wait(.5)
	local before = progress().recoveries
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character}
	local frames, supported, maxDrift = 0, 0, 0
	local began = os.clock()
	repeat
		game:GetService("RunService").Heartbeat:Wait()
		local hit = workspace:Raycast(body.Position, Vector3.new(0, -12, 0), params)
		frames += 1
		if hit and hit.Instance == pad and character.Humanoid.FloorMaterial ~= Enum.Material.Air then supported += 1 end
		maxDrift = math.max(maxDrift, (Vector3.new(body.Position.X, 0, body.Position.Z) - Vector3.new(pad.Position.X, 0, pad.Position.Z)).Magnitude)
	until os.clock() - began >= 12.2
	local after = progress()
	local elapsed = os.clock() - began
	table.insert(tests, {name=pad.Parent.Name, support=pad:GetFullName(), seconds=elapsed, swingCycles=elapsed/6,
		frames=frames, supportedFrames=supported, maxHorizontalDrift=maxDrift, recoveriesBefore=before,
		progress=after, passed=after.recoveries==before and frames==supported and maxDrift<2})
end
local passed = true
for _, row in tests do passed = passed and row.passed end
return http:JSONEncode({candidate=root:GetAttribute("CandidateId"), passed=passed,
	setup="Controlled placement at each wait center; no movement input. Static waiting proof only, not route traversal or multiplayer arrival proof.", tests=tests})
