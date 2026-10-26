--!strict
local Art = require(script.Parent.EnvironmentParts)
local ArchiveBackdrop = {}

local Steel = Color3.fromRGB(40, 65, 71)
local Slate = Color3.fromRGB(39, 49, 60)
local RearPanel = Color3.fromRGB(28, 42, 48)
local TrayColor = Color3.fromRGB(61, 74, 78)
local Carton = Color3.fromRGB(116, 103, 86)
local CartonLid = Color3.fromRGB(142, 129, 110)
local WarmLight = Color3.fromRGB(199, 175, 123)
local InventoryColors = {Art.Palette.Creamy[1], Art.Palette.Creamy[3], Art.Palette.Creamy[2], Art.Palette.Clicky[2]}
local ShelfHeights = {-103, -48, 7, 62, 117}
local BayCenters = {-246, -82, 82, 246}

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local part = Art.Block(parent, name, size, cf, color)
	part.Material, part.CastShadow = Enum.Material.Metal, false
	part:SetAttribute("Pressable", false)
	part:SetAttribute("KCPress", false)
	part:SetAttribute("ArchiveBackdrop", true)
	return part
end

local function inventoryCap(parent: Instance, template: MeshPart, cf: CFrame, color: Color3): MeshPart
	local key = template:Clone()
	key.Name, key.Size, key.CFrame = "StoredCap", Vector3.new(9.6, 3.4, 9.6), cf
	key.PivotOffset = CFrame.identity
	key.Color, key.Material = color, Enum.Material.SmoothPlastic
	key.Anchored, key.CanCollide, key.CanTouch, key.CanQuery, key.CastShadow = true, false, false, false, false
	key:SetAttribute("Role", "MapArtwork")
	key:SetAttribute("MapArtwork", true)
	key:SetAttribute("ArchiveBackdrop", true)
	key:SetAttribute("ArchiveInventory", true)
	key:SetAttribute("Pressable", false)
	key:SetAttribute("KCPress", false)
	for _, item in key:GetDescendants() do
		if item:IsA("SurfaceGui") then item.Enabled, item.MaxDistance = false, 65 end
	end
	key.Parent = parent
	return key
end

local function tray(parent: Instance, cf: CFrame): Model
	local model = Art.Model(parent, "InventoryTray")
	model.PrimaryPart = block(model, "TrayFloor", Vector3.new(82, 1.4, 31), cf * CFrame.new(0, .7, 0), Slate)
	block(model, "FrontLip", Vector3.new(83, 3.4, 1.8), cf * CFrame.new(0, 2.4, 15.7), TrayColor)
	for _, side in {-1, 1} do
		block(model, "SideRim", Vector3.new(1.8, 3.4, 31), cf * CFrame.new(side * 41, 2.4, 0), TrayColor)
	end
	return model
end

