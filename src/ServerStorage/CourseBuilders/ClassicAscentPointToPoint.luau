--!strict

local Builder = {}
local Environment = require(script.Parent.AscentEnvironment)
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
	{ name = "Stepping Gardens", count = 14, width = 14, gap = 4, style = "garden", material = Enum.Material.Slate, color = Color3.fromRGB(139, 160, 128) },
	{ name = "Switchback Climb", count = 16, width = 16, gap = 2, style = "stairs", material = Enum.Material.Rock, color = Color3.fromRGB(159, 145, 117) },
	{ name = "Ridge Bridges", count = 16, width = 10, gap = 0, style = "bridge", material = Enum.Material.WoodPlanks, color = WOOD },
	{ name = "Pillar Yard", count = 18, width = 12, gap = 4, style = "pillars", material = Enum.Material.Basalt, color = Color3.fromRGB(91, 109, 119) },
	{ name = "Broken Causeway", count = 12, width = 19, gap = 4, style = "ruins", material = Enum.Material.Limestone, color = Color3.fromRGB(180, 169, 135) },
	{ name = "Cliffside Traverse", count = 16, width = 10, gap = 3, style = "ledge", material = Enum.Material.Slate, color = Color3.fromRGB(116, 139, 149) },
	{ name = "Summit Steps", count = 18, width = 17, gap = 1, style = "snowstairs", material = Enum.Material.Snow, color = SNOW },
	{ name = "Skyline", count = 16, width = 11, gap = 4, style = "teeth", material = Enum.Material.Glacier, color = Color3.fromRGB(168, 204, 214) },
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

