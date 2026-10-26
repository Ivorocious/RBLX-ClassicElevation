--!strict
local Conveyors = {}
function Conveyors.Create(course: Model)
 local records = {}
 for _,part in course:GetDescendants() do
  if not part:IsA("BasePart") or part:GetAttribute("ConveyorSpeed") == nil then continue end
  local marks={}
  for _,p in part.Parent:GetChildren() do
   if p:IsA("BasePart") and p:GetAttribute("ConveyorTread") then
    table.insert(marks,{part=p,relative=part.CFrame:ToObjectSpace(p.CFrame)})
   end
  end
  table.insert(records,{part=part,marks=marks})
 end
 local controller={}
 function controller.Step(elapsed: number)
  for _,r in records do
   local p=r.part;local speed=p:GetAttribute("ConveyorSpeed") or 0
   local cframe=p.CFrame
   -- Anchored surface velocity carries grounded avatars without moving the beam.
   local velocity=cframe.RightVector*speed
   if p.AssemblyLinearVelocity~=velocity then p.AssemblyLinearVelocity=velocity end
   local span=p.Size.X-1
   for _,mark in r.marks do
    local relative=mark.relative
    local x=(relative.X+span/2+elapsed*speed)%span-span/2
    mark.part.CFrame=cframe*CFrame.new(x,relative.Y,relative.Z)*relative.Rotation
   end
  end
 end
 function controller.Stop()
  for _,r in records do
   r.part.AssemblyLinearVelocity=Vector3.zero
   for _,mark in r.marks do mark.part.CFrame=r.part.CFrame*mark.relative end
  end
 end
 return controller
end
return Conveyors
