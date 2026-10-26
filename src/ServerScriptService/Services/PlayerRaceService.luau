--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Config.RaceConfig)
local Service = {}
local services: any
local started = false
local state, raceId = "WaitingForPlayers", ""
local enrolled: {[Player]: boolean} = {}
local statuses: {[Player]: string} = {}
local official: {[Player]: boolean} = {}
local admitted: {[Player]: Model} = {}
local cameraReady: {[Player]: any} = {}
local messages: {[Player]: string} = {}
local tickets: {[Player]: any} = {}
local activity: {[Player]: any} = {}
local watchFocus: {[Player]: any} = {}
local connections: {[Player]: {RBXScriptConnection}} = {}
local lastRequest: {[Player]: number} = {}
local entryOpen = false
local revision = 0
local changed: RemoteEvent
local statusChanged: RemoteEvent

local function now(): number return workspace:GetServerTimeNow() end
local function alive(player: Player): boolean
 local character = player.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 local root = character and character:FindFirstChild("HumanoidRootPart")
 return humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart")
end
local function onboardingReady(player: Player): boolean
 return player.Parent == Players and player:GetAttribute("OnboardingReady") == true
end
local function preparation(): any
 if services.TournamentService then
  local prep = services.TournamentService.GetPreparation()
  if prep then return prep end
 end
 return services.RaceService and services.RaceService.GetPreparation() or nil
end
local function courseInfo(): any
 return services.RaceService and services.RaceService.GetCourseInfo() or {}
end
local function targets(): {any}
 local rows = {}
 if state ~= "Racing" then return rows end
 for _,player in Players:GetPlayers() do
  if statuses[player] == "Racing" and official[player] and alive(player) then
   table.insert(rows,{userId=player.UserId,name=player.Name,displayName=player.DisplayName})
  end
 end
 table.sort(rows,function(a,b) return a.userId < b.userId end)
 return rows
end
local function actionLabel(player: Player): string
 if enrolled[player] then return "You're in" end
 if state == "WaitingForPlayers" then return "Start racing" end
 if entryOpen then return "Join this race" end
 return "Join next race"
end
function Service.GetFlowSnapshot(player: Player): any
 local info, prep = courseInfo(), preparation()
 return {revision=revision,serverTime=now(),raceId=raceId,state=state,status=statuses[player] or "Lobby",
  enrolled=enrolled[player] == true,entryOpen=entryOpen,actionLabel=actionLabel(player),message=messages[player],
  courseId=info.courseId,courseDisplayName=(prep and prep.courseDisplayName) or info.displayName or info.courseDisplayName,preparation=prep,
  finishTicket=tickets[player],watchTargets=targets(),inactivityWarning=activity[player] and activity[player].warningAt,
  departureAt=prep and prep.previewAt or nil,
  visit=services.VisitProgressService and services.VisitProgressService.GetSnapshot(player,if info.courseId=="unavailable" then nil else info) or nil,
  practice=services.PracticeService and services.PracticeService.GetSnapshot(player) or nil}
end
function Service.PublishFlow(player: Player?)
 if not changed then return end
 revision += 1
 if player then
  if player.Parent == Players then changed:FireClient(player,Service.GetFlowSnapshot(player)) end
 else
  for _,recipient in Players:GetPlayers() do changed:FireClient(recipient,Service.GetFlowSnapshot(recipient)) end
 end
end
function Service.IsEnrolled(player: Player): boolean return enrolled[player] == true end
function Service.GetPlayerStatus(player: Player): string? return statuses[player] end
function Service.IsOfficialRacer(player: Player): boolean return official[player] == true and onboardingReady(player) end
function Service.GetEnrolledPlayers(): {Player}
 local rows = {}
 for _,player in Players:GetPlayers() do
  if enrolled[player] and onboardingReady(player) then table.insert(rows,player) end
 end
 return rows
end
function Service.GetEligiblePlayerCount(): number return #Service.GetEnrolledPlayers() end
function Service.GetRacingPlayers(): {Player}
 local rows = {}
 for _,player in Players:GetPlayers() do
  if statuses[player] == "Racing" and official[player] then table.insert(rows,player) end
 end
 return rows
end
function Service.GetQueuedPlayers(): {Player}
 local rows = {}
 for _,player in Players:GetPlayers() do
  if statuses[player] == "Queued" and enrolled[player] and onboardingReady(player) and alive(player) then
   table.insert(rows,player)
  end
 end
 return rows
