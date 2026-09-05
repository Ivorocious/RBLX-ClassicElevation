--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Config = require(game:GetService("ReplicatedStorage").Config.ClassicAscentAmbienceConfig)
local sky: Sky? = nil
local createdSky = false
local savedSky: { [string]: any }? = nil
local saved: { [string]: any }? = nil
local savedAtmosphere: { [string]: any }? = nil
local atmosphere: Atmosphere? = nil
local correction = Instance.new("ColorCorrectionEffect")
correction.Name = "ClassicAscentColor"
correction.Enabled = false
correction.Parent = Lighting

local function setActive(active: boolean)
	if active == (saved ~= nil) then return end
	if active then
		saved = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
		Lighting.ClockTime, Lighting.Brightness = 15.2, 2.5
		Lighting.Ambient = Color3.fromRGB(115, 126, 140)
		Lighting.OutdoorAmbient = Color3.fromRGB(146, 153, 160)
		atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			savedAtmosphere = { Density = atmosphere.Density, Offset = atmosphere.Offset, Color = atmosphere.Color, Decay = atmosphere.Decay, Haze = atmosphere.Haze, Glare = atmosphere.Glare }
			atmosphere.Density, atmosphere.Offset, atmosphere.Haze, atmosphere.Glare = 0.2, 0.2, 0.65, 0.1
			atmosphere.Color, atmosphere.Decay = Color3.fromRGB(207, 225, 239), Color3.fromRGB(131, 161, 177)
		end
		sky = Lighting:FindFirstChildOfClass("Sky")
		createdSky = sky == nil
		if not sky then sky = Instance.new("Sky"); sky.Name = "ClassicAscentSky"; sky.Parent = Lighting end
		savedSky = {}
		local skyObject: any = sky
		for key, value in pairs(Config.Sky) do
			(savedSky :: {[string]: any})[key] = skyObject[key]
			skyObject[key] = value
		end
		correction.Brightness, correction.Contrast, correction.Saturation = 0.01, 0.08, 0.08
		correction.TintColor = Color3.fromRGB(255, 246, 232)
		correction.Enabled = true
	else
		for key, value in pairs(saved :: { [string]: any }) do (Lighting :: any)[key] = value end
		if atmosphere and savedAtmosphere then
			for key, value in pairs(savedAtmosphere) do (atmosphere :: any)[key] = value end
		end
		if sky then
			if createdSky then sky:Destroy()
			elseif savedSky then
				for key, value in pairs(savedSky) do (sky :: any)[key] = value end
			end
		end
		correction.Enabled = false
		sky, savedSky = nil, nil
		saved, savedAtmosphere = nil, nil
	end
end

local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed < 0.5 then return end
	elapsed = 0
	local course = workspace:FindFirstChild("RaceCourse")
	local info = course and course:FindFirstChild("CourseInfo")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local start = course and course:FindFirstChild("Start")
	local active = info ~= nil and info:GetAttribute("CourseId") == Config.CourseId
		and root ~= nil and root:IsA("BasePart") and start ~= nil and start:IsA("BasePart")
		and (root.Position - start.Position).Magnitude < Config.ActivationDistance
	setActive(active)
end)
