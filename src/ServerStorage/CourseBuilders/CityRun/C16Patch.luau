--!strict
local Patch={}
function Patch.Apply(data)
 assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
 local c=workspace.Course_CityRun
 assert(c:GetAttribute("ReviewBuildId")=="C15_04")
 local archive=assert(game.ServerStorage:FindFirstChild("CityRun_C16_Archive"))
 assert(game.ServerStorage:FindFirstChild("CityRun_C16_Before"))
 local routes=c.Obstacles.C15Routes
 local prepared={}
 for _,unit in data.units do
  local old=assert(routes[unit.section]:FindFirstChild(unit.name),unit.name)
  local m=Instance.new("Model");m.Name=unit.name
  m:SetAttribute("BlenderSource","CityRun_C16_precision.blend")
  for _,r in unit.parts do
   local p=Instance.new("Part");p.Name=r.name
   p.Size=Vector3.new(unpack(r.size));p.CFrame=CFrame.new(unpack(r.position))*CFrame.Angles(0,r.yaw or 0,0)
   p.Color=Color3.fromRGB(unpack(r.color));p.Material=Enum.Material.SmoothPlastic
   p.Anchored=true;p.CanCollide=r.collide;p.CanTouch=r.collide;p.CanQuery=r.collide;p.CastShadow=r.name=="Stem"
   p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m
   if r.tread then p:SetAttribute("ConveyorTread",true) end
   if r.name=="Collider" and unit.speed then p:SetAttribute("ConveyorSpeed",unit.speed) end
  end
  m.PrimaryPart=m:FindFirstChild("Collider") or m:FindFirstChildWhichIsA("BasePart")
  table.insert(prepared,{model=m,old=old,section=unit.section})
 end
 for _,entry in prepared do
  entry.old:SetAttribute("C16OriginalPath",entry.old:GetFullName());entry.old.Parent=archive
  for _,suffix in {"_Stem","_Brackets"} do
   local support=routes[entry.section]:FindFirstChild(entry.model.Name..suffix)
   if support then support:SetAttribute("C16OriginalPath",support:GetFullName());support.Parent=archive end
  end
  entry.model.Parent=routes[entry.section]
 end
 local hazard=routes.SwingingBars.C15_Swing_StationMain_04_02:FindFirstChildWhichIsA("BasePart")
 hazard.Size=Vector3.new(7.3,hazard.Size.Y,hazard.Size.Z)
 local bridge=c.Decoration.CourtBridgeFrames:FindFirstChild("CourtBridgeFrames__Cream__00")
 bridge.CanCollide=false
 c:SetAttribute("ReviewBuildId","C16_02");c:SetAttribute("VisualReviewPassed",false)
 return {build="C16_02",replaced=#prepared,blenderTriangles=data.triangles}
end
return Patch
