--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VotingPreview = require(script.Parent.StudioVotingPreview)
local ArcadePreview = require(script.Parent.StudioGrandArcadePreview)
local Controller = {}

function Controller.Init()
    if not RunService:IsStudio() then return end
    VotingPreview.Preload()
    local player = Players.LocalPlayer
    local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StudioDevControl", 15)
    if not remote or not remote:IsA("RemoteFunction") then warn("Studio developer controls are unavailable"); return end
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "StudioDevControls", false, 100
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local toggle = Instance.new("TextButton")
    toggle.Name, toggle.Text = "Toggle", "DEV TOOLS [F6]"
    toggle.AnchorPoint, toggle.Position = Vector2.new(1,1), UDim2.new(1,-12,1,-8)
    toggle.Size = UDim2.fromOffset(140,28)
    toggle.Parent = gui
    local panel = Instance.new("ScrollingFrame")
    panel.Name, panel.Visible = "Panel", false
    panel.AnchorPoint, panel.Position = Vector2.new(1,1), UDim2.new(1,-12,1,-42)
    panel.Size, panel.CanvasSize = UDim2.new(0,300,0.72,0), UDim2.new()
    panel.AutomaticCanvasSize, panel.ScrollBarThickness = Enum.AutomaticSize.Y, 6
    panel.BackgroundColor3, panel.BorderSizePixel = Color3.fromRGB(24,29,38), 0
    panel.Parent = gui
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft, padding.PaddingRight = UDim.new(0,10), UDim.new(0,10)
    padding.PaddingTop, padding.PaddingBottom = UDim.new(0,10), UDim.new(0,10)
    padding.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0,6), Enum.SortOrder.LayoutOrder, panel
    local order = 0
    local function label(text: string, height: number): TextLabel
        order += 1
        local item = Instance.new("TextLabel")
        item.Size, item.LayoutOrder = UDim2.new(1,-6,0,height), order
        item.BackgroundTransparency, item.TextWrapped = 1, true
        item.TextColor3, item.Font, item.TextSize = Color3.fromRGB(225,232,239), Enum.Font.Gotham, 13
        item.Text, item.Parent = text, panel
        return item
    end
    local status = label("Connecting...", 48)
    local feedback = label("Play changes are temporary. Edit the map before Play.\nF toggles flight; F6 opens these tools.", 54)
    local busy = false
    local lastState: any = {}
    local refresh: (any) -> ()
    local function request(payload, quiet: boolean?)
        if busy then return end
        busy = true
        local ok, result = pcall(function() return remote:InvokeServer(payload) end)
        busy = false
        if ok and typeof(result) == "table" then
            lastState = result
            refresh(result)
            if not quiet then feedback.Text = result.message or "Ready" end
        elseif not quiet then feedback.Text = "Connection failed. Check Output." end
    end
    local function button(name: string, text: string, callback): TextButton
        order += 1
        local item = Instance.new("TextButton")
        item.Name, item.Text, item.LayoutOrder = name, text, order
        item.Size = UDim2.new(1,-6,0,34)
        item.BackgroundColor3, item.TextColor3 = Color3.fromRGB(47,63,81), Color3.new(1,1,1)
        item.Font, item.TextSize, item.BorderSizePixel = Enum.Font.GothamMedium, 13, 0
        item.Parent = panel
        item.Activated:Connect(callback)
        return item
    end
    label("UI PREVIEWS", 22)
    button("VotingUI", "Voting UI (10-map preview)", function()
        if VotingPreview.Open(lastState.maps) then
            panel.Visible = false
            feedback.Text = "10 sample maps. Confirming stays in this preview."
        else
            feedback.Text = "Map list is loading. Try again in a moment."
        end
    end)
    label("ROUND CONTROLS", 22)
    button("StartKeyboardCircuit", "Keyboard Circuit — start race", function()
        request({action="Map", courseId="keyboard_circuit"})
    end)
    button("StartStudGarden", "Stud Garden — start race", function()
        request({action="Map", courseId="stud_garden_v2"})
    end)
    for _,row in {{"GrandArcade","Stage opening (local preview)","Opening"},{"GrandArcadeNext","Stage next race (local preview)","Next"},{"GrandArcadeSlow","Stage slow delivery (local preview)","Slow"},{"GrandArcadeFailure","Stage failure (local preview)","Failure"}} do
        button(row[1],row[2],function()
            panel.Visible=false
            if not ArcadePreview.Open(row[3]) then feedback.Text="Enter the lobby first; the stage must be installed." end
        end)
    end
    for _, definition in {
        {"StartEvent","Start event (uses enrolled players)"},
        {"StartRace","Start race now"}, {"RestartRace","Restart race / reload current map"},
        {"NextState","Advance to next state"}, {"EndRace","End race → show results"},
        {"HoldLobby","Return everyone to lobby / hold rounds"},
    } do
        button(definition[1], definition[2], function() request({action=definition[1]}) end)
    end
    local timer = button("UnlimitedTime", "Unlimited timer: OFF", function()
        request({action="UnlimitedTime", enabled=not lastState.unlimitedTime})
    end)
    label("TELEPORT YOUR CHARACTER", 22)
    for _, destination in {"Lobby", "Start", "Finish"} do
        button("Teleport" .. destination, destination .. (if destination == "Finish" then " area" else ""), function()
            request({action="Teleport", destination=destination})
        end)
    end
    button("Respawn", "Respawn character", function() request({action="Respawn"}) end)
    label("ARRIVAL — TEMPORARY TEST PROFILES", 28)
    for _, preset in require(ReplicatedStorage.Config.OnboardingConfig).StudioPresets do
        button("Arrival_" .. preset, preset, function() request({action="OnboardingPreset", preset=preset}) end)
    end
    local dynamic = {}
    local signature = ""
    refresh = function(state)
        status.Text = string.format("STUDIO ONLY  •  %s\nMap: %s%s", state.state or "?", state.selectedMap or "?", if state.holdInLobby then "\nRounds held in lobby" else "")
        timer.Text = "Unlimited timer: " .. (if state.unlimitedTime then "ON" else "OFF")
        local nextSignature = game:GetService("HttpService"):JSONEncode({state.maps, state.checkpoints})
        if signature == nextSignature then return end
        signature = nextSignature
        for _, item in dynamic do item:Destroy() end
        table.clear(dynamic)
        order = 100
        table.insert(dynamic, label("MAPS — SELECT AND START RACE", 26))
        for _, map in state.maps or {} do
            table.insert(dynamic, button("Map_" .. map.id, map.name, function() request({action="Map", courseId=map.id}) end))
        end
        table.insert(dynamic, label("CHECKPOINTS — UPDATES RACE PROGRESS", 26))
        for _, checkpoint in state.checkpoints or {} do
            table.insert(dynamic, button("Checkpoint_" .. checkpoint.index, "Checkpoint " .. checkpoint.index, function()
                request({action="Teleport", destination="Checkpoint", checkpointIndex=checkpoint.index})
            end))
        end
    end
    toggle.BackgroundColor3, toggle.TextColor3 = Color3.fromRGB(27,107,132), Color3.new(1,1,1)
    toggle.Font, toggle.TextSize = Enum.Font.GothamBold, 14
    toggle.Activated:Connect(function() panel.Visible = not panel.Visible end)
    local function refreshToggle()
        toggle.Visible = player:GetAttribute("ArrivalOpen") ~= true or panel.Visible
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        toggle.Text = if viewport and viewport.X < 520 then "F6" else "DEV TOOLS [F6]"
        toggle.Size = UDim2.fromOffset(if viewport and viewport.X < 520 then 46 else 140,28)
        toggle.Position = if viewport and viewport.X < 520 then UDim2.new(1,-12,1,-96) else UDim2.new(1,-12,1,-8)
    end
    player:GetAttributeChangedSignal("ArrivalOpen"):Connect(refreshToggle)
    panel:GetPropertyChangedSignal("Visible"):Connect(refreshToggle)
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshToggle) end
    refreshToggle()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.F6 then panel.Visible = not panel.Visible end
    end)
    task.spawn(function()
        while gui.Parent do request({action="State"}, true); task.wait(2) end
    end)
end

return Controller
