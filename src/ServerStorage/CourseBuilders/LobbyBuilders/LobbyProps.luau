--!strict

local ServerStorage = game:GetService("ServerStorage")
local AssetStorage = require(script.Parent.Parent.AssetStorage)
local Props = {}
local ASSET_ID = 102619480125450
local DEFINITIONS = {
	TrophyCup = { height = 3.3, parts = { "TrophyCup__TrophyGold" } },
	FloatingCrystal = { height = 4, parts = { "FloatingCrystal__CrystalBlue" } },
	HangingBanner = { height = 7, parts = { "HangingBanner__BannerBlue", "HangingBanner__BannerGold" } },
}
local COLORS = {
	TrophyCup__TrophyGold = Color3.fromRGB(238,179,57),
	FloatingCrystal__CrystalBlue = Color3.fromRGB(85,205,246),
	HangingBanner__BannerBlue = Color3.fromRGB(27,117,161),
	HangingBanner__BannerGold = Color3.fromRGB(221,174,69),
}

function Props.Prepare(): Folder
	local existing = AssetStorage.Folder("AssetLibraries"):FindFirstChild("LobbyMeshLibrary")
	if existing then return existing :: Folder end
	local source = AssetStorage.Folder("AssetImports"):FindFirstChild("LobbyPropsImport")
	if not source then
		source = game:GetService("InsertService"):LoadAsset(ASSET_ID)
		source.Name, source.Parent = "LobbyPropsImport", AssetStorage.Folder("AssetImports")
	end
	local library = Instance.new("Folder")
	library.Name = "LobbyMeshLibrary"
	for kind, definition in pairs(DEFINITIONS) do
		local model = Instance.new("Model")
		model.Name = kind
		for _, name in ipairs(definition.parts) do
			local original = source:FindFirstChild(name, true)
			assert(original and original:IsA("MeshPart"), "Missing lobby mesh: " .. name)
			local mesh = original:Clone()
			mesh.Anchored, mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = true, false, false, false
			mesh.Color = COLORS[name]
			mesh.Material = if kind == "TrophyCup" then Enum.Material.Metal elseif kind == "HangingBanner" then Enum.Material.Fabric else Enum.Material.Glass
			mesh.Parent = model
		end
		-- Asset insertion may rotate the whole imported kit to the Studio camera.
		local firstMesh = model:FindFirstChildWhichIsA("MeshPart") :: MeshPart
		model:PivotTo(firstMesh.CFrame.Rotation:Inverse() * model:GetPivot())
		local _, size = model:GetBoundingBox()
		model:ScaleTo(model:GetScale() * definition.height / size.Y)
		local frame, scaled = model:GetBoundingBox()
		local bottom = frame.Position - Vector3.new(0, scaled.Y / 2, 0)
		model:PivotTo(model:GetPivot() - bottom)
		model.WorldPivot = CFrame.identity
		model:SetAttribute("NominalHeight", definition.height)
		model.Parent = library
	end
	library.Parent = AssetStorage.Folder("AssetLibraries")
	return library
end

function Props.Place(parent: Instance, kind: string, frame: CFrame, height: number, color: Color3?): Model
	local template = Props.Prepare():FindFirstChild(kind) :: Model
	assert(template, "Unknown lobby prop: " .. kind)
	local model = template:Clone()
	model:ScaleTo(model:GetScale() * height / model:GetAttribute("NominalHeight"))
	model:PivotTo(frame)
	if color then for _, part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.Color = color end end end
	model.Parent = parent
	return model
end

return Props
