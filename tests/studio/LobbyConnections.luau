-- Run in Studio Play to check the turns between stair landings and their rooms.
local Test = {}

function Test.Run()
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsRunning(),"Studio Play required")
	local description=Instance.new("HumanoidDescription")
	local rig=game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name="LobbyConnectionsFixture"
	rig.Parent=workspace
	local h=rig:FindFirstChildOfClass("Humanoid")
	local root=rig.HumanoidRootPart
	root:SetNetworkOwner(nil)
	h.WalkSpeed=16
	local lift=h.HipHeight+root.Size.Y/2
	local origin=require(game.ReplicatedStorage.Config.LobbyConfig).Center
	local results={}
	local function walk(localFoot)
		local target=origin+localFoot
		local started=os.clock()
		while os.clock()-started<4 do
			local d=target-root.Position
			local flat=Vector3.new(d.X,0,d.Z)
			if flat.Magnitude<.85 and math.abs(root.Position.Y-lift-target.Y)<1 then h:Move(Vector3.zero);return true end
			h:Move(if flat.Magnitude<.2 then Vector3.zero else flat.Unit,false)
			game:GetService("RunService").Heartbeat:Wait()
		end
		h:Move(Vector3.zero)
		return false
	end
	local ok,failure=xpcall(function()
		for _,side in ipairs({-1,1}) do
			for _,kind in ipairs({"Shop","Roof"}) do
				local points=if kind=="Shop"
					then {Vector3.new(side*42,40,25),Vector3.new(side*46,40,24.5),Vector3.new(side*46,40,32),Vector3.new(side*22,40,24)}
					else {Vector3.new(side*33,58,36.5),Vector3.new(side*22,58,38),Vector3.new(side*20,58,30),Vector3.new(side*20,58,12),Vector3.new(0,58,10)}
				root.CFrame=CFrame.new(origin+points[1]+Vector3.new(0,lift+.15,0))
				root.AssemblyLinearVelocity=Vector3.zero
				task.wait(.4)
				local record={name=(if side<0 then "Left" else "Right")..kind.."Entrance",groundedStart=h.FloorMaterial~=Enum.Material.Air,passed=true,waypoints={}}
				for i=2,#points do local passed=walk(points[i]);table.insert(record.waypoints,passed);if not passed then record.passed=false;break end end
				record.position=tostring(root.Position)
				table.insert(results,record)
			end
		end
	end,debug.traceback)
	rig:Destroy()
	if not ok then error(failure) end
	return results
end

return Test
