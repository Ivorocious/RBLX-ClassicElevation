--!nonstrict
local Finish=require(script.Parent.Finish)
local Build={}
local function visibleContacts(model)
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")then
   p:SetAttribute("ERLethal",true);p.CanQuery=true
   assert(p:IsA("MeshPart")and p.CollisionFidelity==Enum.CollisionFidelity.PreciseConvexDecomposition,"Prepare visible mesh contacts first")
  end
 end
end
local function bounds(model)
 local low,high=Vector3.one*math.huge,-Vector3.one*math.huge
 for _,p in ipairs(model:GetDescendants())do
  if not p:IsA("BasePart")then continue end
  for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
   local point=p.CFrame*Vector3.new(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)
   low=Vector3.new(math.min(low.X,point.X),math.min(low.Y,point.Y),math.min(low.Z,point.Z))
   high=Vector3.new(math.max(high.X,point.X),math.max(high.Y,point.Y),math.max(high.Z,point.Z))
  end end end
 end
 return low,high
end
function Build.Apply(root,kit)
 assert(root:GetAttribute("EROwned")==true and not root:GetAttribute("ERMechanismArt"))
 local mechanisms=root.Obstacles.Mechanisms
 for i,name in ipairs({"EggCoral","EggMint"})do
  local m=mechanisms["EggBand"..i];local rough=m.RoughEgg
  local egg=Finish.Skin(kit,name,m,m:GetPivot()*CFrame.new(0,-4,0),Vector3.new(7/6,1,7/6))
  visibleContacts(egg)
  rough:SetAttribute("ERLethal",nil);rough.Transparency=1;rough.CanQuery=false
 end
 local tail=mechanisms.GuardianTail;local rough=tail.RoughTail
 local low,high=bounds(kit.GuardianSweepTail)
 assert((low-Vector3.new(0,-1.5,-4)).Magnitude<.05 and(high-Vector3.new(29.25,3.5,4)).Magnitude<.05,"Inspect the authored sweep-tail bounds")
 local feathers=Finish.Skin(kit,"GuardianSweepTail",tail,tail:GetPivot());visibleContacts(feathers)
 rough:SetAttribute("ERLethal",nil);rough.Transparency=1;rough.CanQuery=false
 local tray=mechanisms.SidewaysTray;local contact=tray.TrayContact
 assert(contact.Size.X==12 and contact.Size.Z==18,"The long side faces the fixed receiving pocket")
 local trayArt=Finish.Skin(kit,"SlidingTray",tray,tray:GetPivot()*CFrame.new(0,-.9,0),Vector3.new(1.2,1,2.25))
 for _,p in ipairs(trayArt:GetDescendants())do
  if p:IsA("BasePart")and p:GetAttribute("ERMaterial")=="Mint"then p.Transparency=1 end
 end
 contact.Transparency=1
 local cap=contact:Clone();cap.Name="TrayStudTop";cap.Size=Vector3.new(contact.Size.X-.5,.12,contact.Size.Z-.5)
 cap.CFrame=contact.CFrame*CFrame.new(0,.54,0);cap.CanCollide=false;cap.CanTouch=false;cap.CanQuery=false;cap.Transparency=0
 cap:SetAttribute("ERSupport",nil);cap.TopSurface=Enum.SurfaceType.Studs;cap.Parent=tray
 root:SetAttribute("ERMechanismArt",true)
end
return Build
