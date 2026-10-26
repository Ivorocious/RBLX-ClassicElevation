local candidate=workspace.KeyboardCircuit_P2_C01
local Fixture={active=false,records={}}
function Fixture.Queue(id,action)
 assert(not Fixture.active and (id=="H05" or id=="H06") and (action=="Stop" or action=="Restart"))
 local unit
 for _,v in candidate.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")==id then unit=v;break end end
 local record={id=id,action=action,active=true,began=os.clock()}
 table.insert(Fixture.records,record)
 Fixture.active=true
 task.spawn(function()
  local ok,err=xpcall(function()
   local player=game.Players:GetPlayerByUserId(86069177)
   local ray=RaycastParams.new()
   ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{unit.RideableBank},true
   local previous=unit.Slider.CurrentPosition
   repeat
    task.wait(.03)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local hit=root and workspace:Raycast(root.Position,Vector3.new(0,-7,0),ray)
    local travel=unit.Slider.CurrentPosition
    local phase=unit:GetAttribute("CycleState")
    if hit and humanoid.FloorMaterial~=Enum.Material.Air and (phase=="Rising" or phase=="Outbound")
     and travel>1.5 and travel<(unit:GetAttribute("Timing_Travel") or (if id=="H05" then 8 else 24))-1.5 and travel-previous>.02 then
     record.trigger={cycle=phase,slider=travel,delta=travel-previous,support=hit.Instance:GetFullName(),actorVelocity=tostring(unit.RideableBank.PrimaryPart.AssemblyLinearVelocity)}
     record.result=shared.KCP2LifecycleServer.OnRideTransition(86069177,id,action)
     break
    end
    previous=travel
   until os.clock()-record.began>26
   assert(record.result,"No actually moving rider seen within bound")
  end,debug.traceback)
  record.error=if ok then nil else tostring(err)
  record.active,Fixture.active=false,false
 end)
 return {queued=true,id=id,action=action}
end
shared.KCP2MovingTransitions=Fixture
return {installed=true}

