--!nonstrict
local MeshKit = {}
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)

function MeshKit.Place(parent, name, assetName, frame, scale)
	local library = game.ServerStorage.CourseAssetKits:FindFirstChild(Config.BlenderLibraryName)
	assert(library and library:GetAttribute("ImportVerified") == true, "Verify the Blender library before assembly")
	local template = library:FindFirstChild(assetName)
	assert(template and template:IsA("Model"), "Missing Blender edit unit: " .. assetName)
	local model = template:Clone()
	model.Name = name
	model.Parent = parent
	scale = scale or Vector3.one
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local localFrame = part.CFrame
		part.Size *= scale
		part.CFrame = frame * CFrame.new(localFrame.Position * scale) * localFrame.Rotation
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	end
	model.WorldPivot = frame
	model:SetAttribute("MCEditUnit", assetName)
	model:SetAttribute("VisualSource", Config.BlenderSourceFile)
	return model
end

return MeshKit
