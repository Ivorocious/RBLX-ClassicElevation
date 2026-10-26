-- Focused shared-kit V4 checks in a disposable Studio Play session with isolated race dependencies.
local Test = {}

function Test.Run()
	assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsRunning())
	local liveRace = require(game.ServerScriptService.Services.RaceService)
	liveRace.ApplyStudioAction("HoldLobby")
	local deadline = os.clock() + 10
	while liveRace.GetRaceState() ~= "WaitingForPlayers" and os.clock() < deadline do task.wait(.1) end
	assert(liveRace.GetRaceState() == "WaitingForPlayers", "Normal rounds must be held during the isolated fixture test")
	local player = assert(game.Players:GetPlayers()[1])
	local character = assert(player.Character)
	local root = character.HumanoidRootPart
	local saved, anchored = character:GetPivot(), root.Anchored
	local palette = workspace:FindFirstChild("ObstacleKit_Palette") or game.ServerStorage.DeveloperAssets:FindFirstChild("ObstacleKit_Palette")
	local fixture = assert(palette):Clone()
	fixture.Name = "ManualObstacleKit_Test"
	fixture:PivotTo(CFrame.new(7500, 100, 0))
	fixture.Parent = workspace
	local currentFixture = fixture
	local authoredMotion = {}
	for _, part in fixture:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("KitMotion") then authoredMotion[part] = part.CFrame end
	end
	local hazardModule = game.ServerScriptService.Services.CourseHazardService:Clone()
	local respawnModule = game.ServerScriptService.Services.RespawnService:Clone()
	hazardModule.Parent, respawnModule.Parent = game.ServerStorage, game.ServerStorage
	local eligible, active, recoveries = true, true, 0
	local destination = CFrame.new(7500, 145, 200)
	local race = { IsRaceActive = function() return active end }
	local racers = {
		IsOfficialRacer = function() return eligible end,
		GetPlayerStatus = function() return "Racing" end,
	}
	local respawn = require(respawnModule)
	respawn.Init({ Services = {
		RaceService = race, PlayerRaceService = racers, CourseService = {},
		CheckpointService = { GetCheckpointRespawnCFrame = function() return destination end },
		ResultsService = { RecordFall = function() end },
	} })
	local hazards = require(hazardModule)
	hazards.Init({ Services = {
		RaceService = race, PlayerRaceService = racers,
		CourseService = { GetActiveCourse = function() return currentFixture end },
		RespawnService = { RecoverPlayer = function(p, reason)
			local recovered = respawn.RecoverPlayer(p, reason)
			if recovered then recoveries += 1 end
			return recovered
		end },
	} })
	local function waitFor(predicate, seconds)
		local deadline = os.clock() + seconds
		repeat if predicate() then return true end task.wait(.05) until os.clock() > deadline
		return predicate()
	end
	local records = {}
	local ok, failure = xpcall(function()
		root.Anchored = true
		hazards.Start()
		for _, definition in {
			{ "17_SpinningKillStrip", "Spinner" }, { "31_PistonPresses", "Press_0" },
            { "32_ClockworkCrossing", "MinuteHand" }, { "33_CargoShuttle", "Cargo_0" },
            { "34_RisingShutterVault", "Shutter_1" }, { "42_ScissorCrossing", "Blade_1_1" },
		} do
			task.wait(1.6)
			local trap = fixture.CopyThese[definition[1]][definition[2]]
			local prior = trap.CFrame
			task.wait(.2)
			assert(trap.CFrame ~= prior, definition[1] .. " did not move")
			local before = recoveries
			character:PivotTo(trap.CFrame * CFrame.new(trap.Size.X*.3, 0, 0))
			local recovered = waitFor(function() return recoveries > before end, 1)
			local errorDistance = (root.Position-destination.Position).Magnitude
			assert(recovered and errorDistance < .01, definition[1] .. " did not recover")
			table.insert(records, { name = definition[1], moved = true, recovered = true, checkpointError = errorDistance })
		end
		eligible = false
		local before = recoveries
		character:PivotTo(fixture.CopyThese["01_RedKillBlock"].KillBlock.CFrame)
		task.wait(1.7)
		assert(recoveries == before, "Non-racer was recovered")
		table.insert(records, { name = "NonRacerExcluded", passed = true })
		eligible, active = true, false
		task.wait(.4)
		assert(recoveries == before, "Inactive race recovered a player")
		table.insert(records, { name = "InactiveRaceExcluded", passed = true })
		for part, cf in authoredMotion do assert(part.CFrame == cf, "Inactive motion did not reset") end
		table.insert(records, { name = "MotionInactiveReset", passed = true })
		currentFixture = nil
		hazards.BindActiveCourse()
		for part, cf in authoredMotion do assert(part.CFrame == cf, "Unbound motion did not restore") end
		currentFixture = fixture
		hazards.BindActiveCourse()
		table.insert(records, { name = "MotionUnbindRebind", passed = true })
		active = true
		for _, tile in {fixture.CopyThese["38_CrumbleStairChoice"].WideStep_0, fixture.CopyThese["39_FallingPianoKeys"].PianoKey_0, fixture.CopyThese["40_RooftopSkylights"].SkylightGlass_0} do
		local tileFrame = tile.CFrame
		character:PivotTo(tile.CFrame + Vector3.new(0, 4, 0))
		root.AssemblyLinearVelocity = Vector3.zero
		root.Anchored = false
		root:SetNetworkOwner(nil)
		assert(waitFor(function() return tile:GetAttribute("HazardPhase") == "Warning" end, 2), "Crumble touch did not trigger")
		root.Anchored = true
		assert(waitFor(function() return tile:GetAttribute("HazardPhase") == "Gone" end, (tile:GetAttribute("CrumbleDelay") or .65) + 2), "Crumble did not disappear")
		assert(not tile.CanCollide and not tile.CanTouch and tile.Position.Y < tileFrame.Position.Y - 1, "Crumble did not fall clear of the route")
		character:PivotTo(destination)
		assert(waitFor(function() return tile:GetAttribute("HazardPhase") == "Solid" end, 3.5), "Crumble did not reset")
		assert(tile.CanCollide and tile.CanTouch and tile.CFrame == tileFrame, "Crumble did not restore its placed position")
		table.insert(records, { name = tile.Parent.Name .. "TouchGoneReset", passed = true })
		end
	end, debug.traceback)
	active = false
	character:PivotTo(saved)
	root.AssemblyLinearVelocity = Vector3.zero
	root.Anchored = anchored
	fixture:Destroy()
	hazardModule:Destroy()
	respawnModule:Destroy()
	if not ok then error(failure) end
	return { records = records, limitation = "Actual kit geometry and existing hazard/recovery services with isolated race/checkpoint dependencies. Owner placements and complete obstacle traversal are not verified." }
end

return Test
