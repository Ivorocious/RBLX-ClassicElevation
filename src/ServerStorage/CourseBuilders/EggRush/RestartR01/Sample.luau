--!nonstrict
local Sample = {}
local V = Vector3.new
local C = {cream=Color3.fromRGB(255,240,202),coral=Color3.fromRGB(246,125,96),mint=Color3.fromRGB(104,205,176),lilac=Color3.fromRGB(182,136,216),honey=Color3.fromRGB(185,123,67),red=Color3.fromRGB(255,20,35)}
local function group(parent,name,class)
 local value=Instance.new(class or "Folder");value.Name=name;value.Parent=parent;return value
end
local function part(parent,name,size,cf,color,collide)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or C.cream
 p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=p.CanCollide;p.CanQuery=p.CanCollide
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function skin(kit,name,parent,cf,scale)
 local m=assert(kit:FindFirstChild(name),"Missing R01 kit unit "..name):Clone();scale=scale or Vector3.one
 for _,p in m:GetDescendants()do if p:IsA("BasePart")then
  p.Size*=scale;p.CFrame=cf*CFrame.new(p.Position*scale)*p.CFrame.Rotation
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 end end
 m.WorldPivot=cf;m:SetAttribute("ERArt",true);m.Parent=parent;return m
end
local function reference(parent,name,value)
 local ref=Instance.new("ObjectValue");ref.Name=name;ref.Value=value;ref.Parent=parent
