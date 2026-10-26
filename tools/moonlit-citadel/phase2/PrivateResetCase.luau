--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Cases = {}
local MARKER, CANDIDATE = "MoonlitPrivateReset1", "MC_P2_C01_R04"
local CHUNK, LIMIT = 16000, 900000
local current, clientCurrent
local profileKeys = {"WalkSpeed", "UseJumpPower", "JumpHeight", "JumpPower", "MaxSlopeAngle"}
local function now() return workspace:GetServerTimeNow() end
local function xyz(v) return {v.X,v.Y,v.Z} end
local function fixture(server)
	assert(RunService:IsStudio() and RunService:IsRunning() and game.PlaceId==0 and game.GameId==0, "Unpublished native Play fixture only")
	assert(server==RunService:IsServer() and Config.CandidateId==CANDIDATE, "Wrong execution side or candidate")
end
local function terminal(state) return state==nil or state=="Complete" or state=="Observed" or state=="Failed" end
local function resolve(root,path)
	for name in path:gmatch("[^/]+") do root=assert(root:FindFirstChild(name),"Missing actual "..path) end
	return root
end
local function character(player)
	local model=assert(player.Character,"Actual character absent")
	local human=assert(model:FindFirstChildOfClass("Humanoid"),"Actual Humanoid absent")
	local root=assert(model:FindFirstChild("HumanoidRootPart"),"Actual root absent")
	assert(human.Health>0 and human.RigType==Enum.HumanoidRigType.R15 and not root.Anchored,"Living unanchored actual R15 required")
	return model,human,root
end
local function profile(human)
	local result={};for _,key in profileKeys do result[key]=human[key] end;return result
end
local function setProfile(human,value) for _,key in profileKeys do human[key]=value[key] end end
local function sameProfile(human,value)
	for _,key in profileKeys do if human[key]~=value[key] then return false end end;return true
end
local function matchesConfig(actual,expected)
	if type(expected)=="number" then return type(actual)=="number" and math.abs(actual-expected)<=.00001 end
	return actual==expected
end
local function sameValue(a,b)
	if type(a)~=type(b) then return false end
	if type(a)~="table" then return a==b end
	for key,value in a do if not sameValue(value,b[key]) then return false end end
	for key in b do if a[key]==nil then return false end end
	return true
end
local function persist(parent,name,value)
	assert(not parent:FindFirstChild(name),"Preserve previous raw evidence")
	local folder=Instance.new("Folder");folder.Name=name;folder:SetAttribute("CreatedBy",MARKER);folder.Parent=parent
	local encoded=HttpService:JSONEncode(value)
	folder:SetAttribute("JSONBytes",#encoded);folder:SetAttribute("JSONChunks",math.ceil(#encoded/60000))
	for offset=1,#encoded,60000 do
		local part=Instance.new("StringValue");part.Name=string.format("JSON_%03d",math.ceil(offset/60000));part.Value=encoded:sub(offset,offset+59999);part.Parent=folder
	end
	return folder:GetFullName()
end
local function bodyPlace(player,part)
	local model,human,root=character(player)
	assert(part:IsA("BasePart") and part.CanCollide and part.CanQuery and part.CFrame.UpVector:Dot(Vector3.yAxis)>.999999,"Level actual standing contact required")
	local low,high=Vector3.one*math.huge,Vector3.one*-math.huge
	local count=0
	for _,body in model:GetChildren() do
		if not body:IsA("BasePart") then continue end
		if body.Name=="HumanoidRootPart" or body.Name=="Head" or body.Name:match("Torso$") or body.Name:match("Arm$") or body.Name:match("Hand$") or body.Name:match("Leg$") or body.Name:match("Foot$") then
			count+=1
			for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
				local p=root.CFrame:PointToObjectSpace(body.CFrame:PointToWorldSpace(body.Size*Vector3.new(x,y,z)/2))
				low=Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z));high=Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
			end end end
		end
	end
	assert(count==16 and low.X>=-part.Size.X/2+.375 and high.X<=part.Size.X/2-.375 and low.Z>=-part.Size.Z/2+.375 and high.Z<=part.Size.Z/2-.375,"Actual complete R15 body exceeds contact clearance")
	local target=part.CFrame*CFrame.new(0,part.Size.Y/2-low.Y+.08,0)
	model:PivotTo(target*root.CFrame:Inverse()*model:GetPivot());root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
	return {userId=player.UserId,contact=part:GetFullName(),bodyLow=xyz(low),bodyHigh=xyz(high),rootTarget=xyz(target.Position),hipHeight=human.HipHeight}
end
local function support(player)
	local _,human,root=character(player)
	local networkOwner=root:GetNetworkOwner()
	assert(networkOwner==player,"Actual racer must own its native character physics")
	local excluded={};for _,actual in Players:GetPlayers() do if actual.Character then table.insert(excluded,actual.Character) end end
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=excluded;params.RespectCanCollide=true
	local hit=workspace:Raycast(root.Position,Vector3.new(0,-(human.HipHeight+root.Size.Y/2+2),0),params)
	return {userId=player.UserId,at=now(),networkOwnerUserId=networkOwner.UserId,networkOwnerPath=networkOwner:GetFullName(),root=xyz(root.Position),velocity=xyz(root.AssemblyLinearVelocity),profile=profile(human),floor=human.FloorMaterial.Name,
		support=hit and hit.Instance:GetFullName(),normalY=hit and hit.Normal.Y,footGap=hit and root.Position.Y-human.HipHeight-root.Size.Y/2-hit.Position.Y}
