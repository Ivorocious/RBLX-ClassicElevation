--!strict

local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")
local Manifest = require(script.Parent.AscentPropManifest)
local Props = {}
local templates: Folder? = nil

function Props.Prepare(): Folder
	if templates then return templates end
	local cached = ServerStorage:FindFirstChild("AscentMeshLibraryV5")
	if cached and cached:IsA("Folder") then templates = cached; return cached end
	local source = ServerStorage:FindFirstChild("AscentPropsImportV5")
	if not source then
		assert(Manifest.AssetId > 0, "The Blender prop kit must be uploaded before building Classic Ascent v5")
		source = InsertService:LoadAsset(Manifest.AssetId)
		source.Name, source.Parent = "AscentPropsImportV5", ServerStorage
	end
	local meshes: {[string]: MeshPart} = {}
	for _, object in ipairs(source:GetDescendants()) do
		assert(not object:IsA("LuaSourceContainer"), "Unexpected script in Blender prop asset")
		if object:IsA("MeshPart") then meshes[object.Name] = object end
	end
	local library = Instance.new("Folder")
	library.Name = "AscentMeshLibraryV5"
	for name, definition in pairs(Manifest.Props) do
		local model = Instance.new("Model")
		model.Name = name
		for _, meshName in ipairs(definition.parts) do
			local original = meshes[meshName]
			assert(original, "Missing Blender mesh: " .. meshName)
			local mesh = original:Clone()
			mesh.Color, mesh.Material = Manifest.Colors[meshName], Enum.Material.SmoothPlastic
			mesh.Anchored, mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = true, false, false, false
			mesh.Parent = model
		end
		local _, size = model:GetBoundingBox()
		model:ScaleTo(model:GetScale() * definition.height / size.Y)
		local bounds, scaled = model:GetBoundingBox()
		local bottom = bounds.Position - Vector3.new(0, scaled.Y / 2, 0)
		model:PivotTo(model:GetPivot() - bottom)
		model.WorldPivot = CFrame.identity
		model:SetAttribute("AuthoredHeight", definition.height)
		model.Parent = library
	end
	library.Parent = ServerStorage
	templates = library
	return library
end

function Props.Place(parent: Instance, kind: string, bottomFrame: CFrame, height: number): Model
	local library = Props.Prepare()
	local template = library:FindFirstChild(kind)
	assert(template and template:IsA("Model"), "Unknown ascent prop: " .. kind)
	local model = template:Clone()
	model:ScaleTo(model:GetScale() * height / (model:GetAttribute("AuthoredHeight") :: number))
	model:PivotTo(bottomFrame)
	model.Parent = parent
	return model
end

return Props