end
function Service.TouchActivity(player: Player)
 local record = activity[player] or {}
 record.lastActive,record.warningAt = now(),nil
 messages[player] = nil
 activity[player] = record
end
local function clearWatchFocus(player: Player)
 local focus = watchFocus[player]
 if focus then pcall(function() player:RemoveReplicationFocus(focus.part) end) end
 watchFocus[player] = nil
end
function Service.SetPlayerStatus(player: Player,status: string,reason: string?)
 local previous = statuses[player]
 statuses[player] = status
 if status ~= "Spectating" then clearWatchFocus(player) end
 if status ~= "Racing" and activity[player] then activity[player].warningAt = nil end
 if status == "Lobby" then
  official[player],admitted[player] = false,nil
  player:SetAttribute("TournamentCourseReady",true)
 end
 if services.GhostService then services.GhostService.SetPlayerGhostMode(player,status == "Finished") end
 if previous ~= status and statusChanged then
  statusChanged:FireAllClients({raceId=raceId,userId=player.UserId,name=player.Name,displayName=player.DisplayName,
   previousStatus=previous,status=status,reason=reason,serverTime=now()})
 end
 if status == "Racing" then Service.TouchActivity(player) end
 Service.PublishFlow(player)
 if status == "Finished" then
  local finishedRace = raceId
  task.delay(Config.FinishReturnSeconds,function()
   if raceId == finishedRace and statuses[player] == "Finished" then Service.ReturnToLobby(player,"Finished — ready for your next choice") end
  end)
 end
end
local function withdraw(player: Player,reason: string)
 if statuses[player] ~= "Racing" or not official[player] then return end
 if services.ResultsService then services.ResultsService.WithdrawPlayer(player,reason) end
 Service.SetPlayerStatus(player,"DNF",reason)
end
function Service.ReturnToLobby(player: Player,reason: string?): boolean
 if not onboardingReady(player) then return false end
 withdraw(player,reason or "Returned to lobby before finishing")
 if services.PracticeService then services.PracticeService.StopAttempt(player,reason or "Returned to lobby") end
 Service.SetPlayerStatus(player,"Lobby",reason)
 if services.StagingService then services.StagingService.ReturnPlayersToLobby({player},reason) end
 return true
end
function Service.OnRaceResolved(player: Player,result: any,race: any)
 if services.VisitProgressService then
  services.VisitProgressService.ResolveRace(player,result,race)
  tickets[player] = services.VisitProgressService.GetFinishTicket(player,result,race)
 else
  tickets[player] = {raceId=race.raceId,courseId=race.courseId,status=result.status,
   placement=result.placement,finishTime=result.finishTime,message=if result.status == "Finished" then "Course completed" else result.dnfReason}
 end
 Service.PublishFlow(player)
end
function Service.FailPreparation(player: Player,reason: string)
 enrolled[player]=false
 player:SetAttribute("RaceEnrolled",false)
 messages[player]=reason.." Start racing to retry. Practice portal stays open."
 Service.ReturnToLobby(player,reason)
 Service.PublishFlow(player)
end
function Service.PreparePlayersForCourse()
 if not entryOpen then return end
 for _,player in Service.GetEnrolledPlayers() do
  if alive(player) and statuses[player] ~= "Racing" then
   if services.PracticeService then services.PracticeService.InterruptForRace(player) end
   if statuses[player] ~= "Queued" then
    cameraReady[player] = nil
    Service.SetPlayerStatus(player,"Queued","Preparing your next race")
   end
  end
 end
end
function Service.QueueEligiblePlayers() Service.PreparePlayersForCourse() end
function Service.OpenAdmission()
 entryOpen = true
 table.clear(admitted)
 table.clear(cameraReady)
 Service.PublishFlow()
end
function Service.CloseAdmission(token: string,studioBypass: boolean?): {Player}
 entryOpen = false
 table.clear(admitted)
 local missed = {}
 for _,player in Players:GetPlayers() do
  if statuses[player] ~= "Queued" then continue end
  local camera = cameraReady[player]
  local delivered = services.StagingService and services.StagingService.IsPlayerDelivered(player)
  local ready = player:GetAttribute("TournamentCourseReady") == true and camera and camera.token == token and camera.character == player.Character
  if enrolled[player] and onboardingReady(player) and alive(player) and delivered and (ready or (studioBypass == true and RunService:IsStudio())) then
   admitted[player] = player.Character
  else
   messages[player] = "Loading finished too late. You're enrolled for the next race."
   Service.SetPlayerStatus(player,"Lobby",messages[player])
   table.insert(missed,player)
  end
 end
 if #missed > 0 and services.StagingService then services.StagingService.ReturnPlayersToLobby(missed,"Next race delivery") end
 Service.PublishFlow()
 local rows = {}
 for player in admitted do table.insert(rows,player) end
 return rows
