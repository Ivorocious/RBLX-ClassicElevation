local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local BASE = "docs/artifacts/moonlit-citadel/phase2/evidence/"
local input = assert(process.args[1], "Provide native evidence RBXM")
local output = assert(process.args[2], "Provide a fresh extraction directory")
local parentPath = process.args[3] or "ServerStorage.MoonlitPhase2Evidence"
input,output = input:gsub("\\","/"),output:gsub("\\","/"):gsub("/$","")
assert(input:sub(1,#BASE)==BASE and input:sub(-5)==".rbxm" and not input:find("%.%."), "Input must be a saved Phase2 evidence RBXM")
assert(output:sub(1,#BASE)==BASE and #output>#BASE and not output:find("%.%."), "Output must stay under Phase2 evidence")
assert(parentPath:match("^[%w_%.]+$"), "Provide an explicit safe original native parent path")
local nativeBytes = fs.readFile(input)
local roots = roblox.deserializeModel(nativeBytes)
assert(#roots>=1, "Empty evidence export")
local planned,records,decoded,hierarchy = {},{},{},{}
local function safe(name)
	assert(name:match("^[%w_%-]+$") and name~="CON" and name~="NUL" and name~="PRN", "Unsafe native filename component "..name)
	return name
end
local function plain(value)
	local kind=typeof(value)
	if kind=="Vector3" then return {type=kind,components={value.X,value.Y,value.Z}} end
	if kind=="Color3" then return {type=kind,components={value.R,value.G,value.B}} end
	if kind=="CFrame" then return {type=kind,components={value:GetComponents()}} end
	assert(type(value)=="string" or type(value)=="number" or type(value)=="boolean", "Unsupported native attribute type "..kind)
	return value
end
local function plan(relative,bytes)
	assert(not planned[relative], "Duplicate extracted output "..relative)
	planned[relative]=bytes
end
local function visit(item,path)
	path=if path=="" then safe(item.Name) else path.."/"..safe(item.Name)
	local attributes={}
	for name,value in item:GetAttributes() do attributes[name]=plain(value) end
	table.insert(hierarchy,{exportPath=path,nativePath=parentPath.."."..path:gsub("/","."),className=item.ClassName,attributes=attributes})
	local chunks,count,bytes={},item:GetAttribute("JSONChunks"),item:GetAttribute("JSONBytes")
	local children=item:GetChildren()
	local names={}
	for _,child in children do
		assert(not names[child.Name], "Duplicate native child name under "..path);names[child.Name]=true
		if child.Name:match("^JSON_") then
			assert(child:IsA("StringValue"), "JSON chunk is not StringValue: "..path.."/"..child.Name)
			local number=child.Name:match("^JSON_(%d%d%d)$")
			assert(number, "Malformed JSON chunk name: "..path.."/"..child.Name)
			chunks[tonumber(number)]=child
		end
	end
	if count~=nil or bytes~=nil or next(chunks) then
		assert(type(count)=="number" and count%1==0 and count>=1 and count<=999, "Missing/invalid JSONChunks at "..path)
		assert(type(bytes)=="number" and bytes%1==0 and bytes>=1 and bytes<=64000000, "Missing/invalid JSONBytes at "..path)
		local joined,manifest={},{}
		local actualCount=0;for index in chunks do assert(index>=1 and index<=count,"Extra native JSON chunk at "..path);actualCount+=1 end
		assert(actualCount==count,"Missing native JSON chunk at "..path)
		assert(#children==count,"Extra native child in chunked report at "..path)
		for index=1,count do
			local chunk=assert(chunks[index], "Missing ordered native chunk at "..path)
			assert(chunk.Name==string.format("JSON_%03d",index) and #chunk.Value>0,"Empty/noncanonical native chunk")
			table.insert(joined,chunk.Value)
			table.insert(manifest,{name=chunk.Name,bytes=#chunk.Value,sha256=serde.hash("sha256",chunk.Value),nativePath=parentPath.."."..path:gsub("/",".").."."..chunk.Name})
		end
		local raw=table.concat(joined)
		assert(#raw==bytes,"Native JSONBytes disagreement/truncation at "..path)
		local value=serde.decode("json",raw)
		assert(type(value)=="table","Native report is not JSON object/array")
		plan(path..".json",raw);decoded[path]=value
		table.insert(records,{exportPath=path,nativePath=parentPath.."."..path:gsub("/","."),file=path..".json",bytes=#raw,
			sha256=serde.hash("sha256",raw),jsonChunks=count,chunkManifest=manifest})
	else
		if item:IsA("StringValue") then
			local raw=item.Value
			local suffix=if item.Name:find("JSON",1,true) then ".json" else ".txt"
			if suffix==".json" then decoded[path]=serde.decode("json",raw) end
			plan(path..suffix,raw)
			table.insert(records,{exportPath=path,nativePath=parentPath.."."..path:gsub("/","."),file=path..suffix,bytes=#raw,sha256=serde.hash("sha256",raw),unchunked=true})
		end
		for _,child in children do visit(child,path) end
	end
end
local rootNames={}
for _,root in roots do assert(not rootNames[root.Name],"Duplicate export root");rootNames[root.Name]=true;visit(root,"") end
assert(#records>0,"Export has no retained evidence reports")
table.sort(records,function(a,b) return a.exportPath<b.exportPath end)
table.sort(hierarchy,function(a,b) return a.exportPath<b.exportPath end)
local function identical(a,b)
	if type(a)~=type(b) then return false end
	if type(a)~="table" then return a==b end
	for key,value in a do if not identical(value,b[key]) then return false end end
	for key in b do if a[key]==nil then return false end end
	return true
end
local function vector(v)
	assert(type(v)=="table" and #v==3,"Missing recorded vector")
	for _,n in v do assert(type(n)=="number" and n==n and math.abs(n)<math.huge,"Nonfinite recorded vector") end
	return roblox.Vector3.new(v[1],v[2],v[3])
end
local configPath="src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"
local configBytes=fs.readFile(configPath)
local declaredBay2Delay=tonumber(configBytes:match("SecondBayDelay%s*=%s*([%d%.]+)"))
assert(declaredBay2Delay,"Current R04 declared second-bay offset absent")
local validation={scope="Offline recheck of retained native observations; artifact extraction is not a fresh final review",cases={},failedCases={},gaps={},
	declaredBay2Delay=declaredBay2Delay,referenceConfigSha256=serde.hash("sha256",configBytes),phaseOffsetSource="Current durable R04 declared offset; native car PhaseSeconds is not embedded in the report"}
local function gap(text) table.insert(validation.gaps,text) end
local function clientEnvelope(server,slice,raw,index)
	local baseline=server.before.players[index]
	assert(slice.source=="native-client-contact-observer" and slice.candidate==server.candidate and slice.caseId==server.caseId
		and slice.raceId==server.raceId and slice.userId==baseline.userId and not slice.failure,"Wrong/failed exact client envelope")
	assert(raw.source==slice.source and raw.userId==slice.userId and raw.candidate==slice.candidate and raw.caseId==slice.caseId
		and raw.raceId==slice.raceId and raw.state=="Observed" and not raw.failure,"Wrong/failed retained full client observer")
	assert(slice.sliceStartAt==server.measurementStartedAt and slice.sliceEndAt==server.measurementEndedAt and slice.rawReportRetained==true,"Slice is not exact measured window")
	assert(type(raw.samples)=="table" and #raw.samples>=slice.rawSampleCount,"Original client samples missing")
	local expected={}
	for _,sample in raw.samples do if sample.at>=server.measurementStartedAt-.35 and sample.at<=server.measurementEndedAt+.35 then table.insert(expected,sample) end end
	assert(identical(expected,slice.samples),"Exact slice differs from complete original client trace")
	local names={};for _,part in raw.initialBody or {} do names[part.name]=true end
	assert(names.HumanoidRootPart and names.UpperTorso and names.LowerTorso and names.LeftFoot and names.RightFoot,"Original actual R15 body evidence missing")
	return baseline
end
local function clientCheck(server,slice,raw,index)
	local baseline=clientEnvelope(server,slice,raw,index)
	local summary={userId=slice.userId,rawSamples=#raw.samples,sliceSamples=#slice.samples,deckSamples=0,maximumRelative3D=0,
		maximumGap=0,maximumAbsFootGap=0,minimumNormalY=1,postRecoverySamples=0}
	local firstRelative,firstSettled,previous,postMaximum=nil,nil,nil,0
	for _,sample in slice.samples do
		assert(sample.raceId==server.raceId and sample.status=="Racing" and sample.official and sample.alive and not sample.anchored,"Actual client state changed")
		assert(sample.cp==baseline.checkpoint,"Actual client checkpoint changed")
		if previous then assert(sample.at>previous and sample.at-previous<=.6,"Actual client sample coverage gap");summary.maximumGap=math.max(summary.maximumGap,sample.at-previous) end
		previous=sample.at;summary.firstAt=summary.firstAt or sample.at;summary.lastAt=sample.at
		local positive=index==1 and (server.case=="overhead" or server.case=="side")
		local after=positive and server.recoveryServerTime and sample.at>=server.recoveryServerTime+.5
		local transition=positive and server.recoveryServerTime and math.abs(sample.at-server.recoveryServerTime)<=.5
		if after then
			assert(sample.falls==baseline.falls+1 and sample.support~=server.deck,"Affected actual client lacks recovery")
			if sample.at>=server.recoveryServerTime+1 then
				local p=vector(sample.position);firstSettled=firstSettled or p;postMaximum=math.max(postMaximum,(p-firstSettled).Magnitude);summary.postRecoverySamples+=1
			end
		elseif not transition then
			assert(sample.falls==baseline.falls and sample.support==server.deck and sample.floor~="Air" and sample.normalY>=.95
				and math.abs(sample.footGap)<=.6,"Actual native client lost physical Deck support")
			summary.deckSamples+=1;summary.maximumAbsFootGap=math.max(summary.maximumAbsFootGap,math.abs(sample.footGap));summary.minimumNormalY=math.min(summary.minimumNormalY,sample.normalY)
			local r=vector(sample.relative);firstRelative=firstRelative or r;summary.maximumRelative3D=math.max(summary.maximumRelative3D,(r-firstRelative).Magnitude)
			assert(summary.maximumRelative3D<=server.relativeTolerance and server.relativeTolerance<=.8,"Existing actual client drift bound exceeded")
		end
	end
	assert(summary.firstAt and summary.firstAt<=server.measurementStartedAt+.35 and summary.lastAt>=server.measurementEndedAt-.35 and summary.deckSamples>=3,"Actual paired client coverage insufficient")
	if index==1 and (server.case=="overhead" or server.case=="side") then assert(summary.postRecoverySamples>=2 and postMaximum<.6,"Actual recovered client not settled") end
	summary.postRecoveryMaximumDrift=postMaximum
	return summary
end
local function hazardClientCheck(server,slice,raw,index)
	local baseline=clientEnvelope(server,slice,raw,index)
	local positive=index==1 and (server.case=="red-body" or server.case=="cage-body")
	local expectedSupport=server.samples[#server.samples].players[index].support
	assert(type(expectedSupport)=="string","Final actual native standing support absent")
	local summary={userId=slice.userId,rawSamples=#raw.samples,sliceSamples=#slice.samples,scope="Hazard identity/progress/timing and actual standing support; LowerBay1 relative pose is unused",
		actualSupport=expectedSupport,supportedSamples=0,maximumGap=0,maximumAbsFootGap=0,minimumNormalY=1,postRecoverySamples=0,postRecoveryMaximumDrift=0}
	local previous,settled
	for _,sample in slice.samples do
		assert(sample.raceId==server.raceId and sample.status=="Racing" and sample.official and sample.alive and not sample.anchored,"Hazard native client state changed")
		assert(sample.cp==baseline.checkpoint,"Hazard native client checkpoint changed")
		if previous then assert(sample.at>previous and sample.at-previous<=.6,"Hazard native client coverage gap");summary.maximumGap=math.max(summary.maximumGap,sample.at-previous) end
		previous=sample.at;summary.firstAt=summary.firstAt or sample.at;summary.lastAt=sample.at
		local after=positive and sample.at>=assert(server.recoveryServerTime,"Positive hazard recovery time absent")+.5
		if positive then assert(sample.falls==baseline.falls or sample.falls==baseline.falls+1,"Hazard client unexpected recovery count")
		else assert(sample.falls==baseline.falls,"Unaffected/negative hazard client recovered") end
		if after then assert(sample.falls==baseline.falls+1,"Hazard client lacks recorded real recovery") end
		if not positive or after then
			assert(sample.support==expectedSupport and sample.floor~="Air" and sample.normalY>=.95 and math.abs(sample.footGap)<=.6,"Hazard client lost actual standing support")
			summary.supportedSamples+=1;summary.maximumAbsFootGap=math.max(summary.maximumAbsFootGap,math.abs(sample.footGap));summary.minimumNormalY=math.min(summary.minimumNormalY,sample.normalY)
		end
		if positive and sample.at>=server.recoveryServerTime+1 then
			local p=vector(sample.position);settled=settled or p;summary.postRecoverySamples+=1
			summary.postRecoveryMaximumDrift=math.max(summary.postRecoveryMaximumDrift,(p-settled).Magnitude)
		end
	end
	assert(summary.firstAt and summary.firstAt<=server.measurementStartedAt+.35 and summary.lastAt>=server.measurementEndedAt-.35 and summary.supportedSamples>=3,"Hazard exact client window incomplete")
	if positive then assert(summary.postRecoverySamples>=2 and summary.postRecoveryMaximumDrift<.6,"Hazard recovered native client did not settle") end
	return summary
end
local function serverOutcome(server,positive)
	for index,before in server.before.players do
		local after=server.after.players[index]
		assert(after.userId==before.userId and after.raceId==server.raceId and after.official and after.status=="Racing" and not after.finished,"Actual server final participant changed")
		assert(after.checkpoint==before.checkpoint and after.falls==before.falls+(if positive and index==1 then 1 else 0),"Actual server hazard/obstruction recovery outcome differs")
	end
	if positive then
		assert(server.postRecoveryDrift<.6,"Server original recovered body drift exceeds existing bound")
		local delta=vector(server.after.players[1].root)-vector(server.recoveryTarget)
		assert(math.sqrt(delta.X^2+delta.Z^2)<1.5 and math.abs(delta.Y)<6,"Server original recovery target differs")
	end
end
local function hazardServerCheck(server)
	local positive=server.case=="red-body" or server.case=="cage-body"
	assert(positive or server.case=="light-miss" or server.case=="accessory-miss","Unknown recorded hazard case")
	serverOutcome(server,positive)
	local summary={target=server.target,initialBodyParts=server.initialNativeOverlap.bodyParts,initialAccessoryParts=server.initialNativeOverlap.accessoryParts,
		bodyOverlapSamples=0,accessoryOverlapSamples=0,lightExposureSamples=0,maximumSampleGap=0,
		hazardHitDelta=server.after.diagnostics.stats.hazardHits-server.before.diagnostics.stats.hazardHits,serverPostRecoveryDrift=server.postRecoveryDrift,
		serverFinalSupport={}}
	local previous
	for _,sample in server.samples do
		if previous then assert(sample.at>previous and sample.at-previous<=.6,"Hazard native server coverage gap");summary.maximumSampleGap=math.max(summary.maximumSampleGap,sample.at-previous) end
		previous=sample.at;summary.firstAt=summary.firstAt or sample.at;summary.lastAt=sample.at
		if sample.visibleBodyHits>0 then summary.bodyOverlapSamples+=1 end
		if sample.accessoryHits>0 then summary.accessoryOverlapSamples+=1 end
		if sample.inLightRange then summary.lightExposureSamples+=1 end
		if not positive then assert(sample.visibleBodyHits==0,"Hazard negative recorded visible body contact") end
		for index,player in sample.players do
			local before=server.before.players[index]
			assert(player.userId==before.userId and player.status=="Racing" and player.cp==before.checkpoint,"Hazard native server participant/progress changed")
			assert(player.falls==before.falls or (positive and index==1 and player.falls==before.falls+1),"Hazard server unexpected actual recovery")
		end
	end
	assert(summary.firstAt<=server.measurementStartedAt+.35 and summary.lastAt>=server.measurementEndedAt-.35,"Hazard native server window incomplete")
	assert(summary.bodyOverlapSamples==server.bodyOverlapSamples and summary.accessoryOverlapSamples==server.accessoryOverlapSamples
		and summary.lightExposureSamples==server.lightExposureSamples,"Hazard native counters differ from original trace")
	if positive then assert(summary.initialBodyParts>0 and summary.bodyOverlapSamples>0 and summary.hazardHitDelta>0,"Actual visible hazard hit/recovery evidence missing")
	else assert(summary.initialBodyParts==0 and summary.hazardHitDelta==0,"Hazard negative setup/body-hit counter differs") end
	if server.case=="light-miss" then assert(summary.lightExposureSamples>0,"Actual native light-range exposure missing") end
	if server.case=="accessory-miss" then assert(summary.initialAccessoryParts>0 or summary.accessoryOverlapSamples>0,"Actual native accessory-only contact missing") end
	for _,player in server.samples[#server.samples].players do
		assert(type(player.support)=="string" and player.supportNormal[2]>=.95 and math.abs(player.footGap)<=.6,"Hazard final actual server standing support missing")
		table.insert(summary.serverFinalSupport,{userId=player.userId,path=player.support,footGap=player.footGap,normalY=player.supportNormal[2]})
	end
	return summary
end
for path,suite in decoded do
	if path:match("/SuiteRaw$") and suite.driverOwner then
		validation.suite={owner=suite.driverOwner,state=suite.state,passed=suite.passed,failure=suite.failure,planned=suite.plannedCaseNames,
			actualClientUserIds=suite.actualClientUserIds,evidenceKind=suite.evidenceKind}
		if suite.passed~=true or suite.state~="Complete" then gap("Native suite failed/incomplete: "..tostring(suite.failure))
		else assert(#suite.cases==#suite.plannedCaseNames,"Passing native suite omits selected cases") end
		assert(type(suite.cases)=="table","Native suite lacks case list")
		local rootPath=path:gsub("/SuiteRaw$","")
		local handshake=decoded[rootPath.."/InitialClientHandshake"]
		if handshake then
			validation.clientHandshake=handshake
			assert(#handshake==2 and handshake[1].userId==-1 and handshake[2].userId==-2,"Actual two-player handshake differs")
			for _,hello in handshake do assert(hello.localArrivalOpen==false and hello.onboardingReady==true and hello.arrivalPhase=="Ready","Recorded native arrival incomplete") end
		else gap("Initial paired native client handshake is absent") end
		for index,entry in suite.cases do
			local casePath=string.format("%s/Case_%02d_%s",rootPath,index,entry.name)
			local summary={name=entry.name,caseId=entry.caseId,raceId=entry.raceId,recordedPassed=entry.passed,nativePath=entry.evidencePath}
			table.insert(validation.cases,summary)
			local checked,failure=pcall(function()
				local server=assert(decoded[casePath.."/ServerRaw"],"Full original server report missing")
				assert(server.state=="Complete" and server.passed==true and not server.failure and not server.storageFailure,"Recorded actual server did not pass")
				assert(server.caseId==entry.caseId and server.raceId==entry.raceId and server.candidate==suite.candidate,"Server/suite case identity differs")
				assert(server.actualClientsPresent==2 and #server.actualClientUserIds==2 and server.actualClientUserIds[1]~=server.actualClientUserIds[2],"Actual native participant count differs")
				assert(server.before.diagnostics.bound and server.after.diagnostics.bound and server.candidate=="MC_P2_C01_R04","Actual recorded native R04 mechanisms not bound")
				for actorIndex,id in server.actualClientUserIds do
					local before=server.before.players[actorIndex]
					assert(before.userId==id and before.official and before.status=="Racing" and before.raceId==server.raceId
						and before.checkpoint==0 and before.falls==0 and not before.finished,"Recorded clean actual official CP0/f0 baseline missing")
				end
				summary.case=server.case;summary.deck=server.deck;summary.actualClientUserIds=server.actualClientUserIds
				summary.measuredSeconds=server.measurementEndedAt-server.measurementStartedAt;summary.serverSamples=#server.samples
				summary.serverSupportMisses=server.supportMisses;summary.serverMaximumRelativeDrift=server.maximumRelativeDrift
				summary.runtimeDeltas=server.measuredRuntimeDeltas;summary.observedPhases=server.observedPhases
				summary.runtimeMeasurementElapsedStart=server.measurementBefore and server.measurementBefore.diagnostics.elapsed
				summary.runtimeMeasurementElapsedEnd=server.after.diagnostics.elapsed
				local lift=server.case=="adjacent" or server.case=="overhead" or server.case=="side"
				if lift then
					for actorIndex,value in server.supportMisses or {} do
						if value>0 or server.maximumRelativeDrift[actorIndex]>.8 then summary.serverPoseDisagreementRecorded=true end
					end
				end
				if summary.serverPoseDisagreementRecorded then gap(entry.name..": server pose/rays disagree with simultaneous clients; passing client rays do not prove zero server disagreement") end
				summary.clients={}
				for actorIndex,id in server.actualClientUserIds do
					assert(id==-1 or id==-2,"Unexpected actual native user ID")
					local stem=casePath.."/Client"..math.abs(id)
					local slice=assert(decoded[stem.."ExactSlice"],"Exact native client slice missing")
					local raw=assert(decoded[stem.."Raw"],"Full native client observer missing")
					if lift then
						table.insert(summary.clients,clientCheck(server,slice,raw,actorIndex))
						assert(server.clientEvidence and identical(server.clientEvidence[actorIndex],slice),"Accepted server client evidence differs from preserved exact slice")
					else
						table.insert(summary.clients,hazardClientCheck(server,slice,raw,actorIndex))
					end
				end
				if not lift then summary.hazard=hazardServerCheck(server) end
				if server.case=="overhead" or server.case=="side" then
					serverOutcome(server,true)
					local blocker=server.after.diagnostics.lastBlocker
					assert(blocker and blocker.userId==server.actualClientUserIds[1] and blocker.part==server.blocker.path and blocker.recoveryAccepted,"Actual native blocker/affected user/recovery differs")
					assert(server.measuredRuntimeDeltas.carriedSteps>0 and server.measuredRuntimeDeltas.carryProbes>0 and server.measuredRuntimeDeltas.blockedCarries>=1
						and server.measuredRuntimeDeltas.recoveries==1,"Actual measured native obstruction/carry/recovery evidence missing")
					summary.blocker=blocker
				end
				if server.case=="adjacent" then
					local cycle
					for _,car in server.before.diagnostics.cars do if server.deck:find("/"..car.name.."/",1,true) or server.deck:find("."..car.name..".",1,true) then cycle=car.cycle end end
					assert(cycle and summary.measuredSeconds>=cycle and server.observedPhases.Rising and server.observedPhases.Descending
						and server.observedPhases.LowDwell and server.observedPhases.HighDwell,"Actual complete native car cycle not evidenced")
					summary.actualCycleSeconds=cycle;summary.originalPhasesAndDurationCheckPassed=true
					local phaseOffset=if server.deck:find("_Bay2.",1,true) or server.deck:find("_Bay2/",1,true) then declaredBay2Delay else 0
					summary.declaredPhaseOffsetSeconds=phaseOffset
					summary.recurringWindowAfterDeclaredPhaseOffset=summary.runtimeMeasurementElapsedStart and summary.runtimeMeasurementElapsedStart>=phaseOffset or false
					summary.fullCycleObserved=summary.recurringWindowAfterDeclaredPhaseOffset
					assert(summary.fullCycleObserved,"Initial native Bay2 startup hold was included; complete recurring-cycle window is unproven")
					assert(server.measuredRuntimeDeltas.carriedSteps>0 and server.measuredRuntimeDeltas.recoveries==0,"Actual carry/recovery window differs")
					for actorIndex in {1,2} do assert(server.after.players[actorIndex].checkpoint==server.before.players[actorIndex].checkpoint
						and server.after.players[actorIndex].falls==server.before.players[actorIndex].falls,"Adjacent official progress/falls changed") end
				end
			end)
			summary.independentRecordedEvidenceChecksPassed=checked
			if not checked then summary.failure=tostring(failure) end
		end
	end
end
for path,server in decoded do
	if path:match("/ServerFailureAtDetection$") then
		local failure={exportPath=path,caseId=server.caseId,case=server.case,state=server.state,passed=server.passed,failure=server.failure,
			deck=server.deck,serverSamples=server.samples and #server.samples,observedPhases=server.observedPhases,
			measurementStartedAt=server.measurementStartedAt,measurementEndedAt=server.measurementEndedAt,
			measurementElapsedStart=server.measurementBefore and server.measurementBefore.diagnostics.elapsed,
			measurementElapsedEnd=server.after and server.after.diagnostics.elapsed}
		if server.measurementBefore and server.after then
			failure.runtimeDeltas={}
			for _,key in {"carriedSteps","carryProbes","blockedCarries","recoveries","hazardHits"} do
				failure.runtimeDeltas[key]=server.after.diagnostics.stats[key]-server.measurementBefore.diagnostics.stats[key]
			end
		end
		table.insert(validation.failedCases,failure)
	end
end
gap("The export does not independently bind the executed live driver/ContactCases source hashes or fixture IDs; source agreement requires the lead's separate native source/install receipt")
gap("Controlled two-player observations cover only the exported selected cases; they do not prove all bays/stages, obstruction/hazard negatives, continuous traversal, twenty players, pacing or FPS")
validation.allCompletedCaseRechecksPassed=#validation.cases>0
for _,case in validation.cases do if not case.independentRecordedEvidenceChecksPassed then validation.allCompletedCaseRechecksPassed=false end end
if not validation.suite then gap("No ContactDriver SuiteRaw schema found; raw artifact integrity only is verified") end
local toolPath="tools/moonlit-citadel/phase2/ExtractNativeEvidence.luau"
local receipt={input=input,nativeExportBytes=#nativeBytes,nativeExportSha256=serde.hash("sha256",nativeBytes),output=output,
	toolSha256=serde.hash("sha256",fs.readFile(toolPath)),runtimeSha256=serde.hash("sha256",fs.readFile(".tools/lune-0.10.5/lune.exe")),
	nativeParentPath=parentPath,nativeParentPathSource="Explicit CLI parent supplied by lead; RBXM root parent is not stored",roots={},reports=records,hierarchy=hierarchy,
	chunkIntegrityPassed=true,exactRawJsonPreserved=true,validation=validation}
for _,root in roots do table.insert(receipt.roots,root.Name) end
plan("receipt.json",serde.encode("json",receipt,true))
plan("validation.json",serde.encode("json",validation,true))
local summary={"Native evidence extracted without JSON reformatting or truncation.","Export SHA-256: "..receipt.nativeExportSha256,
	"Export bytes: "..#nativeBytes.."; reports: "..#records,"Completed case rechecks passed: "..tostring(validation.allCompletedCaseRechecksPassed),""}
for _,case in validation.cases do table.insert(summary,case.name..": server verdict="..tostring(case.recordedPassed)..", offline recheck="..tostring(case.independentRecordedEvidenceChecksPassed)..", measurement seconds="..tostring(case.measuredSeconds));if case.failure then table.insert(summary,case.failure) end end
table.insert(summary,"");for _,text in validation.gaps do table.insert(summary,"Proof boundary: "..text) end
plan("SUMMARY.txt",table.concat(summary,"\n").."\n")
for path,bytes in planned do if fs.isFile(output.."/"..path) then assert(fs.readFile(output.."/"..path)==bytes,"Preserve differing pre-existing extraction: "..path) end end
local function directory(path)
	if fs.isDir(path) then return end
	local parent=path:match("^(.*)/[^/]+$");if parent then directory(parent) end
	fs.writeDir(path)
end
for path,bytes in planned do
	local full=output.."/"..path;directory(assert(full:match("^(.*)/[^/]+$")))
	if not fs.isFile(full) then fs.writeFile(full,bytes) end
	assert(fs.readFile(full)==bytes,"Written extracted bytes differ: "..path)
end
print(serde.encode("json",{input=input,nativeExportSha256=receipt.nativeExportSha256,output=output,reports=#records,
	chunkIntegrityPassed=true,completedCaseRechecksPassed=validation.allCompletedCaseRechecksPassed,cases=validation.cases},true))
