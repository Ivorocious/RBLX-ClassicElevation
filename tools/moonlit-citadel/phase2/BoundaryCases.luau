--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local ForwardGate = require(game.ReplicatedStorage.Shared.ForwardGate)
local Cases = {}
local CANDIDATE, MARKER, ACTION = "MC_P2_C01_R04", "MoonlitBoundaryCases1", "MCPhase2BoundaryAction"
local current, clientCurrent
local bodyNames = {Head=true, UpperTorso=true, LowerTorso=true, LeftUpperArm=true, LeftLowerArm=true,
	LeftHand=true, RightUpperArm=true, RightLowerArm=true, RightHand=true, LeftUpperLeg=true,
	LeftLowerLeg=true, LeftFoot=true, RightUpperLeg=true, RightLowerLeg=true, RightFoot=true}
local profileNames = {"WalkSpeed", "UseJumpPower", "JumpHeight", "JumpPower", "MaxSlopeAngle"}
local function xyz(v) return {v.X,v.Y,v.Z} end
local function now() return workspace:GetServerTimeNow() end
local function terminal(state) return state == nil or state == "Complete" or state == "Failed" or state == "Observed" end
local function fixture(server)
	assert(RunService:IsStudio() and RunService:IsRunning() and game.PlaceId == 0 and game.GameId == 0, "Owned unpublished native Play fixture only")
	assert((server and RunService:IsServer()) or (not server and RunService:IsClient()), "Wrong native execution side")
	assert(Config.CandidateId == CANDIDATE, "Boundary cases belong to R04")
end
local function resolve(root,path)
	for name in path:gmatch("[^/]+") do root = assert(root:FindFirstChild(name), "Missing actual instance "..path) end
	return root
end
local function character(player)
	local model = assert(player.Character, "Actual Character absent")
	local root = assert(model:FindFirstChild("HumanoidRootPart"), "Actual root absent")
	local human = assert(model:FindFirstChildOfClass("Humanoid"), "Actual Humanoid absent")
	assert(human.RigType == Enum.HumanoidRigType.R15 and human.Health > 0 and not root.Anchored, "Living unanchored actual R15 required")
	return model,root,human
end
local function profile(human)
	local value = {}
	for _,name in profileNames do value[name] = human[name] end
	return value
end
local function equalProfile(a,b)
	for _,name in profileNames do if a[name] ~= b[name] then return false end end
	return true
end
local function configuredProfile(actual)
	for name,value in Config.Movement do
		if type(value)=="number" then
			assert(math.abs(actual[name]-value)<.00001,"Actual movement profile differs from Config")
		else assert(actual[name]==value,"Actual movement profile differs from Config") end
	end
end
local function bodyBounds(model, frame)
	local low, high = Vector3.one*math.huge, Vector3.one*-math.huge
	local bodies = {}
	for _,part in model:GetChildren() do
		if not part:IsA("BasePart") or (not bodyNames[part.Name] and part.Name ~= "HumanoidRootPart") then continue end
		if bodyNames[part.Name] and part.Transparency < 1 and part.CanQuery then table.insert(bodies,part) end
		for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
			local p = frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
			low = Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
			high = Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
		end end end
	end
	assert(#bodies == 15, "All fifteen actual visible queryable R15 body parts required")
	return low,high,bodies
end
local function overlap(part,bodies)
	local params = OverlapParams.new()
	params.FilterType,params.FilterDescendantsInstances = Enum.RaycastFilterType.Include,bodies
	local hits = {}
	for _,hit in workspace:GetPartsInPart(part,params) do table.insert(hits,hit.Name) end
	table.sort(hits)
	return hits
end
local function support(root,human)
	local params = RaycastParams.new()
	local excluded = {}
	for _,player in Players:GetPlayers() do if player.Character then table.insert(excluded,player.Character) end end
	params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide = Enum.RaycastFilterType.Exclude,excluded,true
	local ray = workspace:Raycast(root.Position,Vector3.new(0,-(human.HipHeight+root.Size.Y/2+2),0),params)
	return ray,ray and root.Position.Y-human.HipHeight-root.Size.Y/2-ray.Position.Y
end
local function place(player,part,offset)
	assert(part:IsA("BasePart") and part.CanCollide and part.CanQuery and part.CFrame.UpVector:Dot(Vector3.yAxis)>.999999, "Actual level collidable contact required")
	local model,root = character(player)
	local low,high = bodyBounds(model,root.CFrame)
	local minX,maxX = -part.Size.X/2-low.X+.375,part.Size.X/2-high.X-.375
	local minZ,maxZ = -part.Size.Z/2-low.Z+.375,part.Size.Z/2-high.Z-.375
	assert(minX<maxX and minZ<maxZ, "Actual avatar has no usable standing rectangle")
	assert(offset.X>=minX and offset.X<=maxX and offset.Z>=minZ and offset.Z<=maxZ and offset.Y==0, "Measured body exceeds contact edge margin")
	local target = part.CFrame*CFrame.new(offset.X,part.Size.Y/2-low.Y+.08,offset.Z)
	model:PivotTo(target*root.CFrame:Inverse()*model:GetPivot())
	root.AssemblyLinearVelocity,root.AssemblyAngularVelocity = Vector3.zero,Vector3.zero
	return {bodyLow=xyz(low),bodyHigh=xyz(high),minX=minX,maxX=maxX,minZ=minZ,maxZ=maxZ,
		actualContact=part:GetFullName(),actualSize=xyz(part.Size),edgeMargin=.375,rootTarget=xyz(target.Position)}
end
local function progress(player,services,course,replacement)
	local encoded = player:GetAttribute("MCPhase2Progress")
	assert(type(encoded)=="string", "Keep the actual ServerProbe observer bridge running")
	local p = HttpService:JSONDecode(encoded)
	assert(p.source=="shared-services" and now()-p.observedAt<=1.5 and p.raceId==services.RaceService.GetCurrentRaceId(), "Stale or wrong shared observer bridge")
	local validReplacement=replacement and player.UserId==-1 and replacement.initialStaged==true
		and replacement.actualDied==true and replacement.actualCharacterChanged==true and replacement.raceId==p.raceId
		and p.characterSerial==replacement.initialCharacterSerial+1
	assert(p.candidate==CANDIDATE and p.coursePath==course:GetFullName() and p.courseId==Config.CourseId and p.official
		and p.status=="Racing" and p.raceState=="Racing" and (p.staged or validReplacement) and not p.finished, "Actual official staged Racing or verified death replacement required")
	assert(services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player)=="Racing"
		and services.CheckpointService.GetLatestCheckpointIndex(player)==p.checkpoint, "Authoritative progress disagrees")
	return p
