local Records=require('../src/ReplicatedStorage/Shared/LobbySessionRecords')
local count=0
local function check(ok,message) count+=1;assert(ok,message) end
local function row(id,rank,status,official,time)
 return {userId=id,placement=rank,status=status or 'Finished',official=official~=false,finishTime=time or 12,displayName='A very long racer name '..id}
end
local function race(id,at,rows)
 return {raceId=id,startedAt=at,duration=30,courseId='cove',courseDisplayName='Shipwreck Cove',placements=rows}
end
local state=Records.New()
check(#Records.Leaders(state)==0 and state.latest==nil,'empty server')
local first=race('a',100,{row(2,2),row(1,1),row(3,3,'DNF'),row(4,4,nil,false)})
check(Records.Capture(state,first),'first complete race')
check(Records.Leaders(state)[1].userId==1 and Records.Leaders(state)[1].wins==1,'only official first wins')
check(#state.latest.finishers==2 and state.latest.finishers[1].placement==1,'sorted official finishes')
check(state.latest.courseName=='Shipwreck Cove','actual latest course')
check(not Records.Capture(state,first) and state.wins[1].wins==1,'duplicate cannot count')
check(not Records.Capture(state,race('old',99,{row(8,1)})),'stale completion')
check(Records.Capture(state,race('partial',101,{row(5,2)})) and state.wins[5]==nil,'partial race never promotes second')
check(Records.Capture(state,race('invalid',102,{false,row(9,0),row(10,1,nil,true,math.huge),row(11,1,nil,true,-1),row(12,1,nil,true,31),row(13,1.5),row(0/0,1)})),'invalid rows ignored')
check(#state.latest.finishers==0,'no invented finishes')
check(Records.Capture(state,race('more',103,{row(1,1),row(1,2),row(7,3),row(8,3),row(9,6)})),'later official win')
check(state.wins[1].wins==2 and #state.latest.finishers==2,'duplicate users/ranks and sixth excluded')
local leaders=Records.Leaders(state);leaders[1].wins=99
check(state.wins[1].wins==2,'caller cannot mutate stored wins')
check(not Records.Capture(state,{raceId='running',courseId='x',startedAt=104,placements={row(1,1)}}),'not completed')
check(not Records.Capture(state,race('',104,{})),'missing race identity')
check(not Records.Capture(state,race('bad-time',math.huge,{})),'finite completion time')
check(next(Records.New().wins)==nil,'new server resets session')
state.capacity=1
check(Records.Capture(state,race('capacity',104,{row(2,1)})) and state.paused and state.winnerCount==1,'bounded honest pause')
check(Records.Capture(state,race('latest',105,{})) and state.latest.raceId=='latest','latest race continues after bounded pause')
check(Records.Time(75.12)=='01:15.12','readable finish time')
print(count..' session records checks passed')
