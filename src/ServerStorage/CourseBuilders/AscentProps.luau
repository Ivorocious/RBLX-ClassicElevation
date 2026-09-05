--!strict

local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")
local Manifest = require(script.Parent.AscentPropManifest)
local V7Manifest = require(script.Parent.AscentV7PropManifest)
local Props = {}
local templates: Folder? = nil

local function prepareLibrary(manifest: any, version: string): Folder
	local cached = ServerStorage:FindFirstChild("AscentMeshLibrary" .. version)
	if cached and cached:IsA("Folder") then return cached end
	local source = ServerStorage:FindFirstChild("AscentPropsImport" .. version)
	if not source then
		assert(manifest.AssetId > 0, "The Blender prop kit must be uploaded before building Classic Ascent")
		source = InsertService:LoadAsset(manifest.AssetId)
		source.Name, source.Parent = "AscentPropsImport" .. version, ServerStorage
	end
	local meshes: {[string]: MeshPart} = {}
	for _, object in ipairs(source:GetDescendants()) do
		assert(not object:IsA("LuaSourceContainer"), "Unexpected script in Blender prop asset")
		if object:IsA("MeshPart") then meshes[object.Name] = object end
	end
	local library = Instance.new("Folder")
	library.Name = "AscentMeshLibrary" .. version
	for name, definition in pairs(manifest.Props) do
		local model = Instance.new("Model")
		model.Name = name
		for _, meshName in ipairs(definition.parts) do
			local original = meshes[meshName]
			assert(original, "Missing Blender mesh: " .. meshName)
			local mesh = original:Clone()
			mesh.Color, mesh.Material = manifest.Colors[meshName], Enum.Material.SmoothPlastic
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
	return library
end

function Props.Prepare(): Folder
	if templates then return templates end
	local original = prepareLibrary(Manifest, "V5")
	local library = prepareLibrary(V7Manifest, "V7")
	for _, model in ipairs(original:GetChildren()) do
		if not library:FindFirstChild(model.Name) then model:Clone().Parent = library end
	end
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
