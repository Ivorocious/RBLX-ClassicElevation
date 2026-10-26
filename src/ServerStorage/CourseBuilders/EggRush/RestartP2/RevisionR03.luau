--!nonstrict
local Revision = { Candidate = "ER_P2_R03_C04" }
local Kit = require(script.Parent.ReadableKit)
local V = Vector3.new
local cream, iron = Color3.fromRGB(255,240,202), Color3.fromRGB(55,60,68)
local offsets = {
 E2_ChuteCut_002=V(0,0,.9), E2_ChuteCut_003=V(0,0,-.25),
 E4_RoostCut_003=V(0,0,-.5), E4_RoostCut_005=V(.5,0,-.6), E4_RoostCut_007=V(.4,0,-.6),
 E3_CrownApproach_001=V(-2.2,0,3.5),
}

local function part(parent,name,size,frame,color)
 local p=Instance.new("Part")
 p.Name,p.Size,p.CFrame,p.Color=name,size,frame,color
 p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
 p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 p.Parent=parent
 return p
end

local function scaleModel(model,factor,shift)
 local pivot=model:GetPivot()
 for _,p in model:GetDescendants() do
  if p:IsA("BasePart") then
   local f=pivot:ToObjectSpace(p.CFrame)
   p.Size*=factor
   p.CFrame=pivot*CFrame.new(f.Position*factor)*f.Rotation+shift
  end
 end
 model.WorldPivot=pivot+shift
end

