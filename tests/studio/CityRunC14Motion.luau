-- Focused C14 motion, hazard-contact, and legacy runtime checks in Studio Play.
local Test = {}

local RunService = game:GetService("RunService")

local function axisVector(name)
	return ({X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis})[name]
end

local function isNamedHazard(part, token)
	return part:IsA("BasePart")
		and part:GetAttribute("HazardType") == "Kill"
		and string.find(part.Name, token, 1, true) ~= nil
end

function Test.Run(template: Model)
	assert(RunService:IsStudio() and RunService:IsServer(), "Run in Studio server Play")
	local player = assert(game.Players:GetPlayers()[1], "No test player")
	local character = assert(player.Character, "No avatar")
	local root = assert(character:FindFirstChild("HumanoidRootPart"))
	local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
	local saved, anchored = character:GetPivot(), root.Anchored
	local fixture = template:Clone()
	fixture.Name = "__C14MotionFixture"
	    local external=Instance.new("Folder")
    external.Name,external.Parent="ExternalCollisionContext",fixture
    for _,item in workspace:GetDescendants() do
        if item:IsA("BasePart") and not item:IsA("Terrain") and item.CanCollide
            and not item:IsDescendantOf(character) and not item:IsDescendantOf(fixture)
            and not item:IsDescendantOf(template)
            and item.Position.X>=3100 and item.Position.X<=4050
            and item.Position.Z>=-500 and item.Position.Z<=400 then
            local copy=item:Clone()
            for _,child in copy:GetDescendants() do if child:IsA("LuaSourceContainer") then child:Destroy() end end
            copy:SetAttribute("ExternalSource",item:GetFullName())
            copy.Parent=external
        end
    end
