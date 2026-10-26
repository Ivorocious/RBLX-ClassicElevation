local Run = game:GetService("RunService")
assert(Run:IsStudio() and Run:IsClient())
local player = game.Players.LocalPlayer
local course = assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateRevision") == "KC_P3_M06_01")
local report = {active=true, passed=false, checkpoints={}, recoveries={}, jumps={}, laps={}, boundary="Staged setup between encounters; ordinary humanoid jumps on both Expert cuts and forward finish movement. This verifies checkpoint recognition and recovery, not whole-course traversal timing."}
shared.KCM06NativeExpert = report
local moveTarget = nil
local jumpRequested = false
local function body()
	local character = assert(player.Character)
	return character, assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
end
local function labels()
	local result = {}
	for _,item in player.PlayerGui.RaceHUD:GetDescendants() do if item:IsA("TextLabel") then result[item.Name]=item.Text end end
	return result
end
local function waitFor(test, seconds)
	local deadline = os.clock()+seconds
	repeat if test() then return true end; Run.Heartbeat:Wait() until os.clock()>=deadline
	return false
end
local function place(frame)
	moveTarget=nil
	jumpRequested=false
	local character,root,humanoid=body()
	humanoid:Move(Vector3.zero,false)
	character:PivotTo(frame)
	root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
end
local function top(contact) return contact.CFrame:PointToWorldSpace(Vector3.new(0,contact.Size.Y/2,0)) end
local function checkpoint(index)
	local part=course.Checkpoints[string.format("Checkpoint_%03d",index)]
	place(part:GetAttribute("RespawnCFrame"))
	assert(waitFor(function() return labels().Checkpoints=="Checkpoints: "..index.." / 8" end,3),"Checkpoint "..index.." failed")
	table.insert(report.checkpoints,{index=index,path="Normal",label=labels().Checkpoints})
end
local function expert(id,index,fall)
	local route
	for _,item in course.Obstacles.ExpertRoutes:GetChildren() do if item:GetAttribute("ExpertId")==id then route=item end end
	assert(route)
	local primary=course.Checkpoints[string.format("Checkpoint_%03d",index)]
	local count=route:GetAttribute("PrecisionLandings")
	local first=route.PrecisionLanding1.KeyContact
	place(CFrame.new(top(first)+Vector3.new(0,3.05,0)))
	assert(waitFor(function() return labels().Checkpoints=="Checkpoints: "..index.." / 8" end,3),"Expert "..id.." did not register checkpoint")
	local localPosition=primary.CFrame:PointToObjectSpace(select(2,body()).Position)
	assert(math.abs(localPosition.X)>primary.Size.X/2+1 or math.abs(localPosition.Z)>primary.Size.Z/2+1,"Expert proof touched the Normal checkpoint")
	table.insert(report.checkpoints,{index=index,path=id,label=labels().Checkpoints,primaryLocal=tostring(localPosition)})
	if fall then
		local before=labels().Falls
		local point=select(2,body()).Position
		place(CFrame.new(point.X,course.FallZones.FallZone_Main.Position.Y,point.Z))
		assert(waitFor(function() return labels().Falls~=before end,3),"Expert fall not recovered")
		local bank=course.Checkpoints.RecoveryPads[primary:GetAttribute("RecoveryGate")].BankContact
		assert(waitFor(function()
			local p=bank.CFrame:PointToObjectSpace(select(2,body()).Position)
			return math.abs(p.X)<bank.Size.X/2 and math.abs(p.Z)<bank.Size.Z/2 and p.Y>2 and p.Y<8
		end,3),"Expert recovery missed permanent bank")
		table.insert(report.recoveries,{route=id,bank=primary:GetAttribute("RecoveryGate"),position=tostring(select(2,body()).Position)})
		task.wait(1.2)
		place(CFrame.new(top(first)+Vector3.new(0,3.05,0)))
	end
	for landing=2,count do
		assert(waitFor(function() return select(3,body()).FloorMaterial~=Enum.Material.Air and math.abs(select(2,body()).AssemblyLinearVelocity.Y)<2 end,2),"Expert takeoff has no support")
		local target=route["PrecisionLanding"..landing].KeyContact
		local expected=top(target)
		moveTarget=expected
		jumpRequested=true
		local began=os.clock()
		assert(waitFor(function()
			local _,root,humanoid=body()
			local p=target.CFrame:PointToObjectSpace(root.Position)
			return os.clock()-began>.25 and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(p.X)<target.Size.X/2+.15 and math.abs(p.Z)<target.Size.Z/2+.15 and p.Y>2 and p.Y<5
		end,2),"Expert jump failed at "..id.."/"..landing)
		moveTarget=nil
		table.insert(report.jumps,{route=id,landing=landing,position=tostring(select(2,body()).Position)})
	end
end
local function finish()
	local gate=course.Finish
	place(gate.CFrame*CFrame.new(0,0,2.5))
	local previous=labels().Lap
	moveTarget=gate.Position+gate.CFrame.LookVector*4
	assert(waitFor(function() return labels().Lap~=previous or labels().Status=="Status: Finished" end,3),"Forward finish failed")
	moveTarget=nil
end
Run:BindToRenderStep("KCM06ExpertMovement",Enum.RenderPriority.Character.Value+1,function()
	local _,root,humanoid=body()
	if jumpRequested then
		humanoid.Jump=true
		if humanoid.FloorMaterial==Enum.Material.Air then jumpRequested=false end
	end
	local delta=moveTarget and Vector3.new(moveTarget.X-root.Position.X,0,moveTarget.Z-root.Position.Z)
	humanoid:Move(if delta and delta.Magnitude>.1 then delta.Unit else Vector3.zero,false)
end)
task.spawn(function()
	local ok,failure=xpcall(function()
		for lap=1,2 do
			expert("X03",1,lap==1)
			for index=2,4 do checkpoint(index) end
			expert("X02",5,lap==1)
			for index=6,8 do checkpoint(index) end
			finish()
			assert(waitFor(function() return (lap==1 and labels().Lap=="Lap: 2 / 2" and labels().Checkpoints=="Checkpoints: 0 / 8") or (lap==2 and labels().Status=="Status: Finished") end,3),"Wrong lap completion")
			table.insert(report.laps,labels())
		end
	end,debug.traceback)
	Run:UnbindFromRenderStep("KCM06ExpertMovement")
	select(3,body()):Move(Vector3.zero,false)
	report.active,report.passed,report.failure=false,ok,if ok then nil else tostring(failure)
end)
return {started=true,report="shared.KCM06NativeExpert"}
