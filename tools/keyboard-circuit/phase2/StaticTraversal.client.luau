local p=shared.KCP2TraversalProbe
local c=workspace.KeyboardCircuit_P2_C01
shared.KCP2Statics={active=true,results={}}
task.spawn(function()
 local r=shared.KCP2Statics
 local completed,failure=xpcall(function()
 for _,id in {"O01","O02","O03","O04","O05","O06","O07","O08"}do
  local u=c.Districts:FindFirstChild(id,true)
  local route
  if id=="O01"then route={"Entry","OffsetLeft","OffsetRight","Exit"}
  elseif id=="O02"then route={"Entry","MissingClusterLeft","MissingClusterRight","Exit"}
  elseif id=="O03"then route={"Entry","EscStep1","EscStep2","Exit"}
  elseif id=="O04"then route={"Entry","EnterStem","OutwardLanding","Exit"}
  elseif id=="O05"then route={"Entry","BracketLeft","BracketRight","Exit"}
  elseif id=="O06"then route={"Entry","OuterLeftHalf","OuterRightHalf","Exit"}
  elseif id=="O07"then route={"Entry","ArrowTurnRight","ArrowTurnLeft","Exit"}
  else route={"Entry","LongEnter1","LongEnter2","Exit"}end
  local contacts={}
  for _,name in route do
   local b=u:FindFirstChild(name)
   if not b or not b:IsA("Model")then
    b=nil
    for _,item in u:GetDescendants()do if item.Name==name and item:IsA("Model")then b=item;break end end
   end
   assert(b,"Expected traversal bank "..name)
   local contact=assert(b:FindFirstChild("BankContact")or b:FindFirstChild("KeyContact"),"Expected fixed contact")
   table.insert(contacts,contact)
  end
  p.Place(contacts[1])
  local ok=true
  for i=2,#contacts do
   if id=="O04"and i==3 then
    local turn=u.EnterHairpin.EnterStem.KeyContact.Position+u.EnterHairpin.EnterStem.KeyContact.CFrame.LookVector*-7
    if not p.Move("O04 Enter hairpin turn",turn,false,contacts[i-1],3,.7)then ok=false;break end
   end
   if not p.Cross(id.." "..route[i-1].." to "..route[i],contacts[i-1],contacts[i])then ok=false;break end
  end
  table.insert(r.results,{id=id,passed=ok})
 end
 end,debug.traceback)
 r.error=if completed then nil else tostring(failure)
 r.records=p.Records()
 r.active=false
end)
return {started=true,sequences=8,boundary="Staged native static-pattern traversal; no whole-race timing claim"}
