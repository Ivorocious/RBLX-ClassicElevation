--!strict
local RunService = game:GetService("RunService")

type Ripple = {part: BasePart, home: CFrame, amplitude: number, phase: number, period: number}
local tracked: {[BasePart]: Ripple} = {}
local course: Instance? = nil
local added: RBXScriptConnection? = nil
local removed: RBXScriptConnection? = nil

local function watch(object: Instance)
	if not object:IsA("BasePart") or object:GetAttribute("OceanMotion") ~= true then return end
	tracked[object] = {
		part = object, home = object.CFrame,
		amplitude = math.clamp(object:GetAttribute("OceanAmplitude") or .12, 0, .2),
		phase = object:GetAttribute("OceanPhase") or 0,
		period = math.max(5, object:GetAttribute("OceanPeriod") or 8),
	}
end

local function bind(nextCourse: Instance?)
	if nextCourse == course then return end
	if added then added:Disconnect(); added = nil end
	if removed then removed:Disconnect(); removed = nil end
	for object, row in tracked do
		if object.Parent then object.CFrame = row.home end
	end

	table.clear(tracked)
	course = nextCourse
	if not course then return end
	for _, object in course:GetDescendants() do watch(object) end
	added = course.DescendantAdded:Connect(watch)
	removed = course.DescendantRemoving:Connect(function(object)
		if object:IsA("BasePart") then
			local row = tracked[object]
			if row then object.CFrame = row.home; tracked[object] = nil end
		end
	end)
end

local refresh, elapsed = 0, 0
RunService.Heartbeat:Connect(function(delta)
	refresh += delta
	elapsed += delta
	if refresh >= .5 then
		refresh = 0
		local active = workspace:FindFirstChild("RaceCourse")
		local info = active and active:FindFirstChild("CourseInfo")
		bind(if info and info:GetAttribute("CourseId") == "shipwreck_cove" then active else nil)
	end
	if elapsed < 1 / 30 then return end
	elapsed = 0
	local camera = workspace.CurrentCamera
	if not camera then return end
	local time = workspace:GetServerTimeNow()
	for object, row in tracked do
		local distance = (camera.CFrame.Position - row.home.Position).Magnitude
		local reach = 350 + math.max(object.Size.X, object.Size.Z) * .5
		if distance <= reach then
			local height = row.amplitude * math.sin(time * (2 * math.pi / row.period) + row.phase)
			object.CFrame = row.home + Vector3.new(0, height, 0)
		else
			object.CFrame = row.home
		end
	end
end)
