--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local Probe = {}
local trace = {route = "RoughNormal", section = "NotStarted", steps = {}, complete = false}
local player, character, humanoid, body, root, rough, recoveryCount

local function position()
	return if body then {body.Position.X, body.Position.Y, body.Position.Z} else nil
end

local function progress()
	local encoded = root:GetAttribute("PreviewReport")
	if typeof(encoded) ~= "string" then return nil end
	local ok, report = pcall(HttpService.JSONDecode, HttpService, encoded)
	if not ok then return nil end
	for _, item in report.players or {} do if item.userId == player.UserId then return item end end
	return nil
end

local function guard()
	assert(player.Character == character and humanoid.Health > 0, "Character was replaced or died during continuous route")
	assert(root:GetAttribute("PreviewState") == "Running", "Preview fixture is not Running")
	local state = progress()
	assert(state and state.area == "RoughRoute", "Enter RoughRoute through the fixture before running RoughProbe.Normal()")
	assert(state.recoveries == recoveryCount, "Recovery interrupted continuous route at " .. trace.section)
end

local function contact()
	if humanoid.FloorMaterial == Enum.Material.Air then return nil end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character}
	params.RespectCanCollide = true
	local leg = character:FindFirstChild("Left Leg")
	local r6LegHeight = if humanoid.RigType == Enum.HumanoidRigType.R6 and leg then leg.Size.Y else 0
	local hit = workspace:Raycast(body.Position, Vector3.new(0, -(humanoid.HipHeight + r6LegHeight + body.Size.Y / 2 + 1.2), 0), params)
	if hit and hit.Normal.Y > 0.2 then return hit.Instance, hit.Position end
	return nil
end

local function record(name)
	local support, supportPoint = contact()
	table.insert(trace.steps, {name = name, section = trace.section, elapsed = os.clock() - trace.started,
		position = position(), ground = humanoid.FloorMaterial.Name, state = humanoid:GetState().Name,
		support = support and support:GetFullName(), supportPoint = supportPoint and {supportPoint.X, supportPoint.Y, supportPoint.Z}})
end

local function await(name, test, seconds)
	trace.waiting = name
	local deadline = os.clock() + seconds
	repeat
		guard()
		if test() then trace.waiting = nil; return end
		task.wait(0.025)
	until os.clock() >= deadline
	error("Timed out: " .. name .. " in " .. trace.section)
end

local function surface(instance)
	if instance:IsA("BasePart") then return instance end
	local part = instance.PrimaryPart or instance:FindFirstChild("Contact", true)
	assert(part and part:IsA("BasePart") and part.CanCollide, "Missing real walking contact: " .. instance:GetFullName())
	return part
end

local function topFrame(part)
	return part.CFrame * CFrame.new(0, part.Size.Y / 2, 0)
end

local function horizontalDistance(target)
	return Vector3.new(body.Position.X - target.X, 0, body.Position.Z - target.Z).Magnitude
end

local function groundedOn(expected)
	local hit, hitPosition = contact()
	if hit == expected then return true end
	if not hit or expected.Name == "Deck" or not hit:IsDescendantOf(rough) then return false end
	local role = hit:GetAttribute("Role")
	if role ~= "WalkableSurface" and role ~= "Walkable" and role ~= "SafeRefuge" then return false end
	-- Authored landings and terraces overlap lane ends; either real contact is valid there.
	local localPoint = expected.CFrame:PointToObjectSpace(hitPosition)
	if math.abs(localPoint.X) > expected.Size.X / 2 + 1.2 or math.abs(localPoint.Z) > expected.Size.Z / 2 + 1.2 then return false end
	local heightAboveTread = localPoint.Y - expected.Size.Y / 2
	if math.abs(heightAboveTread) < 0.65 then return true end
	local segment = expected.Name:match("^ArchTread_(%d+)_")
	if segment and hit.Parent == expected.Parent and hit.Name == "Landing_" .. segment
		and heightAboveTread >= 0 and heightAboveTread <= 2.5 then return true end
	if expected.Parent.Name == "E1_InnerDiagonal" and hit.Parent == rough.GalleryJoin
		and heightAboveTread >= 0 and heightAboveTread <= 1.3 then return true end
	local receiving = {
		OpeningClimb = {ArchRest = true},
		H1_NormalOuter = {ArchRest = true, GalleryEntrance = true},
		E1_InnerDiagonal = {ArchRest = true, GalleryEntrance = true},
		GalleryToLifts = {CP03Wait = true, LowerBoarding = true},
		CrownApproach = {CrownTerrace = true},
	}
	local allowed = receiving[expected.Parent.Name]
	return expected.Name:match("^ArchTread_%d+_%d+$") ~= nil and hit.Parent == rough
		and allowed ~= nil and allowed[hit.Name] == true and heightAboveTread >= 0 and heightAboveTread <= 2.5
