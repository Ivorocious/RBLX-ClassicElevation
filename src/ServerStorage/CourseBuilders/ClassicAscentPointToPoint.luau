--!strict

-- This builder is the durable graybox source; Ensure never replaces an authored course.
local Builder = {}
local MODEL_NAME = "Course_ClassicAscentPointToPoint"
local ORIGIN = Vector3.new(400, 28, -300)
local GAP = 4
local PLATFORM_HEIGHT = 3
local CHECKPOINT_COLOR = Color3.fromRGB(246, 193, 66)
local ROCK_COLOR = Color3.fromRGB(47, 62, 72)
local TOP_COLOR = Color3.fromRGB(205, 218, 210)

type Section = {
	name: string,
	heading: number,
	style: string,
	rise: number,
	width: number,
	length: number,
	color: Color3,
	budget: number,
}

local SECTIONS: { Section } = {
	{ name = "Trailhead", heading = 0, style = "steps", rise = 0, width = 22, length = 14, color = Color3.fromRGB(113, 154, 115), budget = 12 },
	{ name = "Stepping Gardens", heading = 0, style = "stagger", rise = 0, width = 14, length = 12, color = Color3.fromRGB(107, 151, 121), budget = 15 },
	{ name = "Switchback Climb", heading = 0, style = "climb", rise = 2, width = 14, length = 12, color = Color3.fromRGB(129, 157, 125), budget = 18 },
	{ name = "Ridge Bridges", heading = 90, style = "bridge", rise = 0, width = 8, length = 18, color = Color3.fromRGB(126, 153, 162), budget = 14 },
	{ name = "Pillar Yard", heading = 180, style = "pillars", rise = 1, width = 11, length = 11, color = Color3.fromRGB(135, 157, 170), budget = 20 },
	{ name = "Broken Causeway", heading = 180, style = "flow", rise = 0, width = 18, length = 16, color = Color3.fromRGB(145, 167, 174), budget = 14 },
	{ name = "Cliffside Traverse", heading = 180, style = "ledge", rise = 0, width = 9, length = 14, color = Color3.fromRGB(157, 169, 180), budget = 20 },
	{ name = "Summit Steps", heading = 90, style = "climb", rise = 2, width = 14, length = 12, color = Color3.fromRGB(180, 189, 200), budget = 17 },
	{ name = "Skyline", heading = 0, style = "mixed", rise = 1, width = 12, length = 12, color = Color3.fromRGB(189, 199, 211), budget = 18 },
	{ name = "Summit Run", heading = 0, style = "flow", rise = 0, width = 22, length = 16, color = Color3.fromRGB(210, 219, 226), budget = 12 },
}

local function folder(parent: Instance, name: string): Folder
	local value = Instance.new("Folder")
	value.Name = name
	value.Parent = parent
	return value
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local value = Instance.new("Part")
	value.Name = name
	value.Size = size
	value.CFrame = cf
	value.Color = color
	value.Anchored = true
	value.TopSurface = Enum.SurfaceType.Smooth
	value.BottomSurface = Enum.SurfaceType.Smooth
	value.Material = Enum.Material.Concrete
	value.Parent = parent
	return value
end

local function sign(parent: Instance, cf: CFrame, text: string)
	local board = part(parent, "SectionSign", Vector3.new(16, 5, 0.4), cf, ROCK_COLOR)
	board.CanCollide = false
	board.CanTouch = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 32
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(250, 244, 222)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
end

local function markLanding(parent: Instance, cf: CFrame, width: number)
	for index = 1, 3 do
		local stripe = part(parent, "RouteStripe", Vector3.new(width * 0.35, 0.06, 0.6), cf * CFrame.new(0, PLATFORM_HEIGHT / 2 + 0.04, -index * 2), CHECKPOINT_COLOR)
		stripe.CanCollide = false
		stripe.CanTouch = false
	end
end

local function fallVolume(parent: Instance, name: string, a: Vector3, b: Vector3)
	local low = Vector3.new(math.min(a.X, b.X) - 40, math.min(a.Y, b.Y) - 13, math.min(a.Z, b.Z) - 40)
	local high = Vector3.new(math.max(a.X, b.X) + 40, low.Y + 3, math.max(a.Z, b.Z) + 40)
	local zone = part(parent, name, high - low, CFrame.new((low + high) / 2), Color3.fromRGB(210, 70, 70))
	zone.CanCollide = false
	zone.CanQuery = false
	zone.Transparency = 1
end

