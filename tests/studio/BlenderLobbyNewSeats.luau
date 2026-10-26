local Test = {}

function Test.Run()
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsRunning(), "Studio Play required")
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name, rig.Parent = "B09SeatFixture", workspace
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local root = rig.HumanoidRootPart
	root:SetNetworkOwner(nil)
	local records = {}
	local ok, failure = xpcall(function()
		for _, side in {-1, 1} do
			local bench = workspace.Lobby.Editable["01_Lower"]["Lower_SocialBench_" .. side]
			for _, seat in bench:GetDescendants() do
				if not seat:IsA("Seat") then continue end
				rig:PivotTo(seat.CFrame + Vector3.new(0, 3, 0))
				root.AssemblyLinearVelocity = Vector3.zero
				seat:Sit(humanoid)
				task.wait(.2)
				table.insert(records, {name=bench.Name .. "/" .. seat.Name, passed=seat.Occupant==humanoid and humanoid.SeatPart==seat, inward=seat.CFrame.LookVector:Dot(Vector3.new(side,0,0))>.99})
				humanoid.Sit = false
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				task.wait(.2)
			end
		end
	end, debug.traceback)
	rig:Destroy()
	if not ok then error(failure) end
	assert(#records==4, "Expected four added seats")
	return {revision=workspace.Lobby:GetAttribute("BlenderRevision"), records=records}
end

return Test
