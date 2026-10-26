--!strict
local c=workspace.KeyboardCircuit_P1_C05
local lift=c.S02_ThockySwitchworks.H05_SpringLift
local root=game.Players.LocalPlayer.Character.HumanoidRootPart
local targets={
{label="CP1 takeoff",jump=false,p=Vector3.new(2306.318115234375,333.1310119628906,-1299.912109375)},
{label="CP1 to Esc1",jump=true,p=Vector3.new(2314.56005859375,334.8710632324219,-1300.0018310546875)},
{label="Esc1 takeoff",jump=false,p=Vector3.new(2324.636962890625,335.1310119628906,-1301.930419921875)},
{label="Esc1 to Esc2",jump=true,p=Vector3.new(2332.341064453125,337.3870544433594,-1303.0487060546875)},
{label="Esc2 takeoff",jump=false,p=Vector3.new(2341.73095703125,337.1310119628906,-1301.056884765625)},
{label="Esc2 to Esc3",jump=true,p=Vector3.new(2349.41162109375,339.3870544433594,-1299.94189453125)},
{label="Esc3 takeoff",jump=false,p=Vector3.new(2358.601806640625,339.1310119628906,-1299.9976806640625)},
{label="Esc3 to approach",jump=true,p=Vector3.new(2365.439208984375,338.8028564453125,-1300.000732421875)},
{label="Approach takeoff",jump=false,p=Vector3.new(2372.773193359375,339.1310119628906,-1297.087158203125)},
{label="Foundry entry",jump=true,p=Vector3.new(2378.331298828125,338.75762939453125,-1293.799072265625)},
{label="Drop1 north lane",jump=false,p=Vector3.new(2389.043212890625,339.1310119628906,-1293.9974365234375)},
{label="Between drops 1-2",jump=false,p=Vector3.new(2389.490966796875,339.1310119628906,-1305.4388427734375)},
{label="Drop2 south lane",jump=false,p=Vector3.new(2401.336181640625,339.1310119628906,-1305.7938232421875)},
{label="Between drops 2-3",jump=false,p=Vector3.new(2401.69140625,339.1310119628906,-1294.4923095703125)},
{label="Drop3 north lane",jump=false,p=Vector3.new(2413.53564453125,339.1310119628906,-1294.0125732421875)},
{label="Common foundry exit",jump=true,p=Vector3.new(2421.792724609375,338.9149169921875,-1296.9212646484375)},
{label="Common exit takeoff",jump=false,p=Vector3.new(2431.615966796875,339.1310119628906,-1299.8841552734375)},
{label="Lift departure",jump=true,p=Vector3.new(2440.18603515625,338.9149169921875,-1299.9984130859375)},
{label="Lift takeoff",jump=false,p=Vector3.new(2449.787353515625,339.1310119628906,-1300)},
{label="Board lift",jump=true,p=Vector3.new(2457.7275390625,339.13555908203125,-1300)},
{label="Lift center",jump=false,p=Vector3.new(2460.66015625,339.1357727050781,-1300)},
{label="Lift upper exit",jump=true,p=Vector3.new(2471.75048828125,347.0491027832031,-1300)},
{label="Upper takeoff",jump=false,p=Vector3.new(2481.748046875,347.1310119628906,-1300)},
{label="To Enter key",jump=true,p=Vector3.new(2490.16845703125,347.1396484375,-1300)},
{label="Enter turn",jump=false,p=Vector3.new(2490.952880859375,347.1809997558594,-1292.444580078125)},
{label="Enter outward takeoff",jump=false,p=Vector3.new(2490.2685546875,347.1809997558594,-1291.3135986328125)},
{label="Enter offset exit",jump=true,p=Vector3.new(2489.992431640625,346.8096618652344,-1282.3804931640625)},
{label="Offset takeoff",jump=false,p=Vector3.new(2484.822509765625,347.1310119628906,-1277.3104248046875)},
{label="Return landing",jump=true,p=Vector3.new(2478.64306640625,346.8028564453125,-1272.7388916015625)},
{label="Return takeoff",jump=false,p=Vector3.new(2469.3564453125,347.1310119628906,-1272.0325927734375)},
{label="To merge",jump=true,p=Vector3.new(2461.326416015625,347.0795593261719,-1266.2552490234375)},
{label="Merge takeoff",jump=false,p=Vector3.new(2456.24951171875,347.1310119628906,-1259.150146484375)},
{label="Merge to CP2",jump=true,p=Vector3.new(2456.01025390625,346.9015197753906,-1251.8096923828125)}
}
shared.KCNormalC05={active=true,ride={},started=os.clock()}
task.spawn(function()
 local result=shared.KCNormalC05
 for _,target in targets do
  result.stage=target.label
  if target.label=="Lift upper exit" then
   local entered=os.clock();local startY=root.Position.Y
   while lift.Slider.CurrentPosition<7.8 and os.clock()-entered<8 do
    table.insert(result.ride,{t=os.clock()-entered,y=root.Position.Y,travel=lift.Slider.CurrentPosition,relativeY=root.Position.Y-lift.RideableBank:GetPivot().Position.Y,state=lift:GetAttribute("CycleState")})
    task.wait(.1)
   end
   result.boardToHigh=os.clock()-entered;result.carriedY=root.Position.Y-startY
   if not shared.KCProbe.Move("C05 Lift upper takeoff",Vector3.new(2465.8,root.Position.Y,-1300),false,2,.35) then result.ok,result.active=false,false;return end
  end
  if not shared.KCProbe.Move("C05 "..target.label,target.p,target.jump,3,.5) then result.ok,result.active=false,false;return end
 end
 result.totalSeconds,result.ok,result.active=os.clock()-result.started,true,false
 shared.KCNormalRecords=shared.KCProbe.Records()
end)
return {started=true}

