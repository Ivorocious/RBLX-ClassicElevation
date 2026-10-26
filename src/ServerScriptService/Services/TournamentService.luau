--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Config=require(ReplicatedStorage.Config.TournamentConfig)
local Timing=require(ReplicatedStorage.Config.GrandArcadeConfig)
local Artwork=require(ReplicatedStorage.Config.VotingArtwork)
local Ballot=require(ReplicatedStorage.Shared.TournamentBallot)
local StageState=require(ReplicatedStorage.Shared.TournamentStageState)
local Service={}
local courseService: any
local stageService: any
local racers: any
local current: any=nil
local display: any=nil
local preparation: any=nil
local worker: any=nil
local event: RemoteEvent?
local revision=0
local preparing=false
local generation=0
local previousOpening: string?=nil
local activeRacers=0
local finaleStartedAt: number?=nil
local finaleUntil: number?=nil
local acknowledgements: {[Player]:any}={}
local random=Random.new()
local function now() return workspace:GetServerTimeNow() end
local function enrolled(player: Player): boolean
 return player.Parent==Players and racers~=nil and racers.IsEnrolled(player)
end
local function participants()
 local result={}
 for _,player in Players:GetPlayers() do
  if enrolled(player) and player:GetAttribute("OnboardingReady")==true then table.insert(result,player) end
 end
 return result
end
local function clearGates()
 for _,player in Players:GetPlayers() do player:SetAttribute("TournamentCourseReady",nil) end
 table.clear(acknowledgements)
end
local function catalog()
 local rows,ids={},{}
 for _,info in courseService.GetEligibleCourses() do
  table.insert(rows,{id=info.courseId,name=info.displayName,image=Artwork.Image(info.courseId)})
  table.insert(ids,info.courseId)
 end
 return rows,ids
end
local function copyPreparation()
 if not preparation then return nil end
 local result=table.clone(preparation)
 if preparation.delivery then
  result.delivery=table.clone(preparation.delivery)
  result.delivery.bounds=table.clone(preparation.delivery.bounds)
 end
 return result
end
local function snapshot(player: Player?,knownRows: {any}?)
 local rows=knownRows or catalog()
 local phase=if current then current.phase elseif #rows==0 then "Unavailable" else "Waiting"
 return {revision=revision,serverTime=now(),tournamentId=current and current.id or "",phase=phase,
  enrolled=player~=nil and enrolled(player),deadline=current and current.deadline or nil,duration=Config.VotingDuration,catalog=rows,
  picks=if current and player then table.clone(current.ballots[player.UserId] or {}) else {},
  lineup=current and current.lineup and table.clone(current.lineup) or {},raceIndex=current and current.index or nil,
  eventMode=current and current.mode or nil,activeRacers=activeRacers,
  activeRaceId=display and display.race and display.race.raceId or nil,
  displayTournamentId=display and display.tournamentId or "",displayLineup=display and table.clone(display.lineup or {}) or {},
  displayRaceIndex=display and display.index or nil,results=display and StageState.CopyResults(display) or {},
  preparation=copyPreparation(),finaleStartedAt=finaleStartedAt,finaleUntil=finaleUntil,
  message=if preparation then preparation.message elseif phase=="Unavailable" then "No playable courses are available. Try the practice portal." else nil}
end
local function broadcast()
 revision+=1
 -- One library scan per update; every recipient's snapshot shares these read-only rows.
 local rows=catalog()
 if stageService then stageService.Render(snapshot(nil,rows)) end
 if event then for _,player in Players:GetPlayers() do event:FireClient(player,snapshot(player,rows)) end end
 if racers and racers.PublishFlow then racers.PublishFlow() end
end
local function valid(token: string): boolean
 return current~=nil and current.phase=="Racing" and preparation~=nil and preparation.token==token and preparation.status~="Failed"
