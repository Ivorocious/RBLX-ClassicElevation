--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Config.EggRushAmbienceConfig)
local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local RaceFlow = require(script.Parent.Controllers.RaceFlowController)
local player = Players.LocalPlayer
local visitStatuses: {[string]: boolean} = {Racing = true, LateRacing = true, GhostRacing = true, Finished = true, Spectating = true}

local correction: ColorCorrectionEffect? = nil
local connections: {RBXScriptConnection} = {}

local function clear()
	if correction then correction:Destroy(); correction = nil end
end

local function insideCourse(course: Model, position: Vector3, padding: number): boolean
	local point = course:GetPivot():PointToObjectSpace(position)
	local lower = Config.VisitBoundsMin - Vector3.one * padding
	local upper = Config.VisitBoundsMax + Vector3.one * padding
	return point.X >= lower.X and point.X <= upper.X
		and point.Y >= lower.Y and point.Y <= upper.Y
		and point.Z >= lower.Z and point.Z <= upper.Z
end

local function wantsGrading(camera: Camera): boolean
	if player:GetAttribute("ArrivalOpen") == true or player:GetAttribute("ArrivalPhase") ~= "Ready"
		or player:GetAttribute("OnboardingReady") ~= true or player:GetAttribute("PracticeRoom") == true then return false end
	local state = RaceFlow.GetState()
	if not state or state.courseId ~= Config.CourseId then return false end
	local presenting = player:GetAttribute("TournamentPresentation") == true
	if state.status == "Queued" then
		if not presenting and state.state ~= "Countdown" then return false end
	elseif not visitStatuses[state.status] then
		return false
	end
	local course = workspace:FindFirstChild(RaceConfig.RaceCourseModelName)
	if not course or not course:IsA("Model") or course:GetAttribute("EROwned") ~= true then return false end
	local info = course:FindFirstChild("CourseInfo")
	if not info or info:GetAttribute("CourseId") ~= Config.CourseId then return false end
	if not insideCourse(course, camera.CFrame.Position, Config.CameraPadding) then return false end

	if presenting then
		local preparation = state.preparation
		return preparation ~= nil and preparation.courseId == Config.CourseId
	end

	local character = player.Character
	if state.status == "Spectating" then
		local subject = camera.CameraSubject
		character = if subject and subject:IsA("Humanoid") and subject.Parent and subject.Parent:IsA("Model") then subject.Parent else nil
	elseif camera.CameraType == Enum.CameraType.Scriptable then
		return false
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart")
		and insideCourse(course, root.Position, 0)
end

local function refresh()
	local camera = workspace.CurrentCamera
	if correction and correction.Parent ~= camera then clear() end
	if not camera or not wantsGrading(camera) then clear(); return end
	if correction then return end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "EggRushWarmth"
	effect.Brightness = Config.ColorCorrection.Brightness
	effect.Contrast = Config.ColorCorrection.Contrast
	effect.Saturation = Config.ColorCorrection.Saturation
	effect.TintColor = Config.ColorCorrection.TintColor
	effect.Parent = camera
	correction = effect
end

local elapsed = 0
table.insert(connections, RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed < Config.RefreshSeconds then return end
	elapsed = 0
	refresh()
end))
table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refresh))
for _, attribute in {"ArrivalOpen", "ArrivalPhase", "OnboardingReady", "PracticeRoom", "TournamentPresentation"} do
	table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(refresh))
end
table.insert(connections, player.CharacterRemoving:Connect(clear))
script.Destroying:Connect(function()
	for _, connection in connections do connection:Disconnect() end
	clear()
end)
refresh()
