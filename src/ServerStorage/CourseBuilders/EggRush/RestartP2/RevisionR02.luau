--!nonstrict
local Revision = {}
local Layout = require(script.Parent.LayoutR02)
local HazardKit = require(script.Parent.HazardKit)
local V = Vector3.new
local C = {
 cream=Color3.fromRGB(255,240,202), violet=Color3.fromRGB(173,117,207),
 honey=Color3.fromRGB(185,123,67), coral=Color3.fromRGB(246,125,96),
 mint=Color3.fromRGB(104,205,176), rock=Color3.fromRGB(128,132,143),
 red=Color3.fromRGB(255,20,35), iron=Color3.fromRGB(100,106,120),
}
Revision.Candidate = "ER_P2_R02_C07"
Revision.Origin = V(1544,311,-1134)

local function folder(parent,name,class)
 local object=Instance.new(class or "Folder")
 object.Name,object.Parent=name,parent
 return object
end
local function part(parent,name,size,frame,color,collide)
 local object=Instance.new("Part")
 object.Name,object.Size,object.CFrame=name,size,frame
 object.Color=color
 object.Anchored,object.CanCollide,object.CanTouch,object.CanQuery=true,collide,collide,collide
 object.TopSurface,object.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 object.Parent=parent
 return object
end
local function skin(kit,name,parent,frame,scale)
 scale=scale or Vector3.one
 if typeof(scale)=="number" then scale=Vector3.one*scale end
 local model=assert(kit:FindFirstChild(name),"Missing inspected kit unit "..name):Clone()
 local pivot=model:GetPivot()
 for _,object in ipairs(model:GetDescendants()) do
  if object:IsA("BasePart") then
   local localFrame=pivot:ToObjectSpace(object.CFrame)
   object.Size*=scale
   object.CFrame=frame*CFrame.new(localFrame.Position*scale)*localFrame.Rotation
   object.Anchored,object.CanCollide,object.CanTouch,object.CanQuery=true,false,false,false
  end
 end
 model.WorldPivot=frame
 model:SetAttribute("ERArt",true)
 model.Parent=parent
 return model
end

