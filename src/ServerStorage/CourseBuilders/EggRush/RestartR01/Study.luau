--!nonstrict
local Study = {}
-- Centerlines and rough mechanisms are admitted study hypotheses, not an accepted course.
Study.Candidate = "ER_P1_R01"
Study.Origin = Vector3.new(1544, 388, -1134)
Study.HorizontalScale = .75
local C = {
 cream=Color3.fromRGB(236,234,226), coral=Color3.fromRGB(164,158,151),
 mint=Color3.fromRGB(147,169,157), green=Color3.fromRGB(128,140,126),
 rock=Color3.fromRGB(128,132,143), honey=Color3.fromRGB(157,153,145),
 expert=Color3.fromRGB(192,188,201), blue=Color3.fromRGB(58,185,232),
 red=Color3.fromRGB(255,20,35), amber=Color3.fromRGB(255,192,75), iron=Color3.fromRGB(100,106,120),
}
local function folder(parent,name,class)
 local v=Instance.new(class or "Folder");v.Name=name;v.Parent=parent;return v
end
local function part(parent,name,size,cf,color,collide)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or C.cream
 p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=p.CanCollide;p.CanQuery=true
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function v(x,y,z) return Vector3.new(x,y,z) end
local function world(p) return Study.Origin+Vector3.new(p.X*Study.HorizontalScale,p.Y,p.Z*Study.HorizontalScale) end
Study.WorldPoint=world
local function facing(p,d) return CFrame.lookAt(world(p),world(p)+Vector3.new(d.X,0,d.Z)) end
local function label(parent,text,cf,color)
 local p=part(parent,"Sign_"..text,Vector3.new(14,4,.4),cf,color or C.honey,false)
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(640,180);gui.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text
 t.TextColor3=C.cream;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Parent=gui;return p
