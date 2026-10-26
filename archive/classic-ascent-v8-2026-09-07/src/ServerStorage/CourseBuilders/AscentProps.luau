--!strict

local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")
local Manifest = require(script.Parent.AscentPropManifest)
local V7Manifest = require(script.Parent.AscentV7PropManifest)
local V8Manifest = require(script.Parent.AscentV8PropManifest)
local SurfaceManifest = require(script.Parent.AscentSurfaceManifest)
local RecoveryManifest = require(script.Parent.AscentRecoveryManifest)
local LedgeManifest = require(script.Parent.AscentLedgeManifest)
local RoutedManifest = require(script.Parent.AscentRoutedManifest)
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
	local combinedName="AscentMeshLibraryCombined"..RoutedManifest.AssetId
	local cached=ServerStorage:FindFirstChild(combinedName)
	if cached and cached:IsA("Folder") then templates=cached;return cached end
	local library=Instance.new("Folder")
	library.Name=combinedName
	for _,entry in ipairs({{V8Manifest,"V8"},{V7Manifest,"V7"},{Manifest,"V5"},{SurfaceManifest,"Surfaces"},{RecoveryManifest,"Recovery"},{LedgeManifest,"Ledges"},{RoutedManifest,"Routed"..RoutedManifest.AssetId}}) do
		local manifest,version=entry[1],entry[2]
		local original=prepareLibrary(manifest,version)
		for name in pairs(manifest.Props) do
			assert(not library:FindFirstChild(name),"Duplicate ascent prop: "..name)
			original[name]:Clone().Parent=library
		end
	end
	library.Parent=ServerStorage
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

function Props.PlaceSized(parent: Instance, kind: string, size: Vector3, center: CFrame, color: Color3?): Model
	local model = Props.Place(parent,kind,CFrame.identity,10)
	local reference = model:FindFirstChildWhichIsA("BasePart",true) :: BasePart
	local basis = reference.CFrame.Rotation:Inverse()
	-- Imported models can retain a shared yaw; normalize it before scaling their local axes.
	for _,mesh in ipairs(model:GetDescendants()) do
		if mesh:IsA("BasePart") then mesh.CFrame = basis*mesh.CFrame end
	end
	local bounds,original = model:GetBoundingBox()
	local scale = size/original
	for _,mesh in ipairs(model:GetDescendants()) do
		if mesh:IsA("BasePart") then
			local relative = bounds:ToObjectSpace(mesh.CFrame)
			mesh.Size *= scale
			mesh.CFrame = center*CFrame.new(relative.Position*scale)*relative.Rotation
			if color then mesh.Color=color end
		end
	end
	model.WorldPivot=center
	return model
end

function Props.UseCollision(mesh: MeshPart, fidelity: Enum.CollisionFidelity)
	if mesh.CollisionFidelity == fidelity then return end
	local cacheName = "Ascent" .. fidelity.Name .. "MeshLibrary"
	local cache = ServerStorage:FindFirstChild(cacheName)
	if not cache then
		cache = Instance.new("Folder")
		cache.Name, cache.Parent = cacheName, ServerStorage
	end
	local name = mesh.MeshId:match("%d+") :: string
	local data = cache:FindFirstChild(name)
	if not data then
		data = AssetService:CreateMeshPartAsync(Content.fromUri(mesh.MeshId), {
			CollisionFidelity = fidelity,
			RenderFidelity = Enum.RenderFidelity.Automatic,
		})
		data.Name, data.Parent = name, cache
	end
	local texture = mesh.TextureID
	-- Collision fidelity needs regenerated mesh data; assigning the property is ineffective.
	mesh:ApplyMesh(data)
	mesh.TextureID = texture
	assert(mesh.CollisionFidelity == fidelity, "Mesh collision data was not regenerated")
end

function Props.OptimizeScenery(model: Model)
	for _, mesh in ipairs(model:GetDescendants()) do
		if not mesh:IsA("MeshPart") or mesh.CanCollide or mesh.CanTouch or mesh.CanQuery then continue end
		Props.UseCollision(mesh, Enum.CollisionFidelity.Box)
	end
	model:SetAttribute("SceneryCollisionRevision", 1)
end

return Props
