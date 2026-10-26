--!strict
local Parts = {}
local Config = require(script.Parent:FindFirstChild("ConfigSnapshot") or game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig)

Parts.Palette = {
	Creamy = {Color3.fromRGB(247, 230, 194), Color3.fromRGB(231, 156, 173), Color3.fromRGB(156, 222, 191)},
	Thocky = {Color3.fromRGB(221, 192, 144), Color3.fromRGB(31, 84, 96), Color3.fromRGB(143, 98, 62)},
	Clacky = {Color3.fromRGB(224, 240, 255), Color3.fromRGB(148, 196, 238), Color3.fromRGB(248, 248, 246)},
	Clicky = {Color3.fromRGB(245, 230, 194), Color3.fromRGB(48, 98, 204), Color3.fromRGB(231, 136, 124)},
}
Parts.Charcoal = Color3.fromRGB(47, 54, 64)
Parts.Crimson = Color3.fromRGB(201, 33, 49)
Parts.Yellow = Color3.fromRGB(244, 195, 49)
Parts.Pitch = 1.3
Parts.KeyPitch = 2.6
Parts.PressDepth = Config.PressDepth
local keyboardRows = {
	{"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="},
	{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]"},
	{"A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "\\"},
	{"Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "⇧", "⌃"},
}
local specialLegends = {Esc = "⎋", ESC = "⎋", Ctrl = "⌃", CTRL = "⌃", SHIFT = "⇧", SPACE = "␣", ENTER = "↵", ["↑"] = "↑", ["↓"] = "↓", ["→"] = "→", ["←"] = "←"}

function Parts.Model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	model:SetAttribute("KCEditUnit", true)
	return model
end

function Parts.Block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, collidable: boolean?): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, cf
	part.Color, part.Material = color, Enum.Material.SmoothPlastic
	part.Anchored, part.CanCollide = true, collidable ~= false
	part.CanTouch, part.CanQuery = false, part.CanCollide
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	part:SetAttribute("Role", if part.CanCollide then "Walkable" else "Decoration")
	return part
end

function Parts.Legend(part: BasePart, text: string, face: Enum.NormalId?, color: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Legend", face or Enum.NormalId.Top
	gui.CanvasSize, gui.LightInfluence, gui.AlwaysOnTop = Vector2.new(128, 128), 1, false
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextScaled, label.Font = text, true, Enum.Font.GothamBold
	label.TextColor3 = color or Parts.Charcoal
	label.Parent, gui.Parent = gui, part
end

function Parts.Key(parent: Instance, template: MeshPart, cf: CFrame, family: string, index: number, legend: string?): MeshPart
	local key = template:Clone()
	key.Name, key.Size, key.CFrame = "Key", Vector3.new(2.4, .85, 2.4), cf
	key.PivotOffset = CFrame.identity
	key.Color, key.Material = Parts.Palette[family][(index - 1) % 3 + 1], Enum.Material.SmoothPlastic
	key.Anchored, key.CanCollide, key.CanQuery, key.CanTouch = true, false, true, false
	key.CollisionFidelity = Enum.CollisionFidelity.Hull
	key:SetAttribute("KeyFamily", family)
	key:SetAttribute("Role", "WalkableSkin")
	key:SetAttribute("PressDepth", Parts.PressDepth)
	key:SetAttribute("Pressable", true)
	key:SetAttribute("KeyLegend", legend or "A")
	key.Parent = parent
	Parts.KeyLegend(key, legend or "A")
	return key
end

function Parts.KeyLegend(key: BasePart, text: string)
	local color = key.Color
	local lightInk = color.R * .2126 + color.G * .7152 + color.B * .0722 < .5
	Parts.Legend(key, text, nil, if lightInk then Color3.fromRGB(255, 248, 230) else Parts.Charcoal)
	local gui = key.Legend :: SurfaceGui
	gui.CanvasSize, gui.LightInfluence = Vector2.new(256, 256), .25
	local label = gui:FindFirstChildOfClass("TextLabel") :: TextLabel
	label.Position, label.Size = UDim2.fromScale(.17, .17), UDim2.fromScale(.66, .66)
	key:SetAttribute("KeyLegend", text)
end

function Parts.Bank(parent: Instance, name: string, template: MeshPart, cf: CFrame, columns: number, rows: number, family: string, legend: string?): Model
	local model = Parts.Model(parent, name)
	local size = Vector3.new(columns * Parts.Pitch, .7, rows * Parts.Pitch)
	local gridColumns, gridRows = math.max(1, math.floor(columns / 2)), math.max(1, math.floor(rows / 2))
	local pitchX, pitchZ = size.X / gridColumns, size.Z / gridRows
	local base = Parts.Block(model, "Base", size, cf * CFrame.new(0, -1.2, 0), Parts.Charcoal)
	model.PrimaryPart = base
	base.Material = Enum.Material.Metal
	base.CanCollide = false
	base.CanQuery = false
	base:SetAttribute("Role", "Decoration")
	local collider = Parts.Block(model, "BankContact", Vector3.new(size.X - .2, .25, size.Z - .2), cf * CFrame.new(0, -Parts.PressDepth - .125, 0), Parts.Palette[family][1])
	collider.Transparency = 1
	collider:SetAttribute("Role", "Walkable")
	model:SetAttribute("KeyFamily", family)
	model:SetAttribute("TopPosition", cf.Position)
	model:SetAttribute("Columns", gridColumns)
	model:SetAttribute("Rows", gridRows)
	model:SetAttribute("GridPitchX", pitchX)
	model:SetAttribute("GridPitchZ", pitchZ)
	model:SetAttribute("BankWidth", size.X)
	model:SetAttribute("BankDepth", size.Z)
	for x = 1, gridColumns do
		for z = 1, gridRows do
			local row = keyboardRows[(z - 1) % #keyboardRows + 1]
			local mark = if x == 1 and z == 1 and legend then specialLegends[legend] or row[1] else row[(x - 1) % #row + 1]
			local colorIndex = if x == 1 then 3 else if x == gridColumns then 2 else 1
			local pose = cf * CFrame.new((x - (gridColumns + 1) / 2) * pitchX, -.425, (z - (gridRows + 1) / 2) * pitchZ)
			local key = Parts.Key(model, template, pose, family, colorIndex, mark)
			key.Name, key.Size = "Key_" .. x .. "_" .. z, Vector3.new(pitchX - .18, .85, pitchZ - .18)
			Parts.Block(model, "Socket_" .. x .. "_" .. z, Vector3.new(pitchX - .06, .1, pitchZ - .06), pose * CFrame.new(0, -.4, 0), Parts.Charcoal, false)
		end
	end
	return model
end

function Parts.Support(parent: Instance, cf: CFrame, height: number, color: Color3?)
	local unit = Parts.Model(parent, "Support")
	local body = Parts.Block(unit, "Housing", Vector3.new(5, height, 5), cf * CFrame.new(0, -height / 2 - 1.55, 0), Parts.Charcoal)
	body:SetAttribute("Role", "SolidBlocker")
	body.Material = Enum.Material.Metal
	Parts.Block(unit, "Insert", Vector3.new(2.4, math.min(3, height * .5), .22), body.CFrame * CFrame.new(0, 0, -2.6), color or Parts.Palette.Thocky[2], false)
	for _,x in {-2.4, 2.4} do
		Parts.Block(unit, "CornerHousing", Vector3.new(1.2, 2.4, 1.1), body.CFrame * CFrame.new(x, -height / 2 + 1.2, -2.3), Parts.Palette.Thocky[1], false)
	end
	Parts.Block(unit, "CircuitTrace", Vector3.new(3.2, .35, .18), body.CFrame * CFrame.new(-.1, .4, -2.74), Color3.fromRGB(156, 222, 191), false)
	Parts.Block(unit, "CircuitReturn", Vector3.new(.35, 1.7, .18), body.CFrame * CFrame.new(1.3, -.3, -2.74), Color3.fromRGB(156, 222, 191), false)
	local foot = Parts.Block(unit, "Foot", Vector3.new(6, .6, 6), cf * CFrame.new(0, -height - 1.85, 0), Parts.Charcoal)
	foot:SetAttribute("Role", "SolidBlocker")
	unit.PrimaryPart = body
	return unit
end

function Parts.SpecialKey(parent: Instance, name: string, cf: CFrame, size: Vector3, family: string, legend: string): Model
	local unit = Parts.Model(parent, name)
	local body = Parts.Block(unit, "KeyBody", Vector3.new(size.X, 1.25, size.Z), cf * CFrame.new(0, -.625, 0), Parts.Palette[family][1], false)
	local top = Parts.Block(unit, "KeyTop", Vector3.new(size.X - .35, .22, size.Z - .35), cf * CFrame.new(0, -.11, 0), Parts.Palette[family][1], false)
	for _,v in {body, top} do v:SetAttribute("KeyFamily", family) end
	top:SetAttribute("Pressable", true)
	top:SetAttribute("PressDepth", Parts.PressDepth)
	Parts.KeyLegend(top, specialLegends[string.upper(legend)] or (if legend == "" then "↵" else legend))
	local contact = Parts.Block(unit, "KeyContact", Vector3.new(size.X, .25, size.Z), cf * CFrame.new(0, -Parts.PressDepth - .125, 0), Parts.Charcoal)
	contact.Transparency = 1
	local link = Instance.new("ObjectValue")
	link.Name, link.Value, link.Parent = "PressKey", top, contact
	local bodyLink = Instance.new("ObjectValue")
	bodyLink.Name, bodyLink.Value, bodyLink.Parent = "PressBody", body, top
	unit.PrimaryPart = body
	unit:SetAttribute("KeyFamily", family)
	unit:SetAttribute("TopPosition", cf.Position)
	return unit
end

function Parts.CheckpointFlag(parent: Instance, cf: CFrame, text: string)
	local flag = Parts.Model(parent, "RecoveryMarker")
	local pole = Parts.Block(flag, "Pole", Vector3.new(.35, 6, .35), cf * CFrame.new(0, 3, 0), Parts.Charcoal, false)
	local cloth = Parts.Block(flag, "Flag", Vector3.new(2.7, 1.5, .15), cf * CFrame.new(1.25, 5, 0), Parts.Palette.Creamy[3], false)
	Parts.Legend(cloth, text, Enum.NormalId.Front)
	Parts.Legend(cloth, text, Enum.NormalId.Back)
	flag.PrimaryPart = pole
end

function Parts.JoinSpecialKeys(primary: Model, secondary: Model)
	local key = primary.KeyTop :: BasePart
	secondary.KeyContact.PressKey.Value = key
	secondary.KeyTop:SetAttribute("Pressable", false)
	-- Joined sections share the primary key's legend.
	local secondaryLegend = secondary.KeyTop.Legend :: SurfaceGui
	secondaryLegend.Enabled = false
	for _,part in {secondary.KeyTop, secondary.KeyBody} do
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "PressCompanion", part, key
	end
end

function Parts.Warning(parent: Instance, cf: CFrame, size: Vector3): Part
	local plate = Parts.Block(parent, "MovementWarning", size, cf, Parts.Yellow, false)
	for n = -1, 1 do
		Parts.Block(parent, "BlackBand", Vector3.new(size.X * .15, size.Y + .015, size.Z * .94), cf * CFrame.new(n * size.X * .3, 0, 0) * CFrame.Angles(0, .25, 0), Parts.Charcoal, false)
	end
	return plate
end

function Parts.KillBody(parent: Instance, name: string, cf: CFrame, size: Vector3): Model
	local unit = Parts.Model(parent, name)
	local body = Parts.Block(unit, "Contact", size, cf, Parts.Crimson, false)
	body.CanQuery = true
	body:SetAttribute("Role", "Lethal")
	unit.PrimaryPart = body
	for _,face in {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom} do
		Parts.Legend(body, "X", face, Color3.new(1, 1, 1))
	end
	for _,y in {-.3, .3} do
		Parts.Block(unit, "BlackBand", Vector3.new(size.X + .035, size.Y * .12, size.Z + .035), cf * CFrame.new(0, size.Y * y, 0), Parts.Charcoal, false)
	end
	return unit
end

function Parts.Cylinder(parent: Instance, name: string, cf: CFrame, length: number, diameter: number, color: Color3): Part
	local part = Parts.Block(parent, name, Vector3.new(length, diameter, diameter), cf, color, false)
	part.Shape, part.Material = Enum.PartType.Cylinder, Enum.Material.Metal
	return part
end

return Parts