end
local function courseReady(): boolean
 local start=courseService.GetStartPart()
 return preparation~=nil and courseService.GetActiveCourseId()==preparation.courseId and start~=nil and start:IsDescendantOf(workspace)
end
local function stopWorker()
 if worker and not worker.done then pcall(task.cancel,worker.thread);worker.done=true end
 worker=nil
end
local function fail(token: string,message: string): (boolean,string?)
 if valid(token) then preparation.status,preparation.message="Failed",message;clearGates();broadcast() end
 stopWorker()
 return false,message
end
local function runBounded(token: string,deadline: number,callback: ()->any): boolean
 local job: any={done=false,ok=false,result=nil}
 worker=job
 job.thread=task.spawn(function() job.ok,job.result=pcall(callback);job.done=true end)
 repeat task.wait(.05) until job.done or not valid(token) or now()>=deadline
 if not job.done then stopWorker();return false end
 if worker==job then worker=nil end
 return valid(token) and job.ok and job.result~=false
end
local function filterBallots(round: any)
 local allowed={}
 for _,player in participants() do allowed[player.UserId]=true end
 for userId in round.ballots do if not allowed[userId] then round.ballots[userId]=nil end end
 return allowed
end
local function attachDelivery()
 local model=courseService.GetActiveCourseModel()
 local start=courseService.GetStartPart()
 local frame,size=model:GetBoundingBox()
 local parts=0
 for _,item in model:GetDescendants() do if item:IsA("BasePart") then parts+=1 end end
 preparation.delivery={modelName=model.Name,startPosition=start.Position,bounds={center=frame.Position,size=size},expectedParts=parts}
 local checkpoints=courseService.GetOrderedCheckpoints()
 local first=checkpoints[1] and checkpoints[1].part or courseService.GetFinishPart()
 if first then
  local rise=first.Position.Y-start.Position.Y
  local destination=if checkpoints[1] then "first checkpoint" else "finish"
  preparation.courseCue=if rise>4 then "The "..destination.." is above the start. Follow the rising route."
   elseif rise< -4 then "The "..destination.." is below the start. Look for the lower route."
   else "Find the "..destination.." ahead before committing to the next jump."
 end
end
local function attempt(selected: string,index: number,options: any,attemptNumber: number): (boolean,string?)
 local token=HttpService:GenerateGUID(false)
 preparation=StageState.Preparation(token,selected,index,now(),options.transitionStartedAt,Timing)
 preparation.attempt=attemptNumber
 for _,row in catalog() do if row.id==selected then preparation.courseDisplayName=row.name;break end end
 clearGates()
 for _,player in participants() do player:SetAttribute("TournamentCourseReady",false) end
 broadcast()
 while now()<preparation.loadAt do
  if not valid(token) then return false,"Cancelled" end
  if #participants()==0 then return fail(token,"No enrolled racers remain.") end
  task.wait(.05)
 end
 if #participants()==0 then return fail(token,"No enrolled racers remain.") end
 preparation.loadStartedAt=now();preparation.loadDeadline=now()+Timing.DeliveryTimeout
 local loaded=runBounded(token,preparation.loadDeadline,function()
  return courseService.LoadTournamentCourse(selected,function() return valid(token) and now()<preparation.loadDeadline end)
 end)
 if not valid(token) then return false,"Cancelled" end
 if not loaded or not courseReady() then return fail(token,"Could not load this course. You can stay in the lobby.") end
 attachDelivery()
 StageState.SetLoaded(preparation,now(),Timing)
 broadcast()
 while now()<preparation.previewAt do
  if not valid(token) then return false,"Cancelled" end
  if #participants()==0 then return fail(token,"No enrolled racers remain.") end
  task.wait(.05)
 end
 local delivered: {[Player]:Model}={}
 local function deliverNew(): boolean
  local additions={}
  for _,player in participants() do
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if character and humanoid and humanoid.Health>0 and delivered[player]~=character then
    table.insert(additions,player)
   end
  end
  if #additions==0 then return true end
  if options.onCourseLoaded and not runBounded(token,now()+Timing.ReadyTimeout,options.onCourseLoaded) then return false end
  for _,player in additions do if player.Character then delivered[player]=player.Character end end
  return true
 end
 if not deliverNew() then return fail(token,"Could not deliver racers safely. You can stay in the lobby.") end
 if not valid(token) then return false,"Cancelled" end
 preparation.previewAt=now();preparation.handoffAt=now()+Timing.PreviewSeconds
 preparation.revealUntil=preparation.handoffAt;preparation.readyUntil=preparation.handoffAt+Timing.ReadyTimeout
 preparation.status,preparation.message="Presentation",nil
 broadcast()
 while now()<preparation.handoffAt do
  if not valid(token) then return false,"Cancelled" end
  if #participants()==0 then return fail(token,"No enrolled racers remain.") end
  if not deliverNew() then return fail(token,"Could not deliver racers safely.") end
  task.wait(.1)
 end
 preparation.status,preparation.message="Ready",nil
 broadcast()
 return true,selected
