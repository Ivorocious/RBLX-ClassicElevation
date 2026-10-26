--!strict
local Parts = require(script.Parent.Parts)
local Art = {}
Art.Palette = Parts.Palette
Art.Charcoal = Parts.Charcoal
Art.Silver = Color3.fromRGB(190, 205, 212)
Art.Trace = Color3.fromRGB(106, 216, 191)
Art.Gold = Color3.fromRGB(245, 198, 85)

function Art.Overlaps(a: CFrame, aSize: Vector3, b: CFrame, bSize: Vector3): boolean
	local function axes(cf: CFrame): {Vector3}
		return {cf.RightVector, cf.UpVector, -cf.LookVector}
	end
	local function extent(axis: Vector3, cf: CFrame, size: Vector3): number
		return math.abs(axis:Dot(cf.RightVector))*size.X/2 + math.abs(axis:Dot(cf.UpVector))*size.Y/2 + math.abs(axis:Dot(-cf.LookVector))*size.Z/2
	end
	local all = axes(a)
	for _, axis in axes(b) do table.insert(all, axis) end
	for _, left in axes(a) do for _, right in axes(b) do
		local cross = left:Cross(right)
		if cross.Magnitude > .00001 then table.insert(all, cross.Unit) end
	end end
	for _, axis in all do
		if math.abs((b.Position-a.Position):Dot(axis)) >= extent(axis,a,aSize)+extent(axis,b,bSize)-.02 then return false end
	end
	return true
end

function Art.Model(parent: Instance, name: string): Model
	local model = Parts.Model(parent, name)
	model:SetAttribute("MapArtwork", true)
	return model
end

function Art.Block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local part = Parts.Block(parent, name, size, cf, color, false)
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part:SetAttribute("Role", "MapArtwork")
	part:SetAttribute("MapArtwork", true)
	return part
end

function Art.Beam(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3): Part
	local midpoint = (a + b) / 2
	return Art.Block(parent, name, Vector3.new(width, width, (b - a).Magnitude), CFrame.lookAt(midpoint, b), color)
end

function Art.Cylinder(parent: Instance, name: string, cf: CFrame, length: number, diameter: number, color: Color3): Part
	local part = Art.Block(parent, name, Vector3.new(length, diameter, diameter), cf, color)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Art.Key(parent: Instance, template: MeshPart, cf: CFrame, family: string, column: number, legend: string): MeshPart
	local key = template:Clone()
	key.Name, key.Size, key.CFrame = "InventoryCap", Vector3.new(2.4, .85, 2.4), cf
	key.PivotOffset = CFrame.identity
	key.Anchored, key.CanCollide, key.CanTouch, key.CanQuery = true, false, false, false
	key.Color, key.Material = Parts.Palette[family][column], Enum.Material.SmoothPlastic
	key:SetAttribute("Pressable", false)
	key:SetAttribute("Role", "MapArtwork")
	key:SetAttribute("MapArtwork", true)
	key.Parent = parent
	Parts.KeyLegend(key, legend)
	return key
end

function Art.Tray(parent: Instance, template: MeshPart, cf: CFrame, family: string, columns: number, rows: number): Model
	local tray = Art.Model(parent, "KeyboardTray")
	local size = Vector3.new(columns * 2.6 + 1.2, .7, rows * 2.6 + 1.2)
	tray.PrimaryPart = Art.Block(tray, "Case", size, cf * CFrame.new(0, -.8, 0), Parts.Charcoal)
	Art.Block(tray, "FrontLip", Vector3.new(size.X, 1, .65), cf * CFrame.new(0, -.6, size.Z / 2), Parts.Palette[family][2])
	local glyphs = {"Q", "W", "E", "R", "T", "Y", "A", "S", "D", "F", "G", "H", "Z", "X", "C", "V", "B", "N"}
	for row = 1, rows do
		for column = 1, columns do
			local position = cf * CFrame.new((column - (columns + 1) / 2) * 2.6, 0, (row - (rows + 1) / 2) * 2.6)
			local color = if column == 1 then 3 elseif column == columns then 2 else 1
			local key = Art.Key(tray, template, position, family, color, glyphs[((row - 1) * columns + column - 1) % #glyphs + 1])
			key.Name = "Cap_" .. row .. "_" .. column
		end
	end
	return tray
end

return Art
