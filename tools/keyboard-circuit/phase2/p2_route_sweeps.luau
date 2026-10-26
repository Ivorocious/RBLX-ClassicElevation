local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local C, V = roblox.CFrame, roblox.Vector3
local env = {CFrame = C, Vector3 = V}
local Motion = luau.load(fs.readFile("tools/keyboard-circuit/phase2/staged/Motion.luau"), {environment = env})()
local fixture = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_mechanism_fixture.rbxm"))[1]
local units = {}
local function box(cf, size)
	return {cf = cf, half = size / 2, axes = {cf.XVector, cf.YVector, cf.ZVector}}
end
local function projection(body, axis)
	return math.abs(axis:Dot(body.axes[1])) * body.half.X + math.abs(axis:Dot(body.axes[2])) * body.half.Y + math.abs(axis:Dot(body.axes[3])) * body.half.Z
end
local function overlaps(a, b)
	local axes = {a.axes[1], a.axes[2], a.axes[3], b.axes[1], b.axes[2], b.axes[3]}
	for _,x in a.axes do for _,y in b.axes do table.insert(axes, x:Cross(y)) end end
	local difference = b.cf.Position - a.cf.Position
	for _,axis in axes do
		if axis.Magnitude < 1e-6 then continue end
		axis = axis.Unit
		if math.abs(difference:Dot(axis)) > projection(a, axis) + projection(b, axis) + .001 then return false end
	end
	return true
end
for _,unit in fixture:GetChildren() do
	local kind = unit:GetAttribute("MechanismKind")
	if not kind then continue end
	local frame = unit.PrimaryPart.CFrame * unit:GetAttribute("FrameFromPrimary")
	local record = {unit = unit, kind = kind, frame = frame, actors = {}, refuges = {}}
	for _,item in unit:GetDescendants() do
		if item:IsA("Model") and item:GetAttribute("KCMover") then
			local rest = item.PrimaryPart.CFrame * item.PrimaryPart.PivotOffset
			local actor = {model = item, index = item:GetAttribute("MotionIndex"), rest = rest, radius = 0, shapes = {}}
			for _,part in item:GetDescendants() do
				if part:IsA("BasePart") and part:GetAttribute("Role") == "Lethal" then
					actor.radius = math.max(actor.radius, (part.CFrame.Position - rest.Position).Magnitude + part.Size.Magnitude / 2)
					table.insert(actor.shapes, {localPose = rest:ToObjectSpace(part.CFrame), size = part.Size})
				end
			end
			if item:GetAttribute("MotionPivotLocal") then actor.pivot = frame * item:GetAttribute("MotionPivotLocal"); actor.localPose = actor.pivot:ToObjectSpace(rest) end
			table.insert(record.actors, actor)
		elseif item:IsA("Model") and item:GetAttribute("Role") == "SafeRefuge" then
			local contact = item:FindFirstChild("BankContact")
			assert(contact, "Safe refuge needs its real fixed support")
			-- Test the bank footprint plus a modest avatar body overhang and six studs of standing room.
			table.insert(record.refuges, box(contact.CFrame * C.new(0, 3.125, 0), V.new(contact.Size.X + 1.6, 6, contact.Size.Z + 1.6)))
		end
	end
	table.insert(units, record)
end
local function destination(record, actor, now)
	local kind, tuning = record.kind, Motion.Defaults[record.kind]
	local state
	if kind == "Foundry" then state = Motion.Foundry(now, actor.index, tuning)
	elseif kind == "Sweep" then state = Motion.Sweep(now, tuning)
	elseif kind == "Domino" then state = Motion.Domino(now, actor.index, tuning)
	else return actor.rest end
	if kind == "Foundry" then return actor.rest + record.frame:VectorToWorldSpace(V.new(0, -tuning.DropDistance * state.alpha, 0)) end
	if kind == "Sweep" then return actor.pivot * C.Angles(0, math.rad(tuning.Angle) * state.alpha, 0) * actor.localPose end
	return actor.pivot * C.Angles(0, 0, -math.rad(tuning.Angle) * state.alpha) * actor.localPose
end
local refugeChecks = 0
for n = 0, 1040 do
	for _,record in units do
		for _,actor in record.actors do
			local pose = destination(record, actor, n / 100)
			for _,shape in actor.shapes do
				local moving = box(pose * shape.localPose, shape.size)
				for _,refuge in record.refuges do
					assert(not overlaps(moving, refuge), record.kind .. " lethal travel reaches a fixed refuge at " .. n / 100)
					refugeChecks += 1
				end
			end
		end
	end
end
local work = {}
for _,dt in {1 / 30, 1 / 60, 1 / 144, .1, .19, .21} do
	local maximum, maxSteps, frames, paused = 0, 0, 0, 0
	local clock = Motion.NewClock(0)
	local previous = {}
	for _,record in units do for _,actor in record.actors do previous[actor] = actor.rest end end
	for frame = 1, math.floor(31.2 / dt) do
		local _, now, advanced = Motion.StepClock(clock, frame * dt)
		if not advanced then paused += 1; continue end
		local queries = 0
		for _,record in units do
			for _,actor in record.actors do
				if #actor.shapes == 0 then continue end
				local target = destination(record, actor, now)
				local steps = Motion.SweepSteps(previous[actor], target, actor.radius)
				assert(steps <= Motion.Defaults.MaxSweepSteps)
				maxSteps = math.max(maxSteps, steps)
				queries += #actor.shapes * (if previous[actor] == target then 1 else steps + 1)
				previous[actor] = target
			end
		end
		assert(queries <= Motion.Defaults.MaxQueriesPerFrame, "Query budget exceeded at dt " .. dt)
		maximum = math.max(maximum, queries); frames += 1
	end
	table.insert(work, {dt = dt, frames = frames, peakPlannedQueries = maximum, maximumActorSteps = maxSteps, pausedStalls = paused})
end
local output = {status = "passed", sampledRefugeSeparations = refugeChecks, avatarEnvelope = "Footprint plus .8 studs per side and six studs above support", rows = work, limits = "Offline oriented-box math and source work counts using ideal elapsed steps. Does not execute Studio GetPartsInPart, contact against live avatars, physics, frame-time or device measurements. Standing refuge checks do not prove every jump is reachable or safe."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_sweeps_receipt.json", serde.encode("json", output, true))
print(serde.encode("json", output, true))
