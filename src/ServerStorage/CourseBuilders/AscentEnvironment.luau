--!strict

local Environment = {}

local ROCK = Color3.fromRGB(91, 101, 99)
local DARK_ROCK = Color3.fromRGB(55, 67, 68)
local PALE_ROCK = Color3.fromRGB(151, 151, 133)
local GRASS = Color3.fromRGB(71, 111, 72)
local PINE = Color3.fromRGB(35, 78, 57)
local SNOW = Color3.fromRGB(226, 237, 235)
local ICE = Color3.fromRGB(158, 201, 216)
local WOOD = Color3.fromRGB(103, 72, 46)
local CANVAS = Color3.fromRGB(194, 139, 64)

type Node = BasePart

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, solid: boolean?): Part
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, cf
	object.Color, object.Material = color, material
	object.Anchored, object.CanCollide = true, solid == true
	object.CanTouch, object.CanQuery = false, solid == true
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function roundRock(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local object = part(parent, name, size, cf, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, object
	return object
end

local function wedge(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, solid: boolean?): WedgePart
	local object = Instance.new("WedgePart")
	object.Name, object.Size, object.CFrame = name, size, cf
	object.Color, object.Material = color, material
	object.Anchored, object.CanCollide = true, solid == true
	object.CanTouch, object.CanQuery = false, solid == true
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function mountain(parent: Instance, center: Vector3)
	local root = Instance.new("Folder")
	root.Name, root.Parent = "SummitMassif", parent
	for index = 1, 12 do
		local angle = (index - 1) * math.pi * 2 / 12
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = center + outward * 150 + Vector3.new(0, 185, 0)
		local mass = wedge(root, "MountainFace_" .. index, Vector3.new(155, 410, 300), CFrame.lookAt(position, position + outward), if index % 2 == 0 then DARK_ROCK else ROCK, Enum.Material.Rock, true)
		mass:SetAttribute("EnvironmentSolid", true)
	end
	for _, side in ipairs({ -1, 1 }) do
		local ridgeFrame = CFrame.new(center + Vector3.new(0, 382.5, side * 25)) * CFrame.Angles(0, if side == -1 then 0 else math.pi, 0)
		wedge(root, "SummitSnowRidge", Vector3.new(100, 85, 50), ridgeFrame, SNOW, Enum.Material.Snow, true)
	end
end

local function pine(parent: Instance, frame: CFrame, scale: number, snowy: boolean)
	part(parent, "PineTrunk", Vector3.new(1.4 * scale, 28, 1.4 * scale), frame * CFrame.new(0, 14, 0), WOOD, Enum.Material.Wood)
	for tier = 1, 3 do
		local width = (26 - tier * 4) * scale
		local crown = part(parent, "PineCrown", Vector3.new(width, 8 * scale, width), frame * CFrame.new(0, 18 + tier * 4 * scale, 0), if snowy and tier >= 2 then SNOW else PINE:Lerp(GRASS, tier * 0.08), if snowy and tier >= 2 then Enum.Material.Snow else Enum.Material.Grass)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, crown
	end
end

local function fern(parent: Instance, frame: CFrame, scale: number, snowy: boolean)
	for leaf = 0, 3 do
		local angle = leaf * math.pi / 2
		part(parent, "FernFrond", Vector3.new(0.25, 0.8, 5) * scale, frame * CFrame.new(0, 1.2 * scale, 0) * CFrame.Angles(math.rad(-18), angle, 0) * CFrame.new(0, 0, -2 * scale), if snowy then Color3.fromRGB(127, 155, 137) else GRASS, Enum.Material.Grass)
	end
end

local function lowSupport(parent: Instance, node: Node, section: number, step: number)
	local frame = node.CFrame
	local suspended = node:GetAttribute("MotionKind") == "MovingLog" or (section == 4 and step % 4 ~= 0 and node.Parent.Name ~= "Checkpoints")
	local supportTop = if suspended then node.Size.Y / 2 - 17 else -node.Size.Y / 2
	local height = 30 + (step % 3) * 7
	local color = if section >= 8 then Color3.fromRGB(111, 137, 145) else DARK_ROCK
	local supportWidth = math.max(7, math.min(14, node.Size.X - 1))
	for _, x in ipairs(if node.Size.X >= 50 then { -20, 0, 20 } else { 0 }) do
		local support = roundRock(parent, "TrailRockSupport", Vector3.new(supportWidth, height, math.max(5, node.Size.Z - 1)), frame * CFrame.new(x, supportTop - height / 2, 0), color, if section >= 8 then Enum.Material.Glacier else Enum.Material.Rock)
		support.CanCollide, support.CanQuery = true, true
		support:SetAttribute("EnvironmentSolid", true)
	end
	local spurTop = node.Size.Y / 2 - 17
	local spur = roundRock(parent, "MountainRoot", Vector3.new(35, height + 18, math.max(13, node.Size.Z + 2)), frame * CFrame.new(43, spurTop - (height + 18) / 2, 3), color, Enum.Material.Rock)
	spur.CanCollide, spur.CanQuery = true, true
	spur:SetAttribute("EnvironmentSolid", true)
end

local function risingHillside(parent: Instance, node: Node, center: Vector3, section: number, variation: number)
	local padTop = node.Size.Y / 2
	local fromCenter = node.Position - center
	local horizontalRadius = Vector3.new(fromCenter.X, 0, fromCenter.Z).Magnitude
	local depth = math.min(140, math.max(95, horizontalRadius - 50))
	local height = 96 + variation * 4
	local midpoint = node.CFrame * CFrame.new(30 + depth / 2, padTop + 38 + variation * 2, 0)
	local slopeFrame = CFrame.lookAt(midpoint.Position, midpoint.Position - node.CFrame.RightVector)
	local color = if section >= 8 then Color3.fromRGB(139, 158, 158) elseif section <= 3 then Color3.fromRGB(82, 108, 78) else ROCK
	local material = if section >= 8 then Enum.Material.Glacier elseif section <= 3 then Enum.Material.Rock else Enum.Material.Slate
	local face = wedge(parent, "RisingMountainSide", Vector3.new(math.max(28, node.Size.Z * 2.5), height, depth), slopeFrame, color, material, true)
	face:SetAttribute("EnvironmentSolid", true)
	if section >= 8 then
		wedge(parent, "HillsideSnowField", Vector3.new(math.max(28, node.Size.Z * 2.5) + 0.1, height * 0.45 + 0.2, depth * 0.45), slopeFrame * CFrame.new(0, height * 0.275 + 0.1, depth * 0.275), SNOW, Enum.Material.Snow)
	end
end

local function bankScenery(parent: Instance, node: Node, section: number, step: number)
	local frame, top = node.CFrame, node.Size.Y / 2
	local snowy = section >= 8
	local color = if snowy then SNOW elseif section <= 3 then GRASS else ROCK
	local material = if snowy then Enum.Material.Snow elseif section <= 3 then Enum.Material.Grass else Enum.Material.Slate
	for _, x in ipairs({ 53, 70 }) do
		local height = 12 + ((step + math.floor(x)) % 3) * 4
		roundRock(parent, "InnerTrailBank", Vector3.new(18, height, math.max(14, node.Size.Z + 5)), frame * CFrame.new(x, top - 4, 1), color, material)
	end
	if step % 3 == 1 and (section <= 3 or section == 8) then
		pine(parent, frame * CFrame.new(55, top + 4, (step % 2) * 5 - 2), 0.72 + (step % 3) * 0.08, snowy)
	elseif step % 4 == 1 then
		roundRock(parent, "TrailBoulder", Vector3.new(9 + step % 3, 7, 8), frame * CFrame.new(53, top + 1, 2), color:Lerp(DARK_ROCK, 0.35), material)
	end
	if section <= 3 and step % 2 == 0 then fern(parent, frame * CFrame.new(45, top + 2, -3), 0.8, false) end
end

local function centerIsland(parent: Instance, node: Node, section: number, step: number)
	if step % 4 ~= 1 then return end
	local frame, top, snowy = node.CFrame, node.Size.Y / 2, section >= 8
	local positions = if section <= 3 then { -32, -10, 10 } else { -10, 10 }
	for _, x in ipairs(positions) do
		roundRock(parent, "BetweenRouteIsland", Vector3.new(5, 5, math.min(8, node.Size.Z - 1)), frame * CFrame.new(x, top - 1.8, 0), if snowy then SNOW else GRASS, if snowy then Enum.Material.Snow else Enum.Material.Grass)
		if section <= 3 then
			pine(parent, frame * CFrame.new(x, top + 0.5, 0), 0.74 + (math.abs(x) % 3) * 0.06, false)
		elseif section == 8 then
			fern(parent, frame * CFrame.new(x, top + 0.6, 0), 0.55, snowy)
		else
			roundRock(parent, "BetweenRouteStone", Vector3.new(2.8, 4, 2.8), frame * CFrame.new(x, top + 0.8, 0), if snowy then ICE else PALE_ROCK, if snowy then Enum.Material.Glacier else Enum.Material.Rock)
		end
	end
end

local function campHut(parent: Instance, node: Node)
	local hut = node.CFrame * CFrame.new(52, node.Size.Y / 2, 1)
	part(parent, "CampFloor", Vector3.new(18, 1, 14), hut * CFrame.new(0, 0.5, 0), WOOD, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -8, 8 }) do
		for _, z in ipairs({ -6, 6 }) do part(parent, "HutPost", Vector3.new(1, 10, 1), hut * CFrame.new(x, 5.5, z), WOOD, Enum.Material.Wood) end
	end
	part(parent, "HutBackWall", Vector3.new(17, 8, 1), hut * CFrame.new(0, 5, 6), Color3.fromRGB(130, 91, 53), Enum.Material.WoodPlanks)
	for _, side in ipairs({ -1, 1 }) do
		part(parent, "PitchedCampRoof", Vector3.new(11, 1, 17), hut * CFrame.new(side * 4.5, 11, 0) * CFrame.Angles(0, 0, math.rad(-side * 30)), CANVAS, Enum.Material.Fabric)
	end
	for crate = 1, 3 do part(parent, "SupplyCrate", Vector3.new(3, 3, 3), hut * CFrame.new(-5 + crate * 4, 2, 3), WOOD, Enum.Material.WoodPlanks) end
end

local function gorge(parent: Instance, node: Node, step: number)
	local frame, top = node.CFrame, node.Size.Y / 2
	for _, side in ipairs({ -1, 1 }) do roundRock(parent, "RiverGorgeWall", Vector3.new(13, 30, node.Size.Z + 5), frame * CFrame.new(side * 35, top - 12, 0), DARK_ROCK, Enum.Material.Rock) end
	if step % 4 == 1 then
		local fall = part(parent, "Waterfall", Vector3.new(1.1, 27, 8), frame * CFrame.new(48, top - 9, 2), Color3.fromRGB(105, 190, 207), Enum.Material.Glass)
		fall.Transparency = 0.22
		part(parent, "WaterfallMist", Vector3.new(9, 1, 9), frame * CFrame.new(43, top - 21, 2), Color3.fromRGB(202, 235, 235), Enum.Material.Neon).Transparency = 0.45
	end
end

local function bridgeAnchors(parent: Instance, node: Node, step: number)
	local top = node.Size.Y / 2 - 17
	for _, x in ipairs({ -29, 29 }) do
		local height = 34 + step % 3 * 5
		local anchor = part(parent, "BridgeGorgeAnchor", Vector3.new(8, height, math.max(8, node.Size.Z - 2)), node.CFrame * CFrame.new(x, top - height / 2, 0), PALE_ROCK, Enum.Material.Rock, true)
		anchor:SetAttribute("EnvironmentSolid", true)
	end
end

local function basaltCavern(parent: Instance, node: Node, step: number)
	if step % 3 ~= 0 then return end
	local frame, top = node.CFrame, node.Size.Y / 2
	for _, x in ipairs({ -32, 32 }) do part(parent, "BasaltCavernColumn", Vector3.new(7, 23 + step % 4 * 3, 8), frame * CFrame.new(x, top + 7, 0), DARK_ROCK, Enum.Material.Basalt) end
	for _, x in ipairs({ -20, 0, 20 }) do
		part(parent, "BasaltCavernCeiling", Vector3.new(24, 9, node.Size.Z + 6), frame * CFrame.new(x, top + 26, 0) * CFrame.Angles(0, 0, math.rad(if (x + step) % 2 == 0 then 4 else -4)), DARK_ROCK, Enum.Material.Basalt)
	end
end

local function overheadGallery(parent: Instance, node: Node, section: number, step: number)
	local frame, top = node.CFrame, node.Size.Y / 2
	local color = if section >= 9 then ICE elseif section == 6 then PALE_ROCK else ROCK
	local material = if section >= 9 then Enum.Material.Glacier elseif section == 6 then Enum.Material.Limestone else Enum.Material.Rock
	if step % 4 == 1 then
		for _, x in ipairs({ -32, 32 }) do roundRock(parent, if section == 6 then "RuinGalleryPier" else "RockArchPier", Vector3.new(9, 29, 10), frame * CFrame.new(x, top + 10, 0), color, material) end
		for _, x in ipairs({ -20, 0, 20 }) do roundRock(parent, if section == 6 then "RuinGalleryLintel" else "RockArchCrown", Vector3.new(28, 8, node.Size.Z + 5), frame * CFrame.new(x, top + 27, 0), color, material) end
	end
end

local function concealRockfallSources(parent: Instance, model: Model)
	local hazards = model:FindFirstChild("Hazards")
	if not hazards then return end
	for _, descendant in ipairs(hazards:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "FallingRock" then
			local source = descendant :: BasePart
			roundRock(parent, "RockfallSourcePocket", Vector3.new(13, 11, 13), source.CFrame, source.Color, source.Material)
			for _, x in ipairs({ -8, 8 }) do
				roundRock(parent, "RockfallSourceShelf", Vector3.new(12, 9, 16), source.CFrame * CFrame.new(x, 2, 0), source.Color:Lerp(DARK_ROCK, 0.18), source.Material)
			end
		end
	end
end

local function iceScenery(parent: Instance, node: Node, step: number)
	if step % 3 ~= 1 then return end
	local frame, top = node.CFrame, node.Size.Y / 2
	for _, x in ipairs({ -32, 32 }) do part(parent, "IceArchPillar", Vector3.new(6, 23, 7), frame * CFrame.new(x, top + 9, 0) * CFrame.Angles(0, 0, math.rad(-x / 8)), ICE, Enum.Material.Glacier) end
	part(parent, "IceArchCrown", Vector3.new(69, 7, node.Size.Z + 3), frame * CFrame.new(0, top + 24, 0), ICE, Enum.Material.Glacier)
end

local function avalancheCornice(parent: Instance, node: Node, step: number)
	if step % 3 ~= 1 then return end
	local frame, top = node.CFrame, node.Size.Y / 2
	for _, x in ipairs({ -21, 0, 21 }) do roundRock(parent, "AvalancheCornice", Vector3.new(27, 10 + step % 3, node.Size.Z + 10), frame * CFrame.new(x, top + 31, 2), SNOW, Enum.Material.Snow) end
	for _, x in ipairs({ -25, 26 }) do roundRock(parent, "CorniceAnchor", Vector3.new(13, 25, 13), frame * CFrame.new(x, top + 16, 3), Color3.fromRGB(114, 139, 147), Enum.Material.Glacier) end
end

function Environment.Build(model: Model, nodes: { Node }, center: Vector3): Folder
	local root = Instance.new("Folder")
	root.Name, root.Parent = "Environment", model.Decoration
	mountain(root, center)
	for nodeIndex, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local step = (node:GetAttribute("SectionStep") or 0) :: number
		local checkpoint = node.Parent == model.Checkpoints or node.Name == "Start" or node.Name == "Finish"
		lowSupport(root, node, section, step)
		if nodeIndex % 2 == 1 then risingHillside(root, node, center, section, nodeIndex % 3) end
		bankScenery(root, node, section, step)
		if section == 1 or section == 8 or section == 10 then
			local ground = part(root, "SharedAdventureGround", Vector3.new(node.Size.X + (if checkpoint then 2 else 54), 6, node.Size.Z + 3), node.CFrame * CFrame.new(0, node.Size.Y/2 - 3.25, 0), if section == 1 then GRASS else SNOW, if section == 1 then Enum.Material.Grass else Enum.Material.Snow, true)
			ground:SetAttribute("EnvironmentSolid", true)
		end
		if not checkpoint then centerIsland(root, node, section, step) end
		if section == 1 and step == 2 then
			campHut(root, node)
		elseif section == 2 then
			gorge(root, node, step)
		elseif section == 3 and step % 3 == 1 then
			for _, x in ipairs({ -31, 31 }) do roundRock(root, "SwitchbackMarker", Vector3.new(8, 13, 9), node.CFrame * CFrame.new(x, node.Size.Y / 2 + 3, 0), PALE_ROCK, Enum.Material.Rock) end
		elseif section == 4 and not checkpoint then
			bridgeAnchors(root, node, step)
		elseif section == 5 then
			basaltCavern(root, node, step)
		elseif section == 6 or section == 7 then
			overheadGallery(root, node, section, step)
		elseif section == 8 and not checkpoint and step % 3 == 1 then
			for _, x in ipairs({ -29, 29 }) do pine(root, node.CFrame * CFrame.new(x, node.Size.Y / 2, 0), 0.7, true) end
		elseif section == 9 then
			iceScenery(root, node, step)
			if not checkpoint then overheadGallery(root, node, section, step) end
		elseif section == 10 then
			avalancheCornice(root, node, step)
		end
	end
	concealRockfallSources(root, model)
	for _, branch in ipairs(model.Obstacles:GetDescendants()) do
		if branch:IsA("BasePart") and branch:GetAttribute("RoutePad") == true and branch:GetAttribute("Lane") ~= 0 then
			lowSupport(root, branch, branch:GetAttribute("SectionIndex") :: number, branch:GetAttribute("SectionStep") :: number)
		end
	end
	return root
end

return Environment
