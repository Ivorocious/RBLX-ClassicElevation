--!strict
local Patch={}
function Patch.Apply(data)
 assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
 local c=workspace.Course_CityRun;assert(c:GetAttribute("ReviewBuildId")=="C17_01")
 local archive=assert(game.ServerStorage.CityRun_C17_Archive)
 local prepared={}
 for _,u in data.units do
  local old=assert(c.Obstacles.Moving:FindFirstChild(u.name))
  local m=Instance.new("Model");m.Name=u.name;m:SetAttribute("BlenderSource","CityRun_C17_cars.blend")
  m:SetAttribute("CarStyle",u.displayName)
  local pivot=old:GetPivot()
  for _,r in u.parts do
   local p=Instance.new(r.robloxClass or "Part");p.Name=r.name
   p.Size=Vector3.new(unpack(r.nativeSize or r.size))
   local rotation=r.nativeRotation or r.rotation
   p.CFrame=pivot*CFrame.new(unpack(r.position))*CFrame.Angles(math.rad(rotation[1]),math.rad(rotation[2]),math.rad(rotation[3]))
   if r.shape=="Cylinder" then p.Shape=Enum.PartType.Cylinder end
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
   p.Color=Color3.fromRGB(unpack(r.color));p.Material=Enum.Material.SmoothPlastic
   p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m
  end
  m.WorldPivot=pivot;table.insert(prepared,{model=m,old=old})
 end
 for _,r in prepared do r.old:SetAttribute("C17OriginalPath",r.old:GetFullName());r.old.Parent=archive;r.model.Parent=c.Obstacles.Moving end
 return {cars=#prepared,build=data.build}
end
return Patch
