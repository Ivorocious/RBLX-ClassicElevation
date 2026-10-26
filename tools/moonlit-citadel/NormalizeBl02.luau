assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local imported = game.ServerStorage.AssetImports.MoonlitCitadel_BL02Import
local destination = game.ServerStorage.CourseAssetKits
assert(not destination:FindFirstChild("MoonlitCitadel_BL02Library"), "Preserve the existing library")
local bindingModule = game.ServerStorage.CourseBuilders.MoonlitCitadel.AssetBindings:Clone()
bindingModule.Name, bindingModule.Parent = "Moonlit_BL02_BindingSnapshot", game.ServerStorage
local bindings = require(bindingModule)
local expected, meshCount, maxError = {}, 0, 0
for _, item in bindings do expected[item.name] = item end
for _, part in imported:GetDescendants() do
 assert(not part:IsA("LuaSourceContainer"), "Unexpected imported script")
 if not part:IsA("BasePart") then continue end
 assert(part:IsA("MeshPart") and expected[part.Name], "Unexpected mesh: " .. part.Name)
 meshCount += 1
 local difference = (part.Size - expected[part.Name].size).Magnitude
 assert(difference < .002, "Imported mesh scale mismatch: " .. part.Name)
 maxError = math.max(maxError, difference)
end
assert(meshCount == #bindings and meshCount==55, "Incomplete import")
local library = Instance.new("Model")
library.Name = "MoonlitCitadel_BL02Library"
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
 part.Material = if item.material == "Red" then Enum.Material.Neon
  elseif item.material == "Iron" or item.material == "Brass" or item.material == "Lead" then Enum.Material.Metal
  elseif item.material:find("Stone",1,true) or item.material == "Floor" then Enum.Material.Limestone
  elseif item.material:find("Slate",1,true) then Enum.Material.Slate
  elseif item.material:find("Amber",1,true) then Enum.Material.Glass
  else Enum.Material.SmoothPlastic
 part.Transparency = 0
 part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
 part.CastShadow = not item.asset:find("Tracery",1,true) and not item.asset:find("Ivy",1,true) and not item.material:find("Amber",1,true) and item.material ~= "Brass"
 part:SetAttribute("Role", "Decoration")
 part:SetAttribute("SourceMaterial", item.material)
 part:SetAttribute("SourceAsset", item.asset)
 part.Parent = model
end
library.WorldPivot = CFrame.identity
library:SetAttribute("CandidateId", "MC_P1_BL02")
library:SetAttribute("OpenCloudAssetId", "138009529483104")
library:SetAttribute("SourceFile", "assets/moonlit_citadel/bl02/MC_BL02_library.fbx")
library:SetAttribute("SourceSHA256", "f024757df1cdf28093bb155ae95a541e3845c1ff44b4c2d933b3126b5b301be9")
library:SetAttribute("ImportVerified", true)
library.Parent = destination
return game.HttpService:JSONEncode({parts=meshCount,units=#library:GetChildren(),maxImportedSizeError=maxError,assetId=library:GetAttribute("OpenCloudAssetId")})
