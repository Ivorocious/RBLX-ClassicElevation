--!strict
local Ballot = {}
function Ballot.Validate(picks: any, eligible: {[string]: boolean}): (boolean, string?)
 if typeof(picks) ~= "table" then return false,"Choose an opening course." end
 local count=0
 for key,id in pairs(picks) do
  if key~=1 or typeof(id)~="string" or #id>100 then return false,"Choose one opening course." end
  if not eligible[id] then return false,"That course is unavailable." end
  count+=1
 end
 if count~=1 then return false,"Choose an opening course." end
 return true,nil
end
function Ballot.New(id: string,ids: {string},deadline: number)
 local round: any={id=id,deadline=deadline,phase="Voting",eligible={},ballots={},requests={},lastRequest={},ranking=nil,lineup=nil,index=1}
 for _,courseId in ids do round.eligible[courseId]=true end
 return round
end
function Ballot.Refresh(round: any,ids: {string})
 if round.phase~="Voting" then return end
 local eligible={}
 for _,id in ids do eligible[id]=true end
 round.eligible=eligible
 for userId,picks in pairs(round.ballots) do if not Ballot.Validate(picks,eligible) then round.ballots[userId]=nil end end
end
function Ballot.Submit(round: any,userId: number,payload: any,time: number,ready: boolean,cooldown: number)
 if not ready then return {ok=false,message="Join racing to vote."} end
 if typeof(payload)~="table" or payload.tournamentId~=round.id then return {ok=false,message="This vote has ended."} end
 local requestId=payload.requestId
 if typeof(requestId)~="number" or requestId%1~=0 or requestId<1 or requestId>2147483647 then return {ok=false,message="Invalid request."} end
 if round.phase~="Voting" or time>=round.deadline then return {ok=false,message="Voting closed."} end
 local previous=round.requests[userId]
 if previous and requestId<=previous.id then
  if requestId==previous.id and Ballot.Validate(payload.picks,round.eligible) and payload.picks[1]==previous.picks[1] and round.ballots[userId] then
   return {ok=true,requestId=requestId,picks=table.clone(previous.picks)}
  end
  return {ok=false,message="That request is out of date."}
 end
 if time-(round.lastRequest[userId] or -math.huge)<cooldown then return {ok=false,message="Try again in a moment."} end
 round.lastRequest[userId]=time
 local valid,message=Ballot.Validate(payload.picks,round.eligible)
 if not valid then return {ok=false,message=message} end
 local picks=table.clone(payload.picks)
 round.ballots[userId]=picks;round.requests[userId]={id=requestId,picks=picks}
 return {ok=true,requestId=requestId,picks=table.clone(picks)}
end
function Ballot.Finalize(round: any,randomInteger: (number,number)->number,previousOpening: string?)
 if round.lineup then return round.lineup end
 if round.phase~="Voting" then return nil end
 local ids,counts={},{}
 for id in pairs(round.eligible) do table.insert(ids,id);counts[id]=0 end
 if #ids==0 then round.phase="Unavailable";return nil end
 for _,picks in pairs(round.ballots) do if Ballot.Validate(picks,round.eligible) then counts[picks[1]]+=1 end end
 table.sort(ids)
 for i=#ids,2,-1 do local j=randomInteger(1,i);ids[i],ids[j]=ids[j],ids[i] end
 local opening=ids[1]
 for _,id in ids do if counts[id]>counts[opening] then opening=id end end
 if counts[opening]==0 and #ids>1 and opening==previousOpening then
  for _,id in ids do if id~=previousOpening then opening=id;break end end
 end
 round.ranking,round.counts,round.lineup=table.clone(ids),counts,{opening}
 round.mode=if #ids>=5 then "Tournament" else "Ordinary"
 if round.mode=="Tournament" then for _,id in ids do if id~=opening and #round.lineup<5 then table.insert(round.lineup,id) end end end
 round.phase="Racing"
 return round.lineup
end
function Ballot.Advance(round: any): boolean
 if round.phase~="Racing" then return false end
 round.index+=1
 if round.index>#round.lineup then round.phase="Complete" end
 return round.phase=="Racing"
end
return Ballot
