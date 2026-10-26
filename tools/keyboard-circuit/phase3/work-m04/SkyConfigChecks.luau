local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local folder = roblox.Instance.new("Folder")
local prefix = "tools/keyboard-circuit/phase3/work-m04/sources/"
local count = 0
for _, name in fs.readDir(prefix) do
 if name:sub(-5) ~= ".luau" then continue end
 local source = fs.readFile(prefix .. name)
 luau.load(source, {debugName = name}); count += 1
 local item = roblox.Instance.new("ModuleScript")
 item.Name, item.Source, item.Parent = name:gsub("%.client%.luau$", ""):gsub("%.server%.luau$", ""):gsub("%.luau$", ""), source, folder
end
local cache = {}
local function loadModule(item)
 if cache[item] then return cache[item] end
 local env = {script = item, require = loadModule, game = {GetService = function() return {} end}}
 for key, value in roblox do env[key] = value end
 cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
 return cache[item]
end
local config = loadModule(folder.ArchiveSkyConfig)
local effects = loadModule(folder.ArchiveEffects)
local real = effects.ValidateSkyConfig(config)
assert(config.Ready == true and real.valid and #real.assets == 6)
local uploads = serde.decode("json", fs.readFile("assets/sky/keyboard-archive/upload-status.json"))
local names = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
for _, name in names do assert(real.textureIds[name] == uploads.faces[name].assetId, name .. " upload mapping mismatch") end
assert(real.profile.SkyboxOrientation == roblox.Vector3.zero)
assert(real.profile.CelestialBodiesShown == false and real.profile.StarCount == 0 and real.profile.SunAngularSize == 0 and real.profile.MoonAngularSize == 0)
local pendingConfig = {Ready=false,Sky=config.Sky}
assert(not effects.ValidateSkyConfig(pendingConfig).valid)
local missing = effects.ValidateSkyConfig({Ready=true,Sky={SkyboxOrientation=roblox.Vector3.zero}})
assert(not missing.valid and missing.reason:find("missing or invalid", 1, true))
local duplicateConfig = {Ready=true,Sky=table.clone(config.Sky)}
duplicateConfig.Sky.SkyboxUp = duplicateConfig.Sky.SkyboxDn
local duplicate = effects.ValidateSkyConfig(duplicateConfig)
assert(not duplicate.valid and duplicate.reason:find("duplicate",1,true))
local result = {compiled=count,configReady=config.Ready,actualAssetIdsConfigured=true,uploadedMappingMatches=true,
missingRejected=true,duplicateRejected=true,skyboxOrientation={0,0,0},celestialBodiesOff=true,actualAssetsLoaded=false,
archiveEffectsSha256=serde.hash("sha256",fs.readFile(prefix.."ArchiveEffects.luau")),
skyConfigSha256=serde.hash("sha256",fs.readFile(prefix.."ArchiveSkyConfig.luau")),
m03EffectsUnchanged=serde.hash("sha256",fs.readFile("tools/keyboard-circuit/phase3/work-m03/sources/ArchiveEffects.luau"))=="7ed4de2c993fc249358e07cd07e09f00d2c7cd058512a6778379a3f8e0cad288",
previewMatchesCurrentM03=fs.readFile(prefix.."KeyboardCircuitPhase2Preview.client.luau")==fs.readFile("tools/keyboard-circuit/phase3/work-m03/sources/KeyboardCircuitPhase2Preview.client.luau")}
assert(result.m03EffectsUnchanged and result.previewMatchesCurrentM03)
print(serde.encode("json", result))
