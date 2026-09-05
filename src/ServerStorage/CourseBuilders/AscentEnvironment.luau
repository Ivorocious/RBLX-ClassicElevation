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

local function cliffFoundation(parent: Instance, node: Node, section: number, variation: number)
	if section == 4 or section == 5 then return end
	local width = math.max(12, node.Size.Z + 4)
	local height = 22 + variation * 4
	local face = wedge(parent, "AngularTrailFoundation", Vector3.new(width, height, 24), node.CFrame * CFrame.new(29, node.Size.Y / 2 - 12, 0) * CFrame.Angles(0, math.pi / 2, 0), if section >= 8 then Color3.fromRGB(124, 148, 154) else DARK_ROCK, if section >= 8 then Enum.Material.Glacier else Enum.Material.Rock, true)
	face:SetAttribute("EnvironmentSolid", true)
end

local function forestCluster(parent: Instance, node: Node, step: number, snowy: boolean, force: boolean?)
	local seed = (node:GetAttribute("RouteIndex") or step) :: number
	local random = Random.new(seed * 977 + (if snowy then 89 else 13))
	if not force and random:NextNumber() > (if snowy then 0.62 else 0.72) then return end
	local choices = if snowy then { "PineSnow", "PineWind", "PineA" } else { "PineA", "PineWind", "PineA" }
	local positions: { number } = {}
	local desired = random:NextInteger(2, 3)
	for _ = 1, 30 do
		if #positions >= desired then break end
		local candidate = random:NextNumber(-25, 25)
		local clear = true
		for _, existing in ipairs(positions) do if math.abs(candidate - existing) < 8 then clear = false end end
		if snowy then
			for _, lane in ipairs({ -20, 0, 20 }) do if math.abs(candidate - lane) < 3 then clear = false end end
		end
		if clear then table.insert(positions, candidate) end
	end
	for _, x in ipairs(positions) do
		local kind = choices[random:NextInteger(1, #choices)]
		local z = random:NextNumber(-node.Size.Z * 0.4, node.Size.Z * 0.4)
		placeProp(parent, kind, node, x, z, random:NextNumber(if snowy then 17 else 18, if snowy then 25 else 24), random:NextNumber(-35, 35))
		for plantIndex = 1, 2 do
			placeProp(parent, if snowy or random:NextNumber() < 0.58 then "GrassClump" else "Wildflowers", node, math.clamp(x + random:NextNumber(-3.5, 3.5), -28, 28), math.clamp(z + random:NextNumber(-3, 3), -node.Size.Z * 0.42, node.Size.Z * 0.42), random:NextNumber(1.25, 1.9), random:NextNumber(0, 360) + plantIndex)
		end
	end
	for _ = #positions * 2 + 1, random:NextInteger(4, 8) do
		placeProp(parent, if snowy or random:NextNumber() < 0.6 then "GrassClump" else "Wildflowers", node, random:NextNumber(-27, 27), random:NextNumber(-node.Size.Z * 0.4, node.Size.Z * 0.4), random:NextNumber(1.2, 1.8), random:NextNumber(0, 360))
	end
end

local function trailheadScenery(parent: Instance, node: Node, step: number)
	forestCluster(parent, node, step, false)
	if step % 3 == 1 then
		for _, x in ipairs({ -22, 22 }) do placeProp(parent, if step % 2 == 0 then "Wildflowers" else "GrassClump", node, x, (x / 8) % 3, 1.5 + (step % 3) * 0.2, step * 17 + x) end
	end
	if step == 4 or step == 8 then placeProp(parent, "RootLog", node, if step == 4 then -11 else 12, 1, 3.1, step * 29, if step == 4 then 8 else -6) end
end

local function propLedge(parent: Instance, node: Node, x: number, width: number, color: Color3, material: Enum.Material)
	part(parent, "SceneryRestLedge", Vector3.new(width, 4, math.max(7, node.Size.Z - 1)), node.CFrame * CFrame.new(x, node.Size.Y / 2 - 2, 0), color, material, true):SetAttribute("EnvironmentSolid", true)
end

local function riverbankScenery(parent: Instance, node: Node, step: number, checkpoint: boolean)
	if not checkpoint and step % 4 ~= 0 then return end
	local side = if step % 8 == 0 then -1 else 1
	local x = if checkpoint then side * math.min(25, node.Size.X / 2 - 4) else side * 30
	propLedge(parent, node, x, 8, DARK_ROCK, Enum.Material.Rock)
	placeProp(parent, if step % 8 == 0 then "GraniteBoulder" else "LichenBoulder", node, x, 0, 4.2 + step % 3 * 0.35, step * 31, side * 7)
	placeProp(parent, "GrassClump", node, x - side * 2.5, -2, 1.4, step * 23)
end

local function switchbackScenery(parent: Instance, node: Node, step: number)
	if step % 3 ~= 1 then return end
	for index, x in ipairs({ -29, 29 }) do
		propLedge(parent, node, x, 7, DARK_ROCK, Enum.Material.Rock)
		placeProp(parent, if (step + index) % 2 == 0 then "GraniteBoulder" else "BasaltBoulder", node, x, (index - 1.5) * 3, 4.2 + ((step + index) % 3) * 0.5, step * 21 + index * 37, if index == 1 then -10 else 12)
	end
end

local function bridgeScenery(parent: Instance, node: Node, step: number)
	if step % 4 ~= 1 then return end
	local side = if step % 8 == 1 then 1 else -1
	propLedge(parent, node, side * 30, 7, DARK_ROCK, Enum.Material.Rock)
	placeProp(parent, if side == 1 then "GraniteBoulder" else "LichenBoulder", node, side * 30, 0, 4, step * 33, side * 5)
end

local function basaltOverhang(parent: Instance, node: Node, step: number)
	if step % 3 ~= 2 then return end
	local variation = step % 5
	local rootPosition = node.CFrame * CFrame.new(53, node.Size.Y / 2 + 15 + variation, 0)
	local rootFrame = CFrame.lookAt(rootPosition.Position, rootPosition.Position - node.CFrame.RightVector)
	local anchor = wedge(parent, "BasaltOverhangRoot", Vector3.new(node.Size.Z + 8, 34 + variation * 3, 52), rootFrame * CFrame.Angles(0, 0, math.rad((variation - 2) * 3)), DARK_ROCK, Enum.Material.Basalt)
	anchor.CanCollide, anchor.CanQuery = false, false
	local x = 16 + variation * 2
	local overhang = wedge(parent, "BasaltOverhang", Vector3.new(28 + variation * 3, 8 + variation, node.Size.Z + 8 + variation * 2), node.CFrame * CFrame.new(x, node.Size.Y / 2 + 24 + variation, 0) * CFrame.Angles(math.rad((variation - 2) * 4), math.rad(step * 11), math.rad(if step % 2 == 0 then 7 else -9)), DARK_ROCK, Enum.Material.Basalt)
	overhang.CanCollide, overhang.CanQuery = false, false
	placeProp(parent, "BasaltBoulder", node, if x > 0 then 34 else -34, 1, 4.5 + variation * 0.2, step * 27, variation * 3)
end

local function ruinScenery(parent: Instance, node: Node, step: number)
	if step % 4 == 1 then
		local side = if step % 8 == 1 then -1 else 1
		placeProp(parent, if side == -1 then "RuinPillarA" else "RuinPillarB", node, side * 30, 0, 20 + step % 3, step * 13, -side * (58 + step % 3 * 4))
		placeProp(parent, "GraniteBoulder", node, side * 24, 3, 3.8, step * 41)
	end
end

local function openCliffScenery(parent: Instance, node: Node, step: number)
	if step % 5 == 1 then
		local rootPosition = node.CFrame * CFrame.new(51, node.Size.Y / 2 + 17, 0)
		local rootFrame = CFrame.lookAt(rootPosition.Position, rootPosition.Position - node.CFrame.RightVector)
		local rootMass = wedge(parent, "SparseCliffRoot", Vector3.new(node.Size.Z + 5, 37, 48), rootFrame * CFrame.Angles(0, 0, math.rad(-5)), ROCK, Enum.Material.Slate)
		rootMass.CanCollide, rootMass.CanQuery = false, false
		placeProp(parent, "GraniteBoulder", node, 30, -2, 4.5, step * 17, -9)
		local ledge = wedge(parent, "SparseCliffOverhang", Vector3.new(23 + step % 3 * 4, 7, node.Size.Z + 4), node.CFrame * CFrame.new(18, node.Size.Y / 2 + 27, 0) * CFrame.Angles(0, math.rad(step * 9), math.rad(8)), ROCK, Enum.Material.Slate)
		ledge.CanCollide, ledge.CanQuery = false, false
	end
end

local function snowForest(parent: Instance, node: Node, step: number, checkpoint: boolean)
	forestCluster(parent, node, step, true, checkpoint)
	if step % 4 == 2 then placeProp(parent, "SnowCoverOutcrop", node, if step % 8 == 2 then -32 else 32, 0, 6.5, step * 29, 4) end
end

local function iceOutcrops(parent: Instance, node: Node, step: number)
	if step % 4 ~= 1 then return end
	local side = if step % 8 == 1 then -1 else 1
	placeProp(parent, if side == -1 then "IceToothA" else "IceToothB", node, side * 32, -2, 6.5 + step % 3, side * (10 + step * 3), -side * 8)
	if step % 8 == 1 then placeProp(parent, "IceToothA", node, side * 27, 4, 4.8, -step * 7, side * 12) end
end

local function summitScenery(parent: Instance, node: Node, step: number)
	if step >= 8 or step % 3 ~= 1 then return end
	local side = if step % 2 == 0 then -1 else 1
	placeProp(parent, "SnowCoverOutcrop", node, side * 33, 1, 5.5 + step % 2, step * 31, side * 5)
end

local function concealRockfallSources(parent: Instance, model: Model, nodes: { Node })
	local hazards = model:FindFirstChild("Hazards")
	if not hazards then return end
	local sources: { BasePart } = {}
	for _, descendant in ipairs(hazards:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "FallingRock" then
			table.insert(sources, descendant :: BasePart)
		end
	end
	table.sort(sources, function(a, b)
		local aIndex = tonumber(a.Parent.Name:match("(%d+)$")) or 0
		local bIndex = tonumber(b.Parent.Name:match("(%d+)$")) or 0
		return aIndex < bIndex
	end)
	for sourceIndex = 1, #sources, 2 do
		local first = sources[sourceIndex]
		local second = sources[math.min(sourceIndex + 1, #sources)]
		local midpoint = (first.Position + second.Position) / 2
		local nearest = nodes[1]
		local nearestDistance = math.huge
		for _, node in ipairs(nodes) do
			local distance = (node.Position - midpoint).Magnitude
			if distance < nearestDistance then nearest, nearestDistance = node, distance end
		end
		local side = if sourceIndex % 4 == 1 then 1 else -1
		local base = (nearest.CFrame * CFrame.new(side * 27, nearest.Size.Y / 2, 0)).Position
		local supportFrame = CFrame.lookAt(base, midpoint) * CFrame.Angles(-math.pi / 2, 0, 0)
		Props.Place(parent, if side == 1 then "RuinPillarA" else "RuinPillarB", supportFrame, (midpoint - base).Magnitude)
		if first ~= second then
			local beamFrame = CFrame.lookAt(first.Position, second.Position) * CFrame.Angles(-math.pi / 2, 0, 0)
			Props.Place(parent, "RuinPillarB", beamFrame, (second.Position - first.Position).Magnitude)
		else
			Props.Place(parent, "RootLog", first.CFrame * CFrame.new(0, -1.5, 0), 4)
		end
		for _, source in ipairs(if first == second then { first } else { first, second }) do
			Props.Place(parent, if source.Material == Enum.Material.Glacier then "IceToothB" else "GraniteBoulder", source.CFrame * CFrame.new(0, -2.5, 0), if source.Material == Enum.Material.Glacier then 7 else 5)
		end
	end
end

function Environment.Build(model: Model, nodes: { Node }, center: Vector3): Folder
	local root = Instance.new("Folder")
	root.Name, root.Parent = "Environment", model.Decoration
	Props.Prepare()
	mountain(root, center)
	for nodeIndex, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local step = (node:GetAttribute("SectionStep") or 0) :: number
		local checkpoint = node.Parent == model.Checkpoints or node.Name == "Start" or node.Name == "Finish"
		if nodeIndex % 2 == 1 then risingHillside(root, node, center, section, nodeIndex % 3) end
		if section == 1 or section == 8 or section == 10 then sharedGround(root, node, section, checkpoint) end
		if nodeIndex % 3 == 1 and section ~= 1 and section ~= 8 and section ~= 10 then cliffFoundation(root, node, section, nodeIndex % 3) end

		if section == 1 then trailheadScenery(root, node, step)
		elseif section == 2 then riverbankScenery(root, node, step, checkpoint)
		elseif section == 3 then switchbackScenery(root, node, step)
		elseif section == 4 then bridgeScenery(root, node, step)
		elseif section == 5 then basaltOverhang(root, node, step)
		elseif section == 6 then ruinScenery(root, node, step)
		elseif section == 7 then openCliffScenery(root, node, step)
		elseif section == 8 then snowForest(root, node, step, checkpoint)
		elseif section == 9 then iceOutcrops(root, node, step)
		elseif section == 10 then summitScenery(root, node, step)
		end
	end
	concealRockfallSources(root, model, nodes)
	return root
end

return Environment
