--!strict
local State = {}
function State.New(tournamentId: string)
 return {tournamentId=tournamentId,results={},race=nil}
end
function State.Bind(state: any,index: number,courseId: string,raceId: string)
 if state.results[index] then return false end
 state.race={tournamentId=state.tournamentId,index=index,courseId=courseId,raceId=raceId}
 return true
end
function State.Capture(state: any,result: any): boolean
 local key=state.race
 if not key or typeof(result)~="table" or result.raceId~=key.raceId or result.courseId~=key.courseId or state.results[key.index] then return false end
 local top,users={},{}
 for _,row in if typeof(result.placements)=="table" then result.placements else {} do
  if typeof(row)~="table" then continue end
  local rank=row.placement
  -- Studio local-server players have negative IDs in these authoritative result rows.
  if row.status=="Finished" and row.official==true and typeof(rank)=="number" and rank%1==0 and rank>=1 and rank<=3
   and typeof(row.userId)=="number" and row.userId==row.userId and math.abs(row.userId)<math.huge and row.userId%1==0
   and not users[row.userId] and top[rank]==nil
   and typeof(row.finishTime)=="number" and row.finishTime==row.finishTime and row.finishTime>=0 and row.finishTime<math.huge then
   users[row.userId]=true
   top[rank]={userId=row.userId,name=row.name,displayName=row.displayName,placement=rank,finishTime=row.finishTime}
  end
 end
 local finishers={}
 for rank=1,3 do if top[rank] then table.insert(finishers,top[rank]) end end
 state.results[key.index]={tournamentId=key.tournamentId,index=key.index,courseId=key.courseId,raceId=key.raceId,finishers=finishers}
 return true
end
function State.CopyResults(state: any)
 local rows={}
 for index,result in pairs(state.results) do
  local copy=table.clone(result);copy.finishers={}
  for _,row in result.finishers do table.insert(copy.finishers,table.clone(row)) end
  rows[index]=copy
 end
 return rows
end
function State.Preparation(token: string,courseId: string,index: number,time: number,transitionStartedAt: number?,timing: any)
 local previewAt=if transitionStartedAt then math.max(time,transitionStartedAt+timing.PreviewAtSeconds) else time+timing.OpeningLoadSeconds
 return {token=token,courseId=courseId,index=index,status="Loading",startedAt=time,
  loadAt=if transitionStartedAt then math.max(time,transitionStartedAt+timing.ResultsSeconds) else time,
  previewAt=previewAt,handoffAt=previewAt+timing.PreviewSeconds,revealUntil=previewAt+timing.PreviewSeconds,
  loadDeadline=time+timing.DeliveryTimeout,message="Preparing the next course"}
end
function State.SetLoaded(preparation: any,time: number,timing: any)
 preparation.previewAt=math.max(preparation.previewAt,time)
 preparation.handoffAt=preparation.previewAt+timing.PreviewSeconds
 preparation.revealUntil=preparation.handoffAt
 preparation.readyUntil=preparation.handoffAt+timing.ReadyTimeout
 preparation.status="Preparing"
end
function State.BayPresentation(snapshot: any,index: number)
 local lineup=snapshot.displayLineup or snapshot.lineup or {}
 local courseId=lineup[index]
 if not courseId then return {status="Empty",text="Awaiting the next lineup"} end
 local result=snapshot.results and snapshot.results[index]
 if result then return {status="Completed",text=if #result.finishers>0 then "Completed · official top three" else "Completed · no official finishers"} end
 if snapshot.phase=="Racing" and snapshot.displayTournamentId==snapshot.tournamentId and snapshot.raceIndex==index then
  if snapshot.preparation and not snapshot.activeRaceId then return {status="Preparing",text="Preparing this race"} end
  if snapshot.activeRaceId then return {status="Active",text=tostring(snapshot.activeRacers or 0).." racers remaining"} end
 end
 return {status="Upcoming",text="Upcoming · race "..index}
end
function State.RouteSamples(route: {any},limit: number): {any}
 if #route<=limit then return table.clone(route) end
 local samples={}
 for index=1,limit do table.insert(samples,route[1+math.floor((index-1)*(#route-1)/(limit-1))]) end
 return samples
end
return State