end

local function move(target, expected, name, seconds)
	guard()
	target = Vector3.new(target.X, topFrame(expected).Position.Y, target.Z)
	trace.goal = {target.X, target.Y, target.Z}
	shared.MCGoal = target
	await("Reached " .. name, function() return horizontalDistance(target) < 1.2 end, seconds or 4)
	shared.MCGoal = nil
	humanoid:Move(Vector3.zero, false)
	await("Grounded " .. name, function() return groundedOn(expected) end, 1.5)
	record(name)
	trace.goal = nil
end

local function jump(target, expected, name)
	guard()
	target = Vector3.new(target.X, topFrame(expected).Position.Y, target.Z)
	assert(contact(), "Ungrounded takeoff: " .. name)
	record(name .. "Takeoff")
	trace.goal = {target.X, target.Y, target.Z}
	shared.MCGoal = target
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	humanoid.Jump = true
	await("Actual takeoff " .. name, function()
		return humanoid.FloorMaterial == Enum.Material.Air and body.AssemblyLinearVelocity.Y > 1
	end, 0.5)
	await("Reached jump goal " .. name, function() return horizontalDistance(target) < 1.2 end, 2.5)
	shared.MCGoal = nil
	humanoid.Jump = false
	humanoid:Move(Vector3.zero, false)
	await("Actual landing " .. name, function() return groundedOn(expected) end, 1.5)
	record(name .. "Landing")
	trace.goal = nil
end

local function checkpoint(index, floorPart)
	local cp
	for _, part in rough.Checkpoints:GetChildren() do if part:GetAttribute("CheckpointIndex") == index then cp = part; break end end
	assert(cp, "Missing rough checkpoint " .. index)
	move(cp.Position, floorPart, "CP" .. index)
	await("Saved CP" .. index, function() local state = progress(); return state and state.checkpoint == index end, 2)
end

