--!strict

local Builder = {}
local Environment = require(script.Parent.AscentEnvironment)
local Details = require(script.Parent.AscentDetails)
local SignAdjustments = require(script.Parent.AscentSignAdjustments)
local MODEL_NAME = "Course_ClassicAscentPointToPoint"
local CENTER = Vector3.new(1400, 0, -1200)
local GOLD = Color3.fromRGB(225, 173, 75)
local STONE = Color3.fromRGB(137, 145, 135)
local DARK = Color3.fromRGB(48, 65, 65)
local WOOD = Color3.fromRGB(122, 83, 51)
local SNOW = Color3.fromRGB(222, 234, 231)

type Section = { name: string, count: number, width: number, gap: number, style: string, material: Enum.Material, color: Color3 }
local SECTIONS: { Section } = {
	{ name = "Trailhead", count = 10, width = 24, gap = 0, style = "trail", material = Enum.Material.Cobblestone, color = STONE },
	{ name = "River Rapids", count = 28, width = 14, gap = 4.5, style = "garden", material = Enum.Material.Slate, color = Color3.fromRGB(139, 160, 128) },
	{ name = "Switchback Climb", count = 24, width = 9, gap = 5, style = "stairs", material = Enum.Material.Rock, color = Color3.fromRGB(159, 145, 117) },
	{ name = "Ridge Bridges", count = 16, width = 10, gap = 0, style = "bridge", material = Enum.Material.WoodPlanks, color = WOOD },
	{ name = "Pillar Yard", count = 18, width = 9, gap = 5.5, style = "pillars", material = Enum.Material.Basalt, color = Color3.fromRGB(91, 109, 119) },
	{ name = "Broken Causeway", count = 12, width = 19, gap = 5.5, style = "ruins", material = Enum.Material.Limestone, color = Color3.fromRGB(180, 169, 135) },
	{ name = "Cliffside Traverse", count = 16, width = 10, gap = 5, style = "ledge", material = Enum.Material.Slate, color = Color3.fromRGB(116, 139, 149) },
	{ name = "Summit Steps", count = 18, width = 17, gap = 1, style = "snowstairs", material = Enum.Material.Snow, color = SNOW },
	{ name = "Skyline", count = 18, width = 9, gap = 5, style = "teeth", material = Enum.Material.Ice, color = Color3.fromRGB(168, 204, 214) },
	{ name = "Summit Run", count = 10, width = 26, gap = 0, style = "summit", material = Enum.Material.Slate, color = Color3.fromRGB(199, 211, 210) },
}

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collidable: boolean?): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide = collidable ~= false
	p.CanTouch = collidable ~= false
	p.CanQuery = collidable ~= false
	p.Parent = parent
	return p
end