end
function Service.Init(context: any)
 courseService=context.Services.CourseService;stageService=context.Services.GrandArcadeService;racers=context.Services.PlayerRaceService
end
function Service.Start()
 local folder=ReplicatedStorage:WaitForChild("Remotes")
 event=folder:WaitForChild("TournamentChanged") :: RemoteEvent
 local state=folder:WaitForChild("GetTournamentState") :: RemoteFunction
 local submit=folder:WaitForChild("SubmitMapVotes") :: RemoteFunction
 local ready=folder:WaitForChild("TournamentStageReady") :: RemoteEvent
 local lastRead: {[Player]:number}={}
 state.OnServerInvoke=function(player)
  if player.Parent~=Players or now()-(lastRead[player] or -math.huge)<.25 then return nil end
  lastRead[player]=now();return snapshot(player)
 end
 submit.OnServerInvoke=function(player,payload)
  if not current then return {ok=false,message="Voting isn't open."} end
  local time=now()
  local _,ids=catalog();Ballot.Refresh(current,ids)
  filterBallots(current)
  local reply=Ballot.Submit(current,player.UserId,payload,time,enrolled(player) and player:GetAttribute("OnboardingReady")==true,Config.SubmitCooldown)
  reply.tournamentId=current.id
  if reply.ok then
   if #participants()==1 then current.soloChoice=true end
   broadcast()
  end
  return reply
 end
 ready.OnServerEvent:Connect(function(player,payload)
  if typeof(payload)~="table" or typeof(payload.token)~="string" or not valid(payload.token)
   or not enrolled(player) or player:GetAttribute("OnboardingReady")~=true then return end
  local ack=acknowledgements[player] or {}
  local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health<=0 then return end
  if ack.character~=character then ack={character=character};player:SetAttribute("TournamentCourseReady",false) end
  if payload.step=="Rendered" and not ack.rendered then ack.rendered=true
  elseif payload.step=="Ready" and ack.rendered and not ack.ready and courseReady() and now()<=(preparation.readyUntil or math.huge)
   and racers.GetPlayerStatus(player)=="Queued" and preparation.delivery then
   ack.ready=true;player:SetAttribute("TournamentCourseReady",true)
   if racers.PublishFlow then racers.PublishFlow(player) end
  else return end
  acknowledgements[player]=ack
 end)
 Players.PlayerRemoving:Connect(function(player)
  lastRead[player],acknowledgements[player]=nil,nil
  if current and current.phase=="Voting" then current.ballots[player.UserId]=nil end
 end)
 broadcast()
end
function Service.Cancel(clearDisplay: boolean?)
 generation+=1;current,preparation=nil,nil
 if clearDisplay then display=nil;finaleStartedAt,finaleUntil=nil,nil end
 stopWorker();clearGates();activeRacers=0;broadcast()
