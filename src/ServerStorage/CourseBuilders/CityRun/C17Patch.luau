--!strict
local Patch = {}
function Patch.Apply(data)
 assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
 local c = workspace.Course_CityRun
 assert(c:GetAttribute("ReviewBuildId") == "C16_02")
 local archive = assert(game.ServerStorage:FindFirstChild("CityRun_C17_Archive"))
 assert(game.ServerStorage:FindFirstChild("CityRun_C17_Before"))
 for _,unit in data.units do
  local family=c.Obstacles.C15Routes[unit.section]
  local old=assert(family:FindFirstChild(unit.name))
  local m=Instance.new("Model");m.Name=unit.name
  m:SetAttribute("BlenderSource","CityRun_C17_posts.blend")
  for _,r in unit.parts do
   local p=Instance.new("Part");p.Name=r.name;p.Size=Vector3.new(unpack(r.size))
   p.CFrame=CFrame.new(unpack(r.position))*CFrame.Angles(0,r.yaw or 0,0)
   p.Color=Color3.fromRGB(unpack(r.color));p.Material=Enum.Material.SmoothPlastic
   p.Anchored=true;p.CanCollide=r.collide;p.CanTouch=r.collide;p.CanQuery=r.collide
   p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m
  end
  m.PrimaryPart=m.Collider
  old:SetAttribute("C17OriginalPath",old:GetFullName());old.Parent=archive;m.Parent=family
 end
 local portal=c.Decoration.C13Terminal.C13_RiversidePortal
 for _,name in {"C13_PortalBearing","C13_PortalCanopy","C13_PortalCanopy_Lettering_RIVERSIDE_TERMINAL"} do
  local m=assert(portal:FindFirstChild(name));m:PivotTo(m:GetPivot()+Vector3.new(0,6,0))
 end
 for _,p in portal:GetDescendants() do
  if p:IsA("BasePart") and (string.find(p.Name,"__Limestone__") or (string.find(p.Name,"PortalColumn_") and string.find(p.Name,"__PaleStone__"))) then
   p.Size+=Vector3.new(0,6,0);p.CFrame+=Vector3.new(0,3,0)
  elseif p:IsA("BasePart") and ((string.find(p.Name,"PortalPier_") and string.find(p.Name,"__PaleStone__") and not string.find(p.Name,"Window")) or (string.find(p.Name,"PortalColumn_") and string.find(p.Name,"__CopperLight__"))) then
   p.CFrame+=Vector3.new(0,6,0)
  end
 end
 for _,name in {"BallA","BallB"} do
  local m=c.Obstacles.Moving[name];m:ScaleTo(m:GetScale()*8/6.5)
 end
 c:SetAttribute("ReviewBuildId","C17_01");c:SetAttribute("VisualReviewPassed",false)
 return {build="C17_01",posts=#data.units,portalLift=6,ballRadius=8}
end
return Patch
