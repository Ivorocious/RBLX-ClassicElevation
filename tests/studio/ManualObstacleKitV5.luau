-- Native geometry and controller checks; RunLive adds a real character and service lifecycle checks.
local Test = {}

local function closeFrame(a, b)
	local aa, bb = {a:GetComponents()}, {b:GetComponents()}
	for i,v in aa do if math.abs(v-bb[i]) > .002 then return false end end
	return true
end

function Test.RunControllers()
	assert(game.PlaceId == 85558151074819)
	local builders = game.ServerStorage.CourseBuilders
	local modules=Instance.new("Folder")
	modules.Name="ManualKitV5_ControllerModules"; modules.Parent=game.ServerStorage
	for _,name in {"ManualObstacleMotion","ManualObstaclePhases"} do local copy=builders[name]:Clone(); copy.Parent=modules end
	local motion = require(modules.ManualObstacleMotion)
	local fixture = workspace.ObstacleKit_Palette:Clone()
	fixture.Name = "ManualKitV5_ControllerTest"
	fixture:PivotTo(CFrame.new(7500,100,0) * CFrame.Angles(0,math.rad(120),0))
	fixture.Parent = game.ServerStorage
	local ok, result = xpcall(function()
		local controller = assert(motion.Create(fixture))
		local moving, phases, before = {}, {}, {}
		for _, part in fixture:GetDescendants() do
			if not part:IsA("BasePart") then continue end
			if part:GetAttribute("KitMotion") then table.insert(moving,part) end
			if part:GetAttribute("KitPhase") then phases[part]={} end
			before[part]={frame=part.CFrame,color=part.Color,material=part.Material,transparency=part.Transparency,
				collide=part.CanCollide,touch=part.CanTouch,query=part.CanQuery,state=part:GetAttribute("KitPhaseState")}
		end
		local defaults, pivots = 0,0
		for _, part in moving do if part:GetAttribute("MotionPivotOffset") then pivots+=1 else defaults+=1 end end
		local axes={X=Vector3.xAxis,Y=Vector3.yAxis,Z=Vector3.zAxis}
		for tick=1,440 do
			controller.Step(.05,nil,nil)
			local elapsed=tick*.05
			for _, part in moving do
				local kind=part:GetAttribute("KitMotion")
				local axis=axes[part:GetAttribute("MotionAxis")]
				local phase=elapsed*math.pi*2/(part:GetAttribute("MotionPeriod") or 6)+math.rad(part:GetAttribute("MotionPhase") or 0)
				local start=before[part].frame
				local expected
				if kind=="Slide" then expected=start*CFrame.new(axis*math.sin(phase)*(part:GetAttribute("MotionDistance") or 6))
				else
					local angle=if kind=="Spin" then phase else math.sin(phase)*math.rad(part:GetAttribute("MotionAngle") or 60)
					local pivot=part:GetAttribute("MotionPivotOffset") or Vector3.zero
					expected=start*CFrame.new(pivot)*CFrame.fromAxisAngle(axis,angle)*CFrame.new(-pivot)
					assert((part.CFrame:PointToWorldSpace(pivot)-start:PointToWorldSpace(pivot)).Magnitude<.003,"Hinge drift: "..part.Name)
				end
				assert(closeFrame(part.CFrame,expected),"Placed motion mismatch: "..part:GetFullName())
			end
			for part,seen in phases do
				local state=part:GetAttribute("KitPhaseState")
				seen[state]=true
				assert(part.CanCollide==(state~="Ghost"),"Phase collision mismatch")
				if state=="Ghost" then assert(not part.CanTouch and not part.CanQuery and part.Transparency>.8) end
				if state=="Warning" then assert(part.Material==Enum.Material.Neon and part.Color~=before[part].color) end
			end
		end
		local phaseCount=0
		for part,seen in phases do
			assert(seen.Solid and seen.Warning and seen.Ghost,"Incomplete phase cycle: "..part.Name)
			phaseCount+=1
		end
		controller.Reset()
		for part,record in before do
			assert(closeFrame(part.CFrame,record.frame),"Reset moved "..part.Name)
			assert(part.Color==record.color and part.Material==record.material and part.Transparency==record.transparency)
			assert(part.CanCollide==record.collide and part.CanTouch==record.touch and part.CanQuery==record.query)
			assert(part:GetAttribute("KitPhaseState")==record.state)
		end
		local phaseOnly=fixture.CopyThese["49_PulseSteppingStones"]:Clone()
		phaseOnly.Parent=fixture
		for _,part in phaseOnly:GetDescendants() do if part:GetAttribute("HazardType")=="Kill" then part:SetAttribute("HazardType",nil) end end
		local pulseController=assert(motion.Create(phaseOnly),"Phase-only course needs a controller")
		for _=1,130 do pulseController.Step(.05,nil,nil) end
		assert(not phaseOnly.Pulse_1.CanCollide,"Phase-only course did not fade")
		pulseController.Reset()
		assert(phaseOnly.Pulse_1.CanCollide)
		phaseOnly.Pulse_1:SetAttribute("PhasePeriod",2)
		phaseOnly.Pulse_1:SetAttribute("PhaseSolidTime",nil)
		phaseOnly.Pulse_1:SetAttribute("PhaseWarningTime",nil)
		local compact=assert(motion.Create(phaseOnly))
		local seen={}
		for _=1,50 do compact.Step(.05,nil,nil); seen[phaseOnly.Pulse_1:GetAttribute("KitPhaseState")]=true end
		assert(seen.Solid and seen.Warning and seen.Ghost,"Minimum period must retain all three states with default timings")
		compact.Reset()
		return {motionParts=#moving,ordinaryMotion=defaults,pivotMotion=pivots,phasePlatforms=phaseCount,
			rotatedPlacementDegrees=120,simulatedSeconds=22,fullRestore=true,phaseOnly=true,minimumPeriodDefaults=true}
	end,debug.traceback)
	fixture:Destroy(); modules:Destroy()
	if not ok then error(result) end
	return result
