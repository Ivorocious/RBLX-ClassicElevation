--!strict

local Kit = {}

Kit.Palette = {
	Stone = Color3.fromRGB(111, 122, 137),
	StoneLight = Color3.fromRGB(149, 157, 169),
	StoneDark = Color3.fromRGB(77, 87, 103),
	Floor = Color3.fromRGB(158, 161, 164),
	Slate = Color3.fromRGB(37, 55, 81),
	Iron = Color3.fromRGB(30, 37, 49),
	Brass = Color3.fromRGB(176, 131, 62),
	Amber = Color3.fromRGB(255, 182, 67),
	Window = Color3.fromRGB(191, 106, 28),
	Leaf = Color3.fromRGB(67, 88, 59),
	Red = Color3.fromRGB(255, 29, 43),
	Checkpoint = Color3.fromRGB(49, 224, 238),
}
local palette = Kit.Palette

local function model(parent: Instance, name: string, role: string, cf: CFrame): Model
	local item = Instance.new("Model")
	item.Name = name
	item.WorldPivot = cf
	item:SetAttribute("Role", role)
	item:SetAttribute("MCEditUnit", true)
	item:SetAttribute("Source", "MoonlitCitadel/Kit.luau native construction")
	item.Parent = parent
	return item
end

function Kit.Part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3?, material: Enum.Material?, collidable: boolean?): BasePart
	assert(size.X > 0 and size.Y > 0 and size.Z > 0, "Part dimensions must be positive")
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, cf
	item.Color, item.Material = color or palette.Stone, material or Enum.Material.Concrete
	item.Anchored, item.CanCollide = true, collidable ~= false
	item.CanTouch, item.CanQuery = false, item.CanCollide
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item:SetAttribute("Role", if item.CanCollide then "SolidBlocker" else "Decoration")
	item.Parent = parent
	return item
end

