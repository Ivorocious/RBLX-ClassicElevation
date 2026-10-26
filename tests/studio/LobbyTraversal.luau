-- Run in a temporary Server Play ModuleScript; results use an R15 physics fixture.
local Test = {}

function Test.Run()
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsRunning(), "Studio Play required")
	local players=game:GetService("Players")
	local heartbeat=game:GetService("RunService").Heartbeat
	local center=require(game.ReplicatedStorage.Config.LobbyConfig).Center
	local lobby=workspace.Lobby
	local description=Instance.new("HumanoidDescription")
	local rig=players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name="LobbyTraversalFixture"
	rig.Parent=workspace
	local humanoid=rig:FindFirstChildOfClass("Humanoid")
	local root=rig.HumanoidRootPart
	local player=players:GetPlayers()[1]
	local playerHumanoid=player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	assert(playerHumanoid,"A spawned player is required to copy the actual movement settings")
	humanoid.WalkSpeed=playerHumanoid.WalkSpeed
	humanoid.UseJumpPower=playerHumanoid.UseJumpPower
	humanoid.JumpHeight=playerHumanoid.JumpHeight
	humanoid.JumpPower=playerHumanoid.JumpPower
	local movement={walkSpeed=humanoid.WalkSpeed,useJumpPower=humanoid.UseJumpPower,jumpHeight=humanoid.JumpHeight,jumpPower=humanoid.JumpPower}
	root:SetNetworkOwner(nil)
	local height=humanoid.HipHeight+root.Size.Y/2
	local records={}
	local function place(foot)
		humanoid:Move(Vector3.zero)
		root.CFrame=CFrame.new(foot+Vector3.new(0,height+.15,0))
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		task.wait(.5)
		return humanoid.FloorMaterial~=Enum.Material.Air
	end
	local function moveTo(foot, jump, seconds)
		local began=os.clock()
		local airborne=false
		if jump then humanoid.Jump=true end
		while os.clock()-began<seconds do
			local delta=foot-root.Position
			local horizontal=Vector3.new(delta.X,0,delta.Z)
			if humanoid.FloorMaterial==Enum.Material.Air then airborne=true end
			local near=horizontal.Magnitude<1.5
			humanoid:Move(if near then Vector3.zero else horizontal.Unit,false)
			if near and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.Position.Y-height-foot.Y)<1 then
				humanoid:Move(Vector3.zero)
				return true,airborne,os.clock()-began
			end
			heartbeat:Wait()
		end
		humanoid:Move(Vector3.zero)
		return false,airborne,os.clock()-began
	end
	local ok,failure=xpcall(function()
		for _,stair in lobby.Stairs:GetChildren() do
			local steps={}
			for _,part in stair:GetChildren() do if part:IsA("BasePart") and part.Name:match("^Step_") then table.insert(steps,part) end end
			table.sort(steps,function(a,b)return a.Position.Y<b.Position.Y end)
			local first,last=steps[1],steps[#steps]
			local start=Vector3.new(first.Position.X,first.Position.Y+first.Size.Y/2-.7,first.Position.Z-first.Size.Z/2-1.5)
			local finish=Vector3.new(last.Position.X,last.Position.Y+last.Size.Y/2,last.Position.Z+last.Size.Z/2+1.5)
			for _,direction in ipairs({"up","down"}) do
				local from,to=if direction=="up" then start else finish,if direction=="up" then finish else start
				local grounded=place(from)
				local passed,airborne,elapsed=moveTo(to,false,8)
				table.insert(records,{name=stair.Name.."_"..direction,passed=passed,groundedStart=grounded,airborne=airborne,seconds=elapsed,position=tostring(root.Position)})
			end
		end
		local jumps=lobby.Architecture["02_Arrival"].PracticeRoom.JumpingCourse
		for i=1,8 do
			local a=jumps[string.format("Jump_%02d",i)]
			local b=jumps[string.format("Jump_%02d",i+1)]
			local direction=Vector3.new(b.Position.X-a.Position.X,0,b.Position.Z-a.Position.Z).Unit
			local from=a.Position+Vector3.new(0,a.Size.Y/2+.12,0)+direction*1.4
			local to=b.Position+Vector3.new(0,b.Size.Y/2+.12,0)
			local grounded=place(from)
			local passed,airborne,elapsed=moveTo(to,true,2.5)
			table.insert(records,{name=string.format("Practice_%02d_%02d",i,i+1),passed=passed and airborne,groundedStart=grounded,airborne=airborne,seconds=elapsed,position=tostring(root.Position)})
		end
	end,debug.traceback)
	rig:Destroy()
	if not ok then error(failure) end
	return {movement=movement,records=records}
end

return Test
