--!nonstrict
local Test = {}
local RunService, Players, Workspace = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace")
function Test.Run(expectedCandidate, laps)
 assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server required")
 laps = laps or 1
 assert(laps == 1 or laps == 3, "One focused lap or the complete three-lap race")
 local services = {}
 for _, name in {"CourseService", "RaceService", "PlayerRaceService", "ResultsService", "CheckpointService", "EggRushService"} do services[name] = require(game.ServerScriptService.Services[name]) end
 local player = assert(Players:GetPlayers()[1]); assert(#Players:GetPlayers() == 1, "One isolated actual client required")
 local course, character = assert(services.CourseService.GetActiveCourse()), assert(player.Character)
 local root, humanoid = assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
 local collider = assert(character:FindFirstChild("CollisionPart")); local colliderSize = collider.Size
 local raceId, began = services.RaceService.GetCurrentRaceId(), os.clock()
 local function result()
  local value = assert(services.ResultsService.GetPlayerResult(player))
  return {lap=value.currentLap, nextCheckpoint=value.nextCheckpointIndex, falls=value.falls or 0, lapTimes=table.clone(value.lapTimes or {}), splits=#(value.checkpointSplits or {}), finishTime=value.finishTime, status=services.PlayerRaceService.GetPlayerStatus(player)}
 end
 local initial = result()
 local report = {candidate=expectedCandidate, lapsRequested=laps, placements=0, progressWrites=0, clockWrites=0, profileWrites=0, checkpoints={}, laps={}, method="Current canonical Normal route, continuous ordinary walking/jumps from the real delivered Start; all contacts remain active", limits="Scripted real avatar; no human, Expert, crowd, FPS or owner acceptance claim"}
 local recoveryUntil = character:GetAttribute("RecoveryUntil") or 0
 local ray = RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances={course}; ray.RespectCanCollide=true
 local function standing()
  local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
  return hit and hit.Instance
 end
 local function finished()
  local value=result()
  return laps==3 and value.status=="Finished" and #value.lapTimes==3 and value.splits==12
 end
 local function guard()
  assert(os.clock()-began<500 and player.Character==character and humanoid.Health>0, "Bounded original character changed")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId, "Actual course/race changed")
  assert(not services.CourseService.IsInspectionMode() and not services.RaceService.IsInspectionUnlimitedTime(), "No inspection override or immunity")
  assert(result().falls==initial.falls and (character:GetAttribute("RecoveryUntil")or 0)<=recoveryUntil+.01, "Actual recovery; stop the continuous attempt")
  if finished() then return true end
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player) and result().status=="Racing", "Actual eligible Racing participant required")
  assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01, "Ordinary accepted movement required")
  assert(collider.CanCollide and (collider.Size-colliderSize).Magnitude<.02 and services.EggRushService.GetDiagnostics().bound, "Current body/runtime must remain bound")
  return true
 end
 local function waitFor(predicate, seconds, message)
  local deadline=os.clock()+seconds
  repeat guard(); if predicate() then return end; RunService.Heartbeat:Wait() until os.clock()>deadline
  error(message)
 end
 local owner, ownerAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
 local ok, failure = xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit" and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("FullBodyContacts")==true, "Expected accepted gameplay candidate")
  assert(initial.lap==1 and initial.nextCheckpoint==1 and initial.splits==0 and #initial.lapTimes==0, "Fresh actual lap1 required; runner does not reset progress")
  guard(); assert(standing()==course.Start and humanoid.FloorMaterial~=Enum.Material.Air,"Must already stand on actual delivered Start")
  local traversal=require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
  local base=traversal.Points(course,"Normal")
  local points, pointLap, ends={table.clone(base[1])},{1},{}
  for lap=1,laps do
   for index=2,#base do table.insert(points,table.clone(base[index])); table.insert(pointLap,lap) end
   ends[#points]=lap
  end
  report.driver=traversal.Run(course,player,points,{placeAtStart=false,guard=guard,afterLanding=function(index,point)
   local lap=pointLap[index]
   local checkpoint=tonumber(point.part.Name:match("^CP([1-4])_Pocket$"))
   if checkpoint then
    waitFor(function()local value=result(); return value.lap==lap and value.nextCheckpoint==checkpoint+1 and value.splits==(lap-1)*4+checkpoint end,.8,"Missing actual ordered checkpoint")
    table.insert(report.checkpoints,{lap=lap,checkpoint=checkpoint,result=result()})
   end
   if ends[index] then
    waitFor(function() local value=result(); return if lap<3 then value.lap==lap+1 and value.nextCheckpoint==1 and #value.lapTimes==lap else finished() end,.8,"Original forward Start return did not award the actual lap")
    assert(standing()==course.Start,"Lap join must be physically supported on Start")
    table.insert(report.laps,{lap=lap,result=result()})
   end
  end},function(index,total,step) script:SetAttribute("Progress",string.format("%d/%d %s",index,total-1,step)) end)
  assert(report.driver.ok,report.driver.failure)
  assert(#report.driver.trayCarries==laps*2,"Both actual full tray rides required each lap")
  for _,carry in report.driver.trayCarries do assert(carry.supportedThroughout and carry.travelSamples>0,"Missing supported outward carry") end
  report.encounters={}
  for _,receipt in report.driver.windowTrace do
   report.encounters[receipt.model]=(report.encounters[receipt.model]or 0)+1
   if receipt.model:match("^EggBand") then assert(receipt.crossed,"Actor band exit missing") end
  end
  for _,name in {"EggBand1","EggBand1_2","EggBand1_3","EggBand2","EggBand2_2","EggBand2_3","SidewaysTray","SidewaysTrayB","ShellLip1","ShellLip2","ShellLip3","ShellLip4"} do assert(report.encounters[name]==laps,"Missing encounter "..name) end
  assert(report.encounters.GuardianPeck==laps*2,"Normal must pass both current peck targets")
  assert(#report.checkpoints==laps*4 and #report.laps==laps,"Ordered actual progression incomplete")
  report.complete=true
 end,debug.traceback)
 humanoid:Move(Vector3.zero,false); humanoid.Jump=false
 if root.Parent then if ownerAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(owner) end end
 report.ok,report.failure,report.seconds,report.final=ok,if ok then nil else tostring(failure),os.clock()-began,result()
 report.cleanup="Movement stopped; original network ownership restored; no return placement"
 script:SetAttribute("State",if ok then "Complete" else "Failed")
 return report
end
return Test