end
function Service.AbortPreparation()
 generation+=1;preparation=nil;stopWorker()
 if display then display.race=nil end
 clearGates();broadcast()
end
function Service.PrepareNextCourse(options: any?): (boolean,string?)
 if not Config.Enabled then return true,nil end
 if preparing then return false,"Preparation is already running." end
 preparing=true
 local run=generation
 local ok,result,course=pcall(function()
  local settings=options or {}
  if #participants()==0 then Service.Cancel();return false,"No enrolled racers remain." end
  if not current or current.phase=="Complete" or current.phase=="Unavailable" then
   local _,ids=catalog()
   if #ids==0 then return false,"No playable courses are available." end
   current=Ballot.New(HttpService:GenerateGUID(false),ids,now()+Config.VotingDuration)
   preparation=nil;clearGates()
   local round=current;broadcast()
   while current==round and round.phase=="Voting" and now()<round.deadline do
    filterBallots(round)
    if #participants()==0 then Service.Cancel();return false,"No enrolled racers remain." end
    if round.soloChoice and #participants()==1 and next(round.ballots)~=nil then break end
    task.wait(.1)
   end
   if generation~=run or current~=round then return false,"Cancelled" end
   local _,latest=catalog();Ballot.Refresh(round,latest);filterBallots(round)
   if not Ballot.Finalize(round,function(a,b) return random:NextInteger(a,b) end,previousOpening) then
    broadcast();return false,"No playable courses are available."
   end
   previousOpening=round.lineup[1]
   display=StageState.New(round.id);display.lineup=table.clone(round.lineup);display.index=1
   finaleStartedAt,finaleUntil=nil,nil
   settings={onCourseLoaded=settings.onCourseLoaded}
   broadcast()
  end
  if not current or current.phase~="Racing" then return false,"Event unavailable." end
  local selected=current.lineup[current.index]
  for number=1,Timing.PreparationAttempts do
   if generation~=run then return false,"Cancelled" end
   local success,message=attempt(selected,current.index,settings,number)
   if success then return true,selected end
   if generation~=run then return false,"Cancelled" end
   if #participants()==0 then Service.Cancel();return false,"No enrolled racers remain." end
   if number==Timing.PreparationAttempts then return false,message end
  end
  return false,"Preparation failed."
 end)
 preparing=false
 if not ok then
  if preparation then fail(preparation.token,"Preparation failed. You can stay in the lobby.") end
  warn("[TournamentService] "..tostring(result))
  return false,"Preparation failed. You can stay in the lobby."
 end
 return result,course
end
function Service.BindRace(raceId: string,courseId: string)
 if current and current.phase=="Racing" and current.lineup[current.index]==courseId and display then
  StageState.Bind(display,current.index,courseId,raceId);display.index=current.index;broadcast()
 end
end
function Service.CaptureRace(result: any): boolean
 if not display or not current or current.phase~="Racing" then return false end
 local captured=StageState.Capture(display,result)
 if captured then activeRacers=0;broadcast() end
 return captured
end
function Service.CompleteRace()
 if not current or not display or not display.results[current.index] then return end
 Ballot.Advance(current);preparation=nil;display.race=nil;display.index=current.index;clearGates()
 if current.phase=="Complete" and current.mode=="Tournament" then finaleStartedAt=now();finaleUntil=finaleStartedAt+Timing.FinaleSeconds end
 broadcast()
end
function Service.UpdateActiveRacers(count: number)
 if typeof(count)~="number" or count%1~=0 or count<0 or count==math.huge or count==activeRacers then return end
 activeRacers=count;broadcast()
end
function Service.IsEventComplete(): boolean return current~=nil and current.phase=="Complete" end
function Service.GetPreparation() return copyPreparation() end
function Service.GetCourseToken(): string? return preparation and preparation.token or nil end
function Service.GetSnapshot(player: Player?) return snapshot(player) end
return Service
