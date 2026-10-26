local Test = {}

function Test.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local lobby = workspace.Lobby
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	local colliders, seats = {}, {}
	for _, part in lobby:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("LobbyCollision") then table.insert(colliders, part) end
		if part:IsA("Seat") then table.insert(seats, part) end
	end
	assert(#colliders > 0 and #seats == 16, "Expected collision and all sixteen seats")
	parameters.FilterDescendantsInstances = colliders
	local function world(x,y,z) return lobby:GetPivot():PointToWorldSpace(Vector3.new(-x,z-18,y+3)) end
	local checks = {}
	for _, side in {-1,1} do
		local hit = workspace:Raycast(world(side*30,0,21), Vector3.new(-side*15,0,0), parameters)
		table.insert(checks, {name="SolidStairSide"..side, passed=hit~=nil})
	end
	for _, level in {{0,59,-47},{18,53.5,-22},{38,45,20}} do
		for _, side in {-1,1} do
			local hit = workspace:Raycast(world(side*(level[2]-3),level[3],level[1]+2),Vector3.new(-side*6,0,0),parameters)
			table.insert(checks,{name="SideGuard"..level[1].."/"..side,passed=hit~=nil})
		end
	end
	for _, z in {3} do
		local hit = workspace:Raycast(world(0,58,z),Vector3.new(0,0,8),parameters)
		table.insert(checks,{name="RearWall"..z,passed=hit~=nil})
	end
	for _, side in {-1,1} do
		for _, definition in {{48.5,14,28},{34.8,48.5,47}} do
			local hit = workspace:Raycast(world(side*definition[1],definition[2]-3,definition[3]),Vector3.new(0,0,6),parameters)
			table.insert(checks,{name="InvisibleBarrier"..side.."/"..definition[3],passed=hit~=nil and hit.Instance:GetAttribute("InvisibleBarrier")==true})
		end
		local hit = workspace:Raycast(world(side*35,10,28),Vector3.new(0,0,7),parameters)
		table.insert(checks,{name="RelocatedMiddleWall"..side,passed=hit~=nil})
	end
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name, rig.Parent = "BlenderLobbySeatFixture", workspace
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local root = rig.HumanoidRootPart
	root:SetNetworkOwner(nil)
	for _, seat in seats do
		rig:PivotTo(seat.CFrame+CFrame.new(0,3,0).Position)
		root.AssemblyLinearVelocity = Vector3.zero
		seat:Sit(humanoid)
		task.wait(.15)
		table.insert(checks,{name=seat.Name,passed=seat.Occupant==humanoid and humanoid.SeatPart==seat})
		humanoid.Sit=false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(.15)
	end
	rig:Destroy()
	return {revision=lobby:GetAttribute("BlenderRevision"),checks=checks}
end

return Test
