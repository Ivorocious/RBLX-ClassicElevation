--!strict
local Art = require(script.Parent.EnvironmentParts)
local Landmarks = {}

local function usb(parent: Instance, origin: Vector3): Model
	local model = Art.Model(parent, "USBStartArch")
	model:SetAttribute("LandmarkId", "USB")
	local cf = CFrame.new(origin + Vector3.new(-89, 0, -81))
	for _, side in {-1, 1} do
		Art.Block(model, "PlugShoulder", Vector3.new(8, 24, 4), cf * CFrame.new(0, 9, side * 21), Art.Charcoal)
		Art.Block(model, "SilverRail", Vector3.new(8.4, 24, 1.2), cf * CFrame.new(0, 9, side * 23), Art.Silver)
		Art.Block(model, "SocketFoot", Vector3.new(11, 2, 7), cf * CFrame.new(0, -3, side * 21), Art.Charcoal)
	end
	Art.Block(model, "SilverPlug", Vector3.new(8.5, 10, 47), cf * CFrame.new(0, 25, 0), Art.Silver)
	Art.Block(model, "DarkContactBed", Vector3.new(.7, 5.6, 38), cf * CFrame.new(4.6, 24.5, 0), Art.Charcoal)
	for index = 1, 4 do
		Art.Block(model, "GoldContact" .. index, Vector3.new(.9, 4.2, 5), cf * CFrame.new(5.05, 24.5, (index - 2.5) * 8), Art.Gold)
	end
	for _, side in {-1, 1} do
		Art.Block(model, "TopRecess", Vector3.new(4.8, .4, 6), cf * CFrame.new(0, 30.1, side * 11), Art.Charcoal)
	end
	Art.Block(model, "CableCollar", Vector3.new(10, 9, 11), cf * CFrame.new(-1, 7, -28), Art.Charcoal)
	local points = {Vector3.new(-1, 7, -32), Vector3.new(-14, 6, -39), Vector3.new(-27, 2, -37), Vector3.new(-31, -7, -28)}
	for index = 1, #points - 1 do
		Art.Beam(model, "CableBend", cf:PointToWorldSpace(points[index]), cf:PointToWorldSpace(points[index + 1]), 5, Art.Charcoal)
	end
	model.PrimaryPart = model.SilverPlug
	return model
end

local function creamy(parent: Instance, origin: Vector3, template: MeshPart): Model
	local model = Art.Model(parent, "CreamyTrayRack")
	model:SetAttribute("LandmarkId", "Creamy")
	local cf = CFrame.new(origin + Vector3.new(11, 7, -218)) * CFrame.Angles(0, math.rad(-12), 0)
	local palette = Art.Palette.Creamy
	for _, x in {-12, 12} do
		Art.Block(model, "RackUpright", Vector3.new(3.5, 32, 3.5), cf * CFrame.new(x, 7, 0) * CFrame.Angles(0, 0, math.rad(-10)), Art.Charcoal)
		Art.Block(model, "RackFoot", Vector3.new(6, 1.8, 14), cf * CFrame.new(x + 2.4, -9, 0), Art.Charcoal)
	end
	for index, height in {0, 15} do
		local trayFrame = cf * CFrame.new(-1, height, 0) * CFrame.Angles(math.rad(16), 0, 0)
		Art.Tray(model, template, trayFrame, "Creamy", 6, 4)
		for _, x in {-10, 10} do
			Art.Block(model, "TrayArm", Vector3.new(2.3, 1.5, 16), cf * CFrame.new(x, height - 2, 0), palette[3])
		end
	end
	Art.Block(model, "RearCrossbar", Vector3.new(27, 3.2, 3), cf * CFrame.new(0, 7, -2.8), palette[2])
	model.PrimaryPart = model.RearCrossbar
	return model
end

local function thocky(parent: Instance, origin: Vector3, template: MeshPart): Model
	local model = Art.Model(parent, "ThockyCapMagazine")
	model:SetAttribute("LandmarkId", "Thocky")
	local cf = CFrame.new(origin + Vector3.new(255, 14, 46)) * CFrame.Angles(0, math.rad(-12), 0)
	local palette = Art.Palette.Thocky
	Art.Block(model, "MagazineBase", Vector3.new(30, 3, 15), cf * CFrame.new(0, -7, 0), Art.Charcoal)
	for _, x in {-13.5, 13.5} do
		Art.Block(model, "MagazineUpright", Vector3.new(3, 34, 13), cf * CFrame.new(x, 10, 0), palette[2])
	end
	Art.Block(model, "MagazineCrown", Vector3.new(30, 3, 15), cf * CFrame.new(0, 27, 0), palette[2])
	Art.Block(model, "BackPanel", Vector3.new(25, 30, 1.2), cf * CFrame.new(0, 10, -5.9), Art.Charcoal)
	for row = 1, 3 do
		local height = -1 + (row - 1) * 9
		local tray = Art.Model(model, "CapDrawer" .. row)
		Art.Block(tray, "Drawer", Vector3.new(25, 1.5, 12), cf * CFrame.new(0, height - 1, 1), palette[1])
		Art.Block(tray, "PullLip", Vector3.new(25, 1, 1), cf * CFrame.new(0, height - .9, 7), palette[2])
		for column = 1, 4 do
			local x = (column - 2.5) * 6.2
			Art.Block(tray, "Compartment", Vector3.new(5.2, .2, 7), cf * CFrame.new(x, height, 1), Art.Charcoal)
			for _, z in {-.6, 2.6} do
				Art.Key(tray, template, cf * CFrame.new(x, height + .4, z), "Thocky", if column % 2 == 0 then 2 else 1, tostring(column))
			end
			if column < 4 then Art.Block(tray, "Divider", Vector3.new(.6, 2.1, 10), cf * CFrame.new(x + 3.1, height + .2, 1), palette[2]) end
		end
	end
	model.PrimaryPart = model.MagazineBase
	return model
