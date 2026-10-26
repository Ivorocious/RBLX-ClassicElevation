-- Run on an isolated R15 fixture in Studio Play; the player is not moved.
local Test = {}

function Test.Run(lowerOnly: boolean?)
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsRunning(), "Studio Play required")
	local players = game:GetService("Players")
	local player = players:GetPlayers()[1]
	local settings = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	assert(settings, "A player is required to copy current movement settings")
	local description = Instance.new("HumanoidDescription")
	local rig = players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name, rig.Parent = "BlenderLobbyTraversalFixture", workspace
	local humanoid, root = rig:FindFirstChildOfClass("Humanoid"), rig.HumanoidRootPart
	root:SetNetworkOwner(nil)
	humanoid.WalkSpeed, humanoid.UseJumpPower = settings.WalkSpeed, settings.UseJumpPower
	humanoid.JumpHeight, humanoid.JumpPower = settings.JumpHeight, settings.JumpPower
	local lift = humanoid.HipHeight + root.Size.Y / 2
	local function world(p)
		return workspace.Lobby:GetPivot():PointToWorldSpace(Vector3.new(-p[1],p[3]-18,p[2]+3))
	end
	local function place(p)
		humanoid:Move(Vector3.zero)
		root.CFrame = CFrame.new(world(p) + Vector3.new(0, lift + 0.15, 0))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		task.wait(0.45)
		return humanoid.FloorMaterial ~= Enum.Material.Air
	end
	local function walk(p, jump, timeout)
		local target, began, airborne = world(p), os.clock(), false
		if jump then humanoid.Jump = true end
		while os.clock() - began < timeout do
			local d = target - root.Position
			local flat = Vector3.new(d.X, 0, d.Z)
			if humanoid.FloorMaterial == Enum.Material.Air then airborne = true end
			if flat.Magnitude < 0.8 and math.abs(root.Position.Y - lift - target.Y) < 0.65 and humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid:Move(Vector3.zero)
				return true, airborne
			end
			humanoid:Move(if flat.Magnitude < 0.25 then Vector3.zero else flat.Unit, false)
			game:GetService("RunService").Heartbeat:Wait()
		end
		humanoid:Move(Vector3.zero)
		return false, airborne
	end
	local records = {}
	local ok, failure = xpcall(function()
		local routes = {
			{ name = "BottomDescentAndLeftTurn", points = {{0,-10,18},{0,-39,0},{-12,-39,0},{-25,-29,0}} },
			{ name = "BottomAscent", points = {{0,-36,0},{0,-10,18}} },
			{ name = "LowerOpenForecourt", points = {{-40,-40,0},{0,-40,0},{40,-40,0}} },
			{ name = "InnerRecordsLeft", points = {{-25,-29,0},{-25,17,0}} },
			{ name = "InnerRecordsRight", points = {{25,-29,0},{25,17,0}} },
		}
		for _, side in if lowerOnly then {} else {-1,1} do
			table.insert(routes, {name = "ShopStair" .. side, points = {{side*37,-17,18},{side*37,21,38},{side*29,21,38},{0,21,38},{0,42,38}}})
		end
		for _, route in routes do
			local record = {name=route.name, groundedStart=place(route.points[1]), passed=true, waypoints={}}
			for index=2,#route.points do
				local passed = walk(route.points[index], false, 7)
				table.insert(record.waypoints, passed)
				if not passed then record.passed=false;break end
			end
			record.position = tostring(root.Position)
			table.insert(records,record)
		end
		if lowerOnly then return end
		local data = require(game.ServerStorage.CourseBuilders.LobbyBuilders.BlenderManifest)
		local points
		for _,tag in data.tags do if tag.kind=="practice" then points=tag.points end end
		for index=1,#points-1 do
			local from,to = table.clone(points[index]),points[index+1]
			local dx,dy=to[1]-from[1],to[2]-from[2]
			local distance=math.sqrt(dx*dx+dy*dy)
			from[1]+=dx/distance*1.1;from[2]+=dy/distance*1.1
			local grounded=place(from)
			local passed,airborne=walk(to,true,3)
			table.insert(records,{name="Practice"..index,groundedStart=grounded,passed=passed and airborne,airborne=airborne,position=tostring(root.Position)})
		end
	end,debug.traceback)
	rig:Destroy()
	if not ok then error(failure) end
	return {revision=workspace.Lobby:GetAttribute("BlenderRevision"),walkSpeed=settings.WalkSpeed,jumpHeight=settings.JumpHeight,records=records}
end

return Test