end
function Study.Build(kit)
 local root=Instance.new("Model");root.Name="Course_EggRush_Phase1_R01"
 for k,value in {CourseId="egg_rush_circuit",CandidateId=Study.Candidate,EROwned=true,ManualEditing=true,Phase=1} do root:SetAttribute(k,value) end
 root:SetAttribute("StudySource","C15 centerlines reassessed as rough hypotheses")
 root:SetAttribute("PacingRevision","T01")
 root:SetAttribute("OwnerAcceptance","Pending")
 local info=folder(root,"CourseInfo","Configuration")
 for k,value in {CourseId="egg_rush_circuit",DisplayName="Egg Rush Circuit / Phase 1 Study",RaceFormat="LapBased",LapCount=3,Enabled=false,Difficulty="Normal / Expert",TargetNewPlayerTime=300,TargetPracticedTime=162,CheckpointCount=4} do info:SetAttribute(k,value) end
 local obstacles=folder(root,"Obstacles");local decoration=folder(root,"Decoration")
 folder(root,"Bounds");local markers=folder(root,"RouteMarkers");local checkpoints=folder(root,"Checkpoints")
 local fall=folder(root,"FallZones")
 local void=part(fall,"FallZone_Main",v(450,8,380),CFrame.new(world(v(0,-22,0))),C.rock,false);void.Transparency=1;void.CanTouch=true
 local routes=folder(root,"Routes");local mechanisms=folder(obstacles,"Mechanisms")
 local islands=folder(decoration,"RoughSupports")
 local function support(name,p,width,depth,rotation)
  local height=p.Y+20
  part(islands,name.."_Rock",v(math.max(3,width-1),height,math.max(3,depth-1)),CFrame.new(world(p-v(0,height/2+1.2,0)))*rotation,C.rock,false)
 end
 local function pad(parent,name,p,d,width,depth,kind)
  local pcf=facing(p,d);local top=part(parent,name,v(width,2,depth),pcf*CFrame.new(0,-1,0),if kind=="Expert" then C.expert else C.cream,true)
  top.TopSurface=Enum.SurfaceType.Studs;top:SetAttribute("ERRoute",kind or "Normal");top:SetAttribute("ERTop",world(p))
  top:SetAttribute("ERForwardDepth",depth);support(name,p,width,depth,pcf.Rotation);return top
 end
 local function chain(name,points,kind,spacing,width)
  local group=folder(obstacles,name);local route=folder(routes,name);local nodes={}
  local lengths,total={},0
  for i=1,#points-1 do
   local delta=world(points[i+1])-world(points[i]);lengths[i]=Vector3.new(delta.X,0,delta.Z).Magnitude
   total+=lengths[i]
  end
  local targetSpacing=math.min(spacing,if kind=="Expert" then 11.8 else 11)
  local count=math.max(1,math.ceil(total/targetSpacing));local distances={}
  local padWidth=math.min(width,if kind=="Expert" then 7 else 8)
  local depth=if name=="S4_IncubatorApproach"then 3.4 else 4
  local function openGap(a,b)
   local delta=b.Position-a.Position;local separated=false
   for _,axis in {a.RightVector,a.LookVector,b.RightVector,b.LookVector}do
    local extentA=math.abs(a.RightVector:Dot(axis))*padWidth/2+math.abs(a.LookVector:Dot(axis))*depth/2
    local extentB=math.abs(b.RightVector:Dot(axis))*padWidth/2+math.abs(b.LookVector:Dot(axis))*depth/2
    if math.abs(delta:Dot(axis))>extentA+extentB then separated=true end
   end
   if not separated then return 0 end
   local function corners(frame)
    local center=v(frame.Position.X,0,frame.Position.Z);local out={}
    for _,sign in {{-1,-1},{1,-1},{1,1},{-1,1}}do
     table.insert(out,center+frame.RightVector*sign[1]*padWidth/2+frame.LookVector*sign[2]*depth/2)
    end
    return out
   end
   local aa,bb=corners(a),corners(b);local distance=math.huge
   for _,pair in {{aa,bb},{bb,aa}}do
    for _,point in pair[1]do
     for i=1,4 do
      local first,last=pair[2][i],pair[2][i%4+1];local line=last-first
      local alpha=math.clamp((point-first):Dot(line)/line:Dot(line),0,1)
      distance=math.min(distance,(point-first-line*alpha).Magnitude)
     end
    end
   end
   return distance
  end
  local function sampleAt(distance)
   local segment=1
   while segment<#lengths and distance>lengths[segment] do distance-=lengths[segment];segment+=1 end
   return points[segment]:Lerp(points[segment+1],distance/lengths[segment])
  end
  local function shapes()
   local samples,frames={},{}
   for _,distance in distances do table.insert(samples,sampleAt(distance)) end
   for i,p in samples do
    local incoming=if i>1 then (p-samples[i-1]).Unit else (samples[2]-p).Unit
    local outgoing=if i<#samples then (samples[i+1]-p).Unit else incoming
    frames[i]=facing(p,incoming+outgoing)
   end
   return samples,frames
  end
  local function score()
   local samples,frames=shapes();local value=0
   for i=2,#frames do
    local clearance=openGap(frames[i-1],frames[i])
    local rise=samples[i].Y-samples[i-1].Y
    local reach=16*(math.sqrt(2*196.2*7.2)+math.sqrt(math.max(0,2*196.2*(7.2-rise))))/196.2-.35
    local minimum=5+math.min(1.5,math.max(0,-rise)*.5)
    value+=math.max(0,minimum-clearance)^2*10+math.max(0,clearance-reach)^2*20
   end
   return value
  end
  -- Keep whole-path sampling, then fit only nearby arc positions at bends.
  local bestDistances,bestScore=nil,math.huge
  for _,adjustment in if name=="S4_IncubatorApproach"then{0}else{0,-1,-2,-3,-4,-5,1} do
   local intervals=math.max(1,count+adjustment);distances={}
   for n=0,intervals do table.insert(distances,total*n/intervals) end
   local best=score()
   for _=1,32 do
    local improved=false
    for i=2,#distances-1 do
     local original=distances[i];local chosen=original
     for _,offset in {-2,-.5,.5,2} do
      distances[i]=math.clamp(original+offset,distances[i-1]+2,distances[i+1]-2)
      local trial=score()
      if trial<best-.0001 then best,chosen=trial,distances[i];improved=true end
     end
     distances[i]=chosen
    end
    if not improved or best<.0001 then break end
   end
   if best<bestScore then bestScore,bestDistances=best,table.clone(distances) end
   if bestScore<.0001 then break end
  end
  distances=bestDistances
  local samples,frames=shapes()
  for i,p in samples do
   local top=pad(group,string.format("%s_%03d",name,#nodes+1),p,frames[i].LookVector,padWidth,depth,kind)
   local ref=Instance.new("ObjectValue");ref.Name=string.format("%03d",#nodes+1);ref.Value=top;ref.Parent=route;table.insert(nodes,top)
  end
  if game and game:GetService("RunService"):IsStudio()and root.Parent==nil then task.wait()end
  return nodes
 end
 local function lethalOnPad(parent,name,nodes,target,width)
  local selected,distance,selectedIndex=nil,math.huge,nil
  for i,candidate in nodes do
   local offset=(candidate:GetAttribute("ERTop")-world(target)).Magnitude
   if offset<distance and i<#nodes then selected,distance,selectedIndex=candidate,offset,i end
   end
  local nextPad=nodes[selectedIndex+1]
  local a,b=selected:GetAttribute("ERTop"),nextPad:GetAttribute("ERTop")
  local direction=Vector3.new(b.X-a.X,0,b.Z-a.Z).Unit
  local function extent(p)
   return math.abs(p.CFrame.RightVector:Dot(direction))*p.Size.X/2+math.abs(p.CFrame.LookVector:Dot(direction))*p.Size.Z/2
  end
  local center=((a+direction*extent(selected))+(b-direction*extent(nextPad)))/2+v(0,.7,0)
  local bar=part(parent,name,v(math.min(width,selected.Size.X-.6),1.4,1.4),CFrame.lookAt(center,center+direction),C.red,false)
  bar.Material=Enum.Material.Neon;bar.CanTouch=true;bar:SetAttribute("ERLethal",true);bar:SetAttribute("ERPadName",selected.Name);bar:SetAttribute("ERNextPadName",nextPad.Name);return bar
 end
 local function checkpoint(i,p,d)
  local base=pad(obstacles,"CP"..i.."_Pocket",p,d,19,10,"Safe")
  local trigger=part(checkpoints,string.format("Checkpoint_%03d",i),v(19,.25,9),facing(p+v(0,.15,0),d),C.blue,false)
  trigger.Transparency=.65;trigger.CanTouch=true
  trigger:SetAttribute("RespawnCFrame",facing(p+v(0,4,-1),d));trigger:SetAttribute("RespawnAreaSize",v(14,0,6))
  local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Top;gui.CanvasSize=Vector2.new(512,256);gui.Parent=trigger
  local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text="CP "..i
  text.TextColor3=C.cream;text.Font=Enum.Font.GothamBold;text.TextScaled=true;text.Parent=gui;return base
 end
 local function warning(name,p,d)
  local lamp=part(decoration,name.."_Warning",v(1.5,2.2,1.5),facing(p,d)*CFrame.new(0,3,0),C.mint,false)
  part(decoration,name.."_WarningPost",v(.8,2,.8),lamp.CFrame*CFrame.new(0,-2,0),C.coral,true)
  return lamp
 end
 local function mechanism(name,kind,cf,attrs,lamp)
  local m=folder(mechanisms,name,"Model");m.WorldPivot=cf;m:SetAttribute("ERMechanism",kind)
  for k,value in attrs do m:SetAttribute(k,value) end
  local ref=Instance.new("ObjectValue");ref.Name="Warning";ref.Value=lamp;ref.Parent=m;return m
 end
 local start=part(root,"Start",v(28,2,26),facing(v(-8,0,120),v(-1,0,0))*CFrame.new(0,-1,0),C.cream,true)
 start.TopSurface=Enum.SurfaceType.Studs
 local finish=part(root,"Finish",v(28,12,1),facing(v(0,5,120),v(-1,0,0)),C.blue,false)
 finish.Transparency=1;finish.CanTouch=true;finish:SetAttribute("RequireForwardCrossing",true)
 local pen=folder(root,"StartPen");local gate=part(pen,"StartGate",v(28,10,1),facing(v(-21,4,120),v(-1,0,0)),C.mint,true);gate.Transparency=1
 local gateArt=folder(pen,"GateVisuals")
 local barrier=part(gateArt,"CountdownBarrier",gate.Size,gate.CFrame,C.mint,false);barrier.Transparency=.55;barrier.CanQuery=false
 local gateSupports=folder(pen,"GateSupports")
 for _,z in {-15,15} do local post=part(gateSupports,"GatePost",v(2,13,2),CFrame.new(world(v(0,5,z+120))),C.coral,false);post.CanQuery=false end
 part(gateArt,"GateLintel",v(2,2,32),CFrame.new(world(v(0,12,120))),C.cream,false)
 label(markers,"PHASE 1 STUDY  /  3 LAPS",facing(v(0,14,120),v(1,0,0)),C.coral)
 local n1=chain("S1_Nestyard",{v(-28,0,120),v(-65,2,145),v(-96,3,112),v(-135,5,135),v(-165,6,100),v(-135,7,75),v(-145,8,52)},"Normal",11,12)
 chain("E1_RimSprint",{v(-43,1,110),v(-77,3,95),v(-107,5,73),v(-142,8,52)},"Expert",13,7)
 lethalOnPad(obstacles,"Nestyard_RedHop",n1,v(-65,2,145),6)
 checkpoint(1,v(-145,8,40),v(0,0,-1))
 chain("S2_EggRollers",{v(-149,8,26),v(-178,8,3),v(-164,9,-36),v(-190,10,-55),v(-161,10,-69),v(-178,11,-100),v(-136,12,-116)},"Normal",11,11)
 chain("E2_ChuteCut",{v(-137,8,27),v(-127,9,-7),v(-137,9,-36),v(-125,10,-57),v(-137,11,-95),v(-131,12,-108)},"Expert",13,7)
 for i,z in {-23,-86} do
  local p=v(-192,if i==1 then 12 else 14,z);local lamp=warning("EggBand"..i,v(-174,if i==1 then 8 else 10,z+14),v(0,0,-1))
  local sound=Instance.new("Sound");sound.Name="WarningSound";sound.SoundId="rbxasset://sounds/electronicpingshort.wav";sound.Volume=.5;sound.Parent=lamp
  local egg=mechanism("EggBand"..i,"EggRoller",CFrame.new(world(p)),{Travel=v(63.75,0,0),WarningSeconds=1.3,MoveSeconds=3.5,RestSeconds=9.7,RollTurns=2,RotationAxis=v(0,0,-1),PhaseSeconds=if i==1 then 8.72 else 1.92},lamp)
  local body=part(egg,"RoughEgg",v(7,8,7),CFrame.new(world(p)),C.cream,false);body:SetAttribute("ERLethal",true)
  for _,x in {-192,-107} do part(decoration,"EggRunout",v(9,5,12),CFrame.new(world(v(x,p.Y-5,z))),C.coral,false) end
 end
 checkpoint(2,v(-125,12,-120),v(1,0,0))
 require(script.Parent.Sample).Build(root,kit,{origin=Study.Origin,horizontalScale=Study.HorizontalScale})
 local n4=chain("S4_IncubatorApproach",{v(22,21,-128),v(36,23,-122),v(65,26,-108)},"Normal",11,11)
 lethalOnPad(obstacles,"Incubator_RedHop",n4,v(48,24,-127),6)
 local boardPocket=pad(obstacles,"Tray_BoardPocket",v(82,26,-105),v(0,0,1),24,8,"Safe")
 pad(obstacles,"Tray_ReceivePocket",v(100,26,-64),v(1,0,0),18,10,"Safe")
 local approachB=folder(obstacles,"S4_TrayApproachB");local approachRefs=folder(routes,"S4_TrayApproachB")
 approachRefs:SetAttribute("FromPad",n4[5].Name);approachRefs:SetAttribute("ToPad",boardPocket.Name)
 local branchPoints={v(64,26,-126.666667),v(77.333333,26,-134.666667),v(90.666667,26,-122.666667)}
 for i,p in ipairs(branchPoints)do
  local previous=if i==1 then n4[5]:GetAttribute("ERTop")else world(branchPoints[i-1])
  local following=if i==#branchPoints then boardPocket:GetAttribute("ERTop")else world(branchPoints[i+1])
  local incoming=(world(p)-previous)*v(1,0,1);local outgoing=(following-world(p))*v(1,0,1)
  local heading=incoming.Unit+outgoing.Unit
  if i==1 then heading=CFrame.Angles(0,math.rad(-10),0):VectorToWorldSpace(heading)end
  local landing=pad(approachB,string.format("S4_TrayApproachB_%03d",i),p,heading,8,4,"Normal")
  local ref=Instance.new("ObjectValue");ref.Name=string.format("%03d",i);ref.Value=landing;ref.Parent=approachRefs
 end
 local trayLamp=warning("Tray",v(74,26,-105),v(0,0,1))
 local tray=mechanism("SidewaysTray","Tray",CFrame.new(world(v(82,26,-92))),{Travel=v(0,0,21),BoardSeconds=3,WarningSeconds=1.2,MoveSeconds=2.8,ExitSeconds=3.5,ClosingWarningSeconds=1.2,PhaseSeconds=13.09},trayLamp)
 local deck=part(tray,"TrayContact",v(12,1,18),CFrame.new(world(v(82,25.5,-92))),C.cream,true);deck:SetAttribute("ERSupport",true)
 for _,x in {77,87} do part(decoration,"ExposedRail",v(.8,1,65),CFrame.new(world(v(x,24.6,-78))),C.iron,false) end
 chain("S4_ExitClimb",{v(113,28,-61),v(132,32,-49),v(144,36,-33)},"Normal",11,11)
 checkpoint(3,v(145,36,-20),v(0,0,1))
 chain("S5_Rookery",{v(154,35,-7),v(183,34,12),v(157,32,28),v(184,30,48),v(158,28,58),v(169,27,74),v(151,26,72)},"Normal",11,12)
 chain("E4_RoostCut",{v(141,35,-6),v(130,32,12),v(143,29,29),v(132,27,47),v(132,26,72)},"Expert",14,7)
 pad(obstacles,"Tail_SafeWait",v(132,26,83),v(0,0,1),22,8,"Safe")
 chain("S5_TailBand",{v(126,25,100),v(138,23,113),v(147,21,119)},"Normal",11,12)
 local tailLamp=warning("Tail",v(135,26,82),v(0,0,-1))
 local tailFrame=CFrame.new(world(v(92,26,112)))*CFrame.Angles(0,math.rad(25),0)
 local tail=mechanism("GuardianTail","Tail",tailFrame,{RestSeconds=2.3,WarningSeconds=1.5,MoveSeconds=1.6,FarWaitSeconds=6,ClosingWarningSeconds=1.5,SweepAngleDegrees=50,RotationAxis=v(0,-1,0),PhaseSeconds=1.59},tailLamp)
 local tailBody=part(tail,"RoughTail",v(29.25,5,3),tailFrame*CFrame.new(14.625,1,0),C.coral,false);tailBody:SetAttribute("ERLethal",true)
 checkpoint(4,v(134,18,135),v(-1,0,0))
 local n6=chain("S6_ShellSpill",{v(119,17,143),v(101,14,154),v(78,11,133),v(61,8,146),v(40,5,126),v(24,1,120),v(14,0,120)},"Normal",11,12)
 lethalOnPad(obstacles,"Return_RedHop",n6,v(78,11,133),6)
 local landmark=folder(decoration,"CentralLandmark","Model")
 for i,data in {{36,7,0},{46,20,7},{38,10,27},{28,8,37},{16,6,45}} do
  part(landmark,"EggTier"..i,v(data[1],data[2],data[1]),CFrame.new(world(v(0,data[3]+data[2]/2,10))),C.cream,true)
 end
 for _,data in {{-115,0,105},{-224,3,-65},{118,26,-107},{181,24,79}} do
  local p=v(data[1],data[2],data[3]);part(decoration,"DistrictRoughMass",v(30,14,7),CFrame.new(world(p+v(0,5,0))),C.honey,false)
 end
 root.WorldPivot=CFrame.new(Study.Origin)
 return root
end
return Study