end
function Service.ReadyToAdmitCount(token: string): number
 local count = 0
 for _,player in Service.GetQueuedPlayers() do
  local camera = cameraReady[player]
  if camera and camera.token == token and camera.character == player.Character
   and player:GetAttribute("TournamentCourseReady") == true and services.StagingService.IsPlayerDelivered(player) then count += 1 end
 end
 return count
end
function Service.StartQueuedPlayers(): {Player}
 local rows = {}
 for player,character in admitted do
  if player.Parent == Players and player.Character == character and alive(player) and enrolled[player] and onboardingReady(player) then
   official[player] = true
   Service.SetPlayerStatus(player,"Racing","Race started")
   table.insert(rows,player)
  else
   official[player] = false
   if player.Parent == Players then
    messages[player] = "Your character changed during countdown. You're in the next race."
    Service.SetPlayerStatus(player,"Lobby",messages[player])
    services.StagingService.ReturnPlayersToLobby({player},"Countdown recovery")
   end
  end
 end
 table.clear(admitted)
 return rows
end
function Service.MarkUnfinishedRacersDNF(reason: string): {any}
 local records = {}
 for _,player in Service.GetRacingPlayers() do
  table.insert(records,{userId=player.UserId,name=player.Name,displayName=player.DisplayName,
   status="DNF",official=true,falls=0,checkpointSplits={},dnfReason=reason})
  Service.SetPlayerStatus(player,"DNF",reason)
 end
 return records
end
function Service.ResetPlayersForNextRound(reason: string?)
 entryOpen = false
 table.clear(admitted);table.clear(cameraReady)
 for _,player in Players:GetPlayers() do
  official[player] = false
  if statuses[player] ~= "Lobby" then Service.SetPlayerStatus(player,"Lobby",reason or "Round reset") end
 end
end
function Service.CanSpectate(player: Player): boolean
 return onboardingReady(player) and state == "Racing" and statuses[player] ~= "Racing" and #targets() > 0
end
function Service.SetWatchTarget(player: Player,userId: any): boolean
 if statuses[player] ~= "Spectating" or not Service.CanSpectate(player)
  or typeof(userId) ~= "number" or userId % 1 ~= 0 then return false end
 local target = Players:GetPlayerByUserId(userId)
 if not target or target == player or statuses[target] ~= "Racing" or not official[target] or not alive(target) then return false end
 local root = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart
 local previous = watchFocus[player]
 if previous and previous.part == root then return true end
 clearWatchFocus(player)
 local ok = pcall(function() player:AddReplicationFocus(root) end)
 if not ok then return false end
 watchFocus[player] = {userId=userId,part=root}
 return true
end
function Service.RequestSpectate(player: Player): boolean
 if not Service.CanSpectate(player) then return false end
 Service.ReturnToLobby(player,"Watching racers")
 Service.SetPlayerStatus(player,"Spectating","Watching racers")
 local list = targets()
 if list[1] then Service.SetWatchTarget(player,list[1].userId) end
 return true
end
function Service.CanRaceLate(_player: Player): boolean return false end
function Service.CanGhostRace(_player: Player): boolean return false end
function Service.RequestRaceLate(player: Player): boolean
 messages[player] = "Full-course practice isn't available. Try the practice portal."
 Service.PublishFlow(player);return false
end
function Service.RequestGhostRace(player: Player): boolean return Service.RequestRaceLate(player) end
function Service.OnRaceStateChanged(nextState: string,nextRaceId: string?)
 state,raceId = nextState,nextRaceId or raceId
 if state == "Countdown" or state == "Racing" or state == "Results" then entryOpen = false end
 Service.PublishFlow()
end
function Service.ForceEnrollReadyPlayersForStudio()
 if not RunService:IsStudio() then return end
 for _,player in Players:GetPlayers() do
  if onboardingReady(player) then enrolled[player] = true;player:SetAttribute("RaceEnrolled",true) end
 end
