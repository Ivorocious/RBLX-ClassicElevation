--!strict

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local Vector3 = roblox.Vector3
local assertions = 0

local function check(condition: boolean, message: string)
	assert(condition, message)
	assertions += 1
end

local function load(path: string, environment: any): any
	local fn = luau.load(fs.readFile(path), {debugName = path})
	setfenv(fn, setmetatable(environment, {__index = getfenv()}))
	return fn()
end

local config = load("src/ReplicatedStorage/Config/StudGardenConfig.luau", {Vector3 = Vector3})
local Layout = load("src/ServerStorage/CourseBuilders/StudGarden/Layout.luau", {Vector3 = Vector3})
local layout = Layout.Get()
check(layout.revision == "SG_LAYOUT_04", "Use the current opening turns, incoming jump gap and recovery pockets")
local tokens = {config = {}, layout = {}, course = {}}
local modules = {[tokens.config] = config, [tokens.layout] = Layout, [tokens.course] = {}}
local gameFixture: any = {
	ReplicatedStorage = {Config = {StudGardenConfig = tokens.config}},
	ServerStorage = {CourseBuilders = {StudGarden = {Layout = tokens.layout}}},
	ServerScriptService = {Services = {CourseService = tokens.course}},
}
function gameFixture:GetService(): any return {} end

local sourcePath = "tools/stud-garden/CrowdStudy.luau"
local source = fs.readFile(sourcePath)
luau.load(source, {debugName = sourcePath})
source = string.gsub(source, "return Study%s*$",
	"Study._PlanCheck = plan\nStudy._TargetCheck = targetPosition\nStudy._EdgeCheck = edgePlan\nStudy._CommandCheck = edgeCommand\nStudy._SupportCheck = nativeSupport\nStudy._LimitsCheck = durationLimits\nStudy._IdentityCheck = matchesActiveCourse\nreturn Study")
local fn = luau.load(source, {debugName = "CrowdStudy offline private function inspection"})
setfenv(fn, setmetatable({game = gameFixture, Vector3 = Vector3, Enum = {Material = {Air = "Air"}},
	require = function(token: any): any return modules[token] end}, {__index = getfenv()}))
local study = fn()
local traversal = load("tools/stud-garden/TraversalStudy.luau", {game = gameFixture, Vector3 = Vector3})

local function inside(point: Vector3, floor: any, inset: number): boolean
	local relative = point - floor.position
	return math.abs(relative.X) <= floor.size.X / 2 - inset + 1e-5
		and math.abs(relative.Z) <= floor.size.Z / 2 - inset + 1e-5
		and math.abs(relative.Y) < 1e-5
end

local function close(a: Vector3, b: Vector3): boolean
	return (a - b).Magnitude < 1e-4
end

local function courseFixture(name: string, overrides: any?): any
	local attributes: any = {RuntimeActiveCourse = true, SourceCourseId = config.CourseId,
		CourseId = config.CourseId, StudGardenBuild = config.BuildId, LayoutRevision = layout.revision}
	for key, value in overrides or {} do attributes[key] = value end
	return {Name = name, GetAttribute = function(_self: any, key: string): any return attributes[key] end}
end
local active = courseFixture("RaceCourse")
check(study._IdentityCheck(active, active, config.CourseId, layout.revision), "Native RaceCourse clone is valid")
active.Name = "OwnerRenamedActiveCourse"
check(study._IdentityCheck(active, active, config.CourseId, layout.revision), "Active model identity does not depend on its name")
check(not study._IdentityCheck(courseFixture(config.ModelName), active, config.CourseId, layout.revision), "Matching template attributes do not replace active object identity")
check(not study._IdentityCheck(nil, nil, config.CourseId, layout.revision), "No active course is invalid")
check(not study._IdentityCheck(active, active, "another_course", layout.revision), "Active source service identity must match")
for key, value in {RuntimeActiveCourse = false, SourceCourseId = "another_course", CourseId = "another_course",
	StudGardenBuild = "SG_WRONG_BUILD", LayoutRevision = "SG_LAYOUT_01"} do
	local wrong = courseFixture("RaceCourse", {[key] = value})
	check(not study._IdentityCheck(wrong, wrong, config.CourseId, layout.revision), "Reject wrong native " .. key)
