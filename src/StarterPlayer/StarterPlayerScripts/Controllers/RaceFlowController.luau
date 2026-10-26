--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local View=require(script.Parent.RaceFlowView)
local Presentation=require(script.Parent.RaceFlowPresentation)
local CoursePresentation=require(script.Parent.TournamentPresentation)
local Spectate=require(script.Parent.SpectateController)
local Ownership=require(script.Parent.CameraOwnership)
local Intro=require(script.Parent.VisitIntroController)
local PracticeCamera=require(script.Parent.PracticeCameraSettling)
local Lobby=require(script.Parent.LobbyUiController)
local RacePresentation=require(script.Parent.RacePresentation)
local PracticeConfig=require(ReplicatedStorage.Config.PracticeConfig)
local Artwork=require(ReplicatedStorage.Config.VotingArtwork)
local ResultsScreen=require(script.Parent.ResultsScreen)
local Controller={}
local player=Players.LocalPlayer
local state: any=nil
local practice: any=nil
local event: any=nil
local ui: any=nil
local actionRemote: RemoteFunction?=nil
local practiceRemote: RemoteFunction?=nil
local stageReady: RemoteEvent?=nil
local revision=-1
local requestVersion=0
local pending,open=false,false
local message=""
local lastTicket=""
local finale: any=nil
local initialized=false
local observers: any={}
local raceClock: any=nil
-- Practice bests per line seen this visit, and the best before the latest finish (display only).
local practiceBests: {[string]: number}={}
local practiceFinish: any=nil
-- Events whose end screen the player closed with Back to lobby.
local eventEndClosed: {[string]: boolean}={}
local notified: any=nil
local notifiedOpen=false
local wasVoting=false
local function ready(): boolean
 return player:GetAttribute("OnboardingReady")==true and player:GetAttribute("ArrivalOpen")~=true and player:GetAttribute("ArrivalPhase")=="Ready"
end
local function stopFinale()
 if finale then Ownership.Release(finale.lease); finale=nil end
 RunService:UnbindFromRenderStep("VisitFinaleCamera")
end
local function practiceLanes(): any
 local area=workspace:FindFirstChild(PracticeConfig.CircuitName)
 local lanes={}
 for _,name in {"Normal","Hard"} do
  local lane=area and area:FindFirstChild(name)
  if lane then lanes[name]={pads=lane:GetAttribute("PadCount"),laps=lane:GetAttribute("LapCount")} end
 end
 return lanes
end
-- Event end summary from the history the event already keeps plus your remembered placings.
local function eventSummary(key: string): any
 local lineup=event.displayLineup or event.lineup or {}
 local texts,places=ResultsScreen.EventPlacings(key)
 local races,best,finished={},nil,0
 for index,courseId in lineup do
  local result=event.results and (event.results[index] or event.results[tostring(index)])
  local winner=nil
  if result then for _,entry in result.finishers or {} do if entry.placement==1 then winner=entry end end end
  local place=places[index]
  if place then finished+=1; if not best or place<best then best=place end end
  local ok,image=pcall(Artwork.Image,courseId)
  table.insert(races,{image=if ok and typeof(image)=="string" then image else "",winnerName=winner and tostring(winner.displayName or winner.name or "Racer"),
   winnerUserId=winner and winner.userId,winnerTime=winner and winner.finishTime,mine=texts[index],place=place})
 end
 local visit=state and state.visit
 return {key=key,raceCount=#lineup,races=races,best=best,finished=finished,
  visit=if visit then "This visit: "..Presentation.VisitCounts(visit) else nil}
