--!nonstrict
local Test={}
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local ServerStorage=game:GetService("ServerStorage")
local busy=false
local function position(value)return{value.X,value.Y,value.Z}end
local function reportChunks(encoded)
 local chunks={};local first=1
 while first<=#encoded do
  local last=math.min(first+63999,#encoded)
  while last<#encoded do
   local nextByte=string.byte(encoded,last+1)
   if nextByte<128 or nextByte>191 then break end
   last-=1
  end
  table.insert(chunks,string.sub(encoded,first,last));first=last+1
 end
 return chunks
end
local function persistReport(stored,encoded)
 stored:SetAttribute("Complete",false);stored:SetAttribute("ReportBytes",#encoded)
 if #encoded<190000 then
  stored.Value=encoded;stored:SetAttribute("Storage","Inline");stored:SetAttribute("ChunkCount",0)
 else
  local chunks=reportChunks(encoded)
  stored:SetAttribute("Storage","Chunked");stored:SetAttribute("ChunkCount",#chunks)
  for index,content in ipairs(chunks)do
   local chunk=Instance.new("StringValue");chunk.Name=string.format("Chunk%04d",index);chunk.Value=content;chunk.Parent=stored
  end
  stored.Value=Http:JSONEncode({storage="Chunked",encoding="UTF-8 JSON",bytes=#encoded,chunkCount=#chunks,
   chunkNameFormat="Chunk%04d",maximumChunkBytes=64000,reconstruct="Concatenate child Values in numeric chunk order"})
 end
 stored:SetAttribute("Complete",true)
end
local function waitFor(predicate,seconds,message)
 local deadline=os.clock()+seconds
 repeat RunService.Heartbeat:Wait()until predicate()or os.clock()>deadline
 assert(predicate(),message)
end
local function snapshot(services,player)
 local result=assert(services.ResultsService.GetPlayerResult(player),"Official result missing")
 return{raceId=services.RaceService.GetCurrentRaceId(),raceElapsed=services.RaceService.GetElapsedRaceTime(),currentLap=result.currentLap,requiredLaps=result.requiredLaps,
  nextCheckpointIndex=result.nextCheckpointIndex,latestCheckpoint=services.CheckpointService.GetLatestCheckpointIndex(player),
  lapTimes=table.clone(result.lapTimes or{}),checkpointSplits=#(result.checkpointSplits or{}),falls=result.falls or 0,
  status=result.status,playerStatus=services.PlayerRaceService.GetPlayerStatus(player),finishTime=result.finishTime}
end
local function walkTo(player,target,guard)
 local character=assert(player.Character);local root=character.HumanoidRootPart;local humanoid=character:FindFirstChildOfClass("Humanoid")
 local movement=Vector3.zero
 root.Anchored=false;root:SetNetworkOwner(nil)
 local connection=RunService.PreSimulation:Connect(function()humanoid:Move(movement,false);humanoid.Jump=false end)
 local began=os.clock()
 local ok,failure=xpcall(function()
  local reached=false
  repeat
   assert(player.Character==character and humanoid.Health>0 and guard(),"Walking case changed character, course or race")
   local delta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
   reached=delta.Magnitude<.35 and humanoid.FloorMaterial~=Enum.Material.Air
   movement=if reached then Vector3.zero else delta.Unit
   if not reached then RunService.Heartbeat:Wait()end
  until reached or os.clock()-began>4
  assert(reached,"Walking trigger path did not reach its endpoint")
 end,debug.traceback)
 connection:Disconnect();humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then root:SetNetworkOwnershipAuto()end
 assert(ok,failure)
 return{seconds=os.clock()-began,endPosition=position(root.Position),method="Ordinary server-owned walking; no progress API writes"}
end

-- Invoke from the existing serialized NativeChecks command runner after Prepare.
function Test.Run(services,options,progress)
 assert(RunService:IsStudio()and RunService:IsServer(),"Studio server race checks only")
 assert(not busy,"Egg Rush race checks already running")
 options=options or{}
 local mode,line=options.mode or"Lap",options.line or"Normal"
 local parent=ServerStorage:FindFirstChild("EggRushNativeRaceReceipts")
 if not parent then parent=Instance.new("Folder");parent.Name="EggRushNativeRaceReceipts";parent.Parent=ServerStorage end
 local receipt=Instance.new("Folder");receipt.Name=mode.."_"..line.."_"..Http:GenerateGUID(false);receipt.Parent=parent
 local stored=Instance.new("StringValue");stored.Name="Report";stored.Parent=receipt
 local report={ok=false,mode=mode,line=line,pace=options.pace==true,checks={},setups={},laps={},limits={
  "Scripted server-owned real-avatar evidence, not human control or crowded/device/FPS proof",
  "Lap timings include actual hazard waits; ThreeLaps with injected fall is not a clean race pacing run",
  "ResultsService first-lap time includes any prepared-race idle before this test; traversal.seconds measures the driven lap itself",
  "Window waiting uses the recorded scripted admission budgets and a full tray ride, not minimum achievable player waiting; pace mode is a practiced-control experiment",
  "ProgressCases uses explicitly listed setup teleports and temporary walking strips, not route traversal",
 }}
 receipt:SetAttribute("State","Running")
 busy=true
 local started=os.clock();local fixture
 local ok,failure=xpcall(function()
  assert(mode=="Lap"or mode=="ThreeLaps"or mode=="ProgressCases","Unknown race-check mode")
  assert(line=="Normal"or line=="Expert","Unknown intended route")
  local player=assert(game.Players:GetPlayers()[1],"No native test player")
  local course=assert(services.CourseService.GetActiveCourse(),"No active course")
  local raceId=services.RaceService.GetCurrentRaceId()
  assert(services.RaceService.IsRaceActive()and course:GetAttribute("CourseId")=="egg_rush_circuit"and course:GetAttribute("EROwned")==true,"Prepared active Egg Rush race required")
  assert(services.PlayerRaceService.IsOfficialRacer(player)and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Prepared official racer required")
  report.candidateId=course:GetAttribute("CandidateId");report.raceId=raceId;report.userId=player.UserId
  receipt:SetAttribute("CandidateId",report.candidateId);receipt:SetAttribute("RaceId",raceId)
  local maxSeconds=options.maxSeconds or(if mode=="ThreeLaps"then 600 else 240)
  local function guard()return services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId and os.clock()-started<maxSeconds end
  local character=assert(player.Character);local root=character.HumanoidRootPart;local humanoid=character:FindFirstChildOfClass("Humanoid")
  local initial=snapshot(services,player);report.initial=initial
  assert(initial.currentLap==1 and initial.nextCheckpointIndex==1 and initial.latestCheckpoint==0 and initial.checkpointSplits==0 and next(initial.lapTimes)==nil and initial.falls==0,"Restart Prepare for a fresh race; inspection progress cannot seed this check")
  assert(initial.requiredLaps==3,"Egg Rush must require three laps")
  local function check(name,value,details)
   table.insert(report.checks,{name=name,ok=value,details=details})
   assert(value,name)
  end
  local function setup(name,ground)
   assert(guard(),"Race changed before setup")
   local target=ground+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.15,0)
   character:PivotTo(CFrame.new(target));root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   table.insert(report.setups,{name=name,position=position(target),kind="Explicit setup teleport before this isolated case or measured run"})
   waitFor(function()return humanoid.FloorMaterial~=Enum.Material.Air end,2,"Setup did not settle")
  end
  local function gateGround(z)
   local point=course.Finish.CFrame:PointToWorldSpace(Vector3.new(0,0,z))
   return Vector3.new(point.X,course.Start.Position.Y+course.Start.Size.Y/2,point.Z)
  end
  setup("Initial launch-side placement",gateGround(3))
  local launchBefore=snapshot(services,player)
  local launchWalk=walkTo(player,course.Start.Position+Vector3.new(0,course.Start.Size.Y/2,0),guard)
  local launchAfter=snapshot(services,player)
  check("Launch crossing awards no lap",launchAfter.currentLap==1 and next(launchAfter.lapTimes)==nil and launchAfter.nextCheckpointIndex==1,{before=launchBefore,after=launchAfter,walk=launchWalk})

  if mode=="ProgressCases"then
   report.method="Isolated real trigger walking with setup teleports listed; no inspection-checkpoint or result mutation"
   local function crossCheckpoint(index)
    local pocket=course.Obstacles["CP"..index.."_Pocket"]
    fixture=Instance.new("Part");fixture.Name="__EggRushProgressWalkSetup";fixture.Anchored=true;fixture.CanCollide=true;fixture.CanTouch=false;fixture.Size=Vector3.new(8,1,6)
    fixture.CFrame=pocket.CFrame*CFrame.new(0,pocket.Size.Y/2-.5,8);fixture.Parent=workspace
    setup("CP"..index.." walking-strip setup",fixture.Position+Vector3.new(0,.5,0))
    local before=snapshot(services,player)
    local walk=walkTo(player,pocket.Position+Vector3.new(0,pocket.Size.Y/2,0),guard)
    RunService.Heartbeat:Wait()
    local after=snapshot(services,player)
    fixture:Destroy();fixture=nil
    return{before=before,after=after,walk=walk}
   end
   local late=crossCheckpoint(2)
   check("Later CP2 rejected before CP1",late.after.nextCheckpointIndex==1 and late.after.latestCheckpoint==0 and late.after.checkpointSplits==0,late)
   for index=1,4 do
    local result=crossCheckpoint(index)
    check("Actual ordered CP"..index.." touch accepted",result.after.nextCheckpointIndex==index+1 and result.after.latestCheckpoint==index,result)
   end
   setup("Completed-progress reverse-gate case",gateGround(-3))
   local before=snapshot(services,player)
   local walk=walkTo(player,gateGround(3),guard)
   local after=snapshot(services,player)
   check("Reverse gate rejected with all CPs complete",after.currentLap==before.currentLap and next(after.lapTimes)==nil and after.latestCheckpoint==4,{before=before,after=after,walk=walk})
   report.final=after
   report.requiresFreshPrepare=true
  else
   report.method="Continuous intended route; one initial setup placement; real CheckpointService and ResultsService; no inspection progress calls"
   local traversal=require(script.Parent.NativeTraversal)
   local laps=if mode=="ThreeLaps"then 3 else 1
   local verifyFall=mode=="ThreeLaps"and options.fallAfterCP4~=false
   local forcedFallDone=false;local expectedFalls=0
   for lap=1,laps do
    local before=snapshot(services,player)
    check("Lap "..lap.." starts with reset ordered progress",before.currentLap==lap and before.nextCheckpointIndex==1 and before.latestCheckpoint==0,before)
    local points=traversal.Points(course,line)
    local result=traversal.Run(course,player,points,{placeAtStart=false,pace=options.pace==true,guard=guard,afterLanding=function(pointIndex,point,record,control)
     local state=snapshot(services,player)
     assert(state.falls==expectedFalls,"Unplanned recovery during measured route")
     for cp=1,4 do
      if point.part==course.Obstacles["CP"..cp.."_Pocket"]then
       waitFor(function()return services.CheckpointService.GetLatestCheckpointIndex(player)==cp end,1,"Native checkpoint did not register")
       if cp==4 and lap==1 and verifyFall and not forcedFallDone then
        local fallBefore=snapshot(services,player);local began=os.clock();local immunity=character:GetAttribute("RecoveryUntil")or 0
        expectedFalls+=1;control.SetMovement(Vector3.zAxis)
        waitFor(function()
         assert(guard(),"Race changed during recovery check")
         return(character:GetAttribute("RecoveryUntil")or 0)>immunity and services.ResultsService.GetPlayerResult(player).falls==expectedFalls
        end,5,"Walking fall did not use normal recovery")
        control.SetMovement(Vector3.zero)
        waitFor(function()return control.Standing()==point.part and humanoid.FloorMaterial~=Enum.Material.Air end,3,"CP4 recovery did not land safely")
        waitFor(function()
         assert(control.Standing()==point.part,"Lost CP4 support while returning to its center")
         local target=point.part.Position-root.Position;local flat=Vector3.new(target.X,0,target.Z)
         control.SetMovement(if flat.Magnitude<.35 then Vector3.zero else flat.Unit)
         return flat.Magnitude<.35
        end,3,"Could not walk from recovery slot to CP4 center")
        control.SetMovement(Vector3.zero)
        local fallAfter=snapshot(services,player)
        check("Fall after CP4 preserves current lap and all progress",fallAfter.currentLap==fallBefore.currentLap and fallAfter.nextCheckpointIndex==5 and fallAfter.latestCheckpoint==4 and fallAfter.falls==fallBefore.falls+1,{before=fallBefore,after=fallAfter,seconds=os.clock()-began,method="Walked off CP4; normal server recovery only"})
        report.forcedRecoverySeconds=os.clock()-began;forcedFallDone=true
       end
      end
     end
     receipt:SetAttribute("Landing",pointIndex)
    end},function(i,total,step)
     if progress then progress(i,total,"Lap "..lap.." "..line..": "..step)end
    end)
    report.laps[lap]=result
    local lapStored=Instance.new("StringValue");lapStored.Name="Lap"..lap;lapStored.Value=Http:JSONEncode(result);lapStored.Parent=receipt
    assert(result.ok,result.failure)
    check("Lap "..lap.." crosses both egg bands",result.eggCrossings.EggBand1 and result.eggCrossings.EggBand1.crossed and result.eggCrossings.EggBand2 and result.eggCrossings.EggBand2.crossed)
    check("Lap "..lap.." includes full supported tray ride",#result.trayCarries==1 and result.trayCarries[1].supportedThroughout,result.trayCarries)
    local after=snapshot(services,player)
    check("Forward return "..lap.." records exactly one lap",typeof(after.lapTimes[lap])=="number"and after.lapTimes[lap]>0 and after.lapTimes[lap+1]==nil,after)
    if lap<3 then check("Forward return resets checkpoint order",after.currentLap==lap+1 and after.nextCheckpointIndex==1 and after.latestCheckpoint==0,after)end
    report.final=after
   end
   if mode=="ThreeLaps"then
    check("Third forward gate finishes actual race result",report.final.status=="Finished"and report.final.currentLap==3 and typeof(report.final.finishTime)=="number"and report.final.checkpointSplits==12,report.final)
    check("Only the initial test setup placement was used",#report.setups==1)
    if verifyFall then check("Required CP4 recovery check executed",forcedFallDone)end
   end
   report.fallAfterCP4Verified=forcedFallDone
  end
  report.ok=true
 end,debug.traceback)
 busy=false
 if fixture then pcall(function()fixture:Destroy()end)end
 if not ok then report.ok=false;report.failure=failure end
 report.seconds=os.clock()-started;report.receiptPath=receipt:GetFullName();report.requiresFreshPrepare=true
 local finalOk,finalFailure=pcall(function()
  local laps={}
  for index,lap in ipairs(report.laps)do laps[index]={ok=lap.ok,seconds=lap.seconds,jumps=lap.jumps,windowWaitSeconds=lap.windowWaitSeconds}end
  local final=Instance.new("StringValue");final.Name="Final";final.Parent=receipt
  final.Value=Http:JSONEncode({ok=report.ok,mode=report.mode,line=report.line,pace=report.pace,candidateId=report.candidateId,raceId=report.raceId,
   final=report.final,laps=laps,seconds=report.seconds,fallAfterCP4Verified=report.fallAfterCP4Verified,
   failure=report.failure and string.sub(tostring(report.failure),1,4000)})
 end)
 if not finalOk then report.receiptErrors={"Final snapshot: "..tostring(finalFailure)}end
 local persistOk,persistFailure=pcall(function()persistReport(stored,Http:JSONEncode(report))end)
 if not persistOk then
  report.receiptErrors=report.receiptErrors or{}
  table.insert(report.receiptErrors,"Full report: "..tostring(persistFailure))
 end
 local stateOk,stateFailure=pcall(function()
  receipt:SetAttribute("PersistenceState",if finalOk and persistOk then"Complete"else"Failed")
  receipt:SetAttribute("State",if report.ok then"Complete"else"Failed")
 end)
 if not stateOk then
  report.receiptErrors=report.receiptErrors or{}
  table.insert(report.receiptErrors,"Receipt state: "..tostring(stateFailure))
 end
 return report
end
return Test
