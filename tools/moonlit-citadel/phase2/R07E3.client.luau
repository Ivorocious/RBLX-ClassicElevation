--!nonstrict
assert(game.RunService:IsStudio() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local P,H,R = game.Players.LocalPlayer,game.HttpService,game.RunService
local character = P.Character
local body, humanoid = character.HumanoidRootPart,character:FindFirstChildOfClass('Humanoid')
local course = workspace.RaceCourse
assert(course:GetAttribute('CandidateId') == 'MC_P2_C01_R07')
local folder = Instance.new('Folder');folder.Name,folder.Parent = 'R07E3Result',P.PlayerGui
local report = {candidate='MC_P2_C01_R07',scope='Both Expert brace/upper ride/exit routes; initial placement only. This is not a full-course finish or human pacing claim.',cases={}}
local function progress() return H:JSONDecode(P:GetAttribute('MCPhase2Progress') or '{}') end
local function xyz(v) return {v.X,v.Y,v.Z} end
local function resolve(path)
	local item = course
	for name in path:gmatch('[^/]+') do item = assert(item:FindFirstChild(name),path) end
	return item
end
local function vector(encoded) return if encoded then Vector3.new(table.unpack(encoded.value)) else Vector3.zero end
local function top(part,offset) return part.CFrame:PointToWorldSpace((offset or Vector3.zero)+Vector3.new(0,part.Size.Y/2,0)) end
local function support()
	if humanoid.FloorMaterial==Enum.Material.Air then return nil end
	local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Exclude;p.FilterDescendantsInstances={character};p.RespectCanCollide=true
	local hit=workspace:Raycast(body.Position,Vector3.new(0,-(humanoid.HipHeight+body.Size.Y/2+1.1),0),p)
	return hit and hit.Normal.Y>.7 and hit.Instance or nil,hit and hit.Position
end
local function grounded(expected)
	local hit,point=support()
	if hit==expected then return true end
	if not hit or expected.Name=='Deck' or not hit:GetAttribute('MCWalkable') then return false end
	local p=expected.CFrame:PointToObjectSpace(point)
	return math.abs(p.X)<=expected.Size.X/2+.4 and math.abs(p.Z)<=expected.Size.Z/2+.4 and math.abs(p.Y-expected.Size.Y/2)<=.65
end
local goal,jumping,current
local key='R07OwnedE3Movement'
R:BindToRenderStep(key,Enum.RenderPriority.Input.Value+1,function()
	humanoid.Jump=jumping==true
	if not goal then humanoid:Move(Vector3.zero,false);return end
	local target=goal()
	local delta=Vector3.new(target.X-body.Position.X,0,target.Z-body.Position.Z)
	humanoid:Move(if delta.Magnitude>.18 then delta.Unit*math.min(1,delta.Magnitude/.6) else Vector3.zero,false)
end)
local function sample(name,expected)
	local hit=support()
	current.steps[#current.steps+1]={name=name,at=workspace:GetServerTimeNow(),p=xyz(body.Position),v=xyz(body.AssemblyLinearVelocity),ground=humanoid.FloorMaterial.Name,support=hit and hit:GetFullName(),expected=expected and expected:GetFullName(),actualExpectedSupport=expected and grounded(expected)}
end
local function await(name,test,seconds)
	local deadline=os.clock()+seconds
	folder:SetAttribute('CurrentStep',name)
	repeat
		local p=progress()
		assert(p.raceState=='Racing' and p.status=='Racing','Actual race stopped')
		assert(p.falls==current.before.falls,'Actual recovery interrupted E3')
		if test() then return end
		task.wait(.025)
	until os.clock()>deadline
	error('Timed out '..name)
end
local function quiet(name)
	goal,jumping=nil,false;humanoid.Jump=false;humanoid:Move(Vector3.zero,false)
	local began,stable=os.clock(),nil
	await(name..'QuietLaunch',function()
		local v=body.AssemblyLinearVelocity
		local floor=support();assert(floor,'Quiet launch lost actual support')
		local moving=floor.Name=='Deck' and floor:IsDescendantOf(course.Obstacles.MovingCars)
		if Vector3.new(v.X,0,v.Z).Magnitude<.25 and (moving or math.abs(v.Y)<1) then stable=stable or os.clock() else stable=nil end
		return os.clock()-began>=.35 and stable and os.clock()-stable>=.1
	end,1.2)
	sample(name..'SupportedQuiet')
end
local function move(part,offset,name,jump)
	if jump then quiet(name);sample(name..'Takeoff');current.jumpRequests+=1 end
	goal=function()return top(part,offset)end
	if jump then
		jumping=true
		await(name..'PositiveTakeoff',function()return humanoid.FloorMaterial==Enum.Material.Air and body.AssemblyLinearVelocity.Y>1 end,.8)
		sample(name..'Airborne');jumping=false;humanoid.Jump=false
	end
	await(name..'SupportedArrival',function()
		local t=goal();return Vector3.new(t.X-body.Position.X,0,t.Z-body.Position.Z).Magnitude<.25 and grounded(part)
	end,5)
	goal,jumping=nil,false;humanoid.Jump=false;humanoid:Move(Vector3.zero,false)
	sample(name..'Arrived',part)
end
local function ride(node)
	local deck,waitPart=resolve(node.path),resolve(node.waitPath)
	move(waitPart,vector(node.waitOffset),node.name..'Wait')
	local last=top(deck).Y
	await(node.name..'UpwardBoardingWindow',function()
		assert(grounded(waitPart),'Boarding wait lost support')
		local y=top(deck).Y;local d=y-last;last=y
		return math.abs(y-node.boardHeight)<=node.boardHeightTolerance and d>=-.02
	end,30)
	move(deck,vector(node.board),node.name..'Board',true)
	local began=os.clock()
	await(node.name..'ActualCarryToExit',function()assert(support()==deck,'Actual lift support lost');return top(deck).Y>=node.exitHeight-.4 end,20)
	current.ride={deck=deck:GetFullName(),seconds=os.clock()-began,exitDeckY=top(deck).Y,actualDeckSupport=true}
	move(deck,vector(node.exitTakeoff),node.name..'ExitTakeoff')
	move(resolve(node.exitPath),vector(node.exitOffset),node.name..'EarlyExit',true)
end
local ok,failure=xpcall(function()
	for _,case in R07_E3_CASES do
		current={name=case.name,before=progress(),steps={},jumpRequests=0,initialPlacementOnly=true};report.cases[#report.cases+1]=current
		body.Anchored=false;humanoid.WalkSpeed,humanoid.UseJumpPower,humanoid.JumpHeight,humanoid.MaxSlopeAngle=16,false,7.2,45
		local first=case.route[1];local floor=resolve(first.path)
		character:PivotTo(CFrame.new(top(floor,vector(first.offset))+Vector3.new(0,humanoid.HipHeight+body.Size.Y/2+.2,0)))
		body.AssemblyLinearVelocity,body.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
		goal,jumping=nil,false;task.wait(.4)
		current.profile={rig=humanoid.RigType.Name,speed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight,gravity=workspace.Gravity}
		for _,node in case.route do
			if node.kind=='Ride' then ride(node) else move(resolve(node.path),vector(node.offset),node.name,node.kind=='Jump') end
		end
		current.after,current.complete=progress(),true
		folder:SetAttribute('CompletedCases',#report.cases)
	end
end,debug.traceback)
goal,jumping=nil,false;R:UnbindFromRenderStep(key);humanoid.Jump=false;humanoid:Move(Vector3.zero,false)
report.ok,report.failure=ok,if ok then nil else failure
folder:SetAttribute('Report',H:JSONEncode(report));folder:SetAttribute('Complete',true)