end
local function render()
 if not state or not ui then return end
 -- A new vote replaces the last race's ticket instead of sitting on top of it.
 local voting=player:GetAttribute("VoteOpen")==true
 if voting and not wasVoting then open=false end
 wasVoting=voting
 -- Observers first: the race HUD may start a finish moment that the panel below must respect.
 if observers.Flow and (notified~=state or notifiedOpen~=open) then
  notified,notifiedOpen=state,open
  observers.Flow(state,open)
 end
 local model=Presentation.Model(state,practice or state.practice,workspace:GetServerTimeNow())
 -- The panel's title names the panel; the course already shows on the lobby card.
 if model.title==tostring(state.courseDisplayName or "Race options") then model.title="Race options" end
 local introCue=Intro.GetCue()
 local practiceScreen=if introCue then nil else Presentation.PracticeScreen(state,practice or state.practice,practiceLanes(),practiceBests,practiceFinish,workspace:GetServerTimeNow())
 model.practiceScreen=practiceScreen
 if introCue then
  model.ticket=nil
  -- The coach card replaces the Race options panel while the guide runs; its last step offers the join action.
  model.coach={title=introCue.title,message=introCue.message,step=introCue.step,count=introCue.count,buttons={}}
  if introCue.step==introCue.count and state.enrolled~=true then table.insert(model.coach.buttons,{id="Join",text=tostring(state.actionLabel or "Start racing")}) end
 elseif Intro.CanStart(state) and (not practice or practice.inRoom~=true) then table.insert(model.buttons,{id="Intro",text="Show me around"}) end
 if state.status~="Racing" then
  table.insert(model.buttons,{id="ReduceMotion",text=if player:GetAttribute("ReducedMotion")==true then "Motion reduced · turn on" else "Reduce motion"})
 end
 if event and event.finaleUntil and workspace:GetServerTimeNow()<event.finaleUntil and state.status~="Racing" then
  table.insert(model.buttons,{id=if finale then "ExitFinale" else "Finale",text=if finale then "Exit celebration" else "View completed event"})
 end
 if state.status=="Spectating" then model.title="Watching "..Spectate.GetTargetName() end
 if model.ticket and raceClock and raceClock.state=="Racing" and typeof(raceClock.remaining)=="number" then
  model.ticket.resultsIn=RacePresentation.Remaining(raceClock.remaining-(os.clock()-raceClock.at))
 end
 -- A finish or "time's up" moment owns the screen briefly; the ticket follows it.
 local moment=player:GetAttribute("RaceMoment")==true
 ui.LauncherSlot(if observers.LauncherSlot then observers.LauncherSlot() else nil)
 ui.Practice(if ready() and not moment and player:GetAttribute("TournamentPresentation")~=true then practiceScreen else nil)
 -- Watching has its own screen (WatchView via the race HUD); Race options only shows when opened.
 if observers.Watch then
  local watchId,loading=Spectate.GetTarget()
  observers.Watch(if ready() and not moment and state.status=="Spectating" then {userId=watchId,name=Spectate.GetTargetName(),loading=loading or watchId==nil} else nil)
 end
 local eventKey=if event and typeof(event.finaleUntil)=="number" then tostring(event.displayTournamentId or event.tournamentId) else nil
 local showEnd=eventKey~=nil and workspace:GetServerTimeNow()<event.finaleUntil and state.status~="Racing" and ready() and not moment and finale==nil
  and not eventEndClosed[eventKey] and not ResultsScreen.IsShowing() and player:GetAttribute("TournamentPresentation")~=true
 ui.EventEnd(if showEnd and eventKey then eventSummary(eventKey) else nil)
 ui.Finale(finale~=nil)
 -- Race options waits behind the results screen rather than showing through its shade.
 ui.Show(model,ready() and not moment and player:GetAttribute("TournamentPresentation")~=true and open and not showEnd and not ResultsScreen.IsShowing() and not voting,pending,message)
 -- The lobby keeps only its wallet in the practice area, so the launcher reopens Race options there.
 if player:GetAttribute("PracticeRoom")~=(practiceScreen~=nil) then player:SetAttribute("PracticeRoom",practiceScreen~=nil) end
 ui.Launcher(ready() and not moment and player:GetAttribute("TournamentPresentation")~=true and (not Lobby.IsVisible() or practiceScreen~=nil) and not open and state.status~="Spectating")
 local departure=state.departureAt
 local notice=if state.status=="Lobby" then Presentation.PracticeNotice(practice or state.practice,workspace:GetServerTimeNow()) else ""
 if state.enrolled and typeof(departure)=="number" and (practice or state.practice) and (practice or state.practice).status=="Running" then
  notice..=(if notice~="" then "\n" else "").."Your next race is preparing · practice ends when you depart"
 end
 ui.Notice(if ready() and not practiceScreen then notice else "")
