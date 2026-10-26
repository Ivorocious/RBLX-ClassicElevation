--!strict

local Workspace = game:GetService("Workspace")
local Phases = require(script.Parent.ManualObstaclePhases)
local Motion = {}
local axes = { X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis }

local function number(part: BasePart, name: string, default: number, low: number, high: number): number
	local value = part:GetAttribute(name)
	return if typeof(value) == "number" and value == value then math.clamp(value, low, high) else default
end

function Motion.Create(course: Model)
	local records = {}
	local phases = Phases.Create(course)
	local elapsed = 0
	local fastest = 0
	for _, part in course:GetDescendants() do
		if not part:IsA("BasePart") or part:GetAttribute("HazardType") ~= "Kill" then continue end
		local kind = part:GetAttribute("KitMotion")
		if kind ~= "Spin" and kind ~= "Swing" and kind ~= "Slide" then continue end
		assert(part.Anchored, "Moving kit traps must be anchored: " .. part:GetFullName())
		local period = number(part, "MotionPeriod", 6, 2, 120)
		local distance = number(part, "MotionDistance", 6, 0, 100)
		local angle = math.rad(number(part, "MotionAngle", 60, 0, 170))
		local axisName = part:GetAttribute("MotionAxis")
		local axis = axes[if typeof(axisName) == "string" then axisName else "Y"] or Vector3.yAxis
		local rate = math.pi * 2 / period
		local pivot = part:GetAttribute("MotionPivotOffset")
		if typeof(pivot) ~= "Vector3" or pivot.Magnitude ~= pivot.Magnitude or pivot.Magnitude == math.huge then pivot = Vector3.zero end
		if pivot.Magnitude > 100 then pivot = pivot.Unit * 100 end
		local radius = part.Size.Magnitude / 2 + pivot.Magnitude
		local speed = rate * (if kind == "Slide" then distance else radius * (if kind == "Swing" then angle else 1))
		fastest = math.max(fastest, speed)
		local followers = {}
		for _, visual in part.Parent:GetChildren() do
			if visual:IsA("BasePart") and visual:GetAttribute("MotionFollows") == part.Name then
				assert(visual.Anchored and not visual.CanCollide and not visual.CanTouch, "Motion followers must be decoration")
				table.insert(followers, {part=visual, start=visual.CFrame, relative=part.CFrame:ToObjectSpace(visual.CFrame)})
			end
		end
		table.insert(records, { part = part, start = part.CFrame, kind = kind, axis = axis,
			rate = rate, distance = distance, angle = angle, speed = speed, pivot = pivot,
			phase = math.rad(number(part, "MotionPhase", 0, 0, 360)), followers=followers })
	end
	if #records == 0 and not phases then return nil end
	local controller = {}
	local function pose(record, time: number): CFrame
		local phase = time * record.rate + record.phase
		if record.kind == "Slide" then
			return record.start * CFrame.new(record.axis * math.sin(phase) * record.distance)
		end
		local angle = if record.kind == "Spin" then phase else math.sin(phase) * record.angle
		return record.start * CFrame.new(record.pivot) * CFrame.fromAxisAngle(record.axis, angle) * CFrame.new(-record.pivot)
	end
	function controller.Reset()
		elapsed = 0
		if phases then phases.Reset() end
		for _, record in records do
			if record.part.Parent then record.part.CFrame = record.start end
			for _, visual in record.followers do
				if visual.part.Parent then visual.part.CFrame = visual.start end
			end
		end
	end
	function controller.Step(deltaTime: number, overlap: OverlapParams?, onHit)
		if deltaTime ~= deltaTime or deltaTime <= 0 then return end
		-- Slow the timeline on a stall instead of skipping across a racer.
		local advance = math.min(deltaTime, .1, 8 / math.max(fastest, 1))
		for _, record in records do
			if not record.part.Parent then continue end
			if overlap then
				local steps = math.max(1, math.ceil(record.speed * advance / .5))
				for step = 0, steps do
					local cf = pose(record, elapsed + advance * step / steps)
					record.part.CFrame = cf
					for _, hit in Workspace:GetPartsInPart(record.part, overlap) do onHit(hit) end
				end
			end
			record.part.CFrame = pose(record, elapsed + advance)
			for _, visual in record.followers do
				if visual.part.Parent then visual.part.CFrame = record.part.CFrame * visual.relative end
			end
		end
		elapsed += advance
		if phases then phases.Step(elapsed) end
	end
	return controller
end

return Motion
