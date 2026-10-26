local Players = game:GetService("Players")
local candidate = workspace:WaitForChild("KeyboardCircuit_P1_C08", 10)
local begin = candidate:WaitForChild("StudioProbeControls", 10):WaitForChild("Begin", 10)
local function stage(player)
    local function characterReady(character)
        if not character:WaitForChild("HumanoidRootPart", 10) then return end
        begin:Fire(player.UserId, "Sample")
    end
    player.CharacterAdded:Connect(characterReady)
    if player.Character then task.spawn(characterReady, player.Character) end
end
Players.PlayerAdded:Connect(stage)
for _, player in Players:GetPlayers() do stage(player) end
