--!nonstrict
local Motion=require(script.Parent.ChickenMotion)
local ChickenPeck={}
local AMBER,CHARCOAL=Color3.fromRGB(255,190,40),Color3.fromRGB(62,66,72)
local STATE_ATTRIBUTES={"ERState","ERPeckTarget","ERStrike"}

function ChickenPeck.Bind(model,course,sampler)
 local body,head,feet=model.Body,model.Head,model.Feet
 local leftFoot,rightFoot=feet.Left,feet.Right
 local lower,upper=model.NeckLower,model.NeckUpper
 local frame=model:GetPivot()
 local bodyHome,headHome,feetHome=body:GetPivot(),head:GetPivot(),feet:GetPivot()
 local leftHome,rightHome=leftFoot:GetPivot(),rightFoot:GetPivot()
 local parts,contacts,attributes,targets={},{},{},{}
 for _,name in STATE_ATTRIBUTES do attributes[name]={value=model:GetAttribute(name)} end
 for _,p in model:GetDescendants() do
  if not p:IsA("BasePart") then continue end
  assert(p.Anchored and not p.CanCollide,"Chicken art must be anchored and noncolliding")
  table.insert(parts,{part=p,frame=p.CFrame})
  if p:GetAttribute("ERLethal")==true then
   assert(p:IsDescendantOf(head) and p.CanQuery and p.Transparency<1,"Only visible beak geometry is lethal")
   table.insert(contacts,p)
  end
 end
 assert(#contacts>0,"Chicken needs a visible red beak")
 local refs=model.Targets:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
 for _,ref in refs do
  local plate=ref.Value
  assert(plate and plate:IsA("BasePart") and plate:IsDescendantOf(course) and not plate:IsDescendantOf(model),"Chicken needs fixed course targets")
  assert(plate:GetAttribute("ERLethal")~=true,"Warning plates cannot apply damage")
  local sound=plate:FindFirstChild("WarningSound")
  table.insert(targets,{plate=plate,point=plate.Position+Vector3.yAxis*(plate.Size.Y/2+.25),color=plate.Color,
   sound=sound,looped=sound and sound.Looped,soundTime=sound and sound.TimePosition})
 end
 local settings={rest=model:GetAttribute("RestSeconds"),warning=model:GetAttribute("WarningSeconds"),
  strike=model:GetAttribute("StrikeSeconds"),impact=model:GetAttribute("ImpactSeconds"),recover=model:GetAttribute("RecoverSeconds"),phase=model:GetAttribute("PhaseSeconds") or 0}
 local contexts={}
 for index in targets do contexts[index]={previousTarget=targets[(index-2)%#targets+1].point} end
 local function poseFor(sample)
  return Motion.Pose(frame,targets[sample.target].point,sample,contexts[sample.target])
 end
 local duration=settings.rest+settings.warning+settings.strike+settings.impact+settings.recover
 local speed,prior=0,nil
 local sampleCount=180*#targets
 for index=0,sampleCount do
  local sample=sampler(settings,index/180*duration,#targets)
  local pose=poseFor(sample)
  if prior then speed=math.max(speed,(pose.head.Position-prior.Position).Magnitude*180/duration) end
  prior=pose.head
 end
 -- The beak descends on a straight path; the extra radius covers its turning corners.
 speed=math.max(speed*2,60)
 local controller={model=model,state=nil,target=nil,contacts=contacts,parts=parts}
 local function silence()
  for _,target in targets do if target.sound then target.sound:Stop() end end
 end
 function controller.Hold() silence() end
 function controller.Resume()
  if controller.state=="Warning" then local s=targets[controller.target].sound;if s then s:Play() end end
 end
 function controller.Stop()
  silence()
  if body.Parent then body:PivotTo(bodyHome) end
  if head.Parent then head:PivotTo(headHome) end
  if feet.Parent then feet:PivotTo(feetHome) end
  if leftFoot.Parent then leftFoot:PivotTo(leftHome) end
  if rightFoot.Parent then rightFoot:PivotTo(rightHome) end
  for _,saved in parts do if saved.part.Parent then saved.part.CFrame=saved.frame end end
  for name,saved in attributes do model:SetAttribute(name,saved.value) end
  for _,target in targets do
   if target.plate.Parent then target.plate.Color=target.color end
   if target.sound and target.sound.Parent then target.sound.Looped=target.looped;target.sound.TimePosition=target.soundTime end
  end
 end
 function controller.Advance(oldElapsed,dt,contact,hasBodies)
  local steps=if hasBodies then math.max(1,math.ceil(speed*dt/.4),math.ceil(dt*30)) else 1
  local final
  for index=1,steps do
   local sample=sampler(settings,oldElapsed+dt*index/steps,#targets)
   local pose=poseFor(sample)
   body:PivotTo(pose.body);head:PivotTo(pose.head)
   leftFoot:PivotTo(pose.footLeft);rightFoot:PivotTo(pose.footRight)
   lower.CFrame,upper.CFrame=pose.lower,pose.upper
   if sample.lethal then for _,p in contacts do contact(p,"EggRush:ChickenPeck") end end
   final=sample
  end
  if final.state~=controller.state or final.target~=controller.target then
   controller.state,controller.target=final.state,final.target
   model:SetAttribute("ERState",final.state);model:SetAttribute("ERPeckTarget",final.target);model:SetAttribute("ERStrike",final.lethal)
   silence()
   for index,target in targets do target.plate.Color=if index==final.target and (final.state=="Warning" or final.lethal) then AMBER else CHARCOAL end
   if final.state=="Warning" then local sound=targets[final.target].sound;if sound then sound.Looped=true;sound:Play() end end
  end
  return steps
 end
 return controller
end

return ChickenPeck