end
function Controller.IsAvailable(): boolean return state~=nil end
function Controller.IsOpen(): boolean return open end
-- Race phase and remaining time from RaceUiController, for the finish ticket's "results in" line.
function Controller.SetRaceClock(raceState: string?,remaining: number?)
 -- The finish ticket belongs to the running race; when it ends, results take over the screen.
 local ended=raceClock and raceClock.state=="Racing" and raceState~="Racing"
 raceClock={state=raceState,remaining=remaining,at=os.clock()}
 if ended and open and ui and ui.IsTicketVisible() then open=false; render() end
 -- The last race's ticket would otherwise sit over the next countdown for a queued racer.
 if raceState=="Countdown" and open and state and state.status=="Queued" then open=false; render() end
end
function Controller.Open() open=true; Lobby.ClosePanel(); render() end
function Controller.GetState(): any return state end
local function closeChoices()
 open=false
 if ui then ui.CloseChoices() end
end
local function alignPracticeCamera()
 PracticeCamera.Schedule(function() return state end,function() return practice end)
end
local function receivePractice(payload: any)
 if typeof(payload)~="table" or not Presentation.IsNewerPractice(practice,payload) then return end
 local previous=practice
 local transition=Presentation.PracticeTransition(previous,payload)
 local line=tostring(payload.line or "Normal")
 if transition=="Finished" then practiceFinish={attemptId=payload.attemptId,previous=practiceBests[line]} end
 if typeof(payload.bestTime)=="number" then practiceBests[line]=payload.bestTime end
 practice=payload
 if state and state.status=="Lobby" then
  if transition=="Running" then closeChoices()
  elseif transition=="Entered" then open=true; alignPracticeCamera()
  elseif transition=="Exited" then closeChoices(); PracticeCamera.Cancel()
  elseif transition=="Finished" then open=true; message="" end
  if previous and typeof(previous.falls)=="number" and typeof(payload.falls)=="number" and payload.status=="Running" and payload.falls>previous.falls then alignPracticeCamera() end
 end
end

local accept: (any) -> ()
local function focusWatchTarget(userId: number)
 if not actionRemote then return end
 local requestedRace = state and state.raceId
 task.spawn(function()
  for attempt=1,3 do
   if not state or state.status~="Spectating" or state.raceId~=requestedRace then return end
   local ok,reply=pcall(function() return actionRemote:InvokeServer({action="WatchTarget",targetUserId=userId}) end)
   if ok and typeof(reply)=="table" and reply.ok==true then return end
   if attempt<3 then task.wait(.2) end
  end
 end)
end
function Controller.Action(action: string, token: string?)
 if not actionRemote or not ready() then return end
 if action~="CameraReady" then Intro.Stop() end
 if action~="CameraReady" then PracticeCamera.Cancel() end
 if action=="StopWatching" then Spectate.Stop() end
 if pending and action~="CameraReady" then return end
 local version=requestVersion
 if action~="CameraReady" then requestVersion+=1; version=requestVersion; pending=true; message="Waiting for the server…"; render() end
 local requestedRace=state and state.raceId
 task.spawn(function()
  local ok,reply
  for attempt=1,(if action=="CameraReady" then 3 else 1) do
   if action=="CameraReady" and (not state or not state.preparation or state.preparation.token~=token or state.status~="Queued") then return end
   ok,reply=pcall(function() return actionRemote:InvokeServer({action=action,token=token}) end)
   if action~="CameraReady" or (ok and typeof(reply)=="table" and reply.ok==true) then break end
   if attempt<3 then task.wait(.3) end
  end
  if action=="CameraReady" then
   if ok and typeof(reply)=="table" then accept(reply.flow or reply.snapshot or reply) end
   return
  end
  if requestVersion~=version or (state and state.raceId~=requestedRace) then return end
  pending=false
  message=if ok and typeof(reply)=="table" then tostring(reply.message or "") else "Couldn't confirm. Please try again."
  if ok and typeof(reply)=="table" then accept(reply.flow or reply.snapshot or reply) end
  render()
 end)
 if action~="CameraReady" then task.delay(6,function()
  if pending and requestVersion==version then pending=false; requestVersion+=1; message="Couldn't confirm. Please try again."; render() end
 end) end
