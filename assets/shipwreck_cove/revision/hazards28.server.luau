local HttpService = game:GetService("HttpService")
local Layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config = require(game.ReplicatedStorage.Config.ShipwreckConfig)
local records = {}
local fixture, controller, player, character, root, origin, humanoid
local oldPivot, oldAnchored, oldAutoRotate
local eligibleEnabled = false
local hits = {}
local waveOriginals = {}
local fallOriginals = {}

local function check(name, callback)
	local ok, result = pcall(callback)
	table.insert(records, {name = name, passed = ok, error = if ok then nil else tostring(result)})
	script:SetAttribute("Progress", #records)
end

local function localPosition(point)
	return origin:PointToWorldSpace(Vector3.new(point[1], point[2], point[3]))
end

local function moveRoot(worldPosition)
	character:PivotTo(character:GetPivot() + (worldPosition - root.Position))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	character:SetAttribute("RecoveryUntil", 0)
end

local function moveLocal(point)
	moveRoot(localPosition(point))
end

local function standOn(surface, localX, localZ)
	local footPoint = surface.CFrame:PointToWorldSpace(Vector3.new(localX, surface.Size.Y * 0.5, localZ))
	local boundsCFrame, boundsSize = character:GetBoundingBox()
	local feetOffset = root.Position.Y - (boundsCFrame.Position.Y - boundsSize.Y * 0.5)
	moveRoot(footPoint + Vector3.new(0, feetOffset, 0))
end

local function step(t, dt)
	hits = {}
	controller.Step(t, dt, true)
end

local function wasHit(reason)
	return table.find(hits, reason) ~= nil
end

local function partSnapshot(part)
	return {
		CFrame = part.CFrame,
		Size = part.Size,
		Color = part.Color,
		Transparency = part.Transparency,
		State = part:GetAttribute("State"),
		Warning = part:GetAttribute("Warning"),
	}
end

local function samePartState(part, saved, checkAttributes)
	assert(part.CFrame == saved.CFrame and part.Size == saved.Size, part.Name .. " pose was not restored")
	assert(part.Color == saved.Color and part.Transparency == saved.Transparency,
		part.Name .. " appearance was not restored")
	if checkAttributes then
		assert(part:GetAttribute("State") == saved.State and part:GetAttribute("Warning") == saved.Warning,
			part.Name .. " state was not restored")
	end
end

local setupOk, setupError = pcall(function()
	local template = assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_ShipwreckCove"),
		"Missing installed Shipwreck Cove course")
	assert(template:GetAttribute("ShipwreckBuild") == Layout.build, "Installed course differs from Layout")
	player = assert(game.Players:GetPlayers()[1], "Need a Studio test player")
	character = assert(player.Character, "Player has no character")
	humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "Missing humanoid")
	assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Probe requires an actual R15")
	root = assert(character:FindFirstChild("HumanoidRootPart"), "Missing HumanoidRootPart")
	oldPivot = character:GetPivot()
	oldAnchored = root.Anchored
	oldAutoRotate = humanoid.AutoRotate
	root.Anchored = true
	humanoid.AutoRotate = false

	fixture = template:Clone()
	fixture.Name = "__ShipwreckHazards28Fixture"
	fixture:PivotTo(fixture:GetPivot() + Vector3.new(1000, 0, 0))
	fixture.Parent = workspace
	origin = fixture.Bounds.CourseOrigin.CFrame

	for _, data in Layout.surges do
		local zone = assert(fixture.Decoration:FindFirstChild(data.name), "Missing " .. data.name)
		local bounds = assert(fixture.Obstacles.ShipwreckHazards:FindFirstChild(data.name .. "Bounds"),
			"Missing bounds for " .. data.name)
		waveOriginals[data.name] = {
			SurgeWater = partSnapshot(assert(zone:FindFirstChild("SurgeWater"))),
			SurgeFoam = partSnapshot(assert(zone:FindFirstChild("SurgeFoam"))),
			SurgeWave = partSnapshot(assert(zone:FindFirstChild("SurgeWave"))),
			bounds = bounds,
			attributes = {
				Phase = bounds:GetAttribute("Phase"),
				WaveNumber = bounds:GetAttribute("WaveNumber"),
				WavePhase = bounds:GetAttribute("WavePhase"),
			},
		}
	end
	for _, data in Layout.falling do
		local visual = assert(fixture.Decoration.Falling:FindFirstChild(data.name), "Missing " .. data.name)
		fallOriginals[data.name] = partSnapshot(visual)
	end
	controller = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
		function(_, reason)
			table.insert(hits, reason)
		end,
		function(candidate)
			return eligibleEnabled and candidate == player
		end)
