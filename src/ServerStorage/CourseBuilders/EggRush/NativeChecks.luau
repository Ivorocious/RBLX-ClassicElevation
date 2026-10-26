--!nonstrict
local Test={}
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local function waitFor(predicate,seconds,message)
 local untilTime=os.clock()+seconds
 repeat RunService.Heartbeat:Wait()until predicate()or os.clock()>untilTime
 assert(predicate(),message)
end
function Test.Start()
 assert(RunService:IsStudio()and RunService:IsServer(),"Studio server checks only")
 assert(not game.ServerStorage:FindFirstChild("EggRushNativeResults"),"An Egg Rush runner is already present")
 local results=Instance.new("Folder");results.Name="EggRushNativeResults";results.Parent=game.ServerStorage
 local services={}
 for _,name in ipairs({"CourseService","RaceService","PlayerRaceService","CheckpointService","RespawnService","OnboardingService","EggRushService","ResultsService"})do
  services[name]=require(game.ServerScriptService.Services[name])
 end
 local busy=false
 local function prepare()
  local player=assert(game.Players:GetPlayers()[1],"No test player")
  for _,racer in ipairs(game.Players:GetPlayers())do
   if racer:GetAttribute("OnboardingReady")~=true then
    local ok,message=services.OnboardingService.SetStudioPreset(racer,"Returning racer");assert(ok,message)
    waitFor(function()return racer:GetAttribute("OnboardingReady")==true end,25,"Returning racer did not arrive")
   end
  end
  assert(services.CourseService.SelectCourseForStudio("egg_rush_circuit"),"Egg Rush is unavailable")
  services.RaceService.SetInspectionUnlimitedTime(true)
  local previousRaceId=services.RaceService.GetCurrentRaceId()
  assert(services.RaceService.ApplyStudioAction("RestartRace"),"Could not start scoped Studio race")
  waitFor(function()return services.RaceService.IsRaceActive()and services.RaceService.GetCurrentRaceId()~=previousRaceId and services.CourseService.GetActiveCourseId()=="egg_rush_circuit"end,35,"Fresh race did not become active")
  waitFor(function()return services.EggRushService.GetDiagnostics().bound==true end,3,"Egg Rush runtime did not bind")
  local character=assert(player.Character,"Missing character");local humanoid=character:FindFirstChildOfClass("Humanoid")
  return{course=services.CourseService.GetActiveCourseId(),raceId=services.RaceService.GetCurrentRaceId(),status=services.PlayerRaceService.GetPlayerStatus(player),official=services.PlayerRaceService.IsOfficialRacer(player),walk=humanoid.WalkSpeed,jump=humanoid.JumpHeight,usePower=humanoid.UseJumpPower,gravity=workspace.Gravity,runtime=services.EggRushService.GetDiagnostics()}
 end
 results:GetAttributeChangedSignal("Command"):Connect(function()
  if busy then return end
  local command=Http:JSONDecode(results:GetAttribute("Command"));busy=true
  results:SetAttribute("State","Running");results:SetAttribute("Job",command.job or command.action)
  task.spawn(function()
   local ok,value=xpcall(function()
    if command.action=="Prepare"then return prepare()
    elseif command.action=="Contacts"then
     return require(game.ServerStorage.CourseBuilders.EggRush.NativeContacts).Run(services,command)
    elseif command.action=="Race"then
     prepare()
     return require(game.ServerStorage.CourseBuilders.EggRush.NativeRaceChecks).Run(services,command,function(i,total,step)
      results:SetAttribute("Progress",Http:JSONEncode({index=i,total=total,step=step}))
     end)
    elseif command.action=="Follower"then
     prepare()
     return require(game.ServerStorage.CourseBuilders.EggRush.NativeFollowerChecks).Run(services,command)
    elseif command.action=="NoJump"then
     prepare()
     return require(game.ServerStorage.CourseBuilders.EggRush.NativeNoJumpChecks).Run(services,command)
    elseif command.action=="Traverse"then
     local player=assert(game.Players:GetPlayers()[1]);local course=assert(services.CourseService.GetActiveCourse())
     assert(services.RaceService.IsRaceActive()and course:GetAttribute("CourseId")=="egg_rush_circuit")
     if command.section=="Shellworks"then services.CheckpointService.SetInspectionCheckpointForStudio(player,2)end
     if command.section=="Incubator"or command.section=="IncubatorAlternate"then services.CheckpointService.SetInspectionCheckpointForStudio(player,2)end
     if command.section=="Rookery"then services.CheckpointService.SetInspectionCheckpointForStudio(player,3)end
     local traversal=require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
     local points=traversal.Points(course,command.line or"Normal",command.section)
     return traversal.Run(course,player,points,{placeAtStart=true},function(i,total,step)
      results:SetAttribute("Progress",Http:JSONEncode({index=i,total=total,step=step}))
     end)
    elseif command.action=="State"then
     local player=game.Players:GetPlayers()[1]
     return{course=services.CourseService.GetActiveCourseId(),maps=services.CourseService.GetDiscoveredCourseIds(),raceState=services.RaceService.GetRaceState(),ready=player and player:GetAttribute("OnboardingReady"),runtime=services.EggRushService.GetDiagnostics()}
    else error("Unknown check action")end
   end,debug.traceback)
   local passed=ok and(typeof(value)~="table"or value.ok~=false)
   local encoded=Http:JSONEncode({ok=passed,value=value})
   if #encoded>=190000 and typeof(value)=="table"and value.receiptPath then
    encoded=Http:JSONEncode({ok=passed,value={ok=value.ok,failure=value.failure,candidateId=value.candidateId,
     mode=value.mode,line=value.line,pace=value.pace,seconds=value.seconds,final=value.final,
     receiptPath=value.receiptPath,receiptErrors=value.receiptErrors,lapCount=value.laps and #value.laps,
     fullResultInReceipt=true}})
   end
   results:SetAttribute("Result",encoded);results:SetAttribute("State",if passed then"Complete"else"Failed");busy=false
  end)
 end)
 results:SetAttribute("State","Ready")
 return results
end
return Test