local function plaque(parent: Instance, cf: CFrame, title: string, subtitle: string)
	local p = block(parent, "TrailSign", Vector3.new(15, 7, 0.5), cf, DARK, Enum.Material.Wood, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 40
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(0.92, 0.9), 1
	label.Position = UDim2.fromScale(0.04, 0.05)
	label.Font, label.TextColor3, label.TextScaled = Enum.Font.GothamBold, SNOW, true
	label.Text = title .. "\n" .. subtitle
	label.Parent = gui
end

local function lantern(parent: Instance, cf: CFrame)
	block(parent, "LanternPost", Vector3.new(0.7, 8, 0.7), cf * CFrame.new(0, 4, 0), DARK, Enum.Material.Wood, false)
	local lightPart = block(parent, "Lantern", Vector3.new(1.4, 1.9, 1.4), cf * CFrame.new(0, 8.6, 0), GOLD, Enum.Material.Neon, false)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = GOLD, 18, 0.65
	light.Shadows = false
	light.Parent = lightPart
end

local function checkpointDetails(parent: Instance, pad: Part, number: number)
	for _, side in ipairs({ -1, 1 }) do
		block(parent, "CheckpointInlay", Vector3.new(0.5, 0.08, pad.Size.Z - 2), pad.CFrame * CFrame.new(side * (pad.Size.X / 2 - 1), 1.55, 0), GOLD, Enum.Material.Neon, false)
		lantern(parent, pad.CFrame * CFrame.new(side * (pad.Size.X / 2 + 1), 1.5, 0))
	end
	local tile = block(parent, "CheckpointNumber", Vector3.new(8, 0.06, 6), pad.CFrame * CFrame.new(0, 1.56, 0), DARK, Enum.Material.Slate, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.PixelsPerStud, gui.Parent = Enum.NormalId.Top, 32, tile
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Font, label.TextColor3, label.TextScaled = Enum.Font.GothamBold, GOLD, true
	label.Text = string.format("%02d  >", number)
	label.Parent = gui
end

local function routePosition(sectionIndex: number, step: number): Vector3
	local section = SECTIONS[sectionIndex]
	local t = ((sectionIndex - 1) + step / section.count) / #SECTIONS
	local angle = math.rad(-25 + t * 480)
	local radius = 340 - 170 * t
	local lateral = 0
	if step ~= 0 and step ~= section.count and step ~= section.count / 2 then
		if section.style == "garden" or section.style == "pillars" then
			lateral = if step % 2 == 0 then 2 else -2
		elseif section.style == "stairs" then
			lateral = 7 * math.sin(step * math.pi / 4)
		elseif section.style == "ledge" then
			lateral = 4 * math.sin(step * math.pi / 4)
		end
	end
	return CENTER + Vector3.new(math.cos(angle) * (radius + lateral), 64 + t * 180, math.sin(angle) * (radius + lateral))
end

local function platformDetails(parent: Instance, pad: Part, section: Section, step: number)
	local cf, size = pad.CFrame, pad.Size
	if section.style == "bridge" then
		for z = -size.Z / 2 + 1, size.Z / 2 - 0.5, 2.2 do
			block(parent, "BridgeBoard", Vector3.new(size.X + 1, 0.12, 1.8), cf * CFrame.new(0, 1.55, z), WOOD:Lerp(GOLD, (step % 3) * 0.06), Enum.Material.Wood, false)
		end
		for _, side in ipairs({ -1, 1 }) do
			local x = side * (size.X / 2 + 0.7)
			beam(parent, "RopeHandrail", (cf * CFrame.new(x, 5.2, -size.Z / 2)).Position, (cf * CFrame.new(x, 5.2, size.Z / 2)).Position, 0.3, GOLD, Enum.Material.Fabric)
			block(parent, "BridgePost", Vector3.new(0.6, 6, 0.6), cf * CFrame.new(x, 2, 0), WOOD, Enum.Material.Wood, false)
		end
	elseif section.style == "pillars" then
		block(parent, "BasaltColumn", Vector3.new(size.X - 0.6, 22 + step % 4 * 3, size.Z - 0.6), cf * CFrame.new(0, -12 - step % 4 * 1.5, 0), DARK, Enum.Material.Basalt, false)
		for _, x in ipairs({ -size.X / 2 + 1, size.X / 2 - 1 }) do
			block(parent, "ColumnSeam", Vector3.new(0.25, 21, 0.25), cf * CFrame.new(x, -11, size.Z / 2), STONE, Enum.Material.Slate, false)
		end
	elseif section.style == "ruins" then
		for _, side in ipairs({ -1, 1 }) do
			local x = side * (size.X / 2 + 2)
			block(parent, "AqueductPier", Vector3.new(3, 25, 4), cf * CFrame.new(x, -11, 0), STONE, Enum.Material.Limestone, false)
			if step % 3 ~= 0 then
				block(parent, "RuinedParapet", Vector3.new(2, 3, size.Z * 0.6), cf * CFrame.new(x, 3, 0), section.color, Enum.Material.Limestone, false)
			end
		end
	elseif section.style == "garden" then
		block(parent, "MossEdge", Vector3.new(size.X * 0.8, 1, size.Z * 0.7), cf * CFrame.new(0, -1.4, 0), Color3.fromRGB(78, 116, 87), Enum.Material.Grass, false)
	elseif section.style == "ledge" then
		local bracket = block(parent, "CliffBracket", Vector3.new(size.X + 3, 8, size.Z * 0.8), cf * CFrame.new(0, -5, 0), DARK, Enum.Material.Rock, false)
		bracket.Shape = Enum.PartType.Block
	elseif section.style == "snowstairs" or section.style == "teeth" then
		block(parent, "IceStratum", Vector3.new(size.X * 0.9, 6 + step % 3 * 2, size.Z * 0.9), cf * CFrame.new(0, -4, 0), Color3.fromRGB(103, 146, 166), Enum.Material.Glacier, false)
	elseif section.style == "trail" or section.style == "summit" or section.style == "stairs" then
		block(parent, "StoneFoundation", Vector3.new(size.X + 2, 6, size.Z), cf * CFrame.new(0, -4, 0), DARK, Enum.Material.Rock, false)
	end
end

function Builder.Ensure(library: Folder): Model
	local existing = library:FindFirstChild(MODEL_NAME)
	if existing then
		assert(existing:IsA("Model"), "Classic Ascent must be a Model")
		if existing:GetAttribute("BuilderVersion") == 2 then return existing end
		assert(existing:GetAttribute("BuilderVersion") == 1, "Unrecognized authored course; reconcile before rebuilding")
		assert(not library:FindFirstChild(MODEL_NAME .. "_Placeholder"), "Placeholder archive already exists")
		existing.Name = MODEL_NAME .. "_Placeholder"
		local oldInfo = existing:FindFirstChild("CourseInfo")
		if oldInfo then
			oldInfo:SetAttribute("Enabled", false)
			oldInfo:SetAttribute("CourseId", "classic_ascent_placeholder")
		end
	end
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model:SetAttribute("BuilderVersion", 2)
	local info = folder(model, "CourseInfo")
	for key, value in pairs({ CourseId = "classic_ascent_point_to_point", DisplayName = "Classic Ascent · Alpine Expedition", RaceFormat = "PointToPoint", LapCount = 1, Enabled = true, Difficulty = "Intermediate", TargetNewPlayerTime = 360, TargetPracticedTime = 160, CheckpointCount = 19, TimingValidated = false }) do
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
	local start = block(model, "Start", Vector3.new(40, 3, 30), startCF, STONE, Enum.Material.Cobblestone)
	model.PrimaryPart = start
	start:SetAttribute("SectionIndex", 1)
	start:SetAttribute("SectionName", "Trailhead")
	plaque(markers, startCF * CFrame.new(0, 14, -12), "CLASSIC ASCENT", "ALPINE EXPEDITION")
	local nodes: { BasePart } = { start }
	local checkpointIndex, routeIndex, length = 0, 0, 0
	local previousPosition = startPosition
	for sectionIndex, section in ipairs(SECTIONS) do
		local group = folder(obstacles, string.format("%02d_%s", sectionIndex, section.name:gsub(" ", "")))
		for step = 1, section.count do
			local position = routePosition(sectionIndex, step)
			local nextPosition = if step < section.count then routePosition(sectionIndex, step + 1) elseif sectionIndex < #SECTIONS then routePosition(sectionIndex + 1, 1) else position + (position - previousPosition)
			local tangent = nextPosition - previousPosition
			local cf = CFrame.lookAt(position, position + Vector3.new(tangent.X, 0, tangent.Z))
			local landing = step == section.count / 2 or step == section.count
			local sizeZ = math.max(7, math.min((position - previousPosition).Magnitude, (nextPosition - position).Magnitude) - section.gap)
			local width = if landing then 26 else section.width
			local pad: Part
			if landing and sectionIndex == #SECTIONS and step == section.count then
				pad = block(model, "Finish", Vector3.new(36, 3, 30), cf, STONE, Enum.Material.Slate)
			elseif landing then
				checkpointIndex += 1
				pad = block(checkpoints, string.format("Checkpoint_%03d", checkpointIndex), Vector3.new(width, 3, math.max(18, sizeZ)), cf, section.color, section.material)
				checkpointDetails(markers, pad, checkpointIndex)
			else
				pad = block(group, string.format("Route_%03d", routeIndex + 1), Vector3.new(width, 3, sizeZ), cf, section.color, section.material)
				platformDetails(group, pad, section, step)
			end
			routeIndex += 1
			pad:SetAttribute("RouteIndex", routeIndex)
			pad:SetAttribute("SectionIndex", sectionIndex)
			pad:SetAttribute("SectionName", section.name)
			pad:SetAttribute("ObstacleStyle", section.style)
			table.insert(nodes, pad)
			length += (position - previousPosition).Magnitude
			previousPosition = position
			local zone = block(zones, string.format("Recovery_%03d", routeIndex), Vector3.new(width + 22, 3, sizeZ + 20), cf * CFrame.new(0, -12, 0), DARK, Enum.Material.SmoothPlastic, false)
			zone.Transparency, zone.CanTouch = 1, true
			if step == 1 then
				plaque(markers, cf * CFrame.new(width / 2 + 11, 8, 0), string.format("%02d  %s", sectionIndex, section.name:upper()), if sectionIndex < 8 then "FOLLOW THE AMBER TRAIL" else "THE SUMMIT IS CLOSE")
			end
		end
	end
	local general = block(zones, "FallZone_Main", Vector3.new(1000, 3, 1000), CFrame.new(CENTER + Vector3.new(0, 15, 0)), DARK, Enum.Material.SmoothPlastic, false)
	general.Transparency, general.CanTouch = 1, true
	local finish = model:FindFirstChild("Finish") :: Part
	for _, side in ipairs({ -1, 1 }) do
		local base = finish.CFrame * CFrame.new(side * 17, 0, -8)
		block(markers, "SummitGateColumn", Vector3.new(3, 24, 3), base * CFrame.new(0, 12, 0), DARK, Enum.Material.Slate, false)
		block(markers, "SummitBanner", Vector3.new(5, 12, 0.3), base * CFrame.new(side * 4, 16, 0), GOLD, Enum.Material.Fabric, false)
	end
	block(markers, "SummitLintel", Vector3.new(39, 3, 4), finish.CFrame * CFrame.new(0, 25, -8), STONE, Enum.Material.Limestone, false)
	plaque(markers, finish.CFrame * CFrame.new(0, 19, -7), "SUMMIT", "CLASSIC ASCENT")
	Environment.Build(model, nodes, CENTER)
	assert(checkpointIndex == 19, "Nineteen checkpoints required")
	info:SetAttribute("RouteLengthStuds", math.floor(length))
	info:SetAttribute("RouteTransitions", routeIndex)
	model.Parent = library
	return model
end

return Builder
