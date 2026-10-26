--!strict

-- Exercises the running service with one real racer and isolated paths; it is not a course playthrough.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local services = game.ServerScriptService.Services
local motion = require(services.CourseMotionService)
assert(require(services.RaceService).IsRaceActive(),"Start a real Studio race first")
local player = game.Players:GetPlayers()[1]
assert(require(services.PlayerRaceService).IsOfficialRacer(player),"A real official racer is required")
local character = player.Character :: Model
local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
local course = workspace.RaceCourse
local authored=script:GetAttribute("UseAuthoredCover")==true
local prefix=if authored then "JourneyAuthoredCover" else "JourneyCover"
local authoredCover: MeshPart?=nil
if authored then
	for _,mesh in ipairs(course:GetDescendants()) do
		if mesh:IsA("MeshPart") and mesh:GetAttribute("ProjectileCover") and mesh.Parent.Name=="SnowRefugeOutcrop" then
			if not authoredCover or mesh.Size.Y<authoredCover.Size.Y then authoredCover=mesh end
		end
	end
	assert(authoredCover,"Expected actual snow refuge geometry")
end
local templates = {}
local saved = {}
for _,p in ipairs(course:GetDescendants()) do
	if p:IsA("BasePart") and p:GetAttribute("MotionKind") then
		local kind = p:GetAttribute("MotionKind")
		if kind=="Snowball" or kind=="RollingBoulder" or kind=="Avalanche" then templates[kind]=p end
		saved[p]=kind
		p:SetAttribute("MotionKind",nil)
	end
end
motion.BindActiveCourse()
local initial = character:GetPivot()
local forcefields = {}
for _,c in ipairs(character:GetChildren()) do if c:IsA("ForceField") then table.insert(forcefields,c);c.Parent=game.ServerStorage end end
local results = {}
root.Anchored=true
player:SetAttribute(prefix.."Status","Running")
local ok,err = pcall(function()
	for _,kind in ipairs(if authored then {"Snowball","Avalanche"} else {"Snowball","RollingBoulder","Avalanche"}) do
		for _,scenario in ipairs(if authored then {"exposed","behind","front"} else {"exposed","behind","front","radius"}) do
			local fixture=Instance.new("Model")
			fixture.Name="JourneyCoverFixture"
			fixture.Parent=course.Hazards
			local z=if scenario=="radius" then 6.5 else 0
			local cover=if authored then (authoredCover :: MeshPart):Clone() else Instance.new("Part")
			if not authored then cover.Size=Vector3.new(2,14,10) end
			cover.CFrame=CFrame.new(0,600,if scenario=="exposed" then 30 else 0)
			cover.Anchored=true
			cover:SetAttribute("ProjectileCover",true)
			cover.Parent=fixture
			local warning=Instance.new("Part")
			warning.Name="Warning"
			warning.Anchored=true
			warning.CanCollide=false
			warning.CanQuery=false
			warning.CFrame=CFrame.new(-20,590,z)
			warning.Parent=fixture
			local hazard=templates[kind]:Clone()
			local reach=if authored then 30 else 20
			hazard.CFrame=CFrame.new(-reach,600,z)
			hazard.Anchored=true
			hazard:SetAttribute("MotionKind",kind)
			hazard:SetAttribute("MotionStart",hazard.CFrame)
			hazard:SetAttribute("MotionEnd",CFrame.new(reach,600,z))
			hazard:SetAttribute("MotionDuration",1)
			hazard:SetAttribute("PauseDuration",.3)
			hazard:SetAttribute("PauseMin",.3)
			hazard:SetAttribute("PauseMax",.3)
			hazard:SetAttribute("CycleOffset",0)
			hazard:SetAttribute("PhysicsMotion",false)
			hazard.Parent=fixture
			motion.BindActiveCourse()
			for cycle=1,2 do
				local distance=if authored then 16 else 8
				local position=Vector3.new(if scenario=="front" then -distance else distance,600,z)
				character:PivotTo(CFrame.new(position))
				character:SetAttribute("RecoveryUntil",0)
				humanoid.Health=100
				local deadline=os.clock()+5
				repeat task.wait() until hazard:GetAttribute("MotionPhase")=="Travelling" or os.clock()>deadline
				assert(os.clock()<deadline,"Hazard never travelled")
				repeat task.wait() until hazard:GetAttribute("MotionPhase")=="Cooldown" or os.clock()>deadline
				assert(os.clock()<deadline,"Hazard never completed")
				local affected=humanoid.Health<100 or (character:GetPivot().Position-position).Magnitude>10
				local expected=scenario=="exposed" or scenario=="front"
				table.insert(results,{kind=kind,scenario=scenario,cycle=cycle,affected=affected,expected=expected,passed=affected==expected,health=humanoid.Health})
			end
			fixture:Destroy()
		end
	end
end)
for p,kind in pairs(saved) do p:SetAttribute("MotionKind",kind) end
motion.BindActiveCourse()
for _,f in ipairs(forcefields) do f.Parent=character end
character:PivotTo(initial)
root.Anchored=false
humanoid.Health=100
local passed=ok
for _,r in ipairs(results) do if not r.passed then passed=false end end
player:SetAttribute(prefix.."Results",game.HttpService:JSONEncode({cases=results,error=if ok then nil else tostring(err)}))
player:SetAttribute(prefix.."Status",if passed then "Passed" else "Failed")
