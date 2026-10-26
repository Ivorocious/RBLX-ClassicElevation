--!strict
local Patch={}
function Patch.Apply()
 assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
 local c=workspace.Course_CityRun;assert(c:GetAttribute("ReviewBuildId")=="C15_03")
 local r=c.Obstacles.C15Routes
 local function mark(parent,name,cf,size,color)
  local p=Instance.new("Part");p.Name=name;p.CFrame=cf;p.Size=size;p.Color=color;p.Material=Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=parent
  return p
 end
 local pale=Color3.fromRGB(241,219,141)
 local function rims(m)
  local p=m.Collider;local g=Instance.new("Model");g.Name="LandingOutline";g.Parent=m
  local w,d=p.Size.X,p.Size.Z
  for _,side in {-1,1} do
   mark(g,"Side"..side,p.CFrame*CFrame.new(side*(w/2-.055),.545,0),Vector3.new(.11,.04,d),pale)
   mark(g,"End"..side,p.CFrame*CFrame.new(0,.545,side*(d/2-.055)),Vector3.new(w,.04,.11),pale)
  end
  g.WorldPivot=p.CFrame
 end
 for _,section in {r.TerminalPosts,r.CornerLedges} do
  for _,m in section:GetChildren() do if m:FindFirstChild("Collider") then rims(m) end end
 end
 for _,p in r.TerminalPosts:GetDescendants() do
  if p:IsA("MeshPart") then
   if p.Name:find("__Copper__",1,true) then p.Color=Color3.fromRGB(207,180,128);p.Material=Enum.Material.SmoothPlastic
   elseif p.Name:find("__Ink__",1,true) then p.Color=Color3.fromRGB(51,74,86) end
  end
 end
 for _,m in r.CrumbleRotors:GetChildren() do
  local lane=tonumber(m.Name:match("^C15_Crumble_%d+_(%d)$"))
  if lane then
   local p=m.Collider
   for _,v in p:GetChildren() do
    if v:IsA("MeshPart") and v.Name:find("__Edge__",1,true) then
     v.Color=if lane%2==0 then Color3.fromRGB(179,145,64) else Color3.fromRGB(228,203,132)
     v.Material=Enum.Material.SmoothPlastic
    end
   end
   for _,side in {-1,1} do mark(p,"LaneEdge"..side,p.CFrame*CFrame.new(side*2.27,.545,0),Vector3.new(.12,.04,7.5),Color3.fromRGB(57,69,72)) end
  end
 end
 for _,p in r:GetDescendants() do
  if p:IsA("BasePart") and p:GetAttribute("HazardType")=="Kill" then p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromRGB(234,48,34) end
 end
 local function arrow(m,direction)
  local p=m.Collider;local g=Instance.new("Model");g.Name="TurnArrow";g.Parent=m
  local cf=CFrame.lookAt(p.Position+Vector3.new(0,.58,0),p.Position+Vector3.new(direction.X,.58,direction.Z))
  for _,side in {-1,1} do mark(g,"Chevron"..side,cf*CFrame.new(side*.27,0,0)*CFrame.Angles(0,side*math.rad(45),0),Vector3.new(.14,.05,.85),Color3.fromRGB(27,64,77)) end
  g.WorldPivot=p.CFrame
 end
 arrow(r.CornerLedges.C15_Corner_07,Vector3.xAxis)
 arrow(r.CornerLedges.C15_Corner_14,Vector3.zAxis)
 arrow(r.ZigzagBeams.C15_Zigzag_00,Vector3.xAxis)
 c:SetAttribute("ReviewBuildId","C15_04");c:SetAttribute("VisualReviewPassed",false)
 return "C15_04 landing outlines, turn cues, lane colors and shaded red hazards"
end
return Patch

