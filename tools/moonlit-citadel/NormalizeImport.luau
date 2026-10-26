local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local imported = game.ServerStorage.AssetImports.MoonlitCitadel_BL01Import
local destination = game.ServerStorage.CourseAssetKits
assert(not destination:FindFirstChild("MoonlitCitadel_BL01Library"), "Preserve the existing library")
local bindings = require(game.ServerStorage.CourseBuilders.MoonlitCitadel.AssetBindings)
local expected, meshCount, maxError = {}, 0, 0
for _, item in bindings do expected[item.name] = item end
for _, part in imported:GetDescendants() do
	assert(not part:IsA("LuaSourceContainer"), "Unexpected imported script")
	if not part:IsA("BasePart") then continue end
	assert(part:IsA("MeshPart") and expected[part.Name], "Unexpected mesh: " .. part.Name)
	meshCount += 1
	local error = (part.Size - expected[part.Name].size).Magnitude
	assert(error < .002, "Imported mesh scale mismatch: " .. part.Name)
	maxError = math.max(maxError, error)
end
assert(meshCount == #bindings, "Incomplete import")
local library = Instance.new("Model")
library.Name, library.Parent = "MoonlitCitadel_BL01Library", destination
local count = 0
for _, item in bindings do
	local model = library:FindFirstChild(item.asset)
	if not model then
		model = Instance.new("Model")
		model.Name, model.Parent, model.WorldPivot = item.asset, library, CFrame.identity
		model:SetAttribute("MCEditUnit", item.asset)
	end
	local part = imported:FindFirstChild(item.name, true):Clone()
	part.CFrame, part.Size = CFrame.new(item.center), item.size
	part.Color = Color3.fromRGB(table.unpack(item.rgb))
	part.Material = if item.material == "Red" then Enum.Material.Neon elseif item.material == "Iron" or item.material == "Brass" then Enum.Material.Metal else Enum.Material.SmoothPlastic
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.CastShadow = not string.find(item.asset, "Tracery") and not string.find(item.asset, "Ivy") and item.material ~= "Amber" and item.material ~= "Brass"
	part:SetAttribute("Role", "Decoration")
	part:SetAttribute("SourceMaterial", item.material)
	part:SetAttribute("SourceAsset", item.asset)
	part.Parent = model
	count += 1
end
library.WorldPivot = CFrame.identity
library:SetAttribute("CandidateId", "MC_P1_BL01")
library:SetAttribute("OpenCloudAssetId", "107285993331110")
library:SetAttribute("SourceFile", "assets/moonlit_citadel/bl01/MC_BL01_library.fbx")
library:SetAttribute("SourceSHA256", "fb5346e7284001d1a0a854777b162993577c94ceda0d86b50e9378afe5caa30c")
library:SetAttribute("ImportVerified", true)
return game:GetService("HttpService"):JSONEncode({parts=count,units=#library:GetChildren(),maxImportedSizeError=maxError,assetId=library:GetAttribute("OpenCloudAssetId")})
