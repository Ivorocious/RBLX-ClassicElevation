--!strict
local Art = require(script.Parent.EnvironmentParts)
local Parts = require(script.Parent.Parts)
local FloatingDecor = {}

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local part = Art.Block(parent, name, size, cf, color)
	part:SetAttribute("Pressable", false)
	part:SetAttribute("KCPress", false)
	return part
end

local function cap(parent: Instance, template: MeshPart, cf: CFrame, family: string, color: number, legend: string?): MeshPart
	local key = template:Clone()
	key.Name, key.Size, key.CFrame = "DisplayCap", Vector3.new(2.4, .85, 2.4), cf
	key.PivotOffset = CFrame.identity
	key.Anchored, key.CanCollide, key.CanTouch, key.CanQuery = true, false, false, false
	key.Material, key.Color = Enum.Material.SmoothPlastic, Art.Palette[family][color]
	key:SetAttribute("Role", "MapArtwork")
	key:SetAttribute("MapArtwork", true)
	key:SetAttribute("Pressable", false)
	key:SetAttribute("KCPress", false)
	key:SetAttribute("KeyFamily", family)
	for _, item in key:GetDescendants() do
		if item:IsA("SurfaceGui") then item.Enabled = false end
	end
	key.Parent = parent
	if legend and not key:FindFirstChild("Legend") then Parts.KeyLegend(key, legend) end
	return key
end

local function unit(parent: Instance, name: string, family: string, origin: Vector3, position: Vector3, yaw: number, tilt: number?): (Model, CFrame)
	local model = Art.Model(parent, name)
	model:SetAttribute("DistrictFamily", family)
	model:SetAttribute("SceneRole", "FloatingHardware")
	model:SetAttribute("Pressable", false)
	return model, CFrame.new(origin + position) * CFrame.Angles(math.rad(tilt or 0), math.rad(yaw), 0)
end

local function traces(parent: Instance, cf: CFrame, width: number, depth: number, color: Color3)
	for index, side in {-1, 1} do
		block(parent, "CopperBus" .. index, Vector3.new(width * .68, .18, .65), cf * CFrame.new(-width * .06, 0, side * depth * .31), color)
		block(parent, "BusTurn" .. index, Vector3.new(.65, .18, depth * .39), cf * CFrame.new(side * width * .26, 0, side * depth * .12), color)
		local via = Art.Cylinder(parent, "PlatedVia", cf * CFrame.new(side * width * .26, .03, side * depth * .34) * CFrame.Angles(0, 0, math.pi / 2), .24, 1.3, Art.Gold)
		via:SetAttribute("Pressable", false)
	end
end

local function keyboard(parent: Instance, template: MeshPart, family: string, cf: CFrame, columns: number, rows: number, split: boolean?)
	local palette = Art.Palette[family]
	local width, depth = columns * 2.6 + 4.8, rows * 2.6 + 5
	local body = block(parent, "KeyboardShell", Vector3.new(width, 3.4, depth), cf * CFrame.new(0, -2.15, 0), Art.Charcoal)
	body.Material = Enum.Material.Metal
	block(parent, "FacePlate", Vector3.new(width - 1.1, .5, depth - 1.1), cf * CFrame.new(0, -.2, 0), palette[2])
	block(parent, "FrontBezel", Vector3.new(width, 1.5, 1.6), cf * CFrame.new(0, -1.05, depth / 2), palette[1])
	block(parent, "RearBezel", Vector3.new(width, 1.5, 1.5), cf * CFrame.new(0, -1.05, -depth / 2), palette[1])
	for _, side in {-1, 1} do
		block(parent, "SideBezel", Vector3.new(1.4, 1.6, depth), cf * CFrame.new(side * width / 2, -1.1, 0), palette[1])
		block(parent, "UndersideRail", Vector3.new(1.3, 1.4, depth * .8), cf * CFrame.new(side * width * .34, -4.4, 0), palette[2])
	end
	for row = 1, rows do
		for column = 1, columns do
			local x = (column - (columns + 1) / 2) * 2.6
			if split then x += if column <= columns / 2 then -1.1 else 1.1 end
			local ink = if row == 1 and (column == 1 or column == columns) then "Esc" elseif row == rows and column == 1 then "Ctrl" else nil
			local key = cap(parent, template, cf * CFrame.new(x, .48, (row - (rows + 1) / 2) * 2.6), family, if column == 1 then 3 elseif column == columns then 2 else 1, ink)
			key.Name = "DisplayCap_" .. row .. "_" .. column
		end
	end
	for index = 1, 3 do
		block(parent, "IndicatorRecess", Vector3.new(1.6, .22, .7), cf * CFrame.new(width / 2 - 2.8 - index * 2.1, .17, -depth / 2 + 1.15), Art.Charcoal)
	end
	traces(parent, cf * CFrame.new(0, -3.9, 0), width - 3, depth - 2, Art.Gold)
	return body
