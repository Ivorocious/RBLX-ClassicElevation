local fs, luau, roblox = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
roblox.implementMethod("Model","GetPivot",function(model)return model.WorldPivotData end)
local environment = {}
for name, value in roblox do environment[name] = value end
local nativeCFrame=table.clone(roblox.CFrame)
function nativeCFrame.lookAt(origin,target,up)
 local look=(target-origin).Unit;local right=look:Cross(up or roblox.Vector3.yAxis).Unit
 return roblox.CFrame.fromMatrix(origin,right,right:Cross(look),-look)
end
environment.CFrame=nativeCFrame
environment.game = {GetService = function() return {} end}
local traversal = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/NativeTraversal.luau"), {environment = environment})()
local runtime = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/Runtime.luau"), {environment = environment})()
local roots = roblox.deserializeModel(fs.readFile("docs/artifacts/egg-rush-circuit/phase2/chicken-r05/recovery/er-p2-r05-c01-chicken-and-course.rbxm"))
local course = roots[1]
assert(course:GetAttribute("CandidateId") == "ER_P2_R05_C01")
-- Lune does not derive BasePart.Position from imported CFrame.
for _, part in course:GetDescendants() do if part:IsA("BasePart") then part.Position = part.CFrame.Position end end
local checks = 0
local function check(value, message) checks += 1; assert(value, message) end
local function top(part)return part.Position+part.CFrame.UpVector*part.Size.Y/2 end
local Vector3,CFrame=roblox.Vector3,roblox.CFrame
local activeAims={}
local function sweepAim(part)return activeAims[part]or top(part)end
local function takeoffInset(part)return if part.Name=="S6_ShellSpill_003"then 2.5 else .55 end
-- The 3.3 x 5.5 x 4.2 probe and 7.2-high parabola are a geometry check, not actual avatar physics.
local function jumpBodies(from,to,aims)
 local a,b=(aims and aims[from])or sweepAim(from),(aims and aims[to])or sweepAim(to)
 local direction=(b-a)*Vector3.new(1,0,1);direction=direction.Unit
 local localDirection=from.CFrame:VectorToObjectSpace(direction)
 local localPosition=from.CFrame:PointToObjectSpace(a)
 local edge=math.huge
 for _,axis in ipairs({"X","Z"})do
  if math.abs(localDirection[axis])>.001 then edge=math.min(edge,(math.sign(localDirection[axis])*from.Size[axis]/2-localPosition[axis])/localDirection[axis])end
 end
 local launch=a+direction*math.max(0,edge-takeoffInset(from))
 local bodies={}
 for step=0,20 do
  local t=step/20
  table.insert(bodies,a:Lerp(launch,t)+Vector3.yAxis*2.75)
  table.insert(bodies,launch:Lerp(b,t)+Vector3.yAxis*(2.75+28.8*t*(1-t)))
 end
 return bodies
end
local function sweepTouches(record,alpha,bodies)
 local frame=record.start*CFrame.fromAxisAngle(record.axis,record.angle*alpha)
 for _,part in ipairs(record.parts)do
  local cf=frame*part.frame
  local half=part.size/2+Vector3.new(
   1.65*math.abs(cf.RightVector.X)+2.1*math.abs(cf.RightVector.Z)+2.75*math.abs(cf.RightVector.Y),
   1.65*math.abs(cf.UpVector.X)+2.1*math.abs(cf.UpVector.Z)+2.75*math.abs(cf.UpVector.Y),
   1.65*math.abs(cf.LookVector.X)+2.1*math.abs(cf.LookVector.Z)+2.75*math.abs(cf.LookVector.Y))
  local extent=Vector3.new(
   math.abs(cf.RightVector.X)*part.size.X+math.abs(cf.UpVector.X)*part.size.Y+math.abs(cf.LookVector.X)*part.size.Z,
   math.abs(cf.RightVector.Y)*part.size.X+math.abs(cf.UpVector.Y)*part.size.Y+math.abs(cf.LookVector.Y)*part.size.Z,
   math.abs(cf.RightVector.Z)*part.size.X+math.abs(cf.UpVector.Z)*part.size.Y+math.abs(cf.LookVector.Z)*part.size.Z)/2+Vector3.new(1.65,2.75,2.1)
  for _,body in ipairs(bodies)do
   local delta=body-cf.Position
   if math.abs(delta.X)>extent.X or math.abs(delta.Y)>extent.Y or math.abs(delta.Z)>extent.Z then continue end
   local p=cf:PointToObjectSpace(body)
   if math.abs(p.X)<=half.X and math.abs(p.Y)<=half.Y and math.abs(p.Z)<=half.Z then return true end
  end
 end
 return false
