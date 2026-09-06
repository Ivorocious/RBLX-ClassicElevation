--!strict

-- Temporary LocalScript in PlayerScripts during an active Studio race.
-- A setup teleport is followed by normal movement; only an actual grounded landing passes.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local p=game.Players.LocalPlayer
local c=p.Character
local h=c.Humanoid
local r=c.HumanoidRootPart
local pads={}
for _,v in ipairs(workspace.RaceCourse:GetDescendants())do
 if v:IsA("BasePart")and v:GetAttribute("RoutePad")and v:GetAttribute("SectionIndex")==9 and v:GetAttribute("Lane")==-1 then pads[v:GetAttribute("SectionStep")]=v end
end
local a,b=pads[6],pads[7]
require(p.PlayerScripts.PlayerModule):GetControls():Disable()
c:PivotTo(a.CFrame+Vector3.new(0,a.Size.Y/2+h.HipHeight+r.Size.Y/2+2,0))
r.AssemblyLinearVelocity=Vector3.zero
local settle=os.clock()+5
repeat task.wait(.03)until (h.FloorMaterial==Enum.Material.Ice and math.abs(r.AssemblyLinearVelocity.Y)<1) or os.clock()>settle
local d=(b.Position-a.Position)*Vector3.new(1,0,1); d=d.Unit
p:SetAttribute("SkylineClientJump","Running")
p:SetAttribute("SkylineClientFailure",nil)
p:SetAttribute("SkylineLandingPosition",nil)
local ok,err=pcall(function()
 assert(h.FloorMaterial==Enum.Material.Ice,"Source not grounded on ice")
 assert((r.Position-a.Position).Magnitude<8,"Wrong source position")
 local localDirection=a.CFrame:VectorToObjectSpace(d)
 local edge=math.min(a.Size.X/2/math.max(math.abs(localDirection.X),.0001),a.Size.Z/2/math.max(math.abs(localDirection.Z),.0001))
 local approachDeadline=os.clock()+2
 repeat h:Move(d);task.wait(.016)until (r.Position-a.Position):Dot(d)>=edge-.35 or os.clock()>approachDeadline
 assert(h.FloorMaterial==Enum.Material.Ice,"Ran off source before jump")
 h.Jump=true;h:ChangeState(Enum.HumanoidStateType.Jumping)
 local deadline=os.clock()+2
 local left=false
 repeat
  h:Move(d)
  task.wait(.016)
  if h.FloorMaterial==Enum.Material.Air then left=true end
  local rel=b.CFrame:PointToObjectSpace(r.Position)
  if left and math.abs(rel.X)<b.Size.X/2-.15 and math.abs(rel.Z)<b.Size.Z/2-.15 and h.FloorMaterial~=Enum.Material.Air then
   p:SetAttribute("SkylineLandingPosition",tostring(r.Position))
   return
  end
 until os.clock()>deadline
 error("No grounded landing; root="..tostring(r.Position).." floor="..h.FloorMaterial.Name)
end)
h:Move(Vector3.zero)
p:SetAttribute("SkylineClientJump",if ok then "Passed"else "Failed")
if not ok then p:SetAttribute("SkylineClientFailure",tostring(err))end
require(p.PlayerScripts.PlayerModule):GetControls():Enable()
