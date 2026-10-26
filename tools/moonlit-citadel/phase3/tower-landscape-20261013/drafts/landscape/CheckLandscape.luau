local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local base = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local own = "tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/landscape/"
local parent = {}
local config = luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"), {environment = {Vector3 = roblox.Vector3}})()
local function load(path)
	return luau.load(fs.readFile(path), {environment = {Vector3 = roblox.Vector3, CFrame = roblox.CFrame,
		Color3 = roblox.Color3, script = {Parent = parent}, game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = config}}},
		require = function(value) return value end}})()
end
for _, name in {"ExpertRoutes", "RouteHazardGoals", "SupportingObstacles", "RouteHazardLayout"} do parent[name] = load(base .. name .. ".luau") end
local layout, environment = load(base .. "Layout.luau"), load(own .. "EnvironmentPlan.luau")
local source43 = serde.decode("json", fs.readFile("docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/source43/final/check-report.json")).complete
for _, record in source43.plantingMounts do record.frame = roblox.CFrame.new(table.unpack(record.frame)) end
for _, record in source43.assemblies do record.frame = roblox.CFrame.new(table.unpack(record.frame)) end
local plan, counts = environment.Get(layout, source43.plantingMounts, source43.assemblies)
local clearance = load("tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/ArchitectureClearance.luau")
local checked = clearance.CheckParts(counts.proposalRows, clearance.Prepare(layout, config), nil)
assert(#checked.blocking == 0 and #checked.headroom == 0 and #checked.camera == 0 and #checked.visibility == 0)
local result = {plannedOnly = true, units = counts.units, meshParts = counts.meshParts, triangles = counts.triangles,
	treeCount = counts.ruralTreeCount, moundCount = 15, rows = #counts.proposalRows, blocking = #checked.blocking,
	headroom = #checked.headroom, camera = #checked.camera, visibility = #checked.visibility, nativeVisualVerified = false,
	broadIslandRoot = {low = {-367, -54.2, -332.8}, high = {337, -30.2, 332.8}}, canopyTops = {}}
for _, grove in counts.groves do table.insert(result.canopyTops, grove.canopyTop) end
fs.writeFile(own .. "focused-checks.json", serde.encode("json", result, true))
local placements = {}
for _, record in plan do table.insert(placements, {name = record.name, asset = record.asset,
	frame = {record.localCF:GetComponents()}, scale = {record.scale.X, record.scale.Y, record.scale.Z}}) end
fs.writeFile(own .. "placement-plan.json", serde.encode("json", placements, true))
print(serde.encode("json", result))
