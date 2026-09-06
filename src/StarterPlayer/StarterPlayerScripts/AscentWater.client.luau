--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local currentCourse: Instance? = nil
local foam: {BasePart} = {}
local descendantConnection: RBXScriptConnection? = nil
local elapsed = 0

local function track(object: Instance)
	if object:IsA("BasePart") and object.Name == "RiverFoam" then table.insert(foam,object) end
end

RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed < 1/30 then return end
	elapsed = 0
	local course = workspace:FindFirstChild("RaceCourse")
	if course ~= currentCourse then
		if descendantConnection then descendantConnection:Disconnect(); descendantConnection = nil end
		currentCourse = course
		table.clear(foam)
		if course then
			descendantConnection = course.DescendantAdded:Connect(track)
			for _, object in ipairs(course:GetDescendants()) do track(object) end
		end
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	local clock = workspace:GetServerTimeNow()
	for _, streak in ipairs(foam) do
		if not streak.Parent then continue end
		local origin = streak:GetAttribute("FlowOrigin")
		if typeof(origin) ~= "CFrame" or (root.Position-origin.Position).Magnitude > 260 then continue end
		local phase = (clock/9+(streak:GetAttribute("FlowPhase") or 0))%1
		local direction = streak:GetAttribute("FlowDirection") or 1
		local width = streak:GetAttribute("FlowWidth") or 80
		streak.CFrame = origin*CFrame.new((phase-.5)*width*direction,0,0)
		streak.Transparency = 0.2+0.8*(math.abs(phase-0.5)*2)^6
	end
end)