function Builder.Ensure(library: Folder): Model
	local existing = library:FindFirstChild(MODEL_NAME)
	if existing ~= nil then
		assert(existing:IsA("Model"), MODEL_NAME .. " must be a Model")
		return existing
	end

	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model:SetAttribute("BuilderVersion", 1)
	local info = folder(model, "CourseInfo")
	local attributes: { [string]: any } = {
		CourseId = "classic_ascent_point_to_point",
		DisplayName = "Classic Ascent · Point to Point",
		RaceFormat = "PointToPoint",
		LapCount = 1,
		Enabled = true,
		Difficulty = "Casual / Intermediate",
		TargetNewPlayerTime = 360,
		TargetPracticedTime = 160,
		CheckpointCount = 19,
		TimingValidated = false,
	}
	for key, value in pairs(attributes) do
		info:SetAttribute(key, value)
	end
	local obstacles = folder(model, "Obstacles")
	local checkpoints = folder(model, "Checkpoints")
	local fallZones = folder(model, "FallZones")
	local markers = folder(model, "RouteMarkers")
	local decoration = folder(model, "Decoration")
	local bounds = folder(model, "Bounds")
	local start = part(model, "Start", Vector3.new(36, PLATFORM_HEIGHT, 36), CFrame.new(ORIGIN), CHECKPOINT_COLOR)
	model.PrimaryPart = start
	markLanding(markers, start.CFrame, 30)
	sign(markers, start.CFrame * CFrame.new(0, 9, -13), "CLASSIC ASCENT\nPOINT TO POINT")
	local cursor = ORIGIN
	local previousLength = 36
	local checkpointIndex = 0
	local pathLength = 0
	local minPosition = ORIGIN
	local maxPosition = ORIGIN
	local previousPosition = ORIGIN
	local routeIndex = 0

	for sectionIndex, section in ipairs(SECTIONS) do
		local group = folder(obstacles, string.format("%02d_%s", sectionIndex, section.name:gsub(" ", "")))
		group:SetAttribute("DisplayName", section.name)
		group:SetAttribute("TargetSkilledSeconds", section.budget)
		local rotation = CFrame.Angles(0, math.rad(-section.heading), 0)
		local direction = rotation.LookVector
		local right = rotation.RightVector
		local segmentStart = cursor
		-- Every bend begins on a square checkpoint pad, so both approaches have full support.
		for step = 1, 12 do
			local landing = step == 6 or step == 12
			local length = if landing then 24 else section.length
			local width = if landing then 24 else section.width
			local rise = if landing then 0 else section.rise
			local lateral = 0
			if not landing then
				if section.style == "stagger" or section.style == "pillars" then
					lateral = if step % 2 == 0 then 3 else -3
				elseif section.style == "ledge" then
					lateral = if step <= 5 then -3 else 3
				elseif section.style == "mixed" then
					lateral = if step % 3 == 0 then 3 else 0
					width = if step % 3 == 0 then 9 else 14
				elseif section.style == "bridge" and step % 3 == 0 then
					width = 18
				end
			end
			cursor += direction * (previousLength / 2 + GAP + length / 2) + Vector3.new(0, rise, 0)
			local position = cursor + right * lateral
			local cf = CFrame.new(position) * rotation
			local surface: Part
			if landing then
				if sectionIndex == #SECTIONS and step == 12 then
					surface = part(model, "Finish", Vector3.new(width, PLATFORM_HEIGHT, length), cf, CHECKPOINT_COLOR)
				else
					checkpointIndex += 1
					surface = part(checkpoints, string.format("Checkpoint_%03d", checkpointIndex), Vector3.new(width, PLATFORM_HEIGHT, length), cf, CHECKPOINT_COLOR)
					if step == 12 then
						surface.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(-SECTIONS[sectionIndex + 1].heading), 0)
					end
				end
				markLanding(markers, surface.CFrame, width)
			else
				surface = part(group, string.format("Platform_%02d", step), Vector3.new(width, PLATFORM_HEIGHT, length), cf, section.color)
			end
			routeIndex += 1
			surface:SetAttribute("RouteIndex", routeIndex)
			surface:SetAttribute("SectionIndex", sectionIndex)
			surface:SetAttribute("SectionName", section.name)
			pathLength += (position - previousPosition).Magnitude
			previousPosition = position
			minPosition = Vector3.new(math.min(minPosition.X, position.X), math.min(minPosition.Y, position.Y), math.min(minPosition.Z, position.Z))
			maxPosition = Vector3.new(math.max(maxPosition.X, position.X), math.max(maxPosition.Y, position.Y), math.max(maxPosition.Z, position.Z))
			if step == 1 then
				sign(markers, cf * CFrame.new(width / 2 + 12, 7, 0), string.format("%02d / 10\n%s", sectionIndex, section.name:upper()))
			end
			if step == 6 or step == 12 then
				fallVolume(fallZones, string.format("FallZone_%02d_%02d", sectionIndex, step), segmentStart, cursor)
				segmentStart = cursor
			end
			if step == 3 or step == 9 then
				local rock = part(decoration, "Cliff", Vector3.new(18, 30 + sectionIndex * 2, 22), cf * CFrame.new(width / 2 + 24, -15, 0), ROCK_COLOR)
				rock.CanCollide = false
				rock.CanTouch = false
				local cap = part(decoration, "CliffCap", Vector3.new(19, 2, 23), rock.CFrame * CFrame.new(0, rock.Size.Y / 2, 0), TOP_COLOR)
				cap.CanCollide = false
				cap.CanTouch = false
			end
			previousLength = length
		end
	end

	assert(checkpointIndex == 19, "Classic Ascent requires nineteen checkpoints")
	info:SetAttribute("RouteLengthStuds", math.floor(pathLength))
	fallVolume(fallZones, "FallZone_Main", Vector3.new(minPosition.X, ORIGIN.Y - 20, minPosition.Z), Vector3.new(maxPosition.X, ORIGIN.Y - 20, maxPosition.Z))
	local extent = part(bounds, "CourseBounds", maxPosition - minPosition + Vector3.new(100, 100, 100), CFrame.new((minPosition + maxPosition) / 2), ROCK_COLOR)
	extent.CanCollide = false
	extent.CanTouch = false
	extent.CanQuery = false
	extent.Transparency = 1
	local finish = model:FindFirstChild("Finish") :: Part
	for _, side in ipairs({ -1, 1 }) do
		part(decoration, "SummitPost", Vector3.new(2, 20, 2), finish.CFrame * CFrame.new(side * 11, 10, -6), ROCK_COLOR)
	end
	part(decoration, "SummitArch", Vector3.new(24, 2, 2), finish.CFrame * CFrame.new(0, 20, -6), CHECKPOINT_COLOR)
	sign(markers, finish.CFrame * CFrame.new(0, 16, -5), "SUMMIT\nFINISH")
	model.Parent = library
	return model
end

return Builder
