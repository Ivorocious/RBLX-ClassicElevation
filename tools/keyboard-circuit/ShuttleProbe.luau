--!strict
local candidate=workspace.KeyboardCircuit_P1_C05
local shuttle=candidate.H06_EarlyProof.H06_CarriageShuttle
local root=game.Players.LocalPlayer.Character.HumanoidRootPart
shared.KCShuttleC05={active=true,ride={},started=os.clock()}
task.spawn(function()
 local result=shared.KCShuttleC05
 local deadline=os.clock()+16
 while not (shuttle:GetAttribute("BoardingWindow")==true and math.abs(shuttle.Slider.CurrentPosition)<.2) and os.clock()<deadline do task.wait(.05) end
 if os.clock()>=deadline then result.active,result.ok,result.reason=false,false,"No boarding window";return end
 if not shared.KCProbe.Move("C05 H06 departure takeoff",Vector3.new(2304.9,333.2,-1200),false,2,.35) then result.active,result.ok=false,false;return end
 if not shared.KCProbe.Move("C05 H06 actual boarding jump",Vector3.new(2312,333.2,-1200),true,3,.35) then result.active,result.ok=false,false;return end
 result.boardedRootX=root.Position.X
 result.boardedPlatformX=shuttle.RideableBank:GetPivot().Position.X
 local entered=os.clock()
 while shuttle.Slider.CurrentPosition<23.7 and os.clock()-entered<10 do
  local bank=shuttle.RideableBank:GetPivot().Position
  table.insert(result.ride,{t=os.clock()-entered,x=root.Position.X,y=root.Position.Y,z=root.Position.Z,platformX=bank.X,relativeX=root.Position.X-bank.X,relativeY=root.Position.Y-bank.Y,travel=shuttle.Slider.CurrentPosition,floor=root.Parent.Humanoid.FloorMaterial.Name,state=shuttle:GetAttribute("CycleState")})
  task.wait(.1)
 end
 result.riderTravel=root.Position.X-result.boardedRootX
 result.platformTravel=shuttle.RideableBank:GetPivot().Position.X-result.boardedPlatformX
 if shuttle.Slider.CurrentPosition<23.7 then result.active,result.ok,result.reason=false,false,"No full travel";return end
 if not shared.KCProbe.Move("C05 H06 receiving takeoff",Vector3.new(2345.2,root.Position.Y,-1200),false,2,.35) then result.active,result.ok=false,false;return end
 if not shared.KCProbe.Move("C05 H06 receiving dock jump",Vector3.new(2351.5,333.2,-1200),true,3,.35) then result.active,result.ok=false,false;return end
 result.totalSeconds,result.ok,result.active=os.clock()-result.started,true,false
end)
return {started=true}
