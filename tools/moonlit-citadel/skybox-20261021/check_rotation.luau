local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local globals = {Color3=roblox.Color3, Vector3=roblox.Vector3}
local checks = {}
local function check(value, label)
	assert(value, label)
	table.insert(checks, label)
end
local function copy(values)
	return table.clone(values)
end
local function signal()
	return {Connect=function() return {Disconnect=function() end} end}
end
local function object(class, values)
	local children, properties = {}, copy(values or {})
	local methods = {}
	function methods:IsA(name) return class == name end
	function methods:GetChildren() return table.clone(children) end
	function methods:GetDescendants() return {} end
	function methods:FindFirstChild(name)
		for _, child in children do if child.Name == name then return child end end
		return nil
	end
	function methods:FindFirstChildOfClass(name)
		for _, child in children do if child:IsA(name) then return child end end
		return nil
	end
	function methods:Destroy() self.Parent = nil end
	return setmetatable({_children=children}, {
		__index=function(_, key) return methods[key] or properties[key] end,
		__newindex=function(self, key, value)
			if key == "Parent" then
				local previous = properties.Parent
				if previous then table.remove(previous._children, assert(table.find(previous._children, self))) end
				if value then table.insert(value._children, self) end
			end
			properties[key] = value
		end,
	})
end
local modules = {}
for _, name in {"ClassicAscent", "CityRun", "Shipwreck", "StudGarden", "MoonlitCitadel"} do
	local key = name .. "AmbienceConfig"
	modules[key] = luau.load(fs.readFile("src/ReplicatedStorage/Config/" .. key .. ".luau"), {environment=globals})()
end
modules.RaceConfig = {}
local moonlit, garden = modules.MoonlitCitadelAmbienceConfig, modules.StudGardenAmbienceConfig
local originalLighting = copy(moonlit.Lighting)
originalLighting.ClockTime, originalLighting.Brightness = 14.5, 2
local originalSky = copy(moonlit.Sky)
for key in originalSky do if key:sub(1,6)=="Skybox" and key~="SkyboxOrientation" then originalSky[key]="baseline-"..key end end
originalSky.SkyboxOrientation = roblox.Vector3.new(3, 27, 1)
originalSky.StarCount = 75
local originalAtmosphere = copy(moonlit.Atmosphere)
originalAtmosphere.Density, originalAtmosphere.Haze = 0, 0
local originalBloom = {Enabled=true,Intensity=1,Size=24,Threshold=2}
local originalRays = {Enabled=true,Intensity=.01,Spread=.1}
local lighting = object("Lighting", originalLighting)
for _, row in {{"Sky",originalSky},{"Atmosphere",originalAtmosphere},{"BloomEffect",originalBloom},{"SunRaysEffect",originalRays}} do
	local item = object(row[1],row[2]); item.Parent=lighting
end
local owner
local player = {GetAttribute=function(_, key) return if key=="KCArchiveLightingOwner" then owner else nil end}
local workspace = object("Workspace")
workspace.DescendantAdded = signal()
local configFolder = {}
for key in modules do configFolder[key]=key end
local services = {Lighting=lighting,Players={LocalPlayer=player},RunService={},
	ReplicatedStorage={Config=configFolder,Shared={MoonlitCitadelAmbienceGate="gate"}}}
local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau")
local boundary = assert(source:find("\nlocal elapsed = 0",1,true))
local rotation = assert(source:match("local heartbeatConnection = RunService%.Heartbeat:Connect%(function%(delta%)\n(.-)\n\telapsed %+="))
local fixture = source:sub(1,boundary-1) .. "\nreturn {SetActive=setActive, Advance=function(delta)\n" .. rotation .. "\nend}"
local controller = luau.load(fixture,{environment={
	game={GetService=function(_,name) return assert(services[name],name) end},
	workspace=workspace,Instance={new=function(class) return object(class) end},
	require=function(key) return if key=="gate" then {} else assert(modules[key],key) end,
	Vector3=roblox.Vector3,
}})()
local sky = assert(lighting:FindFirstChildOfClass("Sky"))
local function verify(instance, expected, label)
	for key, value in expected do assert(instance[key]==value,label.."."..key) end
end
local function restored(label)
	verify(lighting,originalLighting,label)
	verify(sky,originalSky,label.." sky")
	verify(lighting:FindFirstChildOfClass("Atmosphere"),originalAtmosphere,label.." atmosphere")
	verify(lighting:FindFirstChildOfClass("BloomEffect"),originalBloom,label.." bloom")
	verify(lighting:FindFirstChildOfClass("SunRaysEffect"),originalRays,label.." rays")
	check(not lighting:FindFirstChildOfClass("ColorCorrectionEffect").Enabled,label.." correction disabled")
	check(true,label.." all baseline fields restored")
end
controller.SetActive(moonlit)
verify(sky,moonlit.Sky,"active Moonlit")
verify(lighting,moonlit.Lighting,"active Moonlit lighting")
for _=1,120 do controller.Advance(1/60) end
check(math.abs(sky.SkyboxOrientation.Y-.4)<.000001,"Actual controller rotates 0.4 degrees over 120 frames at 60Hz")
check(sky.SkyboxOrientation.X==0 and sky.SkyboxOrientation.Z==0,"Rotation stays level")
check(lighting.ClockTime==19.2 and sky.MoonTextureId==moonlit.Sky.MoonTextureId,"Rotation keeps clock and moon configuration fixed")
sky.SkyboxOrientation=roblox.Vector3.new(0,359.99,0)
controller.Advance(.1)
check(math.abs(sky.SkyboxOrientation.Y-.01)<.0001,"Yaw wraps cleanly at 360 degrees within Vector3 precision")
owner="archive-fixture"
local paused=sky.SkyboxOrientation
controller.Advance(1)
check(sky.SkyboxOrientation==paused,"Rotation yields to the existing archive lighting owner")
owner=nil
controller.SetActive(garden)
verify(sky,garden.Sky,"Stud Garden")
local gardenOrientation=sky.SkyboxOrientation
controller.Advance(10)
check(sky.SkyboxOrientation==gardenOrientation,"Other course profile does not rotate")
controller.SetActive(nil)
restored("Moonlit through Stud Garden to lobby")
controller.Advance(10)
check(sky.SkyboxOrientation==originalSky.SkyboxOrientation,"Rotation remains stopped in lobby")
controller.SetActive(moonlit)
controller.Advance(2)
controller.SetActive(nil)
restored("Direct Moonlit exit")
controller.SetActive(moonlit)
check(sky.SkyboxOrientation==roblox.Vector3.zero,"Reactivation starts level at the configured orientation")
controller.Advance(1)
check(math.abs(sky.SkyboxOrientation.Y-.2)<.000001,"Reactivation resumes configured rotation")
controller.SetActive(nil)
restored("Final cleanup")
luau.load(fs.readFile("tools/moonlit-citadel/skybox-20261021/NativeChecks.client.luau"))
local report = {passed=true,checks=checks,
	scope="Actual source apply/rotate/restore functions executed with mock services. Excludes native scheduling, course gating, respawn, rendering, image delivery and visual quality."}
fs.writeFile("docs/artifacts/moonlit-citadel/skybox-20261021/offline-rotation-checks.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
