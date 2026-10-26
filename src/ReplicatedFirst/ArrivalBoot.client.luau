--!strict
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("Arrival") then return end
local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "ArrivalBoot", true, false, 79
local background = Instance.new("Frame")
background.Size, background.BackgroundColor3, background.BorderSizePixel = UDim2.fromScale(1,1), Color3.fromRGB(1,3,9), 0
background.Parent = gui
local label = Instance.new("TextLabel")
label.Text, label.Font, label.TextSize = "OBBY TOURNAMENT", Enum.Font.GothamBlack, 24
label.TextColor3, label.BackgroundTransparency = Color3.fromRGB(82,223,255), 1
label.Size, label.Position, label.TextXAlignment = UDim2.new(1,-48,0,40), UDim2.fromOffset(24,20), Enum.TextXAlignment.Left
label.Parent = background
local loading = label:Clone()
loading.Text, loading.TextSize, loading.Position, loading.Parent = "Getting ready…", 16, UDim2.new(0,24,1,-70), background
gui.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()
task.delay(30, function()
	if gui.Parent then loading.Text = "Still connecting. If this continues, please rejoin." end
end)
