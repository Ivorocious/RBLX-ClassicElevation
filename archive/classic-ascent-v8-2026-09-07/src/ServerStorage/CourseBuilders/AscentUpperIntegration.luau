--!strict

local Props = require(script.Parent.AscentProps)
local UpperIntegration = {}

local FROST_ROCK = Color3.fromRGB(104, 132, 143)
local DEEP_ROCK = Color3.fromRGB(64, 79, 83)
local SNOW_ROCK = Color3.fromRGB(150, 177, 187)

local function folder(parent: Instance, name: string): Folder
	local result = Instance.new("Folder")
	result.Name, result.Parent = name, parent
	return result
end

local function markScenery(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide, descendant.CanTouch, descendant.CanQuery = false, false, false
			descendant:SetAttribute("UpperIntegrationScenery", true)
		end
	end
end

local function prop(parent: Instance, kind: string, frame: CFrame, height: number): Model
	local result = Props.Place(parent, kind, frame, height)
	markScenery(result)
	return result
end

local function mass(parent: Instance, kind: string, size: Vector3, frame: CFrame, color: Color3): Model
	local result = Props.PlaceSized(parent, kind, size, frame, color)
	markScenery(result)
	return result
end

local function bank(parent: Instance, node: BasePart, kind: string, x: number, z: number, size: Vector3, top: number, color: Color3): Model
	local center = node.CFrame * CFrame.new(x, node.Size.Y / 2 + top - size.Y / 2, z)
	return mass(parent, kind, size, center, color)
end

local function plant(parent: Instance, node: BasePart, kind: string, x: number, z: number, top: number, height: number, yaw: number): Model
	local base = node.CFrame * CFrame.new(x, node.Size.Y / 2 + top - 6, z) * CFrame.Angles(0, yaw, 0)
	return prop(parent, kind, base, height)
end

local function section7(parent: Instance, node: BasePart)
	local cluster = folder(parent, "CliffsideRockFace")
	bank(cluster, node, "FaultWallA", 56, 0, Vector3.new(34, 62, 70), 24, DEEP_ROCK)
	bank(cluster, node, "TalusFan", 50, -4, Vector3.new(25, 11, 49), 1, FROST_ROCK)
	plant(cluster, node, "PineWind", 61, -8, 4, 42, -0.42)
	plant(cluster, node, "CedarLite", 67, 9, 5, 28, 0.28)
	prop(cluster, "LichenBoulder", node.CFrame * CFrame.new(51, node.Size.Y / 2 - 2, 15) * CFrame.Angles(0, 0.58, 0), 6)
end

local function section8(parent: Instance, node: BasePart)
	local cluster = folder(parent, "SummitPineGrove")
	bank(cluster, node, "SnowRidge", -58, 2, Vector3.new(38, 20, 62), 3, SNOW_ROCK)
	bank(cluster, node, "CliffButtress", -66, 0, Vector3.new(28, 30, 41), 5, FROST_ROCK)
	plant(cluster, node, "PineSnow", -60, -12, 6, 31, -0.34)
	plant(cluster, node, "PineSnow", -68, 2, 7, 25, 0.22)
	plant(cluster, node, "PineSnow", -57, 14, 6, 21, 0.54)
	prop(cluster, "SnowCoverOutcrop", node.CFrame * CFrame.new(-48, node.Size.Y / 2 - 2, -18) * CFrame.Angles(0, -0.45, 0), 7)
end

local function section9(parent: Instance, node: BasePart)
	local cluster = folder(parent, "SkylineFrostWall")
	bank(cluster, node, "FaultWallB", 55, -4, Vector3.new(34, 50, 50), 25, FROST_ROCK)
	bank(cluster, node, "SnowRidge", 61, 7, Vector3.new(30, 18, 38), 31, SNOW_ROCK)
	prop(cluster, "GlacierSerac", node.CFrame * CFrame.new(48, node.Size.Y / 2 + 2, -18) * CFrame.Angles(0, 0.46, 0), 23)
	prop(cluster, "GlacierSerac", node.CFrame * CFrame.new(67, node.Size.Y / 2 + 25, 18) * CFrame.Angles(0, -0.38, 0), 17)
	prop(cluster, "RockSpurB", node.CFrame * CFrame.new(46, node.Size.Y / 2 + 2, 18) * CFrame.Angles(0, 0.2, 0), 18)
end

local function summitBank(parent: Instance, node: BasePart, side: number, name: string)
	local cluster = folder(parent, name)
	local ridgeX = if side < 0 then -58 else 55
	local ridgeZ = if side < 0 then -4 else 5
	local ridgeSize = if side < 0 then Vector3.new(34, 20, 53) else Vector3.new(29, 16, 44)
	local buttressSize = if side < 0 then Vector3.new(27, 29, 36) else Vector3.new(22, 24, 31)
	bank(cluster, node, "SnowRidge", ridgeX, ridgeZ, ridgeSize, if side<0 then 14 else 11, SNOW_ROCK)
	bank(cluster, node, "CliffButtress", side * 64, -ridgeZ, buttressSize, 20, FROST_ROCK)
	bank(cluster, node, "TalusFan", side * 47, ridgeZ, Vector3.new(22, 9, 35), 1, DEEP_ROCK)
end

function UpperIntegration.Build(model: Model, nodes: {BasePart})
	local decoration = model:FindFirstChild("Decoration")
	assert(decoration and decoration:IsA("Folder"), "Course decoration is required")
	assert(not decoration:FindFirstChild("UpperIntegration"), "Upper integration already exists")
	local root = folder(decoration, "UpperIntegration")

	for _, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex")
		local step = node:GetAttribute("SectionStep")
		if section == 7 and step == 8 then
			section7(root, node)
		elseif section == 8 and step == 8 then
			section8(root, node)
		elseif section == 9 and step == 9 then
			section9(root, node)
		elseif section == 10 and step == 2 then
			summitBank(root, node, -1, "SummitApproachBank")
		elseif section == 10 and step == 7 then
			summitBank(root, node, 1, "SummitRunBank")
		elseif section == 10 and step == 10 then
			summitBank(root, node, -1, "SummitDestinationLeft")
			summitBank(root, node, 1, "SummitDestinationRight")
		end
	end

	return root
end

return UpperIntegration