end
local expected = {
	Start20 = {count = 20, duration = 32, invocation = 35},
	H01_Clear = {count = 6, duration = 6.2, invocation = 20},
	H02_Clear = {count = 6, duration = 6.2, invocation = 20},
	K1_Merge = {count = 4, duration = 12, invocation = 20},
	K2_Merge = {count = 4, duration = 12, invocation = 20},
	R1_Returns = {count = 8, duration = 12, invocation = 20},
	R2_Returns = {count = 8, duration = 12, invocation = 20},
	R3_Returns = {count = 8, duration = 12, invocation = 20},
	R4_Returns = {count = 8, duration = 12, invocation = 20},
}
local report: any = {status = "passed", buildId = config.BuildId, layoutRevision = layout.revision,
	controllerRevision = "SG_CROWD_02",
	scope = "Offline syntax, native support/jump transitions, active identity, timings, start/landing/end bounds and traversal-planner agreement; not physical crowd proof.",
	nativeActiveNameChecked = "RaceCourse", cases = {}}
for _, id in study.Cases() do
	local description = study._PlanCheck(id, layout)
	local requirement = expected[id]
	check(#description.actors == requirement.count, id .. " fixture count")
	check(description.maximumDuration == requirement.duration, id .. " exact setup/movement maximum")
	local duration, invocation = study._LimitsCheck(id, description.maximumDuration, nil)
	check(duration == requirement.duration and invocation == requirement.invocation, id .. " default and total limit")
	check(study._LimitsCheck(id, description.maximumDuration, 100) == requirement.duration, id .. " excessive request clamps")
	check(study._LimitsCheck(id, description.maximumDuration, 0) == 1, id .. " nonpositive request clamps")
	check(study._LimitsCheck(id, description.maximumDuration, 2) == 2, id .. " shorter requested window is retained")
	check(invocation - duration >= 3, id .. " total limit reserves cleanup time")
	for _, actor in description.actors do
		check(inside(actor.source.position + actor.offset, actor.source, 1), id .. " starting footprint")
		check(inside(actor.endPosition, actor.path[#actor.path], 1.9), id .. " supported separate end slot")
		for index, point in actor.path do
			local target = study._TargetCheck(actor, index)
			check(inside(target, point, 1.9), id .. " target footprint")
			local edge = study._EdgeCheck(actor, index)
			local takeoffInset, landingInset = if edge.expert then 0.2 else 0.5, if edge.expert then 0.35 else 0.6
			check(inside(edge.takeoff, edge.source, takeoffInset), id .. " exact native takeoff bounds")
			check(inside(edge.landing, point, landingInset), id .. " exact native landing bounds")
			local takeoffRelative, landingRelative = edge.takeoff - edge.source.position, edge.landing - point.position
			check(math.abs(math.min(edge.source.size.X / 2 - math.abs(takeoffRelative.X),
				edge.source.size.Z / 2 - math.abs(takeoffRelative.Z)) - takeoffInset) < 1e-4, id .. " takeoff uses verified edge inset")
			check(math.abs(math.min(point.size.X / 2 - math.abs(landingRelative.X),
				point.size.Z / 2 - math.abs(landingRelative.Z)) - landingInset) < 1e-4, id .. " landing uses verified edge inset")
			check(edge.jump == (edge.gap > 0.75 or edge.rise > 0.6), id .. " traversal jump threshold")
			local centerActor = {source = edge.source, path = {point}, offset = Vector3.zero,
				lane = 0, endPosition = point.position}
			local center = study._EdgeCheck(centerActor, 1)
			local reference = traversal.PlanEdge(edge.source, point)
			check(close(center.takeoff, reference.takeoff) and close(center.landing, reference.landing)
				and math.abs(center.gap - reference.gap) < 1e-4 and center.jump == reference.jump,
				id .. " agrees with passing TraversalStudy for centered travel")
		end
	end
	for index, actor in description.actors do
		for otherIndex = index + 1, #description.actors do
			local other = description.actors[otherIndex]
			check((actor.source.position + actor.offset - other.source.position - other.offset).Magnitude >= 3 - 1e-5,
				id .. " initial placements do not share a body center")
			check((actor.endPosition - other.endPosition).Magnitude >= 3 - 1e-5, id .. " separate end slots")
		end
	end
	if description.mergeId ~= nil then
		local leader, follower = description.actors[3], description.actors[4]
		check(leader.source ~= follower.source and leader.offset == Vector3.zero and follower.offset == Vector3.zero,
			id .. " expert arrivals start single-file on different caps")
		check(follower.path[1] == leader.source and follower.path[2].id == description.mergeId,
			id .. " follower traverses its last expert cap before the merge")
	end
	table.insert(report.cases, {id = id, actors = #description.actors,
		maximumDuration = description.maximumDuration, invocationLimit = invocation})
end

local startPlan = study._PlanCheck("Start20", layout)
local edge = study._EdgeCheck(startPlan.actors[1], 1)
local motion: any = {phase = "approach"}
local destination, jump, requested = study._CommandCheck(motion, edge, edge.takeoff - edge.direction * 3, true, false, false, 0)
check(destination == edge.takeoff and not jump and not requested and motion.phase == "approach", "No jump three studs before takeoff")
destination, jump, requested = study._CommandCheck(motion, edge, edge.takeoff, false, false, false, 0.1)
check(destination == nil and not jump and not requested and motion.phase == "approach", "Takeoff waits for the exact native floor")
destination, jump, requested = study._CommandCheck(motion, edge, edge.takeoff, true, false, false, 0.2)
check(destination == edge.landing and jump and requested and motion.phase == "flight", "One supported edge takeoff is requested")
destination, jump, requested = study._CommandCheck(motion, edge, edge.takeoff, true, false, false, 0.3)
check(jump and not requested, "Holding the first jump does not create a second takeoff request")
destination, jump, requested = study._CommandCheck(motion, edge, edge.takeoff + edge.direction, false, false, true, 0.4)
check(not jump and not requested and motion.airborne, "Jump releases after airborne")
destination, jump, requested = study._CommandCheck(motion, edge, edge.landing, false, true, false, 0.7)
check(not jump and not requested and motion.phase == "center", "Landing stays released while clearing the entry")
destination, jump, requested = study._CommandCheck(motion, edge, edge.targetPosition, false, true, false, 0.8)
check(destination == nil and not jump and not requested and motion.phase == "arrived", "Supported anchor arrival completes the edge")
destination, jump, requested = study._CommandCheck(motion, edge, edge.targetPosition, false, true, false, 0.9)
check(not jump and not requested and motion.phase == "arrived", "No repeated jump from an arrived floor")

local missed: any = {phase = "flight", began = 0, airborne = false}
destination, jump = study._CommandCheck(missed, edge, edge.takeoff, true, false, false, 0.46)
check(destination == nil and not jump and missed.issue == "takeoff_not_airborne", "Blocked takeoff is bounded and releases Jump")
local expired: any = {phase = "flight", began = 0, airborne = true}
destination, jump = study._CommandCheck(expired, edge, edge.landing, false, false, true, 2.51)
check(destination == nil and not jump and expired.issue == "flight_deadline", "Unlanded flight is bounded and releases Jump")
local walking: any = {phase = "walk"}
destination, jump = study._CommandCheck(walking, edge, edge.takeoff, false, false, false, 0)
check(destination == nil and not jump, "Walking waits when native support is absent")
destination, jump = study._CommandCheck(walking, edge, edge.takeoff, true, false, false, 0.1)
check(destination == edge.targetPosition and not jump, "Supported walking does not jump")

local floorToken = {}
local supportActor = {root = {Position = Vector3.new(0, 3, 0)}, humanoid = {FloorMaterial = "Concrete"}, lift = 3}
local hit = {Instance = floorToken, Position = Vector3.zero}
check(study._SupportCheck(supportActor, hit, floorToken), "Matching native floor at normal standing height supports takeoff")
check(not study._SupportCheck(supportActor, hit, {}), "Another floor cannot confirm native takeoff")
check(not study._SupportCheck(supportActor, nil, floorToken), "No ray hit cannot confirm native takeoff")
supportActor.humanoid.FloorMaterial = "Air"
check(not study._SupportCheck(supportActor, hit, floorToken), "Airborne humanoid cannot confirm supported takeoff")
supportActor.humanoid.FloorMaterial = "Concrete"
supportActor.root.Position = Vector3.new(0, 6, 0)
check(not study._SupportCheck(supportActor, hit, floorToken), "Standing on another actor above a floor is not native floor support")
for index = 1, 4 do
	local checkpoint = layout.nodeById["R" .. index]
	check(checkpoint.spawnSize.X == 18, "R" .. index .. " recovery pocket uses its widened short dimension")
end
check(not pcall(study._PlanCheck, "unrelated_course", layout), "Reject unknown case")
report.assertions = assertions
fs.writeFile("docs/artifacts/stud-garden/first-pass/crowd-study-plan-checks.json", serde.encode("json", report, true) .. "\n")
print(serde.encode("json", report))
