local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Run this read-only probe in the actual client")
local player = game:GetService("Players").LocalPlayer
local candidate = workspace:FindFirstChild("KeyboardCircuit_P2_C01")
local result = {
	boundary = "Read-only actual client snapshot; no movement, camera, play-state or source edits",
	candidatePresent = candidate ~= nil, participant = player:GetAttribute("KCPhase2Candidate"),
	progress = {}, actions = {}, feedback = {}, layouts = {},
}
for _, name in {"KCPhase2Lap", "KCPhase2CompletedLaps", "KCPhase2NextGate", "KCPhase2Finished", "KCPhase2Recoveries"} do
	result.progress[name] = player:GetAttribute(name)
end
if candidate then
	result.revision, result.runId = candidate:GetAttribute("KCPhase2Revision"), candidate:GetAttribute("KCPhase2RunId")
end
for name in game:GetService("ContextActionService"):GetAllBoundActionInfo() do table.insert(result.actions, name) end
table.sort(result.actions)
for _, folder in player.PlayerGui:GetChildren() do
	if folder.Name == "KeyboardCircuitAudition" then
		local identity, probe = folder:FindFirstChild("Candidate"), folder:FindFirstChild("Diagnostics")
		if identity and identity:IsA("ObjectValue") and probe and probe:IsA("BindableFunction") then
			local ok, diagnostic = pcall(function() return probe:Invoke() end)
			table.insert(result.feedback, {
				candidate = if identity.Value then identity.Value.Name else "removed", ok = ok,
				active = if ok then diagnostic.active else nil,
				readiness = if ok then diagnostic.readiness else nil,
				totals = if ok then diagnostic.totals else nil,
				heldKeys = if ok then #diagnostic.held else nil,
				maxVoices = if ok then diagnostic.maxVoices else nil,
			})
		end
	end
end
for _, name in {"KeyboardCircuitPhase2Status", "KeyboardCircuitPhase2Lap"} do
	local gui = player.PlayerGui:FindFirstChild(name)
	local label = if gui then gui:FindFirstChild(if name == "KeyboardCircuitPhase2Status" then "Status" else "Progress") else nil
	if gui and label and label:IsA("TextLabel") then
		result.layouts[name] = {
			text = label.Text, x = label.AbsolutePosition.X, y = label.AbsolutePosition.Y,
			width = label.AbsoluteSize.X, height = label.AbsoluteSize.Y, size = label.TextSize,
			readiness = gui:GetAttribute("ReadinessState"), holding = gui:GetAttribute("HoldingMovement"),
			elapsed = gui:GetAttribute("Elapsed"), loaded = gui:GetAttribute("LoadedClips"),
		}
	end
end
local character = player.Character
local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
result.character = {
	alive = humanoid ~= nil and humanoid.Health > 0,
	floor = if humanoid then humanoid.FloorMaterial.Name else nil,
	state = if humanoid then humanoid:GetState().Name else nil,
	anchored = if root and root:IsA("BasePart") then root.Anchored else nil,
}
local camera = workspace.CurrentCamera
if camera then result.viewport = {width = camera.ViewportSize.X, height = camera.ViewportSize.Y} end
return result
