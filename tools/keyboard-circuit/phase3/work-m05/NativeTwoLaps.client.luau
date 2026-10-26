assert(game:GetService("RunService"):IsClient())
local player = game.Players.LocalPlayer
local course = assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CourseId") == "keyboard_circuit")
local Run = game:GetService("RunService")
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
local report = {passed=false, boundary="Owned Studio fixture using staged character placements and ordinary humanoid movement at the finish; verifies shared progression and recovery, not a human traversal time.", checkpoints={}, recoveries={}, laps={}, startedAt=os.clock()}
shared.KCM05NativeTwoLaps = report
local function body()
	local character = assert(player.Character)
	return character, assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
end
local function place(frame)
	local character, root, humanoid = body()
	humanoid:Move(Vector3.zero, false)
	character:PivotTo(frame)
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
end
local function labels()
	local out = {}
	for _,item in player.PlayerGui.RaceHUD:GetDescendants() do if item:IsA("TextLabel") then out[item.Name]=item.Text end end
	return out
end
local function waitFor(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat if predicate() then return true end; Run.Heartbeat:Wait() until os.clock() >= deadline
	return false
end
local function checkpoint(index)
	local part = course.Checkpoints[string.format("Checkpoint_%03d",index)]
	local pad = course.Checkpoints.RecoveryPads[part:GetAttribute("RecoveryGate")].BankContact
	place(part:GetAttribute("RespawnCFrame"))
	assert(waitFor(function() return labels().Checkpoints == "Checkpoints: " .. index .. " / 8" end, 3), "Checkpoint failed: " .. index)
	table.insert(report.checkpoints, {index=index, pose=tostring(select(2,body()).Position), label=labels().Checkpoints})
	return part, pad
end
local function finish()
	local gate = course.Finish
	local _, root, humanoid = body()
	local height = root.Position.Y - gate.Position.Y
	local entry = gate.CFrame * CFrame.new(0,math.clamp(height,-1,1),2.5)
	place(entry)
	local target = gate.Position + gate.CFrame.LookVector * 4
	local before = labels().Lap
	local deadline = os.clock() + 2
	Run:BindToRenderStep("KCM05Finish", Enum.RenderPriority.Character.Value+1, function()
		local _, liveRoot, liveHumanoid = body()
		local delta = Vector3.new(target.X-liveRoot.Position.X,0,target.Z-liveRoot.Position.Z)
		liveHumanoid:Move(if delta.Magnitude>.1 then delta.Unit else Vector3.zero,false)
	end)
	while os.clock() < deadline do
		if labels().Lap ~= before or labels().Status == "Status: Finished" then break end
		Run.Heartbeat:Wait()
	end
	Run:UnbindFromRenderStep("KCM05Finish")
	select(3,body()):Move(Vector3.zero,false)
end
for lap = 1,2 do
	for index=1,8 do
		local part, pad = checkpoint(index)
		if lap == 1 then
			local _,root = body()
			local falls = labels().Falls
			local floor = course.FallZones.FallZone_Main
			place(CFrame.new(root.Position.X, floor.Position.Y, root.Position.Z))
			assert(waitFor(function() return labels().Falls ~= falls end,3), "Fall was not recovered")
			assert(waitFor(function()
				local point = pad.CFrame:PointToObjectSpace(select(2,body()).Position)
				return math.abs(point.X) < pad.Size.X/2 and math.abs(point.Z) < pad.Size.Z/2 and point.Y > 2 and point.Y < 8
			end,3), "Recovery pose is outside its bank")
			task.wait(.2)
			local _, liveRoot = body()
			local hit = workspace:Raycast(liveRoot.Position,Vector3.new(0,-9,0),ray)
			assert(hit and hit.Instance:IsDescendantOf(course), "Recovery has no physical support")
			table.insert(report.recoveries,{index=index,position=tostring(liveRoot.Position),support=hit.Instance:GetFullName(),falls=labels().Falls})
			task.wait(1.1)
		end
	end
	finish()
	assert(waitFor(function() return (lap==1 and labels().Lap=="Lap: 2 / 2" and labels().Checkpoints=="Checkpoints: 0 / 8") or (lap==2 and labels().Status=="Status: Finished") end,3), "Lap finish failed: " .. lap)
	table.insert(report.laps,labels())
end
report.finishedAt, report.elapsed = os.clock(), os.clock()-report.startedAt
report.passed=true
return game.HttpService:JSONEncode(report)
