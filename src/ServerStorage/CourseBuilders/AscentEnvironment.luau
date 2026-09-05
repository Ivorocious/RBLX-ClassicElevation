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
	for index = 1, 14 do
		local angle = index * math.pi * 2 / 14
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = center + radial * 203 + Vector3.new(0, 112, 0)
		part(parent, "MountainMass", Vector3.new(174, 350, 370), CFrame.lookAt(position, position + radial), ROCK, Enum.Material.Rock, true)
	end
	-- Paired slopes share a ridge; the snow follows the same slope without loose caps.
	for _, ridge in ipairs({{x = 0, z = 0, width = 124, depth = 170, height = 88}, {x = 72, z = 25, width = 65, depth = 96, height = 53}}) do
		for _, side in ipairs({-1, 1}) do
			local cf = CFrame.new(center + Vector3.new(ridge.x, 223 + ridge.height / 2, ridge.z + side * ridge.depth / 4)) * CFrame.Angles(0, if side == -1 then 0 else math.pi, 0)
			part(parent, "SummitRidge", Vector3.new(ridge.width, ridge.height, ridge.depth / 2), cf, ROCK, Enum.Material.Slate, true)
			part(parent, "SettledSummitSnow", Vector3.new(ridge.width + 0.2, ridge.height * 0.45 + 0.4, ridge.depth * 0.225), cf * CFrame.new(0, ridge.height * 0.275 + 0.2, ridge.depth * 0.1375), SNOW, Enum.Material.Snow, true)
		end
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
	root.Name, root.Parent = "Environment", model.Decoration
	mountain(root, center)
	for index, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local radial = Vector3.new(node.Position.X - center.X, 0, node.Position.Z - center.Z).Unit
		local snowy = section >= 8
		local openTrail = section == 1 or section == 10
		local top = node.Position.Y + node.Size.Y / 2
		local depth = math.min(150, (node.Position - center).Magnitude - 45)
		local tangentLength = math.max(node.Size.Z + 10, 24)
		local innerEdge = node.Size.X / 2 - 1
		local edgePosition = node.Position - radial * innerEdge
		local frame = CFrame.lookAt(Vector3.new(edgePosition.X, top, edgePosition.Z), Vector3.new(edgePosition.X, top, edgePosition.Z) + radial)
		local color = if snowy then SNOW elseif section <= 3 then GRASS else ROCK
		local material = if snowy then Enum.Material.Snow elseif section <= 3 then Enum.Material.Grass else Enum.Material.Slate
		local bankHeight = if openTrail then 0 else 11
		local bank = part(root, "ConnectedMountainBank", Vector3.new(tangentLength, 100 + bankHeight, depth), frame * CFrame.new(0, (bankHeight - 100) / 2, depth / 2 + (if openTrail then 0 else 6)), color, material)
		bank.CanCollide, bank.CanQuery = true, true
		bank:SetAttribute("EnvironmentSolid", true)
		if not openTrail and section ~= 4 and node:GetAttribute("HazardType") ~= "Crumble" then
			part(root, "JoinedLedgeCorbel", Vector3.new(node.Size.Z * 0.8, 18, node.Size.X / 2 + 14), frame * CFrame.new(0, -12, 3), ROCK, Enum.Material.Rock)
		end
		if openTrail then
			local shoulder = part(root, "TrailShoulder", Vector3.new(tangentLength, 14, node.Size.X + 10), node.CFrame * CFrame.new(0, -5.6, 0), color, material)
			shoulder.Size = Vector3.new(node.Size.X + 8, 14, node.Size.Z + 6)
			shoulder.CanCollide, shoulder.CanQuery = true, true
			shoulder:SetAttribute("EnvironmentSolid", true)
		end
		-- The support face reaches into the mountain instead of ending in mid-air.
		local footing = part(root, "EmbeddedCliffFooting", Vector3.new(tangentLength, 104, depth + node.Size.X / 2), frame * CFrame.new(0, -67, depth / 2 - node.Size.X / 4), ROCK, Enum.Material.Rock)
		footing.CanCollide, footing.CanQuery = true, true
		footing:SetAttribute("EnvironmentSolid", true)
		local propBase = frame * CFrame.new(0, bankHeight, 18)
		if (section <= 3 or section == 8) and index % 3 == 0 then
			pine(root, propBase, 0.8 + index % 3 * 0.12, snowy)
		elseif section == 5 and index % 2 == 0 then
			for column = 1, 3 do
				local height = 8 + (index + column) % 3 * 5
				part(root, "BasaltOutcrop", Vector3.new(5, height, 7), propBase * CFrame.new((column - 2) * 5, height / 2, 0), Color3.fromRGB(57, 73, 77), Enum.Material.Basalt)
			end
		elseif section == 6 and index % 3 == 0 then
			for _, x in ipairs({-6, 6}) do
				part(root, "RuinColumn", Vector3.new(3, 12, 4), propBase * CFrame.new(x, 6, 0), Color3.fromRGB(176, 167, 140), Enum.Material.Limestone)
			end
			part(root, "RuinLintel", Vector3.new(16, 3, 5), propBase * CFrame.new(0, 13, 0), Color3.fromRGB(176, 167, 140), Enum.Material.Limestone)
		elseif section >= 9 and index % 5 == 0 then banner(root, propBase, AMBER) end
		if section == 2 or section == 5 then
			local pool = part(root, if section == 2 then "ScaldingSpring" else "MoltenFissure", Vector3.new(node.Size.X + 12, 1, node.Size.Z + 8), node.CFrame * CFrame.new(0, -6, 0), if section == 2 then Color3.fromRGB(85, 181, 153) else Color3.fromRGB(219, 86, 34), Enum.Material.Neon)
			pool.CanTouch, pool.CanQuery = true, true
			pool:SetAttribute("HazardType", "Kill")
		end
		if index == 2 then camp(root, propBase * CFrame.new(0, 0, 4)) end
	end
	return root
end

return Environment
