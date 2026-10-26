local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local folder = "docs/artifacts/stud-garden/environment-01"
local builders = "src/ServerStorage/CourseBuilders/StudGarden/"
local env = {Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,Enum=roblox.Enum,Instance=roblox.Instance}
local kit = luau.load(fs.readFile(builders.."Kit.luau"),{environment=env})()
local layout = luau.load(fs.readFile(builders.."Layout.luau"),{environment=env})().Get()
local cfg = luau.load(fs.readFile("src/ReplicatedStorage/Config/StudGardenConfig.luau"),{environment=env})()
local moduleEnv = table.clone(env)
moduleEnv.script = {Parent={Kit="Kit"}}
moduleEnv.require = function() return kit end
local environment = luau.load(fs.readFile("tools/stud-garden/env01/Environment.luau"),{environment=moduleEnv})()
local roots = roblox.deserializeModel(fs.readFile(folder.."/native/stud-garden-env01-s02-native-b.rbxm"))
local course = roots[1]
local fields = {"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","TopSurface","BottomSurface","Reflectance","CastShadow"}
local function atom(value)
 local kind = typeof(value)
 if kind == "Vector3" then return {value.X,value.Y,value.Z} end
 if kind == "CFrame" then return {value:GetComponents()} end
 if kind == "Color3" then return {value.R,value.G,value.B} end
 if kind == "EnumItem" then return tostring(value) end
 return value
end
local function snapshot(root)
 local result = {}
 local function walk(object,path,art)
  local entry = {class=object.ClassName,attributes={},art=art}
  for key,value in object:GetAttributes() do entry.attributes[key] = atom(value) end
  if object:IsA("BasePart") then
   entry.fields = {}
   for _,field in fields do entry.fields[field] = atom(object[field]) end
   if object:IsA("Part") then entry.fields.Shape = atom(object.Shape) end
  end
  result[path] = entry
  local counts = {}
  for _,child in object:GetChildren() do
   counts[child.Name] = (counts[child.Name] or 0)+1
   walk(child,path.."/"..child.Name.."["..counts[child.Name].."]",art or object==root and child.Name=="Art")
  end
 end
 walk(root,"",false)
 return result
end
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)=="number" then return math.abs(a-b)<0.00001 end
 if type(a)~="table" then return a==b end
 for key,value in a do if not equal(value,b[key]) then return false end end
 for key in b do if a[key]==nil then return false end end
 return true
end
local before = snapshot(course)
local report = environment.CorrectRepresentative(course,cfg,layout)
local after = snapshot(course)
local changed = {}
report.originalCandidateInstancesPreserved,report.protectedInstancesUnchanged = 0,0
local changes = {}
for path,entry in before do
 assert(after[path],"Original instance removed: "..path)
 report.originalCandidateInstancesPreserved += 1
 if not entry.art or path:find("/Art[1]/HazardVisuals[1]",1,true)==1 then
  assert(equal(entry,after[path]),"Protected instance changed: "..path)
  if not entry.art then report.protectedInstancesUnchanged += 1 end
 elseif not equal(entry,after[path]) then
  table.insert(changes,{path=path,before=entry,after=after[path]})
 end
end
local function changedParts(object,path)
 if object:IsA("BasePart") and (not before[path] or not equal(before[path],after[path])) then changed[object] = true end
 local counts = {}
 for _,child in object:GetChildren() do
  counts[child.Name] = (counts[child.Name] or 0)+1
  changedParts(child,path.."/"..child.Name.."["..counts[child.Name].."]")
 end
end
changedParts(course,"")
local origin = roblox.CFrame.new(cfg.Origin)
local function bounds(part)
 local frame = origin:ToObjectSpace(part.CFrame)
 local half = roblox.Vector3.new(
  math.abs(frame.RightVector.X)*part.Size.X/2+math.abs(frame.UpVector.X)*part.Size.Y/2+math.abs(frame.LookVector.X)*part.Size.Z/2,
  math.abs(frame.RightVector.Y)*part.Size.X/2+math.abs(frame.UpVector.Y)*part.Size.Y/2+math.abs(frame.LookVector.Y)*part.Size.Z/2,
  math.abs(frame.RightVector.Z)*part.Size.X/2+math.abs(frame.UpVector.Z)*part.Size.Y/2+math.abs(frame.LookVector.Z)*part.Size.Z/2
 )
 return frame.Position,half
end
local protected = {}
for _,part in course:GetDescendants() do
 if part:IsA("BasePart") and part:GetAttribute("CoreFloor")==true then
  local p,h = bounds(part)
  table.insert(protected,{name=part.Name,p=p,h=h})
 end
end
for _,hazard in layout.hazards do table.insert(protected,{name=hazard.id.." volume",p=hazard.volume.position,h=hazard.volume.size/2}) end
report.clearanceConflicts = {}
for part in changed do
 if not part:IsDescendantOf(course.Art) then continue end
 local p,h = bounds(part)
 for _,floor in protected do
  if math.abs(p.X-floor.p.X)<h.X+floor.h.X+0.75 and math.abs(p.Z-floor.p.Z)<h.Z+floor.h.Z+0.75
   and p.Y+h.Y>floor.p.Y+floor.h.Y+0.1 and p.Y-h.Y<floor.p.Y+floor.h.Y+7 then
   table.insert(report.clearanceConflicts,{part=part:GetFullName(),protected=floor.name})
  end
 end
end
for _,part in course.Art:GetDescendants() do
 if part:IsA("BasePart") then assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,"Art became physical") end
end
report.modifiedExistingArtInstances = #changes
report.nativeReview = "Pending corrected native installation and independent rereview"
if #report.clearanceConflicts>0 then
 print(serde.encode("json",report,true))
 error("Corrected scenery enters a protected floor or hazard bounding volume")
end
local output = folder.."/s02-corrected-B.rbxm"
fs.writeFile(output,roblox.serializeModel(roots))
assert(equal(after,snapshot(roblox.deserializeModel(fs.readFile(output))[1])),"Corrected candidate differs after serialization")
report.serializedReadback = true
fs.writeFile(folder.."/correction-b.json",serde.encode("json",report,true))
fs.writeFile(folder.."/s02-correction-b-changes.json",serde.encode("json",changes,true))
print(serde.encode("json",report,true))
