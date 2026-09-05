--!strict

local Props = require(script.Parent.AscentProps)

local Environment = {}

local ROCK = Color3.fromRGB(91, 101, 99)
local DARK_ROCK = Color3.fromRGB(55, 67, 68)
local GRASS = Color3.fromRGB(71, 111, 72)
local SNOW = Color3.fromRGB(226, 237, 235)

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

local function placeProp(parent: Instance, kind: string, node: Node, x: number, z: number, height: number, yaw: number?, roll: number?)
	local bottom = node.CFrame * CFrame.new(x, node.Size.Y / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), math.rad(roll or 0))
	Props.Place(parent, kind, bottom, height)
end

local function sharedGround(parent: Instance, node: Node, section: number, checkpoint: boolean)
	local width = if checkpoint then math.max(node.Size.X + 2, 64) else 62
	local ground = part(parent, "SharedAdventureGround", Vector3.new(width, 6, node.Size.Z + 3), node.CFrame * CFrame.new(0, node.Size.Y / 2 - 3.25, 0), if section == 1 then GRASS else SNOW, if section == 1 then Enum.Material.Grass else Enum.Material.Snow, true)
	ground:SetAttribute("EnvironmentSolid", true)
end

local function scenicX(random: Random): number
	if random:NextNumber() < 0.5 then return random:NextNumber(-59, -40) end
	return random:NextNumber(40, 59)
end

local function soilPocket(parent: Instance, node: Node, x: number, z: number): CFrame
	local depth = math.max(3, math.min(6, node.Size.Z - 1))
	local pocket = part(parent, "PlantedSoilPocket", Vector3.new(5, 0.35, depth), node.CFrame * CFrame.new(x, node.Size.Y / 2 + 0.16, z), Color3.fromRGB(67, 58, 39), Enum.Material.Ground)
	pocket.CanCollide, pocket.CanQuery = false, false
	return node.CFrame * CFrame.new(x, node.Size.Y / 2 + 0.35, z)
end

local function forestWall(parent: Instance, node: Node, section: number, step: number, snowy: boolean, checkpoint: boolean)
	local seed = (node:GetAttribute("RouteIndex") or step) :: number
	local random = Random.new(seed * 1129 + section * 71)
	-- Wider gaps are intentional view windows; populated nodes form a dense left-biased forest bank.
	if random:NextNumber() < (if snowy then 0.16 else 0.2) then return end
	local count = random:NextInteger(3, 6)
	for _ = 1, count do
		local x = if random:NextNumber() < 0.72 then random:NextNumber(-59, -42) else random:NextNumber(42, 59)
		local kind = if not snowy and random:NextNumber() < 0.3 then "Cedar" elseif snowy and random:NextNumber() < 0.7 then "PineSnow" elseif random:NextNumber() < 0.38 then "PineWind" else "PineA"
		placeProp(parent, kind, node, x, random:NextNumber(-node.Size.Z * 0.42, node.Size.Z * 0.42), random:NextNumber(if snowy then 18 else 19, if snowy then 26 else 25), random:NextNumber(-50, 50))
	end
	if not checkpoint then
		for _ = 1, random:NextInteger(2, 5) do
			local x = if random:NextNumber() < 0.7 then random:NextNumber(-58, -41) else random:NextNumber(41, 58)
			local kind = if snowy then (if random:NextNumber() < 0.58 then "SnowCoverOutcrop" else "LichenBoulder") elseif random:NextNumber() < 0.34 then "RootLog" elseif random:NextNumber() < 0.56 then "LichenBoulder" elseif random:NextNumber() < 0.55 then "Fern" elseif random:NextNumber() < 0.78 then "Wildflowers" else "GrassClump"
			local height = if kind == "RootLog" then random:NextNumber(2.5, 3.8) elseif kind == "SnowCoverOutcrop" then random:NextNumber(3.5, 6) elseif kind == "LichenBoulder" then random:NextNumber(2.2, 4.5) else random:NextNumber(1.0, 1.7)
			placeProp(parent, kind, node, x, random:NextNumber(-node.Size.Z * 0.42, node.Size.Z * 0.42), height, random:NextNumber(0, 360))
		end
	end
	if not snowy and not checkpoint and section == 1 and step > 0 and random:NextNumber() < 0.65 then
		local x = if random:NextNumber() < 0.5 then -10 else 10
		local z = random:NextNumber(-node.Size.Z * 0.25, node.Size.Z * 0.25)
		local base = soilPocket(parent, node, x, z)
		for plantIndex = 1, random:NextInteger(2, 4) do
			Props.Place(parent, if random:NextNumber() < 0.65 then "GrassClump" else "Wildflowers", base * CFrame.new(random:NextNumber(-1.5, 1.5), 0, random:NextNumber(-1.8, 1.8)) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), random:NextNumber(1.1, 1.65))
		end
	end
end

