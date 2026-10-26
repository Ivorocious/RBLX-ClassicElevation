local Run=game:GetService("RunService")
local p=game.Players:GetPlayers()[1];local c=p.Character;local h=c.Humanoid;local r=c.HumanoidRootPart
assert(h.WalkSpeed==16 and not h.UseJumpPower and math.abs(h.JumpHeight-7.2)<.01,"Movement settings changed")
local knot=workspace.RaceCourse.Decoration.HeartwoodHazards.HeartKnot
local deadline=os.clock()+8
repeat Run.Heartbeat:Wait() until knot:GetAttribute("State")~="Travel" or os.clock()>deadline
repeat Run.Heartbeat:Wait() until knot:GetAttribute("State")=="Travel" or os.clock()>deadline
assert(knot:GetAttribute("State")=="Travel","No active pulse transition")
local recoveryBefore=c:GetAttribute("RecoveryUntil") or 0;local target=Vector3.new(4252,148,-50)
local began=os.clock();local jumped=false;local maxY=r.Position.Y;local records={};local lastRecord=-1;local jumpPosition;local groundedTakeoff
repeat
 local t=os.clock()-began;local d=(target-r.Position)*Vector3.new(1,0,1)
 h:Move(if d.Magnitude>.6 then d.Unit else Vector3.zero,false)
 if not jumped and t>=.3 then
  groundedTakeoff=h.FloorMaterial~=Enum.Material.Air;jumpPosition={r.Position.X-4200,r.Position.Y-80,r.Position.Z}
  h.Jump=true;h:ChangeState(Enum.HumanoidStateType.Jumping);jumped=true
 end
 maxY=math.max(maxY,r.Position.Y)
 if t-lastRecord>=.1 then lastRecord=t;table.insert(records,{t=t,phase=knot:GetAttribute("State"),state=tostring(h:GetState()),p={r.Position.X-4200,r.Position.Y-80,r.Position.Z}}) end
 Run.Heartbeat:Wait()
until os.clock()-began>=1.9
h:Move(Vector3.zero);h.Jump=false
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.RaceCourse};params.RespectCanCollide=true
local hit=workspace:Raycast(r.Position,Vector3.new(0,-5,0),params)
local grounded=h.FloorMaterial~=Enum.Material.Air
local distance=((target-r.Position)*Vector3.new(1,0,1)).Magnitude
local recoveryAfter=c:GetAttribute("RecoveryUntil") or 0
return {passed=jumped and groundedTakeoff and grounded and distance<1 and recoveryAfter==recoveryBefore and h.Health==100,
 groundedTakeoff=groundedTakeoff,jumped=jumped,grounded=grounded,distance=distance,recoveryBefore=recoveryBefore,recoveryAfter=recoveryAfter,
 health=h.Health,support=hit and hit.Instance:GetFullName(),jumpPosition=jumpPosition,maxRelativeY=maxY-80,records=records,
 scope="One solo server-driven jump after .3 second approach in active Travel; initial placement before trial; not human robustness"}
