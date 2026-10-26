local c=workspace.KeyboardCircuit_P2_C01
local p=assert(shared.KCP2TraversalProbe)
shared.KCP2Rides={active=true,results={}}
task.spawn(function()
 local r=shared.KCP2Rides
 for _,id in {"H05","H06"}do
  local u
  for _,item in c.Districts:GetDescendants()do if item:GetAttribute("MechanismId")==id then u=item;break end end
  local entry,ride,exit=u.EntryBank.BankContact,u.RideableBank.BankContact,u.ExitBank.BankContact
  p.Place(entry)
  local result={id=id,samples={}}
  table.insert(r.results,result)
  local began=os.clock()
  while not u:GetAttribute("BoardingWindow") and os.clock()-began<18 do task.wait(.05)end
  result.boardingWindow=u:GetAttribute("BoardingWindow")
  if not result.boardingWindow then continue end
  result.boarded=p.Cross(id.." boarding",entry,ride)
  if not result.boarded then continue end
  local root=game.Players.LocalPlayer.Character.HumanoidRootPart
  local start=root.Position
  began=os.clock()
  while not u:GetAttribute("ExitWindow") and os.clock()-began<12 do
   table.insert(result.samples,{t=os.clock()-began,root={root.Position.X,root.Position.Y,root.Position.Z},relative={ride.CFrame:PointToObjectSpace(root.Position).X,ride.CFrame:PointToObjectSpace(root.Position).Y,ride.CFrame:PointToObjectSpace(root.Position).Z},travel=u.Slider.CurrentPosition,state=u:GetAttribute("CycleState")})
   task.wait(.05)
  end
  result.exitWindow=u:GetAttribute("ExitWindow")
  result.carriedDistance=(root.Position-start).Magnitude
  result.verticalGain=root.Position.Y-start.Y
  result.waitToExit=os.clock()-began
  if result.exitWindow then result.exited=p.Cross(id.." exit",ride,exit)end
 end
 r.records=p.Records()
 r.active=false
end)
return {started=true,boundary="Staged boarding/continuous physical carrying/exit fixture; no teleport while riding"}
