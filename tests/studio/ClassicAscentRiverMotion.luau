--!strict

-- Call Run from a temporary server Script during an active Studio race.
local Check = {}

function Check.Run()
 assert(game:GetService("RunService"):IsStudio(), "Studio only")
local report=Instance.new("Folder")
report.Name="RiverRuntimeCycles"; report.Parent=game.ServerStorage
report:SetAttribute("Status","Observing")
local ok,err=pcall(function()
 local race=require(game.ServerScriptService.Services.RaceService)
 assert(race.IsRaceActive(),"Active race required")
 local m=workspace.RaceCourse
 assert(m:GetAttribute("RiverFinishRevision")==1,"Wrong runtime course")
 assert(game.Players:GetPlayers()[1].CameraMaxZoomDistance==30,"Wrong player zoom")
 local logs={}
 for _,l in ipairs(m:GetDescendants())do
  if l:IsA("BasePart")and l:GetAttribute("MotionKind")=="MovingLog" then table.insert(logs,{part=l,phase=l:GetAttribute("MotionPhase"),position=l.Position})end
 end
 assert(#logs==100,"Expected 100 moving logs")
 local starts,resets,bad=0,0,0
 local deadline=os.clock()+72
 repeat
  for _,r in ipairs(logs)do
   local l=r.part
   local phase=l:GetAttribute("MotionPhase")
   local mid=l:GetAttribute("MotionStart"):Lerp(l:GetAttribute("MotionEnd"),.5)
   if phase~=r.phase then
    if phase=="Travelling"then
     starts+=1
     if math.abs(mid:PointToObjectSpace(l.Position).X)<75 then bad+=1 end
    elseif r.phase=="Travelling"and phase=="Cooldown"then
     resets+=1
     if math.abs(mid:PointToObjectSpace(r.position).X)<75 then bad+=1 end
    end
    r.phase=phase
   end
   r.position=l.Position
  end
  task.wait(.03)
 until os.clock()>deadline
 report:SetAttribute("Starts",starts);report:SetAttribute("Resets",resets);report:SetAttribute("VisibleTransitions",bad)
 assert(starts>=100 and resets>=100,"Insufficient cycles")
 assert(bad==0,"Transition entered visible river")
end)
report:SetAttribute("Status",if ok then "Passed"else "Failed")
if not ok then report:SetAttribute("Failure",tostring(err))end
 return report:GetAttributes()
end

return Check
