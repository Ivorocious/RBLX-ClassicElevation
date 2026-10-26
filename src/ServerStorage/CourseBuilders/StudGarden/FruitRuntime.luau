--!strict

local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Phase=require(script.Parent.HazardState)
local Motion=require(script.Parent.FruitMotion)
local Wayfinding=require(script.Parent.Wayfinding)
local HazardClock=require(script.Parent.HazardClock)
local FruitRuntime={}

function FruitRuntime.Start(hazard: Model,eligible: (Player)->boolean,recover: (Player,string)->boolean)
	assert(RunService:IsServer() and RunService:IsRunning(),"Runtime server required")
	assert(hazard:GetAttribute("SGV2Owned")==true and not hazard:GetAttribute("FruitRuntimeActive"),"Owned inactive fruit encounter required")
	assert(math.abs(hazard:GetScale()-1)<.001,"Translate/rotate complete encounter; scaling unsupported")
	local timing={Clear=hazard:GetAttribute("ClearSeconds") or 7,Warning=hazard:GetAttribute("WarningSeconds") or 1.5,Active=hazard:GetAttribute("ActiveSeconds") or 3.2}
	assert(timing.Clear>=5 and timing.Warning>=1.5 and timing.Active>=2.6,"Preserve warning and crossing windows")
	local frame=hazard:GetPivot()
	local catchDrop=hazard:GetAttribute("CatchDrop") or 0
	local lamp=hazard.WarningLamp :: BasePart
	local fruits={hazard.Fruit_1,hazard.Fruit_2,hazard.Fruit_3}
	local saved={lamp=lamp.Color,frames={}}
	local originalStatus=Wayfinding.CaptureStatus(hazard)
	for _,fruit in fruits do table.insert(saved.frames,fruit:GetPivot()) end
	local clock=HazardClock.New(workspace:GetServerTimeNow())
	local cooldowns: {[Player]: number}={}
	local report={steps=0,contacts=0,recoveries=0,pausedStalls=0,maxStepMs=0}
	hazard:SetAttribute("FruitRuntimeActive",true)
	local connection=RunService.Heartbeat:Connect(function()
		local before=os.clock()
		local previous,elapsed,advanced=HazardClock.Step(clock,workspace:GetServerTimeNow())
		if not advanced then report.pausedStalls=clock.pausedStalls;return end
		local phase,alpha=Phase.Phase(elapsed,timing)
		local remaining=if phase=="Clear" then timing.Clear*(1-alpha) else 0
		local entry=Wayfinding.UpdateHazard(hazard,"FRUIT",phase,alpha,timing,hazard:GetAttribute("MinimumEntrySeconds") or 3.5,originalStatus)
		for index,fruit in fruits do
			local parked=Vector3.new(hazard:GetAttribute("ParkedX") or -22,5.7,(index-2)*8)
			local position=if phase=="Active" then Motion.Position(alpha,index,catchDrop) elseif phase=="Warning" then parked:Lerp(Motion.Position(0,index,catchDrop),alpha) else parked
			fruit:PivotTo(frame*CFrame.new(position)*CFrame.Angles(0,0,if phase=="Active" then -(position.X+17)/2.4 else 0))
		end
		Wayfinding.PublishPhase(hazard,phase,alpha,remaining,entry)
		do
			local intervals=Phase.ActiveIntervals(previous,elapsed,timing)
			if #intervals>0 then
				local cachedSweeps: {[number]: {[number]: {Vector3}}}?=nil
				for _,player in Players:GetPlayers() do
				local character=player.Character
				local root=character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid=character and character:FindFirstChildOfClass("Humanoid")
				if character and root and humanoid and humanoid.Health>0 and (root.Position-frame.Position).Magnitude<60 and eligible(player) and (cooldowns[player] or 0)<elapsed then
					local hit=false
					for _,body in character:GetChildren() do
						if body:IsA("BasePart") and body.Name~="HumanoidRootPart" then
							for index=1,3 do for intervalIndex,interval in intervals do
									if not cachedSweeps then cachedSweeps={} end
									local fruitSweeps=cachedSweeps[index]
									if not fruitSweeps then fruitSweeps={};cachedSweeps[index]=fruitSweeps end
									local positions=fruitSweeps[intervalIndex]
									if not positions then
										positions=Motion.Segments(interval[1],interval[2],index,catchDrop)
										for pointIndex,position in positions do positions[pointIndex]=frame*position end
										fruitSweeps[intervalIndex]=positions
									end
									for segment=1,#positions-1 do
										report.contacts+=1
										if Motion.SweepTouchesBody(positions[segment],positions[segment+1],2.4,body.CFrame,body.Size) then hit=true;break end
									end
									if hit then break end
							end;if hit then break end end
						end
						if hit then break end
					end
					if hit then cooldowns[player]=elapsed+1;if recover(player,"SGV2_H2") then report.recoveries+=1 end end
				end
			end end
		end
		report.steps+=1;report.maxStepMs=math.max(report.maxStepMs,(os.clock()-before)*1000)
	end)
	local stopped=false
	return {
		Diagnostics=function() return table.clone(report) end,
		Stop=function()
			if stopped then return end;stopped=true;connection:Disconnect()
			for index,fruit in fruits do fruit:PivotTo(saved.frames[index]) end
			lamp.Color=saved.lamp
			Wayfinding.RestoreStatus(originalStatus)
			for _,name in {"Phase","PhaseAlpha","ClearRemaining","EntryOpen","FruitRuntimeActive"} do hazard:SetAttribute(name,nil) end
		end,
	}
end

return FruitRuntime
