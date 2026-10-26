--!strict
assert(plugin, "Install this as a local Studio plugin")
local RunService = game:GetService("RunService")
local Preview = require(script.Parent.Preview)
local toolbar = plugin:CreateToolbar("Classic Elevation")
local button = toolbar:CreateButton("ClassicElevationUIPreview", "Preview game UI without starting Play", "rbxasset://textures/loading/robloxTiltRed.png", "UI Preview")
button.ClickableWhenViewportHidden = true
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,false,false,1280,850,540,450)
local widget = plugin:CreateDockWidgetPluginGuiAsync("ClassicElevationUIPreviewV1",info)
widget.Title = "Classic Elevation — UI Preview"
local preview = nil

local function update()
	button:SetActive(widget.Enabled)
	if RunService:IsRunning() then widget.Enabled=false; return end
	if widget.Enabled then
		if preview then preview.SetVisible(true) else preview=Preview.Create(widget) end
	elseif preview then preview.SetVisible(false) end
end
button.Click:Connect(function() widget.Enabled=not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(update)
local modeConnection = RunService.Heartbeat:Connect(function()
	if widget.Enabled and RunService:IsRunning() then widget.Enabled=false end
end)
plugin.Unloading:Connect(function() modeConnection:Disconnect(); if preview then preview.Destroy() end; widget:Destroy() end)
update()