end
function Service.RequestAction(player: Player,payload: any): any
 if player.Parent ~= Players or typeof(payload) ~= "table" or typeof(payload.action) ~= "string" then
  return {ok=false,message="Invalid race action."}
 end
 if not onboardingReady(player) then return {ok=false,message="Finish arriving before choosing a race."} end
 local action = payload.action
 if action == "CameraReady" then
  local prep = preparation()
  if not entryOpen or not prep or prep.status == "Failed" or payload.token ~= prep.token or statuses[player] ~= "Queued"
   or player:GetAttribute("TournamentCourseReady") ~= true or not alive(player) or not services.StagingService.IsPlayerDelivered(player) then
   return {ok=false,message="This delivery is no longer open."}
  end
  cameraReady[player] = {token=prep.token,character=player.Character}
 elseif action == "Join" then
  enrolled[player] = true
  player:SetAttribute("RaceEnrolled",true)
  messages[player] = if entryOpen then "You're in. Preparing your course." elseif state == "WaitingForPlayers" then "You're in. Choose an opening course." else "You're in the next race."
  if entryOpen then
   local prep = preparation()
   if prep and prep.status ~= "Failed" and now() >= (prep.previewAt or math.huge) then
    Service.PreparePlayersForCourse()
    services.StagingService.MovePlayersToRaceStart(Service.GetQueuedPlayers(),"Joined before entry closed")
   end
  end
 elseif action == "Break" then
  enrolled[player] = false
  player:SetAttribute("RaceEnrolled",false)
  player:SetAttribute("TournamentCourseReady",true)
  withdraw(player,"Took a break")
  if statuses[player] ~= "Lobby" then Service.ReturnToLobby(player,"Taking a break") end
  messages[player] = "Taking a break. Practice stays open."
 elseif action == "Lobby" or action == "StopWatching" then
  Service.ReturnToLobby(player,if action == "StopWatching" then "Stopped watching" else "Returned to lobby")
 elseif action == "Watch" then
  if not Service.RequestSpectate(player) then return {ok=false,message="No active racers to watch."} end
 elseif action == "WatchTarget" then
  if not Service.SetWatchTarget(player,payload.targetUserId) then return {ok=false,message="That racer is unavailable."} end
 elseif action == "KeepRacing" then
  if statuses[player] ~= "Racing" then return {ok=false,message="You're not in an active race."} end
  Service.TouchActivity(player)
 else return {ok=false,message="Unknown race action."} end
 Service.PublishFlow(player)
 return {ok=true,snapshot=Service.GetFlowSnapshot(player)}
end
local function sampleActivity()
 local time = now()
 for _,player in Service.GetRacingPlayers() do
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local record = activity[player] or {lastActive=time}
  activity[player] = record
  if not onboardingReady(player) or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
   record.lastActive,record.warningAt = time,nil
  else
   local moved = record.position == nil or (root.Position-record.position).Magnitude > .5
   if moved or humanoid.MoveDirection.Magnitude > .05 or root.AssemblyLinearVelocity.Magnitude > 1 then
    record.lastActive,record.warningAt = time,nil
   end
   record.position = root.Position
   local idle = time-record.lastActive
   if idle >= Config.InactivityBreakSeconds then
    enrolled[player] = false
    player:SetAttribute("RaceEnrolled",false)
    Service.ReturnToLobby(player,"Extended inactivity after warning")
    messages[player] = "You were put on break after inactivity. Start racing whenever you're ready."
   elseif idle >= Config.InactivityWarningSeconds and record.warningAt == nil then
    record.warningAt = time
    messages[player] = "Still there? Move or choose Keep racing to stay in this race."
   end
  end
 end
end
local function addPlayer(player: Player)
 enrolled[player],official[player] = false,false
 statuses[player] = "Lobby"
 player:SetAttribute("RaceEnrolled",false)
 player:SetAttribute("TournamentCourseReady",true)
 connections[player] = {
  player.CharacterRemoving:Connect(function() clearWatchFocus(player) end),
  player.CharacterAdded:Connect(function(character)
   cameraReady[player],admitted[player] = nil,nil
   player:SetAttribute("TournamentCourseReady",statuses[player]=="Lobby")
   Service.TouchActivity(player)
   if not entryOpen and statuses[player] == "Queued" then
    messages[player] = "Your character changed after entry closed. You're enrolled for the next race."
    Service.SetPlayerStatus(player,"Lobby",messages[player])
    task.spawn(function()
     local root=character:WaitForChild("HumanoidRootPart",10)
     if root and player.Character == character and statuses[player] == "Lobby" and onboardingReady(player) then
      services.StagingService.ReturnPlayersToLobby({player},"Countdown reset recovery")
     end
    end)
   end
   Service.PublishFlow(player)
  end),
  player:GetAttributeChangedSignal("OnboardingReady"):Connect(function() Service.PublishFlow(player) end),
 }
 Service.PublishFlow(player)
