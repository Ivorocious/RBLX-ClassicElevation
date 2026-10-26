-- Run once in Studio Edit mode after importing StylizedOak.fbx.
local tree = workspace:FindFirstChild("StylizedOak")
assert(tree and tree:IsA("Model"), "Import StylizedOak.fbx first")
assert(not tree:GetAttribute("ImportFinished"), "Tree is already configured")
local _, size = tree:GetBoundingBox()
tree:ScaleTo(tree:GetScale() * 16 / size.Y)
tree:PivotTo(CFrame.new(30, 17, -137))
local bounds, scaledSize = tree:GetBoundingBox()
tree:PivotTo(tree:GetPivot() + Vector3.new(0, 17 - (bounds.Position.Y - scaledSize.Y / 2), 0))
local canopyColors = {
	Canopy1 = Color3.fromRGB(115, 162, 77),
	Canopy2 = Color3.fromRGB(139, 181, 89),
	Canopy3 = Color3.fromRGB(115, 162, 77),
	Canopy4 = Color3.fromRGB(139, 181, 89),
	Canopy5 = Color3.fromRGB(162, 197, 105),
}
for _, part in tree:GetDescendants() do
	if part:IsA("BasePart") then
		part.Anchored = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = canopyColors[part.Name] or Color3.fromRGB(137, 97, 66)
		part.CanCollide = part.Name == "Trunk"
		part.CanTouch = false
	end
end
tree:SetAttribute("ImportFinished", true)
tree:SetAttribute("SourceFile", "assets/trees/StylizedOak.blend")
game:GetService("Selection"):Set({tree})
workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(49, 29, -157), Vector3.new(30, 25, -137))
return "StylizedOak placed in lobby; height 16 studs"