function Revision.Apply(root,kit)
 assert(root:GetAttribute("CandidateId")=="ER_P2_R01_C05","Revise the preserved C05 foundation")
 local pivot=root:GetPivot()
 local o,mechanisms=root.Obstacles,root.Obstacles.Mechanisms
 local retired=Instance.new("Folder")
 retired.Name="C05_ReplacedGeometry"
 local function retire(object) if object then object.Parent=retired end end
 for _,object in ipairs(root.Routes:GetChildren()) do retire(object) end
 for _,object in ipairs(root.Decoration:GetChildren()) do retire(object) end
 for _,object in ipairs(root.RouteMarkers:GetChildren()) do
  if object.Name:find("Choice",1,true) then retire(object) end
 end
 for _,object in ipairs(o:GetChildren()) do
  if object~=mechanisms and not object.Name:match("^CP%d_Pocket$") then retire(object) end
 end
 for _,name in ipairs({"EggBand1","EggBand2","GuardianTail","SidewaysTray"}) do retire(mechanisms:FindFirstChild(name)) end
 local art=folder(root.Decoration,"RevisionR02")
 local islands=folder(art,"LandingBases")
 local hazardArt=folder(art,"HazardMounts")
 local staticHazards=folder(o,"ThemedHazards")
 local function W(x,y,z,yaw) return pivot*CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(yaw or 0),0) end
 local function ref(parent,name,value,waitKind)
  local object=Instance.new("ObjectValue")
  object.Name,object.Value,object.Parent=name,value,parent
  if waitKind then object:SetAttribute("WaitKind",waitKind) end
  return object
 end
 local function base(name,frame,width,depth)
  local model=skin(kit,"BareRock",islands,frame*CFrame.new(0,-2.1,0),V(width/7,1.1,depth/5.4))
  model.Name=name.."_Base"
 end
 local function pad(parent,name,x,y,z,width,depth,yaw,route)
  local frame=W(x,y,z,yaw)
  local object=part(parent,name,V(width,2,depth),frame*CFrame.new(0,-1,0),if route=="Expert"then C.violet else C.cream,true)
  object.TopSurface=Enum.SurfaceType.Studs
  object:SetAttribute("ERTop",frame.Position)
  object:SetAttribute("ERRoute",route or "Normal")
  object:SetAttribute("ERForwardDepth",depth)
  base(name,frame,width*.95,depth*.95)
  return object
 end
 local groups={}
 local function chain(name,route)
  local group=folder(o,name)
  local routeGroup=folder(root.Routes,name)
  local pads={}
  for index,row in ipairs(Layout[name]) do
   local p=pad(group,string.format("%s_%03d",name,index),table.unpack({row[1],row[2],row[3],row[4],row[5],row[6],route}))
   ref(routeGroup,string.format("%03d",index),p)
   table.insert(pads,p)
  end
  groups[name]=pads
  task.wait()
  return pads
 end
 for _,name in ipairs({"S1_Nestyard","E1_RimSprint","S2_EggRollers","E2_ChuteCut","S3_ShellApproach","E3_CrownApproach",
  "S4_IncubatorApproach","S4_TransferSteps","S4_ExitClimb","S5_Rookery","E4_RoostCut","S5_TailBand","S6_ShellSpill"}) do
  chain(name,if name:sub(1,1)=="E" then "Expert" else "Normal")
 end
 local function pocket(name,x,y,z,width,depth,yaw)
  return pad(o,name,x,y,z,width,depth,yaw,"Safe")
 end
 local fork=pocket("Shell_ForkWait",-58.5,16,-109.5,16,7,90)
 local middle=pocket("Shell_MiddleWait",-26,17,-122,16,5,90)
 local shellExit=pocket("Shell_ExitWait",5.25,20,-105.5,14,4,90)
 local boardA=pocket("Tray_BoardPocket",48,25,-87,12,6,0)
 local receiveA=pocket("Tray_ReceivePocket",61,25,-59,8,10,0)
 local boardB=pocket("TrayB_BoardPocket",78,29,-41,6,12,0)
 local receiveB=pocket("TrayB_ReceivePocket",110,27,-28,8,6,0)
 local tailWait=pocket("Tail_SafeWait",123,26,66,12,6,0)
 o.CP4_Pocket.CFrame=W(100.5,17,119,90)
 for i=1,4 do
  local p=o["CP"..i.."_Pocket"]
  local top=p.Position+p.CFrame.UpVector*p.Size.Y/2
  p:SetAttribute("ERTop",top)
  p:SetAttribute("ERRoute","Safe")
  base(p.Name,CFrame.new(top)*p.CFrame.Rotation,p.Size.X,p.Size.Z)
  local trigger=root.Checkpoints[string.format("Checkpoint_%03d",i)]
  trigger.CFrame=CFrame.new(top+V(0,.15,0))*p.CFrame.Rotation
  trigger:SetAttribute("RespawnCFrame",CFrame.new(top+V(0,4,0))*p.CFrame.Rotation)
  trigger:SetAttribute("RespawnAreaSize",V(14,0,6))
 end
 root.Start:SetAttribute("ERTop",root.Start.Position+root.Start.CFrame.UpVector*root.Start.Size.Y/2)
 root.Start:SetAttribute("ERRoute","Safe")

 local function warning(name,frame)
  local model=skin(kit,"WarningBeacon",hazardArt,frame)
  model.Name=name.."_Beacon"
  local lens
  for _,p in ipairs(model:GetDescendants()) do
   if p:IsA("BasePart") and p:GetAttribute("ERMaterial")=="Amber" then lens=p end
  end
  if not lens then lens=model:FindFirstChildWhichIsA("BasePart",true) end
  local sound=Instance.new("Sound")
  sound.Name,sound.SoundId,sound.Volume="WarningSound","rbxasset://sounds/electronicpingshort.wav",.35
  sound.RollOffMaxDistance,sound.Parent=40,lens
  return lens
 end
 local function mechanism(name,kind,frame,attributes,lamp)
  local m=folder(mechanisms,name,"Model")
  m.WorldPivot=frame
  m:SetAttribute("ERMechanism",kind)
  for k,value in pairs(attributes) do m:SetAttribute(k,value) end
  ref(m,"Warning",lamp)
  return m
 end
 local function lethal(model)
  for _,p in ipairs(model:GetDescendants()) do
   if p:IsA("BasePart") then p:SetAttribute("ERLethal",true);p.CanQuery=true end
  end
 end

 for i=1,5 do
  local m=mechanisms["CrownLip"..i]
  local old=m:GetPivot()
  for _,p in ipairs(m:GetDescendants()) do
   if p:IsA("BasePart") then
    local f=old:ToObjectSpace(p.CFrame)
    p.Size=V(p.Size.X*.63,p.Size.Y,p.Size.Z)
    p.CFrame=old*CFrame.new(f.Position*V(.63,1,1))*f.Rotation
   end
  end
  local row=Layout.Crowns[i]
  local target=W(row[1],row[2],row[3],if i==1 then -90 else 90)*CFrame.new(0,0,6.25)
  m:PivotTo(target)
  m:SetAttribute("OpenSeconds",6.2)
  m:SetAttribute("PhaseSeconds",0)
 end
 for _,m in ipairs(mechanisms:GetChildren()) do
  if m:GetAttribute("ERMechanism")=="ShellLip" then
   local f=m:GetPivot()
   local expert=m.Name:match("^Crown")~=nil
   local hinge=skin(kit,if expert then "ShellHingeCrown" else "ShellHingeWide",art,f,V(if expert then .63 else 1,1,1))
   hinge.Name=m.Name.."_Hinge"
   skin(kit,"BareRock",art,f*CFrame.new(0,-4,3),V(if expert then 1.3 else 2.5,.9,1))
   local lamp=warning(m.Name,f*CFrame.new(if expert then 4 else 7,1.7,1))
   m.Warning.Value=lamp
  end
 end
 for band=1,2 do
  local z=if band==1 then -17.25 else -64.5
  local y=if band==1 then 12 else 14
  for actor=1,3 do
   local name="EggBand"..band..(if actor==1 then "" else "_"..actor)
   local lamp=warning(name,W(-147,y-2,z+9+actor*1.4))
   local egg=mechanism(name,"EggRoller",W(-144,y,z),{
    Travel=V(63.75,0,0),WarningSeconds=1.3,MoveSeconds=3.5,RestSeconds=3,
    RollTurns=2,RotationAxis=V(0,0,-1),PhaseSeconds=(actor-1)*2.6+(band-1)*1.3,
   },lamp)
   egg:SetAttribute("EggBand",band)
   lethal(skin(kit,if band==1 then "EggCoral" else "EggMint",egg,egg:GetPivot()*CFrame.new(0,-4,0),V(7/6,1,7/6)))
   local preview=CFrame.new(63.75*(actor-1)/3,0,0)*CFrame.fromAxisAngle(V(0,0,-1),4*math.pi*(actor-1)/3)
   egg:SetAttribute("ERPreviewTransform",preview)
   egg:PivotTo(egg:GetPivot()*preview)
  end
  skin(kit,"EggChute",art,W(-157,y-4.6,z,90),V(1.7,1.5,1.4))
  skin(kit,"SortingShed",art,W(-162,y-11,z-6,90),V(2.1,1.9,1.6))
  skin(kit,"BareRock",art,W(-161,y-11,z),V(3.8,2.1,3.4))
  skin(kit,"NestRing",art,W(-72,y-9,z),V(1.3,.8,1.1))
 end
 local function tray(name,x,y,z,travel,scale)
  local lamp=warning(name,W(x-8,y+1,z-7))
  local m=mechanism(name,"Tray",W(x,y,z),{
   Travel=travel,BoardSeconds=2.6,WarningSeconds=1,MoveSeconds=2.3,
   ExitSeconds=2.8,ClosingWarningSeconds=1,PhaseSeconds=0,
  },lamp)
  local model=skin(kit,"SlidingTray",m,m:GetPivot()*CFrame.new(0,-.9,0),scale)
  for _,p in ipairs(model:GetDescendants()) do
   if p:IsA("BasePart") and p:GetAttribute("ERMaterial")=="Mint" then p.Transparency=1 end
  end
  local width,depth=10*scale.X,8*scale.Z
  local contact=part(m,"TrayContact",V(width,.9,depth),m:GetPivot()*CFrame.new(0,-.45,0),C.cream,true)
  contact.Transparency=1
  contact:SetAttribute("ERSupport",true)
  local top=part(m,"TrayStudTop",V(width-.3,.08,depth-.3),m:GetPivot()*CFrame.new(0,.04,0),C.cream,false)
  top.TopSurface=Enum.SurfaceType.Studs
  for _,side in ipairs({-1,1}) do
   if math.abs(travel.X)>0 then
    part(art,name.."_Rail"..side,V(width+travel.Magnitude,.6,.65),W(x+travel.X/2,y-2,z+side*(depth/2-.7)),C.iron,false)
   else
    part(art,name.."_Rail"..side,V(.65,.6,depth+travel.Magnitude),W(x+side*(width/2-.7),y-2,z+travel.Z/2),C.iron,false)
   end
  end
  return contact
 end
 local trayA=tray("SidewaysTray",48,25,-75,V(0,0,16),V(1,1,1.5))
 local trayB=tray("SidewaysTrayB",90,29,-41,V(16,0,0),V(1.2,1,1.25))
 mechanisms.SidewaysTrayB:SetAttribute("PhaseSeconds",2.1)

 local tailFrame=W(58,26,40,-70)
 local tail=mechanism("GuardianTail","Tail",tailFrame,{
  RestSeconds=2.3,WarningSeconds=1.5,MoveSeconds=1.6,FarWaitSeconds=6,
  ClosingWarningSeconds=1.5,SweepAngleDegrees=50,RotationAxis=V(0,-1,0),PhaseSeconds=1.59,
 },warning("GuardianTail",W(124,28,59)))
 lethal(skin(kit,"GuardianSweepTail",tail,tailFrame,Vector3.one*2))
 local body=skin(kit,"GuardianBody",art,W(78,18,40,90),Vector3.one*3.6)
 body.Name="GiantGuardianBody"
 skin(kit,"GuardianTail",art,W(60,24,40,90),Vector3.one*3.6).Name="GuardianTailRoot"
 skin(kit,"NestRing",art,W(78,14,40),V(3.3,1,3))
 skin(kit,"BareRock",art,W(78,13,40),V(7,3.7,7))

 local function static(name,key,x,y,z,yaw,scale)
  local m=HazardKit.Create(staticHazards,key,W(x,y,z,yaw),scale)
  m.Name=name
  return m
 end
 static("NestShellTeeth","ScorchedShell",-51,1.5,110,90,V(.75,.65,.6))
 static("NestHotGrate","HeatGrate",-103.5,5,99,0,V(.7,.8,.65))
 static("RimCornerTooth","ScorchedShell",-69,3,61,90,V(.5,.55,.45))
 static("SortingGrate","HeatGrate",-138,10,-33,90,V(.8,.75,.65))
 static("ShellApproachTeeth","ScorchedShell",-84,14,-125,55,V(.65,.55,.55))
 static("RoostFeatherPinch","FeatherPinch",145,32,11,20,V(.75,.7,.65))
 static("RoostInnerTeeth","ScorchedShell",121.5,29,26,45,V(.48,.55,.45))
 static("ReturnHotGrate","HeatGrate",53,10,121,90,V(.75,.8,.65))
 static("ReturnShellTeeth","ScorchedShell",30,5,105,90,V(.6,.55,.5))
 local function sweep(name,key,x,y,z,yaw,axis,angle,phase,scale)
  local f=W(x,y,z,yaw)
  local model=HazardKit.Create(mechanisms,key,f,scale)
  model.Name=name
  model:SetAttribute("ERMechanism","Tail")
  for k,value in pairs({RestSeconds=1.2,WarningSeconds=1,MoveSeconds=1.1,FarWaitSeconds=1.3,
   ClosingWarningSeconds=1,SweepAngleDegrees=angle,RotationAxis=axis,PhaseSeconds=phase}) do model:SetAttribute(k,value) end
  ref(model,"Warning",warning(name,f*CFrame.new(-4,1,4)))
  return model
 end
 sweep("NestFeederSweep","FeederPaddle",-62,2.5,90,0,V(0,1,0),100,.4,V(1.1,.8,.8))
 sweep("ShellToothShutter","ScorchedShell",-73,15,-130,90,V(1,0,0),80,2.1,V(.65,.65,.55))
 sweep("IncubatorFeederSweep","FeederPaddle",38,24,-103,50,V(0,1,0),105,1.8,V(1,.8,.85))
 sweep("RoostFeatherSwing","FeatherPinch",135,28,40,20,V(0,0,1),85,3.3,V(.75,.7,.65))
 sweep("ReturnFeederSweep","FeederPaddle",65,12,122,0,V(0,1,0),110,4.1,V(1,.8,.8))

 skin(kit,"EggCoral",art,W(0,0,7.5),Vector3.one*5.75).Name="CentralEgg"
 skin(kit,"NestRing",art,W(0,-1,7.5),Vector3.one*3.3)
 skin(kit,"NurseryWallBay",art,W(-83,-4,121,10),V(3,2.5,2.5))
 skin(kit,"SortingShed",art,W(-116,-1,128,20),V(2.3,1.9,1.8))
 skin(kit,"NestRing",art,W(-49,-12,112),V(2,.8,1.8))
 skin(kit,"BareRock",art,W(-49,-12,112),V(4,2.2,4.8)).Name="NestGroundingA"
 skin(kit,"NestRing",art,W(-113,-7,79),V(1.5,.8,1.4))
 skin(kit,"BareRock",art,W(-113,-7,79),V(3.1,2,3.7)).Name="NestGroundingB"
 skin(kit,"SortingShed",art,W(-73,6,-145),V(3.2,2.6,2.2))
 skin(kit,"WorkshopBay",art,W(-76,6,-140),V(2.5,2.2,1.5))
 skin(kit,"MintPipeArch",art,W(-101,7,-145,90),V(2.3,2.3,2.3))
 skin(kit,"PipeStraight",art,W(64,22,-108,90),V(2,2,4))
 skin(kit,"MintArchWindow",art,W(63,20,-106),V(3.6,3.8,3))
 skin(kit,"SortingShed",art,W(70,16,-110),V(3.1,2.8,2.5))
 skin(kit,"NurseryWallBay",art,W(155,16,27,-90),V(3.4,3,2.5))
 skin(kit,"NestRing",art,W(143,11,32),V(2.2,.8,2))
 skin(kit,"BareRock",art,W(143,11,32),V(4.6,2,5.2)).Name="RoostGrounding"
 skin(kit,"NurseryWallBay",art,W(55,-3,153),V(3,2.4,2.5))
 skin(kit,"EggDisplay",art,W(75,-3,157),V(2.4,2.4,2.4))
 for _,object in ipairs(art:GetDescendants()) do
  if object:IsA("BasePart") and object:GetAttribute("ERMaterial")=="Lilac" then object.Color=C.coral end
 end

 local function fullRoute(name,expert)
  local route=folder(root.Routes,name)
  local index=0
  local function add(p,waitKind)
   index+=1;ref(route,string.format("%03d",index),p,waitKind)
  end
  local function addGroup(group) for _,p in ipairs(groups[group]) do add(p) end end
  add(root.Start)
  addGroup(if expert then "E1_RimSprint" else "S1_Nestyard")
  add(o.CP1_Pocket)
  addGroup(if expert then "E2_ChuteCut" else "S2_EggRollers")
  add(o.CP2_Pocket)
  addGroup("S3_ShellApproach");add(fork)
  if expert then
   addGroup("E3_CrownApproach")
   for i=1,5 do add(mechanisms["CrownLip"..i].ShellContact,"Shell") end
  else
   for i=1,4 do add(mechanisms["ShellLip"..i].ShellContact,"Shell");if i==2 then add(middle) end end
  end
  add(shellExit);addGroup("S4_IncubatorApproach");add(boardA)
  add(trayA,"Tray");add(receiveA,"SideExit");addGroup("S4_TransferSteps");add(boardB)
  add(trayB,"Tray");add(receiveB,"SideExit");addGroup("S4_ExitClimb");add(o.CP3_Pocket)
  addGroup(if expert then "E4_RoostCut" else "S5_Rookery");add(tailWait)
  for i,p in ipairs(groups.S5_TailBand) do add(p,if i==1 then "Tail" else nil) end
  add(o.CP4_Pocket);addGroup("S6_ShellSpill");add(root.Start)
  route:SetAttribute("Purpose","Authoring path and visual feasibility; Expert driver completion is not acceptance")
 end
 fullRoute("RevisionNormal",false)
 fullRoute("RevisionExpert",true)
 root:SetAttribute("CandidateId",Revision.Candidate)
 root:SetAttribute("Phase",2)
 root:SetAttribute("Phase2Revision",1)
 root:SetAttribute("OwnerAcceptance","Pending R02 owner review")
 root:SetAttribute("PresentationRevision","R02")
 root:SetAttribute("RouteRevision","R02")
 root:SetAttribute("StudySource","Owner six-image critique 2026-10-26; explicit varied section layouts")
 root:SetAttribute("ExpertVerification","Visual and physical-range judgment; automated full Expert run not required")
 root.CourseInfo:SetAttribute("Enabled",true)
 return root,retired
end

return Revision
