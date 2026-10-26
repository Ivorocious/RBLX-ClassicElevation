local fs, luau, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local prefix="tools/keyboard-circuit/phase2/work-i07/"
local current=luau.load(fs.readFile(prefix.."sources/Motion.luau"))()
local before=luau.load(fs.readFile("tools/keyboard-circuit/phase2/history/I07_03/sources/Motion.luau"))()
local counts={}
for _,kind in {"Fallaway","Foundry","Shuttle","Sweep","Domino","Shift"} do
 local config=current.Tuning(kind)
 local old=before.Tuning(kind)
 assert(config.Warning==old.Warning or kind=="Domino")
 assert(kind~="Domino" or config.ReturnWarning==old.ReturnWarning)
 assert(not config.CrossingAllowance or config.CrossingAllowance==old.CrossingAllowance)
 if kind=="Shuttle" then assert(config.Speed*config.Outbound==config.Travel and config.Period==2*config.Outbound+config.BoardDwell+config.ExitDwell and config.BoardDwell==old.BoardDwell and config.ExitDwell==old.ExitDwell) end
 if kind=="Shift" then assert(config.Open+config.Warning+config.Retract+config.Closed+config.Return<=config.Period+.00001) end
 if kind=="Sweep" then assert(config.Rest+config.Warning+config.Outbound+config.FarDwell+config.Return<=config.Period+.00001) end
 if kind=="Fallaway" then assert(config.Open+config.Warning+config.Drop+config.Down+config.Return+2*config.RowDelay<config.Period) end
 local samples, admissions=0,0
 local fn=current[kind]
 for index=1,(if kind=="Fallaway" then 2 elseif kind=="Foundry" or kind=="Domino" then 3 elseif kind=="Shift" then 2 else 1) do
  for step=0,1200 do
   local elapsed=step*.025
   local state
   if kind=="Fallaway" then state=fn(elapsed,index,1,config)
   elseif kind=="Foundry" or kind=="Domino" or kind=="Shift" then state=fn(elapsed,index,config)
   else state=fn(elapsed,config) end
   assert(state.alpha>=-.000001 and state.alpha<=1.000001)
   if state.admission then
    admissions+=1
    if kind=="Fallaway" or kind=="Shift" then
     local offset=(index-1)*(if kind=="Fallaway" then config.LaneOffset else config.Offset)
     if elapsed>=offset then assert(config.Open-(elapsed-offset)%config.Period>=config.CrossingAllowance-.00001) end
    end
   end
   samples+=1
  end
 end
 assert(admissions>0)
 counts[kind]={samples=samples,admissions=admissions,tuning=config}
end
local clock=current.NewClock(0)
local _,elapsed,advanced=current.StepClock(clock,1)
assert(not advanced and elapsed==0 and clock.pausedStalls==1)
assert(current.Defaults.MaxSweepSteps==before.Defaults.MaxSweepSteps and current.Defaults.MaxQueriesPerFrame==before.Defaults.MaxQueriesPerFrame)
local report={revision="KC_P2_I07_06",passed=true,checks=counts,lift=current.Tuning("Lift"),boundary="Pure motion boundaries and retained safety warnings/boarding/crossing allowances. Actual carrying/contact/progression and pacing require separate native full-race receipts."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/P2-I07-motion-boundaries-06.json",serde.encode("json",report,true))
local totalSamples=0
for _,info in counts do totalSamples+=info.samples end
print(serde.encode("json",{passed=true,kinds=6,samples=totalSamples}))
