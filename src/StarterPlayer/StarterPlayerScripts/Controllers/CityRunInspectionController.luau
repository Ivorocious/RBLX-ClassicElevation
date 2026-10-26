--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Controller = {}

function Controller.Init()
    if not RunService:IsStudio() then return end

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local request = remotes:WaitForChild("RequestCityRunInspection") :: RemoteEvent
    local state = remotes:WaitForChild("CityRunInspectionState") :: RemoteEvent
    local gui = Instance.new("ScreenGui")
    gui.Name = "CityRunInspection"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.Enabled = false

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 1)
    panel.Position = UDim2.new(0.5, 0, 1, -16)
    panel.Size = UDim2.fromOffset(244, 52)
    panel.BackgroundColor3 = Color3.fromRGB(20, 23, 28)
    panel.BackgroundTransparency = 0.08
    panel.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.Parent = panel

    local expanded = false
    local header = Instance.new("TextButton")
    header.Name = "ToggleInspection"
    header.Size = UDim2.new(1, -16, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(54, 68, 86)
    header.TextColor3 = Color3.new(1, 1, 1)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.Text = "City Run inspection - open"
    header.LayoutOrder = 0
    header.Parent = panel
    local body: { GuiObject } = {}
    local function setExpanded(value: boolean)
        expanded = value
        panel.Size = UDim2.fromOffset(244, if expanded then 266 else 52)
        header.Text = if expanded then "City Run inspection - hide" else "City Run inspection - open"
        for _, item in ipairs(body) do item.Visible = expanded end
    end
    header.Activated:Connect(function() setExpanded(not expanded) end)
    local title = Instance.new("TextLabel")
    title.Name = "Status"
    title.Size = UDim2.new(1, -16, 0, 34)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 14
    title.TextWrapped = true
    title.Text = "CITY RUN INSPECTION"
    title.LayoutOrder = 1
    title.Parent = panel
    table.insert(body, title)

    local function button(text: string, callback: () -> ()): TextButton
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, -16, 0, 36)
        item.BackgroundColor3 = Color3.fromRGB(54, 68, 86)
        item.TextColor3 = Color3.new(1, 1, 1)
        item.Font = Enum.Font.GothamMedium
        item.TextSize = 14
        item.Text = text
        item.LayoutOrder = #body + 1
        item.Parent = panel
        table.insert(body, item)
        item.Visible = false
        item.Activated:Connect(callback)
        return item
    end

    local checkpoint = 0
    local checkpointCount = 0
    local activeVariant = ""
    local availableVariants = { "Original", "Optimized" }
    local unlimited = false
    local variant: TextButton
    local nextCheckpoint: TextButton
    local timer: TextButton

    local variantLabels: { [string]: string } = {
        Original = "V1 Original",
        Optimized = "V2 Optimized",
        Rebuilt = "V3 Rebuilt",
    }

    local function getNextVariant(): string?
        local activeIndex = table.find(availableVariants, activeVariant) or 0
        if #availableVariants == 0 then return nil end
        return availableVariants[activeIndex % #availableVariants + 1]
    end

    local function refreshControls(message: string?)
        local nextVariant = getNextVariant()
        variant.Text = if nextVariant ~= nil then "Show " .. (variantLabels[nextVariant] or nextVariant) else "No variants available"
        variant.Active = nextVariant ~= nil
        nextCheckpoint.Text = if checkpointCount > 0
            then string.format("Next checkpoint (%d/%d)", math.min(checkpoint + 1, checkpointCount), checkpointCount)
            else "Next checkpoint"
        timer.Text = "Unlimited time: " .. (if unlimited then "ON" else "OFF")
        title.Text = "CITY RUN - " .. string.upper(variantLabels[activeVariant] or activeVariant) .. if message ~= nil and message ~= "" then "\n" .. message else ""
    end

    variant = button("Show V2 Optimized", function()
        local nextVariant = getNextVariant()
        if nextVariant ~= nil then request:FireServer({ action = "Switch", variant = nextVariant }) end
    end)
    nextCheckpoint = button("Next checkpoint", function()
        if checkpointCount <= checkpoint then return end
        request:FireServer({ action = "Jump", checkpointIndex = checkpoint + 1 })
    end)
    button("Jump to start", function()
        request:FireServer({ action = "Jump", checkpointIndex = 0 })
    end)
    timer = button("Unlimited time: OFF", function()
        request:FireServer({ action = "UnlimitedTime", enabled = not unlimited })
    end)

    state.OnClientEvent:Connect(function(payload)
        if typeof(payload) ~= "table" or payload.enabled ~= true then
            gui.Enabled = false
            return
        end

        local nextVariant = if typeof(payload.variant) == "string" then payload.variant else ""
        if nextVariant ~= activeVariant then
            checkpoint = 0
            activeVariant = nextVariant
        end
        if typeof(payload.availableVariants) == "table" then
            local receivedVariants: { string } = {}
            for _, candidate in ipairs(payload.availableVariants) do
                if typeof(candidate) == "string" then table.insert(receivedVariants, candidate) end
            end
            if #receivedVariants > 0 then availableVariants = receivedVariants end
        end
        if typeof(payload.checkpointCount) == "number" then
            checkpointCount = math.max(0, math.floor(payload.checkpointCount))
            checkpoint = math.clamp(checkpoint, 0, checkpointCount)
        end
        if typeof(payload.checkpointIndex) == "number" then
            checkpoint = math.clamp(math.floor(payload.checkpointIndex), 0, checkpointCount)
        end
        unlimited = payload.unlimitedTime == true
        gui.Enabled = true
        refreshControls(if typeof(payload.message) == "string" then payload.message else nil)
    end)

    setExpanded(false)
    request:FireServer({ action = "State" })
end

return Controller