end

local function clacky(parent: Instance, origin: Vector3, template: MeshPart): Model
	local model = Art.Model(parent, "ClackySplitFins")
	model:SetAttribute("LandmarkId", "Clacky")
	local cf = CFrame.new(origin + Vector3.new(-10, 15, 223)) * CFrame.Angles(0, math.rad(6), 0)
	local palette = Art.Palette.Clacky
	Art.Block(model, "SwitchBase", Vector3.new(16, 3, 17), cf * CFrame.new(0, -5, 0), Art.Charcoal)
	Art.Block(model, "SwitchInsert", Vector3.new(11, 7, 11), cf * CFrame.new(0, 0, 0), palette[2])
	local clear = Art.Block(model, "SwitchShell", Vector3.new(13, 13, 13), cf * CFrame.new(0, 4, 0), palette[1])
	clear.Material, clear.Transparency = Enum.Material.Glass, .55
	for _, x in {-7, 7} do for _, z in {-7, 7} do
		Art.Block(model, "SwitchFrame", Vector3.new(1.4, 17, 1.4), cf * CFrame.new(x, 3, z), Art.Charcoal)
	end end
	Art.Block(model, "SwitchCrown", Vector3.new(15, 1.8, 15), cf * CFrame.new(0, 12, 0), palette[2])
	for _, side in {-1, 1} do
		local finFrame = cf * CFrame.new(side * 18, 11, 0) * CFrame.Angles(0, 0, math.rad(side * -58))
		local fin = Art.Tray(model, template, finFrame, "Clacky", 3, 5)
		fin.Name = if side < 0 then "LeftKeyboardFin" else "RightKeyboardFin"
		Art.Beam(model, "FinBrace", cf:PointToWorldSpace(Vector3.new(side * 5, -4, 0)), cf:PointToWorldSpace(Vector3.new(side * 23, 8, 0)), 3, Art.Charcoal)
	end
	model.PrimaryPart = model.SwitchBase
	return model
end

local function clicky(parent: Instance, origin: Vector3): Model
	local model = Art.Model(parent, "ClickyRotaryDial")
	model:SetAttribute("LandmarkId", "Clicky")
	local cf = CFrame.new(origin + Vector3.new(-224, 12, 28)) * CFrame.Angles(0, math.rad(12), 0)
	local palette = Art.Palette.Clicky
	Art.Block(model, "DialCase", Vector3.new(33, 5, 32), cf * CFrame.new(0, -6, 0), Art.Charcoal)
	Art.Block(model, "SteppedCase", Vector3.new(28, 3, 28), cf * CFrame.new(0, -2.5, 0), palette[3])
	local cylinderFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	Art.Cylinder(model, "CobaltDial", cylinderFrame * CFrame.new(4.5, 0, 0), 9, 25, palette[2])
	Art.Cylinder(model, "IvoryCenter", cylinderFrame * CFrame.new(9.2, 0, 0), .5, 17, palette[1])
	for index = 0, 11 do
		local angle = index * math.pi / 6
		Art.Block(model, "GripNotch", Vector3.new(3.3, 9.5, 2.4), cf * CFrame.new(math.sin(angle) * 12, 4.5, math.cos(angle) * 12) * CFrame.Angles(0, angle, 0), if index % 3 == 0 then palette[3] else palette[2])
	end
	Art.Block(model, "Pointer", Vector3.new(2.3, .7, 9), cf * CFrame.new(0, 9.9, -4.5), palette[1])
	Art.Block(model, "DialIndicator", Vector3.new(3.6, .5, 1.3), cf * CFrame.new(0, -.7, -14.4), Art.Trace)
	model.PrimaryPart = model.DialCase
	return model
end

function Landmarks.Build(parent: Instance, origin: Vector3, template: MeshPart): Model
	local group = Art.Model(parent, "HardwareLandmarks")
	usb(group, origin)
	creamy(group, origin, template)
	thocky(group, origin, template)
	clacky(group, origin, template)
	clicky(group, origin)
	return group
end

return Landmarks