local function treadList(lane)
	local result = {}
	for _, part in lane:GetChildren() do
		local segment, step = part.Name:match("^ArchTread_(%d+)_(%d+)$")
		if segment and part:IsA("BasePart") then table.insert(result, {part = part, segment = tonumber(segment), step = tonumber(step)}) end
	end
	table.sort(result, function(a, b) return a.segment < b.segment or (a.segment == b.segment and a.step < b.step) end)
	assert(#result > 0, "Missing real lane treads: " .. lane.Name)
	return result
end

local function followLane(lane, jumpLandings)
	local treads = treadList(lane)
	for index, item in treads do
		if jumpLandings then jump(topFrame(item.part).Position, item.part, lane.Name .. "/" .. item.part.Name)
		else move(topFrame(item.part).Position, item.part, lane.Name .. "/" .. item.part.Name) end
		local nextItem = treads[index + 1]
		if not nextItem or nextItem.segment ~= item.segment then
			local landing = surface(lane["Landing_" .. item.segment])
			if jumpLandings then
				local target = topFrame(landing).Position
				local incoming = Vector3.new(target.X - item.part.Position.X, 0, target.Z - item.part.Position.Z)
				-- Land on the entry of the rest pad before its outgoing stair rises.
				if incoming.Magnitude > 0.01 then target -= incoming.Unit * 1.8 end
				jump(target, landing, lane.Name .. "/Landing_" .. item.segment)
			else move(topFrame(landing).Position, landing, lane.Name .. "/Landing_" .. item.segment) end
		end
	end
end

local function confirmJoin(a, b, name)
	local flat = Vector3.new(b.Position.X - a.Position.X, 0, b.Position.Z - a.Position.Z)
	if flat.Magnitude < 0.001 then return end
	local direction = flat.Unit
	local function extent(part)
		return math.abs(part.CFrame.RightVector:Dot(direction)) * part.Size.X / 2
			+ math.abs(part.CFrame.LookVector:Dot(direction)) * part.Size.Z / 2
	end
	local gap = math.max(0, flat.Magnitude - extent(a) - extent(b))
	assert(gap <= 8.5, string.format("Missing continuous %s join: %.1f stud gap from %s to %s", name, gap, a:GetFullName(), b:GetFullName()))
end

local function lanternNormal()
	local gallery = rough.H2_ThreeBands
	local entrance = surface(gallery.EntranceWait)
	local frame = topFrame(entrance)
	local function point(x, z) return frame:PointToWorldSpace(Vector3.new(x, 0, z)) end
	local function away(band, left)
		local cage = gallery.SwingLanterns["SwingBand" .. band].PrimaryPart
		local previous = frame:PointToObjectSpace(cage.Position).X
		await("Lantern " .. band .. " away from Normal line", function()
			local x = frame:PointToObjectSpace(cage.Position).X
			local movingRight = x > previous
			previous = x
			return if left then x > 2 and movingRight else x < -2 and not movingRight
		end, Config.LanternCycleSeconds + 2)
	end
	trace.section = "H2_NormalLanterns"
	move(point(-8, -6), entrance, "LanternEntranceEdge")
	away(1, true)
	jump(point(-8, -14), surface(gallery.NormalCrossing1), "Band1Entry")
	move(point(-8, -24), surface(gallery.NormalCrossing1), "Band1Cross")
	jump(point(-8, -31), surface(gallery.NormalWait1), "Band1Wait")
	move(point(-3, -34.5), surface(gallery.NormalWait1), "Band2TransferTakeoff")
	jump(point(8, -35), surface(gallery.NormalCrossing2), "Band2Entry")
	away(2, false)
	move(point(8, -46), surface(gallery.NormalCrossing2), "Band2Cross")
	jump(point(8, -53), surface(gallery.NormalWait2), "Band2Wait")
	move(point(3, -56.5), surface(gallery.NormalWait2), "Band3TransferTakeoff")
	jump(point(-8, -57), surface(gallery.NormalCrossing3), "Band3Entry")
	away(3, true)
	move(point(-8, -68), surface(gallery.NormalCrossing3), "Band3Cross")
	jump(point(-8, -75), surface(gallery.NormalWait3), "Band3Wait")
	move(point(0, -80), surface(gallery.ExitWait), "LanternExit")
	return surface(gallery.ExitWait)
end

local function ride(stage, boarding, exit)
	trace.section = stage .. "Counterweight"
	local deck = rough.MovingCars[stage .. "_Bay1"].PrimaryPart
	local base = Config.RoughOrigin + Config.BlenderOffset
	local low = base.Y + (if stage == "Lower" then 72 else 106)
	local high = low + Config.LiftRise
	local waiting = Vector3.new(deck.Position.X, topFrame(boarding).Position.Y, deck.Position.Z + 11)
	move(waiting, boarding, stage .. "BoardingWait")
	await(stage .. " low parked boarding window", function()
		return math.abs(topFrame(deck).Position.Y - low) < 0.1 and math.abs(deck.AssemblyLinearVelocity.Y) < 0.1
	end, Config.LiftCycleSeconds + 3)
	jump(topFrame(deck).Position, deck, stage .. "Board")
	await(stage .. " high parked arrival", function()
		assert(contact() == deck, "Lost real deck support during " .. stage .. " ride")
		return topFrame(deck).Position.Y >= high - 0.1 and math.abs(deck.AssemblyLinearVelocity.Y) < 0.1
	end, Config.LiftCycleSeconds + 3)
	record(stage .. "RideTop")
	move(topFrame(deck):PointToWorldSpace(Vector3.new(0, 0, -4)), deck, stage .. "ExitTakeoff")
	local receiving = Vector3.new(deck.Position.X, topFrame(exit).Position.Y, exit.Position.Z + 4)
	jump(receiving, exit, stage .. "Exit")
end

local function lanternExpert()
	local gallery = rough.H2_ThreeBands
	local entrance = surface(gallery.EntranceWait)
	local frame = topFrame(entrance)
	local function point(x,z) return frame:PointToWorldSpace(Vector3.new(x,0,z)) end
	trace.section = "H2_CentralExpert"
	move(point(0,-6),entrance,"CentralEntrance")
	jump(point(0,-13),surface(gallery.ExpertIsland1_7),"CentralApproach1")
	for band=1,3 do
		local before=-13-(band-1)*22
		local after=before-14
		move(point(0,before-3.6),surface(gallery["ExpertIsland"..band.."_7"]),"CentralTakeoff"..band)
		local cage=gallery.SwingLanterns["SwingBand"..band].PrimaryPart
		local previous=frame:PointToObjectSpace(cage.Position).X
		await("Central lantern clear "..band,function()
			local x=frame:PointToObjectSpace(cage.Position).X
			local clear=math.abs(x)>6.5 and math.abs(x)>math.abs(previous)
			previous=x
			return clear
		end,Config.LanternCycleSeconds+2)
		jump(point(0,after+1.7),surface(gallery["ExpertIsland"..band.."_-7"]),"CentralGap"..band)
		if band<3 then
			move(point(0,after-2.8),surface(gallery["ExpertIsland"..band.."_-7"]),"CentralNextTakeoff"..band)
			jump(point(0,before-21),surface(gallery["ExpertIsland"..(band+1).."_7"]),"CentralApproach"..(band+1))
		end
	end
	jump(point(0,-80),surface(gallery.ExitWait),"CentralExit")
	return surface(gallery.ExitWait)
end

local function expertUpper(upper)
	trace.section="UpperExpert"
	local approach=upper.ExpertBraceApproach
	move(topFrame(surface(approach.BraceStep1)).Position,surface(approach.BraceStep1),"ExpertBrace1")
	for index=2,5 do
		jump(topFrame(surface(approach["BraceStep"..index])).Position,surface(approach["BraceStep"..index]),"ExpertBrace"..index)
	end
	local deck=rough.MovingCars.Upper_Bay2.PrimaryPart
	local low=(Config.RoughOrigin+Config.BlenderOffset).Y+106
	local previous=topFrame(deck).Position.Y
	await("Expert ascent board window",function()
		local height=topFrame(deck).Position.Y
		local rising=height>previous
		previous=height
		return height>low+9 and height<low+11 and rising
	end,Config.LiftCycleSeconds+3)
	jump(topFrame(deck).Position,deck,"ExpertUpperBoard")
	await("Expert early-exit height",function()
		assert(contact()==deck,"Lost actual Expert deck support")
		return topFrame(deck).Position.Y>low+26
	end,Config.LiftCycleSeconds+3)
	record("ExpertUpperRide")
	move(topFrame(deck):PointToWorldSpace(Vector3.new(0,0,4)),deck,"ExpertUpperExitTakeoff")
	jump(topFrame(surface(approach.EarlyExitContact)).Position,surface(approach.EarlyExitContact),"ExpertEarlyExit")
	followLane(approach.ExitRise)
	move(topFrame(surface(upper.SharedUpperExit)).Position,surface(upper.SharedUpperExit),"ExpertSharedMerge")
end

function Probe.Debug()
	return {route = trace.route, section = trace.section, goal = trace.goal, waiting = trace.waiting,
		position = position(), complete = trace.complete, failure = trace.failure, steps = trace.steps}
end

local function fallTo(target, shelf, name)
	shared.MCGoal = target
	await("Walked beyond " .. name, function() return horizontalDistance(target) < 1.2 end, 3)
	shared.MCGoal = nil
	humanoid:Move(Vector3.zero, false)
	await("Actual catch landing " .. name, function() return contact() == shelf end, 4)
	record(name .. "Landing")
end

local function archCatch()
	trace.section = "ArchCatchReturn"
	local origin = Config.RoughOrigin + Config.BlenderOffset
	move(origin + Vector3.new(-70,28,-18), surface(rough.ArchRest), "ArchCatchTakeoff")
	fallTo(origin + Vector3.new(-70,8,-13.5), surface(rough.ArchCatch), "ArchCatch")
	move(origin + Vector3.new(-104,8,-10), surface(rough.ArchCatch), "ArchCatchReturnEntry", 5)
	followLane(rough.ArchCatchReturn)
	move(rough.Start.Position, surface(rough.GateCourt), "ArchCatchReturnedStart")
	trace.section = "OpeningClimbAfterCatch"
	followLane(rough.OpeningClimb)
	checkpoint(1, surface(rough.ArchRest))
end

local function upperCatch(upper)
	trace.section = "UpperCatchReturn"
	local origin = Config.RoughOrigin + Config.BlenderOffset + Vector3.new(76,106,-34)
	move(origin + Vector3.new(-18,0,23), surface(upper.CP04_Wait), "UpperCatchTakeoff")
	fallTo(origin + Vector3.new(-18,-8,29.5), surface(upper.CatchShelf), "UpperCatch")
	move(origin + Vector3.new(-25,-8,24), surface(upper.CatchShelf), "UpperCatchReturnEntry")
	followLane(upper.CatchReturn)
	move(origin + Vector3.new(-18,0,21), surface(upper.CP04_Wait), "UpperCatchReturnedCP04")
end

local function run(archExpert, centralExpert, upperExpert, catches)
	assert(RunService:IsStudio() and RunService:IsClient(), "RoughProbe requires the real Studio client")
	assert(game.PlaceId == 0 and game.GameId == 0, "Use the isolated unpublished sample fixture")
	player = Players.LocalPlayer
	character = player.Character
	humanoid, body = character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
	root = workspace[Config.BlenderRootName]
	rough = root.RoughRoute
	assert(root:GetAttribute("CandidateId") == Config.BlenderCandidateId, "Candidate does not match current Config")
	assert(humanoid.WalkSpeed == 16 and humanoid.UseJumpPower == false and math.abs(humanoid.JumpHeight - 7.2) < 0.001, "Expected ordinary16-speed/7.2-height movement")
	assert(math.abs(workspace.Gravity - 196.2) < 0.001, "Unexpected gravity")
	assert(humanoid.MaxSlopeAngle == 89, "Expected the fixture's documented slope limit")
	local initial = progress()
	assert(initial and initial.area == "RoughRoute" and initial.checkpoint == 0 and not initial.finished, "Enter a fresh RoughRoute start before the continuous probe")
	recoveryCount = initial.recoveries
	trace = {route = if catches then "RoughNormalWithCatches" elseif archExpert and centralExpert and upperExpert then "RoughExpert" elseif archExpert or centralExpert or upperExpert then "RoughMixed" else "RoughNormal", section = "GateCourt", steps = {}, complete = false, started = os.clock()}
	local ok, reason = xpcall(function()
		local court = surface(rough.GateCourt)
		await("Initial GateCourt grounding", function() return contact() == court end, 3)
		move(rough.Start.Position, court, "Start")
		trace.section = "OpeningClimb"
		followLane(rough.OpeningClimb)
		checkpoint(1, surface(rough.ArchRest))
		if catches then archCatch() end
		trace.section = if archExpert then "E1_InnerDiagonal" else "H1_NormalOuter"
		if archExpert then move((Config.RoughOrigin + Config.BlenderOffset) + Vector3.new(-63,28,-23), surface(rough.ArchRest), "ExpertArchTakeoff") end
		followLane(if archExpert then rough.E1_InnerDiagonal else rough.H1_NormalOuter, archExpert)
		checkpoint(2, surface(rough.GalleryEntrance))
		trace.section = "GalleryJoin"
		followLane(rough.GalleryJoin)
		local galleryExit = if centralExpert then lanternExpert() else lanternNormal()
		trace.section = "GalleryToLifts"
		confirmJoin(galleryExit, treadList(rough.GalleryToLifts)[1].part, "lantern exit to lifts")
		followLane(rough.GalleryToLifts)
		checkpoint(3, surface(rough.CP03Wait))
		move(topFrame(surface(rough.LowerBoarding)).Position, surface(rough.LowerBoarding), "LowerApproach")
		ride("Lower", surface(rough.LowerBoarding), surface(rough.MidGallery))
		checkpoint(4, surface(rough.MidGallery))
		local upper = rough.UpperApproaches
		if catches then upperCatch(upper) end
		if upperExpert then expertUpper(upper)
		else ride("Upper", surface(upper.CP04_Wait), surface(upper.SharedUpperExit)) end
		trace.section = "CrownApproach"
		followLane(rough.CrownApproach)
		move(rough.Finish.Position, surface(rough.CrownTerrace), "CrownFinish")
		await("Legitimate local rough finish", function() local state = progress(); return state and state.checkpoint == 4 and state.finished end, 2)
		record("ContinuousRouteComplete")
		trace.complete = true
	end, debug.traceback)
	shared.MCGoal = nil
	humanoid.Jump = false
	humanoid:Move(Vector3.zero, false)
	if not ok then trace.failure = tostring(reason); record("Failed"); error(reason, 0) end
	return Probe.Debug()
end

function Probe.Normal() return run(false,false,false) end
function Probe.Expert() return run(true,true,true) end
function Probe.Mixed() return run(true,false,true) end
function Probe.NormalWithCatches() return run(false,false,false,true) end

return Probe
