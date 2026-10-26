local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local record = {pending = true, samples = {}, loadingFrames = 0, movementChecks = 0, blockedChecks = 0}
shared.KCC08Startup = record
local gui = player:WaitForChild("PlayerGui")
local result = Instance.new("BindableFunction")
result.Name, result.OnInvoke, result.Parent = "KCC08StartupResult", function() return record end, gui
local requestingMovement = true
RunService:BindToRenderStep("KCC08ProbeInput", Enum.RenderPriority.Input.Value, function()
    if not requestingMovement then return end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:Move(Vector3.xAxis); humanoid.Jump = true end
end)
local began = os.clock()
local frame
frame = RunService.PreSimulation:Connect(function()
    local folder = gui:FindFirstChild("KeyboardCircuitAudition")
    local diagnostic = folder and folder:FindFirstChild("Diagnostics")
    if not diagnostic then return end
    local result = diagnostic:Invoke()
    if not result.readiness then return end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local loading = gui:FindFirstChild("KeyboardCircuitLoading")
    local actionPresent = false
    for name in ContextActionService:GetAllBoundActionInfo() do
        if name:sub(1, 22) == "KeyboardCircuitLoading" then actionPresent = true end
    end
    table.insert(record.samples, {
        at = os.clock() - began, readiness = result.readiness, totals = table.clone(result.totals),
        held = #result.held, loadingPanel = loading ~= nil, action = actionPresent,
        movement = if humanoid then humanoid.MoveDirection.Magnitude else nil,
        jumping = if humanoid then humanoid.Jump else nil,
    })
    if result.readiness.state == "loading" then
        record.loadingFrames += 1
        if humanoid and loading and actionPresent then
            record.movementChecks += 1
            if humanoid.MoveDirection.Magnitude == 0 and not humanoid.Jump then record.blockedChecks += 1 end
        end
    else
        requestingMovement = false
        RunService:UnbindFromRenderStep("KCC08ProbeInput")
        frame:Disconnect()
        record.pending, record.final = false, result
        record.resolvedAfter = os.clock() - began
    end
end)
task.delay(12, function()
    if not record.pending then return end
    requestingMovement = false
    RunService:UnbindFromRenderStep("KCC08ProbeInput")
    frame:Disconnect()
    record.pending, record.error = false, "Startup did not resolve within 12 seconds"
end)