end

local function switch(parent: Instance, cf: CFrame, family: string, exploded: boolean?): Part
	local palette = Art.Palette[family]
	local base = block(parent, "SwitchSocket", Vector3.new(29, 3.4, 27), cf * CFrame.new(0, -6, 0), Art.Charcoal)
	base.Material = Enum.Material.Metal
	block(parent, "LowerHousing", Vector3.new(24, 5.5, 22), cf * CFrame.new(0, -1.5, 0), palette[2])
	for _, side in {-1, 1} do
		block(parent, "SocketLatch", Vector3.new(4, 6.5, 11), cf * CFrame.new(side * 12.5, -.5, 0), palette[1])
		block(parent, "ContactBlade", Vector3.new(2.2, 9, 3), cf * CFrame.new(side * 7.5, -11, 0), Art.Gold)
	end
	local crown = if exploded then 18 else 8
	block(parent, "UpperHousingRim", Vector3.new(27, 2.3, 25), cf * CFrame.new(0, crown, 0), palette[1])
	for _, x in {-11, 11} do
		for _, z in {-10, 10} do
			block(parent, "HousingCorner", Vector3.new(2, 11, 2), cf * CFrame.new(x, crown - 5, z), Art.Charcoal)
		end
	end
	local stemHeight = if exploded then 19 else 12
	block(parent, "CrossStemX", Vector3.new(14, stemHeight, 5), cf * CFrame.new(0, crown + 2, 0), palette[3])
	block(parent, "CrossStemZ", Vector3.new(5, stemHeight, 14), cf * CFrame.new(0, crown + 2, 0), palette[3])
	for index = 1, if exploded then 5 else 3 do
		Art.Cylinder(parent, "SpringCoil" .. index, cf * CFrame.new(0, 2 + index * 2.3, 0) * CFrame.Angles(0, 0, math.pi / 2), .8, 12, Art.Silver)
	end
	traces(parent, cf * CFrame.new(0, -4.2, 0), 25, 23, Art.Gold)
	return base
end

local function circuit(parent: Instance, cf: CFrame, family: string, width: number, depth: number): Part
	local palette = Art.Palette[family]
	local board = block(parent, "CircuitLaminate", Vector3.new(width, 2.8, depth), cf, palette[2])
	block(parent, "LaminateEdge", Vector3.new(width + .5, .55, depth + .5), cf * CFrame.new(0, -1.35, 0), Art.Charcoal)
	traces(parent, cf * CFrame.new(0, 1.5, 0), width - 3, depth - 2, Art.Trace)
	for index, x in {-width * .22, width * .19} do
		block(parent, "Controller" .. index, Vector3.new(width * .24, 4.6, depth * .34), cf * CFrame.new(x, 3.7, 0), Art.Charcoal)
		block(parent, "ControllerInset", Vector3.new(width * .2, .28, depth * .27), cf * CFrame.new(x, 6.15, 0), palette[1])
		for pin = 1, 4 do
			for _, side in {-1, 1} do
				block(parent, "ChipPin", Vector3.new(.85, .65, 2), cf * CFrame.new(x + (pin - 2.5) * width * .048, 2.6, side * depth * .2), Art.Gold)
			end
		end
	end
	for index = 1, 5 do
		block(parent, "EdgeContact", Vector3.new(width * .1, .3, 4.4), cf * CFrame.new((index - 3) * width * .15, 1.55, depth / 2 - 2.1), Art.Gold)
	end
	return board
end

