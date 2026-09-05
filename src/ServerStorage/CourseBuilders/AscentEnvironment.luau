--!strict

local Environment = {}
local ROCK = Color3.fromRGB(92, 104, 102)
local GRASS = Color3.fromRGB(91, 126, 79)
local SNOW = Color3.fromRGB(228, 239, 236)
local WOOD = Color3.fromRGB(106, 74, 48)
local AMBER = Color3.fromRGB(229, 164, 63)

type Node = BasePart

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, wedge: boolean?): BasePart
	local p = Instance.new(if wedge then "WedgePart" else "Part") :: BasePart
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function pine(parent: Instance, base: CFrame, scale: number, snowy: boolean)
	part(parent, "PineTrunk", Vector3.new(1.5, 15, 1.5) * scale, base * CFrame.new(0, 7.5 * scale, 0), WOOD, Enum.Material.Wood)
	for tier = 1, 3 do
		local width = (15 - tier * 3) * scale
		for _, turn in ipairs({0, math.pi}) do
			part(parent, "PineCrown", Vector3.new(width, 9 * scale, width / 2), base * CFrame.new(0, (5 + tier * 4) * scale, 0) * CFrame.Angles(0, turn, 0) * CFrame.new(0, 0, -width / 4), if snowy and tier > 1 then SNOW else Color3.fromRGB(40, 88 + tier * 7, 64), if snowy and tier > 1 then Enum.Material.Snow else Enum.Material.Grass, true)
		end
	end
end

local function banner(parent: Instance, base: CFrame, color: Color3)
	part(parent, "BannerPole", Vector3.new(0.6, 15, 0.6), base * CFrame.new(0, 7.5, 0), WOOD, Enum.Material.Wood)
	part(parent, "ExpeditionFlag", Vector3.new(5, 7, 0.2), base * CFrame.new(2.7, 10.5, 0), color, Enum.Material.Fabric)
end

local function mountain(parent: Instance, center: Vector3)
	-- The radial slope stays below the playable spiral; local shelves join its edges.
	for index = 1, 20 do
		local angle = index * math.pi * 2 / 20
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = center + radial * (210 + math.sin(index * 2.4) * 12) + Vector3.new(0, 120 + math.sin(index * 1.7) * 8, 0)
		local frame = CFrame.lookAt(position, position + radial)
		part(parent, "MountainButtress", Vector3.new(135, 370, 360), frame, ROCK:Lerp(Color3.fromRGB(70, 88, 82), (index % 4) * 0.1), Enum.Material.Rock, true)
	end
	for index = 1, 9 do
		local angle = index * 2.39996
		local radius = if index == 1 then 0 else 35 + index * 5
		local position = center + Vector3.new(math.cos(angle) * radius, 264 + index % 3 * 9, math.sin(angle) * radius)
		local frame = CFrame.new(position) * CFrame.Angles(0, angle, 0)
		part(parent, "SummitCrag", Vector3.new(56, 100 + index % 3 * 15, 78), frame, ROCK, Enum.Material.Slate, true)
		part(parent, "SnowCornice", Vector3.new(58, (100 + index % 3 * 15) * 0.35, 78 * 0.35), frame * CFrame.new(0, (100 + index % 3 * 15) * 0.325 + 0.7, 78 * 0.325), SNOW, Enum.Material.Snow, true)
	end
end

local function camp(parent: Instance, frame: CFrame)
	for _, side in ipairs({-1, 1}) do
		part(parent, "CanvasTent", Vector3.new(12, 8, 7), frame * CFrame.new(side * 3.5, 4, 0) * CFrame.Angles(0, side * math.pi / 2, 0), AMBER, Enum.Material.Fabric, true)
	end
	part(parent, "TentEntrance", Vector3.new(5, 5, 0.1), frame * CFrame.new(0, 2.5, -6.05), Color3.fromRGB(49, 57, 52), Enum.Material.Fabric)
	for i = 1, 3 do
		part(parent, "SupplyCrate", Vector3.new(4, 4, 4), frame * CFrame.new(10 + i % 2 * 4, 2 + math.floor(i / 3) * 4, 3), WOOD, Enum.Material.WoodPlanks)
	end
	banner(parent, frame * CFrame.new(-12, 0, 5), AMBER)