fixture:PivotTo(CFrame.new(8000, 100, 0))
	fixture.Parent = workspace

	local records = {}
	local recoveries = {}
	local current = fixture
	local hazardSource = game.ServerScriptService.Services.CourseHazardService:Clone()
	hazardSource.Name, hazardSource.Parent = "__C14MotionHazards", game.ServerStorage
	local hazardService = require(hazardSource)
	local safeCFrame = fixture.Start.CFrame + Vector3.new(0, 6, 0)
	hazardService.Init({Services = {
		RaceService = {IsRaceActive = function() return true end},
		PlayerRaceService = {
			IsOfficialRacer = function(candidate) return candidate == player end,
			GetPlayerStatus = function() return "Racing" end,
		},
		CourseService = {GetActiveCourse = function() return current end},
		RespawnService = {RecoverPlayer = function(_, label)
			table.insert(recoveries, label)
			character:PivotTo(safeCFrame)
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			return true
		end},
	}})

	local function waitFor(predicate, seconds, message)
		local deadline = os.clock() + seconds
		repeat RunService.Heartbeat:Wait() until predicate() or os.clock() >= deadline
		assert(predicate(), message)
	end

	local function contact(part, label)
		local before = #recoveries
		root.Anchored = false
		root:SetNetworkOwner(nil)
		character:PivotTo(part.CFrame)
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		waitFor(function() return #recoveries > before end, 2, label .. " did not recover the avatar")
		table.insert(records, {name = label, passed = true, recoveryLabel = recoveries[#recoveries]})
		task.wait(.15)
	end

	local ok, failure = xpcall(function()
		local categories = {Gate = 0, Slalom = 0, Hurdle = 0}
		local slides = {}
		local checker
		for _, item in fixture.Obstacles.C14Routes:GetDescendants() do
			if not item:IsA("BasePart") or item:GetAttribute("HazardType") ~= "Kill" then continue end
			assert(item.Anchored and item.CanTouch and item.CanQuery, item:GetFullName() .. " cannot bind safely")
			if string.find(item.Name, "Gate", 1, true) then categories.Gate += 1 end
			if string.find(item.Name, "Slalom", 1, true) then categories.Slalom += 1 end
			if string.find(item.Name, "Travel", 1, true) or string.find(item.Name, "Hurdle", 1, true) then
				categories.Hurdle += 1
			end
			if item:GetAttribute("KitMotion") == "Slide" then table.insert(slides, item) end
			if not checker and isNamedHazard(item, "Checker") then checker = item end
		end
		assert(categories.Gate > 0 and categories.Slalom > 0 and categories.Hurdle > 0, "A C14 moving-hazard family is missing")
		assert(#slides > 1, "C14 slide hazards are missing")
		assert(checker, "C14 checker kill trap is missing")
		table.insert(records, {name = "C14HazardFamiliesBindable", passed = true, counts = categories, slides = #slides})

		local motion = assert(require(game.ServerStorage.CourseBuilders.ManualObstacleMotion).Create(fixture), "Manual motion did not bind")
		local starts = {}
		for _, slide in slides do
			starts[slide] = slide.CFrame
			local worldAxisName = slide:GetAttribute("WorldMotionAxis") or slide:GetAttribute("MotionAxis")
			assert(typeof(worldAxisName) == "string" and axisVector(worldAxisName), slide.Name .. " has no valid world motion axis")
			local actual = slide.CFrame:VectorToWorldSpace(axisVector(slide:GetAttribute("MotionAxis")))
			assert(math.abs(actual:Dot(axisVector(worldAxisName)))>.999, slide.Name .. " runtime axis diverges from authored world axis")
		end

		local sample
        for _, slide in slides do if slide.Name:find("C14_Gate_DistrictRoofs_02_01",1,true) then sample=slide end end
        assert(sample,"Deterministic gate sample missing")
		local period = assert(sample:GetAttribute("MotionPeriod"))
		local distance = assert(sample:GetAttribute("MotionDistance"))
		local expectedAxis = axisVector(sample:GetAttribute("WorldMotionAxis") or sample:GetAttribute("MotionAxis"))
		for _ = 1, math.round(period / .4) do motion.Step(.1) end
		local delta = sample.Position - starts[sample].Position
		assert(math.abs(delta:Dot(expectedAxis)) >= distance - .12, sample.Name .. " did not reach its authored endpoint")
		assert((delta - expectedAxis * delta:Dot(expectedAxis)).Magnitude < .03, sample.Name .. " moved off its world axis")

		local opposite
		for _, candidate in slides do
			if candidate ~= sample
				and candidate:GetAttribute("MotionPeriod") == period
				and candidate:GetAttribute("MotionDistance") == distance
				and candidate:GetAttribute("WorldMotionAxis") == sample:GetAttribute("WorldMotionAxis")
				and math.abs((candidate:GetAttribute("MotionPhase") or 0) - (sample:GetAttribute("MotionPhase") or 0)) == 180 then
				opposite = candidate
				break
			end
		end
		assert(opposite, "No matching opposite-phase C14 slide pair")
		local sampleTravel = (sample.Position - starts[sample].Position):Dot(expectedAxis)
		local oppositeTravel = (opposite.Position - starts[opposite].Position):Dot(expectedAxis)
		assert(sampleTravel * oppositeTravel < 0, "Opposite-phase slides moved together")

		motion.Reset()
		for _, slide in slides do
			assert((slide.CFrame.Position - starts[slide].Position).Magnitude < .001, slide.Name .. " did not reset")
			if slide.Size.Y < 2 then continue end
            local worldAxisName = slide:GetAttribute("WorldMotionAxis") or slide:GetAttribute("MotionAxis")
			local axis = axisVector(worldAxisName)
			local avatarWidth = if worldAxisName == "X" then root.Size.X else root.Size.Z
			local nearestDeck, nearestDistance
			for _, candidate in fixture.Obstacles.C14Routes:GetDescendants() do
				if candidate:IsA("BasePart") and candidate.CanCollide then
					local localPoint = candidate.CFrame:PointToObjectSpace(slide.Position)
					local horizontal = Vector2.new(
						math.max(0, math.abs(localPoint.X) - candidate.Size.X / 2),
						math.max(0, math.abs(localPoint.Z) - candidate.Size.Z / 2)
					).Magnitude
					if horizontal < 1 and (not nearestDistance or math.abs(localPoint.Y) < nearestDistance) then
						nearestDeck, nearestDistance = candidate, math.abs(localPoint.Y)
					end
				end
			end
			assert(nearestDeck, slide.Name .. " has no supporting route deck")
			local localAxis = nearestDeck.CFrame:VectorToObjectSpace(axis)
			local deckSpan = if math.abs(localAxis.X) > math.abs(localAxis.Z) then nearestDeck.Size.X else nearestDeck.Size.Z
			local localHazardAxis=slide.CFrame:VectorToObjectSpace(axis)
            local hazardSpan=math.abs(localHazardAxis.X)*slide.Size.X+math.abs(localHazardAxis.Y)*slide.Size.Y+math.abs(localHazardAxis.Z)*slide.Size.Z
			local clearWidth = math.min(deckSpan,(deckSpan-hazardSpan)/2+slide:GetAttribute("MotionDistance"))
			assert(clearWidth >= avatarWidth + .5, slide.Name .. " closes passage below avatar width at an extreme")
		end
		table.insert(records, {name = "SlideEndpointsAxesPhaseResetAndClearance", passed = true,
			sample = sample.Name, opposite = opposite.Name, slideCount = #slides, avatarSize = {root.Size.X, root.Size.Y, root.Size.Z}})

		hazardService.Start()
		contact(sample, "MovingSlideContact")
		contact(checker, "StationaryCheckerContact")
        for _, part in fixture.Obstacles.C14Routes.DepotEntry:GetDescendants() do
            if isNamedHazard(part,"KillStrip") then contact(part,"StationaryKillStripContact"); break end
        end

		assert(fixture.Obstacles.Moving:FindFirstChild("BallA") and fixture.Obstacles.Moving:FindFirstChild("BallB") and fixture.Obstacles.Moving:FindFirstChild("BallACable") and fixture.Obstacles.Moving:FindFirstChild("BallBCable"), "Both signature wrecking balls and cables are required")
		local ballContacts=0
        local runtime = require(game.ServerStorage.CourseBuilders.CityRun.Runtime).Create(fixture,
            function(_,label) if label=="CityRunWreckingBall" then ballContacts+=1 end return true end,
            function(candidate) return candidate==player end)
		assert(fixture.Obstacles.Moving:FindFirstChild("Car0") and fixture.Obstacles.Moving:FindFirstChild("Car1")
			and fixture.Obstacles.Moving:FindFirstChild("Car2"), "Runtime removed a traffic car")
		local train = fixture.Obstacles.Moving:FindFirstChild("TrainAssembly")
		assert(train and #train:GetChildren() == 3, "Runtime did not retain all three train coaches")
		runtime.Step(0, false)
        for index,name in {"BallA","BallB"} do
            runtime.Step(index,false)
            local frame=fixture.Obstacles.Moving[name]:GetBoundingBox()
            local before=ballContacts
            character:PivotTo(CFrame.new(frame.Position))
            runtime.Step(index+.01,true)
            assert(ballContacts>before,name.." did not register actual avatar contact")
            table.insert(records,{name=name.."SignatureContact",passed=true})
        end
		runtime.Stop()
		table.insert(records, {name = "RuntimeRetainsSignatureBallsAndTraffic", passed = true,
			cars = 3, trainCoaches = #train:GetChildren(), wreckingBalls=2, cables=2})
	end, debug.traceback)

	current = nil
	hazardService.BindActiveCourse()
	character:PivotTo(saved)
	root.Anchored = anchored
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	if not anchored then root:SetNetworkOwnershipAuto() end
	fixture:Destroy()
	hazardSource:Destroy()
	return {
		passed = ok,
		records = records,
		failure = if ok then nil else failure,
		method = "Actual C14 clone, deterministic ManualObstacleMotion poses, real avatar hazard contacts, and legacy City Run runtime creation",
		limitation = "Focused server Play test; it does not grade human timing, client latency, or full-course traversal",
	}
end

return Test