end
local function practiceAction(action: string,line: string?)
 if pending or not practiceRemote or not ready() then return end
 Intro.Stop()
 PracticeCamera.Cancel()
 requestVersion+=1
 local version=requestVersion
 pending,message=true,"Preparing practice…"; render()
 task.spawn(function()
  local ok,reply=pcall(function() return practiceRemote:InvokeServer({action=action,line=line}) end)
  if version~=requestVersion then return end
  pending=false
  message=if ok and typeof(reply)=="table" then tostring(reply.message or "") else "Practice couldn't be confirmed. Try again."
  if ok and typeof(reply)=="table" and reply.practice then receivePractice(reply.practice) end
  if ok and typeof(reply)=="table" and Presentation.AcceptPracticeAction(state,action,reply) then
   -- Entering opens the line choice; starting a run clears the screen for the HUD.
   if action=="Enter" then open=true else closeChoices() end
   message=""; alignPracticeCamera()
  elseif action=="Exit" and ok and typeof(reply)=="table" and Presentation.AcceptPracticeExit(state,reply) then
   closeChoices(); message=""; PracticeCamera.Cancel()
  end
  render()
 end)
 task.delay(6,function() if pending and requestVersion==version then requestVersion+=1; pending=false; message="Practice couldn't be confirmed. Try again."; render() end end)
end
local function viewFinale()
 if not event or not event.finaleUntil or workspace:GetServerTimeNow()>=event.finaleUntil or not ready() or (state and state.status=="Racing") then return end
 local stage=workspace:FindFirstChild("GrandArcade")
 if not stage or not stage:IsA("Model") then message="Completed event display is still loading."; render(); return end
 Intro.Stop()
 PracticeCamera.Cancel()
 local lease=Ownership.Acquire("Finale",stopFinale,false)
 if not lease then return end
 finale={lease=lease,untilTime=event.finaleUntil}
 local frame=stage:GetPivot()
 local target=CFrame.lookAt(frame:PointToWorldSpace(Vector3.new(0,12,65)),frame:PointToWorldSpace(Vector3.new(0,6,0)))
 RunService:BindToRenderStep("VisitFinaleCamera",Enum.RenderPriority.Camera.Value+2,function()
  if not finale then return end
  if not ready() or not Ownership.IsOwner(lease) or workspace.CurrentCamera~=lease.camera or workspace:GetServerTimeNow()>=finale.untilTime or (state and state.status=="Racing") then stopFinale(); render(); return end
  lease.camera.CameraType,lease.camera.CFrame=Enum.CameraType.Scriptable,target
 end)
 render()
end
function Controller.HandleTournament(snapshot: any)
 event=snapshot
 CoursePresentation.SetEvent(snapshot)
 if observers.Tournament then observers.Tournament(snapshot) end
 if not event or not event.finaleUntil or workspace:GetServerTimeNow()>=event.finaleUntil then stopFinale() end
 render()
end
accept=function(payload: any)
 if typeof(payload)~="table" or typeof(payload.revision)~="number" or payload.revision<revision then return end
 local old=state
 payload.courseDisplayName=RacePresentation.CourseName(payload.courseDisplayName)
 revision,state=payload.revision,payload
 Intro.Update(state)
 -- Race options no longer pops open on arrival: the lobby's next-race card carries the same actions.
 if old and old.raceId~=state.raceId then requestVersion+=1; pending=false; message="" end
 if state.status~="Lobby" then PracticeCamera.Cancel() end
 if state.practice then receivePractice(state.practice) end
 Lobby.UpdateFlow(state)
 local key=Presentation.FinishChoiceKey(state,practice)
 if key and key~=lastTicket then lastTicket=key; open=true end
 Spectate.Update(state.watchTargets,state.status=="Spectating",function() Controller.Action("StopWatching") end,focusWatchTarget)
 local prep=state.preparation
 if ready() and state.enrolled and state.entryOpen==true and state.state=="Intermission" and prep and prep.status~="Failed" and state.status~="Racing" then
  if CoursePresentation.HasSession(prep.token) then CoursePresentation.Update(state)
  else CoursePresentation.Start(state,function(token,step) if stageReady then stageReady:FireServer({token=token,step=step}) end end,function(token) Controller.Action("CameraReady",token) end) end
 else
  CoursePresentation.Stop()
  if ready() then CoursePresentation.ShowFailure(state) end
 end
 if state.status=="Racing" then stopFinale(); open=false end
 render()