local function connector(parent: Instance, cf: CFrame, family: string): Part
	local palette = Art.Palette[family]
	local body = block(parent, "ConnectorCase", Vector3.new(34, 12, 15), cf, palette[2])
	block(parent, "MetalSocket", Vector3.new(27, 8.5, 10), cf * CFrame.new(0, .2, -11), Art.Silver)
	block(parent, "SocketOpening", Vector3.new(23, 5.4, .5), cf * CFrame.new(0, .2, -16.2), Art.Charcoal)
	for index = 1, 5 do
		block(parent, "SocketContact", Vector3.new(2.1, .65, .6), cf * CFrame.new((index - 3) * 4.5, -1.2, -16.5), Art.Gold)
	end
	for index = 1, 3 do
		block(parent, "CableStrainRelief", Vector3.new(13 - index * 1.3, 8, 2.3), cf * CFrame.new(0, 0, 8.8 + index * 2.5), Art.Charcoal)
	end
	local points = {Vector3.new(0, 0, 17), Vector3.new(0, -3, 27), Vector3.new(11, -8, 33), Vector3.new(22, -11, 25)}
	for index = 1, #points - 1 do
		Art.Beam(parent, "FloatingCable", cf:PointToWorldSpace(points[index]), cf:PointToWorldSpace(points[index + 1]), 6.2, Art.Charcoal)
	end
	return body
end

local function rotary(parent: Instance, cf: CFrame, family: string): Part
	local palette = Art.Palette[family]
	local body = block(parent, "EncoderHousing", Vector3.new(45, 6, 43), cf * CFrame.new(0, -4.5, 0), Art.Charcoal)
	block(parent, "HousingStep", Vector3.new(38, 3, 37), cf * CFrame.new(0, 0, 0), palette[3])
	Art.Cylinder(parent, "EncoderDrum", cf * CFrame.new(0, 8, 0) * CFrame.Angles(0, 0, math.pi / 2), 13, 32, palette[2])
	Art.Cylinder(parent, "EncoderFace", cf * CFrame.new(0, 14.8, 0) * CFrame.Angles(0, 0, math.pi / 2), .8, 26, palette[1])
	for index = 0, 11 do
		local angle = index * math.pi / 6
		block(parent, "KnurledGrip", Vector3.new(3.2, 12.5, 2.8), cf * CFrame.new(math.sin(angle) * 16, 8, math.cos(angle) * 16) * CFrame.Angles(0, angle, 0), palette[2])
	end
	block(parent, "EncoderPointer", Vector3.new(2.3, .5, 10), cf * CFrame.new(0, 15.5, -6), Art.Charcoal)
	for _, side in {-1, 1} do
		block(parent, "HousingLatch", Vector3.new(3, 7.5, 12), cf * CFrame.new(side * 22, -2.5, 0), Art.Silver)
	end
	return body
end