function Revision.Apply(root)
 assert(root:GetAttribute("CandidateId")=="ER_P2_R02_C07","Use the preserved R02 foundation")
 local pivot=root:GetPivot()
 local function W(x,y,z,yaw) return pivot*CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(yaw or 0),0) end
 local retired=Instance.new("Folder");retired.Name="R03_ReplacedGeometry"
 local function retire(p) if p then p.Parent=retired end end
 local o,mechanisms=root.Obstacles,root.Obstacles.Mechanisms
 local art=root.Decoration.RevisionR02
 retire(o.ThemedHazards)
 for _,name in {"GuardianTail","NestFeederSweep","ShellToothShutter","IncubatorFeederSweep","RoostFeatherSwing","ReturnFeederSweep"} do retire(mechanisms:FindFirstChild(name)) end
 retire(art:FindFirstChild("GiantGuardianBody"));retire(art:FindFirstChild("GuardianTailRoot"))
 for _,p in art.HazardMounts:GetChildren() do
  if p.Name:match("GuardianTail") or p.Name:match("NestFeeder") or p.Name:match("ShellTooth") or p.Name:match("IncubatorFeeder") or p.Name:match("RoostFeather") or p.Name:match("ReturnFeeder") then retire(p) end
 end
 local newArt=Instance.new("Folder");newArt.Name="RevisionR03";newArt.Parent=root.Decoration
 for _,p in root.RouteMarkers:GetChildren() do if p.Name:find("Sign_PHASE",1,true) then retire(p) end end

 for _,groupName in {"E1_RimSprint","E2_ChuteCut","E3_CrownApproach","E4_RoostCut"} do
  for _,p in o[groupName]:GetChildren() do
   local oldSize=p.Size
   local width,depth=math.max(2.2,oldSize.X*.66),math.max(2.6,oldSize.Z*.76)
   if p.Name=="E2_ChuteCut_003" or p.Name=="E2_ChuteCut_007" then width,depth=5,5.5 end
   local shift=pivot:VectorToWorldSpace(offsets[p.Name] or Vector3.zero)
   p.Size=V(width,oldSize.Y,depth);p.CFrame+=shift
   p:SetAttribute("ERTop",p.Position+p.CFrame.UpVector*p.Size.Y/2)
   p:SetAttribute("ERForwardDepth",depth)
   local base=art.LandingBases:FindFirstChild(p.Name.."_Base")
   if base then scaleModel(base,V(width/oldSize.X,1,depth/oldSize.Z),shift) end
  end
 end
 for i=1,5 do
  local crown=mechanisms["CrownLip"..i]
  scaleModel(crown,V(.8,1,1),Vector3.zero)
  scaleModel(art[crown.Name.."_Hinge"],V(.8,1,1),Vector3.zero)
  crown:SetAttribute("OpenSeconds",5.3)
 end

 -- Backdrop pipes stay behind the entire jump arc, not just the landing centers.
 for _,p in art:GetChildren() do
  if p.Name=="PipeStraight" then p:PivotTo(p:GetPivot()+pivot:VectorToWorldSpace(V(16,0,-35)))
  elseif p.Name=="MintArchWindow" then p:PivotTo(p:GetPivot()+pivot:VectorToWorldSpace(V(0,0,-25)))
  elseif p.Name=="SortingShed" and pivot:PointToObjectSpace(p:GetPivot().Position).X>0 then p:PivotTo(p:GetPivot()+pivot:VectorToWorldSpace(V(0,0,-30))) end
 end

 local hazards=Instance.new("Folder");hazards.Name="ThemedHazards";hazards.Parent=o
 local staticRows={
  {"NestShellTeeth","ScorchedShell",-51,1.5,112,0,V(.7,.9,.65)},
  {"NestHotGrate","HeatGrate",-103.7,5,99,90,V(.7,1,.65)},
  {"RimCornerTooth","ScorchedShell",-69,3,62.4,0,V(.4,.8,.45)},
  {"SortingGrate","HeatGrate",-138,10,-30,0,V(.6,1,.6)},
  {"ShellApproachTeeth","ScorchedShell",-86,14,-126.4,55,V(.6,.9,.55)},
  {"RoostFeatherPinch","FeatherPinch",146.5,32,12,20,V(.65,1,.6)},
  {"ReturnHotGrate","HeatGrate",53,10,124,0,V(.7,1,.6)},
  {"ReturnShellTeeth","ScorchedShell",30,5,108.4,0,V(.6,.9,.6)},
 }
 for _,row in staticRows do
  local p=Kit.Create(hazards,row[2],W(row[3],row[4],row[5],row[6]),row[7]);p.Name=row[1]
 end
 local function sweep(name,key,x,y,z,yaw,axis,angle,phase,scale)
  local frame=W(x,y,z,yaw)
  local model=Kit.Create(mechanisms,key,frame,scale);model.Name=name
  model:SetAttribute("ERMechanism","Tail")
  for k,v in {RestSeconds=1.5,WarningSeconds=1.1,MoveSeconds=1.2,FarWaitSeconds=1.4,ClosingWarningSeconds=1.1,SweepAngleDegrees=angle,RotationAxis=axis,PhaseSeconds=phase} do model:SetAttribute(k,v) end
  local lamp=part(newArt,name.."_Cue",V(.7,.7,.7),frame*CFrame.new(-4,1,4),Color3.fromRGB(255,190,40))
  lamp.Material=Enum.Material.Neon
  local ref=Instance.new("ObjectValue");ref.Name,ref.Value,ref.Parent="Warning",lamp,model
 end
 sweep("NestFeederSweep","FeederPaddle",-64,3,90,0,V(0,1,0),100,.4,V(.9,.9,.8))
 sweep("ShellToothShutter","ScorchedShell",-73,15,-131.5,90,V(1,0,0),80,2.1,V(.6,.8,.55))
 sweep("IncubatorFeederSweep","FeederPaddle",35,24,-101,50,V(0,1,0),105,1.8,V(.85,.9,.8))
 sweep("ReturnFeatherSwing","FeatherPinch",72,14,134.5,20,V(0,0,1),85,3.3,V(.65,.9,.6))
 sweep("ReturnFeederSweep","FeederPaddle",62,12,122,0,V(0,1,0),110,4.1,V(.85,.9,.8))

 local chicken=Instance.new("Model");chicken.Name="GuardianPeck";chicken.WorldPivot=W(78,18,40);chicken.Parent=mechanisms
 chicken:SetAttribute("ERMechanism","Peck")
 chicken:SetAttribute("NeckAnchor",V(16,18,0));chicken:SetAttribute("NeckLinkLength",24)
 chicken:SetAttribute("BendSide",Vector3.yAxis)
 for k,v in {RestSeconds=2.2,WarningSeconds=1.8,StrikeSeconds=.55,ImpactSeconds=.3,RecoverSeconds=.9,PhaseSeconds=0} do chicken:SetAttribute(k,v) end
 Kit.Create(newArt,"Body",chicken:GetPivot()).Name="GiantGuardianBody"
 local head=Kit.Create(chicken,"Head",W(112,55,40,-90));head.Name="Head"
 head:SetAttribute("BeakTip",V(0,-1,-10));head:SetAttribute("HeadNeck",V(0,-3,2.5))
 local lower=part(chicken,"NeckLower",V(8,24,8),W(94,48,40),cream)
 local upper=part(chicken,"NeckUpper",V(8,24,8),W(106,56,40),cream)
 local peck=require(script.Parent.Parent.GuardianPeck)
 local anchor=W(94,36,40).Position
 local neckEnd=head:GetPivot():PointToWorldSpace(V(0,-3,2.5))
 local elbow=peck.Elbow(anchor,neckEnd,24,pivot.UpVector)
 lower.CFrame=CFrame.lookAt((anchor+elbow)/2,elbow)*CFrame.Angles(-math.pi/2,0,0)
 upper.CFrame=CFrame.lookAt((elbow+neckEnd)/2,neckEnd)*CFrame.Angles(-math.pi/2,0,0)
 local targets=Instance.new("Folder");targets.Name="Targets";targets.Parent=chicken
 for index,p in {o.S5_Rookery.S5_Rookery_006,o.E4_RoostCut.E4_RoostCut_004,o.S5_TailBand.S5_TailBand_003} do
  local plate=part(newArt,"PeckTarget"..index,V(math.max(1,p.Size.X-.5),.06,math.max(1,p.Size.Z-.5)),p.CFrame*CFrame.new(0,p.Size.Y/2+.04,0),iron)
  local cross=Instance.new("SurfaceGui");cross.Face=Enum.NormalId.Top;cross.CanvasSize=Vector2.new(256,256);cross.Parent=plate
  local mark=Instance.new("TextLabel");mark.BackgroundTransparency=1;mark.Size=UDim2.fromScale(1,1);mark.Text="+";mark.TextColor3=cream;mark.TextScaled=true;mark.Font=Enum.Font.GothamBlack;mark.Parent=cross
  local sound=Instance.new("Sound");sound.Name="WarningSound";sound.SoundId="rbxasset://sounds/electronicpingshort.wav";sound.Volume=.45;sound.RollOffMaxDistance=60;sound.Parent=plate
  local ref=Instance.new("ObjectValue");ref.Name,ref.Value,ref.Parent=string.format("%02d",index),plate,targets
 end

 root.Start:SetAttribute("RespawnCFrame",CFrame.new(root.Start:GetAttribute("ERTop")+pivot:VectorToWorldSpace(V(-2,4,0)))*root.Start.CFrame.Rotation)
 root.Start:SetAttribute("RespawnAreaSize",V(16,0,8))
 root.Start:SetAttribute("ERPurpose","Start recovery for each new lap")
 local gate=Instance.new("Model");gate.Name="LapGate";gate.WorldPivot=root.Finish.CFrame;gate.Parent=root.RouteMarkers
 local top=root.StartPen.GateVisuals.GateLintel
 top.Color=iron
 for _,face in {Enum.NormalId.Left,Enum.NormalId.Right} do
  local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(900,100);gui.Parent=top
  local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.Text="START / LAP";label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.TextColor3=cream;label.Parent=gui
 end
 for index=1,14 do part(gate,"Line",V(2,.06,1),root.Finish.CFrame*CFrame.new(-15+index*2,-5+.04,0),if index%2==0 then cream else iron) end
 root:SetAttribute("CandidateId",Revision.Candidate);root:SetAttribute("RouteRevision","R03")
 root:SetAttribute("OwnerAcceptance","Pending R03 owner review")
 root:SetAttribute("StudySource","Owner hazard clarity, lap/start, decor and chicken-peck critique 2026-10-26")
 root:SetAttribute("ExpertVerification","Owner tests Expert skill; no automated completion gate")
 return root,retired
end

return Revision
