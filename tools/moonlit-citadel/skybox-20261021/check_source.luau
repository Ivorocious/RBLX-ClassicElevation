local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local folder = "docs/artifacts/moonlit-citadel/skybox-20261021/"
local configPath = "src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau"
local environmentPath = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/EnvironmentPlan.luau"
local controllerPath = "src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau"
local globals = {Vector3=roblox.Vector3, Color3=roblox.Color3}
local checks = {}
local function check(value, label)
	assert(value, label)
	table.insert(checks, label)
end
local function equal(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in a do if not equal(value, b[key]) then return false end end
	for key in b do if a[key] == nil then return false end end
	return true
end
local function loadConfig(text)
	return luau.load(text, {environment=globals})()
end
local function splitProfile(text)
	local first = assert(text:find("Environment.Profile = table.freeze(", 1, true))
	local last = assert(text:find("\n})", first, true)) + 2
	return text:sub(first, last), text:sub(1, first-1) .. text:sub(last+1)
end
for _, path in {configPath, environmentPath, controllerPath} do
	luau.load(fs.readFile(path), {debugName=path})
end
check(true, "Three production sources compile")
local config = loadConfig(fs.readFile(configPath))
local old = loadConfig(fs.readFile(folder .. "source-before-implementation/" .. configPath))
local profile, rest = splitProfile(fs.readFile(environmentPath))
local _, oldRest = splitProfile(fs.readFile(folder .. "source-before-implementation/" .. environmentPath))
check(rest == oldRest, "Authoring geometry and all code outside Profile unchanged")
local authoring = loadConfig("return " .. profile:sub(#"Environment.Profile = " + 1))
check(equal(config, authoring), "Runtime and authoring profiles match completely")
for key, value in old do
	if key ~= "Sky" then check(equal(config[key], value), "Preserved profile " .. key) end
end
check(config.SkyRotationDegreesPerSecond == .2, "Rotation is 0.2 degrees/second, 30-minute turn")
check(config.Sky.SkyboxOrientation == roblox.Vector3.zero, "Sky starts level")
check(config.Sky.StarCount == 0, "Painted stars are not doubled")
for _, key in {"CelestialBodiesShown", "SunAngularSize", "MoonAngularSize", "MoonTextureId"} do
	check(config.Sky[key] == old.Sky[key], "Preserved " .. key)
end
local manifest = serde.decode("json", fs.readFile("assets/sky/moonlit-citadel-20261021/violet-veil-S04-C01/manifest.json"))
check(#manifest.faces == 6, "Exactly six sky faces")
for _, face in manifest.faces do
	local receipt = serde.decode("json", fs.readFile(face.receipt))
	check(receipt.state == "complete" and receipt.assetId == face.assetId, "Completed upload " .. face.property)
	check(config.Sky[face.property] == "rbxassetid://" .. face.assetId, "Profile uses receipt " .. face.property)
end
local report = {passed=true, checks=checks, compiled=3, scope="Source consistency and compile; native rendering and lifecycle checked separately."}
fs.writeFile(folder .. "source-checks.json", serde.encode("json", report, true) .. "\n")
print(serde.encode("json", report))
