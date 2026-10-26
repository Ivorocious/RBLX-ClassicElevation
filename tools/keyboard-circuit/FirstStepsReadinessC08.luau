local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P1_C08
local controller = require(candidate.SourceSnapshot.KeyboardCircuitFeedback).Get(candidate)
local record = {pending = true, steps = {}, revision = "KC_P1_C08", players = #Players:GetPlayers()}
shared.KCC08FirstSteps = record
task.spawn(function()
    local ok, err = pcall(function()
        assert(controller.Readiness().state == "ready", "Eight clips must resolve before first steps")
        local character = assert(player.Character)
        local root = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local controls = require(player.PlayerScripts.PlayerModule):GetControls()
        local prior = controls.controlsEnabled
        controls:Disable()
        record.initial = controller.Diagnostics()
        local bank = candidate.S02_ThockySwitchworks.CP1_Recovery
        for _, name in {"Key_2_2", "Key_5_5", "Key_2_5", "Key_5_2", "Key_3_3"} do
            local before = controller.Diagnostics()
            local step = {key = name, voices = {}, grounded = false, maxHeld = 0}
            local observed = {}
            local connection = RunService.PreRender:Connect(function()
                local folder = player.PlayerGui:FindFirstChild("KeyboardCircuitAudition")
                if folder then
                    for _, sound in folder:GetChildren() do
                        if sound:IsA("Sound") and sound.Name:sub(1, 4) == "down" and sound.IsPlaying then
                            local signature = sound.Name .. "|" .. sound.SoundId
                            if not observed[signature] then
                                observed[signature] = true
                                table.insert(step.voices, {name = sound.Name, id = sound.SoundId, playing = true, position = sound.TimePosition, duration = sound.TimeLength, volume = sound.Volume})
                            end
                        end
                    end
                end
                local count = 0
                for _, held in controller.Diagnostics().held do if held.held then count += 1 end end
                step.maxHeld = math.max(step.maxHeld, count)
                if humanoid.FloorMaterial ~= Enum.Material.Air then step.grounded = true end
            end)
            root.CFrame = CFrame.new(bank[name].Position + Vector3.new(0, 3.16, 0))
            root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            task.wait(.6)
            connection:Disconnect()
            local after = controller.Diagnostics()
            step.entries = after.totals.entries - before.totals.entries
            step.plays = after.totals.played - before.totals.played
            step.unavailable = after.totals.unavailable - before.totals.unavailable
            step.coalesced = after.totals.coalesced - before.totals.coalesced
            step.passed = step.grounded and step.entries >= 1 and step.plays >= 1 and step.unavailable == 0 and #step.voices >= 1 and step.maxHeld <= 2 * record.players
            table.insert(record.steps, step)
        end
        record.final = controller.Diagnostics()
        record.passed = record.final.totals.unavailable == 0 and #record.steps == 5
        for _, step in record.steps do record.passed = record.passed and step.passed end
        if prior then controls:Enable() end
    end)
    record.pending, record.error = false, if ok then nil else tostring(err)
    if not ok then record.passed = false end
end)
return {started = true}
