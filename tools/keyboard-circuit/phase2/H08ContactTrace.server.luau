assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer())
local player = assert(game.Players:GetPlayerByUserId(-1))
local candidate = workspace.KeyboardCircuit_P2_C01
local unit
for _, item in candidate.Districts:GetDescendants() do if item:IsA("Model") and item:GetAttribute("MechanismId") == "H08" then unit = item end end
assert(unit)
local params = OverlapParams.new()
params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Include, false
local state = {active = true, hits = {}, beganAt = workspace:GetServerTimeNow(), queries = 0}
shared.KCP2H08ContactTrace = state
local connection
connection = game:GetService("RunService").PostSimulation:Connect(function()
	local character = player.Character
	if not character then return end
	params.FilterDescendantsInstances = {character}
	local root = character:FindFirstChild("HumanoidRootPart")
	for index = 1, 3 do
		local panel = unit["DominoPanel" .. index]
		local shape = panel.Contact
		state.queries += 1
		for _, body in workspace:GetPartsInPart(shape, params) do
			if body:FindFirstAncestorWhichIsA("Accessory") then continue end
			if #state.hits < 32 then
				local frame = unit:GetAttribute("EncounterFrame")
				local relative = frame:PointToObjectSpace(body.Position)
				table.insert(state.hits, {at = workspace:GetServerTimeNow(), panel = index, cycle = panel:GetAttribute("CycleState"), admission = panel:GetAttribute("AdmissionOpen"),
					body = body.Name, bodySize = tostring(body.Size), bodyLocal = {relative.X, relative.Y, relative.Z}, bodyPose = {body.CFrame:GetComponents()},
					shapePose = {shape.CFrame:GetComponents()}, shapeSize = tostring(shape.Size), root = root and tostring(root.Position), floor = character.Humanoid.FloorMaterial.Name})
			end
		end
	end
end)
task.delay(35, function() connection:Disconnect(); state.active = false end)
return {tracing = true, boundary = "Read-only PostSimulation overlap observer; test queries are additional fixture cost and are not course performance measurements"}
