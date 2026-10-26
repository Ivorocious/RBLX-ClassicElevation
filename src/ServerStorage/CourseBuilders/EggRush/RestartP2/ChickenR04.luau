--!nonstrict
local Chicken={Candidate="ER_P2_R05_C01"}
local Kit=require(script.Parent.ChickenKit)
local Motion=require(script.Parent.Parent.ChickenMotion)

local function part(parent,name,size,frame,color)
 local p=Instance.new("Part");p.Name,p.Size,p.CFrame,p.Color=name,size,frame,color
 p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
 p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 p.Parent=parent;return p
end

function Chicken.Apply(root)
 local candidate=root:GetAttribute("CandidateId")
 assert(candidate=="ER_P2_R03_C04" or candidate=="ER_P2_R04_C02","Use the current Phase2 course")
 local old=root.Obstacles.Mechanisms.GuardianPeck
 local oldBody=root.Decoration.RevisionR03:FindFirstChild("GiantGuardianBody")
 local retired=Instance.new("Folder");retired.Name="ChickenBeforeR05"
 local targets=old.Targets:Clone()
 local rig=Instance.new("Model");rig.Name="GuardianPeck"
 local frame=root:GetPivot()*CFrame.new(91,18,40)*CFrame.Angles(0,-math.pi/2,0)
 rig.WorldPivot=frame
 rig:SetAttribute("ERMechanism","Peck");rig:SetAttribute("ChickenRevision","R05")
 rig:SetAttribute("NeckAnchor",Motion.Shoulder);rig:SetAttribute("NeckLinkLength",Motion.LinkLength)
 for _,key in {"RestSeconds","WarningSeconds","StrikeSeconds","ImpactSeconds","RecoverSeconds","PhaseSeconds"} do rig:SetAttribute(key,old:GetAttribute(key)) end
 targets.Parent=rig
 local first=targets:GetChildren();table.sort(first,function(a,b)return a.Name<b.Name end)
 local plate=first[1].Value
 local previous=first[#first].Value
 local pose=Motion.Pose(frame,plate.Position+Vector3.yAxis*(plate.Size.Y/2+.25),{state="Rest",alpha=0},
  {previousTarget=previous.Position+Vector3.yAxis*(previous.Size.Y/2+.25),targetIndex=1})
 Kit.Create(rig,"Body",pose.body).Name="Body"
 local head=Kit.Create(rig,"Head",pose.head);head.Name="Head"
 head:SetAttribute("BeakTip",Motion.BeakTip);head:SetAttribute("HeadNeck",Motion.HeadNeck)
 local feet=Kit.Create(rig,"Feet",frame);feet.Name="Feet"
 for _,side in {-1,1} do
  local foot=Instance.new("Model");foot.Name=if side==-1 then "Left" else "Right"
  foot.WorldPivot=frame*CFrame.new(0,0,side*8);foot.Parent=feet
  for _,p in feet:GetChildren() do
   if p:IsA("BasePart") and (if p.Name:find("-1",1,true) then -1 else 1)==side then p.Parent=foot end
  end
  foot:PivotTo(if side==-1 then pose.footLeft else pose.footRight)
 end
 local cream=Color3.fromRGB(255,242,210)
 part(rig,"NeckLower",Vector3.new(9,6,9),pose.lower,cream)
 part(rig,"NeckUpper",Vector3.new(9,6,9),pose.upper,cream)
 local roost=root.Decoration:FindFirstChild("ChickenRoostR04")
 if not roost then roost=Instance.new("Folder");roost.Name="ChickenRoostR04";roost.Parent=root.Decoration end
 local originals={}
 for _,p in root.Decoration.RevisionR02:GetChildren() do
  if p:IsA("Model") and (p.Name=="NestRing" or p.Name=="BareRock") then
   local point=root:GetPivot():PointToObjectSpace(p:GetPivot().Position)
   if math.abs(point.X-78)<.01 and math.abs(point.Z-40)<.01 then table.insert(originals,p) end
  end
 end
 for _,p in originals do
  local clone=p:Clone();clone:PivotTo(clone:GetPivot()+root:GetPivot():VectorToWorldSpace(Vector3.new(13,if p.Name=="BareRock" then 3 else 0,0)));clone.Parent=roost
  p.Parent=retired
 end
 old.Parent=retired;if oldBody then oldBody.Parent=retired end
 rig.Parent=root.Obstacles.Mechanisms
 root:SetAttribute("CandidateId",Chicken.Candidate);root:SetAttribute("ChickenRevision","R05")
 root:SetAttribute("OwnerAcceptance","Pending chicken-only review")
 return root,retired
end

return Chicken
