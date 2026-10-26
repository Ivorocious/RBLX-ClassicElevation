-- Representative checks use a separate R15 fixture; they never move the player's character.
local Test = {}

function Test.Run(onlyAwnings: boolean?, importedCourse: Model?)
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and RunService:IsRunning(), "Studio Play required")
	local Players = game:GetService("Players")
	local player = Players:GetPlayers()[1]
	local settings = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	assert(settings, "A player is required for live movement settings")
	local builders = game.ServerStorage.CourseBuilders.CityRun
	local data = require(builders.Manifest)
	local course = importedCourse or workspace:FindFirstChild("CityRunGeometry_C01")
		or require(builders.Installer).Install(nil,"CityRunGeometry_C01",true)
	course.StartPen.StartGate.CanCollide = false
	local warnings = require(game.ServerScriptService.Services.CourseService).ValidateCourseModel(course,true)
	assert(#warnings==0,table.concat(warnings,"; "))
	local origin = course:GetPivot()
	local surfaces = course.Obstacles.WalkingSurfaces
	local description = Instance.new("HumanoidDescription")
	local rig = Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name, rig.Parent = "CityRunMovementFixture",workspace
	local humanoid,root = rig:FindFirstChildOfClass("Humanoid"),rig.HumanoidRootPart
	root:SetNetworkOwner(nil)
	humanoid.WalkSpeed,humanoid.UseJumpPower = settings.WalkSpeed,settings.UseJumpPower
	humanoid.JumpHeight,humanoid.JumpPower = settings.JumpHeight,settings.JumpPower
	local lift = humanoid.HipHeight+root.Size.Y/2
	local records = {}
	local function place(p)
		humanoid:Move(Vector3.zero)
		root.CFrame = CFrame.new(p+Vector3.new(0,lift+.12,0))
		root.AssemblyLinearVelocity,root.AssemblyAngularVelocity = Vector3.zero,Vector3.zero
		task.wait(.35)
		return humanoid.FloorMaterial~=Enum.Material.Air
	end
	local function reach(target,jump,timeout)
		local started,airborne = os.clock(),false
		if jump then humanoid.Jump=true end
		while os.clock()-started<timeout do
			local d=target-root.Position;local flat=Vector3.new(d.X,0,d.Z)
			if humanoid.FloorMaterial==Enum.Material.Air then airborne=true end
			if flat.Magnitude<.65 and math.abs(root.Position.Y-lift-target.Y)<.8 and humanoid.FloorMaterial~=Enum.Material.Air then
				humanoid:Move(Vector3.zero);return true,airborne
			end
			humanoid:Move(if flat.Magnitude<.2 then Vector3.zero else flat.Unit,false)
			RunService.Heartbeat:Wait()
		end
		humanoid:Move(Vector3.zero);return false,airborne
	end
	local ok,failure=xpcall(function()
		for _,pair in {
			{"Awnings_00_02","Awnings_00_03"}, {"Awnings_01_03","Awnings_02_01"},
			{"ClimbMain_01_02","ClimbMain_01_03"}, {"X01_02_05","X01_02_06"},
			{"X01_00_00","X01_00_01"}, {"X01_00_02","X01_01_01"},
			{"DistrictRoofs_00_02","DistrictRoofs_00_03"}, {"X02_01_07","X02_01_08"},
			{"StationaryTrains_00_01","StationaryTrains_00_02"},
			{"StationMain_03_01","StationMain_03_02"}, {"X03_01_05","X03_01_06"},
		} do
			if onlyAwnings and pair[1]~="Awnings_01_03" then continue end
			local a,b=surfaces[pair[1]],surfaces[pair[2]]
			if a:IsA("Model") then a = assert(a.PrimaryPart) end
			if b:IsA("Model") then b = assert(b.PrimaryPart) end
			local d=b.Position-a.Position;local direction=Vector3.new(d.X,0,d.Z).Unit
			local halfA=math.abs(direction.X)*a.Size.X/2+math.abs(direction.Z)*a.Size.Z/2
			local halfB=math.abs(direction.X)*b.Size.X/2+math.abs(direction.Z)*b.Size.Z/2
			local from=a.Position+Vector3.new(0,.5,0)+direction*(halfA-.4)
			local target=b.Position+Vector3.new(0,.5,0)-direction*(halfB-.4)
			local grounded=place(from)
			local passed,airborne=reach(target,true,1.8)
			table.insert(records,{name=pair[1].." > "..pair[2],grounded=grounded,passed=passed and airborne,airborne=airborne,position=tostring(root.Position)})
		end
		for _,definition in if onlyAwnings then {} else {
			{name="TrainContinuousCrossing",a=Vector3.new(205,82,-32),b=Vector3.new(205,82,8)},
			{name="MarketRoad",a=Vector3.new(-170,12,178),b=Vector3.new(-170,12,150)},
			{name="StationEntryStairs",a=Vector3.new(205,82,14),b=Vector3.new(205,86,57)},
		} do
			local grounded=place(origin:PointToWorldSpace(definition.a))
			local began=os.clock();local passed=reach(origin:PointToWorldSpace(definition.b),false,4)
			table.insert(records,{name=definition.name,grounded=grounded,passed=passed,seconds=os.clock()-began})
		end
	end,debug.traceback)
	rig:Destroy()
	if not ok then error(failure) end
	return {revision=course:GetAttribute("CityRunRevision") or data.revision,geometryOnly=importedCourse==nil,walkSpeed=settings.WalkSpeed,jumpHeight=settings.JumpHeight,records=records,
		limitation="Representative movement samples; full route timing, crowds and hazard contact/recovery are separate checks."}
end

return Test
