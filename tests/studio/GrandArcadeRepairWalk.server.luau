-- Run only for the changed entrance joint in a labelled solo Studio session.
local Test = {}

function Test.Run()
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	assert(RunService:IsStudio() and RunService:IsRunning() and game.PlaceId == 85558151074819)
	local owner = Players:GetPlayers()[1]
	local character = owner and owner.Character
	local settings = character and character:FindFirstChildOfClass("Humanoid")
	assert(character and settings and settings.RigType == Enum.HumanoidRigType.R15, "Live R15 character required")
	local previousArchivable = character.Archivable
	character.Archivable = true
	local rig = character:Clone()
	character.Archivable = previousArchivable
	rig.Name = "GrandArcadeRepairWalkingFixture"
	for _, value in rig:GetDescendants() do
		if value:IsA("LuaSourceContainer") then value:Destroy() end
		if value:IsA("BasePart") then value.Anchored = false end
	end
	rig.Parent = workspace
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local root = rig:FindFirstChild("HumanoidRootPart")
	assert(humanoid and root)
	root:SetNetworkOwner(nil)
	humanoid.WalkSpeed = settings.WalkSpeed
	humanoid.PlatformStand, humanoid.Sit, humanoid.AutoRotate = false, false, true
	humanoid.JumpHeight, humanoid.JumpPower = 0, 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	local lift = humanoid.HipHeight + root.Size.Y / 2
	local record = {kind = "Solo Studio R15 fixture; real Humanoid movement over changed joint", walkSpeed = humanoid.WalkSpeed, routes = {}, passed = true}
	local function walk(x, z)
		local started = os.clock()
		local samples = {}
		local passed = false
		while os.clock() - started < 5 do
			local difference = Vector3.new(x - root.Position.X, 0, z - root.Position.Z)
			table.insert(samples, {time = os.clock() - started, p = {root.Position.X, root.Position.Y, root.Position.Z},
				grounded = humanoid.FloorMaterial ~= Enum.Material.Air, health = humanoid.Health, state = humanoid:GetState().Name})
			if difference.Magnitude < .45 then passed = true; break end
			if humanoid.Health <= 0 or root.Position.Y < 373 then break end
			humanoid:Move(difference.Unit, false)
			task.wait(.05)
		end
		humanoid:Move(Vector3.zero, false)
		for _, sample in samples do
			passed = passed and sample.grounded and sample.health == humanoid.MaxHealth and sample.state ~= "Jumping"
		end
		return {target = {x, z}, reached = (Vector3.new(x - root.Position.X, 0, z - root.Position.Z)).Magnitude < .45,
			passed = passed, samples = samples, finish = {root.Position.X, root.Position.Y, root.Position.Z}}
	end
	local ok, err = xpcall(function()
		for _, x in {1552, 1544.8, 1559.2} do
			root.CFrame = CFrame.new(x, 374.2 + lift + .15, -911)
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			task.wait(.6)
			local forward = walk(x, -926)
			task.wait(.1)
			local reverse = walk(x, -911)
			local route = {x = x, forward = forward, reverse = reverse,
				jumpDisabled = not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) and humanoid.JumpPower == 0 and humanoid.JumpHeight == 0}
			route.passed = forward.passed and reverse.passed and route.jumpDisabled
			record.passed = record.passed and route.passed
			table.insert(record.routes, route)
		end
	end, debug.traceback)
	rig:Destroy()
	assert(ok, err)
	return record
end

return Test
