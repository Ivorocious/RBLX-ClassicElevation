local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local original = workspace.KeyboardCircuit_P1_C08
local record = {pending = true, revision = "KC_P1_C08", boundary = "Transient client fixture: one invalid release ID and a delayed preload; no production-source or server changes."}
shared.KCC08ReadinessFault = record
local function actions()
    local names = {}
    for name in ContextActionService:GetAllBoundActionInfo() do
        if name:sub(1, 22) == "KeyboardCircuitLoading" then table.insert(names, name) end
    end
    return names
end
local function fixture(name, timeout)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("CourseId", "keyboard-circuit")
    model:SetAttribute("KCSessionEnabled", true)
    local snapshot = original.SourceSnapshot:Clone()
    snapshot.Session.Disabled = true
    local replaced
    snapshot.ConfigSnapshot.Source, replaced = snapshot.ConfigSnapshot.Source:gsub("AudioReadyTimeout = 10", "AudioReadyTimeout = " .. timeout, 1)
    assert(replaced == 1)
    snapshot.ConfigSnapshot.Source, replaced = snapshot.ConfigSnapshot.Source:gsub('upId = "73995464860692"', 'upId = "0"', 1)
    assert(replaced == 1)
    snapshot.KeyboardCircuitAudio.Source, replaced = snapshot.KeyboardCircuitAudio.Source:gsub("ContentProvider:PreloadAsync%(list%)", [[
local available = {}
for _, sound in list do if sound.SoundId ~= "rbxassetid://0" then table.insert(available, sound) end end
ContentProvider:PreloadAsync(available)
task.wait(3)
ContentProvider:PreloadAsync(list)]], 1)
    assert(replaced == 1)
    snapshot.Parent = model
    local bank = original.S02_ThockySwitchworks.CP1_Recovery:Clone()
    bank.Name, bank.Parent = "Bank", model
    return model
end
local function diagnostic(model)
    local folder = player.PlayerGui:FindFirstChild("KeyboardCircuitAudition")
    assert(folder and folder.Candidate.Value == model)
    return folder.Diagnostics:Invoke(), folder
