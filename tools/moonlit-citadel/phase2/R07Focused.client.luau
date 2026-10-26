--!nonstrict
assert(game.RunService:IsStudio() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local P,H,R = game.Players.LocalPlayer,game.HttpService,game.RunService
local character = P.Character
local body, humanoid = character.HumanoidRootPart,character:FindFirstChildOfClass('Humanoid')
local course = workspace.RaceCourse
assert(course:GetAttribute('CandidateId') == 'MC_P2_C01_R07')
local folder = Instance.new('Folder');folder.Name,folder.Parent = 'R07FocusedResult',P.PlayerGui
local report = {candidate='MC_P2_C01_R07',scope='Focused physical cases; initial placement only; no full-route or pacing claim',cases={}}
local function progress() return H:JSONDecode(P:GetAttribute('MCPhase2Progress') or '{}') end
local function resolve(path)
	local item = course
	for name in path:gmatch('[^/]+') do item = assert(item:FindFirstChild(name),path) end
	return item
end
local function xyz(v) return {v.X,v.Y,v.Z} end
local goal, jumping, connection
local key = 'R07OwnedFocusedMovement'
R:BindToRenderStep(key,Enum.RenderPriority.Input.Value+1,function()
	humanoid.Jump = jumping == true
	if not goal then humanoid:Move(Vector3.zero,false);return end
	local delta = Vector3.new(goal.X-body.Position.X,0,goal.Z-body.Position.Z)
	humanoid:Move(if delta.Magnitude>.18 then delta.Unit*math.min(1,delta.Magnitude/.6) else Vector3.zero,false)
end)
local function run(name,path,points,jumpIndex,expectRecovery,allowFall)
	local support = resolve(path)
	local frame = support.CFrame*CFrame.new(0,support.Size.Y/2,0)
	local before = progress()
	local entry = {name=name,supportPath=support:GetFullName(),before=before,initialPlacementOnly=true,samples={},jumpRequests=0}
	report.cases[#report.cases+1]=entry
	body.Anchored=false
	humanoid.WalkSpeed,humanoid.UseJumpPower,humanoid.JumpHeight,humanoid.MaxSlopeAngle = 16,false,7.2,45
	character:PivotTo(frame*CFrame.new(points[1]+Vector3.new(0,humanoid.HipHeight+body.Size.Y/2+.2,0)))
	body.AssemblyLinearVelocity,body.AssemblyAngularVelocity = Vector3.zero,Vector3.zero
	goal,jumping=nil,false
	task.wait(.35)
	entry.profile = {rig=humanoid.RigType.Name,speed=humanoid.WalkSpeed,height=humanoid.JumpHeight,gravity=workspace.Gravity}
	local started = os.clock()
	for index=2,#points do
		goal=frame:PointToWorldSpace(points[index])
		if jumpIndex==index then jumping=true;entry.jumpRequests+=1 end
		local deadline = os.clock()+3
		repeat
			if jumping and humanoid.FloorMaterial==Enum.Material.Air and body.AssemblyLinearVelocity.Y>1 then jumping=false end
			entry.samples[#entry.samples+1]={at=workspace:GetServerTimeNow(),p=xyz(body.Position),v=xyz(body.AssemblyLinearVelocity),ground=humanoid.FloorMaterial.Name,falls=progress().falls}
			if (progress().falls or 0)>(before.falls or 0) then break end
			if Vector3.new(goal.X-body.Position.X,0,goal.Z-body.Position.Z).Magnitude<.25 then break end
			task.wait(.05)
		until os.clock()>deadline
		if (progress().falls or 0)>(before.falls or 0) then break end
	end
	entry.targetDistance=goal and Vector3.new(goal.X-body.Position.X,0,goal.Z-body.Position.Z).Magnitude or 0
	goal,jumping=nil,false
	task.wait(if allowFall then 2 else .5)
	entry.after,entry.elapsed=progress(),os.clock()-started
	entry.recovered=(entry.after.falls or 0)>(before.falls or 0)
	entry.ground=humanoid.FloorMaterial.Name
	entry.reached=entry.targetDistance<.25
	entry.ok=if expectRecovery then entry.recovered else not entry.recovered and entry.ground~='Air' and entry.reached
	folder:SetAttribute('Latest',H:JSONEncode(entry))
	task.wait(if entry.recovered then 1.3 else .2)
end
local ok,failure=xpcall(function()
	run('HurdleJump','Obstacles/Gate/Causeway_3_1/Contact',{Vector3.new(0,0,3.6),Vector3.new(0,0,-3.6)},2,false)
	run('HurdleGroundedControl','Obstacles/Gate/Causeway_3_1/Contact',{Vector3.new(0,0,3.6),Vector3.new(0,0,-3.6)},nil,true)
	run('WeaveCentreControl','Obstacles/SharedArches/Causeway_3_1/Contact',{Vector3.new(0,0,10),Vector3.new(0,0,-10)},nil,true)
	run('WeaveCorrectPass','Obstacles/SharedArches/Causeway_3_1/Contact',{Vector3.new(1.25,0,9.7),Vector3.new(1.25,0,3.3),Vector3.new(-1.25,0,-3.3),Vector3.new(-1.25,0,-9.7)},nil,false)
	run('ExpertPostLiftGate','Obstacles/UpperExpertExit/PostLiftTurn/Contact',{Vector3.new(-3.6,0,1.25),Vector3.new(3.6,0,1.25)},nil,false)
	run('ExpertMirrorPostLiftGate','Obstacles/UpperExpertExitMirror/PostLiftTurn/Contact',{Vector3.new(3.6,0,1.25),Vector3.new(-3.6,0,1.25)},nil,false)
	run('InvisibleSkyFall','Obstacles/Gate/GateCourt/Contact',{Vector3.new(0,0,13),Vector3.new(0,0,25)},nil,true,true)
end,debug.traceback)
goal,jumping=nil,false
R:UnbindFromRenderStep(key)
humanoid.Jump=false;humanoid:Move(Vector3.zero,false)
report.ok,report.failure=ok,if ok then nil else failure
folder:SetAttribute('Report',H:JSONEncode(report));folder:SetAttribute('Complete',true)
