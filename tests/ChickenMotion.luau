local fs,luau,roblox=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox")
local environment={}
for key,value in roblox do environment[key]=value end
local nativeCFrame=table.clone(roblox.CFrame)
function nativeCFrame.lookAt(origin,target,up)
 local look=(target-origin).Unit
 local right=look:Cross(up or roblox.Vector3.yAxis).Unit
 return roblox.CFrame.fromMatrix(origin,right,right:Cross(look),-look)
end
environment.CFrame=nativeCFrame
local motion=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/ChickenMotion.luau"),{environment=environment})()
local V,CF=roblox.Vector3.new,nativeCFrame
local root=CF.new(91,18,40)*CF.Angles(0,-math.pi/2,0)
local checks=0
local maxSpan,maxPitch=0,0
local function check(value,message)checks+=1;assert(value,message)end
local targets={V(135,28.32,40),V(121.5,29.32,26),V(87,23.32,85)}
local contexts={}
for index in targets do contexts[index]={previousTarget=targets[(index-2)%#targets+1]}end
for targetIndex,target in targets do
 for _,state in {"Rest","Warning","Pecking","Impact","Recovering"} do
  local steps=300
  for step=0,steps do
   local ok,pose=pcall(motion.Pose,root,target,{state=state,alpha=if steps==0 then 0 else step/steps},contexts[targetIndex])
   assert(ok,string.format("Target %s state %s sample%d: %s",tostring(target),state,step,tostring(pose)))
   check(math.abs((pose.elbow-pose.shoulder).Magnitude-6)<.0001,"Fixed lower neck length")
   check(math.abs((pose.headNeck-pose.elbow).Magnitude-6)<.0001,"Fixed upper neck length")
   check((pose.body.Position-root.Position).Magnitude<.0001,"Hip stays planted")
   local lowTop=pose.lower.Position+pose.lower.UpVector*3
   local highBottom=pose.upper.Position-pose.upper.UpVector*3
   check((lowTop-highBottom).Magnitude<.0001,"Neck joins without a gap")
   local left,right=root:PointToObjectSpace(pose.footLeft.Position),root:PointToObjectSpace(pose.footRight.Position)
   check(math.abs(V(left.X,0,left.Z).Magnitude-8)<.0001 and math.abs(V(right.X,0,right.Z).Magnitude-8)<.0001,"Feet follow fixed radius rather than sliding across hip")
   check(pose.footLeftLift>=-1e-8 and pose.footLeftLift<=1.5 and pose.footRightLift>=-1e-8 and pose.footRightLift<=1.5,"Authored shuffle lift")
   check(math.min(pose.footLeftLift,pose.footRightLift)<.0001,"One foot stays planted")
   for _,foot in {pose.footLeft,pose.footRight} do
    local embedded=0
    for _,x in {-1.5,0,1.5}do for _,z in {-1.5,0,1.5}do
     local at=pose.body:PointToObjectSpace(foot:PointToWorldSpace(V(x,7.15,z)))
     local inBelly=at.X>=-14 and at.X<=6 and at.Y>=2 and at.Y<=12 and math.abs(at.Z)<=11
     local inCore=at.X>=-17.5 and at.X<=7.5 and at.Y>=7 and at.Y<=25 and math.abs(at.Z)<=14
     if inBelly or inCore then embedded+=1 end
    end end
    check(embedded>=3,"Leg top stays substantially embedded in the new tucked belly/core through the shuffle")
   end
   if state=="Impact" then check((pose.head:PointToWorldSpace(motion.BeakTip)-target).Magnitude<.0001,"Beak tip reaches original court target")end
   maxSpan=math.max(maxSpan,(pose.headNeck-pose.shoulder).Magnitude)
   maxPitch=math.max(maxPitch,pose.bodyPitchDegrees)
  end
 end
end
print(string.format("ChickenMotion: %d short-neck, planted-hip, connection and target checks pass; max span %.5f, max bow %.5f degrees; native silhouette/contact not simulated",checks,maxSpan,maxPitch))

local states={"Rest","Warning","Pecking","Impact","Recovering"}
local function poseAt(targetIndex,state,alpha)
 return motion.Pose(root,targets[targetIndex],{state=state,alpha=alpha},contexts[targetIndex])
end
for targetIndex,target in targets do
 local previous=(targetIndex-2)%#targets+1
 local rest=poseAt(targetIndex,"Rest",0)
 check((rest.head.Position-motion.AttentionFrame(root,targets[previous]).Position).Magnitude<.0001,"Rest retains the previous target's attention")
 check((rest.head.Position-(root*motion.HomeHead).Position).Magnitude>1,"Rest does not reset to the fixed authored home")
 check((poseAt(targetIndex,"Rest",.35).head.Position-rest.head.Position).Magnitude>.4,"Rest visibly watches toward the next target")
 local mid=poseAt(targetIndex,"Rest",.48)
 check(mid.footLeft.LookVector:Dot(mid.footRight.LookVector)<.999,"The feet step separately rather than turning as one plate")
 for stateIndex,state in states do
  local nextState=states[stateIndex%#states+1]
  local nextTarget=if state=="Recovering"then targetIndex%#targets+1 else targetIndex
  local before,after=poseAt(targetIndex,state,1),poseAt(nextTarget,nextState,0)
  for _,part in {"head","body","lower","upper","footLeft","footRight"}do
   check((before[part].Position-after[part].Position).Magnitude<.00015,"Position continuity at "..state.."/"..nextState.."/"..part)
   check(before[part].LookVector:Dot(after[part].LookVector)>.99999,"Rotation continuity at "..state.."/"..nextState.."/"..part)
  end
  local prior,later=poseAt(targetIndex,state,.999),poseAt(nextTarget,nextState,.001)
  check((before.head.Position-prior.head.Position).Magnitude<.002 and(after.head.Position-later.head.Position).Magnitude<.002,"Smooth head speed at "..state.."/"..nextState)
 end
 local again=poseAt(targetIndex,"Rest",.618)
 poseAt(targetIndex%#targets+1,"Pecking",.4)
 check((again.head.Position-poseAt(targetIndex,"Rest",.618).head.Position).Magnitude<1e-6,"Arbitrary sample order gives the same pose")
end
print("ChickenMotion: previous-target continuity, no home reset, staggered stepping and deterministic sampling pass")

local serde=require("@lune/serde")
local manifestPath="assets/egg_rush_circuit/phase2/chicken_r05/candidate_a02/manifest.json"
local manifest=serde.decode("json",fs.readFile(manifestPath))
local geometry=serde.decode("json",fs.readFile("docs/artifacts/egg-rush-circuit/phase2/revision-r03/candidate-c04-geometry.json"))
local function frame(row)
 local r=row.rotationMatrix
 return CF.new(row.position[1],row.position[2],row.position[3],table.unpack(r))
end
local function bounds(cf,size)
 return {cf=cf,half=size/2,radius=size.Magnitude/2,axes={cf.RightVector,cf.UpVector,cf.ZVector}}
end
local function overlap(a,b)
 local delta=b.cf.Position-a.cf.Position
 if delta.Magnitude>a.radius+b.radius then return false end
 local axes={a.axes[1],a.axes[2],a.axes[3],b.axes[1],b.axes[2],b.axes[3]}
 for _,x in a.axes do for _,y in b.axes do table.insert(axes,x:Cross(y))end end
 for _,axis in axes do if axis.Magnitude>1e-6 then
  local ar,br=0,0
  for i=1,3 do ar+=math.abs(axis:Dot(a.axes[i]))*({a.half.X,a.half.Y,a.half.Z})[i];br+=math.abs(axis:Dot(b.axes[i]))*({b.half.X,b.half.Y,b.half.Z})[i]end
  if math.abs(delta:Dot(axis))>ar+br+1e-5 then return false end
 end end
 return true
end
local used={}
for _,route in geometry.routes do for _,ref in route do used[ref.id]=true end end
local stands={}
for index,p in geometry.parts do if used[index] and not p.moving then
 local cf=CF.new(table.unpack(p.cf))
 local at=cf.Position+cf.UpVector*(p.size[2]/2+2.95)
 local box=bounds(CF.new(at)*cf.Rotation,V(3.3,5.5,4.2));box.name=p.name
 table.insert(stands,box)
end end
local definitions={}
for _,group in {"Body","Head","Feet"}do
 for _,row in manifest.templates[group].parts do table.insert(definitions,{group=group,name=row.name,frame=frame(row),size=V(table.unpack(row.size))})end
end
local report={method="Analytic full-rig boxes against fixed landing-centered body boxes; intended active-pad head/neck contact excluded; no engine collision/player-camera proof",manifest=manifestPath,samples=0,overlaps={}}
local seen={}
local targetNames={"S5_Rookery_006","E4_RoostCut_004","S5_TailBand_003"}
for targetIndex,target in targets do
 for _,state in {"Rest","Warning","Pecking","Impact","Recovering"} do
  local steps=120
  for step=0,steps do
  local alpha=if steps==0 then 0 else step/steps
  local pose=poseAt(targetIndex,state,alpha);report.samples+=1
  local boxes={}
  for _,definition in definitions do
   local parentFrame=if definition.group=="Body"then pose.body else pose.head
   if definition.group=="Feet"then
    local side=if definition.name:sub(-2)=="-1"then -1 else 1
    parentFrame=(if side<0 then pose.footLeft else pose.footRight)*CF.new(0,0,-side*8)
   end
   local box=bounds(parentFrame*definition.frame,definition.size);box.group=definition.group;box.name=definition.name;table.insert(boxes,box)
  end
  for _,key in {"lower","upper"}do local box=bounds(pose[key],V(9,6,9));box.group="Neck";box.name=key;table.insert(boxes,box)end
  for _,box in boxes do
   for _,standing in stands do if not((box.group=="Head"or box.group=="Neck")and standing.name==targetNames[targetIndex]and(state=="Pecking"or state=="Impact"or state=="Recovering"))and overlap(box,standing)then
    local key=targetIndex..state..box.name..standing.name
    if not seen[key]then seen[key]=true;table.insert(report.overlaps,{target=targetIndex,state=state,alpha=alpha,part=box.group.."/"..box.name,landing=standing.name})end
   end end
  end
 end end
end
local folder="docs/artifacts/egg-rush-circuit/phase2/chicken-r05"
if not fs.isDir(folder)then fs.writeDir(folder)end
fs.writeFile(folder.."/motion-envelope.json",serde.encode("json",report,true))
print(string.format("Full rig envelope: %d poses, %d landing boxes, %d unique non-target overlaps",report.samples,#stands,#report.overlaps))
for index=1,math.min(10,#report.overlaps)do print(report.overlaps[index])end
assert(#report.overlaps==0,"Chicken enters a neighboring route body's standing space")
