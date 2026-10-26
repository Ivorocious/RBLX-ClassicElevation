--!strict
local Patch = {}
function Patch.Apply()
 assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
 local c=workspace.Course_CityRun
 assert(c:GetAttribute("ReviewBuildId")=="C17_02")
 local folder=Instance.new("Folder");folder.Name="C17Wayfinding";folder.Parent=c.Decoration
 local amber=Color3.fromRGB(239,184,49)
 local cyan=Color3.fromRGB(28,207,218)
 local function part(parent,name,size,cf,color)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
  p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
  p:SetAttribute("C17Wayfinding",true);p.Parent=parent
  return p
 end
 local function arrow(parent,name,cf,color,scale,moving)
  for i,d in {{-.45,0,0,1.8,.22},{.2,-.32,-.7,1.05,.22},{.2,.32,.7,1.05,.22}} do
   local p=part(parent,name.."_"..i,Vector3.new(d[4]*scale,.035,d[5]*scale),cf*CFrame.new(d[1]*scale,0,d[2]*scale)*CFrame.Angles(0,d[3],0),color)
   if moving then p:SetAttribute("ConveyorTread",true) end
  end
 end
 for _,d in {{"BallA",3458,3440,82.13},{"BallB",3542,3519,82.16}} do
  arrow(folder,d[1].."_Entry",CFrame.new(d[3],d[4],-257),cyan,1.5,false)
  for _,x in {d[2]-9,d[2]+9} do
   for j=0,7 do
    part(folder,d[1].."_SwingBoundary_"..x.."_"..j,Vector3.new(.75,.035,1),CFrame.new(x,d[4],-260.5+j),j%2==0 and amber or Color3.fromRGB(30,40,51))
   end
  end
 end
 for _,m in c.Obstacles.C15Routes.ZigzagBeams:GetChildren() do
  local collider=m:FindFirstChild("Collider")
  if collider and collider:IsA("BasePart") then
   for _,x in {-3.5,3.5} do arrow(m,"BeltDirection_"..x,collider.CFrame*CFrame.new(x,.565,0)*CFrame.Angles(0,math.pi,0),amber,.8,true) end
  end
 end
 for _,m in c.Obstacles.C15Routes.TerminalPosts:GetChildren() do
  local p=m:FindFirstChild("Collider")
  if p and p:IsA("BasePart") then p:SetAttribute("C17PreviousColor",p.Color);p.Color=amber end
 end
 c:SetAttribute("ReviewBuildId","C17_03");c:SetAttribute("VisualReviewPassed",false)
 return {build="C17_03",descendants=#c:GetDescendants(),wayfindingOnly=true}
end
return Patch