end
for _, line in {"Normal", "Expert"} do
 local points = traversal.Points(course, line)
 local admissions,aims=traversal.SweepAdmissions(course,points)
 activeAims=aims
 local covered={}
 for _,admission in admissions do
  covered[admission.model.Name]=true
  local model=admission.model
  local pivot=model:GetPivot()
  local record={start=pivot,axis=model:GetAttribute("RotationAxis"),angle=math.rad(model:GetAttribute("SweepAngleDegrees")),parts={}}
  for _,part in model:GetDescendants()do if part:IsA("BasePart")and part:GetAttribute("ERLethal")==true then table.insert(record.parts,{frame=pivot:ToObjectSpace(part.CFrame),size=part.Size})end end
  for index=admission.first,admission.last do
   local landingAims=table.clone(aims)
   if admission.model.Name=="ReturnFeatherSwing"then landingAims[points[index].part]=traversal.PointAim(points[index].part,nil,line=="Expert")end
   local bodies=jumpBodies(points[index-1].part,points[index].part,landingAims)
   if admission.observeOnly then
    for step=0,20 do check(not sweepTouches(record,step/20,bodies),"Shutter clear-side choice avoids the sampled sweep")end
   else check(not sweepTouches(record,admission.endpoint,bodies),"Selected existing sweep endpoint clears the sampled body path")end
  end
  local settings=admission.settings
  if not admission.observeOnly then
   local waitPart=points[admission.first-1].part
   local body=(aims[waitPart]or top(waitPart))+Vector3.yAxis*2.75
   for step=0,20 do check(not sweepTouches(record,step/20,{body}),"Sweep wait stays outside the sampled complete envelope")end
   if model.Name=="ReturnFeatherSwing"then
    local destination=points[admission.last].part
    local held=(aims[destination]or top(destination))+Vector3.yAxis*2.75
    for step=0,20 do check(not sweepTouches(record,step/20,{held}),"Feather side landing remains clear while waiting for next feeder")end
   end
   local available=if admission.endpoint==0 then settings.rest+settings.warning else settings.open+settings.closingWarning
   check(admission.needed<available,"Actual authored parked duration covers this bounded crossing")
   local at=if admission.endpoint==0 then .01 else settings.rest+settings.warning+settings.move+.01
   for offset=0,admission.needed,.05 do
    local alpha,state=runtime.Sample("Tail",settings,at-settings.phase+offset)
    check(math.abs(alpha-admission.endpoint)<.001,"Unchanged runtime sampler stays at selected clear endpoint")
   end
  end
 end
 for _,name in {"ShellToothShutter","IncubatorFeederSweep","ReturnFeatherSwing","ReturnFeederSweep"}do check(covered[name],line.." accounts for current "..name)end
 check(covered.NestFeederSweep==(line=="Normal"or nil),"Nest sweep only tags its actual route")
 for part,aim in aims do
  local p=part.CFrame:PointToObjectSpace(aim)
  check(math.abs(p.X)<=part.Size.X/2-.5 and math.abs(p.Z)<=part.Size.Z/2-.25 and math.abs(p.Y-part.Size.Y/2)<.01,"Driver aim stays on actual supported pad")
 end
 local refs = course.Routes["Revision" .. line]:GetChildren()
 table.sort(refs, function(a,b) return a.Name < b.Name end)
 check(#points == #refs, line .. " preserves every accepted reference")
 local eggs, exits, pecks = {}, {}, {}
 for index, point in points do
  check(point.part == refs[index].Value, line .. " follows reference " .. index)
  check(point.waitKind ~= "Tail", "No obsolete tail admission")
  for _, actor in point.eggs or {} do eggs[actor.model.Name] = true end
  if point.waitKind == "SideExit" then
   exits[point.tray.Name] = true
   check(point.tray == points[index-1].part.Parent, "Exit uses the deck actually just ridden")
  end
  if point.peck then pecks[point.peck.target] = true end
 end
 for _, name in {"EggBand1", "EggBand1_2", "EggBand1_3", "EggBand2", "EggBand2_2", "EggBand2_3"} do check(eggs[name], line .. " observes " .. name) end
 check(exits.SidewaysTray and exits.SidewaysTrayB, "Both authored tray exits")
 check(pecks[if line == "Normal" then 1 else 2] and pecks[3], "Current route's two chicken targets")
end
local base=traversal.Points(course,"Normal")
local _,normalAims=traversal.SweepAdmissions(course,base);activeAims=normalAims
local function staticRecord(name)
 local hazard=assert(course.Obstacles.ThemedHazards:FindFirstChild(name))
 local record={start=CFrame.identity,axis=Vector3.yAxis,angle=0,parts={}}
 for _,part in hazard:GetDescendants()do
  if part:IsA("BasePart")and part:GetAttribute("ERLethal")==true then table.insert(record.parts,{frame=part.CFrame,size=part.Size})end
 end
 return record
end
local function boxGap(a,asize,b,bsize)
 local aa,ba={a.RightVector,a.UpVector,a.LookVector},{b.RightVector,b.UpVector,b.LookVector}
 local axes={aa[1],aa[2],aa[3],ba[1],ba[2],ba[3]}
 for _,u in aa do for _,v in ba do local cross=u:Cross(v);if cross.Magnitude>1e-5 then table.insert(axes,cross.Unit)end end end
 local av,bv={asize.X,asize.Y,asize.Z},{bsize.X,bsize.Y,bsize.Z}
 local delta=b.Position-a.Position
 local gap=-math.huge
 for _,axis in axes do
  local ar,br=0,0
  for index,u in aa do ar+=math.abs(axis:Dot(u))*av[index]/2 end
  for index,u in ba do br+=math.abs(axis:Dot(u))*bv[index]/2 end
  gap=math.max(gap,math.abs(delta:Dot(axis))-ar-br)
 end
 return gap
end
local measured=require("@lune/serde").decode("json",fs.readFile("docs/artifacts/egg-rush-circuit/phase3/current-w01/actual-racer-body.json"))
local rootHeight=measured.hipHeight
for _,part in measured.rig do if part.name=="HumanoidRootPart"then rootHeight+=part.size[2]/2 end end
local measuredRig={}
for _,part in measured.rig do
 if part.name~="HumanoidRootPart"then table.insert(measuredRig,{name=part.name,frame=CFrame.new(table.unpack(part.frame)),size=Vector3.new(table.unpack(part.size))})end
end
local fixed={
 {hazard="NestHotGrate",from="S1_Nestyard_008",to="S1_Nestyard_009",after="S1_Nestyard_010",finish="S1_Nestyard_011"},
 {hazard="ShellApproachTeeth",from="S3_ShellApproach_002",to="S3_ShellApproach_003",after="S3_ShellApproach_004",finish="S3_ShellApproach_005"},
 {hazard="RoostFeatherPinch",from="S5_Rookery_002",to="S5_Rookery_003",after="S5_Rookery_004",finish="S5_Rookery_005"},
}
local byName={};for _,point in base do byName[point.part.Name]=point.part end
for _,case in fixed do
 local record=staticRecord(case.hazard)
 activeAims={}
 check(sweepTouches(record,0,jumpBodies(byName[case.from],byName[case.to]))or sweepTouches(record,0,jumpBodies(byName[case.to],byName[case.after])),"Centered red-contact path is reproduced by the bounded body probe")
 activeAims=normalAims
 local parts={byName[case.from],byName[case.to],byName[case.after],byName[case.finish]}
 local minimum=math.huge
 for index=1,#parts-1 do
  local from,to=parts[index],parts[index+1]
  local bodies=jumpBodies(from,to)
  check(not sweepTouches(record,0,bodies),"Contained red-contact flank clears approach, flight and exit body samples")
  local delta=(sweepAim(to)-sweepAim(from))*Vector3.new(1,0,1)
  local look=delta.Unit;local right=look:Cross(Vector3.yAxis)
  for _,body in bodies do
   local root=CFrame.fromMatrix(body+Vector3.yAxis*(rootHeight-2.75),right,Vector3.yAxis,-look)
   for _,rig in measuredRig do for _,red in record.parts do
    local gap=boxGap(root*rig.frame,rig.size,red.frame,red.size)
    minimum=math.min(minimum,gap)
    check(gap>.01,"Measured off-center collider/recorded body parts clear exact static red boxes")
   end end
  end
 end
 print(string.format("%s: measured recorded-body minimum separation %.3f studs; feet/legs use the separate conservative probe",case.hazard,minimum))
end
local focused=require("@lune/serde").decode("json",fs.readFile("docs/artifacts/egg-rush-circuit/phase3/current-w01/nest-red-focused-r03.json"))
check(focused.ok and #focused.trace==24,"Actual successful body-motion reference")
for _,snapshot in focused.trace do check(#snapshot.redOverlaps==0,"Passed native red trace has no recorded overlap")end
local function measuredBounds(snapshot)
 local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,part in snapshot.rig do
  if not part.bodyContact or not part.visible or not part.canQuery then continue end
  local cf,size=CFrame.new(table.unpack(part.frame)),Vector3.new(table.unpack(part.size))
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local at=cf*(size*Vector3.new(x,y,z)/2)
   low=Vector3.new(math.min(low.X,at.X),math.min(low.Y,at.Y),math.min(low.Z,at.Z));high=Vector3.new(math.max(high.X,at.X),math.max(high.Y,at.Y),math.max(high.Z,at.Z))
  end end end
 end
 return low,high
end
local low,high=measuredBounds(focused.after)
local padding=Vector3.new(.5,1,.75);low-=padding;high+=padding
for _,snapshot in focused.trace do
 local a,b=measuredBounds(snapshot)
 check(a.X>=low.X and a.Y>=low.Y and a.Z>=low.Z and b.X<=high.X and b.Y<=high.Y and b.Z<=high.Z,"Driver padding covers every recorded walking/jumping limb envelope")
end
local actors=traversal.EggActors(course,0,runtime.Sample)
for _,clock in {0.5,3.25,7.7}do
 local moving=course:Clone()
 for name,actor in actors do
  local model=moving.Obstacles.Mechanisms[name]
  local old=model:GetPivot()
  local alpha,state=runtime.Sample("EggRoller",actor.settings,clock)
  local frame=actor.start*CFrame.new(actor.travel*alpha)*CFrame.fromAxisAngle(actor.axis,2*math.pi*actor.turns*alpha)
  for _,part in model:GetDescendants()do if part:IsA("BasePart")then part.CFrame=frame*old:ToObjectSpace(part.CFrame);part.Position=part.CFrame.Position end end
  model.WorldPivotData=frame;model:SetAttribute("ERState",state)
 end
 local reconstructed=traversal.EggActors(moving,clock,runtime.Sample)
 for name,original in actors do
  local record=reconstructed[name]
  check((record.start.Position-original.start.Position).Magnitude<.002,"Live rolling snapshot recovers the actual fixed release origin")
  check(record.start.RightVector:Dot(original.start.RightVector)>.99999 and record.start.UpVector:Dot(original.start.UpVector)>.99999,"Live rolling snapshot removes translation and roll in the correct order")
  check(#record.parts==#original.parts,"Every current visible contact shape retained")
  for index,part in record.parts do check((part.frame.Position-original.parts[index].frame.Position).Magnitude<.002,"Contact-box local shape survives a rolling snapshot")end
 end
end
local rootHeight=focused.after.root[2]-top(byName.S1_Nestyard_011).Y
for band=1,2 do
 local entry
 for index,point in base do if point.eggs and point.eggs[1].model:GetAttribute("EggBand")==band then entry=index;break end end
 check(entry~=nil,"Current band crossing reference exists")
 local group={};for _,egg in base[entry].eggs do table.insert(group,actors[egg.model.Name])end
 check(#group==3,"All three staggered actors guard their band")
 local position=sweepAim(base[entry-1].part)+Vector3.yAxis*rootHeight
 local path,duration=traversal.EggPath(base,entry-1,entry+base[entry].eggs[1].hops-1,position,low,high,sweepAim)
 check(#path>30 and duration>1 and duration<3,"Forecast includes actual body volume through both approach/flight/landing hops")
 local clearTimes={}
 for step=0,389 do local clock=step*.02;if traversal.EggClear(group,path,clock,runtime.Sample)then table.insert(clearTimes,clock)end end
 check(#clearTimes>0,"Staggered actors offer moving-geometry clearance without a whole-band parked window")
 for _,clock in clearTimes do check(traversal.EggClear(group,path,clock,runtime.Sample),"Actual phase/roll geometry clears observed padded limb envelopes")end
 if band==1 then
  local clear,actor=traversal.EggClear(group,path,92.14727725461125,runtime.Sample)
  check(not clear and actor=="EggBand1_3","Observed failed entry clock predicts the actual third-actor conflict")
 end
 print(string.format("Band%d: %d sampled admitted clocks per7.8s; %.3fs padded body path; first admission %.2fs",band,#clearTimes,duration,clearTimes[1]))
end
local returnModels={course.Obstacles.Mechanisms.ReturnFeatherSwing,course.Obstacles.Mechanisms.ReturnFeederSweep}
local function extent(frame,size)
 return Vector3.new(math.abs(frame.RightVector.X)*size.X+math.abs(frame.UpVector.X)*size.Y+math.abs(frame.LookVector.X)*size.Z,math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z,math.abs(frame.RightVector.Z)*size.X+math.abs(frame.UpVector.Z)*size.Y+math.abs(frame.LookVector.Z)*size.Z)/2
end
local function tailBoxes(model,alpha)
 local pivot=model:GetPivot();local frame=pivot*CFrame.fromAxisAngle(model:GetAttribute("RotationAxis"),math.rad(model:GetAttribute("SweepAngleDegrees"))*alpha)
 local out={}
 for _,part in model:GetDescendants()do if part:IsA("BasePart")and part:GetAttribute("ERLethal")then table.insert(out,{frame=frame*pivot:ToObjectSpace(part.CFrame),size=part.Size})end end
 return out
end
local function overlapsBody(boxes,center,bodyHalf)
 for _,part in boxes do
  local d=part.frame.Position-center;local h=extent(part.frame,part.size)+bodyHalf
  if math.abs(d.X)<h.X and math.abs(d.Y)<h.Y and math.abs(d.Z)<h.Z then return true end
 end
 return false
end
local pad=byName.S6_ShellSpill_002
local previous=byName.S6_ShellSpill_001
local nextPad=byName.S6_ShellSpill_003
local boxCenter,boxSize=(low+high)/2,high-low
local hold=sweepAim(pad)
local incoming=(hold-sweepAim(previous))*Vector3.new(1,0,1)
local outgoing=(sweepAim(nextPad)-hold)*Vector3.new(1,0,1)
local landed=traversal.PointAim(pad,nil,false)
local prior=require("@lune/serde").decode("json",fs.readFile("docs/artifacts/egg-rush-circuit/phase3/current-w03/normal-continuous-w03-c02-r06.json"))
local passedLanding
for _,record in prior.driver.records do if record.to=="S6_ShellSpill_002"then passedLanding=record end end
check(passedLanding~=nil and(Vector3.new(table.unpack(passedLanding.landingAim))-landed).Magnitude<.001,"Incoming return jump uses the exact previously native-supported landing point")
check(math.abs((hold-landed).Magnitude-1.925)<.001,"Only a1.925stud actual walk separates the old landing and north hold")
for step=0,20 do
 local at=pad.CFrame:PointToObjectSpace(landed:Lerp(hold,step/20))
 check(math.abs(at.X)<=pad.Size.X/2-.64 and math.abs(at.Z)<=pad.Size.Z/2-.64,"Entire reposition walk stays inside the same actual support footprint")
end
local featherAdmission
for _,admission in traversal.SweepAdmissions(course,base)do if admission.model.Name=="ReturnFeatherSwing"then featherAdmission=admission end end
check(featherAdmission and featherAdmission.needed==2,"Feather admission reserves the landing, supported move and settling")
check(passedLanding.seconds+(hold-landed).Magnitude/16+.24<featherAdmission.needed,"Actual passed jump plus ordinary walk and settle fit reserved unchanged far-pose time")
local oldHold=pad.CFrame*Vector3.new(.5*(pad.Size.X/2-.65),pad.Size.Y/2,0)
local oldRotation=nativeCFrame.lookAt(Vector3.zero,(oldHold-top(previous))*Vector3.new(1,0,1)).Rotation
local oldCenter=oldHold+Vector3.yAxis*3.18+oldRotation:VectorToWorldSpace(boxCenter)
local oldHalf=extent(oldRotation,boxSize)
local oldBlocked=false
for step=0,100 do if overlapsBody(tailBoxes(returnModels[1],step/100),oldCenter,oldHalf)then oldBlocked=true;break end end
check(oldBlocked,"Full observed rig reproduces the unsafe former feather waiting flank")
for step=0,4 do
 local direction=incoming.Unit:Lerp(outgoing.Unit,step/4).Unit
 local rotation=nativeCFrame.lookAt(Vector3.zero,direction).Rotation
 for _,height in {3.18,rootHeight}do
  local center=hold+Vector3.yAxis*height+rotation:VectorToWorldSpace(boxCenter)
  local bodyHalf=extent(rotation,boxSize)
  for _,model in returnModels do for pose=0,100 do
   check(not overlapsBody(tailBoxes(model,pose/100),center,bodyHalf),"North supported hold clears BOTH complete sweep envelopes with padded full-body bounds")
  end end
 end
end
-- The complete body box is too coarse near a low shaft, so preserve each observed limb's actual height.
local returnParts={pad,nextPad,byName.S6_ShellSpill_004}
local feederFar=tailBoxes(returnModels[2],1)
for index=1,2 do
 local from,to=returnParts[index],returnParts[index+1]
 local path=traversal.EggPath({{part=from},{part=to}},1,2,sweepAim(from)+Vector3.yAxis*3.18,low,high,sweepAim)
 local direction=(sweepAim(to)-sweepAim(from))*Vector3.new(1,0,1)
 local rotation=nativeCFrame.lookAt(Vector3.zero,direction.Unit).Rotation
 local minimum=math.huge
 for _,sample in path do
  local at=(sample.low+sample.high)/2-rotation:VectorToWorldSpace(boxCenter)
  local frame=CFrame.new(at)*rotation
  for _,pose in focused.trace do for _,body in pose.rig do if body.bodyContact and body.visible and body.canQuery then
   local cf=frame*CFrame.new(table.unpack(body.frame));local size=Vector3.new(table.unpack(body.size))+Vector3.one*.1
   for _,red in feederFar do minimum=math.min(minimum,boxGap(cf,size,red.frame,red.size))end
  end end end
 end
 check(minimum>.1,"Every recorded padded visible limb clears the feeder's selected far pose through the planned crossing")
 print(string.format("Return hop%d: padded recorded-limb minimum feeder separation %.3f studs",index+1,minimum))
end
local joined={base[1]}
for lap=1,3 do for index=2,#base do table.insert(joined,base[index])end end
local repeated=traversal.SweepAdmissions(course,joined)
check(#repeated==15,"All five current sweep observations/admissions repeat once per physical lap")
for section, bounds in {Rookery={"CP3_Pocket","CP4_Pocket"}, Incubator={"Shell_ExitWait","CP3_Pocket"}, Shellworks={"CP2_Pocket","Shell_ExitWait"}} do
 local points = traversal.Points(course,"Normal",section)
 check(points[1].part.Name == bounds[1] and points[#points].part.Name == bounds[2], section .. " actual current section")
end
local ref = course.Routes.RevisionNormal["002"]
local original = ref.Value
ref.Value = course.Start
check(traversal.Points(course,"Normal")[2].part == course.Start,"Later accepted route reference edits are read directly")
ref.Value = original
for _, file in {"tests/studio/EggRushPhase3Peck.luau", "tests/studio/EggRushPhase3Normal.luau", "tools/egg-rush-circuit/phase3/RunFocused.server.luau", "tests/studio/EggRushPhase3NestRed.luau", "tests/studio/EggRushPhase3EggBand1.luau", "tests/studio/EggRushPhase3ReturnSweeps.luau"} do
 assert(luau.load(fs.readFile(file),{debugName=file}))
end
print(string.format("Egg Rush current traversal: %d checks passed; all five native preparation modules and the bounded runner compile. Physics remains a Studio check.",checks))