end

function Test.RunLive()
	assert(game.PlaceId==85558151074819 and game:GetService("RunService"):IsRunning())
	local liveRace=require(game.ServerScriptService.Services.RaceService)
	liveRace.ApplyStudioAction("HoldLobby")
	local deadline=os.clock()+10
	while liveRace.GetRaceState()~="WaitingForPlayers" and os.clock()<deadline do task.wait(.1) end
	assert(liveRace.GetRaceState()=="WaitingForPlayers")
	local player=assert(game.Players:GetPlayers()[1])
	local character=assert(player.Character)
	local root=character.HumanoidRootPart
	local saved, anchored=character:GetPivot(),root.Anchored
	local fixture=workspace.ObstacleKit_Palette:Clone()
	fixture.Name="ManualKitV5_LiveTest"
	fixture:PivotTo(CFrame.new(7500,100,0)*CFrame.Angles(0,math.rad(120),0))
	fixture.Parent=workspace
	local hazardModule=game.ServerScriptService.Services.CourseHazardService:Clone()
	local respawnModule=game.ServerScriptService.Services.RespawnService:Clone()
	hazardModule.Parent,respawnModule.Parent=game.ServerStorage,game.ServerStorage
	local active,eligible,recoveries=true,true,0
	local current=fixture
	local destination=CFrame.new(7500,180,200)
	local race={IsRaceActive=function() return active end}
	local racers={IsOfficialRacer=function() return eligible end,GetPlayerStatus=function() return "Racing" end}
	local respawn=require(respawnModule)
	respawn.Init({Services={RaceService=race,PlayerRaceService=racers,CourseService={},
		CheckpointService={GetCheckpointRespawnCFrame=function() return destination end},ResultsService={RecordFall=function() end}}})
	local hazards=require(hazardModule)
	hazards.Init({Services={RaceService=race,PlayerRaceService=racers,CourseService={GetActiveCourse=function() return current end},
		RespawnService={RecoverPlayer=function(p,reason) local recovered=respawn.RecoverPlayer(p,reason); if recovered then recoveries+=1 end; return recovered end}}})
	local function waitFor(predicate,seconds)
		local untilTime=os.clock()+seconds
		repeat if predicate() then return true end; task.wait(.04) until os.clock()>untilTime
		return predicate()
	end
	local records={}
	local ok,failure=xpcall(function()
		root.Anchored=true; character:PivotTo(destination)
		hazards.Start()
		for _,item in {
			{"17_SpinningKillStrip","Spinner"},{"43_HammerArcade","Hammer_0"},{"44_SatelliteCauseway","SatelliteA"},
			{"45_RotatingDoorway","HorizontalEdge_1"},{"46_CrescentSweep","CrescentArm"},{"47_FoldingFanGates","Fan_1_1"},
			{"48_OrbitalJumpRope","Rope"},{"61_HourglassCrossing","Sweep_1"},{"62_EclipseChamber","EclipseOrb"},
			{"63_ShuffleVault","ShufflingGate"},{"64_TidalLock","TidalGate"},{"65_DominoStairSprint","DominoHammer"},{"66_ClockworkGauntlet","EntrySweep"},
		} do
			task.wait(1.6)
			local trap=fixture.CopyThese[item[1]][item[2]]
			local prior=trap.CFrame; task.wait(.12)
			assert(not closeFrame(trap.CFrame,prior),"Static trap: "..item[1])
			local count=recoveries
			character:PivotTo(trap.CFrame)
			assert(waitFor(function() return recoveries>count end,1),"No recovery: "..item[1])
			assert((root.Position-destination.Position).Magnitude<.01)
			table.insert(records,{name=item[1],recovered=true,checkpointError=(root.Position-destination.Position).Magnitude})
		end
		eligible=false
		local count=recoveries
		character:PivotTo(fixture.CopyThese["43_HammerArcade"].Hammer_0.CFrame)
		task.wait(1.7); assert(recoveries==count,"Non-racer recovered")
		table.insert(records,{name="NonRacerExcluded",passed=true})
		active=false; eligible=true; character:PivotTo(destination); task.wait(.2)
		local tile=fixture.CopyThese["49_PulseSteppingStones"].Pulse_1
		local baseline={tile.Color,tile.Material,tile.Transparency,tile.CanCollide,tile.CanTouch,tile.CanQuery}
		assert(tile.CanCollide and tile:GetAttribute("KitPhaseState")==nil)
		table.insert(records,{name="InactiveRestoresPhases",passed=true})
		active=true
		assert(waitFor(function() return tile:GetAttribute("KitPhaseState")=="Solid" end,2))
		character:PivotTo(tile.CFrame+Vector3.new(0,3.7,0))
		root.AssemblyLinearVelocity=Vector3.zero; root.Anchored=false; root:SetNetworkOwner(nil)
		task.wait(.6)
		assert(root.Position.Y>tile.Position.Y+1.5,"Solid platform did not support character")
		assert(waitFor(function() return tile:GetAttribute("KitPhaseState")=="Warning" end,7))
		local warnedAt=os.clock()
		assert(tile.CanCollide)
		assert(waitFor(function() return tile:GetAttribute("KitPhaseState")=="Ghost" end,2.5))
		assert(os.clock()-warnedAt>1,"Warning too short")
		assert(waitFor(function() return recoveries>count or root.Position.Y<tile.Position.Y-2 end,1.5),"Ghost platform still supported character")
		root.Anchored=true; character:PivotTo(destination)
		assert(waitFor(function() return tile:GetAttribute("KitPhaseState")=="Solid" end,3))
		table.insert(records,{name="CharacterSolidWarningGhostReturn",passed=true})
		active=false; task.wait(.2)
		assert(tile.Color==baseline[1] and tile.Material==baseline[2] and tile.Transparency==baseline[3])
		assert(tile.CanCollide==baseline[4] and tile.CanTouch==baseline[5] and tile.CanQuery==baseline[6])
		current=nil; hazards.BindActiveCourse(); current=fixture; hazards.BindActiveCourse()
		active=true; task.wait(.2); assert(tile:GetAttribute("KitPhaseState")=="Solid")
		hazards.Stop(); assert(tile:GetAttribute("KitPhaseState")==nil and tile.CanCollide)
		table.insert(records,{name="RebindAndStopRestorePhases",passed=true})
	end,debug.traceback)
	active=false
	hazards.Stop()
	character:PivotTo(saved); root.AssemblyLinearVelocity=Vector3.zero; root.Anchored=anchored
	fixture:Destroy(); hazardModule:Destroy(); respawnModule:Destroy()
	if not ok then error(failure) end
	return {records=records,limitation="Isolated race and checkpoint dependencies; not complete route traversal, multiplayer, or device performance proof."}