local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material)
	return block(parent, name, Vector3.new(thickness, thickness, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color, material, false)
end

local function routePosition(sectionIndex: number, step: number, preserveRiverExit: boolean?): Vector3
	local section = SECTIONS[sectionIndex]
	local t = ((sectionIndex - 1) + step / section.count) / #SECTIONS
	local angle = math.rad(-25 + t * 480)
	local radius = 340 - 170 * t
	local lateral = if sectionIndex == 3 and not preserveRiverExit then 18 * math.sin(step * math.pi / 8) else 2 * math.sin(step * math.pi / section.count)
	return CENTER + Vector3.new(math.cos(angle) * (radius + lateral), 64 + t * 180, math.sin(angle) * (radius + lateral))
end


function Builder.Ensure(library: Folder): Model
	local existing = library:FindFirstChild(MODEL_NAME)
	if existing then
		assert(existing:IsA("Model"), "Classic Ascent must be a Model")
		if existing:GetAttribute("BuilderVersion") == 8 then
			assert(existing:GetAttribute("JourneyRevision") == 1 and existing:GetAttribute("SceneryCollisionRevision") == 1, "Incomplete V8 course; archive and rebuild before use")
			require(script.Parent.AscentDepthPass).Apply(existing)
			require(script.Parent.AscentRiverFinishPass).Apply(existing)
			require(script.Parent.AscentJumpTuning).Apply(existing)
			return existing
		end
		assert(existing:GetAttribute("BuilderVersion") >= 1 and existing:GetAttribute("BuilderVersion") <= 7, "Unrecognized authored course; reconcile before rebuilding")
		local archiveName = MODEL_NAME .. "_Version" .. tostring(existing:GetAttribute("BuilderVersion"))
		assert(not library:FindFirstChild(archiveName), "Generated version archive already exists")
		existing.Name = archiveName
		local oldInfo = existing:FindFirstChild("CourseInfo")
		if oldInfo then
			oldInfo:SetAttribute("Enabled", false)
			oldInfo:SetAttribute("CourseId", "classic_ascent_archived_v" .. tostring(existing:GetAttribute("BuilderVersion")))
		end
	end
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model:SetAttribute("BuilderVersion", 8)
	local info = folder(model, "CourseInfo")
	for key, value in pairs({ CourseId = "classic_ascent_point_to_point", DisplayName = "Classic Ascent · Alpine Expedition", RaceFormat = "PointToPoint", LapCount = 1, Enabled = true, Difficulty = "Intermediate", TargetNewPlayerTime = 420, TargetPracticedTime = 300, CheckpointCount = 19, TimingValidated = false, DesignedRacerCapacity = 20, ParallelRoutes = 3 }) do
		info:SetAttribute(key, value)
	end
	local obstacles = folder(model, "Obstacles")
	local checkpoints = folder(model, "Checkpoints")
	local zones = folder(model, "FallZones")
	local markers = folder(model, "RouteMarkers")
	folder(model, "Decoration")
	folder(model, "Bounds")
	local startPosition = routePosition(1, 0)
	local startCF = CFrame.lookAt(startPosition, Vector3.new(routePosition(1, 1).X, startPosition.Y, routePosition(1, 1).Z))
	local start = block(model, "Start", Vector3.new(66, 3, 36), startCF, STONE, Enum.Material.Cobblestone)
	model.PrimaryPart = start
	start:SetAttribute("SectionIndex", 1)
	start:SetAttribute("SectionName", "Trailhead")
	Details.StartPen(model, start)
	local nodes: { BasePart } = { start }
	local checkpointIndex, routeIndex, length = 0, 0, 0
	local previousPosition = startPosition
	for sectionIndex, section in ipairs(SECTIONS) do
		local group = folder(obstacles, string.format("%02d_%s", sectionIndex, section.name:gsub(" ", "")))
		for step = 1, section.count do
			local position = routePosition(sectionIndex, step)
			local nextPosition = if step < section.count then routePosition(sectionIndex, step + 1) elseif sectionIndex < #SECTIONS then routePosition(sectionIndex + 1, 1) else position + (position - previousPosition)
			local facingPosition = if sectionIndex == 2 and step == section.count then routePosition(3, 1, true) else nextPosition
			local tangent = facingPosition - previousPosition
			local cf = CFrame.lookAt(position, position + Vector3.new(tangent.X, 0, tangent.Z))
			local landing = step == section.count / 2 or step == section.count
			local sizeZ = math.max(4, math.min((position - previousPosition).Magnitude, (nextPosition - position).Magnitude) - section.gap)
			local width = if landing then 66 elseif sectionIndex == 6 then 15 else math.min(section.width, 14)
			local pad: Part
			if landing and sectionIndex == #SECTIONS and step == section.count then
				pad = block(model, "Finish", Vector3.new(66, 3, 30), cf, STONE, Enum.Material.Slate)
			elseif landing then
				checkpointIndex += 1
				pad = block(checkpoints, string.format("Checkpoint_%03d", checkpointIndex), Vector3.new(width, 3, if sectionIndex == 2 then 10 else math.max(18, sizeZ)), cf, if section.style == "teeth" then SNOW else section.color, if section.style == "teeth" then Enum.Material.Snow else section.material)
				Details.Checkpoint(markers, pad, checkpointIndex)
			else
				pad = block(group, string.format("Route_%03d", routeIndex + 1), Vector3.new(width, 3, sizeZ), cf, section.color, section.material)
			end
			routeIndex += 1
			pad:SetAttribute("RouteIndex", routeIndex)
			pad:SetAttribute("SectionIndex", sectionIndex)
			pad:SetAttribute("SectionStep", step)
			pad:SetAttribute("SectionName", section.name)
			pad:SetAttribute("ObstacleStyle", section.style)
			pad:SetAttribute("RoutePad", true)
			pad:SetAttribute("Lane", 0)
			if not landing then
				-- Three paths share rest areas; small bends pass either side of planted islands.
				for _, lane in ipairs({-1, 1}) do
					local offset = lane * (20 + 2 * math.sin(step * math.pi / section.count))
					local branch = block(group, string.format("Branch_%03d_%s", routeIndex, if lane < 0 then "Valley" else "Mountain"), pad.Size, cf * CFrame.new(offset, 0, 0), section.color, section.material)
					for key, value in pairs(pad:GetAttributes()) do branch:SetAttribute(key, value) end
					branch:SetAttribute("RouteIndex", nil)
					branch:SetAttribute("Lane", lane)
				end
			end
			table.insert(nodes, pad)
			length += (position - previousPosition).Magnitude
			previousPosition = position
			local zone = block(zones, string.format("Recovery_%03d", routeIndex), Vector3.new(92, 3, sizeZ + 20), cf * CFrame.new(0, -12, 0), DARK, Enum.Material.SmoothPlastic, false)
			zone.Transparency, zone.CanTouch = 1, true
			if step == 1 then
				local adjustment = SignAdjustments[sectionIndex]
				Details.Sign(markers, cf * CFrame.new(29, 1.5, 4) * CFrame.Angles(0, adjustment.yaw, 0), string.format("%02d  %s", sectionIndex, section.name), ({"Jump over logs", "Ride logs to cross", "Climb the shelves", "Boards fall", "Wait · Then jump", "Watch red circles", "Use rock refuges", "Dodge · Use cover", "Ice slips · Snow grips", "Dodge · Use cover"})[sectionIndex], sectionIndex >= 5)
			end
		end
	end
	local general = block(zones, "FallZone_Main", Vector3.new(1000, 3, 1000), CFrame.new(CENTER + Vector3.new(0, 15, 0)), DARK, Enum.Material.SmoothPlastic, false)
	general.Transparency, general.CanTouch = 1, true
	local finish = model:FindFirstChild("Finish") :: Part
	for _, side in ipairs({ -1, 1 }) do
		local base = finish.CFrame * CFrame.new(side * 17, 0, -8)
		block(markers, "SummitGateColumn", Vector3.new(3, 20, 3), base * CFrame.new(0, 10, 0), DARK, Enum.Material.Slate, false)
		block(markers, "SummitBanner", Vector3.new(5, 9, 0.3), base * CFrame.new(side * 4, 14, 0), GOLD, Enum.Material.Fabric, false)
	end
	block(markers, "SummitLintel", Vector3.new(39, 3, 4), finish.CFrame * CFrame.new(0, 21, -8), STONE, Enum.Material.Limestone, false)
	Details.Sign(markers, finish.CFrame * CFrame.new(0, 7, -8), "SUMMIT", "CLASSIC ASCENT", true, true)
	require(script.Parent.AscentProps).Prepare()
	require(script.Parent.AscentLayout).Apply(model)
	Details.RouteExtras(model, nodes)
	require(script.Parent.AscentSurfaces).Build(model,nodes)
	require(script.Parent.AscentWorld).Build(model, nodes, CENTER)
	Environment.Build(model, nodes, CENTER)
	require(script.Parent.AscentDepthPass).Apply(model)
	require(script.Parent.AscentRiverFinishPass).Apply(model)
	require(script.Parent.AscentJourney).Build(model, nodes)
	require(script.Parent.AscentLowerIntegration).Build(model,nodes)
	require(script.Parent.AscentUpperIntegration).Build(model,nodes)
	require(script.Parent.AscentJumpTuning).Apply(model)
	require(script.Parent.AscentProps).OptimizeScenery(model)
	assert(checkpointIndex == 19, "Nineteen checkpoints required")
	length = 0
	for index = 2, #nodes do length += (nodes[index].Position - nodes[index-1].Position).Magnitude end
	info:SetAttribute("RouteLengthStuds", math.floor(length + 0.5))
	info:SetAttribute("RouteTransitions", routeIndex)
	model.Parent = library
	return model
end

return Builder
