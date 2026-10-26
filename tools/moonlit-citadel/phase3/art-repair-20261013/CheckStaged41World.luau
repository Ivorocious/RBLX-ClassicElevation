local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local source = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local draft = "docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/source41/final/"
local config = luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"), {environment = {Vector3 = roblox.Vector3}})()
local parent = {}
local function load(name, directory)
	return luau.load(fs.readFile((directory or source) .. name .. ".luau"), {environment = {
		Vector3 = roblox.Vector3, CFrame = roblox.CFrame, Color3 = roblox.Color3,
		script = {Parent = parent}, game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = config}}},
		require = function(value) return value end,
	}})()
end
for _, name in {"RouteHazardGoals", "SupportingObstacles", "RouteHazardLayout", "ExpertRoutes"} do parent[name] = load(name) end
local layout = load("Layout")
parent.BaselineWorldPlan, parent.AssetGeometry = load("BaselineWorldPlan"), load("AssetGeometry")
local world = luau.load(fs.readFile("tools/moonlit-citadel/phase3/art-repair-20261013/WorldPlan41.luau"), {environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,script={Parent=parent},require=function(value)return value end}})()
local clearance = load("ArchitectureClearance", "tools/moonlit-citadel/phase3/art-repair-20261013/drafts/protection/")
local function encode(value)
	if typeof(value) == "Vector3" then return {value.X, value.Y, value.Z} end
	if typeof(value) == "CFrame" then return {value:GetComponents()} end
	if type(value) ~= "table" then return value end
	local result = {}; for key, item in value do if type(item) ~= "function" then result[key] = encode(item) end end
	return result
end
local reports = {}
for _, representative in {true, false} do
	local plan, counts = world.Get(layout, {representative = representative, config = config, clearance = clearance})
	assert(#counts.clearance.blocking == 0 and #counts.clearance.headroom == 0, "Architecture intersects accepted movement space")
	assert(#counts.clearance.camera == 0 and #counts.clearance.visibility == 0, "Architecture obscures an accepted camera or landing view")
	assert(#counts.clearance.invalidContactFlags == 0, "Architecture flags must remain inert")
	assert(counts.fullMapPending == representative, "Complete-map continuation must be included outside representative mode")
	counts.proposalRows = nil
	reports[if representative then "representative" else "complete"] = counts
	fs.writeFile(draft .. (if representative then "representative-plan.json" else "complete-plan.json"), serde.encode("json", encode(plan)))
end
fs.writeFile(draft .. "check-report.json", serde.encode("json", encode(reports)))
for stage, report in reports do
	print(stage, report.units, report.meshParts, report.triangles, "blocking", #report.clearance.blocking,
		"headroom", #report.clearance.headroom, "camera", #report.clearance.camera, "visibility", #report.clearance.visibility)
end