end

function Test.RunRoute(index: number, lane: number?)
	assert(game.PlaceId==85558151074819 and game:GetService("RunService"):IsRunning())
	local player=assert(game.Players:GetPlayers()[1])
	local character=assert(player.Character)
	local root, humanoid=character.HumanoidRootPart,character.Humanoid
	local saved,anchored=character:GetPivot(),root.Anchored
	local fixture
	for _,model in workspace.ObstacleKit_Palette.CopyThese:GetChildren() do
		if tonumber(model.Name:sub(1,2))==index then fixture=model:Clone(); break end
	end
	assert(fixture)
	fixture.Name="ManualKitV5_Traversal_"..index
	fixture:PivotTo(CFrame.new(7800,150,0))
	fixture.Parent=workspace
	local path={"Entry"}
	if index==55 then for i=0,4 do table.insert(path,"Trestle_"..i) end
	elseif index==56 then for i=2,6 do table.insert(path,"AqueductCap_"..i) end
	elseif index==57 then for i=2,13 do table.insert(path,"KnotStep_"..i) end
	elseif index==58 then for i=1,6 do table.insert(path,"CompassPoint_"..i) end
	elseif index==59 then for i=0,5 do table.insert(path,"Cantilever_"..i) end
	elseif index==60 then for i=1,6 do table.insert(path,"Braid_"..(lane or 1).."_"..i) end
	else error("Unknown static route") end
	table.insert(path,"Exit")
	local ray=RaycastParams.new()
	ray.FilterType=Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances={fixture}
	local reached={}
	local targetName="Entry"
	local jumpCount=0
	local ok,failure=xpcall(function()
		assert(humanoid.WalkSpeed==16 and math.abs(humanoid.JumpHeight-7.2)<.01 and not humanoid.UseJumpPower)
		root.Anchored=false; root:SetNetworkOwner(nil)
		local start=fixture.Entry
		character:PivotTo(CFrame.new(start.Position+Vector3.new(0,start.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.1,0)))
		root.AssemblyLinearVelocity=Vector3.zero
		humanoid:Move(Vector3.zero,false); task.wait(.3)
		for i=2,#path do
			targetName=path[i]
			local target=fixture[targetName]
			local function steer()
				local delta=(target.Position-root.Position)*Vector3.new(1,0,1)
				humanoid:Move(if delta.Magnitude>.6 then delta.Unit else Vector3.zero,false)
				return delta.Magnitude
			end
			local walking=index==57 and (targetName=="KnotStep_3" or targetName=="KnotStep_4")
			steer()
			if not walking then
				humanoid.Jump=true; humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				jumpCount+=1
			end
			local deadline=os.clock()+3
			local stable,airborne=0,walking
			repeat
				game:GetService("RunService").Heartbeat:Wait()
				humanoid.Jump=false
				local distance=steer()
				airborne=airborne or humanoid.FloorMaterial==Enum.Material.Air
				local contact=workspace:Raycast(root.Position,Vector3.new(0,-8,0),ray)
				if airborne and contact and contact.Instance==target and humanoid.FloorMaterial~=Enum.Material.Air and distance<1 and math.abs(root.AssemblyLinearVelocity.Y)<5 then
					stable+=1
				else stable=0 end
			until stable>=4 or root.Position.Y<144 or os.clock()>deadline
			assert(stable>=4,"Could not land at "..targetName)
			table.insert(reached,targetName)
		end
	end,debug.traceback)
	local position=tostring(root.Position)
	humanoid:Move(Vector3.zero,false); humanoid.Jump=false
	root.Anchored=true; character:PivotTo(saved); root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=anchored
	fixture:Destroy()
	return {index=index,lane=lane,passed=ok,error=if ok then nil else failure,target=targetName,finalPosition=position,reached=reached,
		jumps=jumpCount,walkSpeed=16,jumpHeight=7.2,teleportsAfterStart=0,limitation="Scripted solo character traversal of static geometry."}
end

return Test
