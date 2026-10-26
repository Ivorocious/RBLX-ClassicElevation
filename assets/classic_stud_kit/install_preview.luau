-- Run in Edit mode after loading asset 91963888161700 into ServerStorage.
assert(game.PlaceId == 85558151074819, "Wrong place")
assert(not workspace:FindFirstChild("ClassicStudKitPreview_V1"), "Preview already exists")
local source = game.ServerStorage:FindFirstChild("ClassicStudKit_V1")
assert(source and source:IsA("Model"), "Import the kit first")
local definitions = {
	Floor = {position = Vector3.new(-11, 0, 7), color = Color3.fromRGB(94, 157, 76), boxes = {{0, .5, 0, 8, 1, 8}}},
	Wall = {position = Vector3.new(0, 0, -7), color = Color3.fromRGB(231, 186, 71), boxes = {{0, 3, 0, 8, 6, 1}}},
	Wedge = {position = Vector3.new(0, 0, 7), color = Color3.fromRGB(79, 140, 193), boxes = {{0, 2, 0, 8, 4, 8}}, wedge = true},
	Stair = {position = Vector3.new(11, 0, 7), color = Color3.fromRGB(192, 97, 76), boxes = {
		{0, .5, 3, 8, 1, 2}, {0, 1, 1, 8, 2, 2}, {0, 1.5, -1, 8, 3, 2}, {0, 2, -3, 8, 4, 2}}},
	Corner = {position = Vector3.new(-11, 0, -7), color = Color3.fromRGB(150, 116, 181), boxes = {
		{-2.5, .5, 0, 3, 1, 8}, {1.5, .5, -2.5, 5, 1, 3}}},
}
local originals = {}
for _, item in source:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "Unexpected imported script")
	if item:IsA("BasePart") then
		assert(item:IsA("MeshPart") and definitions[item.Name] and not originals[item.Name], "Unexpected imported mesh")
		originals[item.Name] = item
	end
end
for name in definitions do assert(originals[name], "Missing " .. name) end
assert(math.abs(originals.Floor.Size.X - 800) < .01, "Unexpected import scale")

local origin = Vector3.new(1770, 355, -845)
local root = Instance.new("Model")
root.Name = "ClassicStudKitPreview_V1"
root:SetAttribute("SourceAssetId", "91963888161700")
root:SetAttribute("SourceFile", "assets/classic_stud_kit/ClassicStudKit_V1.blend")
local rotation = CFrame.Angles(0, math.pi, 0)
local function part(name, size, cf, parent, color)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, cf
	item.Anchored, item.CanTouch = true, false
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item.Material, item.Color, item.Parent = Enum.Material.SmoothPlastic, color, parent
	return item
end
for name, definition in definitions do
	local group = Instance.new("Model")
	group.Name, group.Parent = name, root
	local mesh = originals[name]:Clone()
	mesh.Name = "Visual"
	mesh.Size /= 100
	mesh.CFrame = CFrame.new(origin) * rotation * (CFrame.new(mesh.Position / 100) * mesh.CFrame.Rotation)
	mesh.Anchored, mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = true, false, false, false
	mesh.Color, mesh.Material, mesh.Parent = definition.color, Enum.Material.SmoothPlastic, group
	for index, box in definition.boxes do
		local collider = Instance.new(definition.wedge and "WedgePart" or "Part")
		collider.Name = "Collision" .. index
		collider.Size = Vector3.new(box[4], box[5], box[6])
		collider.CFrame = CFrame.new(origin + definition.position + Vector3.new(box[1], box[2], box[3]))
		if definition.wedge then collider.CFrame *= rotation end
		collider.Anchored, collider.Transparency, collider.CanCollide = true, 1, true
		collider.CanTouch, collider.Parent = false, group
	end
	group.WorldPivot = CFrame.new(origin + definition.position)
	group:SetAttribute("StudPitch", 1)
	group:SetAttribute("StudWidth", .65)
	group:SetAttribute("StudHeight", .12)
end
local native = part("NativeStudsReference", Vector3.new(8, 1, 8), CFrame.new(origin + Vector3.new(22, .5, 7)), root, definitions.Floor.color)
native.TopSurface = Enum.SurfaceType.Studs
native.Material = Enum.Material.Plastic
part("PreviewDeck", Vector3.new(54, 1, 30), CFrame.new(origin + Vector3.new(5, -.5, 0)), root, Color3.fromRGB(62, 70, 80))
for name, position in {Floor = Vector3.new(-11, .12, 13), Wedge = Vector3.new(0, .12, 13), Stair = Vector3.new(11, .12, 13), Native = Vector3.new(22, .12, 13)} do
	local labelPart = part(name .. "Label", Vector3.new(7, .05, 1.5), CFrame.new(origin + position), root, Color3.fromRGB(62, 70, 80))
	labelPart.CanCollide, labelPart.CanQuery = false, false
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.Parent = Enum.NormalId.Top, Vector2.new(560, 120), labelPart
	gui.LightInfluence, gui.AlwaysOnTop = 0, true
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3, label.TextSize = string.upper(name), Color3.new(1, 1, 1), 52
	label.Font, label.Parent = Enum.Font.GothamBold, gui
end
root.WorldPivot = CFrame.new(origin)
root.Parent = workspace
game:GetService("Selection"):Set({root})
workspace.CurrentCamera.CFrame = CFrame.lookAt(origin + Vector3.new(40, 32, 44), origin + Vector3.new(5, 1, 0))
return "Five reusable mesh-and-collision groups placed at Workspace.ClassicStudKitPreview_V1"
