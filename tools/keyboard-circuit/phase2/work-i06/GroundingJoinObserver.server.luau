--!strict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
assert(RunService:IsStudio() and RunService:IsServer())
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
assert(candidate:GetAttribute("Phase2Only"))
assert(not shared.KCP2GroundingServer10 or not shared.KCP2GroundingServer10.active)
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
local began, center = os.clock(), candidate.RouteLinks.H08_to_H01_1.BankContact.Position
local report = {active = true, samples = {}, beganAt = workspace:GetServerTimeNow(), boundary = "Read-only server grounding observations near the H08→H01 connector; no course/session edits."}
shared.KCP2GroundingServer10 = report
local connection
local function vector(p) return {p.X, p.Y, p.Z} end
connection = RunService.Heartbeat:Connect(function()
	if os.clock() - began >= 50 or not candidate.Parent then report.active = false; connection:Disconnect(); return end
	local player = Players:GetPlayerByUserId(-2)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or (root.Position - center).Magnitude > 28 then return end
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -6.5, 0), ray)
	table.insert(report.samples, {at = workspace:GetServerTimeNow(), root = vector(root.Position), velocity = vector(root.AssemblyLinearVelocity), floor = humanoid.FloorMaterial.Name,
		state = humanoid:GetState().Name, hit = hit and hit.Instance:GetFullName(), role = hit and hit.Instance:GetAttribute("Role"), distance = hit and hit.Distance,
		recoveries = player:GetAttribute("KCPhase2Recoveries")})
end)
report.Stop = function() connection:Disconnect(); report.active = false end
return {started = true, secondsLimit = 50, boundary = report.boundary}