end
function Controller.Init(listeners: any?)
 if initialized then return end
 initialized=true
 observers=listeners or {}
 local function activate(action: string)
  if action=="Open" then Controller.Open()
  elseif action=="Close" then Intro.Stop(); open=false; render()
  elseif action=="Next" then Spectate.Cycle(1); render()
  elseif action=="Previous" then Spectate.Cycle(-1); render()
  elseif action=="PracticeNormal" then practiceAction("Start","Normal")
  elseif action=="EnterPractice" then practiceAction("Enter")
  elseif action=="PracticeHard" then practiceAction("Start","Hard")
  elseif action=="Retry" then practiceAction("Retry")
  elseif action=="ExitPractice" then practiceAction("Exit")
  elseif action=="Finale" then viewFinale()
  elseif action=="ExitFinale" then stopFinale(); render()
  elseif action=="CloseEventEnd" then
   if event then eventEndClosed[tostring(event.displayTournamentId or event.tournamentId)]=true end
   render()
  elseif action=="Intro" then PracticeCamera.Cancel(); Intro.Start(state); open=true; render()
  elseif action=="SkipIntro" then Intro.Stop(); render()
  elseif action=="ReduceMotion" then player:SetAttribute("ReducedMotion",player:GetAttribute("ReducedMotion")~=true); render()
  else Controller.Action(action) end
 end
 -- Other screens (the lobby card) reuse the Race options actions by id.
 Controller.Activate=activate
 CoursePresentation.SetActions(activate)
 ui=View.Create(player,activate)
 task.spawn(function()
  local folder=ReplicatedStorage:WaitForChild("Remotes")
  actionRemote=folder:WaitForChild("RaceAction") :: RemoteFunction
  practiceRemote=folder:WaitForChild("PracticeAction") :: RemoteFunction
  stageReady=folder:WaitForChild("TournamentStageReady") :: RemoteEvent
  local flowChanged=folder:WaitForChild("RaceFlowChanged") :: RemoteEvent
  local practiceChanged=folder:WaitForChild("PracticeStateChanged") :: RemoteEvent
  flowChanged.OnClientEvent:Connect(accept)
  practiceChanged.OnClientEvent:Connect(function(payload)
   receivePractice(payload); render()
  end)
  local getState=folder:WaitForChild("GetRaceFlowState") :: RemoteFunction
  for _=1,3 do local ok,result=pcall(function() return getState:InvokeServer() end); if ok then accept(result); if state then break end end; task.wait(1) end
 end)
 for _,name in {"ArrivalOpen","ArrivalPhase","OnboardingReady","TournamentPresentation","VisitIntroAvailable"} do player:GetAttributeChangedSignal(name):Connect(function()
  if not ready() then PracticeCamera.Cancel(); Intro.Stop(); stopFinale(); Spectate.Stop(); CoursePresentation.Stop() end
  if ready() and state and name~="TournamentPresentation" then accept(state) end
  render()
 end) end
 player:GetAttributeChangedSignal("RaceMoment"):Connect(render)
 player.CharacterRemoving:Connect(stopFinale)
 player.CharacterRemoving:Connect(PracticeCamera.Cancel)
 player.CharacterRemoving:Connect(function() if state and state.preparation then CoursePresentation.Forget(state.preparation.token) end; CoursePresentation.Stop() end)
 player.CharacterAdded:Connect(function() task.delay(.3,function() if state then accept(state) end end) end)
 workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() PracticeCamera.Cancel(); if state and state.preparation then CoursePresentation.Forget(state.preparation.token) end end)
 local elapsed=0
 RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt
  if elapsed<.2 then return end
  elapsed=0
  if state and ready() then Spectate.Update(state.watchTargets,state.status=="Spectating",function() Controller.Action("StopWatching") end,focusWatchTarget) end
  if state and ready() and state.entryOpen==true and state.state=="Intermission" and state.status=="Queued" and state.preparation and not CoursePresentation.HasSession(state.preparation.token) then accept(state) end
  render()
 end)
end
return Controller
