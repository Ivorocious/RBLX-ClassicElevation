--!nonstrict
local Test={}
local RunService=game:GetService("RunService")
local function eggCrossings(course,points)
 local models=course.Obstacles.Mechanisms:GetChildren()
 table.sort(models,function(a,b)return a.Name<b.Name end)
 for _,model in ipairs(models)do
  if model:GetAttribute("ERMechanism")~="EggRoller"then continue end
  assert(math.abs(model:GetAttribute("Travel").Z)<.001,"Egg check expects the authored sideways band")
  local low,high=math.huge,-math.huge
  for _,part in ipairs(model:GetDescendants())do
   if part:IsA("BasePart")and part:GetAttribute("ERLethal")==true then
    local cf=part.CFrame;local half=(math.abs(cf.RightVector.Z)*part.Size.X+math.abs(cf.UpVector.Z)*part.Size.Y+math.abs(cf.LookVector.Z)*part.Size.Z)/2
    low=math.min(low,cf.Position.Z-half);high=math.max(high,cf.Position.Z+half)
   end
  end
  local enter,leave
  for i=2,#points do
   local a,b=points[i-1].part.Position.Z,points[i].part.Position.Z
   if not enter and a>high+3 and b<=high+3 then enter=i end
   if enter and b<low-3 then leave=i;break end
  end
  assert(enter and leave,"Full route must cross "..model.Name)
  points[enter].eggs=points[enter].eggs or{}
  table.insert(points[enter].eggs,{model=model,low=low,high=high,hops=leave-enter+1})
  points[leave].eggExit=points[leave].eggExit or{}
  table.insert(points[leave].eggExit,model.Name)
 end