end
function Service.Init(context: any) services = context.Services end
function Service.Start()
 if started then return end
 started = true
 local folder = ReplicatedStorage:WaitForChild("Remotes")
 changed = folder:WaitForChild("RaceFlowChanged") :: RemoteEvent
 statusChanged = folder:WaitForChild("PlayerRaceStatusChanged") :: RemoteEvent
 local actionRemote = folder:WaitForChild("RaceAction") :: RemoteFunction
 local stateRemote = folder:WaitForChild("GetRaceFlowState") :: RemoteFunction
 actionRemote.OnServerInvoke = function(player,payload)
  local time = now()
  if time-(lastRequest[player] or -math.huge) < .15 then return {ok=false,message="Try again in a moment."} end
  lastRequest[player] = time
  return Service.RequestAction(player,payload)
 end
 local reads: {[Player]: number} = {}
 stateRemote.OnServerInvoke = function(player)
  if player.Parent ~= Players or now()-(reads[player] or -math.huge) < .25 then return nil end
  reads[player] = now();return Service.GetFlowSnapshot(player)
 end
 local standaloneAcknowledgements: {[Player]: any} = {}
 folder:WaitForChild("TournamentStageReady").OnServerEvent:Connect(function(player,payload)
  local prep = services.RaceService and services.RaceService.GetPreparation()
  if not prep or not entryOpen or typeof(payload) ~= "table" or payload.token ~= prep.token
   or not enrolled[player] or not onboardingReady(player) or statuses[player] ~= "Queued" or not alive(player) then return end
  local ack = standaloneAcknowledgements[player]
  if not ack or ack.character ~= player.Character or ack.token ~= prep.token then
   ack={character=player.Character,token=prep.token}
  end
  if payload.step == "Rendered" then ack.rendered = true
  elseif payload.step == "Ready" and ack.rendered and services.StagingService.IsPlayerDelivered(player) then
   player:SetAttribute("TournamentCourseReady",true)
  else return end
  standaloneAcknowledgements[player]=ack
 end)
 folder:WaitForChild("RequestSpectate").OnServerEvent:Connect(function(player)
  if now()-(lastRequest[player] or -math.huge) < .15 then return end
  lastRequest[player] = now();Service.RequestAction(player,{action="Watch"})
 end)
 folder:WaitForChild("RequestRaceLate").OnServerEvent:Connect(Service.RequestRaceLate)
 folder:WaitForChild("RequestGhostRace").OnServerEvent:Connect(Service.RequestGhostRace)
 Players.PlayerAdded:Connect(addPlayer)
 Players.PlayerRemoving:Connect(function(player)
  clearWatchFocus(player)
  withdraw(player,"Left race")
  for _,connection in connections[player] or {} do connection:Disconnect() end
  enrolled[player],statuses[player],official[player],admitted[player],cameraReady[player] = nil,nil,nil,nil,nil
  connections[player],tickets[player],messages[player],activity[player],lastRequest[player],reads[player],standaloneAcknowledgements[player] = nil,nil,nil,nil,nil,nil,nil
  Service.PublishFlow()
 end)
 for _,player in Players:GetPlayers() do addPlayer(player) end
 task.spawn(function()
  while started do
   task.wait(1)
   sampleActivity()
   for watcher,focus in watchFocus do
    local target = Players:GetPlayerByUserId(focus.userId)
    if not target or not alive(target) or statuses[target] ~= "Racing" or not official[target] then clearWatchFocus(watcher)
    elseif target.Character:FindFirstChild("HumanoidRootPart") ~= focus.part then Service.SetWatchTarget(watcher,focus.userId) end
   end
   if services.TournamentService then services.TournamentService.UpdateActiveRacers(#Service.GetRacingPlayers()) end
   Service.PublishFlow()
  end
 end)
end
return Service

