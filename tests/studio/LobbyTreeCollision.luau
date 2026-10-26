local Test = {}

local function trees(lobby)
	local result = {}
	for _, object in lobby:GetDescendants() do
		if object:IsA("Model") and string.match(object.Name, "^Gardens_Tree_%d%d$") then table.insert(result, object) end
	end
	table.sort(result, function(a,b) return a.Name < b.Name end)
	assert(#result == 8, "Expected eight editable trees")
	return result
end

function Test.Static()
	local lobby = workspace.Lobby
	local results = {}
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = {lobby}
	parameters.RespectCanCollide = true
	for _, tree in trees(lobby) do
		local trunk = tree:FindFirstChild("TreeTrunkCollider")
		assert(trunk and trunk:IsA("BasePart") and trunk.CanCollide, "Missing solid trunk: " .. tree.Name)
		local planter = nil
		for _, part in tree:GetChildren() do
			if part:IsA("BasePart") and part.CanCollide and part ~= trunk then planter = part; break end
		end
		assert(planter, "Missing planter")
		local point = planter.Position + Vector3.new(0, planter.Size.Y/2 + 2, 0)
		for _, axis in {Vector3.xAxis, Vector3.zAxis} do
			local hit = workspace:Raycast(point-axis*2, axis*4, parameters)
			assert(hit and hit.Instance == trunk, "Trunk ray missed: " .. tree.Name)
		end
		local clone = tree:Clone()
		local before = clone.TreeTrunkCollider
		local localFrame, size = clone:GetPivot():ToObjectSpace(before.CFrame), before.Size
		local target = clone:GetPivot() * CFrame.new(8,3,-6) * CFrame.Angles(0,math.rad(25),0)
		clone:PivotTo(target)
		clone:ScaleTo(clone:GetScale()*1.1)
		local expected = target * (localFrame.Rotation + localFrame.Position*1.1)
		local error = (before.Position-expected.Position).Magnitude + (before.Size-size*1.1).Magnitude
		clone:Destroy()
		assert(error < .002, "Collision did not follow tree editing")
		table.insert(results, {tree=tree.Name,rayAxesPassed=2,editTransformError=error})
	end
	return results
end

function Test.Movement()
	assert(game:GetService("RunService"):IsRunning(), "Play mode required")
	local fixture = Instance.new("Folder")
	fixture.Name, fixture.Parent = "LobbyTreeCollisionFixture", workspace
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Parent = fixture
	local humanoid, root = rig:FindFirstChildOfClass("Humanoid"), rig.HumanoidRootPart
	root:SetNetworkOwner(nil)
	humanoid.WalkSpeed = 16
	local records = {}
	local ok, failure = xpcall(function()
		for _, original in trees(workspace.Lobby) do
			local tree = original:Clone()
			tree:PivotTo(CFrame.new(6000,1000,6000))
			tree.Parent = fixture
			local trunk = tree.TreeTrunkCollider
			local floor = Instance.new("Part")
			floor.Name, floor.Size = "Ground", Vector3.new(20,1,20)
			floor.Anchored = true
			floor.Position = Vector3.new(trunk.Position.X,trunk.Position.Y-trunk.Size.Y/2-.5,trunk.Position.Z)
			floor.Parent = fixture
			for _, axis in {Vector3.xAxis,Vector3.zAxis} do
				humanoid:Move(Vector3.zero)
				local start = Vector3.new(trunk.Position.X,floor.Position.Y+.5+humanoid.HipHeight+root.Size.Y/2+.1,trunk.Position.Z)-axis*3
				rig:PivotTo(CFrame.new(start))
				root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				task.wait(.2)
				humanoid:Move(axis)
				task.wait(.7)
				humanoid:Move(Vector3.zero)
				local advance = (root.Position-start):Dot(axis)
				local signedDistance = (root.Position-trunk.Position):Dot(axis)
				local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
				table.insert(records,{tree=tree.Name,axis=tostring(axis),advance=advance,signedDistance=signedDistance,grounded=grounded,passed=advance>.4 and signedDistance<-.5 and grounded})
			end
			tree:Destroy()
			floor:Destroy()
		end
	end, debug.traceback)
	fixture:Destroy()
	assert(ok, failure)
	return records
end

return Test
