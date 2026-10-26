local P = require("../src/StarterPlayer/StarterPlayerScripts/Controllers/LobbyPresentation")
local checks = 0
local function check(value, message) assert(value,message); checks+=1 end
for _, status in {"Lobby","Queued"} do
	local result = P.Race("Intermission",status,24,false,true)
	check(result.visible,"intermission is visible in lobby")
	check(result.queued == (status=="Queued"),"only a queued player is promised entry")
	check(result.timer=="00:24","server time is formatted")
	check(result.canEdit == (status=="Lobby"),"editor follows supported lobby status")
	check(not result.canChoose,"intermission has no late run action")
end
for _, status in {"Racing","LateRacing","GhostRacing","Spectating","Finished","DNF"} do
	check(not P.Race("Racing",status,75,false,true).visible,"lobby UI yields to gameplay")
end
for _, state in {"WaitingForPlayers","Intermission","Countdown","Racing","RaceEnding","Results","Resetting"} do
	local result = P.Race(state,"Lobby",10,false,false)
	check(not result.visible and not result.canChoose and not result.canEdit,"arrival hides lobby actions")
end
local late = P.Race("Racing","Lobby",80,false,true)
check(late.visible and late.canChoose and late.timer=="01:20","late join uses supported race state")
check(not P.Race("Countdown","Queued",3,false,true).visible,"countdown owns the screen")
check(P.Race("Resetting","Lobby",3,false,true).timer=="Soon","reset does not promise a start time")
check(P.Race("WaitingForPlayers","Lobby",nil,true,true).status=="Studio preview","studio hold is labelled")
check(P.Balance(nil)=="—","missing balance is unknown")
check(P.Balance(0)=="0","a loaded zero is real")
check(P.Balance(12450)=="12,450","full balance is readable")
check(P.Balance(-1)=="—" and P.Balance(math.huge)=="—" and P.Balance(0/0)=="—","invalid balance is unknown")
check(P.Timer(nil)=="--:--" and P.Timer(math.huge)=="--:--" and P.Timer(0/0)=="--:--","invalid time is unknown")
local phase=P.Phase("Intermission",18,24,false)
check(phase.label=="INTERMISSION" and phase.time=="00:18" and phase.fraction==.75,"phase uses server remaining time and duration")
check(P.Phase("Intermission",30,24,false).fraction==1,"progress stays within its track")
check(P.Phase("Intermission",0,24,false).fraction==0,"completed phase has no remaining fill")
check(P.Phase("Intermission",18,nil,false).fraction==nil,"missing duration never reuses a denominator")
for _,invalid in {0,-1,math.huge,-math.huge,0/0} do
 check(P.Duration(invalid)==nil,"invalid duration remains unknown")
 check(P.Phase("Intermission",18,invalid,false).fraction==nil,"invalid duration has no progress")
end
for _,invalid in {math.huge,-math.huge,0/0} do
 local unknown=P.Phase("Intermission",invalid,24,false)
 check(not unknown.timed and unknown.fraction==nil,"invalid remaining time is not presented as a countdown")
end
phase=P.Phase("WaitingForPlayers",nil,nil,true)
check(phase.label=="LOBBY OPEN" and phase.time=="Explore" and phase.fraction==nil,"held lobby is truthful")
phase=P.Phase("Racing",nil,540,false)
check(phase.label=="RACING" and phase.time=="In progress" and phase.fraction==nil,"unlimited inspection does not invent a countdown")
check(P.Phase("Results",10,30,false).fraction==nil,"untimed phase does not show artificial progress")
print("Passed " .. checks .. " lobby presentation checks")
