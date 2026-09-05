--!strict

-- Focused startup/recovery/motion check; deliberately does not traverse the course.
local QuickCheck = {}

function QuickCheck.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local report = Instance.new("Folder")
	report.Name, report.Parent = "ClassicAscentV4Report", game.ServerStorage
	report:SetAttribute("Status", "Running")
	local checks = {}
	local function check(ok: boolean, message: string)
		assert(ok, message)
		table.insert(checks, message)
		report:SetAttribute("Checks", game.HttpService:JSONEncode(checks))
	end
	local function waitFor(predicate: () -> boolean, seconds: number)
		local deadline = os.clock()+seconds
		repeat task.wait(0.05) until predicate() or os.clock()>deadline
		assert(predicate(), "Timed out waiting for runtime state")
	end
	local ok, failure = pcall(function()
		local services=game.ServerScriptService.Services
		local race=require(services.RaceService)
		waitFor(race.IsRaceActive,50)
		local player=game.Players:GetPlayers()[1]
		local character=player.Character :: Model
		local humanoid=character:FindFirstChildOfClass("Humanoid") :: Humanoid
		local root=character.PrimaryPart :: BasePart
		root:SetNetworkOwner(nil)
		local course=workspace.RaceCourse
		check(course:GetAttribute("BuilderVersion")==4,"Version 4 starts with 19 checkpoints")
		check(#course.Checkpoints:GetChildren()==19,"Ordered checkpoints retained")
		local cp=course.Checkpoints.Checkpoint_001 :: BasePart
		character:PivotTo(cp.CFrame+CFrame.new(0,4,0).Position)
		local checkpoint=require(services.CheckpointService)
		waitFor(function()return checkpoint.GetLatestCheckpointIndex(player)==1 end,3)
		humanoid.Health=40
		local recovery=require(services.RespawnService)
		check(recovery.RecoverPlayer(player,"V4QuickCheck"),"Recovery accepted for official racer")
		check(player.Character==character and humanoid.Health==humanoid.MaxHealth,"Same character recovered and healed without death")
		check((root.Position-cp.Position).Magnitude<10,"Recovery lands directly at saved checkpoint")
		check(not recovery.RecoverPlayer(player,"Duplicate"),"Duplicate recovery suppressed")
		local log: BasePart?=nil
		local lava: BasePart?=nil
		local snow: BasePart?=nil
		local avalanche: BasePart?=nil
		for _, p in ipairs(course:GetDescendants())do
			if p:IsA("BasePart")then
				local kind=p:GetAttribute("MotionKind")
				if kind=="MovingLog" then log=p elseif kind=="LavaSpurt" then lava=p elseif kind=="Snowball" then snow=p elseif kind=="Avalanche" then avalanche=p end
			end
		end
		assert(log and lava and snow and avalanche,"All four motion types required")
		local initial=log.Position
		task.wait(1.2)
		check((log.Position-initial).Magnitude>0.05,"River logs move during race")
		local timber=log:FindFirstChild("RaftTimber") :: BasePart
		check(timber~=nil and math.abs(log.CFrame:PointToObjectSpace(timber.Position).X)<0.1,"Log bundle visuals stay attached")
		check(snow:GetAttribute("MotionPhase")~=nil and avalanche:GetAttribute("MotionPhase")~=nil,"Snowball and avalanche cycles active")
		waitFor(function()return lava:GetAttribute("MotionPhase")=="LavaPause" end,10)
		check(lava.Transparency<1,"Erupting lava is visible")
		character:PivotTo(lava.CFrame)
		waitFor(function()return (root.Position-cp.Position).Magnitude<10 end,3)
		check(player.Character==character and humanoid.Health>0,"Lava contact recovers without replacing character")
	end)
	report:SetAttribute("Status",if ok then "Passed" else "Failed")
	if not ok then report:SetAttribute("Failure",tostring(failure)) end
end

return QuickCheck