end
function Cases.Current() return current end
function Cases.Status()
	if not current then return {state="Idle"} end
	return {state=current.state,passed=current.passed,owner=current.owner,evidencePath=current.evidencePath,failure=current.failure,resetAccepted=current.resetAccepted,cleanup=current.cleanup}
end
function Cases.Stop() fixture(true);if current and not terminal(current.state) then current.stopRequested=true end end

function Cases.Start(services,options)
	fixture(true);options=options or {}
	assert(options.authorizedControlledNative==true,"Explicit controlled native reset authorization required")
	assert(not current or terminal(current.state),"Prior private reset test active")
	local tools=game.ServerStorage.MoonlitPhase2Tools
	for _,name in {"ContactCases","BoundaryCases"} do local prior=require(tools[name]).Current();assert(not prior or terminal(prior.state),"Prior controlled test active") end
	local remotes=assert(game.ReplicatedStorage:FindFirstChild("Remotes"),"Existing Remotes folder required")
	for _,item in remotes:GetChildren() do assert(item:GetAttribute("DriverActive")~=true,"Prior native driver active") end
	local actor=assert(Players:GetPlayerByUserId(-1),"Native player -1 absent")
	local other=assert(Players:GetPlayerByUserId(-2),"Native player -2 absent")
	local players={actor,other}
	assert(#Players:GetPlayers()==2,"Exactly two actual native players required")
	for _,name in {"CourseService","RaceService","PlayerRaceService","CheckpointService","ResultsService","RespawnService","MoonlitCitadelService"} do assert(services[name],"Missing shared service "..name) end
	local initialCourse=services.CourseService.GetActiveCourse()
	assert(initialCourse and initialCourse==workspace:FindFirstChild("RaceCourse") and initialCourse:GetAttribute("CandidateId")==CANDIDATE and initialCourse:GetAttribute("CourseId")==Config.CourseId,"Current actual R04 race course required")
	local Runtime=require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Runtime)
	assert(type(Runtime.Start)=="function" and type(services.RespawnService.RecoverPlayer)=="function" and type(services.MoonlitCitadelService.Stop)=="function" and type(services.MoonlitCitadelService.Start)=="function","Actual runtime/service APIs required")
	local Control=require(tools.TrialControl)
	local owner="MC_P2_C01_R04_PrivateReset_"..HttpService:GenerateGUID(false):gsub("%-","")
	local nonce=HttpService:GenerateGUID(false)
	local parent=game.ServerStorage:FindFirstChild("MoonlitPhase2Evidence")
	if not parent then parent=Instance.new("Folder");parent.Name="MoonlitPhase2Evidence";parent.Parent=game.ServerStorage end
	local evidence=Instance.new("Folder");evidence.Name=owner;evidence:SetAttribute("CreatedBy",MARKER);evidence.Parent=parent
	local status=Instance.new("StringValue");status.Name="StatusJSON";status.Parent=evidence
	local remote=Instance.new("RemoteEvent");remote.Name=owner;remote:SetAttribute("CreatedBy",MARKER);remote:SetAttribute("DriverOwner",owner)
	remote:SetAttribute("Nonce",nonce);remote:SetAttribute("CandidateId",CANDIDATE);remote:SetAttribute("DriverActive",true)
	local report={state="Handshake",candidate=CANDIDATE,owner=owner,caseId=owner,startedAt=now(),evidencePath=evidence:GetFullName(),
		evidenceKind="Controlled private Runtime.Reset with actual two native clients; not continuous traversal or twenty-player evidence",
		physicalFootingEvidence="Actual owning-client exact full trace must satisfy original Gate support, normal, floor, foot gap and drift bounds; server support/gap remains raw and any stale-height discrepancy is retained separately",
		samples={},callbacks={},profiles={},rejectedPackets=0,clients={},serverClientFootingComparisons={}}
	current=report
	local began=os.clock();local packets,incoming={},{};local allowed={hello=true,error=true};local transportFailure
	local controller,course,raceId,deck,car;local serviceStopped=false;local connection;local originalHumans={}
	local function update() status.Value=HttpService:JSONEncode(Cases.Status()) end
	local function guard()
		fixture(true);assert(not report.stopRequested and os.clock()-began<180,"Private reset stopped or watchdog expired")
		assert(#Players:GetPlayers()==2 and Players:GetPlayerByUserId(-1)==actor and Players:GetPlayerByUserId(-2)==other,"Actual native players changed")
		assert(not transportFailure,transportFailure or "Client transport failed")
		for _,player in players do assert(player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("OnboardingReady")==true,"Authoritative native arrival incomplete") end
	end
	local function waitFor(label,predicate,seconds,tick)
		local deadline=os.clock()+seconds
		repeat guard();if tick then tick() end;if predicate() then return end;update();task.wait(.05) until os.clock()>=deadline
		error("Private reset timeout: "..label)
	end
	local function paired(kind) return packets[-1] and packets[-2] and packets[-1][kind] and packets[-2][kind] end
	connection=remote.OnServerEvent:Connect(function(player,packet)
		local valid=(player==actor or player==other) and type(packet)=="table" and packet.owner==owner and packet.nonce==nonce and packet.caseId==owner
			and packet.raceId==(raceId or "") and allowed[packet.kind]==true and type(packet.chunk)=="string" and #packet.chunk<=CHUNK
			and type(packet.total)=="number" and packet.total%1==0 and packet.total>=1 and packet.total<=60
			and type(packet.index)=="number" and packet.index%1==0
		if not valid then report.rejectedPackets+=1;return end
		local ok,failure=xpcall(function()
			local id=player.UserId;packets[id]=packets[id] or {};incoming[id]=incoming[id] or {}
			assert(not packets[id][packet.kind],"Duplicate complete packet")
			local value=incoming[id][packet.kind]
			if not value then value={total=packet.total,bytes=0,chunks={}};incoming[id][packet.kind]=value end
			assert(value.total==packet.total and packet.index==#value.chunks+1,"Out-of-order evidence chunks")
			value.bytes+=#packet.chunk;assert(value.bytes<=LIMIT,"Exact client evidence exceeds transport bound")
			table.insert(value.chunks,packet.chunk);if packet.index~=value.total then return end
			local decoded=HttpService:JSONDecode(table.concat(value.chunks));assert(decoded.userId==id,"Packet caller identity mismatch")
			if packet.kind=="error" then transportFailure=tostring(decoded.failure)
			elseif packet.kind=="hello" then
				assert(decoded.arrivalOpen==false and decoded.arrivalPhase=="Ready" and decoded.onboardingReady==true,"Actual local readiness incomplete")
			else assert(decoded.caseId==owner and decoded.raceId==raceId and decoded.candidate==CANDIDATE and decoded.source=="native-client-contact-observer","Wrong native observer envelope") end
			packets[id][packet.kind]=decoded;incoming[id][packet.kind]=nil
		end,debug.traceback)
		if not ok then transportFailure=tostring(failure) end
	end)
	remote.Parent=remotes
	local function eligible(player)
		return services.RaceService.IsRaceActive()==true and services.CourseService.GetActiveCourse()==course
			and services.RaceService.GetCurrentRaceId()==raceId and services.PlayerRaceService.IsOfficialRacer(player)==true
			and services.PlayerRaceService.GetPlayerStatus(player)=="Racing"
	end
	local function progress(player)
		assert(eligible(player),"Actual shared official eligibility changed")
		local result=assert(services.ResultsService.GetCurrentRaceResult(),"Actual results absent")
		assert(result.raceId==raceId,"Results race changed")
		local entry
		for _,list in {result.activeRacers or {},result.placements or {},result.dnfs or {}} do for _,item in list do if item.userId==player.UserId then entry=item end end end
		assert(entry and type(entry.falls)=="number","Actual racer result absent")
		return {userId=player.UserId,checkpoint=services.CheckpointService.GetLatestCheckpointIndex(player),falls=entry.falls,official=true,status=services.PlayerRaceService.GetPlayerStatus(player),raceId=raceId}
	end
	local function measured()
		guard();assert(services.CourseService.GetActiveCourse()==course and course==workspace:FindFirstChild("RaceCourse"),"Actual course changed")
		local sample={at=now(),diagnostics=controller.Diagnostics(),players={}}
		for _,player in players do local value=support(player);value.progress=progress(player);table.insert(sample.players,value) end
		table.insert(report.samples,sample);return sample
	end
	local function phase(diag)
		for _,item in diag.cars do if item.name=="Lower_Bay1" then return item end end
		error("Lower Bay1 diagnostics absent")
	end
	local function clientReady(raw,expectedSupport)
		assert(raw and #raw.samples>=3,"Actual paired client readiness absent")
		for _,s in raw.samples do
			assert(s.at<=now()+.2 and now()-s.at<=.6 and s.cp==0 and s.falls==0 and s.official and s.status=="Racing" and s.alive and not s.anchored,"Stale or invalid actual client readiness")
			assert(s.support==expectedSupport and s.floor~="Air" and (s.normalY or 0)>=.95 and s.footGap and math.abs(s.footGap)<=.6,"Actual native support not established")
		end
	end
	task.spawn(function()
		local ok,failure=xpcall(function()
			waitFor("both passive native clients",function() return paired("hello") end,60)
			report.hello={packets[-1].hello,packets[-2].hello};allowed={error=true}
			local oldRace=services.RaceService.GetCurrentRaceId();report.state="Restarting";update();Control.Restart()
			waitFor("fresh real CP0/f0 Racing",function()
				local actual=services.CourseService.GetActiveCourse()
				if not actual or not services.RaceService.IsRaceActive() or services.RaceService.GetCurrentRaceId()==oldRace then return false end
				course,raceId=actual,services.RaceService.GetCurrentRaceId()
				assert(course==workspace:FindFirstChild("RaceCourse") and course:GetAttribute("CandidateId")==CANDIDATE and course:GetAttribute("MoonlitCourse")==true,"Wrong fresh native R04")
				for _,player in players do
					local p=progress(player);assert(p.checkpoint==0 and p.falls==0,"Fresh shared race must start CP0/f0");character(player)
					local encoded=player:GetAttribute("MCPhase2Progress")
					if type(encoded)~="string" then return false end
					local bridge=HttpService:JSONDecode(encoded)
					if bridge.raceId~=raceId or bridge.raceState~="Racing" or bridge.checkpoint~=0 or bridge.falls~=0 or bridge.staged~=true then return false end
					assert(bridge.source=="shared-services" and bridge.candidate==CANDIDATE and bridge.coursePath==course:GetFullName() and bridge.official and bridge.status=="Racing" and now()-bridge.observedAt<=1.5,"Wrong or stale actual server observer bridge")
				end
				return services.MoonlitCitadelService.GetDiagnostics().bound==true
			end,35)
			report.raceId=raceId;report.coursePath=course:GetFullName();report.beforeServiceStop=services.MoonlitCitadelService.GetDiagnostics()
			services.MoonlitCitadelService.Stop();serviceStopped=true
			assert(services.MoonlitCitadelService.GetDiagnostics().bound==false,"Normal binding did not stop")
			for i,player in players do
				local model,human=character(player)
				originalHumans[i]=human
				local baseline={WalkSpeed=12+i,UseJumpPower=true,JumpHeight=6+i/10,JumpPower=40+i,MaxSlopeAngle=38+i}
				local previous=profile(human);setProfile(human,baseline)
				table.insert(report.profiles,{userId=player.UserId,characterPath=model:GetFullName(),previousActual=previous,requestedTestBaseline=baseline,trustedFreshBindingBaseline=profile(human),
					baselineKind="Explicit test baseline after legitimate service Stop; not a historical private profile claim"})
			end
			car=resolve(course,"Obstacles/MovingCars/Lower_Bay1");deck=resolve(car,"Deck")
			local gate=resolve(course,"Obstacles/Gate/GateCourt/Contact")
			local transforms,velocities={},{}
			for _,model in resolve(course,"Obstacles/MovingCars"):GetChildren() do
				if model:IsA("Model") then
					table.insert(transforms,{instance=model,frame=model:GetPivot()})
					for _,part in model:GetDescendants() do if part:IsA("BasePart") and part.CanCollide then table.insert(velocities,{instance=part,velocity=part.AssemblyLinearVelocity}) end end
					local weight=assert(model:FindFirstChild("Counterweight"),"Counterweight reference absent").Value
					assert(weight and weight:IsA("Model"),"Actual counterweight absent");table.insert(transforms,{instance=weight,frame=weight:GetPivot()})
				end
			end
			for _,model in resolve(course,"Obstacles/SwingLanterns"):GetChildren() do if model:IsA("Model") then table.insert(transforms,{instance=model,frame=model:GetPivot()}) end end
			assert(#transforms==11,"Expected four cars, four outside weights and three lanterns")
			report.originalTransforms={};for _,t in transforms do table.insert(report.originalTransforms,{path=t.instance:GetFullName(),frame={t.frame:GetComponents()}}) end
			controller=Runtime.Start(course,eligible,function(player,reason,force)
				local target=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player),"Actual callback checkpoint target absent")
				local call={at=now(),userId=player.UserId,reason=reason,force=force,before=progress(player),rootBefore=xyz(select(3,character(player)).Position),
					recoveryTarget=xyz(target.Position),recoveryFrame={target:GetComponents()}}
				table.insert(report.callbacks,call)
				call.accepted=services.RespawnService.RecoverPlayer(player,reason,force);call.after=progress(player);call.rootAfter=xyz(select(3,character(player)).Position);call.endedAt=now()
				return call.accepted
			end)
			assert(type(controller.Reset)=="function" and type(controller.Stop)=="function" and type(controller.Diagnostics)=="function","Actual returned private runtime controller APIs required")
			report.privateBindingStartedAt=now();report.state="Observing";update()
			remote:SetAttribute("RaceId",raceId);allowed={error=true,observing=true,ready=true,raw=true};remote:SetAttribute("Command","Observe")
			waitFor("both actual passive observers started",function() return paired("observing") end,5)
			waitFor("private movement profile applied",function()
				for _,player in players do local _,h=character(player);for key,value in Config.Movement do if not matchesConfig(h[key],value) then return false end end end
				return controller.Diagnostics().supportedR15==2
			end,3)
			report.placements={bodyPlace(actor,deck),bodyPlace(other,gate)}
			waitFor("actual rising Lower Bay1 rider",function()
				local diag=measured().diagnostics;local value=phase(diag)
				return value.phase=="Rising" and value.passengers==1 and diag.stats.carriedSteps>0 and diag.elapsed>=car:GetAttribute("PhaseSeconds")
			end,18)
			remote:SetAttribute("Command","Ready")
			waitFor("both actual supported client readiness",function() return paired("ready") end,3)
			clientReady(packets[-1].ready,deck:GetFullName());clientReady(packets[-2].ready,gate:GetFullName())
			report.clientReadiness={packets[-1].ready,packets[-2].ready};report.measurementStartAt=packets[-1].ready.samples[1].at
			report.beforeReset=measured();local before=report.beforeReset.diagnostics
			assert(phase(before).phase=="Rising" and phase(before).passengers==1 and before.stats.carriedSteps>0,"Private reset requires actual rising rider")
			for _,p in report.beforeReset.players do assert(p.progress.checkpoint==0 and p.progress.falls==0,"Unexpected progress before Reset") end
			report.preflightRecoveryTargets={};for _,player in players do local target=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player),"Actual checkpoint target absent");table.insert(report.preflightRecoveryTargets,{userId=player.UserId,position=xyz(target.Position)}) end
			report.state="Resetting";update();report.resetCalledAt=now();report.resetAccepted=controller.Reset();report.resetReturnedAt=now()
			report.immediateAfterReset=measured();report.resetTransforms={};report.resetContactVelocities={}
			for _,t in transforms do
				local actual=t.instance:GetPivot();local a,b={actual:GetComponents()},{t.frame:GetComponents()};local maximum=0
				for i=1,12 do maximum=math.max(maximum,math.abs(a[i]-b[i])) end
				table.insert(report.resetTransforms,{path=t.instance:GetFullName(),actual=a,expected=b,maximumComponentError=maximum})
				assert(maximum<=.0001,"Reset did not restore actual mechanism transform")
			end
			for _,v in velocities do
				local actual=v.instance.AssemblyLinearVelocity;local error=(actual-v.velocity).Magnitude
				table.insert(report.resetContactVelocities,{path=v.instance:GetFullName(),actual=xyz(actual),expected=xyz(v.velocity),error=error})
				assert(error<=.0001,"Reset did not restore collidable car contact velocity")
			end
			assert(report.resetAccepted==true and report.immediateAfterReset.diagnostics.elapsed==0,"Private Reset rejected or elapsed not zero")
			assert(report.immediateAfterReset.diagnostics.stats.recoveries==before.stats.recoveries+2 and report.immediateAfterReset.diagnostics.stats.recoveryRejected==before.stats.recoveryRejected,"Reset callback statistics disagree")
			assert(#report.callbacks==2,"Expected exactly two real reset recovery callbacks")
			local seen={};for _,call in report.callbacks do assert(not seen[call.userId] and call.reason=="MoonlitRuntimeReset" and call.force==false and call.accepted==true and call.before.falls==0 and call.after.falls==1 and call.after.checkpoint==0,"Real reset recovery callback failed");seen[call.userId]=true end
			report.actualRecoveryTargets={}
			for _,player in players do
				for _,call in report.callbacks do if call.userId==player.UserId then table.insert(report.actualRecoveryTargets,{userId=player.UserId,position=call.recoveryTarget,recordedAt=call.at}) end end
			end
			for _,item in report.immediateAfterReset.diagnostics.cars do assert(item.passengers==0 and item.phase=="LowDwell","Reset kept stale passengers/phase") end
			local resetStats=report.immediateAfterReset.diagnostics.stats;local settled={};local cycle=assert(car:GetAttribute("CycleSeconds"));assert(cycle>0 and cycle<=20,"Bounded actual cycle required")
			report.state="CheckingNoStaleCarry";update();local endAt=now()+cycle+1;local observedPhases={};local lastAt=report.resetReturnedAt
			repeat
				local sample=measured();local diag=sample.diagnostics
				assert(sample.at>=lastAt and sample.at-lastAt<=.6,"Post-reset server observation gap exceeds .6 bound");lastAt=sample.at
				observedPhases[phase(diag).phase]=true
				assert(diag.stats.carriedSteps==resetStats.carriedSteps and diag.stats.carryProbes==resetStats.carryProbes,"Stale actual carry after reset")
				for _,item in diag.cars do assert(item.passengers==0,"Stale passenger after reset") end
				for i,p in sample.players do
					assert(p.progress.checkpoint==0 and p.progress.falls==1,"Reset changed CP0 or added unrelated recovery")
					for key,value in Config.Movement do assert(matchesConfig(p.profile[key],value),"Reset changed the active course movement profile") end
					assert(p.profile.JumpPower==report.profiles[i].trustedFreshBindingBaseline.JumpPower,"Reset changed the saved unused JumpPower")
					if sample.at>=report.resetReturnedAt+1 then
						local target=report.actualRecoveryTargets[i].position;local v=Vector3.new(p.root[1],p.root[2],p.root[3]);local delta=v-Vector3.new(target[1],target[2],target[3])
						assert(Vector3.new(delta.X,0,delta.Z).Magnitude<1.5 and math.abs(delta.Y)<6,"Reset racer did not settle at real checkpoint target")
						assert(p.networkOwnerUserId==p.userId and p.support==gate:GetFullName() and p.floor~="Air" and (p.normalY or 0)>=.95 and type(p.footGap)=="number","Recovered client-owned server body lacks actual Gate ray/floor/normal evidence")
						if not settled[i] then settled[i]=v end
						assert((v-settled[i]).Magnitude<.6,"Recovered racer drift exceeds existing .6 bound")
					end
				end
				update();task.wait(.1)
			until now()>=endAt
			for _,name in {"LowDwell","Rising","HighDwell","Descending"} do assert(observedPhases[name],"Post-reset complete cycle phase absent") end
			report.postResetObservedPhases=observedPhases
			report.measurementEndAt=now();report.noStaleCarrySeconds=report.measurementEndAt-report.resetReturnedAt
			remote:SetAttribute("SliceStartAt",report.measurementStartAt);remote:SetAttribute("SliceEndAt",report.measurementEndAt);remote:SetAttribute("Command","Collect")
			waitFor("both complete original client traces",function() return paired("raw") end,15)
			for _,player in players do
				local raw=packets[player.UserId].raw;report.clients[tostring(player.UserId)]=raw;persist(evidence,"ClientRaw_"..math.abs(player.UserId),raw)
				assert(raw.state=="Observed" and not raw.failure and type(raw.exactSlice)=="table","Actual client observer failed")
				assert(raw.exactSlice.userId==player.UserId and raw.exactSlice.caseId==owner and raw.exactSlice.raceId==raceId and raw.exactSlice.candidate==CANDIDATE
					and raw.exactSlice.sliceStartAt==report.measurementStartAt and raw.exactSlice.sliceEndAt==report.measurementEndAt,"Exact actual client slice envelope differs")
				local selected={}
				for _,s in raw.samples do if s.at>=report.measurementStartAt-.35 and s.at<=report.measurementEndAt+.35 then table.insert(selected,s) end end
				assert(sameValue(selected,raw.exactSlice.samples),"Exact slice differs from original full native trace")
				local samples=raw.exactSlice.samples;assert(#samples>10 and samples[1].at<=report.measurementStartAt+.35 and samples[#samples].at>=report.measurementEndAt-.35,"Exact client reset window incomplete")
				local last,settle;local count=0
				for _,s in samples do
					if last then assert(s.at>last and s.at-last<=.6,"Actual client evidence gap") end;last=s.at
					assert(s.cp==0 and s.status=="Racing" and s.official and s.alive and not s.anchored,"Actual client progress/character invalid")
					assert(s.falls==0 or s.falls==1,"Unexpected client fall count")
					if s.at<report.resetCalledAt then assert(s.falls==0,"Client recorded premature recovery") end
					if s.at>=report.resetReturnedAt+1 then
						assert(s.falls==1 and s.support==gate:GetFullName() and s.floor~="Air" and (s.normalY or 0)>=.95 and s.footGap and math.abs(s.footGap)<=.6,"Actual recovered client not supported at GateCourt")
						local v=Vector3.new(s.position[1],s.position[2],s.position[3]);settle=settle or v;assert((v-settle).Magnitude<.6,"Actual client stale movement after reset");count+=1
					end
				end
				assert(count>=10,"Insufficient recovered actual client observations")
				for _,serverSample in report.samples do
					if serverSample.at<report.resetReturnedAt+1 or serverSample.at>report.measurementEndAt then continue end
					local actualPlayer;for _,p in serverSample.players do if p.userId==player.UserId then actualPlayer=p;break end end
					assert(actualPlayer and actualPlayer.networkOwnerUserId==player.UserId,"Server/client footing comparison has wrong actual network owner")
					local nearest,difference
					for _,s in samples do
						local delta=math.abs(s.at-serverSample.at)
						if s.at>=report.resetReturnedAt+1 and (not difference or delta<difference) then nearest,difference=s,delta end
					end
					assert(nearest and difference<=.35,"Recovered server sample has no fresh actual owning-client footing observation")
					table.insert(report.serverClientFootingComparisons,{userId=player.UserId,networkOwnerUserId=actualPlayer.networkOwnerUserId,
						serverAt=serverSample.at,clientAt=nearest.at,timeDifference=difference,serverRoot=actualPlayer.root,clientRoot=nearest.position,
						serverFootGap=actualPlayer.footGap,clientFootGap=nearest.footGap,rootHeightDifference=actualPlayer.root[2]-nearest.position[2],
						serverGapWithinClientFootingBound=math.abs(actualPlayer.footGap)<=.6,actualClientFootingWithinBound=math.abs(nearest.footGap)<=.6})
				end
			end
			report.serverFootingDiscrepancySamples=0
			for _,comparison in report.serverClientFootingComparisons do if not comparison.serverGapWithinClientFootingBound then report.serverFootingDiscrepancySamples+=1 end end
		end,debug.traceback)
		if not paired("raw") and raceId and paired("observing") then
			remote:SetAttribute("Command","Retain")
			local deadline=os.clock()+8
			repeat if paired("raw") then break end;task.wait(.05) until os.clock()>=deadline
			for _,player in players do
				local raw=packets[player.UserId] and packets[player.UserId].raw
				if raw then report.clients[tostring(player.UserId)]=raw;if not evidence:FindFirstChild("ClientRaw_"..math.abs(player.UserId)) then persist(evidence,"ClientRaw_"..math.abs(player.UserId),raw) end end
			end
		end
		report.cleanup={};report.state="Cleanup";update()
		local cleanupOk,cleanupFailure=xpcall(function()
			if controller then controller.Stop();report.cleanup.privateStopped=true end
		end,debug.traceback)
		local profileFailures={}
		for i,entry in report.profiles do
			local restored,reason=xpcall(function()
				local human=originalHumans[i];assert(human and human.Parent,"Original Humanoid removed before cleanup")
				entry.afterPrivateStop=profile(human);entry.trustedBaselineRestored=sameProfile(human,entry.trustedFreshBindingBaseline)
				setProfile(human,entry.previousActual);entry.afterRealPreviousRestore=profile(human)
				assert(sameProfile(human,entry.previousActual),"Real previous profile cleanup failed")
				assert(entry.trustedBaselineRestored,"Private Stop did not restore exact fresh-binding baseline")
			end,debug.traceback)
			if not restored then table.insert(profileFailures,tostring(reason)) end
		end
		report.cleanup.profileFailures=profileFailures
		if #profileFailures>0 then cleanupOk=false;cleanupFailure=tostring(cleanupFailure or "")..table.concat(profileFailures,"\n") end
		local resumeOk,resumeFailure=pcall(function()
			if serviceStopped then
				services.MoonlitCitadelService.Start()
				local deadline=os.clock()+3
				repeat report.cleanup.normalBinding=services.MoonlitCitadelService.GetDiagnostics();if report.cleanup.normalBinding.bound and report.cleanup.normalBinding.supportedR15==2 then break end;task.wait(.05) until os.clock()>=deadline
				assert(report.cleanup.normalBinding.bound and report.cleanup.normalBinding.raceId==raceId and report.cleanup.normalBinding.supportedR15==2,"Normal service binding did not resume")
				report.cleanup.afterNormalProfiles={}
				for _,player in players do
					local _,human=character(player);local value=profile(human);table.insert(report.cleanup.afterNormalProfiles,{userId=player.UserId,profile=value})
					for key,expected in Config.Movement do assert(matchesConfig(value[key],expected),"Normal service movement profile did not resume") end
				end
			end
		end)
		if connection then connection:Disconnect() end;remote:SetAttribute("DriverActive",false);remote:SetAttribute("Command","Done")
		report.cleanup.success=cleanupOk and resumeOk;report.cleanup.failure=not cleanupOk and tostring(cleanupFailure) or not resumeOk and tostring(resumeFailure) or nil
		report.failure=not ok and tostring(failure) or report.cleanup.failure;report.passed=ok and cleanupOk and resumeOk
		report.state=if report.passed then "Complete" else "Failed";report.endedAt=now();update();persist(evidence,"ServerRaw",report)
	end)
	update();return {Current=Cases.Current,Status=Cases.Status,Stop=Cases.Stop}
end

function Cases.ClientCurrent() return clientCurrent end
function Cases.ClientWatch(options)
	fixture(false);options=options or {};assert(options.authorizedPassiveNative==true,"Explicit passive native observation authorization required")
	assert(not clientCurrent or terminal(clientCurrent.state),"Prior private reset client active")
	local player=Players.LocalPlayer;assert(player.UserId==-1 or player.UserId==-2,"Actual native client required")
	local tools=game.ReplicatedStorage.MoonlitPhase2Tools
	local Contact=require(tools.ContactCases)
	local function inactive()
		for _,name in {"ClientProbe","ClientSuite","ContactCases","BoundaryCases"} do
			local module=require(tools[name]);local prior=if name=="BoundaryCases" then module.ClientCurrent() else module.Current()
			assert(not prior or terminal(prior.state),"Prior native client observer active")
		end
		assert(player:GetAttribute("ArrivalOpen")==false and player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("OnboardingReady")==true,"Actual local readiness incomplete")
	end
	inactive()
	local report={state="Waiting",userId=player.UserId,startedAt=now()};clientCurrent=report
	task.spawn(function()
		local observer,remote,owner,nonce,raceId,localEvidence;local collected=false
		local function send(kind,value)
			local encoded=HttpService:JSONEncode(value);assert(#encoded<=LIMIT,"Original client evidence exceeds bounded transport")
			for index=1,math.ceil(#encoded/CHUNK) do
				remote:FireServer({owner=owner,nonce=nonce,caseId=owner,raceId=raceId or "",kind=kind,index=index,total=math.ceil(#encoded/CHUNK),chunk=encoded:sub((index-1)*CHUNK+1,index*CHUNK)})
				if index<math.ceil(#encoded/CHUNK) then task.wait(.04) end
			end
		end
		local ok,failure=xpcall(function()
			local began=os.clock();local deadline=began+60
			repeat
				for _,item in game.ReplicatedStorage.Remotes:GetChildren() do if item:IsA("RemoteEvent") and item:GetAttribute("CreatedBy")==MARKER and item:GetAttribute("DriverActive")==true then assert(not remote or remote==item,"Multiple private reset transports");remote=item end end
				if not remote then task.wait(.05) end
			until remote or os.clock()>=deadline
			assert(remote,"Private reset transport absent");owner=assert(remote:GetAttribute("DriverOwner"));nonce=assert(remote:GetAttribute("Nonce"))
			assert(remote:GetAttribute("CandidateId")==CANDIDATE and owner:match("^MC_P2_C01_R04_PrivateReset_"),"Wrong scoped native transport")
			report.owner=owner;localEvidence=Instance.new("Folder");localEvidence.Name=owner;localEvidence:SetAttribute("CreatedBy",MARKER);localEvidence.Parent=player:WaitForChild("PlayerScripts")
			report.evidencePath=localEvidence:GetFullName();send("hello",{userId=player.UserId,arrivalOpen=player:GetAttribute("ArrivalOpen"),arrivalPhase=player:GetAttribute("ArrivalPhase"),onboardingReady=player:GetAttribute("OnboardingReady")})
			local readySent=false
			repeat
				fixture(false);assert(os.clock()-began<180,"Passive private reset watcher watchdog expired")
				assert(player:GetAttribute("ArrivalOpen")==false and player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("OnboardingReady")==true,"Native local readiness changed")
				local command=remote:GetAttribute("Command")
				if command=="Observe" and not observer then
					inactive();raceId=assert(remote:GetAttribute("RaceId"));local course=assert(workspace:FindFirstChild("RaceCourse"))
					assert(course:GetAttribute("CandidateId")==CANDIDATE,"Wrong native course")
					local encoded=player:GetAttribute("MCPhase2Progress");local bridge=type(encoded)=="string" and HttpService:JSONDecode(encoded)
					if bridge and bridge.raceId==raceId and bridge.status=="Racing" and bridge.official and now()-bridge.observedAt<=1.5 then
						observer=Contact.ObserveClient(course,{caseId=owner,stage="Lower",bay=1,durationSeconds=90});report.state="Observing"
						send("observing",{userId=player.UserId,source="native-client-contact-observer",candidate=CANDIDATE,caseId=owner,raceId=raceId})
					end
				elseif command=="Ready" and not readySent then
					assert(observer,"Passive observation not started before readiness")
					local raw=Contact.Current()
					if #raw.samples>=3 then
						local ready=Contact.Readiness();local valid=true
						local expected=if player.UserId==-1 then "Workspace.RaceCourse.Obstacles.MovingCars.Lower_Bay1.Deck" else "Workspace.RaceCourse.Obstacles.Gate.GateCourt.Contact"
						for _,s in ready.samples do if s.support~=expected or s.floor=="Air" or (s.normalY or 0)<.95 or not s.footGap or math.abs(s.footGap)>.6 or s.cp~=0 or s.falls~=0 then valid=false end end
						if valid then send("ready",ready);readySent=true end
					end
				elseif command=="Collect" and not collected then
					local startAt,endAt=remote:GetAttribute("SliceStartAt"),remote:GetAttribute("SliceEndAt")
					assert(type(startAt)=="number" and type(endAt)=="number" and endAt>=startAt,"Exact measured window absent")
					if now()>=endAt+.35 then
						local slice=Contact.EvidenceSlice(startAt,endAt);if Contact.Current().state=="Observing" then observer.Stop() end;observer=nil
						local raw=Contact.Current();raw=table.clone(raw);raw.exactSlice=slice
						persist(localEvidence,"OriginalClientRaw",raw);send("raw",raw);report.state="Retained";collected=true
					end
				elseif command=="Retain" and not collected and observer then
					if Contact.Current().state=="Observing" then observer.Stop() end;observer=nil
					local raw=Contact.Current();persist(localEvidence,"FailureOriginalClientRaw",raw);send("raw",raw);report.state="Retained";collected=true
				end
				if command=="Done" or remote:GetAttribute("DriverActive")~=true then break end
				if observer then assert(not Contact.Current().failure,Contact.Current().failure or "Passive observer failure") end
				task.wait(.05)
			until false
		end,debug.traceback)
		if observer then
			if Contact.Current().state=="Observing" then observer.Stop() end
			local raw=Contact.Current();if localEvidence then pcall(persist,localEvidence,"FailureOriginalClientRaw",raw) end
			if remote then pcall(send,"raw",raw) end
		end
		if not ok then report.failure=tostring(failure);if remote then pcall(send,"error",{userId=player.UserId,failure=report.failure}) end end
		report.state=if ok then "Observed" else "Failed";report.endedAt=now();if localEvidence then persist(localEvidence,"WatcherRaw",report) end
	end)
	return {Current=Cases.ClientCurrent}
end
return Cases