end
local controls = require(player.PlayerScripts.PlayerModule):GetControls()
local priorControls = controls.controlsEnabled
local oldParent = original.Parent
local current
task.spawn(function()
    local ok, err = pcall(function()
        controls:Disable()
        current = fixture("KC_C08_Readiness_DeadlineFixture", 1.2)
        original.Parent = nil
        current.Parent = workspace
        local root = player.Character.HumanoidRootPart
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        root.CFrame = CFrame.new(current.Bank.Key_3_3.Position + Vector3.new(0, 3.16, 0))
        root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        task.wait(.1)
        record.loading = diagnostic(current)
        record.loadingActions = actions()
        record.controlEnabledWhileLoading = controls.controlsEnabled
        record.movementChecks, record.blockedChecks = 0, 0
        RunService:BindToRenderStep("KCC08FaultInput", Enum.RenderPriority.Input.Value, function()
            humanoid:Move(Vector3.xAxis); humanoid.Jump = true
        end)
        local movementProbe = RunService.PreSimulation:Connect(function()
            record.movementChecks += 1
            if humanoid.MoveDirection.Magnitude == 0 and not humanoid.Jump then record.blockedChecks += 1 end
        end)
        task.wait(.3)
        RunService:UnbindFromRenderStep("KCC08FaultInput")
        movementProbe:Disconnect()
        local status = player.PlayerGui.KeyboardCircuitLoading.Status
        record.status = {text = status.Text, width = status.AbsoluteSize.X, viewport = workspace.CurrentCamera.ViewportSize.X, scale = status.Size.X.Scale, max = status.UISizeConstraint.MaxSize.X}
        local began = os.clock()
        repeat task.wait(.03) until diagnostic(current).readiness.state ~= "loading" or os.clock() - began > 2
        task.wait(.1)
        record.degraded = diagnostic(current)
        record.degradedActions = actions()
        record.controlEnabledAfterRelease = controls.controlsEnabled
        record.degradedText = player.PlayerGui.KeyboardCircuitLoading.Status.Text
        task.wait(.25)
        record.currentFoot = diagnostic(current)
        record.noReplayedEvents = record.loading.totals.entries == 0 and record.loading.totals.played == 0 and record.loading.totals.unavailable == 0
        record.survivingVoice = false
        local before, folder = diagnostic(current)
        local observed = RunService.PreRender:Connect(function()
            for _, sound in folder:GetChildren() do
                if sound:IsA("Sound") and sound.Name:sub(1, 4) == "down" and sound.IsPlaying then record.survivingVoice = true end
            end
        end)
        root.CFrame = CFrame.new(current.Bank.Key_5_5.Position + Vector3.new(0, 3.16, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(.5)
        observed:Disconnect()
        record.afterStep = diagnostic(current)
        record.heldVisual = #record.afterStep.held >= 1
        record.movementReturned = false
        humanoid:Move(Vector3.xAxis)
        record.movementReturned = humanoid.MoveDirection.Magnitude > .5
        humanoid:Move(Vector3.zero)
        current.Parent = nil
        current:Destroy()
        current = fixture("KC_C08_Readiness_StopFixture", 1.2)
        current.Parent = workspace
        task.wait(.1)
        local stopBefore, stopFolder = diagnostic(current)
        record.stopBefore = stopBefore
        stopFolder.StopFeedback:Invoke()
        task.wait(.15)
        record.stopActions = actions()
        record.stopPanel = player.PlayerGui:FindFirstChild("KeyboardCircuitLoading") ~= nil
        record.stopFolder = player.PlayerGui:FindFirstChild("KeyboardCircuitAudition") ~= nil
        current.Parent = nil
        current:Destroy()
        current = fixture("KC_C08_Readiness_SwitchFixture", 1.2)
        current.Parent = workspace
        task.wait(.1)
        record.switchBefore = diagnostic(current)
        record.switchLoadingActions = actions()
        current.Parent = nil
        current:Destroy()
        current = nil
        original.Parent = oldParent
        local switchedAt = os.clock()
        repeat task.wait(.05) until diagnostic(original).readiness.state ~= "loading" or os.clock() - switchedAt > 10.1
        task.wait(.1)
        record.switchAfter = diagnostic(original)
        record.switchActions = actions()
        record.switchPanel = player.PlayerGui:FindFirstChild("KeyboardCircuitLoading") ~= nil
        record.controlsAfterSwitch = controls.controlsEnabled
        task.wait(3.2)
        record.lateActions = actions()
        record.latePanel = player.PlayerGui:FindFirstChild("KeyboardCircuitLoading") ~= nil
        record.lateController = diagnostic(original)
        record.passed = record.loading.readiness.state == "loading" and #record.loadingActions == 1
            and record.degraded.readiness.state == "degraded" and record.degraded.readiness.reason == "deadline"
            and record.degraded.readiness.elapsed <= 1.35 and #record.degraded.readiness.failed == 1
            and #record.degradedActions == 0 and record.noReplayedEvents and record.survivingVoice and record.heldVisual and record.movementReturned
            and record.movementChecks > 0 and record.movementChecks == record.blockedChecks
            and not record.controlEnabledWhileLoading and not record.controlEnabledAfterRelease and not record.controlsAfterSwitch
            and #record.stopActions == 0 and not record.stopPanel and not record.stopFolder
            and #record.switchActions == 0 and not record.switchPanel and #record.lateActions == 0 and not record.latePanel
            and record.switchAfter.readiness.state == "ready" and record.lateController.totals.unavailable == 0
    end)
    if current then current:Destroy() end
    original.Parent = oldParent
    if priorControls then controls:Enable() end
    record.pending, record.error = false, if ok then nil else tostring(err)
    if not ok then record.passed = false end
end)
return {started = true}