function FloatingDecor.Build(root: Model, origin: Vector3, template: MeshPart): Model
	local artParent = root:FindFirstChild("MapEnvironment")
	assert(artParent and artParent:IsA("Model"), "Build MapEnvironment before floating hardware")
	local previous = artParent:FindFirstChild("FloatingHardware")
	if previous and previous:IsA("Model") then return previous end
	local group = Art.Model(artParent, "FloatingHardware")
	group:SetAttribute("DecorRevision", "KC_FLOAT_M02_01")
	group:SetAttribute("OrdinaryCapSize", Vector3.new(2.4, .85, 2.4))
	local model, cf = unit(group, "CreamyFloatingKeyboard", "Creamy", origin, Vector3.new(18, 16, -274), -18, 16)
	model.PrimaryPart = keyboard(model, template, "Creamy", cf, 14, 5)
	model, cf = unit(group, "CreamyExplodedSwitch", "Creamy", origin, Vector3.new(-102, 11, -233), 22, -5)
	model.PrimaryPart = switch(model, cf, "Creamy", true)
	model, cf = unit(group, "CreamySocketStack", "Creamy", origin, Vector3.new(135, 14, -264), -15, 8)
	for index = 1, 3 do
		local slab = circuit(model, cf * CFrame.new(0, (index - 2) * 11, 0), "Creamy", 34, 25)
		if index == 1 then model.PrimaryPart = slab end
	end
	model, cf = unit(group, "CreamyCircuitRaft", "Creamy", origin, Vector3.new(190, 1, -194), 28, 12)
	model.PrimaryPart = circuit(model, cf, "Creamy", 39, 29)

	model, cf = unit(group, "ThockyControllerRaft", "Thocky", origin, Vector3.new(291, 12, -48), -22, 11)
	model.PrimaryPart = circuit(model, cf, "Thocky", 46, 33)
	model, cf = unit(group, "ThockySwitchMonument", "Thocky", origin, Vector3.new(291, 18, 111), -20)
	model.PrimaryPart = switch(model, cf, "Thocky", true)
	model, cf = unit(group, "ThockySpringColumn", "Thocky", origin, Vector3.new(234, 20, 173), 18, -9)
	model.PrimaryPart = switch(model, cf, "Thocky", false)
	for index = 1, 4 do
		Art.Cylinder(model, "OuterSpringDisc", cf * CFrame.new(0, 21 + index * 2.1, 0) * CFrame.Angles(0, 0, math.pi / 2), 1.1, 19, Art.Silver)
	end
	model, cf = unit(group, "ThockyCapacitorBank", "Thocky", origin, Vector3.new(225, -1, -124), -12, 14)
	model.PrimaryPart = circuit(model, cf, "Thocky", 36, 27)
	for _, x in {-10, 0, 10} do
		Art.Cylinder(model, "CapacitorCan", cf * CFrame.new(x, 9, -5) * CFrame.Angles(0, 0, math.pi / 2), 13, 7, Art.Silver)
		block(model, "CapacitorPolarity", Vector3.new(1.4, 10, .7), cf * CFrame.new(x, 9, -1.3), Art.Palette.Thocky[2])
	end

	model, cf = unit(group, "ClackySplitKeyboard", "Clacky", origin, Vector3.new(32, 31, 274), 14, -18)
	model.PrimaryPart = keyboard(model, template, "Clacky", cf, 14, 5, true)
	model, cf = unit(group, "ClackyCableConnector", "Clacky", origin, Vector3.new(-125, 28, 253), 35, -9)
	model.PrimaryPart = connector(model, cf, "Clacky")
	model, cf = unit(group, "ClackySwitchTower", "Clacky", origin, Vector3.new(-202, 23, 140), -13, 7)
	model.PrimaryPart = switch(model, cf, "Clacky", true)
	model, cf = unit(group, "ClackyCircuitShelf", "Clacky", origin, Vector3.new(116, -3, 201), -12, 16)
	model.PrimaryPart = circuit(model, cf, "Clacky", 43, 28)

	model, cf = unit(group, "ClickyEncoderWheel", "Clicky", origin, Vector3.new(-296, 16, 3), 14, 8)
	model.PrimaryPart = rotary(model, cf, "Clicky")
	model, cf = unit(group, "ClickyRelayKeyboard", "Clicky", origin, Vector3.new(-271, 21, -119), -18, 14)
	model.PrimaryPart = keyboard(model, template, "Clicky", cf, 12, 5)
	model, cf = unit(group, "ClickyRelayStack", "Clicky", origin, Vector3.new(-193, 8, -240), 22, -12)
	for index = 1, 2 do
		local slab = circuit(model, cf * CFrame.new(0, (index - 1) * 15, 0), "Clicky", 35, 26)
		if index == 1 then model.PrimaryPart = slab end
	end
	model, cf = unit(group, "ClickyContactConnector", "Clicky", origin, Vector3.new(-286, -2, 127), -30, 12)
	model.PrimaryPart = connector(model, cf, "Clicky")

	model, cf = unit(group, "CentralFloatingMotherboard", "Thocky", origin, Vector3.new(0, -27, 0), 12)
	model.PrimaryPart = circuit(model, cf, "Thocky", 57, 49)
	for index, offset in {Vector3.new(-20, -4, -24), Vector3.new(20, -7, 25)} do
		local daughter = Art.Model(model, "DaughterBoard" .. index)
		daughter.PrimaryPart = circuit(daughter, cf * CFrame.new(offset) * CFrame.Angles(math.rad(12), math.rad(index * 14), 0), "Thocky", 19, 16)
	end
	group:SetAttribute("AssemblyCount", 17)
	group:SetAttribute("KeyLegendPolicy", "Three labels per large keyboard; remaining ordinary caps use geometry")
	for _, part in group:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
			part:SetAttribute("Pressable", false)
			part:SetAttribute("KCPress", false)
		end
	end
	return group
end

return FloatingDecor
