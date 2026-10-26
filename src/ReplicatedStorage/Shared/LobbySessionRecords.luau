--!strict
local Records = {}
local function finite(value: any): boolean
 return typeof(value)=="number" and value==value and value>-math.huge and value<math.huge
end
local function name(row: any): string
 local text=if typeof(row.displayName)=="string" and row.displayName~="" then row.displayName else row.name
 return if typeof(text)=="string" and text~="" then text else "Racer"
end
function Records.New()
 return {wins={},winnerCount=0,capacity=512,paused=false,latest=nil,lastStartedAt=-1}
end
function Records.Capture(state: any,result: any): boolean
 if typeof(result)~="table" or typeof(result.raceId)~="string" or result.raceId==""
  or typeof(result.courseId)~="string" or result.courseId=="" or not finite(result.startedAt)
  or result.startedAt<=state.lastStartedAt or not finite(result.duration) or result.duration<=0
  or typeof(result.placements)~="table" then return false end
 local ranks,users={},{}
 for _,row in ipairs(result.placements) do
  if typeof(row)=="table" and row.status=="Finished" and row.official==true
   and finite(row.userId) and row.userId%1==0 and row.userId>=0
   and finite(row.placement) and row.placement%1==0 and row.placement>=1 and row.placement<=5
   and finite(row.finishTime) and row.finishTime>=0 and row.finishTime<=result.duration
   and not users[row.userId] and not ranks[row.placement] then
   users[row.userId]=true
   ranks[row.placement]={userId=row.userId,displayName=name(row),placement=row.placement,finishTime=row.finishTime}
  end
 end
 local finishers={}
 for rank=1,5 do if ranks[rank] then table.insert(finishers,ranks[rank]) end end
 local title=if typeof(result.courseDisplayName)=="string" and result.courseDisplayName~="" then result.courseDisplayName else result.courseId
 state.latest={raceId=result.raceId,courseId=result.courseId,courseName=title,finishers=finishers}
 state.lastStartedAt=result.startedAt
 local first=ranks[1]
 if first and not state.paused then
  local entry=state.wins[first.userId]
  if not entry and state.winnerCount>=state.capacity then state.paused=true;return true end
  if not entry then entry={userId=first.userId,displayName=first.displayName,wins=0};state.wins[first.userId]=entry;state.winnerCount+=1 end
  entry.wins+=1;entry.displayName=first.displayName
 end
 return true
end
function Records.Leaders(state: any)
 local rows={}
 for _,entry in pairs(state.wins) do table.insert(rows,table.clone(entry)) end
 table.sort(rows,function(a,b) return if a.wins~=b.wins then a.wins>b.wins else a.userId<b.userId end)
 while #rows>5 do table.remove(rows) end
 return rows
end
function Records.Time(seconds: number): string
 local minutes=math.floor(seconds/60)
 return string.format("%02d:%05.2f",minutes,seconds-minutes*60)
end
return Records
