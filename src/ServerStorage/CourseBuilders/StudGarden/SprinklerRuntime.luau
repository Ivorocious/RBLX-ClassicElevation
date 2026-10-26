--!strict

local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Geometry=require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local Phase=require(script.Parent.HazardState)
local Wayfinding=require(script.Parent.Wayfinding)
local HazardClock=require(script.Parent.HazardClock)
local Runtime={}

function Runtime.Start(course: Model, eligible: (Player)->boolean, recover: (Player,string)->boolean)
	assert(RunService:IsServer() and RunService:IsRunning(),"Runtime server required")
	assert(course:GetAttribute("SGV2Owned")==true,"V2 course required")
	assert(course:GetAttribute("SGV2RuntimeActive")~=true,"Runtime is already active")
	local hazard=course:FindFirstChild("H1_Sprinkler") :: Model
	assert(hazard and hazard:IsA("Model"),"Sprinkler assembly required")
	assert(math.abs(hazard:GetScale()-1)<0.001,"Move/rotate the complete encounter; scaling is not supported")
	local water=hazard:FindFirstChild("WaterSweep") :: BasePart
	local lamp=hazard:FindFirstChild("WarningLamp") :: BasePart
	local nozzle=hazard:FindFirstChild("NozzleCap") :: BasePart
	local jets=hazard:FindFirstChild("WaterJets")
	assert(water and lamp and nozzle,"Hazard visuals required")
	local frame=hazard:GetPivot()
	local curtainCenter=.5+water.Size.Y/2
	local nozzleHeight=hazard:GetAttribute("NozzleHeight") or 6
	local timing={Clear=hazard:GetAttribute("ClearSeconds") or 6.5,Warning=hazard:GetAttribute("WarningSeconds") or 1.5,Active=hazard:GetAttribute("ActiveSeconds") or 2}
	assert(timing.Clear>=5 and timing.Warning>=1.2 and timing.Active>0,"Keep a usable clear window and warning")
	local original={water=water.CFrame,transparency=water.Transparency,lamp=lamp.Color,nozzle=nozzle.CFrame}
	local originalJets={}
	if jets then for _,jet in jets:GetChildren() do
		if jet:IsA("BasePart") then table.insert(originalJets,{part=jet,frame=jet.CFrame,transparency=jet.Transparency}) end
	end end
	local originalStatus=Wayfinding.CaptureStatus(hazard)
	local clock=HazardClock.New(workspace:GetServerTimeNow())
	local cooldowns: {[Player]: number}={}
	local diagnostics={steps=0,contacts=0,recoveries=0,pausedStalls=0,maxStepMs=0}
	course:SetAttribute("SGV2RuntimeActive",true)
	local function sweep(alpha: number): CFrame
		return frame*CFrame.new(0,curtainCenter,-8+16*alpha)
	end
	local function step()
		local before=os.clock()
		local lastElapsed,elapsed,advanced=HazardClock.Step(clock,workspace:GetServerTimeNow())
		if not advanced then diagnostics.pausedStalls=clock.pausedStalls;return end
		local phase,alpha=Phase.Phase(elapsed,timing)
		water.CFrame=sweep(if phase=="Active" then alpha else 0)
		water.Transparency=if phase=="Active" then 0.78 else 1
		local remaining=if phase=="Clear" then timing.Clear*(1-alpha) else 0
		local entryOpen=Wayfinding.UpdateHazard(hazard,"SPRINKLER",phase,alpha,timing,hazard:GetAttribute("MinimumEntrySeconds") or 3.2,originalStatus)
		nozzle.CFrame=frame*CFrame.new(0,nozzleHeight,-8+16*(if phase=="Active" then alpha else 0))
		if jets then for _,jet in jets:GetChildren() do
			if jet:IsA("BasePart") then
				jet.CFrame=frame*CFrame.new(jet:GetAttribute("Across"),curtainCenter,-8+16*(if phase=="Active" then alpha else 0))
				jet.Transparency=if phase=="Active" then 0.16 else 1
			end
		end end
		Wayfinding.PublishPhase(hazard,phase,alpha,remaining,entryOpen)
		do
			local intervals=Phase.ActiveIntervals(lastElapsed,elapsed,timing)
			if #intervals>0 then
				local cachedSweeps: {{CFrame}}?=nil
				for _,player in Players:GetPlayers() do
				local character=player.Character
				local hum=character and character:FindFirstChildOfClass("Humanoid")
				if character and hum and hum.Health>0 and eligible(player) and (cooldowns[player] or 0)<elapsed then
					local hit=false
					for _,body in character:GetChildren() do
						if body:IsA("BasePart") and body.Name~="HumanoidRootPart" then
							for intervalIndex,interval in intervals do
								diagnostics.contacts+=1
								if not cachedSweeps then cachedSweeps={} end
								local endpoints=cachedSweeps[intervalIndex]
								if not endpoints then
									endpoints={sweep(interval[1]),sweep(interval[2])}
									cachedSweeps[intervalIndex]=endpoints
								end
								if Geometry.SweptBoxesIntersect(endpoints[1],endpoints[2],water.Size,body.CFrame,body.Size) then hit=true; break end
							end
						end
						if hit then break end
					end
					if hit then
						cooldowns[player]=elapsed+1
						if recover(player,"SGV2_H1") then diagnostics.recoveries+=1 end
					end
				end
			end end
		end
		diagnostics.steps+=1
		diagnostics.maxStepMs=math.max(diagnostics.maxStepMs,(os.clock()-before)*1000)
	end
	local connection=RunService.Heartbeat:Connect(step)
	local stopped=false
	return {
		Diagnostics=function() return table.clone(diagnostics) end,
		Stop=function()
			if stopped then return end
			stopped=true; connection:Disconnect()
			water.CFrame=original.water; water.Transparency=original.transparency
			lamp.Color=original.lamp; nozzle.CFrame=original.nozzle
			Wayfinding.RestoreStatus(originalStatus)
			for _,saved in originalJets do
				if saved.part.Parent then saved.part.CFrame=saved.frame;saved.part.Transparency=saved.transparency end
			end
			hazard:SetAttribute("Phase",nil); hazard:SetAttribute("PhaseAlpha",nil); hazard:SetAttribute("ClearRemaining",nil)
			hazard:SetAttribute("EntryOpen",nil)
			course:SetAttribute("SGV2RuntimeActive",nil)
		end,
	}
end

return Runtime