end)

if setupOk then
	check("All sixteen battery platforms receive cannon contact with a standing R15", function()
		eligibleEnabled = true
		local platforms = {}
		local missing = {}
		assert(#Layout.shots == 4, "Expected four cannon lanes")
		for _, surface in fixture.Obstacles.WalkingSurfaces:GetChildren() do
			if surface:IsA("BasePart") and (string.match(surface.Name, "^BatteryCluster")
				or string.match(surface.Name, "^BatteryDeck")) then
				table.insert(platforms, surface)
			end
		end
		table.sort(platforms, function(a, b) return a.Name < b.Name end)
		assert(#platforms == 16, "Expected all sixteen battery route platforms")
		for _, support in platforms do
			local row = string.match(support.Name, "^BatteryCluster(%d+)_")
				or string.match(support.Name, "^BatteryDeck(%d+)$")
			local shot = assert(Layout.shots[(tonumber(row) or -1) + 1], "No cannon for " .. support.Name)
			local supportLocal = origin:PointToObjectSpace(support.Position)
			local targetWorld = origin:PointToWorldSpace(Vector3.new(supportLocal.X, 0, shot.start[3]))
			local targetOnSurface = support.CFrame:PointToObjectSpace(targetWorld)
			assert(math.abs(targetOnSurface.X) <= support.Size.X * 0.5
				and math.abs(targetOnSurface.Z) <= support.Size.Z * 0.5, support.Name .. " misses its lane")
			standOn(support, targetOnSurface.X, targetOnSurface.Z)
			local progress = math.clamp((supportLocal.X - shot.start[1]) / (shot.finish[1] - shot.start[1]), 0.02, 0.98)
			local travel = (Vector3.new(shot.finish[1], shot.finish[2], shot.finish[3])
				- Vector3.new(shot.start[1], shot.start[2], shot.start[3])).Magnitude / Config.CannonSpeed
			controller.Reset()
			step(shot.phase + Config.CannonWarning + travel * progress + 0.01, 0.1)
			if fixture.Decoration.H01[shot.name]:GetAttribute("Phase") ~= "Shot" or not wasHit("H01 Cannon") then
				table.insert(missing, support.Name)
			end
		end
		assert(#missing == 0, "Standing body missed battery platforms: " .. table.concat(missing, ", "))
	end)

	check("Two wave zones keep independent phases and a trailing flood", function()
		eligibleEnabled = false
		assert(Config.TideCycle == 14, "Expected the tuned 14-second wave cycle")
		controller.Reset()
		step(0, 0)
		assert(fixture.Obstacles.ShipwreckHazards.Surge1Bounds:GetAttribute("Phase") == "Dry",
			"Dry phase did not start the cycle")
		controller.Reset()
		step(6.5, 0.1)
		assert(fixture.Obstacles.ShipwreckHazards.Surge1Bounds:GetAttribute("Phase") == "Warning",
			"Warning phase did not precede the surge")
		controller.Reset()
		step(13, 0.1)
		assert(fixture.Obstacles.ShipwreckHazards.Surge1Bounds:GetAttribute("Phase") == "Drain",
			"Drain phase did not follow the surge")
		controller.Reset()
		step(14, 0.1)
		assert(fixture.Obstacles.ShipwreckHazards.Surge1Bounds:GetAttribute("Phase") == "Dry",
			"14-second cycle did not return to dry")
		controller.Reset()
		step(10.5, 0.1)
		local bounds1 = fixture.Obstacles.ShipwreckHazards.Surge1Bounds
		local bounds2 = fixture.Obstacles.ShipwreckHazards.Surge2Bounds
		local zone1 = fixture.Decoration.Surge1
		local zone2 = fixture.Decoration.Surge2
		assert(bounds1:GetAttribute("Phase") == "Surge" and zone1.SurgeWave.Transparency < 1,
			"Surge1 did not show its crest")
		assert(bounds2:GetAttribute("Phase") == "Dry" and zone2.SurgeWave.Transparency == 1,
			"Surge2 did not remain dry during Surge1")
		local firstFront = bounds1.CFrame:PointToObjectSpace(zone1.SurgeWave.Position).Z
		local waterCenter = origin:PointToObjectSpace(zone1.SurgeWater.Position)
		local waterFront = bounds1.CFrame:PointToObjectSpace(zone1.SurgeWater.Position).Z
			- zone1.SurgeWater.Size.Z * 0.5
		local waterBack = waterFront + zone1.SurgeWater.Size.Z
		local waterTop = waterCenter.Y + zone1.SurgeWater.Size.Y * 0.5
		assert(math.abs(firstFront - waterFront) < 0.3, "Pool front is not behind the visible crest")
		assert(firstFront - zone1.SurgeWave.Size.Z * 0.5 < waterFront - 0.5,
			"Visible crest does not lead the pool front")
		assert(waterBack > firstFront + zone1.SurgeWave.Size.Z * 0.5 + 1,
			"Pool does not extend behind the crest")
		assert(waterTop <= 8.6, "Water pool rises above the 8.5-stud refuge clearance")
		assert(math.abs(zone1.SurgeWave.Size.X - bounds1.Size.X) < 0.1
			and math.abs(zone1.SurgeWave.Size.Y - Config.TideCrestHeight) < 0.1
			and math.abs(zone1.SurgeWave.Size.Z - Config.TideCrestDepth) < 0.1, "Crest dimensions drifted")

		controller.Reset()
		step(16.5, 0.1)
		assert(bounds2:GetAttribute("Phase") == "Surge" and zone2.SurgeWave.Transparency < 1,
			"Surge2 did not activate independently")
		assert(bounds1:GetAttribute("Phase") == "Dry" and zone1.SurgeWave.Transparency == 1,
			"Surge1 remained active during Surge2")
		local secondFront = bounds2.CFrame:PointToObjectSpace(zone2.SurgeWave.Position).Z
		assert(secondFront > 0, "Surge2 crest did not start at the +Z edge")
		step(17, 0.5)
		step(17.5, 0.5)
		local secondLateFront = bounds2.CFrame:PointToObjectSpace(zone2.SurgeWave.Position).Z
		assert(secondFront > secondLateFront, "Surge2 front did not move toward -Z")
		controller.Reset()
		step(9, 0.1)
		local earlyFront = bounds1.CFrame:PointToObjectSpace(zone1.SurgeWave.Position).Z
		step(10, 0.5)
		local laterFront = bounds1.CFrame:PointToObjectSpace(zone1.SurgeWave.Position).Z
		assert(earlyFront > laterFront, "Surge1 front did not sweep toward -Z")
	end)

	check("Dry front and three refuge decks stay safe; crest and pool contact", function()
		eligibleEnabled = true
		local crossing = assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild("Surge1Passage"),
			"Missing Surge1 passage")
		local crossingLocal = origin:PointToObjectSpace(crossing.Position)
		controller.Reset()
		standOn(crossing, 0, 0)
		step(0, 0)
		assert(not wasHit("H02 Tide surge"), "Dry zone caused contact")
		controller.Reset()
		standOn(crossing, 0, 0)
		step(6.5, 0.1)
		assert(fixture.Obstacles.ShipwreckHazards.Surge1Bounds:GetAttribute("Phase") == "Warning"
			and not wasHit("H02 Tide surge"), "Warning phase caused damage")
		controller.Reset()
		standOn(crossing, 0, -6.5)
		step(10.5, 0.1)
		assert(not wasHit("H02 Tide surge"), "Wave hit ahead of its visible front")
		controller.Reset()
		standOn(crossing, 0, -2)
		step(10.5, 0.1)
		assert(wasHit("H02 Tide surge"), "Visible crest missed standing R15")
		controller.Reset()
		standOn(crossing, 0, 6.5)
		step(10.5, 0.1)
		assert(wasHit("H02 Tide surge"), "Visible surge pool missed standing R15")
		assert(math.abs(crossingLocal.Y + crossing.Size.Y * 0.5 - 5) < 0.1, "Passage is not at the authored floor")

		local refugeNames = {"SurgeEastRefuge", "SurgeMiddleRefuge", "SurgeWestRefuge"}
		for _, time in {10.5, 17.5} do
			for _, name in refugeNames do
				local refuge = assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild(name), "Missing " .. name)
				for _, data in Layout.surges do
					local bounds = fixture.Obstacles.ShipwreckHazards[data.name .. "Bounds"]
					local inZone = bounds.CFrame:PointToObjectSpace(refuge.Position)
					local overlapX = math.abs(inZone.X) < (bounds.Size.X + refuge.Size.X) * 0.5
					local overlapZ = math.abs(inZone.Z) < (bounds.Size.Z + refuge.Size.Z) * 0.5
					assert(not (overlapX and overlapZ), name .. " overlaps " .. data.name .. " bounds")
				end
				controller.Reset()
				standOn(refuge, 0, 0)
				step(time, 0.1)
				assert(not wasHit("H02 Tide surge"), name .. " was hit during an active wave")
			end
		end
	end)

	check("Six stalactites and nineteen coconuts warn with safe varied cycles", function()
		eligibleEnabled = false
		local spikes, coconuts = {}, {}
		local markerCount = 0
		for _, data in Layout.falling do
			if data.kind == "coconut" then table.insert(coconuts, data) else table.insert(spikes, data) end
			local marker = assert(fixture.Decoration.Falling:FindFirstChild(data.name .. "Warning"),
				"Missing marker for " .. data.name)
			assert(marker.Material == Enum.Material.SmoothPlastic and not marker.CanCollide
				and not marker.CanTouch and not marker.CanQuery, "Warning marker is interactive or glossy")
			markerCount += 1
		end
		assert(#spikes == 6 and #coconuts == 19 and #Layout.falling <= (Config.MaxFallingHazards or 32),
			"Unexpected falling hazard counts")
		local events = {}
		local previous = {}
		for _, data in Layout.falling do events[data.name] = {}; previous[data.name] = false end
		controller.Reset()
		controller.Step(0, 0, true)
		for _, data in Layout.falling do
			previous[data.name] = fixture.Decoration.Falling[data.name]:GetAttribute("Warning") == true
		end
		local warningStart = {}
		local shortWarnings = {}
		for tick = 1, 540 do
			local time = tick * 0.05
			controller.Step(time, 0.05, true)
			for _, data in Layout.falling do
				local visual = fixture.Decoration.Falling[data.name]
				local marker = fixture.Decoration.Falling[data.name .. "Warning"]
				local warning = visual:GetAttribute("Warning") == true
				if warning and not previous[data.name] then
					local localMarker = origin:PointToObjectSpace(marker.Position)
					local offset = Vector3.new(localMarker.X - data.bottom[1], 0, localMarker.Z - data.bottom[3])
					assert(offset.Magnitude <= (data.spread or 0) + 0.12, data.name .. " marker misses its target")
					assert(marker.Transparency < 1, data.name .. " warning marker stayed hidden")
					local period = data.period or 5
					local cycle = math.floor((time - (data.phase or 0)) / period)
					table.insert(events[data.name], {
						time = time,
						delay = time - ((data.phase or 0) + cycle * period),
						offset = offset,
					})
					warningStart[data.name] = time
				elseif not warning and previous[data.name] and warningStart[data.name] then
					local length = time - warningStart[data.name]
					if length + 0.11 < math.max(1.3, data.warning or 1.3) then
						table.insert(shortWarnings, data.name)
					end
					warningStart[data.name] = nil
				end
				previous[data.name] = warning
			end
		end
		assert(#shortWarnings == 0, "Warning was too short for " .. table.concat(shortWarnings, ", "))
		local missing, jittered, drifted = {}, 0, 0
		for _, data in spikes do
			local starts = events[data.name]
			if #starts < 2 or math.abs((starts[2].time - starts[1].time) - data.period) > 0.15 then
				table.insert(missing, data.name .. " stable warning period")
			end
		end
		for _, data in coconuts do
			local starts = events[data.name]
			if #starts < 2 then
				table.insert(missing, data.name .. " repeated warning")
			else
				if math.abs(starts[2].delay - starts[1].delay) > 0.1 then jittered += 1 end
				if (starts[2].offset - starts[1].offset).Magnitude > 0.15 then drifted += 1 end
			end
		end
		assert(#missing == 0, table.concat(missing, ", "))
		assert(jittered >= 15 and drifted >= 15,
			"Coconut cycles were too synchronized (delay=" .. jittered .. ", target=" .. drifted .. ")")
		local finalMarkers = 0
		for _, child in fixture.Decoration.Falling:GetChildren() do
			if string.find(child.Name, "Warning$", 1) and child:IsA("BasePart") then finalMarkers += 1 end
		end
		assert(finalMarkers == markerCount, "Runtime recreated or lost warning markers")
	end)

	check("Reset restores reusable visuals and Stop removes runtime objects", function()
		eligibleEnabled = false
		controller.Reset()
		controller.Step(10.5, 0.1, true)
		controller.Reset()
		for name, saved in waveOriginals do
			local zone = fixture.Decoration[name]
			for partName, original in saved do
				if partName ~= "bounds" and partName ~= "attributes" then
					local part = zone[partName]
					assert(part.CFrame == original.CFrame and part.Size == original.Size,
						partName .. " was not restored by Reset")
					assert(part.Transparency == 1, partName .. " remained visible after Reset")
				end
			end
		end
		for name, saved in fallOriginals do
			samePartState(fixture.Decoration.Falling[name], saved, true)
			assert(fixture.Decoration.Falling[name .. "Warning"].Transparency == 1,
				name .. " warning remained visible after Reset")
		end
		for _, data in Layout.surges do
			local foam = fixture.Decoration[data.name].SurgeFoam
			assert(foam:FindFirstChild("TideWarning") and foam:FindFirstChild("TideSurge"),
				data.name .. " runtime sounds were not created")
		end
		controller.Step(10.5, 0.1, true)
		controller.Stop()
		controller = nil
		for name, saved in waveOriginals do
			local zone = fixture.Decoration[name]
			for partName, original in saved do
				if partName ~= "bounds" and partName ~= "attributes" then
					samePartState(zone[partName], original, false)
				end
			end
			for attributeName, value in saved.attributes do
				assert(saved.bounds:GetAttribute(attributeName) == value,
					name .. " bounds attribute was not restored")
			end
		end
		for name, saved in fallOriginals do samePartState(fixture.Decoration.Falling[name], saved, true) end
		for _, data in Layout.falling do
			assert(not fixture.Decoration.Falling:FindFirstChild(data.name .. "Warning"),
				"Stop left a warning marker")
		end
		for _, data in Layout.surges do
			local foam = fixture.Decoration[data.name].SurgeFoam
			assert(not foam:FindFirstChild("TideWarning") and not foam:FindFirstChild("TideSurge"),
				"Stop left a wave sound")
		end
		for _, data in Layout.shots do
			local cue = fixture.Decoration.H01[data.cue]
			local impact = fixture.Decoration.H01[data.impact]
			assert(not cue:FindFirstChild("Fuse") and not cue:FindFirstChild("Blast")
				and not cue:FindFirstChild("MuzzleFire") and not cue:FindFirstChild("MuzzleSmoke")
				and not impact:FindFirstChild("WaterSplash"), "Stop left cannon objects")
		end
	end)
end

if controller then pcall(function() controller.Stop() end) end
if fixture then fixture:Destroy() end
if character and oldPivot then
	character:PivotTo(oldPivot)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.Anchored = oldAnchored
	end
	if humanoid then humanoid.AutoRotate = oldAutoRotate end
end
if not setupOk then table.insert(records, {name = "Probe setup", passed = false, error = tostring(setupError)}) end
local passed = 0
for _, result in records do if result.passed then passed += 1 end end
script:SetAttribute("Result", HttpService:JSONEncode({
	build = Layout.build,
	passed = passed,
	total = #records,
	records = records,
	method = "Controlled server clock in a cloned SC_MAP_28 fixture with the live Studio R15; not full-route, real-time, or multiplayer validation.",
}))