local function rockyScenery(parent: Instance, node: Node, section: number, step: number)
	local seed = (node:GetAttribute("RouteIndex") or step) :: number
	local random = Random.new(seed * 811 + section * 137)
	if random:NextNumber() < (if section == 4 then 0.68 else 0.38) then return end
	local count = if section == 4 then 1 else random:NextInteger(1, if section == 5 then 3 else 2)
	for _ = 1, count do
		local kind = if section == 5 or random:NextNumber() < 0.42 then "BasaltBoulder" elseif random:NextNumber() < 0.3 then "LichenBoulder" else "GraniteBoulder"
		placeProp(parent, kind, node, scenicX(random), random:NextNumber(-node.Size.Z * 0.4, node.Size.Z * 0.4), random:NextNumber(3.4, if section == 5 then 6.2 else 5.4), random:NextNumber(0, 360))
	end
	if section == 6 and random:NextNumber() < 0.32 then
		placeProp(parent, if random:NextNumber() < 0.5 then "RuinPillarA" else "RuinPillarB", node, scenicX(random), random:NextNumber(-2, 2), random:NextNumber(10, 15), random:NextNumber(-25, 25))
	end
end

local function riverForest(parent: Instance, node: Node, step: number)
	local seed = (node:GetAttribute("RouteIndex") or step) :: number
	local random = Random.new(seed * 1237 + 29)
	if random:NextNumber() < 0.25 then return end
	for _ = 1, random:NextInteger(3, 5) do
		local x = if random:NextNumber() < 0.72 then random:NextNumber(-63, -49) else random:NextNumber(49, 63)
		placeProp(parent, if random:NextNumber() < 0.3 then "Cedar" elseif random:NextNumber() < 0.38 then "PineWind" else "PineA", node, x, random:NextNumber(-node.Size.Z * 0.4, node.Size.Z * 0.4), random:NextNumber(18, 24), random:NextNumber(-45, 45))
	end
	if random:NextNumber() < 0.72 then
		placeProp(parent, if random:NextNumber() < 0.5 then "RootLog" else "LichenBoulder", node, random:NextNumber(-62, -50), random:NextNumber(-node.Size.Z * 0.35, node.Size.Z * 0.35), random:NextNumber(2.8, 4.4), random:NextNumber(0, 360))
	end
end

local function iceScenery(parent: Instance, node: Node, step: number)
	local seed = (node:GetAttribute("RouteIndex") or step) :: number
	local random = Random.new(seed * 947 + 901)
	if random:NextNumber() < 0.48 then return end
	for _ = 1, random:NextInteger(2, 4) do
		placeProp(parent, if random:NextNumber() < 0.5 then "IceToothA" else "IceToothB", node, scenicX(random), random:NextNumber(-node.Size.Z * 0.4, node.Size.Z * 0.4), random:NextNumber(18, 35), random:NextNumber(-18, 18))
	end
	if random:NextNumber() < 0.55 then placeProp(parent, "SnowCoverOutcrop", node, scenicX(random), random:NextNumber(-2, 2), random:NextNumber(4.5, 7.5), random:NextNumber(-25, 25)) end
end

local function summitScenery(parent: Instance, node: Node, step: number)
	if step >= 8 then return end
	local random = Random.new(step * 613 + 41)
	if random:NextNumber() < 0.5 then return end
	placeProp(parent, "SnowCoverOutcrop", node, scenicX(random), random:NextNumber(-node.Size.Z * 0.3, node.Size.Z * 0.3), random:NextNumber(4.8, 7), random:NextNumber(-35, 35))
end

function Environment.Build(model: Model, nodes: { Node }, center: Vector3): Folder
	local root = Instance.new("Folder")
	root.Name, root.Parent = "Environment", model.Decoration
	Props.Prepare()
	mountain(root, center)
	local summitFrame = CFrame.new(center + Vector3.new(0, 180, 0)) * CFrame.Angles(0, math.rad(24), 0)
	local summit = Props.Place(root, "AlpineMassif", summitFrame, 380)
	for _, mesh in ipairs(summit:GetDescendants()) do
		if mesh:IsA("BasePart") then
			local relative = summitFrame:ToObjectSpace(mesh.CFrame)
			mesh.Size *= Vector3.new(.65,1,.65)
			mesh.CFrame = summitFrame*CFrame.new(relative.Position*Vector3.new(.65,1,.65))*relative.Rotation
		end
	end
	for nodeIndex, node in ipairs(nodes) do
		local frame = node:GetAttribute("SceneryFrame")
		if typeof(frame) == "CFrame" then
			node = node:Clone()
			node.CFrame = frame
		end
		local section = node:GetAttribute("SectionIndex") :: number
		local step = (node:GetAttribute("SectionStep") or 0) :: number
		local checkpoint = node.Parent == model.Checkpoints or node.Name == "Start" or node.Name == "Finish"
		if nodeIndex % 2 == 1 then risingHillside(root, node, center, section, nodeIndex % 3) end
		if section == 1 or section == 8 or section == 10 then sharedGround(root, node, section, checkpoint) end

		if section == 1 then forestWall(root, node, section, step, false, checkpoint)
		elseif section == 2 then riverForest(root, node, step)
		elseif section == 3 or section == 4 or section == 5 or section == 6 or section == 7 then rockyScenery(root, node, section, step)
		elseif section == 8 then forestWall(root, node, section, step, true, checkpoint)
		elseif section == 9 then iceScenery(root, node, step)
		elseif section == 10 then summitScenery(root, node, step)
		end
	end
	return root
end

return Environment
