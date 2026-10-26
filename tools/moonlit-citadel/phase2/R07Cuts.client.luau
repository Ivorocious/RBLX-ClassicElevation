--!nonstrict
assert(game.RunService:IsStudio() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local player, run, http = game.Players.LocalPlayer, game.RunService, game.HttpService
local character = player.Character
local body, humanoid = character.HumanoidRootPart, character:FindFirstChildOfClass('Humanoid')
local course, origin = workspace.RaceCourse, Vector3.new(4000,300,2600)
assert(course:GetAttribute('CandidateId') == 'MC_P2_C01_R07')
local folder = Instance.new('Folder'); folder.Name, folder.Parent = 'R07CutsResult', player.PlayerGui
local report = {candidate='MC_P2_C01_R07', scope='Four ordinary single-jump shortcut attempts; initial placement only; no claim that every skilled phase cut is impossible', cases={}}
local function progress() return http:JSONDecode(player:GetAttribute('MCPhase2Progress')) end
local function resolve(path)
	local item = course
	for name in path:gmatch('[^/]+') do item = assert(item:FindFirstChild(name),path) end
	return item
end
local function support()
	if humanoid.FloorMaterial==Enum.Material.Air then return nil end
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character};params.RespectCanCollide=true
	local hit=workspace:Raycast(body.Position,Vector3.new(0,-(humanoid.HipHeight+body.Size.Y/2+1.1),0),params)
	return hit and hit.Normal.Y>.7 and hit.Instance
end
local function xyz(v) return {v.X,v.Y,v.Z} end
local goal, jumping
local key='R07OwnedShortcutMovement'
run:BindToRenderStep(key,Enum.RenderPriority.Input.Value+1,function()
	humanoid.Jump=jumping==true
	local target=goal and goal()
	local delta=target and Vector3.new(target.X-body.Position.X,0,target.Z-body.Position.Z)
	humanoid:Move(if delta and delta.Magnitude>.18 then delta.Unit else Vector3.zero,false)
end)
local function attempt(name, path, start, targetPath, targetOffset, corner, lowCar)
	local floor, target=resolve(path),resolve(targetPath)
	local before=progress();assert(before.raceState=='Racing')
	local entry={name=name,before=before,initialPlacementOnly=true,samples={}}
	table.insert(report.cases,entry);folder:SetAttribute('CurrentCase',name)
	goal,jumping=nil,false
	humanoid.WalkSpeed,humanoid.UseJumpPower,humanoid.JumpHeight,humanoid.MaxSlopeAngle=16,false,7.2,45
	character:PivotTo(CFrame.new(origin+start+Vector3.new(0,humanoid.HipHeight+body.Size.Y/2+.2,0)))
	body.AssemblyLinearVelocity,body.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
	task.wait(.4);assert(support()==floor,'Initial floor support missing')
	if lowCar then
		local deadline=os.clock()+30
		repeat
			assert(progress().raceState=='Racing' and support()==floor,'Corner wait lost supported race')
			if target.Position.Y+target.Size.Y/2<=406.15 then break end
			task.wait(.05)
		until os.clock()>deadline
		assert(target.Position.Y+target.Size.Y/2<=406.15,'Actual low dwell absent')
	end
	entry.profile={rig=humanoid.RigType.Name,speed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight,gravity=workspace.Gravity}
	entry.launchSupport=support():GetFullName();entry.deckYAtLaunch=target.Position.Y+target.Size.Y/2
	local started=os.clock();jumping=true
	goal=function()
		if corner and os.clock()-started<.35 then return origin+corner end
		return target.CFrame:PointToWorldSpace(targetOffset+Vector3.new(0,target.Size.Y/2,0))
	end
	local airborne, landedTarget=false,false
	repeat
		local hit=support();local p=progress()
		assert(p.raceState=='Racing','Actual race stopped')
		if humanoid.FloorMaterial==Enum.Material.Air and body.AssemblyLinearVelocity.Y>1 then airborne=true;jumping=false end
		if hit==target then landedTarget=true end
		entry.samples[#entry.samples+1]={at=workspace:GetServerTimeNow(),p=xyz(body.Position),v=xyz(body.AssemblyLinearVelocity),ground=humanoid.FloorMaterial.Name,support=hit and hit:GetFullName(),falls=p.falls}
		if (p.falls or 0)>(before.falls or 0) then break end
		task.wait(.05)
	until os.clock()-started>2.2
	goal,jumping=nil,false;humanoid.Jump=false;humanoid:Move(Vector3.zero,false)
	entry.after=progress();entry.actualPositiveTakeoff=airborne;entry.actualTargetSupport=landedTarget
	entry.ok=airborne and not landedTarget and entry.after.checkpoint==before.checkpoint
	folder:SetAttribute('Latest',http:JSONEncode(entry));task.wait(.6)
end
local ok,failure=xpcall(function()
	attempt('UpperBay2CornerCut','Obstacles/Lifts/CP04Terrace/Contact',Vector3.new(99.35,106,-24.65),'Obstacles/MovingCars/Upper_Bay2/Deck',Vector3.new(6.35,0,5.35),Vector3.new(101.1,106,-28.5),true)
	attempt('UpperBay1CornerCut','Obstacles/Lifts/CP04Terrace/Contact',Vector3.new(52.65,106,-24.65),'Obstacles/MovingCars/Upper_Bay1/Deck',Vector3.new(-6.35,0,5.35),Vector3.new(50.9,106,-28.5),true)
	attempt('BraceStep1To3','Obstacles/UpperBrace/BraceStep1/Contact',Vector3.new(104.85,110,-14.35),'Obstacles/UpperBrace/BraceStep3/Contact',Vector3.new(-1.6,0,1.85))
	attempt('MirrorBraceStep1To3','Obstacles/UpperBraceMirror/BraceStep1/Contact',Vector3.new(47.15,110,-14.35),'Obstacles/UpperBraceMirror/BraceStep3/Contact',Vector3.new(1.6,0,1.85))
end,debug.traceback)
goal,jumping=nil,false;run:UnbindFromRenderStep(key);humanoid.Jump=false;humanoid:Move(Vector3.zero,false)
report.ok,report.failure=ok,if ok then nil else failure
folder:SetAttribute('Report',http:JSONEncode(report));folder:SetAttribute('Complete',true)
