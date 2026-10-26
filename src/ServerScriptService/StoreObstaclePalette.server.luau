--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Studio keeps the palette in Workspace for building; live servers store it before players join so they never download it.
if RunService:IsStudio() then
	return
end

local palette = workspace:FindFirstChild("ObstacleKit_Palette")

if palette ~= nil then
	palette.Parent = ServerStorage:FindFirstChild("DeveloperAssets") or ServerStorage
end