local function visual(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local item = Kit.Part(parent, name, size, cf, color, material, false)
	item.CastShadow = false
	return item
end

local function finish(item: Model, primary: BasePart, cf: CFrame): Model
	primary.PivotOffset = primary.CFrame:ToObjectSpace(cf)
	item.PrimaryPart = primary
	return item
end

local function bar(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, depth: number, color: Color3, material: Enum.Material?): BasePart
	local delta = b - a
	assert(delta.Magnitude > 0.001, "Trim endpoints must differ")
	return visual(parent, name, Vector3.new(depth, width, delta.Magnitude), CFrame.lookAt((a + b) / 2, b), color, material)
end

-- Two right triangles keep the pointed faces closed without an uploaded mesh.
local function triangle(parent: Instance, name: string, a: Vector3, b: Vector3, c: Vector3, thickness: number, color: Color3, material: Enum.Material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		c, a = a, c
	elseif ac.Magnitude > ab.Magnitude and ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local back = bc.Unit
	local up = bc:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	for index, spec in {
		{Size = Vector3.new(thickness, height, math.abs(ab:Dot(back))), Cf = CFrame.fromMatrix((a + b) / 2, right, up, back)},
		{Size = Vector3.new(thickness, height, math.abs(ac:Dot(back))), Cf = CFrame.fromMatrix((a + c) / 2, -right, up, -back)},
	} do
		if spec.Size.Z > 0.001 then
			local face = Instance.new("WedgePart")
			face.Name, face.Size, face.CFrame = name .. index, spec.Size, spec.Cf
			face.Color, face.Material = color, material
			face.Anchored, face.CanCollide, face.CanTouch, face.CanQuery = true, false, false, false
			face.CastShadow = material ~= Enum.Material.Neon
			face.TopSurface, face.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			face:SetAttribute("Role", "Decoration")
			face.Parent = parent
		end
	end
end

local function pointed(parent: Instance, name: string, cf: CFrame, width: number, height: number, depth: number, color: Color3, material: Enum.Material): BasePart
	local shoulder = height * 0.62
	local lower = visual(parent, name .. "Lower", Vector3.new(width, shoulder, depth), cf * CFrame.new(0, shoulder / 2, 0), color, material)
	triangle(parent, name .. "Point", cf:PointToWorldSpace(Vector3.new(0, height, 0)), cf:PointToWorldSpace(Vector3.new(-width / 2, shoulder, 0)), cf:PointToWorldSpace(Vector3.new(width / 2, shoulder, 0)), depth, color, material)
	return lower
end

function Kit.Floor(parent: Instance, name: string, size: Vector3, cf: CFrame): Model
	assert(size.X >= 2 and size.Z >= 2 and size.Y > 0, "Floor needs positive thickness and at least two studs of width/depth")
	local item = model(parent, name, "Walkable", cf)
	local contact = Kit.Part(item, "Contact", size, cf * CFrame.new(0, -size.Y / 2, 0), palette.Floor)
	contact:SetAttribute("Role", "Walkable")
	local trim = model(item, "EdgeAndJoints", "Decoration", cf)
	local edgeHeight = math.min(0.3, size.Y * 0.45)
	for _, side in {-1, 1} do
		visual(trim, "EdgeX" .. side, Vector3.new(0.16, edgeHeight, size.Z), cf * CFrame.new(side * (size.X / 2 - 0.08), -edgeHeight / 2 - 0.03, 0), palette.StoneLight)
		visual(trim, "EdgeZ" .. side, Vector3.new(size.X - 0.32, edgeHeight, 0.16), cf * CFrame.new(0, -edgeHeight / 2 - 0.03, side * (size.Z / 2 - 0.08)), palette.StoneLight)
	end
	for axis, extent in {X = size.X, Z = size.Z} do
		local bays = math.clamp(math.floor(extent / 5), 1, 6)
		for index = 1, bays - 1 do
			local offset = -extent / 2 + extent * index / bays
			local jointSize = if axis == "X" then Vector3.new(0.035, 0.012, size.Z - 0.32) else Vector3.new(size.X - 0.32, 0.012, 0.035)
			local position = if axis == "X" then Vector3.new(offset, -0.006, 0) else Vector3.new(0, -0.006, offset)
			visual(trim, "Joint" .. axis .. index, jointSize, cf * CFrame.new(position), palette.StoneDark)
		end
	end
	item:SetAttribute("ContactTopLocalY", 0)
	return finish(item, contact, cf)
end

function Kit.Window(parent: Instance, name: string, cf: CFrame, width: number, height: number): Model
	assert(width >= 1.5 and height >= width * 1.4, "Window needs a slender pointed proportion")
	local item = model(parent, name, "Decoration", cf)
	local stone = model(item, "StoneSurround", "Decoration", cf)
	local glass = model(item, "GlassAndTracery", "Decoration", cf)
	local shoulder, half = height * 0.62, width / 2
	local frame = math.clamp(width * 0.065, 0.16, 0.65)
	local base = pointed(stone, "Recess", cf * CFrame.new(0, 0, 0.12), width, height, 0.24, palette.StoneDark, Enum.Material.Concrete)
	pointed(glass, "AmberPane", cf * CFrame.new(0, frame, -0.025), width - frame * 2.4, height - frame * 2, 0.08, palette.Window, Enum.Material.Neon)
	for _, side in {-1, 1} do
		visual(stone, "Jamb" .. side, Vector3.new(frame, shoulder, 0.38), cf * CFrame.new(side * half, shoulder / 2, -0.08), palette.StoneLight)
		local previous = Vector3.new(side * half, shoulder, -0.08)
		for index = 1, 4 do
			local theta = math.pi - index / 4 * math.pi / 3
			local nextPoint = Vector3.new(side * -(half + width * math.cos(theta)), shoulder + (height - shoulder) * math.sin(theta) / math.sin(math.pi / 3), -0.08)
			bar(stone, "PointedFrame" .. side .. "_" .. index, cf:PointToWorldSpace(previous), cf:PointToWorldSpace(nextPoint), frame, 0.38, palette.StoneLight)
			previous = nextPoint
		end
	end
	visual(stone, "Sill", Vector3.new(width + frame * 2, frame, 0.5), cf * CFrame.new(0, frame / 2, -0.09), palette.StoneLight)
	visual(glass, "CenterMullion", Vector3.new(frame * 0.45, height * 0.66, 0.09), cf * CFrame.new(0, height * 0.34, -0.11), palette.Brass, Enum.Material.Metal)
	for _, side in {-1, 1} do
		bar(glass, "DiamondLower" .. side, cf:PointToWorldSpace(Vector3.new(0, height * 0.17, -0.11)), cf:PointToWorldSpace(Vector3.new(side * width * 0.26, height * 0.37, -0.11)), frame * 0.25, 0.065, palette.Brass, Enum.Material.Metal)
		bar(glass, "DiamondUpper" .. side, cf:PointToWorldSpace(Vector3.new(side * width * 0.26, height * 0.37, -0.11)), cf:PointToWorldSpace(Vector3.new(0, height * 0.57, -0.11)), frame * 0.25, 0.065, palette.Brass, Enum.Material.Metal)
	end
	if width >= 5 then
		local center = Vector3.new(0, height * 0.75, -0.15)
		for index, offset in {Vector3.new(-width * 0.065, 0, 0), Vector3.new(width * 0.065, 0, 0), Vector3.new(0, width * 0.065, 0), Vector3.new(0, -width * 0.065, 0)} do
			local border = visual(glass, "QuatrefoilBorder" .. index, Vector3.new(width * 0.18, width * 0.18, 0.08), cf * CFrame.new(center + offset), palette.Brass, Enum.Material.Metal) :: Part
			border.Shape = Enum.PartType.Ball
			local lobe = visual(glass, "QuatrefoilLight" .. index, Vector3.new(width * 0.13, width * 0.13, 0.08), cf * CFrame.new(center + offset + Vector3.new(0, 0, -0.045)), palette.Window, Enum.Material.Neon) :: Part
			lobe.Shape = Enum.PartType.Ball
		end
	end
	item:SetAttribute("Front", "-Z")
	return finish(item, base, cf)
end

function Kit.Turret(parent: Instance, name: string, cf: CFrame, width: number, height: number): Model
	assert(width >= 3 and height >= width * 2, "Turret must be slender")
	local item = model(parent, name, "Decoration", cf)
	local shaft = model(item, "Shaft", "Decoration", cf)
	local roof = model(item, "SlateSpire", "Decoration", cf)
	local bodyHeight, roofHeight = height * 0.66, height * 0.34
	local body = visual(shaft, "Body", Vector3.new(width, bodyHeight, width), cf * CFrame.new(0, bodyHeight / 2, 0), palette.Stone)
	body.CastShadow = true
	for index, y in {0.25, bodyHeight * 0.45, bodyHeight - 0.2} do
		visual(shaft, "CourseBand" .. index, Vector3.new(width + 0.3, 0.4, width + 0.3), cf * CFrame.new(0, y, 0), palette.StoneLight)
	end
	local windowWidth = math.max(1.5, width * 0.42)
	local windowHeight = math.max(windowWidth * 1.4, bodyHeight * 0.48)
	for index, angle in {0, math.pi / 2} do
		Kit.Window(shaft, "RecessedWindow" .. index, cf * CFrame.Angles(0, angle, 0) * CFrame.new(0, bodyHeight * 0.38, -width / 2 - 0.02), windowWidth, windowHeight)
	end
	local roofWidth = width * 1.12
	local corners = {
		Vector3.new(-roofWidth / 2, bodyHeight, -roofWidth / 2),
		Vector3.new(roofWidth / 2, bodyHeight, -roofWidth / 2),
		Vector3.new(roofWidth / 2, bodyHeight, roofWidth / 2),
		Vector3.new(-roofWidth / 2, bodyHeight, roofWidth / 2),
	}
	local apex = Vector3.new(0, bodyHeight + roofHeight, 0)
	for index, corner in corners do
		triangle(roof, "RoofFace" .. index .. "_", cf:PointToWorldSpace(apex), cf:PointToWorldSpace(corner), cf:PointToWorldSpace(corners[index % 4 + 1]), 0.06, palette.Slate, Enum.Material.Slate)
		bar(roof, "Hip" .. index, cf:PointToWorldSpace(corner), cf:PointToWorldSpace(apex), 0.12, 0.12, palette.StoneDark)
	end
	visual(roof, "ClosedEave", Vector3.new(roofWidth, 0.18, roofWidth), cf * CFrame.new(0, bodyHeight, 0), palette.StoneLight)
	visual(roof, "BrassFinial", Vector3.new(0.18, 0.9, 0.18), cf * CFrame.new(0, height + 0.25, 0), palette.Brass, Enum.Material.Metal)
	item:SetAttribute("BaseLocalY", 0)
	return finish(item, body, cf)
end

function Kit.Arch(parent: Instance, name: string, cf: CFrame, width: number, rise: number, depth: number): Model
	assert(width >= 3 and rise > 0 and depth > 0, "Arch dimensions must be positive")
	local item = model(parent, name, "Decoration", cf)
	item:SetAttribute("Use", "Support appearance only; add explicit traversal contacts separately")
	local shell = model(item, "CurvedSupport", "Decoration", cf)
	local thickness = math.clamp(width * 0.08, 0.5, 1.8)
	local primary: BasePart? = nil
	for index = 1, 10 do
		local t0, t1 = (index - 1) / 10, index / 10
		local a = Vector3.new(-width / 2 + width * t0, rise * math.sin(math.pi * t0), 0)
		local b = Vector3.new(-width / 2 + width * t1, rise * math.sin(math.pi * t1), 0)
		local segment = bar(shell, "StoneSegment" .. index, cf:PointToWorldSpace(a), cf:PointToWorldSpace(b), thickness, depth, palette.Stone)
		segment.CastShadow = true
		if not primary then primary = segment end
	end
	assert(primary)
	return finish(item, primary, cf)
end

function Kit.Rail(parent: Instance, name: string, cf: CFrame, length: number): Model
	assert(length >= 2, "Rail needs at least two studs")
	local item = model(parent, name, "SolidBlocker", cf)
	local contact = Kit.Part(item, "RailContact", Vector3.new(length, 2.8, 0.44), cf * CFrame.new(0, 1.4, 0), palette.Iron, Enum.Material.Metal)
	contact.Transparency = 1
	contact.CastShadow = false
	local stone = model(item, "StoneSill", "Decoration", cf)
	local iron = model(item, "IronBalustrade", "Decoration", cf)
	visual(stone, "LowSill", Vector3.new(length, 0.55, 0.6), cf * CFrame.new(0, 0.275, 0), palette.StoneLight)
	visual(iron, "Handrail", Vector3.new(length, 0.14, 0.34), cf * CFrame.new(0, 2.73, 0), palette.Brass, Enum.Material.Metal)
	local bays = math.clamp(math.floor(length / 2.4), 1, 8)
	for index = 0, bays do
		local x = -length / 2 + index * length / bays
		visual(iron, "Upright" .. index, Vector3.new(0.12, 2.15, 0.16), cf * CFrame.new(x, 1.59, 0), palette.Iron, Enum.Material.Metal)
	end
	return finish(item, contact, cf)
end

function Kit.Lantern(parent: Instance, name: string, cf: CFrame, size: Vector3): Model
	assert(size.X >= 1 and size.Y >= 2 and size.Z >= 1, "Lantern must have room for its cage")
	local item = model(parent, name, "Hazard", cf)
	local contact = Kit.Part(item, "CageContact", size, cf, palette.Iron, Enum.Material.Metal, false)
	contact.Transparency, contact.CanTouch, contact.CanQuery = 1, true, true
	contact.CastShadow = false
	contact:SetAttribute("Role", "Hazard")
	local cage = model(item, "CageAndCore", "Decoration", cf)
	local mounts = model(item, "Mounting", "Decoration", cf)
	local core = visual(cage, "AmberCore", Vector3.new(size.X * 0.58, size.Y * 0.68, size.Z * 0.58), cf, palette.Amber, Enum.Material.Neon)
	core.CastShadow = false
	for _, y in {-1, 1} do
		visual(cage, "EndCap" .. y, Vector3.new(size.X, size.Y * 0.12, size.Z), cf * CFrame.new(0, y * size.Y * 0.44, 0), palette.Iron, Enum.Material.Metal)
		visual(cage, "BrassRim" .. y, Vector3.new(size.X * 1.005, 0.1, size.Z * 1.005), cf * CFrame.new(0, y * size.Y * 0.365, 0), palette.Brass, Enum.Material.Metal)
	end
	for _, x in {-1, 1} do
		for _, z in {-1, 1} do
			visual(cage, "CagePost" .. x .. "_" .. z, Vector3.new(0.13, size.Y * 0.8, 0.13), cf * CFrame.new(x * (size.X / 2 - 0.07), 0, z * (size.Z / 2 - 0.07)), palette.Brass, Enum.Material.Metal)
		end
	end
	visual(mounts, "SuspensionStem", Vector3.new(0.17, size.Y * 0.35, 0.17), cf * CFrame.new(0, size.Y * 0.67, 0), palette.Iron, Enum.Material.Metal)
	visual(mounts, "MountCollar", Vector3.new(size.X * 0.35, 0.16, size.Z * 0.35), cf * CFrame.new(0, size.Y * 0.53, 0), palette.Brass, Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Name, light.Color = "AmberLight", palette.Amber
	light.Brightness, light.Range, light.Shadows = 0.9, math.clamp(size.Y * 3, 10, 26), false
	light.Parent = core
	return finish(item, contact, cf)
end

function Kit.Car(parent: Instance, name: string, cf: CFrame, width: number, depth: number): Model
	assert(width >= 4 and depth >= 4, "Car must leave usable boarding space")
	local item = model(parent, name, "Walkable", cf)
	local surface = Kit.Floor(item, "Platform", Vector3.new(width, 0.75, depth), cf)
	local deck = surface:FindFirstChild("Contact") :: BasePart
	deck.Name = "Deck"
	local underframe = model(item, "Underframe", "Decoration", cf)
	visual(underframe, "IronFascia", Vector3.new(width, 0.42, depth), cf * CFrame.new(0, -0.63, 0), palette.Iron, Enum.Material.Metal)
	for _, side in {-1, 1} do
		Kit.Rail(item, "SideRail" .. side, cf * CFrame.new(side * (width / 2 - 0.3), 0, 0) * CFrame.Angles(0, math.pi / 2, 0), depth - 0.6)
		visual(underframe, "BrassSideBand" .. side, Vector3.new(0.12, 0.12, depth), cf * CFrame.new(side * (width / 2 - 0.06), -0.33, 0), palette.Brass, Enum.Material.Metal)
	end
	item:SetAttribute("TransferEdges", "Open -Z and +Z; rails at X sides only")
	item:SetAttribute("ContactTopLocalY", 0)
	return finish(item, deck, cf)
end

function Kit.Weight(parent: Instance, name: string, cf: CFrame, width: number, height: number): Model
	assert(width >= 2 and height >= 3, "Weight dimensions are too small")
	local item = model(parent, name, "SolidBlocker", cf)
	local body = Kit.Part(item, "WeightContact", Vector3.new(width, height, width * 0.65), cf, palette.Stone)
	local details = model(item, "CapsAndEmblem", "Decoration", cf)
	for _, side in {-1, 1} do
		visual(details, "IronCap" .. side, Vector3.new(width, 0.25, width * 0.65), cf * CFrame.new(0, side * (height / 2 - 0.125), 0), palette.Iron, Enum.Material.Metal)
	end
	local z = -width * 0.325 - 0.025
	local diamond = {Vector3.new(0, height * 0.24, z), Vector3.new(width * 0.22, 0, z), Vector3.new(0, -height * 0.24, z), Vector3.new(-width * 0.22, 0, z)}
	for index, point in diamond do
		bar(details, "BrassDiamond" .. index, cf:PointToWorldSpace(point), cf:PointToWorldSpace(diamond[index % 4 + 1]), 0.08, 0.06, palette.Brass, Enum.Material.Metal)
	end
	return finish(item, body, cf)
end

function Kit.KillBlock(parent: Instance, name: string, cf: CFrame, size: Vector3): Model
	assert(size.X >= 2 and size.Y >= 0.4 and size.Z >= 2, "Kill block dimensions are too small")
	local item = model(parent, name, "Hazard", cf)
	local contact = Kit.Part(item, "HazardContact", size, cf, palette.Red, Enum.Material.Neon, false)
	contact.Transparency, contact.CanTouch, contact.CanQuery = 1, true, true
	contact.CastShadow = false
	contact:SetAttribute("Role", "Hazard")
	local casing = model(item, "FlushCasing", "Decoration", cf)
	visual(casing, "DarkBody", size, cf, palette.Iron, Enum.Material.Metal)
	visual(casing, "RedTop", Vector3.new(size.X, 0.08, size.Z), cf * CFrame.new(0, size.Y / 2 - 0.04, 0), palette.Red, Enum.Material.Neon).CastShadow = false
	local faceHeight = math.min(size.Y * 0.72, size.X * 0.5)
	if faceHeight >= 0.6 then
		pointed(casing, "RedFace", cf * CFrame.new(0, -faceHeight / 2, -size.Z / 2 + 0.01), math.min(size.X * 0.45, faceHeight * 0.6), faceHeight, 0.025, palette.Red, Enum.Material.Neon)
	end
	item:SetAttribute("NoSafeRim", true)
	return finish(item, contact, cf)
end

return Kit