end
local function sign(parent,text,cf,color)
 local face=part(parent,"Choice_"..text,V(8,2,.35),cf,color,false)
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(640,160);gui.Parent=face
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.TextColor3=C.cream;label.Text=text;label.Parent=gui
end
function Sample.Build(root,kit,config)
 assert(root:GetAttribute("CandidateId")=="ER_P1_R01" and root.Obstacles:FindFirstChild("CP2_Pocket"))
 local origin=config.origin
 local function W(x,y,z)return origin+V(x,y,z)end
 local art=group(root.Decoration,"Shellworks_R01")
 local approaches=group(root.Obstacles,"S3_ShellApproach")
 local approachRefs=group(root.Routes,"S3_ShellApproach")
 local expertRefs=group(root.Routes,"E3_CrownApproach")
 local normalRefs=group(root.Routes,"R01_NormalShells")
 local crownRefs=group(root.Routes,"E3_MovingCrown")
 local function studs(parent,cf,width,depth)
  local p=part(parent,"SelectedStuds",V(math.min(width-1,4),.08,math.min(depth-.3,2)),cf*CFrame.new(0,.04,0),C.cream,false)
  p.TopSurface=Enum.SurfaceType.Studs
 end
 local function fixed(parent,name,pos,heading,width,depth,route)
  local cf=CFrame.lookAt(pos,pos+heading)
  local p=part(parent,name,V(width,.6,depth),cf*CFrame.new(0,-.3,0),C.cream,true)
  p.Transparency=1;p:SetAttribute("ERTop",pos);p:SetAttribute("ERRoute",route);p:SetAttribute("ERForwardDepth",depth)
  -- The fragment's central eight-stud top is solid for its full depth.
  skin(kit,"ShellFragment",art,cf,V(width/8,1,depth/4.5));studs(art,cf,width,depth)
  for _,side in {-1,1}do
   local shoulder=part(parent,name.."_Shoulder"..side,V(width/8,.6,depth*3.5/4.5),cf*CFrame.new(side*width*9/16,-.3,0),C.cream,true)
   shoulder.Transparency=1;shoulder:SetAttribute("ERTop",pos);shoulder:SetAttribute("ERRoute",route)
  end
  return p
 end
 local points={W(-84,12,-108),W(-95,13,-117),W(-82,14,-119),W(-72,15,-113)}
 local approachParts={}
 for i,p in points do
  local following=points[i+1]or W(-58.5,16,-109.5)
  local previous=points[i-1]or root.Obstacles.CP2_Pocket:GetAttribute("ERTop")
  local incoming=(p-previous)*V(1,0,1);local outgoing=(following-p)*V(1,0,1)
  local pad=fixed(approaches,string.format("S3_ShellApproach_%03d",i),p,incoming.Unit+outgoing.Unit,8,4.5,"Normal")
  reference(approachRefs,string.format("%03d",i),pad);reference(expertRefs,string.format("%03d",i),pad)
  table.insert(approachParts,pad)
 end
 local fork=fixed(root.Obstacles,"Shell_ForkWait",W(-58.5,16,-109.5),V(1,0,0),22,8,"Safe")
 local middle=fixed(root.Obstacles,"Shell_MiddleWait",W(-26,17,-122),V(1,0,0),18,6,"Safe")
 local exit=fixed(root.Obstacles,"Shell_ExitWait",W(5.25,20,-97.5),V(1,0,0),20,3.5,"Safe")
 reference(expertRefs,"005",fork)
 local a,b=approachParts[2],approachParts[3]
 local pa,pb=a:GetAttribute("ERTop"),b:GetAttribute("ERTop");local delta=(pb-pa)*V(1,0,1)
 local hazard=part(root.Obstacles,"Shellworks_RedHop",V(5.5,1.2,1.2),CFrame.lookAt((pa+pb)/2+V(0,.5,0),(pa+pb)/2+V(0,.5,0)+delta),C.red,false)
 hazard.Material=Enum.Material.Neon;hazard.CanQuery=true;hazard.CanTouch=true;hazard:SetAttribute("ERLethal",true)
 hazard:SetAttribute("ERPadName",a.Name);hazard:SetAttribute("ERNextPadName",b.Name)
 local function bank(name,pos,width,depth)
  local support=skin(kit,"RockSupportLow",art,CFrame.new(pos),V(width/10,1,depth/6));support.Name=name
 end
 -- Banks sit below separate landings; none supplies a walkable bridge across a gap.
 bank("ApproachShoulder",W(-84,9.6,-108),12,8)
 bank("ApproachTurnRock",W(-95,10.6,-117),10,6)
 bank("ForkBank",W(-58.5,13.6,-109.5),25,10)
 bank("MiddleBank",W(-26,14.6,-122),21,8)
 bank("ExitBank",W(5.25,17.6,-97.5),23,6)
 for i,p in approachParts do
  if i==3 or i==4 then bank("FragmentRock"..i,p:GetAttribute("ERTop")-V(0,2.4,0),9,5.5)end
 end
 local function shell(name,pos,heading,expert,phase)
  local width=if expert then 8 else 12
  local rootPos=pos-heading*6.25
  local frame=CFrame.lookAt(rootPos,rootPos+heading)
  local m=group(root.Obstacles.Mechanisms,name,"Model");m.WorldPivot=frame
  for k,value in {ERMechanism="ShellLip",ClosedSeconds=1.8,WarningSeconds=1.2,MoveSeconds=1.2,OpenSeconds=8,ClosingWarningSeconds=1.4,ClosedAngleDegrees=90,RotationAxis=V(1,0,0),PhaseSeconds=phase}do m:SetAttribute(k,value)end
  local contact=part(m,"ShellContact",V(width-2,2.5,3.5),frame*CFrame.new(0,-1.25,-6.25),C.cream,true)
  contact.Transparency=1;contact:SetAttribute("ERSupport",true)
  local function shellSupport(name,size,offset)
   local p=part(m,name,size,frame*CFrame.new(offset),C.cream,true)
   p.Transparency=1;p:SetAttribute("ERSupport",true)
  end
  shellSupport("CupFloor",V(width-2,.4,7),V(0,-2.7,-4))
  shellSupport("LowerStep",V(width-4,.5,6),V(0,-3.15,-4))
  shellSupport("BackRim",V(width-2,2.5,.8),V(0,-1.25,-.4))
  for _,side in {-1,1}do
   shellSupport("SideRim"..side,V(1,2.5,6),V(side*(width/2-.5),-1.25,-4))
   shellSupport("RearStep"..side,V(1,2.5,1.4),V(side*(width/2-1.5),-1.25,-.7))
  end
  skin(kit,if expert then"ShellLeafCrown"else"ShellLeafWide",m,frame)
  studs(m,frame*CFrame.new(0,0,-6.25),width-2,3.5)
  skin(kit,if expert then"ShellHingeCrown"else"ShellHingeWide",art,frame)
  local footing=skin(kit,"BareRock",art,frame*CFrame.new(0,-1.55,1.2),V((width+8)/7,.3,2.4/5.4))
  footing.Name=name.."_Footing"
  local base=skin(kit,"BareRock",art,frame*CFrame.new(0,-3.65,3),V((width+8)/7,.6,6/5.4))
  base.Name=name.."_RockBase"
  local lampPos=frame*V(width/2+1.3,1.7,.4)
  part(art,name.."_LampMount",V(.5,.85,.5),CFrame.new(lampPos-V(0,.425,0)),C.coral,false)
  local beacon=skin(kit,"WarningBeacon",art,CFrame.new(lampPos))
  local lamp
  for _,p in beacon:GetDescendants()do if p:IsA("BasePart")and p:GetAttribute("ERMaterial")=="Amber"then lamp=p end end
  assert(lamp,"Beacon needs its amber lens")
  local sound=Instance.new("Sound");sound.Name="WarningSound";sound.SoundId="rbxasset://sounds/electronicpingshort.wav"
  sound.Volume=.55;sound.RollOffMaxDistance=48;sound.Parent=lamp
  reference(m,"Warning",lamp)
  return contact
 end
 local normal={
  {W(-46,16,-112),0},{W(-36.5,17,-121),0},
  {W(-15.5,18,-114),1},{W(-6,19,-105),1},
 }
 for i,data in normal do
  local p=shell("ShellLip"..i,data[1],V(if i%2==1 then 1 else -1,0,0),false,data[2])
  reference(normalRefs,string.format("%03d",i),p)
 end
 for i,data in {W(-46,17,-94),W(-35,18,-91),W(-24,19,-94),W(-13,20,-93),W(-4,20,-95)}do
  local p=shell("CrownLip"..i,data,V(if i==1 then 1 else -1,0,0),true,14.15)
  reference(crownRefs,string.format("%03d",i),p)
 end
 sign(root.RouteMarkers,"NORMAL  >  OUTER",CFrame.lookAt(W(-64,20,-117),W(-90,20,-117)),C.honey)
 sign(root.RouteMarkers,"EXPERT  >  INNER LIP",CFrame.lookAt(W(-64,20,-101),W(-90,20,-101)),C.lilac)
 local workshopBase=W(-59,9,-146)
 bank("WorkshopRock",W(-63,9,-146),39,17)
 bank("ArchRock",W(-85,10.5,-147),14,8)
 part(art,"WorkshopMass",V(16,11.6,6),CFrame.new(workshopBase+V(0,5.8,-1.5)),C.cream,false)
 skin(kit,"WorkshopBay",art,CFrame.new(workshopBase+V(0,0,2)))
 skin(kit,"SortingShed",art,CFrame.new(workshopBase+V(0,4,-2)),V(1.5,1,1.1))
 skin(kit,"MintPipeArch",art,CFrame.new(W(-85,10.5,-147)))
 skin(kit,"PipeElbow",art,CFrame.new(W(-79,13.5,-147))*CFrame.Angles(0,math.pi/2,0))
 skin(kit,"PipeStraight",art,CFrame.new(W(-67,13.5,-147))*CFrame.Angles(0,math.pi/2,0),V(1,1,1.2))
 skin(kit,"ShrubGroup",art,CFrame.new(W(-72,9,-139)),Vector3.one*.65)
 skin(kit,"ShrubGroup",art,CFrame.new(W(-47,9,-140)),Vector3.one*.65)
 skin(kit,"NestRing",art,CFrame.new(W(-47,9,-146)),Vector3.one*.45)
 skin(kit,"EggDisplay",art,CFrame.new(W(-47,9,-146)))
 root:SetAttribute("ShellworksArt","R01")
 root:SetAttribute("SampleRevision",3)
 root:SetAttribute("FullBodyContacts",true)
 root:SetAttribute("Phase1Scope","Reusable kit + rough whole route + finished Shellworks sample; owner approval pending")
 return art
end
function Sample.Points(course,line)
 local out={};local o=course.Obstacles
 local function add(p,kind)table.insert(out,{part=p,waitKind=kind})end
 add(o.CP2_Pocket)
 local refs=course.Routes.S3_ShellApproach:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
 for _,ref in refs do add(ref.Value)end
 add(o.Shell_ForkWait)
 if line=="Expert"then
  for i=1,5 do add(o.Mechanisms["CrownLip"..i].ShellContact,"Shell")end
 else
  for i=1,4 do
   add(o.Mechanisms["ShellLip"..i].ShellContact,"Shell")
   if i==2 then add(o.Shell_MiddleWait)end
  end
 end
 add(o.Shell_ExitWait)
 return out
end
return Sample
