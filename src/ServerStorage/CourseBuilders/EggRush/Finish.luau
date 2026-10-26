--!nonstrict
local Finish={}
local function skin(kit,name,parent,cf,scale)
 local model=assert(kit:FindFirstChild(name),"Missing admitted kit unit "..name):Clone()
 model.Name=name;scale=scale or Vector3.one
 for _,p in ipairs(model:GetDescendants())do
  if not p:IsA("BasePart")then continue end
  p.Size*=scale;p.CFrame=cf*(CFrame.new(p.CFrame.Position*scale)*p.CFrame.Rotation)
  p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Anchored=true
 end
 model.WorldPivot=cf;model:SetAttribute("ERArt",true);model.Parent=parent;return model
end
Finish.Skin=skin
local function group(parent,name)
 local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
local function coverPad(kit,p,parent)
 local cf=p.CFrame*CFrame.new(0,p.Size.Y/2-2.4,0)
 skin(kit,"ShellPad",parent,cf,Vector3.new(p.Size.X/8,1,p.Size.Z/6))
 p.Transparency=1
 local cap=p:Clone();cap.Name=p.Name.."_StudTop";cap.Size=Vector3.new(p.Size.X-.5,.12,p.Size.Z-.4)
 cap.CFrame=p.CFrame*CFrame.new(0,p.Size.Y/2+.04,0);cap.Transparency=0;cap.CanCollide=false;cap.CanTouch=false;cap.CanQuery=false
 cap:SetAttribute("ERTop",nil);cap:SetAttribute("ERRoute",nil);cap:SetAttribute("ERForwardDepth",nil)
 cap.Parent=parent
end
local function support(kit,p,parent)
 local top=p:GetAttribute("ERTop");if not top then return end
 local h=top.Y-282
 local model=skin(kit,"RockSupportStandard",parent,CFrame.new(top-Vector3.new(0,2.2,0))*p.CFrame.Rotation,Vector3.new(p.Size.X/10,h/20,p.Size.Z/6))
 model.Name=p.Name.."_Island"
end
Finish.CoverPad=coverPad
Finish.Support=support
function Finish.Shellworks(root,kit)
 assert(root:GetAttribute("EROwned")==true and not root.Decoration:FindFirstChild("ShellworksFinished"))
 local art=group(root.Decoration,"ShellworksFinished");local A=require(game.ServerStorage.CourseBuilders.EggRush.Authoring:Clone())
 local function W(x,y,z)return A.WorldPoint(Vector3.new(x,y,z))end
 for _,name in ipairs({"S3_ShellApproach","E3_CrownApproach"})do
  for _,p in ipairs(root.Obstacles[name]:GetChildren())do if p:IsA("BasePart")then coverPad(kit,p,art);support(kit,p,art)end end
 end
 for _,name in ipairs({"Shell_ForkWait","Shell_MiddleWait","Shell_ExitWait"})do
  local p=root.Obstacles[name];coverPad(kit,p,art);support(kit,p,art)
 end
 for _,m in ipairs(root.Obstacles.Mechanisms:GetChildren())do
  if m:GetAttribute("ERMechanism")~="ShellLip"then continue end
  local p=m.ShellContact;p.Transparency=1
  local hinge=m:GetPivot();local direction=(p.Position-hinge.Position)*Vector3.new(1,0,1)
  local leafFrame=CFrame.lookAt(hinge.Position,hinge.Position+direction)
  local leaf=skin(kit,"ShellLeaf",m,leafFrame,Vector3.new(p.Size.Z/10,1,p.Size.X/8))
  if m.Name:match("^Crown")then for _,piece in ipairs(leaf:GetChildren())do if piece:GetAttribute("ERMaterial")=="Mint"then piece.Color=Color3.fromRGB(182,136,216)end end end
  skin(kit,"ShellHinge",art,leafFrame*CFrame.new(0,-1,0),Vector3.new(p.Size.Z/11.6,1,1))
  local cap=p:Clone();cap.Name="SelectedStuds";cap.Size=Vector3.new(p.Size.X-.6,.12,p.Size.Z-.6);cap.Transparency=0
  cap.CFrame=p.CFrame*CFrame.new(0,.64,0);cap.CanCollide=false;cap.CanTouch=false;cap.CanQuery=false;cap:SetAttribute("ERSupport",nil);cap.Parent=m
 end
 for i,x in ipairs({-110,-86,-62,-38,-14})do
  skin(kit,"WorkshopBay",art,CFrame.new(W(x,14,-210)))
  skin(kit,"SortingShed",art,CFrame.new(W(x,14,-216)),Vector3.new(1.4,1.15,1.4))
  skin(kit,"RockSupportStandard",art,CFrame.new(W(x,13,-212)),Vector3.new(1.8,1.65,2.8))
 end
 for _,x in ipairs({-119,-8})do
  skin(kit,"NurseryArch",art,CFrame.new(W(x,13,-204)))
  skin(kit,"PipeElbow",art,CFrame.new(W(x+7,20,-211))*CFrame.Angles(0,math.pi/2,0),Vector3.one*1.4)
 end
 for _,x in ipairs({-121,-98,-72,-47,-20})do
  skin(kit,"ShrubGroup",art,CFrame.new(W(x,13,-203)),Vector3.one*.7)
 end
 for _,p in ipairs(root.Decoration.RoughSupports:GetChildren())do
  if p.Name:match("^S3_")or p.Name:match("^E3_")or p.Name:match("^Shell_")then p.Transparency=1;p.CanCollide=false end
 end
 for _,p in ipairs(root.Decoration:GetChildren())do
  if p.Name=="DistrictRoughMass"and p.Position.Z<W(0,0,-150).Z and p.Position.X>6700 and p.Position.X<6810 then p.Transparency=1;p.CanCollide=false end
 end
 root:SetAttribute("ShellworksArt",1)
 return art
end
return Finish
