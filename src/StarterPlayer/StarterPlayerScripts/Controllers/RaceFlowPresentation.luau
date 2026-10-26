--!strict
local Presentation = {}
function Presentation.FinishChoiceKey(state: any,practice: any): string?
 local ticket = state and state.finishTicket
 if not ticket or state.status == "Racing" or (practice and practice.status == "Running") then return nil end
 return tostring(ticket.raceId)..":"..tostring(ticket.status)
end
-- "1 race entered · 0 completed": this visit's counts, shared by the flow ticket, results and event end.
function Presentation.VisitCounts(visit: any): string
 local entered = tonumber(visit and visit.racesEntered) or 0
 return entered..(if entered == 1 then " race" else " races").." entered · "..tostring(tonumber(visit and visit.completions) or 0).." completed"
end
local function time(value: any): string
 if typeof(value)~="number" or value<0 or value>=math.huge then return "—" end
 return string.format("%d:%05.2f",math.floor(value/60),value%60)
end
function Presentation.AcceptPracticeAction(state: any,action: string,reply: any): boolean
 return state~=nil and state.status=="Lobby" and reply~=nil and reply.ok==true and reply.practice~=nil and reply.practice.inRoom==true
  and (action=="Enter" or action=="Start" or action=="Retry")
end
function Presentation.AcceptPracticeExit(state: any,reply: any): boolean
 return state~=nil and state.status=="Lobby" and reply~=nil and reply.ok==true and reply.practice~=nil and reply.practice.inRoom==false
end
function Presentation.IsNewerPractice(previous: any,current: any): boolean
 if not current then return false end
 if previous and typeof(previous.activityRevision)=="number" and typeof(current.activityRevision)=="number" and current.activityRevision<previous.activityRevision then return false end
 if not previous or typeof(previous.attemptId)~="number" or typeof(current.attemptId)~="number" then return true end
 if current.attemptId<previous.attemptId then return false end
 if current.attemptId==previous.attemptId and current.status=="Running" then
  if previous.status=="Finished" or previous.status=="Interrupted" or (previous.status=="Idle" and previous.startedAt==nil) then return false end
  if typeof(previous.nextCheckpoint)=="number" and typeof(current.nextCheckpoint)=="number" and current.nextCheckpoint<previous.nextCheckpoint then return false end
 end
 return true
end
function Presentation.PracticeTransition(previous: any,current: any): string?
 if not current then return nil end
 local changed=not previous or previous.status~=current.status or previous.attemptId~=current.attemptId
 if changed and current.status=="Finished" and typeof(current.lastTime)=="number" and current.lastTime>0 and current.lastTime<math.huge then return "Finished" end
 if changed and current.status=="Running" and current.inRoom==true then return "Running" end
 if current.inRoom==true and (not previous or previous.inRoom~=true) then return "Entered" end
 if previous and previous.inRoom==true and current.inRoom==false then return "Exited" end
 return nil
end
function Presentation.PracticeNotice(practice: any,serverNow: number?): string
 if not practice or practice.status~="Running" or practice.inRoom~=true then return "" end
 local elapsed=practice.elapsed
 if typeof(serverNow)=="number" and typeof(practice.startedAt)=="number" then elapsed=math.max(0,serverNow-practice.startedAt) end
 local nextPad=if practice.nextPad then "next "..tostring(practice.nextPad) else "next step "..tostring(practice.nextCheckpoint or "—")
 return "Practice "..time(elapsed).." · lap "..tostring(practice.lap or 1).."/"..tostring(practice.lapCount or "—").." · "..nextPad
end
-- Practice screens (brief "Practice") while the player is in the practice area: "Lines", "Running"
-- or "Finished". `lanes` holds each line's pad and lap counts from the lane attributes, `bests` the
-- best time per line seen this visit and `finish` the best before the latest finish.
function Presentation.PracticeScreen(state: any,practice: any,lanes: any,bests: any,finish: any,serverNow: number?): any
 if not state or state.status~="Lobby" or not practice or practice.available~=true or practice.inRoom~=true then return nil end
 local line=tostring(practice.line or "Normal")
 if practice.status=="Running" then
  local elapsed=practice.elapsed
  if typeof(serverNow)=="number" and typeof(practice.startedAt)=="number" then elapsed=math.max(0,serverNow-practice.startedAt) end
  local padCount=practice.padCount
  local nextIndex=if typeof(padCount)=="number" and padCount>0 and typeof(practice.nextCheckpoint)=="number" then practice.nextCheckpoint%padCount else nil
  local departure=if state.enrolled and typeof(state.departureAt)=="number" and typeof(serverNow)=="number" then math.max(0,state.departureAt-serverNow) else nil
  return {mode="Running",line=line,startedAt=practice.startedAt,elapsed=elapsed,lap=practice.lap,lapCount=practice.lapCount,padCount=padCount,
   nextIndex=nextIndex,best=bests and bests[line],departure=departure,course=state.courseDisplayName}
 end
 if practice.status=="Finished" and typeof(practice.lastTime)=="number" and practice.lastTime>0 then
  local previous=if finish and finish.attemptId==practice.attemptId then finish.previous else nil
  return {mode="Finished",line=line,time=practice.lastTime,previous=previous,best=practice.bestTime,other=if line=="Hard" then "Normal" else "Hard"}
 end
 local choices={}
 for _,name in {"Normal","Hard"} do
  local lane=lanes and lanes[name] or {}
  table.insert(choices,{line=name,pads=lane.pads,laps=lane.laps,best=bests and bests[name]})
 end
 return {mode="Lines",lines=choices}
