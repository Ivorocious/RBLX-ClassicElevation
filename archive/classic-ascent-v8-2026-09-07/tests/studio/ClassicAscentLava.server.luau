--!strict

-- Tests the authored mesh with the running service in an isolated Studio area.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local services=game.ServerScriptService.Services
local motion=require(services.CourseMotionService)
local player=game.Players:GetPlayers()[1]
assert(require(services.RaceService).IsRaceActive() and require(services.PlayerRaceService).IsOfficialRacer(player),"A real race and official racer are required")
local character=player.Character :: Model
local root=character:FindFirstChild("HumanoidRootPart") :: BasePart
local initial=character:GetPivot()
local saved={}
local template: MeshPart?=nil
for _,p in ipairs(workspace.RaceCourse:GetDescendants()) do
	if p:IsA("BasePart") and p:GetAttribute("MotionKind") then
		local kind=p:GetAttribute("MotionKind")
		if kind=="LavaSpurt" then template=p :: MeshPart end
		saved[p]=kind
		p:SetAttribute("MotionKind",nil)
	end
end
motion.BindActiveCourse()
assert(template and template:IsA("MeshPart"),"Expected the tapered lava mesh")
local fixture=Instance.new("Model")
fixture.Name="JourneyLavaFixture"
fixture.Parent=workspace.RaceCourse.Hazards
local warning=Instance.new("Part")
warning.Name="Warning"
warning.Anchored,warning.CanCollide,warning.CanQuery,warning.CanTouch=true,false,false,false
warning.CFrame=CFrame.new(0,580,0)
warning.Parent=fixture
local plume=template:Clone()
plume.CFrame=CFrame.new(0,582,0)*CFrame.Angles(0,0,math.pi)
plume:SetAttribute("MotionStart",plume.CFrame)
plume:SetAttribute("MotionEnd",CFrame.new(0,600,0)*CFrame.Angles(0,0,math.pi))
plume:SetAttribute("MotionKind","LavaSpurt")
plume:SetAttribute("CycleOffset",0)
plume.Parent=fixture
motion.BindActiveCourse()
root.Anchored=true
player:SetAttribute("JourneyLavaStatus","Running")
local results={}
local ok,err=pcall(function()
	for _,x in ipairs({0,6,0,6}) do
		local position=Vector3.new(x,600,0)
		character:PivotTo(CFrame.new(position))
		character:SetAttribute("RecoveryUntil",0)
		local deadline=os.clock()+8
		repeat task.wait() until plume:GetAttribute("MotionPhase")=="LavaPause" or os.clock()>deadline
		assert(os.clock()<deadline,"Lava never reached its peak")
		task.wait(.25)
		local affected=(character:GetPivot().Position-position).Magnitude>10
		table.insert(results,{x=x,affected=affected,expected=x==0,passed=affected==(x==0)})
		repeat task.wait() until plume:GetAttribute("MotionPhase")=="Cooldown" or os.clock()>deadline
		assert(os.clock()<deadline,"Lava never retracted")
	end
end)
fixture:Destroy()
for p,kind in pairs(saved) do p:SetAttribute("MotionKind",kind) end
motion.BindActiveCourse()
character:PivotTo(initial)
root.Anchored=false
local passed=ok
for _,result in ipairs(results) do if not result.passed then passed=false end end
player:SetAttribute("JourneyLavaResults",game.HttpService:JSONEncode({cases=results,error=if ok then nil else tostring(err)}))
player:SetAttribute("JourneyLavaStatus",if passed then "Passed" else "Failed")
