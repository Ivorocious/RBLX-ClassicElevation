-- Uses the final course geometry, real avatar movement and controlled train timing.
local Test = {}

function Test.Run(template: Model)
	assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsRunning())
	local player = assert(game.Players:GetPlayers()[1])
	local character = assert(player.Character)
	local root, humanoid = character.HumanoidRootPart, character.Humanoid
	local saved, anchored = character:GetPivot(), root.Anchored
	local fixture = template:Clone()
	fixture.Name = "__C12TrainFixture"
	fixture:PivotTo(CFrame.new(9000, 100, 0))
	fixture.Parent = workspace
	local origin, recoveries, eligible = fixture:GetPivot(), 0, true
	local destination = fixture.Checkpoints.Checkpoint_006.CFrame+Vector3.new(0,5,0)
	local runtime = require(game.ServerStorage.CourseBuilders.CityRun.Runtime).Create(fixture, function(p, reason)
		assert(p==player and reason=="CityRunTrain")
		recoveries += 1
		character:PivotTo(destination)
		return true
	end, function(p) return eligible and p==player end)
	local records = {}
	local rail = require(game.ReplicatedStorage.Config.CityRunTuning).hazards.train
	local ok, failure = xpcall(function()
		local moving = fixture.Obstacles.Moving
		local closed = 9.2
		runtime.Step(closed, false)
		assert(fixture:GetAttribute("TrainPhase")=="Clearance")
		assert(not fixture.Obstacles.TrainEntryGate.CanCollide)
		for _, name in {"TrainBarrier","TrainBarrierExit"} do
			for _, part in moving[name]:GetDescendants() do
				if part:IsA("BasePart") then assert(not part.CanCollide and not part.CanTouch) end
			end
		end
		local standing = humanoid.HipHeight+root.Size.Y/2
		root.Anchored = false
		root:SetNetworkOwner(nil)
		character:PivotTo(origin*CFrame.new(205,82+standing,-34))
		root.AssemblyLinearVelocity = Vector3.zero
		humanoid:MoveTo(origin:PointToWorldSpace(Vector3.new(205,82+standing,8)))
		local deadline = os.clock()+4
		repeat task.wait(.05) until origin:PointToObjectSpace(root.Position).Z>6 or os.clock()>deadline
		assert(origin:PointToObjectSpace(root.Position).Z>6, "Lowered gate blocked normal walking")
		table.insert(records,{name="WalkThroughLoweredGate",passed=true,phase=fixture:GetAttribute("TrainPhase")})
		root.Anchored = true
		local function contact(x, name, y, z)
			local time = rail.openTime+(x-rail.startX)/rail.speed
			runtime.Step(time-.001,false)
			character:PivotTo(origin*CFrame.new(205,y or 85.6,z or -12))
			character:SetAttribute("RecoveryUntil",nil)
			local before = recoveries
			runtime.Step(time,true)
			assert(recoveries>before and (root.Position-destination.Position).Magnitude<.01, name)
			table.insert(records,{name=name,passed=true,respawnError=(root.Position-destination.Position).Magnitude})
		end
		contact(205,"TrainBodyRecoversToCP06")
		contact(258,"TrainTailStillLethal")
		contact(259,"EnlargedUpperBodyRecovers",93.6,-12)
		contact(260,"EnlargedSideRecovers",85.6,-5.7)
		eligible = false
		local before = recoveries
		character:PivotTo(origin*CFrame.new(205,85.6,-12))
		runtime.Step(rail.openTime+(261-rail.startX)/rail.speed+.001,true)
		assert(recoveries==before)
		table.insert(records,{name="NonRacerExcluded",passed=true})
		local clearTime = rail.openTime+(270-rail.startX)/rail.speed
		runtime.Step(clearTime,false)
		assert(fixture:GetAttribute("TrainPhase")=="Open")
		assert(not fixture.Obstacles.TrainEntryGate.CanCollide)
		local expected = origin*CFrame.new(270,89,-12)
		assert((moving.TrainAssembly:GetPivot().Position-expected.Position).Magnitude<.01)
		table.insert(records,{name="WholeTailClearOpensAndTrainPivotMatches",passed=true})
	end,debug.traceback)
	runtime.Stop()
	humanoid:Move(Vector3.zero)
	character:PivotTo(saved)
	root.Anchored = anchored
	root.AssemblyLinearVelocity = Vector3.zero
	if not anchored then root:SetNetworkOwnershipAuto() end
	fixture:Destroy()
	return {passed=ok,records=records,failure=if ok then nil else failure,
		limitation="One real avatar in a copied course with controlled timing and isolated recovery; no multiplayer or complete race traversal."}
end
return Test