end
function Presentation.Model(state: any, practice: any, serverNow: number?): any
 local ticket = state.finishTicket
 local title = tostring(state.courseDisplayName or "Race options")
 local lines = {}
 local practiceResult=practice and practice.status=="Finished" and typeof(practice.lastTime)=="number" and practice.lastTime>0
 if practiceResult then title="Practice finished"; table.insert(lines,tostring(practice.line or "Normal").." · "..time(practice.lastTime)) end
 if ticket then
  local officialTitle=if ticket.status=="Finished" and ticket.official==true then "Course completed" else "Run unfinished"
  if practiceResult then table.insert(lines,"Official race history · "..officialTitle) else title=officialTitle end
  if ticket.official==true and ticket.status=="Finished" then
   table.insert(lines,"Place "..tostring(ticket.placement or "—").." · "..time(ticket.finishTime))
   if ticket.isVisitBest and typeof(ticket.previousBestTime)=="number" then table.insert(lines,"Fastest official run on this course this visit") end
  else
   if typeof(ticket.furthestCheckpoint)=="number" and typeof(ticket.checkpointCount)=="number" then
    table.insert(lines,"Reached checkpoint "..ticket.furthestCheckpoint.." of "..ticket.checkpointCount)
   end
  end
 end
 if state.message and state.message~="" then table.insert(lines,state.message) end
 local visit = state.visit
 if visit then
  table.insert(lines,Presentation.VisitCounts(visit).." this visit")
  if visit.target and visit.target.message then table.insert(lines,"Optional target: "..visit.target.message) end
 end
 if practice and practice.available then
  if practice.inRoom~=true then table.insert(lines,tostring(practice.entranceCue or "Enter the practice portal to reach the separate practice area.")) end
  if practice.status~="Idle" then table.insert(lines,tostring(practice.message or practice.status)) end
  if practice.inRoom==true and practice.status=="Running" and practice.lapCount then table.insert(lines,"Lap "..tostring(practice.lap or 1).." of "..practice.lapCount.." · return to Start after each lap") end
  if practice.inRoom==true and practice.status=="Running" then
   local elapsed=practice.elapsed
   if typeof(serverNow)=="number" and typeof(practice.startedAt)=="number" then elapsed=math.max(0,serverNow-practice.startedAt) end
   table.insert(lines,"Practice "..time(elapsed).." · checkpoint "..tostring((practice.nextCheckpoint or 1)-1).." of "..tostring(practice.checkpointCount or "—"))
  end
  if practice.status=="Finished" and practice.lastTime and not practiceResult then table.insert(lines,"Practice finish: "..time(practice.lastTime)) end
  if practice.bestTime then table.insert(lines,tostring(practice.line or "Normal").." practice best this visit: "..time(practice.bestTime)) end
 end
 if state.inactivityWarning then table.insert(lines,"Still racing? Keep racing to stay in this race.") end
 local buttons = {}
 if state.inactivityWarning then table.insert(buttons,{id="KeepRacing",text="Keep racing"}) end
 if state.status=="Spectating" then
  table.insert(buttons,{id="Previous",text="Previous racer"}); table.insert(buttons,{id="Next",text="Next racer"})
  table.insert(buttons,{id="StopWatching",text="Exit watching"})
 else
  table.insert(buttons,{id=if state.enrolled then "Break" else "Join",text=if state.enrolled then "Take a break" else tostring(state.actionLabel or "Start racing")})
  if state.status~="Racing" and state.status~="Queued" then
   if #(state.watchTargets or {})>0 then table.insert(buttons,{id="Watch",text="Watch racers"}) end
   if state.status=="Lobby" and practice and practice.available and practice.inRoom~=true then table.insert(buttons,{id="EnterPractice",text="Enter practice portal"}) end
   if practice and practice.available and practice.inRoom==true then
    if practice.status=="Running" then table.insert(buttons,{id="Retry",text="Retry practice"})
    elseif practice.status=="Finished" then
     table.insert(buttons,{id="Retry",text="Retry practice"})
     table.insert(buttons,{id=if practice.line=="Hard" then "PracticeNormal" else "PracticeHard",text=if practice.line=="Hard" then "Try the normal route" else "Try the harder line"})
    else table.insert(buttons,{id="PracticeNormal",text="Practice normal route"}); table.insert(buttons,{id="PracticeHard",text="Practice harder line"}) end
    table.insert(buttons,{id="ExitPractice",text="Return to lobby"})
   end
  end
  if state.status=="Finished" or state.status=="DNF" or state.status=="Racing" then table.insert(buttons,{id="Lobby",text="Return to lobby"}) end
 end
 local finishView=nil
 -- The finish ticket layout is only for the race the player just left; older tickets keep the
 -- ordinary panel so its title, lines and enrolment stay visible.
 if ticket and not practiceResult and ticket.raceId~=nil and ticket.raceId==state.raceId
  and (state.status=="Finished" or state.status=="DNF" or state.status=="Lobby") then
  -- Structured copy of the same ticket lines for the finish ticket layout.
  finishView={finished=ticket.status=="Finished" and ticket.official==true,placement=ticket.placement,finishTime=ticket.finishTime,
   visitBest=ticket.isVisitBest==true and typeof(ticket.previousBestTime)=="number",
   furthest=ticket.furthestCheckpoint,count=ticket.checkpointCount,
   target=if visit and visit.target and visit.target.message then "Optional target: "..visit.target.message else nil,
   visitLine=if visit then Presentation.VisitCounts(visit).." this visit" else nil,
   message=if state.message and state.message~="" then state.message else nil}
 end
 return {title=title,body=table.concat(lines,"\n"),buttons=buttons,enrolled=state.enrolled==true,enrollment=if state.enrolled then "You're in for the next race" else "Choose to join races for this visit",ticket=finishView}
end
return Presentation