end
function Cases.Preview()
	local names = {}
	for band=1,3 do
		for _,side in {"Before","After"} do table.insert(names,"NormalWait"..side..band) end
		table.insert(names,"ExpertBefore"..band)
	end
	for _,name in {"RedAdjacent","JumpDeparture","CP04Bypass","CrownBypass","StopStart","Restart","MapExit","CharacterReplacement"} do table.insert(names,name) end
	return {candidate=CANDIDATE,names=names,optionalExpertAfter={"ExpertAfter1","ExpertAfter2","ExpertAfter3"},
		unsupported={"Private Runtime controller.Reset is not exposed by MoonlitCitadelService; this tool does not call or claim it"}}
end
function Cases.Current() return current end
function Cases.Status()
	if not current then return {state="Idle",candidate=CANDIDATE} end
	return {state=current.state,candidate=CANDIDATE,owner=current.owner,caseName=current.caseName,caseIndex=current.caseIndex,
		completed=#current.cases,failure=current.failure,evidencePath=current.evidencePath}
end
function Cases.Stop()
	fixture(true)
	if current and not terminal(current.state) then current.stopRequested=true end
end

function Cases.Start(services,options)
	fixture(true)
	options=options or {}
	assert(options.authorizedControlledNative==true, "Explicit controlled native placement authorization required")
	assert(not current or terminal(current.state), "Prior boundary suite active")
	for _,name in {"CourseService","RaceService","PlayerRaceService","CheckpointService","MoonlitCitadelService"} do assert(services[name],"Missing real shared service "..name) end
	for _,entry in {{"CourseService","GetActiveCourse"},{"CourseService","GetOrderedCheckpoints"},{"CourseService","GetFinishPart"},
		{"RaceService","ApplyStudioAction"},{"RaceService","GetCurrentRaceId"},{"MoonlitCitadelService","Start"},
		{"MoonlitCitadelService","Stop"},{"MoonlitCitadelService","GetDiagnostics"}} do assert(type(services[entry[1]][entry[2]])=="function","Actual service API missing") end
	local tools = game.ServerStorage.MoonlitPhase2Tools
	local prior = require(tools.ContactCases).Current()
	assert(not prior or terminal(prior.state),"Prior contact case active")
	for _,item in game.ReplicatedStorage.Remotes:GetChildren() do assert(item:GetAttribute("DriverActive")~=true,"Prior native driver active") end
	local Control = require(tools.TrialControl)
	local actor = assert(Players:GetPlayerByUserId(-1),"Actual native Player -1 required")
	local other = assert(Players:GetPlayerByUserId(-2),"Actual native Player -2 required")
	local players = {actor,other}
	assert(#Players:GetPlayers()==2,"Exactly two actual native Players required")
	for _,player in players do assert(player:GetAttribute("OnboardingReady")==true and player:GetAttribute("ArrivalPhase")=="Ready","Actual authoritative arrival incomplete") end
	local initialCourse=assert(services.CourseService.GetActiveCourse(),"Actual course absent before boundary setup")
	assert(initialCourse==workspace:FindFirstChild("RaceCourse") and initialCourse:GetAttribute("CandidateId")==CANDIDATE and initialCourse:GetAttribute("CourseId")==Config.CourseId,"Wrong native R04 before boundary setup")
	local oldEvidence=game.ServerStorage:FindFirstChild("MoonlitPhase2Evidence")
	if oldEvidence then for _,item in oldEvidence:GetChildren() do assert(item:GetAttribute("CreatedBy")~=MARKER or item:GetAttribute("BoundaryActive")~=true,"Another boundary suite active") end end
	local plan = options.names or {"NormalWaitBefore1","NormalWaitAfter1","NormalWaitBefore2","NormalWaitAfter2","NormalWaitBefore3","NormalWaitAfter3","ExpertBefore1","ExpertBefore2","ExpertBefore3"}
	assert(type(plan)=="table" and #plan>=1 and #plan<=20,"Select a bounded nonempty subset")
	local allowed={}
	for _,name in Cases.Preview().names do allowed[name]=true end
	for _,name in Cases.Preview().optionalExpertAfter do allowed[name]=true end
	local seen={}
	for _,name in plan do assert(allowed[name] and not seen[name],"Unknown or duplicate boundary case");seen[name]=true end
	local id="MC_P2_C01_R04_Boundary_"..HttpService:GenerateGUID(false):gsub("%-","")
	current={candidate=CANDIDATE,owner=id,state="Starting",startedAt=now(),cases={},planned=table.clone(plan),
		evidenceKind="Controlled actual two-client native cases; not continuous traversal or twenty-player proof",limitations=Cases.Preview().unsupported}
	local report=current
	local began=os.clock()
	local connections={}
	local savedProfiles={}
	local function guard()
		fixture(true)
		assert(not report.stopRequested,"Stopped by lead")
		assert(os.clock()-began<1200,"Boundary suite watchdog expired")
		assert(#Players:GetPlayers()==2 and Players:GetPlayerByUserId(-1)==actor and Players:GetPlayerByUserId(-2)==other,"Actual native Players changed")
		for _,player in players do assert(player:GetAttribute("OnboardingReady")==true and player:GetAttribute("ArrivalPhase")=="Ready","Actual authoritative arrival incomplete") end
	end
	local function activeCourse()
		local root=assert(services.CourseService.GetActiveCourse(),"Actual active course absent")
		assert(root==workspace:FindFirstChild("RaceCourse") and root:GetAttribute("CandidateId")==CANDIDATE and root:GetAttribute("CourseId")==Config.CourseId,"Wrong active native R04")
		return root
	end
	activeCourse();guard()
	local evidenceRoot=game.ServerStorage:FindFirstChild("MoonlitPhase2Evidence")
	if not evidenceRoot then evidenceRoot=Instance.new("Folder");evidenceRoot.Name="MoonlitPhase2Evidence";evidenceRoot.Parent=game.ServerStorage end
	local folder=Instance.new("Folder");folder.Name=id;folder:SetAttribute("CreatedBy",MARKER);folder:SetAttribute("BoundaryActive",true);folder.Parent=evidenceRoot
	local status=Instance.new("StringValue");status.Name="StatusJSON";status.Parent=folder
	report.evidencePath=folder:GetFullName()
	local function update()
		status.Value=HttpService:JSONEncode({owner=id,candidate=CANDIDATE,state=report.state,caseName=report.caseName,
			caseIndex=report.caseIndex,completed=#report.cases,failure=report.failure,evidencePath=report.evidencePath,elapsedSeconds=os.clock()-began})
	end
	local function save(name,value)
		assert(not folder:FindFirstChild(name),"Keep prior evidence")
		local item=Instance.new("Folder");item.Name=name;item:SetAttribute("CreatedBy",MARKER);item.Parent=folder
		local encoded=HttpService:JSONEncode(value)
		item:SetAttribute("JSONBytes",#encoded);item:SetAttribute("JSONChunks",math.ceil(#encoded/60000))
		for offset=1,#encoded,60000 do local chunk=Instance.new("StringValue");chunk.Name=string.format("JSON_%03d",math.ceil(offset/60000));chunk.Value=encoded:sub(offset,offset+59999);chunk.Parent=item end
	end
	local function waitFor(label,predicate,seconds,tick)
		local deadline=os.clock()+seconds
		repeat guard();if tick then tick() end;if predicate() then return end;update();task.wait(.05) until os.clock()>=deadline
		error("Native boundary timeout: "..label)
	end
	local function fresh(tick)
		local old=services.RaceService.GetCurrentRaceId()
		Control.Restart()
		waitFor("fresh shared CP0/f0 Racing",function()
			if not services.CourseService.GetActiveCourse() or not services.RaceService.IsRaceActive() or services.RaceService.GetCurrentRaceId()==old then return false end
			local root=activeCourse()
			for _,player in players do
				local raw=player:GetAttribute("MCPhase2Progress")
				if type(raw)~="string" then return false end
				local p=HttpService:JSONDecode(raw)
				if p.raceId~=services.RaceService.GetCurrentRaceId() or p.raceState~="Racing" then return false end
				p=progress(player,services,root);assert(p.checkpoint==0 and p.falls==0,"Restart did not produce clean CP0/f0")
				character(player)
			end
			return true
		end,35,tick)
		return activeCourse()
	end
	local function command(kind,data)
		actor:SetAttribute(ACTION,HttpService:JSONEncode({owner=id,candidate=CANDIDATE,caseName=report.caseName,
			raceId=services.RaceService.GetCurrentRaceId(),nonce=HttpService:GenerateGUID(false),kind=kind,at=now(),data=data}))
	end
	local function observe(entry,course,part,seconds,check)
		local start=now()
		local previousAt
		repeat
			guard();assert(activeCourse()==course,"Course changed during measurement")
			local model,root,human=character(actor)
			local p=progress(actor,services,course,entry.replacementBaseline)
			local low,high,bodies=bodyBounds(model,root.CFrame)
			local ray,gap=support(root,human)
			local sample={at=now(),root=xyz(root.Position),bodyLow=xyz(low),bodyHigh=xyz(high),state=human:GetState().Name,
				floorMaterial=human.FloorMaterial.Name,jump=human.Jump,health=human.Health,profile=profile(human),checkpoint=p.checkpoint,falls=p.falls,
				supportPath=ray and ray.Instance:GetFullName(),footGap=gap,normalY=ray and ray.Normal.Y,diagnostics=services.MoonlitCitadelService.GetDiagnostics(),cages={},lights={}}
			for band=1,3 do
				local cage=resolve(course,"Obstacles/SwingLanterns/SwingBand"..band)
				local visible=assert(cage:FindFirstChild("CageAndCore"),"Actual visible cage/core group missing")
				for _,piece in visible:GetDescendants() do
					if piece:IsA("BasePart") and piece.Transparency<1 and piece.CanQuery then
						local hits=overlap(piece,bodies)
						table.insert(sample.cages,{path=piece:GetFullName(),position=xyz(piece.Position),hits=hits})
					elseif piece:IsA("PointLight") and piece.Parent:IsA("BasePart") then
						table.insert(sample.lights,{path=piece:GetFullName(),enabled=piece.Enabled,range=piece.Range,
							distance=(root.Position-piece.Parent.Position).Magnitude,exposed=piece.Enabled and (root.Position-piece.Parent.Position).Magnitude<=piece.Range})
					end
				end
			end
			table.insert(entry.samples,sample)
			if previousAt then assert(sample.at>previousAt and sample.at-previousAt<=.6,"Native observation gap exceeds existing 0.6-second evidence bound") end
			previousAt=sample.at
			if check then check(sample,model,root,human,bodies,part) end
			update();task.wait(.1)
		until now()-start>=seconds
		entry.measuredSeconds=now()-start
	end
	local function unchanged(sample)
		assert(sample.checkpoint==0 and sample.falls==0,"Unexpected checkpoint/fall during negative")
	end
	local function movingDeck(course,entry)
		local car=resolve(course,"Obstacles/MovingCars/Lower_Bay1")
		local deck=resolve(car,"Deck")
		waitFor("actual LowDwell",function() return car:GetAttribute("MoonlitPhase")=="LowDwell" end,16)
		entry.placement=place(actor,deck,Vector3.zero);command("Idle")
		waitFor("actual sole native passenger on rising deck",function()
			local model,root,human=character(actor)
			local ray,gap=support(root,human)
			return car:GetAttribute("MoonlitPhase")=="Rising" and car:GetAttribute("MoonlitPassengers")==1 and ray and ray.Instance==deck and gap and math.abs(gap)<=.6
		end,16)
		entry.activeMechanisms=services.MoonlitCitadelService.GetDiagnostics()
		assert(entry.activeMechanisms.bound and #entry.activeMechanisms.cars==4,"Actual bound four-car mechanism required")
		return car,deck
	end
	local function captureOriginal(entry)
		services.MoonlitCitadelService.Stop()
		local _,_,human=character(actor)
		local observed=profile(human)
		if not savedProfiles[human] then savedProfiles[human]=observed end
		entry.observedRestoredProfile=observed
		human.WalkSpeed,human.JumpHeight,human.MaxSlopeAngle=14,6.5,40
		entry.originalProfile=profile(human)
		entry.originalProfileSource="Trusted controlled diagnostic baseline14/6.5/40 before a fresh service binding; real previous values restored on cleanup"
		entry.controlledDistinctBaseline=true
		services.MoonlitCitadelService.Start()
		waitFor("fresh native runtime binding",function() return services.MoonlitCitadelService.GetDiagnostics().bound==true end,3)
		task.wait(.2)
		entry.appliedProfile=profile(human)
		configuredProfile(entry.appliedProfile)
		assert(not equalProfile(entry.originalProfile,entry.appliedProfile),"Profile restoration test must have a distinct original baseline")
		return human
	end
	local function run(name,entry,course)
		if name:match("^NormalWait") or name:match("^Expert") then
			local contact=resolve(course,"Obstacles/Gallery/"..name.."/Contact")
			local model,root=character(actor)
			local low,high=bodyBounds(model,root.CFrame)
			local minX,maxX=-contact.Size.X/2-low.X+.375,contact.Size.X/2-high.X-.375
			local minZ,maxZ=-contact.Size.Z/2-low.Z+.375,contact.Size.Z/2-high.Z-.375
			assert(minX<0 and maxX>0 and minZ<0 and maxZ>0,"Actual body cannot use all requested edges")
			entry.positions={}
			local cycle=0
			for band=1,3 do local value=resolve(course,"Obstacles/SwingLanterns/SwingBand"..band):GetAttribute("CycleSeconds");assert(type(value)=="number" and value>0 and value<=15,"Actual cycle invalid");cycle=math.max(cycle,value) end
			for index,edge in {"Center","MinX","MaxX","MinZ","MaxZ"} do
				local actualModel,actualRoot=character(actor)
				local liveLow,liveHigh=bodyBounds(actualModel,actualRoot.CFrame)
				local liveMinX,liveMaxX=-contact.Size.X/2-liveLow.X+.375,contact.Size.X/2-liveHigh.X-.375
				local liveMinZ,liveMaxZ=-contact.Size.Z/2-liveLow.Z+.375,contact.Size.Z/2-liveHigh.Z-.375
				local offset=if edge=="MinX" then Vector3.new(liveMinX+.025,0,0)
					else if edge=="MaxX" then Vector3.new(liveMaxX-.025,0,0)
					else if edge=="MinZ" then Vector3.new(0,0,liveMinZ+.025)
					else if edge=="MaxZ" then Vector3.new(0,0,liveMaxZ-.025) else Vector3.zero
				local row={index=index,edge=edge,offset=xyz(offset),nativeRoundingInset=.025,samples={},placement=place(actor,contact,offset)}
				table.insert(entry.positions,row);command("Idle");task.wait(.6)
				local angleRange={}
				observe(row,course,contact,cycle*2+.15,function(sample,actualModel,_,_,_,part)
					unchanged(sample)
					assert(sample.supportPath==part:GetFullName() and math.abs(sample.footGap)<=.6 and sample.normalY>=.95,"Actual edge lost physical support")
					local a,b=bodyBounds(actualModel,part.CFrame)
					assert(a.X>=-part.Size.X/2 and b.X<=part.Size.X/2 and a.Z>=-part.Size.Z/2 and b.Z<=part.Size.Z/2,"Actual body leaves contact footprint")
					assert(sample.diagnostics.bound,"Mechanisms stopped during wait test")
					assert(#sample.diagnostics.lanterns==3,"All three actual lantern diagnostics required")
					for _,cage in sample.cages do assert(#cage.hits==0,"Actual visible cage touches wait body") end
					for _,lantern in sample.diagnostics.lanterns do
						local range=angleRange[lantern.name] or {min=math.huge,max=-math.huge};angleRange[lantern.name]=range
						range.min=math.min(range.min,lantern.angleDegrees);range.max=math.max(range.max,lantern.angleDegrees)
					end
				end)
				row.actualAngleRanges=angleRange
				local first,last=row.samples[1].diagnostics,row.samples[#row.samples].diagnostics
				assert(last.elapsed-first.elapsed>=cycle*2,"Fewer than two actual runtime cycles observed")
				for _,range in angleRange do assert(range.min< -30 and range.max>30,"Actual complete swing range not observed") end
			end
		elseif name=="RedAdjacent" then
			local plan=assert(options.redAdjacent,"Supply separately measured actual red/standing paths and offset")
			assert(plan.measuredSafeStand==true and typeof(plan.standOffset)=="Vector3","Explicit measured native standing plan required")
			local red=resolve(course,plan.redPath)
			assert(red:IsA("BasePart") and red:GetAttribute("MoonlitHazard")==true and red:GetAttribute("Role")=="VisibleResetContact"
				and red.Material==Enum.Material.Neon and red.Transparency<1 and red.CanQuery,"Actual visible native red hazard required")
			local contact=resolve(course,plan.standPath)
			entry.placement=place(actor,contact,plan.standOffset);entry.redPath=red:GetFullName();command("Idle");task.wait(.6)
			observe(entry,course,contact,3,function(sample,model,_,_,bodies,part)
				unchanged(sample);sample.redBodyHits=overlap(red,bodies)
				assert(#sample.redBodyHits==0 and sample.supportPath==part:GetFullName() and math.abs(sample.footGap)<=.6,"Actual red-adjacent negative lost clearance/support")
				local low,high=bodyBounds(model,red.CFrame)
				local dx=math.max(low.X-red.Size.X/2,-red.Size.X/2-high.X,0)
				local dy=math.max(low.Y-red.Size.Y/2,-red.Size.Y/2-high.Y,0)
				local dz=math.max(low.Z-red.Size.Z/2,-red.Size.Z/2-high.Z,0)
				sample.redBoundsSeparation=Vector3.new(dx,dy,dz).Magnitude
				entry.adjacencyLimit=2.1
				entry.adjacencyTolerance="Two studs of authored vertical separation plus0.1stud for native foot settling"
				assert(sample.redBoundsSeparation>0 and sample.redBoundsSeparation<=entry.adjacencyLimit,"Measured body exceeds the declared adjacent separation")
			end)
		elseif name=="CP04Bypass" then
			local cp
			for _,definition in services.CourseService.GetOrderedCheckpoints() do if definition.index==4 then cp=definition.part end end
			assert(cp and cp:IsDescendantOf(course),"Actual CP04 trigger required")
			local model,root=character(actor)
			local touch=0
			table.insert(connections,cp.Touched:Connect(function(part) if part.Parent==model and bodyNames[part.Name] then touch+=1 end end))
			model:PivotTo(CFrame.new(cp.Position)*root.CFrame:Inverse()*model:GetPivot());root.AssemblyLinearVelocity=Vector3.zero
			entry.controlledTriggerPlacement=cp:GetFullName()
			observe(entry,course,nil,1.5,function(sample,_,_,_,bodies)
				unchanged(sample);sample.cp04BodyHits=overlap(cp,bodies);sample.nativeTouches=touch
			end)
			local maximum=0;for _,sample in entry.samples do maximum=math.max(maximum,#sample.cp04BodyHits) end
			assert(maximum>0 and touch>0,"Real native CP04 overlap and Touched not established")
			entry.nativeTouches=touch;entry.acceptanceScope="Actual shared CP04 rejects CP0 contact; this does not prove route inaccessibility"
		elseif name=="CrownBypass" then
			local finish=assert(services.CourseService.GetFinishPart(),"Actual Finish absent")
			assert(finish:IsDescendantOf(course),"Expected real shared finish required")
			local model,root=character(actor)
			local touch=0
			entry.finishTriggerMode=if finish:GetAttribute("RequireForwardCrossing")==true then "ForwardCrossing" else "NativeTouched"
			table.insert(connections,finish.Touched:Connect(function(part) if part.Parent==model and bodyNames[part.Name] then touch+=1 end end))
			local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={actor.Character,other.Character};params.RespectCanCollide=true
			local pre=finish.CFrame:PointToWorldSpace(Vector3.new(0,0,finish.Size.Z/2-1))
			local ray=workspace:Raycast(pre+Vector3.yAxis*12,-Vector3.yAxis*30,params)
			assert(ray and ray.Instance:IsDescendantOf(resolve(course,"Obstacles/Crown")) and ray.Normal.Y>=.95,"Actual pre-finish crown support not established")
			local localPoint=ray.Instance.CFrame:PointToObjectSpace(ray.Position)
			entry.placement=place(actor,ray.Instance,Vector3.new(localPoint.X,0,localPoint.Z));command("Idle");task.wait(.6)
			entry.finishPath=finish:GetFullName();local previous,previousAt=root.Position,now();local crossing=false
			command("Walk",{direction=xyz(finish.CFrame.LookVector),seconds=1.25})
			observe(entry,course,nil,2,function(sample,_,actualRoot,_,bodies)
				unchanged(sample)
				sample.finishBodyHits=overlap(finish,bodies);sample.nativeTouches=touch
				local t=now();sample.forwardCrossed=ForwardGate.Crossed(finish.CFrame,finish.Size,previous,actualRoot.Position,t-previousAt)
				crossing=crossing or sample.forwardCrossed;previous,previousAt=actualRoot.Position,t
			end)
			assert(crossing,"Real native continuous back-to-front Finish crossing not observed")
			assert(touch>0,"Real native finish touch not established")
			entry.nativeTouches=touch
			entry.acceptanceScope="Actual shared finish rejects a real CP0 touch during crown crossing; controlled crown placement does not prove route inaccessibility"
		elseif name=="JumpDeparture" then
			local car,deck=movingDeck(course,entry)
			local airSamples,observedAirSpan,lastAirStats,lastAirAt=0,0,nil,nil
			command("Jump",{seconds=.35})
			observe(entry,course,deck,2,function(sample)
				unchanged(sample)
				local airborne=(sample.state=="Jumping" or sample.state=="Freefall") and sample.floorMaterial=="Air" and sample.supportPath~=deck:GetFullName()
				if airborne then
					airSamples+=1
					if lastAirAt then observedAirSpan+=sample.at-lastAirAt end
					if lastAirStats then assert(sample.diagnostics.stats.carriedSteps==lastAirStats,"Runtime carried an airborne actual jumper") end
					lastAirStats=sample.diagnostics.stats.carriedSteps
					lastAirAt=sample.at
					assert(car:GetAttribute("MoonlitPassengers")==0,"Airborne jumper remains a native passenger")
				else lastAirStats=nil;lastAirAt=nil end
			end)
			assert(airSamples>=2 and observedAirSpan>0,"Two successive actual airborne observations not established")
			entry.actualAirborneSamples=airSamples;entry.actualAirborneObservedSpanSeconds=observedAirSpan
		else
			local originalHuman=captureOriginal(entry)
			local car,deck=movingDeck(course,entry)
			if name=="StopStart" then
				services.MoonlitCitadelService.Stop();entry.restoredProfile=profile(originalHuman)
				assert(equalProfile(entry.originalProfile,entry.restoredProfile),"Original surviving Humanoid profile not restored on Stop")
				local stopped=deck.CFrame
				local untilAt=os.clock()+.8
				repeat guard();assert(services.MoonlitCitadelService.GetDiagnostics().bound==false and deck.CFrame==stopped,"Mechanism changes after Stop");task.wait(.05) until os.clock()>=untilAt
				place(actor,resolve(course,"Obstacles/Gate/GateCourt/Contact"),Vector3.zero)
				services.MoonlitCitadelService.Start()
				waitFor("native rebind after Stop",function() return services.MoonlitCitadelService.GetDiagnostics().bound==true end,3)
				observe(entry,course,nil,1,function(sample) unchanged(sample);assert(car:GetAttribute("MoonlitPassengers")==0,"Stale rider after rebind") end)
			elseif name=="Restart" then
				local oldRace=services.RaceService.GetCurrentRaceId();entry.oldRaceId=oldRace
				local restored=false
				local newCourse=fresh(function()
					local measured=originalHuman.Parent and profile(originalHuman)
					if measured and equalProfile(measured,entry.originalProfile) then restored=true end
					table.insert(entry.samples,{at=now(),raceId=services.RaceService.GetCurrentRaceId(),raceState=services.RaceService.GetRaceState(),
						profile=measured,bound=services.MoonlitCitadelService.GetDiagnostics().bound,oldDeckPresent=deck:IsDescendantOf(workspace),oldPassengers=car:GetAttribute("MoonlitPassengers")})
				end)
				assert(restored,"Original surviving profile restoration not observed during direct shared RestartRace")
				entry.originalProfileRestored=true;entry.newRaceId=services.RaceService.GetCurrentRaceId()
				assert(entry.newRaceId~=oldRace and newCourse~=course and not deck:IsDescendantOf(workspace),"Direct shared restart retained old course/race")
				observe(entry,newCourse,nil,1,function(sample) unchanged(sample);for _,item in sample.diagnostics.cars do assert(item.passengers==0,"Stale rider after shared restart") end end)
			elseif name=="MapExit" then
				local oldRace=services.RaceService.GetCurrentRaceId();entry.oldRaceId=oldRace
				assert(services.RaceService.ApplyStudioAction("HoldLobby"),"Shared lobby exit rejected")
				local restored=false
				waitFor("shared map unload, lobby and profile restore",function()
					if originalHuman.Parent and equalProfile(profile(originalHuman),entry.originalProfile) then restored=true end
					return services.CourseService.GetActiveCourse()==nil and services.MoonlitCitadelService.GetDiagnostics().bound==false
						and services.PlayerRaceService.GetPlayerStatus(actor)=="Lobby"
				end,15,function()
					table.insert(entry.samples,{at=now(),raceId=services.RaceService.GetCurrentRaceId(),raceState=services.RaceService.GetRaceState(),
						profile=originalHuman.Parent and profile(originalHuman),bound=services.MoonlitCitadelService.GetDiagnostics().bound,
						oldDeckPresent=deck:IsDescendantOf(workspace),oldPassengers=car:GetAttribute("MoonlitPassengers")})
				end)
				assert(restored,"Original surviving profile restoration not observed during map exit")
				entry.originalProfileRestored=true;assert(not deck:IsDescendantOf(workspace),"Old moving deck remains after shared unload")
			elseif name=="CharacterReplacement" then
				local oldCharacter=actor.Character;local died=false
				local before=progress(actor,services,course)
				entry.replacementBaseline={initialCharacterSerial=before.characterSerial,initialStaged=before.staged,raceId=before.raceId}
				local oldProfileRestored=false
				table.insert(connections,originalHuman.Died:Connect(function() died=true end))
				originalHuman.Health=0
				waitFor("actual native replacement after death",function()
					local model=actor.Character;local human=model and model:FindFirstChildOfClass("Humanoid")
					return model~=oldCharacter and human and human.Health>0 and model:FindFirstChild("HumanoidRootPart") and not model.HumanoidRootPart.Anchored
				end,20,function()
					local measured=originalHuman.Parent and profile(originalHuman)
					if measured and equalProfile(measured,entry.originalProfile) then oldProfileRestored=true end
					table.insert(entry.samples,{at=now(),oldHealth=originalHuman.Health,oldProfile=measured,
						actualCharacterChanged=actor.Character~=oldCharacter,bound=services.MoonlitCitadelService.GetDiagnostics().bound,
						oldPassengers=car:GetAttribute("MoonlitPassengers")})
				end)
				assert(died,"Actual Humanoid.Died was not observed")
				entry.replacementBaseline.actualDied=true;entry.replacementBaseline.actualCharacterChanged=actor.Character~=oldCharacter
				waitFor("shared real death recovery f1 CP0",function()
					local ok,p=pcall(progress,actor,services,course,entry.replacementBaseline);return ok and p.falls==1 and p.checkpoint==0
				end,5)
				local respawn=assert(services.CheckpointService.GetCheckpointRespawnCFrame(actor),"Actual shared checkpoint respawn transform absent")
				entry.actualRecoveryTarget=xyz(respawn.Position)
				observe(entry,course,nil,1,function(sample,_,actualRoot)
					assert(sample.checkpoint==0 and sample.falls==1,"Replacement progress not preserved")
					assert(sample.supportPath~=deck:GetFullName() and car:GetAttribute("MoonlitPassengers")==0,"Stale carry after actual replacement")
					local delta=actualRoot.Position-respawn.Position
					assert(Vector3.new(delta.X,0,delta.Z).Magnitude<1.5 and math.abs(delta.Y)<6,"Actual replacement did not settle at shared checkpoint recovery")
					configuredProfile(sample.profile)
				end)
				entry.actualCharacterChanged=true;entry.oldHumanoidOriginalProfileRestoredObserved=oldProfileRestored
				entry.deadHumanoidProfileRestoration="Known fresh-binding baseline is compared while the old Humanoid remains readable; a removed Humanoid's private stored profile is not exposed"
				assert(oldProfileRestored,"Old Humanoid original profile restoration was not observed before removal")
			end
		end
	end
	task.spawn(function()
		local entry
		local ok,failure=xpcall(function()
			for index,name in plan do
				entry=nil
				guard();report.caseName,report.caseIndex,report.state=name,index,"Restarting";update()
				local course=fresh()
				entry={name=name,state="Running",candidate=CANDIDATE,raceId=services.RaceService.GetCurrentRaceId(),startedAt=now(),samples={}}
				report.activeCase=entry;report.state="Running";update()
				run(name,entry,course)
				entry.state,entry.endedAt="Complete",now();save(string.format("Case_%02d_%s",index,name),entry)
				table.insert(report.cases,{name=name,state=entry.state,evidenceFolder=string.format("Case_%02d_%s",index,name)})
				report.activeCase=nil
				for _,connection in connections do connection:Disconnect() end;table.clear(connections)
				if name~="MapExit" then command("Idle") end
			end
		end,debug.traceback)
		for _,connection in connections do connection:Disconnect() end
		local cleanupOk,cleanupFailure=pcall(function()
			if next(savedProfiles) then
				services.MoonlitCitadelService.Stop()
				report.profileCleanup={}
				for human,previous in savedProfiles do
					if human.Parent then
						for key,value in previous do human[key]=value end
						table.insert(report.profileCleanup,{path=human:GetFullName(),restored=profile(human),expected=previous})
						assert(equalProfile(profile(human),previous),"Real previous profile cleanup failed")
					end
				end
				services.MoonlitCitadelService.Start()
			end
		end)
		if not cleanupOk then ok=false;failure=tostring(failure or "").."; profile cleanup: "..tostring(cleanupFailure) end
		folder:SetAttribute("BoundaryActive",false)
		if actor:GetAttribute(ACTION) then
			local decodedOk,decoded=pcall(HttpService.JSONDecode,HttpService,actor:GetAttribute(ACTION))
			if decodedOk and decoded.owner==id then actor:SetAttribute(ACTION,nil) end
		end
		if not ok then
			report.failure=tostring(failure)
			if entry and entry.state=="Running" then entry.state="Failed";entry.failure=report.failure;entry.endedAt=now();save(string.format("Failure_%02d_%s",report.caseIndex,entry.name),entry) end
		end
		report.state,report.endedAt=if ok then "Complete" else "Failed",now();report.activeCase=nil;update();save("SuiteRaw",report)
	end)
	update()
	return {Current=function() return report end,Stop=Cases.Stop}
end

function Cases.ClientWatch(options)
	fixture(false)
	options=options or {}
	assert(options.authorizedNativeMovement==true,"Explicit bounded native Jump/Walk authorization required")
	assert(not clientCurrent or terminal(clientCurrent.state),"Prior boundary client watcher active")
	local player=Players.LocalPlayer
	assert(player.UserId==-1 or player.UserId==-2,"Actual native clients only")
	local tools=game.ReplicatedStorage.MoonlitPhase2Tools
	for _,name in {"ClientProbe","ClientSuite","ContactCases"} do local prior=require(tools[name]).Current();assert(not prior or terminal(prior.state),"Prior client probe active") end
	assert(player:GetAttribute("ArrivalOpen")==false and player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("OnboardingReady")==true,"Actual local arrival must be complete")
	local duration=options.durationSeconds or 1100
	assert(duration>=10 and duration<=1200,"Bounded native client watcher duration required")
	local report={state="Observing",candidate=CANDIDATE,userId=player.UserId,startedAt=now(),actions={},samples={}}
	clientCurrent=report
	local folder=Instance.new("Folder");folder.Name="MC_P2_C01_R04_BoundaryClient_"..HttpService:GenerateGUID(false):gsub("%-","");folder:SetAttribute("CreatedBy",MARKER);folder.Parent=player:WaitForChild("PlayerScripts")
	report.evidencePath=folder:GetFullName()
	task.spawn(function()
		local last,moveUntil,movement,jumpUntil=nil,0,Vector3.zero,0
		local inputBinding=folder.Name.."_Input"
		RunService:BindToRenderStep(inputBinding,Enum.RenderPriority.Input.Value+1,function()
			local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if human and human.Health>0 then
				human:Move(if os.clock()<moveUntil then movement else Vector3.zero,false)
				human.Jump=os.clock()<jumpUntil
			end
		end)
		local deadline=os.clock()+duration
		local ok,failure=xpcall(function()
			repeat
				fixture(false)
				assert(player:GetAttribute("ArrivalOpen")==false and player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("OnboardingReady")==true,"Native local readiness changed")
				local model=player.Character
				local root=model and model:FindFirstChild("HumanoidRootPart")
				local human=model and model:FindFirstChildOfClass("Humanoid")
				local encoded=player:GetAttribute(ACTION)
				if encoded and encoded~=last then
					local command=HttpService:JSONDecode(encoded)
					assert(player.UserId==-1 and command.candidate==CANDIDATE and type(command.owner)=="string" and command.owner:match("^MC_P2_C01_R04_Boundary_")
						and type(command.nonce)=="string" and now()-command.at>=0 and now()-command.at<=2,"Stale/wrong native boundary action")
					assert(not report.owner or report.owner==command.owner,"Native boundary owner changed; start a fresh client watcher for each suite")
					report.owner=command.owner
					local rootCourse=assert(workspace:FindFirstChild("RaceCourse"),"Native course absent for requested action")
					assert(rootCourse:GetAttribute("CandidateId")==CANDIDATE,"Wrong native movement candidate")
					assert(human and human.Health>0 and root and not root.Anchored,"Actual living unanchored native actor required")
					local p=HttpService:JSONDecode(player:GetAttribute("MCPhase2Progress"))
					assert(p.raceId==command.raceId and p.status=="Racing" and p.official and now()-p.observedAt<=1.5,"Wrong actual action race")
					movement=Vector3.zero;moveUntil=0;jumpUntil=0
					if command.kind=="Jump" then
						assert(command.caseName=="JumpDeparture" and command.data.seconds>0 and command.data.seconds<=.5,"Jump belongs to bounded departure case")
						jumpUntil=os.clock()+command.data.seconds
					elseif command.kind=="Walk" then
						assert(command.caseName=="CrownBypass" and command.data.seconds>0 and command.data.seconds<=1.5,"Walk belongs to bounded crown attempt")
						local v=command.data.direction;movement=Vector3.new(v[1],v[2],v[3]);assert(math.abs(movement.Y)<.001 and math.abs(movement.Magnitude-1)<.001,"Actual finite horizontal direction required")
						moveUntil=os.clock()+command.data.seconds
					else assert(command.kind=="Idle","Unknown native action") end
					table.insert(report.actions,command);last=encoded
				end
				if root and human then
					local bridge=player:GetAttribute("MCPhase2Progress")
					table.insert(report.samples,{at=now(),root=xyz(root.Position),state=human:GetState().Name,health=human.Health,
						floorMaterial=human.FloorMaterial.Name,arrivalOpen=player:GetAttribute("ArrivalOpen"),arrivalPhase=player:GetAttribute("ArrivalPhase"),
						progress=type(bridge)=="string" and HttpService:JSONDecode(bridge) or nil})
				end
				task.wait(.1)
			until os.clock()>=deadline or report.stopRequested
		end,debug.traceback)
		RunService:UnbindFromRenderStep(inputBinding)
		local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid");if human then human:Move(Vector3.zero,false);human.Jump=false end
		report.state,report.endedAt=if ok then "Observed" else "Failed",now();if not ok then report.failure=tostring(failure) end
		local encoded=HttpService:JSONEncode(report);folder:SetAttribute("JSONBytes",#encoded);folder:SetAttribute("JSONChunks",math.ceil(#encoded/60000))
		for offset=1,#encoded,60000 do local chunk=Instance.new("StringValue");chunk.Name=string.format("JSON_%03d",math.ceil(offset/60000));chunk.Value=encoded:sub(offset,offset+59999);chunk.Parent=folder end
	end)
	return {Current=function() return report end,Stop=function() report.stopRequested=true end}
end
function Cases.ClientCurrent() return clientCurrent end
function Cases.ClientStop()
	fixture(false)
	if clientCurrent and not terminal(clientCurrent.state) then clientCurrent.stopRequested=true end
end
return Cases