end

function Environment.Build(model: Model, nodes: {Node}, center: Vector3): Folder
	local root = Instance.new("Folder")
	root.Name = "Environment"
	root:SetAttribute("DecorationsAreNonGameplay", true)
	root.Parent = model.Decoration
	mountain(root, center)
	for index, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local radial = Vector3.new(node.Position.X - center.X, 0, node.Position.Z - center.Z).Unit
		local ground = CFrame.lookAt(node.Position - radial * (node.Size.X / 2 + 27) - Vector3.new(0, 4, 0), node.Position + radial * 20 - Vector3.new(0, 4, 0))
		local snowy = section >= 8
		local color = if snowy then SNOW elseif section <= 3 then GRASS else ROCK
		local material = if snowy then Enum.Material.Snow elseif section <= 3 then Enum.Material.Grass else Enum.Material.Slate
		-- Gorges and pillar jumps remain exposed; shelves sit on the mountain side.
		part(root, "TrailShelf", Vector3.new(math.max(20, node.Size.Z + 7), 14, 42), ground * CFrame.new(0, -7, 0), color, material)
		if index % 2 == 0 then
			part(root, "CliffFace", Vector3.new(node.Size.Z + 14, 94 + index % 3 * 7, 40), ground * CFrame.new(0, -52, 0) * CFrame.Angles(0, 0, math.rad((index % 3 - 1) * 7)), ROCK, Enum.Material.Rock, true)
		end
		if (section <= 3 or section == 7 or section == 8) and index % 3 == 0 then
			pine(root, ground * CFrame.new(0, 0, -3), 0.8 + (index % 4) * 0.15, snowy)
		elseif section == 5 and index % 2 == 0 then
			for column = 1, 3 do
				local height = 12 + (index + column) % 4 * 5
				part(root, "BasaltOrgan", Vector3.new(5, height, 6), ground * CFrame.new((column - 2) * 6, height / 2, -8), Color3.fromRGB(59, 75, 80), Enum.Material.Basalt)
			end
		elseif section == 7 and index % 2 == 0 then
			part(root, "CliffWall", Vector3.new(node.Size.Z + 4, 35, 15), ground * CFrame.new(0, 12, -10) * CFrame.Angles(0, 0, 0.12), ROCK, Enum.Material.Rock)
		elseif section >= 9 and index % 3 == 0 then
			banner(root, ground, AMBER)
		end
		if section == 2 then
			local water = part(root, "GardenStream", Vector3.new(node.Size.Z + 8, 0.4, 12), ground * CFrame.new(0, 0.3, 8), Color3.fromRGB(54, 161, 155), Enum.Material.Glass)
			water.Transparency = 0.2
			part(root, "StreamCascade", Vector3.new(2, 3, 12), ground * CFrame.new(-node.Size.Z / 2 - 2, -1, 8), Color3.fromRGB(157, 223, 208), Enum.Material.Glass).Transparency = 0.25
			if index % 3 == 0 then
				part(root, "GardenBoulder", Vector3.new(8, 6, 7), ground * CFrame.new(3, 2, -4) * CFrame.Angles(0, index, 0), ROCK, Enum.Material.Slate, true)
			end
		end
		if section == 6 and index % 2 == 0 then
			for _, x in ipairs({-7, 7}) do
				part(root, "RuinColumn", Vector3.new(3, 18, 4), ground * CFrame.new(x, 9, -4), Color3.fromRGB(176, 167, 140), Enum.Material.Limestone)
			end
			part(root, "RuinLintel", Vector3.new(19, 4, 5), ground * CFrame.new(0, 19, -4) * CFrame.Angles(0, 0, 0.06), Color3.fromRGB(176, 167, 140), Enum.Material.Limestone)
		end
		if index == 3 then camp(root, ground * CFrame.new(0, 0, -3)) end
	end
	return root
end

return Environment
