-- Run in Edit mode after inserting asset 105751216627858 under ServerStorage.
assert(game.PlaceId == 85558151074819, "Wrong place")
local tree = game.ServerStorage:FindFirstChild("StylizedOakApiTest")
assert(tree and tree:IsA("Model"), "Insert the uploaded test model first")
assert(not workspace:FindFirstChild("StylizedOakApiTest"), "Test model already placed")
local original = workspace:FindFirstChild("StylizedOak")
assert(original and original:GetAttribute("ImportFinished"), "Original tree is missing")
local count = 0
for _, part in tree:GetDescendants() do
	assert(not part:IsA("LuaSourceContainer"), "Unexpected script in uploaded model")
	if part:IsA("BasePart") then
		local reference = original:FindFirstChild(part.Name)
		assert(reference and reference:IsA("MeshPart") and part:IsA("MeshPart"), "Unexpected mesh")
		count += 1
	end
end
assert(count == 14, "Expected 14 uploaded meshes")
local _, size = tree:GetBoundingBox()
tree:ScaleTo(tree:GetScale() * 16 / size.Y)
tree:PivotTo(CFrame.new())
local bounds, scaledSize = tree:GetBoundingBox()
local bottomCenter = bounds.Position - Vector3.new(0, scaledSize.Y / 2, 0)
tree:PivotTo(tree:GetPivot() + Vector3.new(4, 17, -140) - bottomCenter)
for _, part in tree:GetDescendants() do
	if part:IsA("BasePart") then
		part.Color = original[part.Name].Color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = part.Name == "Trunk"
		part.CanTouch = false
	end
end
tree:SetAttribute("ImportFinished", true)
tree:SetAttribute("SourceFile", "assets/trees/StylizedOak.blend")
tree:SetAttribute("OpenCloudAssetId", "105751216627858")
tree.Parent = workspace
game:GetService("Selection"):Set({tree})
workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(32, 31, -165), Vector3.new(16, 24, -137))
return "API-uploaded tree placed for comparison"
