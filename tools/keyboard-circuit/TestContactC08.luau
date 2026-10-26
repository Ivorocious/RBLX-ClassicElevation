local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local p = Players.LocalPlayer
local c = workspace.KeyboardCircuit_P1_C08
local feedback = require(c.SourceSnapshot.KeyboardCircuitFeedback)
local controller = feedback.Get(c) or feedback.Start(c)
local character, root = p.Character, p.Character.HumanoidRootPart
local humanoid = character:FindFirstChildOfClass("Humanoid")
local controls = require(p.PlayerScripts.PlayerModule):GetControls()
local bank = c.S02_ThockySwitchworks.CP1_Recovery
local receipt = {pending = true, revision = c:GetAttribute("CandidateRevision"), samples = {}, maxHeld = 0}
shared.KCC08Contact = receipt
task.spawn(function()
    local originalSpeed = humanoid.WalkSpeed
    controls:Disable()
    humanoid.WalkSpeed = 16
    local function sample(label)
        local diagnostic = controller.Diagnostics()
        local count = 0
        for _,held in diagnostic.held do if held.held then count += 1 end end
        receipt.maxHeld = math.max(receipt.maxHeld, count)
        table.insert(receipt.samples, {label = label, time = os.clock(), floor = humanoid.FloorMaterial.Name, state = humanoid:GetState().Name, position = {root.Position.X, root.Position.Y, root.Position.Z}, diagnostic = diagnostic})
        return diagnostic
    end
    local function place(key)
        root.CFrame = CFrame.new(key.Position + Vector3.new(0, 3.16, 0))
        root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    end
    local ok, err = pcall(function()
        place(bank.Key_3_3)
        task.wait(.6)
        receipt.holdBefore = sample("hold begin")
        for index = 1, 30 do task.wait(.1); sample("stable hold") end
        receipt.holdAfter = controller.Diagnostics()
        receipt.legends = {}
        for _,key in bank:GetChildren() do
            if key:IsA("BasePart") and key.LocalTransparencyModifier == 1 then
                local gui = key:FindFirstChildOfClass("SurfaceGui")
                table.insert(receipt.legends, {key = key.Name, originalEnabled = gui.Enabled, mark = key:GetAttribute("KeyLegend")})
            end
        end
        humanoid.Jump = true
        for index = 1, 45 do task.wait(.025); sample("jump and landing") end
        for _,name in {"Key_2_2", "Key_5_5", "Key_2_5", "Key_5_2", "Key_3_3"} do
            local target = bank[name].Position
            humanoid:MoveTo(Vector3.new(target.X, root.Position.Y, target.Z))
            local began = os.clock()
            repeat task.wait(.04); sample("walk " .. name) until (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < .3 or os.clock() - began > 2
        end
        task.wait(.4)
        receipt.final = sample("final hold")
        receipt.staticVisualWrites = receipt.holdAfter.totals.visualWrites - receipt.holdBefore.totals.visualWrites
        receipt.staticAudioEntries = receipt.holdAfter.totals.entries - receipt.holdBefore.totals.entries
        receipt.passed = receipt.maxHeld <= 2 and receipt.staticVisualWrites == 0 and receipt.staticAudioEntries == 0
        for _,item in receipt.legends do receipt.passed = receipt.passed and not item.originalEnabled and utf8.len(item.mark) == 1 end
    end)
    humanoid.WalkSpeed = originalSpeed
    controls:Enable()
    receipt.pending, receipt.error = false, if ok then nil else tostring(err)
    if not ok then receipt.passed = false end
end)
return {requested = true}
