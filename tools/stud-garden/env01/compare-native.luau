local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local args=require("@lune/process").args
local root="docs/artifacts/stud-garden/environment-01/"
local before=roblox.deserializeModel(fs.readFile(root.."native/stud-garden-env01-before-install.rbxm"))[1]
local after=roblox.deserializeModel(fs.readFile(root.."native/"..(args[1] or "stud-garden-env01-s02-native-b.rbxm")))[1]
local fields={"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","TopSurface","BottomSurface","Reflectance","CastShadow"}
local function difference(a,b)
 if typeof(a)~=typeof(b) then return math.huge end
 local kind=typeof(a)
 if kind=="number" then return math.abs(a-b) end
 if kind=="Vector3" then return (a-b).Magnitude end
 if kind=="Color3" then return math.max(math.abs(a.R-b.R),math.abs(a.G-b.G),math.abs(a.B-b.B)) end
 if kind=="CFrame" then local aa,bb,d={a:GetComponents()},{b:GetComponents()},0 for i=1,12 do d=math.max(d,math.abs(aa[i]-bb[i])) end return d end
 return if a==b then 0 else math.huge
end
local report={candidate=args[3] or "SG_ENV_01_S02_A",source="Actual native exports",originalInstancesPreserved=0,protectedInstances=0,protectedParts=0,artParts=0,colliders=0,maximumProtectedDifference=0,meshes=0,lights=0,allArtNonPhysical=true}
local function compare(a,b,path,art)
 assert(a.Name==b.Name and a.ClassName==b.ClassName,"Existing hierarchy changed: "..path)
 report.originalInstancesPreserved+=1
 if not art then
  report.protectedInstances+=1
  if a:IsA("BasePart") then report.protectedParts+=1
   for _,field in fields do local d=difference(a[field],b[field]);assert(d<0.00001,"Protected field changed: "..path.."."..field);report.maximumProtectedDifference=math.max(report.maximumProtectedDifference,d) end
   if a:IsA("Part") then assert(a.Shape==b.Shape,"Protected primitive shape changed: "..path) end
  end
  local attrs=a:GetAttributes()
  for key,value in attrs do assert(difference(value,b:GetAttribute(key))<0.00001,"Protected attribute changed: "..path.."/"..key) end
  for key in b:GetAttributes() do assert(attrs[key]~=nil,"Protected attribute added: "..path.."/"..key) end
 end
 local counts={}
 for _,child in a:GetChildren() do
  counts[child.Name]=(counts[child.Name] or 0)+1
  local matches={} for _,candidate in b:GetChildren() do if candidate.Name==child.Name then table.insert(matches,candidate) end end
  local target=matches[counts[child.Name]];assert(target,"Original instance removed: "..path.."/"..child.Name)
  compare(child,target,path.."/"..child.Name.."["..counts[child.Name].."]",art or child.Name=="Art" and a==before)
 end
end
compare(before,after,"",false)
for _,object in after:GetDescendants() do
 if object:IsA("BasePart") then
  if object.CanCollide then report.colliders+=1 end
  if object:IsDescendantOf(after.Art) then report.artParts+=1;assert(object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery,"Art has physical behavior") end
 elseif object:IsA("Light") then report.lights+=1 end
 if object:IsA("MeshPart") then report.meshes+=1 end
end
assert(report.originalInstancesPreserved==4743 and report.protectedInstances==1402 and report.protectedParts==912 and report.colliders==237,"Unexpected native preservation totals")
local layoutSource=fs.readFile("src/ServerStorage/CourseBuilders/StudGarden/Layout.luau")
local layout=require("@lune/luau").load(layoutSource,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame}})().Get()
local function compareHazard(a,b,path)
 assert(a.Name==b.Name and a.ClassName==b.ClassName,"Hazard hierarchy changed")
 if a:IsA("BasePart") then for _,field in fields do assert(difference(a[field],b[field])<0.00001,"Hazard cue changed: "..path) end end
 if a:IsA("Part") then assert(a.Shape==b.Shape,"Hazard shape changed: "..path) end
 for key,value in a:GetAttributes() do assert(difference(value,b:GetAttribute(key))<0.00001,"Hazard attribute changed") end
 local aa,bb=a:GetChildren(),b:GetChildren();assert(#aa==#bb,"Hazard child count changed")
 for index,child in aa do compareHazard(child,bb[index],path.."/"..child.Name) end
end
compareHazard(before.Art.HazardVisuals,after.Art.HazardVisuals,"Art/HazardVisuals")
report.hazardVisualsUnchanged=true
report.sightlines="Actual captures provided for independent review; static geometry preservation alone does not verify visibility."
fs.writeFile(root..(args[2] or "native-preservation-a.json"),serde.encode("json",report,true))
print(serde.encode("json",report))