local function capTray(parent: Instance, template: MeshPart, cf: CFrame, variation: number)
	local model = tray(parent, cf)
	model:SetAttribute("InventoryType", "Keycaps")
	for row = 1, 2 do
		for column = 1, 4 do
			local color = InventoryColors[(column + variation - 2) % #InventoryColors + 1]
			local key = inventoryCap(model, template, cf * CFrame.new((column - 2.5) * 15.6, 3.15, (row - 1.5) * 14.4), color)
			key.Name = "StoredCap_" .. row .. "_" .. column
		end
	end
end

local function switchTray(parent: Instance, cf: CFrame, variation: number)
	local model = tray(parent, cf)
	model:SetAttribute("InventoryType", "Switches")
	for index = 1, 3 do
		local pose = cf * CFrame.new((index - 2) * 24, 0, 0)
		local color = InventoryColors[(index + variation - 2) % #InventoryColors + 1]
		block(model, "SwitchHousing", Vector3.new(12, 6, 14), pose * CFrame.new(0, 4.4, 0), TrayColor)
		local xStem = block(model, "CrossStemX", Vector3.new(8, 3, 2.5), pose * CFrame.new(0, 8.9, 0), color)
		local zStem = block(model, "CrossStemZ", Vector3.new(2.5, 3, 8), pose * CFrame.new(0, 8.9, 0), color)
		xStem.Material, zStem.Material = Enum.Material.SmoothPlastic, Enum.Material.SmoothPlastic
	end
end

local function boxes(parent: Instance, cf: CFrame, height: number, variation: number)
	local model = Art.Model(parent, "StoredCases")
	model:SetAttribute("InventoryType", "Cases")
	for index, side in {-1, 1} do
		local pose = cf * CFrame.new(side * 28, 0, -1)
		local body = block(model, "Case" .. index, Vector3.new(42, height, 30), pose * CFrame.new(0, height / 2, 0), if variation % 2 == 0 then Carton else Slate)
		body.Material = Enum.Material.SmoothPlastic
		block(model, "CaseLid", Vector3.new(43, 1.5, 31), pose * CFrame.new(0, height + .65, 0), if variation % 2 == 0 then CartonLid else TrayColor)
		if index == 1 then
			block(model, "InventoryLabel", Vector3.new(13, math.min(height * .45, 7), .18), pose * CFrame.new(-5, height * .52, 15.1), CartonLid)
		end
		if not model.PrimaryPart then model.PrimaryPart = body end
	end
end

local function shelf(parent: Instance, template: MeshPart, cf: CFrame, number: number): Model
	local model = Art.Model(parent, "ShelfBay" .. string.format("%02d", number))
	model:SetAttribute("SceneRole", "ArchiveShelf")
	model:SetAttribute("InventoryTierCount", #ShelfHeights)
	model.PrimaryPart = block(model, "BackPanel", Vector3.new(148, 270, 2), cf * CFrame.new(0, -5, -20), RearPanel)
	for _, x in {-72, 72} do
		for _, z in {-19, 19} do
			block(model, "SteelUpright", Vector3.new(4, 270, 4), cf * CFrame.new(x, -5, z), Steel)
		end
	end
	block(model, "CrownRail", Vector3.new(148, 4, 6), cf * CFrame.new(0, 128, 19), Steel)
	for index, height in ShelfHeights do
		block(model, "ShelfDeck" .. index, Vector3.new(148, 2, 40), cf * CFrame.new(0, height, 0), Slate)
		block(model, "ShelfFront" .. index, Vector3.new(148, 4, 2.8), cf * CFrame.new(0, height - .8, 19.5), Steel)
		local content = cf * CFrame.new(0, height + 1, 0)
		if index == 1 or index == #ShelfHeights then
			boxes(model, content, if index == 1 then 18 else 8, number + index)
		else
			local style = (number + index) % 3
			if style == 0 then capTray(model, template, content, number)
			elseif style == 1 then switchTray(model, content, number)
			else boxes(model, content, 18, number + index) end
		end
	end
	if number % 2 == 0 then
		block(model, "LampHousing", Vector3.new(52, 1.7, 6), cf * CFrame.new(0, 59.8, 12), RearPanel)
		local lamp = block(model, "WarmShelfStrip", Vector3.new(48, .35, 3.4), cf * CFrame.new(0, 58.75, 12), WarmLight)
		lamp.Material = Enum.Material.Neon
		lamp:SetAttribute("ArchiveEmissive", true)
	end
	return model
end

local function enclosure(parent: Instance, origin: Vector3): Part
	local cf = CFrame.new(origin)
	local floor = block(parent, "Floor", Vector3.new(816, 8, 796), cf * CFrame.new(0, -144, 0), Color3.fromRGB(27, 35, 42))
	floor:SetAttribute("ArchiveFloorY", -140)
	block(parent, "Roof", Vector3.new(816, 8, 796), cf * CFrame.new(0, 138, 0), Color3.fromRGB(19, 28, 35))
	for _, side in {-1, 1} do
		block(parent, "EndWall", Vector3.new(816, 286, 8), cf * CFrame.new(0, -1, side * 390), RearPanel)
		block(parent, "SideWall", Vector3.new(8, 286, 772), cf * CFrame.new(side * 404, -1, 0), RearPanel)
		block(parent, "FloorEndRail", Vector3.new(816, 3, 4), cf * CFrame.new(0, -138.5, side * 381), Slate)
		block(parent, "FloorSideRail", Vector3.new(4, 3, 764), cf * CFrame.new(side * 397, -138.5, 0), Slate)
	end
	for index = -2, 2 do
		block(parent, "CeilingBeam", Vector3.new(8, 3, 770), cf * CFrame.new(index * 156, 132, 0), Steel)
	end
	for _, distance in {-294, -98, 98, 294} do
		block(parent, "FloorLongSeam", Vector3.new(.32, .1, 766), cf * CFrame.new(distance, -139.94, 0), Slate)
		block(parent, "FloorCrossSeam", Vector3.new(800, .1, .32), cf * CFrame.new(0, -139.94, distance), Slate)
	end
	for _, x in {-156, 156} do
		for _, z in {-156, 156} do
			local pose = cf * CFrame.new(x, 0, z)
			block(parent, "LampStem", Vector3.new(1.3, 11, 1.3), pose * CFrame.new(0, 125, 0), Slate)
			block(parent, "PendantHousing", Vector3.new(26, 4, 15), pose * CFrame.new(0, 118.5, 0), RearPanel)
			local lamp = block(parent, "WarmPendantLens", Vector3.new(22, .5, 11), pose * CFrame.new(0, 116.25, 0), WarmLight)
			lamp.Material = Enum.Material.Neon
			lamp:SetAttribute("ArchiveEmissive", true)
		end
	end
	return floor
end

function ArchiveBackdrop.Build(course: Model, origin: Vector3, template: MeshPart): Model
	local environment = course:FindFirstChild("MapEnvironment")
	assert(environment and environment:IsA("Model"), "Build MapEnvironment before the archive backdrop")
	local previous = environment:FindFirstChild("ArchiveBackdrop")
	if previous and previous:IsA("Model") then return previous end
	local group = Art.Model(environment, "ArchiveBackdrop")
	group:SetAttribute("BackdropRevision", "KC_ARCHIVE_M03_01")
	group:SetAttribute("SceneRole", "ArchiveBackdrop")
	group:SetAttribute("AppearanceReference", "37-keycap-archive.png")
	group:SetAttribute("ArchiveFloorY", -140)
	group:SetAttribute("ClearCourseMinimum", Vector3.new(-320, -125, -320))
	group:SetAttribute("ClearCourseMaximum", Vector3.new(320, 104, 320))
	group:SetAttribute("LocalBoundsMinimum", Vector3.new(-408, -148, -398))
	group:SetAttribute("LocalBoundsMaximum", Vector3.new(408, 142, 398))
	group:SetAttribute("InventoryCapSize", Vector3.new(9.6, 3.4, 9.6))
	group:SetAttribute("MaximumPartCount", 1000)
	group.PrimaryPart = enclosure(group, origin)
	local number = 0
	for _, wall in {
		{position = Vector3.new(0, 0, -351), yaw = 0},
		{position = Vector3.new(0, 0, 351), yaw = math.pi},
		{position = Vector3.new(361, 0, 0), yaw = -math.pi / 2},
		{position = Vector3.new(-361, 0, 0), yaw = math.pi / 2},
	} do
		local wallFrame = CFrame.new(origin + wall.position) * CFrame.Angles(0, wall.yaw, 0)
		for _, distance in BayCenters do
			number += 1
			shelf(group, template, wallFrame * CFrame.new(distance, 0, 0), number)
		end
	end
	local parts, caps, emissives = 0, 0, 0
	for _, item in group:GetDescendants() do
		if item:IsA("BasePart") then
			parts += 1
			if item:GetAttribute("ArchiveInventory") then caps += 1 end
			if item:GetAttribute("ArchiveEmissive") then emissives += 1 end
		end
	end
	assert(parts <= 1000, "Archive backdrop exceeded its part budget")
	group:SetAttribute("ShelfBayCount", number)
	group:SetAttribute("ShelfTierCount", number * #ShelfHeights)
	group:SetAttribute("BackdropPartCount", parts)
	group:SetAttribute("InventoryCapCount", caps)
	group:SetAttribute("EmissivePartCount", emissives)
	return group
end

return ArchiveBackdrop