end
function Test.Points(course,line,section)
 assert(line=="Normal"or line=="Expert","Expected Normal or Expert route")
 local route=assert(course.Routes:FindFirstChild("Revision"..line),"Current revision route required")
 local refs=route:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
 local out={}
 local peck=assert(course.Obstacles.Mechanisms:FindFirstChild("GuardianPeck"),"Current chicken required")
 for _,ref in ipairs(refs)do
  local part=assert(ref.Value,"Route reference missing landing")
  local kind=ref:GetAttribute("WaitKind")
  local point={part=part,waitKind=if kind=="Tail"then nil else kind}
  if point.waitKind=="SideExit"then
   local preceding=out[#out]
   assert(preceding and preceding.waitKind=="Tray"and preceding.part.Parent:GetAttribute("ERMechanism")=="Tray","Side exit must follow its actual tray")
   point.tray=preceding.part.Parent
  end
  for _,target in ipairs(peck.Targets:GetChildren())do
   local plate=assert(target.Value)
   if (part.Position+part.CFrame.UpVector*part.Size.Y/2-plate.Position).Magnitude<2 then
    point.peck={model=peck,target=assert(tonumber(target.Name))}
   end
  end
  table.insert(out,point)
 end
 assert(out[1].part==course.Start and out[#out].part==course.Start,"Current route must return to original Start")
 if section then
  assert(section~="IncubatorAlternate","The current route has two required trays and no alternate entry")
  local limits={Rookery={"CP3_Pocket","CP4_Pocket"},Incubator={"Shell_ExitWait","CP3_Pocket"},Shellworks={"CP2_Pocket","Shell_ExitWait"}}
  local bounds=assert(limits[section],"Unknown section")
  local selected,active={},false
  for _,point in ipairs(out)do
   if point.part.Name==bounds[1]then active=true end
   if active then table.insert(selected,point)end
   if active and point.part.Name==bounds[2]then break end
  end
  assert(#selected>1 and selected[#selected].part.Name==bounds[2],"Section endpoints missing")
  return selected
 end
 eggCrossings(course,out)
 return out
end
local function top(part)return part.Position+part.CFrame.UpVector*part.Size.Y/2 end
local CONTACT_AIMS={
 S1_Nestyard_005={0,-1},S1_Nestyard_009={1,1},
 S3_ShellApproach_003={0,.5},S3_ShellApproach_004={-1,0},
 S4_IncubatorApproach_002={0,-.5},S4_IncubatorApproach_003={-.5,0},
 S5_Rookery_003={-1,-1},
 -- The north flank keeps the returning feather outside the full-body waiting space.
 S6_ShellSpill_002={1,0},S6_ShellSpill_003={0,1},
}
local function contactAim(part)
 local offset=CONTACT_AIMS[part.Name]
 if not offset then return top(part)end
 return part.CFrame:PointToWorldSpace(Vector3.new(offset[1]*math.max(0,part.Size.X/2-.65),part.Size.Y/2,offset[2]*math.max(0,part.Size.Z/2-.65)))
end
-- Jump before walking into the return feeder shaft at the near edge.
local function takeoffInset(part)return if part.Name=="S6_ShellSpill_003"then 2.5 else .55 end
-- These are the actual R05 crossings; Expert keeps its own route and is not auto-completed.
local SWEEP_CROSSINGS={
 NestFeederSweep={"S1_Nestyard_004","S1_Nestyard_006",1},
 ShellToothShutter={"S3_ShellApproach_003","S3_ShellApproach_005",0,true},
 IncubatorFeederSweep={"S4_IncubatorApproach_002","S4_IncubatorApproach_003",0},
 ReturnFeatherSwing={"S6_ShellSpill_001","S6_ShellSpill_002",1},
 ReturnFeederSweep={"S6_ShellSpill_002","S6_ShellSpill_004",1},
}
function Test.SweepAdmissions(course,points)
 local admissions,aims={},{}
 for _,point in ipairs(points)do if CONTACT_AIMS[point.part.Name]then aims[point.part]=contactAim(point.part)end end
 for _,model in ipairs(course.Obstacles.Mechanisms:GetChildren())do
  local crossing=SWEEP_CROSSINGS[model.Name]
  if not crossing then continue end
  assert(model:GetAttribute("ERMechanism")=="Tail","Expected current themed sweep")
  local settings={rest=model:GetAttribute("RestSeconds"),warning=model:GetAttribute("WarningSeconds"),move=model:GetAttribute("MoveSeconds"),open=model:GetAttribute("FarWaitSeconds"),closingWarning=model:GetAttribute("ClosingWarningSeconds"),phase=model:GetAttribute("PhaseSeconds")or 0}
  for index=1,#points-1 do
   if points[index].part.Name~=crossing[1]then continue end
   local last=index+1
   while last<=#points and points[last].part.Name~=crossing[2]do last+=1 end
   assert(last<=#points,"Current sweep crossing endpoint missing")
   table.insert(admissions,{model=model,settings=settings,endpoint=crossing[3],observeOnly=crossing[4],needed=if model.Name=="ReturnFeatherSwing"then 2 else(last-index)*1.1+.2,first=index+1,last=last})
  end
 end
 return admissions,aims
end
local function insideFootprint(part,position)
 local p=part.CFrame:PointToObjectSpace(position)
 return math.abs(p.X)<=part.Size.X/2 and math.abs(p.Z)<=part.Size.Z/2
end
local function landingAim(part,nextPart,pace)
 local center=top(part)
 if not pace or not nextPart then return center end
 local delta=top(nextPart)-center;local flat=Vector3.new(delta.X,0,delta.Z)
 if flat.Magnitude<.001 then return center end
 local p=part.CFrame:PointToObjectSpace(center+flat.Unit*1.2)
 local x,z=math.max(0,part.Size.X/2-.6),math.max(0,part.Size.Z/2-.6)
 return part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(p.X,-x,x),part.Size.Y/2,math.clamp(p.Z,-z,z)))
end
function Test.PointAim(part,nextPart,pace)
 if part.Name=="S6_ShellSpill_002"then
  return part.CFrame:PointToWorldSpace(Vector3.new(.5*math.max(0,part.Size.X/2-.65),part.Size.Y/2,0))
 end
 return if CONTACT_AIMS[part.Name]then contactAim(part)else landingAim(part,nextPart,pace)
end
local function acceptsSupport(course,wanted,support,position)
 if support==wanted then return true end
 if not support then return false end
 for _,part in ipairs({wanted,support})do
  if not part:IsA("BasePart")or not part.Anchored or not part.CanCollide or not part.CanQuery
   or not part:IsDescendantOf(course)or typeof(part:GetAttribute("ERTop"))~="Vector3"
   or not table.find({"Normal","Expert","Safe"},part:GetAttribute("ERRoute"))
   or part.CFrame.UpVector:Dot(Vector3.yAxis)<.9999
   or math.abs(top(part).Y-part:GetAttribute("ERTop").Y)>.05 then return false end
  local ancestor=part
  while ancestor and ancestor~=course do
   if ancestor:GetAttribute("ERMechanism")~=nil then return false end
   ancestor=ancestor.Parent
  end
 end
 if math.abs(top(wanted).Y-top(support).Y)>.05 then return false end
 return insideFootprint(wanted,position)
end
local function edgeDistance(part,position,direction)
 local p,d=part.CFrame:PointToObjectSpace(position),part.CFrame:VectorToObjectSpace(direction)
 local distance=math.huge
 for _,axis in ipairs({"X","Z"})do
  if math.abs(d[axis])>.0001 then distance=math.min(distance,(math.sign(d[axis])*part.Size[axis]/2-p[axis])/d[axis])end
 end
 return distance
end
local function boxHalf(frame,size)
 return Vector3.new(math.abs(frame.RightVector.X)*size.X+math.abs(frame.UpVector.X)*size.Y+math.abs(frame.LookVector.X)*size.Z,math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z,math.abs(frame.RightVector.Z)*size.X+math.abs(frame.UpVector.Z)*size.Y+math.abs(frame.LookVector.Z)*size.Z)/2
end
function Test.EggActors(course,elapsed,sample)
 local actors={}
 for _,model in ipairs(course.Obstacles.Mechanisms:GetChildren())do
  if model:GetAttribute("ERMechanism")~="EggRoller"then continue end
  local settings={rest=model:GetAttribute("RestSeconds"),warning=model:GetAttribute("WarningSeconds"),move=model:GetAttribute("MoveSeconds"),phase=model:GetAttribute("PhaseSeconds")or 0}
  local pivot,travel,axis,turns=model:GetPivot(),model:GetAttribute("Travel"),model:GetAttribute("RotationAxis"),model:GetAttribute("RollTurns")
  local alpha=sample("EggRoller",settings,elapsed)
  local pose=CFrame.new(travel*alpha)*CFrame.fromAxisAngle(axis,2*math.pi*turns*alpha)
  local start=if model:GetAttribute("ERState")then pivot*pose:Inverse()else pivot*(model:GetAttribute("ERPreviewTransform")or CFrame.identity):Inverse()
  local record={model=model,settings=settings,travel=travel,axis=axis,turns=turns,start=start,parts={}}
  for _,part in ipairs(model:GetDescendants())do if part:IsA("BasePart")and part:GetAttribute("ERLethal")==true then table.insert(record.parts,{frame=pivot:ToObjectSpace(part.CFrame),size=part.Size})end end
  actors[model.Name]=record
 end
 return actors
end
function Test.EggPath(points,first,last,position,low,high,aim)
 local path,elapsed={},0
 local height=position.Y-top(points[first].part).Y
 local center,size=(low+high)/2,high-low
 local velocity=math.sqrt(2*196.2*7.2)
 for index=first,last-1 do
  local from,to=points[index].part,points[index+1].part
  local target=aim(to,points[index+2]and points[index+2].part)
  local flat=(target-position)*Vector3.new(1,0,1);local direction=flat.Unit
  local approach=math.max(0,edgeDistance(from,position,direction)-takeoffInset(from))/16
  local rise=target.Y-top(from).Y
  local flight=(velocity+math.sqrt(velocity*velocity-2*196.2*rise))/196.2
  local duration=math.max(flat.Magnitude/16,approach+flight)+.17
  local rotation=CFrame.lookAt(Vector3.zero,direction).Rotation
  local half=boxHalf(rotation,size)
  for step=0,math.ceil(duration/.04)do
   local t=math.min(step*.04,duration)
   local air=t-approach
   local y=if air<0 then top(from).Y elseif air<flight then top(from).Y+velocity*air-196.2*air*air/2 else target.Y
   local root=Vector3.new(position.X,y+height,position.Z)+direction*math.min(flat.Magnitude,16*t)
   local at=root+rotation:VectorToWorldSpace(center)
   table.insert(path,{time=elapsed+t,low=at-half,high=at+half})
  end
  elapsed+=duration;position=target+Vector3.yAxis*height
 end
 return path,elapsed
end
function Test.EggClear(actors,path,elapsed,sample)
 for _,body in ipairs(path)do for _,actor in ipairs(actors)do for _,jitter in ipairs({-.08,0,.08})do
  local alpha,state=sample("EggRoller",actor.settings,elapsed+body.time+jitter)
  if state~="Rolling"then continue end
  local frame=actor.start*CFrame.new(actor.travel*alpha)*CFrame.fromAxisAngle(actor.axis,2*math.pi*actor.turns*alpha)
  for _,part in ipairs(actor.parts)do
   local cf=frame*part.frame;local half=boxHalf(cf,part.size);local low,high=cf.Position-half,cf.Position+half
   if body.low.X<high.X and body.high.X>low.X and body.low.Y<high.Y and body.high.Y>low.Y and body.low.Z<high.Z and body.high.Z>low.Z then return false,actor.model.Name end
  end
 end end end
 return true
end
function Test.Run(course,player,points,options,progress)
 assert(RunService:IsStudio()and RunService:IsServer(),"Native Studio server traversal only")
 options=options or{}
 local pace=options.pace==true
 local function aim(part,nextPart)
  local point=Test.PointAim(part,nextPart,pace)
  if not options.aim then return point end
  local selected=options.aim(part,nextPart,point)
  assert(typeof(selected)=="Vector3","Test steering needs a physical landing point")
  local localPoint=part.CFrame:PointToObjectSpace(selected)
  assert(math.abs(localPoint.X)<=part.Size.X/2-.5 and math.abs(localPoint.Z)<=part.Size.Z/2-.25
   and math.abs(localPoint.Y-part.Size.Y/2)<.1,"Test steering must stay inside the actual supported footprint")
  return selected
 end
 local char=assert(player.Character);local root=char.HumanoidRootPart;local humanoid=char:FindFirstChildOfClass("Humanoid")
 assert(humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01,"Wrong movement profile")
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={course};params.RespectCanCollide=true
 local function standing()
  local hit=workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),params)
  return hit and hit.Instance
 end
 local function supportedBy(part)return acceptsSupport(course,part,standing(),root.Position)end
 local movement,jump=Vector3.zero,false;local approach;local records,windowTrace,eggReceipts,carryReceipts,walkReceipts={},{},{},{},{};local waits=0;local started=os.clock();local paceSettle
 local runtime=require(game.ServerScriptService.Services.EggRushService)
 local lastClock=assert(runtime.GetDiagnostics().elapsed,"Egg Rush runtime must be bound")
 local function clock()lastClock=runtime.GetDiagnostics().elapsed or lastClock;return lastClock end
 local sweepAdmissions=Test.SweepAdmissions(course,points)
 local eggSampler=require(game.ServerStorage.CourseBuilders.EggRush.Runtime).Sample
 local eggActors=Test.EggActors(course,clock(),eggSampler)
 local function valid()
  assert(player.Character==char and humanoid.Health>0,"Character changed during traversal")
  assert(not options.guard or options.guard(),"Course or race changed during traversal")
 end
 root.Anchored=false;root:SetNetworkOwner(nil)
 local connection=RunService.PreSimulation:Connect(function()
  if approach and not approach.requested and edgeDistance(approach.part,root.Position,approach.direction)<=approach.inset then
   approach.requested=true;approach.launch=root.Position;jump=true
  end
  humanoid:Move(movement,false);humanoid.Jump=jump
 end)
 local function untilTrue(predicate,seconds,message)
  local deadline=os.clock()+seconds
  repeat RunService.Heartbeat:Wait();valid()until predicate()or os.clock()>deadline
  assert(predicate(),message)
 end
 local function waitWindow(point,from,index)
  local before=os.clock();movement=Vector3.zero;jump=false
  for _,admission in ipairs(sweepAdmissions)do
   if admission.first~=index then continue end
   local model,settings=admission.model,admission.settings
   local function remaining()
    local t=(clock()+settings.phase)%(settings.rest+settings.warning+settings.move+settings.open+settings.closingWarning+settings.move)
    if admission.endpoint==0 then return if t<settings.rest+settings.warning then settings.rest+settings.warning-t else 0 end
    local at=settings.rest+settings.warning+settings.move
    return if t>=at and t<at+settings.open+settings.closingWarning then at+settings.open+settings.closingWarning-t else 0
   end
   local trace={model=model.Name,beforeClock=clock(),beforeState=model:GetAttribute("ERState"),needed=admission.needed,endpoint=admission.endpoint,first=points[admission.first-1].part.Name,last=points[admission.last].part.Name,policy="Actual themed sweep geometry; unchanged parked pose and shared clock"}
   table.insert(windowTrace,trace)
   if not admission.observeOnly then
    untilTrue(function()assert(supportedBy(from.part),"Lost support before themed sweep");return remaining()>=admission.needed end,18,"No authored safe crossing window for "..model.Name)
   else trace.policy="Actual clear side of shutter pad; no wait required"end
   trace.entryClock=clock();trace.entryState=model:GetAttribute("ERState");trace.remaining=remaining();trace.waitSeconds=os.clock()-before
  end
  local eggPlan
  if point.eggs and #point.eggs>0 then
   local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
   for _,part in ipairs(char:GetChildren())do
    if part:IsA("BasePart")and part~=root and part.Name~="CollisionPart"and part.Transparency<1 and part.CanQuery then
     local frame=root.CFrame:ToObjectSpace(part.CFrame);local half=boxHalf(frame,part.Size)
     local a,b=frame.Position-half,frame.Position+half
     low=Vector3.new(math.min(low.X,a.X),math.min(low.Y,a.Y),math.min(low.Z,a.Z));high=Vector3.new(math.max(high.X,b.X),math.max(high.Y,b.Y),math.max(high.Z,b.Z))
    end
   end
   -- This padding covers the observed walking/jumping limb changes and landing tolerance.
   local padding=Vector3.new(.5,1,.75);low-=padding;high+=padding
   local path,seconds=Test.EggPath(points,index-1,index+point.eggs[1].hops-1,root.Position,low,high,aim)
   local actors={};for _,egg in ipairs(point.eggs)do table.insert(actors,assert(eggActors[egg.model.Name]))end
   local entered=os.clock()
   untilTrue(function()assert(supportedBy(from.part),"Lost support at egg safe wait");return Test.EggClear(actors,path,clock(),eggSampler)end,16,"No body-clear opening through the staggered egg actors")
   eggPlan={seconds=seconds,waitSeconds=os.clock()-entered,bodyLow={low.X,low.Y,low.Z},bodyHigh={high.X,high.Y,high.Z},clockJitter=.08}
  end
  for _,egg in ipairs(point.eggs or{})do
   local model=egg.model
   local low=math.huge
   for _,part in ipairs(char:GetChildren())do
    if part:IsA("BasePart")and part.Name~="HumanoidRootPart"and part.Transparency<1 then
     local cf=part.CFrame;local half=(math.abs(cf.RightVector.Z)*part.Size.X+math.abs(cf.UpVector.Z)*part.Size.Y+math.abs(cf.LookVector.Z)*part.Size.Z)/2
     low=math.min(low,part.Position.Z-half)
    end
   end
   assert(low>egg.high+.1,"Egg wait is inside the swept band at "..from.part.Name)
   local receipt={model=model.Name,entryClock=clock(),entryState=model:GetAttribute("ERState"),hops=egg.hops,safeBodyClearance=low-egg.high,pace=pace,plan=eggPlan,policy="Actual-clock moving actor boxes against observed padded body path; contacts remain active"}
   table.insert(windowTrace,receipt);eggReceipts[model.Name]=receipt
  end
  if point.peck then
   local model,target=point.peck.model,point.peck.target
   local settings={rest=model:GetAttribute("RestSeconds"),warning=model:GetAttribute("WarningSeconds"),strike=model:GetAttribute("StrikeSeconds"),impact=model:GetAttribute("ImpactSeconds"),recover=model:GetAttribute("RecoverSeconds"),phase=model:GetAttribute("PhaseSeconds")or 0}
   local sampler=require(game.ServerStorage.CourseBuilders.EggRush.GuardianPeck).Sample
   local needed=2.4
   local function clear()
    for offset=0,needed,.05 do
     local sample=sampler(settings,clock()+offset,#model.Targets:GetChildren())
     if sample.target==target and sample.lethal then return false end
    end
    return true
   end
   untilTrue(function()assert(supportedBy(from.part),"Lost support before peck target");return clear()end,20,"Chicken target did not offer a clear crossing")
   table.insert(windowTrace,{model=model.Name,target=target,entryClock=clock(),entryState=model:GetAttribute("ERState"),needed=needed,waitSeconds=os.clock()-before,policy="Existing target cycle; no hazard clock writes"})
  end
  if point.waitKind=="Shell"then
   local model=point.part.Parent
   local function remaining()
    local c,w,m,o,cw=model:GetAttribute("ClosedSeconds"),model:GetAttribute("WarningSeconds"),model:GetAttribute("MoveSeconds"),model:GetAttribute("OpenSeconds"),model:GetAttribute("ClosingWarningSeconds")
    local t=(clock()+(model:GetAttribute("PhaseSeconds")or 0))%(c+w+m+o+cw+m)
    local openAt=c+w+m
    return if t>=openAt and t<openAt+o+cw then openAt+o+cw-t else 0
   end
   local onLip=from.part.Parent:GetAttribute("ERMechanism")=="ShellLip"
   local needed=if onLip then .85 elseif model.Name:match("^Crown")then(if pace then 4.8 else 6)else 3.4
   local trace={model=model.Name,beforeClock=clock(),beforeState=model:GetAttribute("ERState"),onLip=onLip,needed=needed,pace=pace}
   table.insert(windowTrace,trace)
   if onLip then assert(remaining()>=needed,"Shared shell window exhausted while on "..from.part.Parent.Name)
   else untilTrue(function()return remaining()>=needed end,16,"Shell window did not open")end
   trace.afterClock=clock();trace.remaining=remaining();trace.waitSeconds=os.clock()-before
  elseif point.waitKind=="Tray"then
   local model=point.part.Parent
   local board,warning,move,exit,returnWarning=model:GetAttribute("BoardSeconds"),model:GetAttribute("WarningSeconds"),model:GetAttribute("MoveSeconds"),model:GetAttribute("ExitSeconds"),model:GetAttribute("ClosingWarningSeconds")
   local function remaining()
    local t=(clock()+(model:GetAttribute("PhaseSeconds")or 0))%(board+warning+move+exit+returnWarning+move)
    return if t<board+warning then board+warning-t else 0
   end
   local trace={model=model.Name,beforeClock=clock(),beforeState=model:GetAttribute("ERState"),needed=1.1,window="Boarding + DepartureWarning",pace=pace}
   table.insert(windowTrace,trace)
   untilTrue(function()return remaining()>=trace.needed end,18,"Tray did not offer steady boarding time")
   trace.afterClock=clock();trace.remaining=remaining();trace.waitSeconds=os.clock()-before
  elseif point.waitKind=="SideExit"then
   local model=assert(point.tray,"Side exit missing its preceding tray");local deck=from.part
   assert(deck.Parent==model,"Side exit tray/deck mismatch")
   assert(model:GetAttribute("ERState")=="Boarding"or model:GetAttribute("ERState")=="DepartureWarning","Tray boarding missed full ride start")
   local initial,rootInitial=deck.CFrame,root.Position;local relativeInitial=deck.CFrame:PointToObjectSpace(root.Position)
   local receipt={model=model.Name,startClock=clock(),samples=0,travelSamples=0,maximumLocalDrift=0,expectedDistance=model:GetAttribute("Travel").Magnitude,pace=pace}
   table.insert(carryReceipts,receipt)
   untilTrue(function()
    local support=standing();local state=model:GetAttribute("ERState")
    receipt.samples+=1
    if state=="Travel"then receipt.travelSamples+=1 end
    receipt.lastState=state;receipt.lastSupport=support and support:GetFullName()
    assert(support==deck and humanoid.FloorMaterial~=Enum.Material.Air,"Lost actual support during tray carry")
    local relative=deck.CFrame:PointToObjectSpace(root.Position)-relativeInitial
    receipt.maximumLocalDrift=math.max(receipt.maximumLocalDrift,Vector3.new(relative.X,0,relative.Z).Magnitude)
    return state=="Exit"
   end,12,"Tray did not complete the outward ride")
   receipt.endClock=clock();receipt.deckDistance=(deck.Position-initial.Position).Magnitude
   receipt.rootDistance=(root.Position-rootInitial).Magnitude
   assert(receipt.travelSamples>0 and math.abs(receipt.deckDistance-receipt.expectedDistance)<.1,"Tray did not carry for its full authored distance")
   assert(math.abs(receipt.rootDistance-receipt.expectedDistance)<1 and receipt.maximumLocalDrift<1.5,"Rider did not remain carried relative to tray")
   receipt.supportedThroughout=true
  end
  waits+=os.clock()-before
 end
 local ok,failure=xpcall(function()
  if options.placeAtStart~=false then
   char:PivotTo(CFrame.new(top(points[1].part)+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.15,0)))
   root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  end
  untilTrue(function()return supportedBy(points[1].part)and humanoid.FloorMaterial~=Enum.Material.Air end,3,"Initial support did not settle")
  for index=1,#points-1 do
   local from,to=points[index],points[index+1]
   local nextPart=points[index+2]and points[index+2].part
   if progress then progress(index,#points,from.part.Name.." -> "..to.part.Name)end
   waitWindow(to,from,index+1)
   local delta=aim(to.part,nextPart)-root.Position;local direction=Vector3.new(delta.X,0,delta.Z).Unit
   assert(supportedBy(from.part),"Lost support before "..from.part.Name)
   local takeoffSupport=standing()
   approach={part=from.part,direction=direction,inset=takeoffInset(from.part),requested=false}
   movement=direction;local began=os.clock()
   untilTrue(function()return approach.requested end,3,"Could not reach takeoff edge at "..from.part.Name)
   local launch=approach.launch
   untilTrue(function()return humanoid.FloorMaterial==Enum.Material.Air end,.65,"Jump did not leave "..from.part.Name)
   jump=false;approach=nil
   local takeoff=os.clock();local reached=false;local firstContact,firstSupport;local deadline=takeoff+1.8
   repeat
    valid()
    local target=aim(to.part,nextPart);local flat=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
    local supported=humanoid.FloorMaterial~=Enum.Material.Air and supportedBy(to.part)and(not pace or insideFootprint(to.part,root.Position))
    if supported and not firstContact then firstContact=os.clock()-takeoff;firstSupport=standing()end
    movement=if flat.Magnitude<=.5 then Vector3.zero else flat.Unit
    reached=supported and flat.Magnitude<=.9 and math.abs(root.AssemblyLinearVelocity.Y)<2
    if reached then break end
    assert(player.Character==char and humanoid.Health>0,"Character changed during traversal")
    RunService.Heartbeat:Wait()
   until os.clock()>deadline
   movement=Vector3.zero
   assert(reached,string.format("Missed %s -> %s; position %s target %s",from.part.Name,to.part.Name,tostring(root.Position),tostring(top(to.part))))
   local settle=os.clock()
   if pace then
    paceSettle={part=to.part:GetFullName(),maximumSeconds=.25,samples=0,consecutiveStable=1,transitions={}}
    local previous="Stable"
    repeat
     RunService.Heartbeat:Wait();valid()
     local support=standing()
     local supported=acceptsSupport(course,to.part,support,root.Position)
     local inside=insideFootprint(to.part,root.Position)
     local floor=humanoid.FloorMaterial~=Enum.Material.Air
     local velocity=root.AssemblyLinearVelocity.Y
     local failed={}
     if not supported then table.insert(failed,"LostPhysicalSupport")end
     if not inside then table.insert(failed,"OutsideWantedFootprint")end
     if not floor then table.insert(failed,"FloorMaterialAir")end
     if math.abs(velocity)>=2 then table.insert(failed,"VerticalVelocityAtLeast2")end
     local status=if #failed==0 then"Stable"else table.concat(failed,",")
     paceSettle.samples+=1;paceSettle.elapsed=os.clock()-settle;paceSettle.lastStatus=status
     paceSettle.support=support and support:GetFullName();paceSettle.floor=tostring(humanoid.FloorMaterial);paceSettle.verticalVelocity=velocity
     if status~=previous then
      table.insert(paceSettle.transitions,{seconds=paceSettle.elapsed,from=previous,to=status,support=paceSettle.support,
       floor=paceSettle.floor,verticalVelocity=velocity,position={root.Position.X,root.Position.Y,root.Position.Z}})
      previous=status
     end
     assert(supported and inside,"Pace settle left "..to.part.Name..": "..status)
     paceSettle.consecutiveStable=if #failed==0 then paceSettle.consecutiveStable+1 else 0
     assert(paceSettle.elapsed<=.25,string.format("Pace settle timed out on %s after %.3fs: %s; consecutive stable %d/2",
      to.part.Name,paceSettle.elapsed,status,paceSettle.consecutiveStable))
    until paceSettle.consecutiveStable>=2
   else
    repeat RunService.Heartbeat:Wait();valid();assert(supportedBy(to.part),"Slid off "..to.part.Name)until os.clock()-settle>=.12
   end
   local settleSeconds=os.clock()-settle
   local holdWalk
   if to.part.Name=="S6_ShellSpill_002"then
    local destination=contactAim(to.part)
    local startedWalk=os.clock()
    holdWalk={part=to.part:GetFullName(),from={root.Position.X,root.Position.Y,root.Position.Z},target={destination.X,destination.Y,destination.Z},samples=0}
    table.insert(walkReceipts,holdWalk)
    untilTrue(function()
     assert(standing()==to.part and humanoid.FloorMaterial~=Enum.Material.Air,"Lost physical support walking to the north feather wait")
     holdWalk.samples+=1
     local delta=(destination-root.Position)*Vector3.new(1,0,1)
     movement=if delta.Magnitude<=.3 then Vector3.zero else delta.Unit
     return delta.Magnitude<=.3
    end,1,"Supported north-wait walk did not reach its actual pad-contained target")
    movement=Vector3.zero
    local held=os.clock()
    repeat RunService.Heartbeat:Wait();valid();assert(standing()==to.part and humanoid.FloorMaterial~=Enum.Material.Air,"North feather wait lost support while settling")until os.clock()-held>=.12
    holdWalk.seconds=os.clock()-startedWalk;holdWalk.supportedThroughout=true;holdWalk.at={root.Position.X,root.Position.Y,root.Position.Z}
   end
   local actualSupport=standing()
   local landingPoint=aim(to.part,nextPart)
   table.insert(records,{from=from.part.Name,to=to.part.Name,seconds=os.clock()-began,flight=firstContact,travel=(root.Position-launch).Magnitude,
    support=actualSupport:GetFullName(),supportAlias=actualSupport~=to.part,firstSupport=firstSupport:GetFullName(),takeoffSupport=takeoffSupport:GetFullName(),
    pace=pace,landingAim={landingPoint.X,landingPoint.Y,landingPoint.Z},settleSeconds=settleSeconds,paceSettle=paceSettle,holdWalk=holdWalk})
   for _,name in ipairs(to.eggExit or{})do
    local receipt=assert(eggReceipts[name],"Egg exit without guarded entry")
    receipt.exitClock=clock();receipt.exitState=course.Obstacles.Mechanisms[name]:GetAttribute("ERState");receipt.crossed=true
   end
   if options.afterLanding then
    options.afterLanding(index+1,to,records[#records],{SetMovement=function(value)movement=value;jump=false end,Standing=standing})
   end
  end
 end,debug.traceback)
 connection:Disconnect();humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;root:SetNetworkOwnershipAuto()end
 return{ok=ok,failure=if ok then nil else failure,pace=pace,paceSettle=paceSettle,jumps=#records,records=records,seconds=os.clock()-started,windowWaitSeconds=waits,windowTrace=windowTrace,eggCrossings=eggReceipts,trayCarries=carryReceipts,supportedWalks=walkReceipts,
  final={position={root.Position.X,root.Position.Y,root.Position.Z},support=standing()and standing():GetFullName(),floor=tostring(humanoid.FloorMaterial),clock=clock()},
  method="Server-owned real avatar, ordinary walking and jumps, supported landings; optional start placement only",
  waitPolicy=if pace then"Practiced-control check: forward landing aim up to1.2stud, two consecutive stable samples within.25sec, Crown4.8 admission; body-volume egg admission, target peck admission and both authored tray carries; not minimum achievable player waiting"else"Conservative shell windows, body-volume egg admission, target peck admission, current themed sweep windows and both authored tray rides; not minimum achievable player waiting",
  limits="Scripted control and reachability; human pace, crowd, device and FPS unverified"}
end
return Test
