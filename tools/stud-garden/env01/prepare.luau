local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local folder="docs/artifacts/stud-garden/environment-01"
fs.writeDir(folder)
local env={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,Enum=roblox.Enum,Instance=roblox.Instance}
local builders="src/ServerStorage/CourseBuilders/StudGarden/"
local kit=luau.load(fs.readFile(builders.."Kit.luau"),{environment=env,debugName="Kit"})()
local layout=luau.load(fs.readFile(builders.."Layout.luau"),{environment=env,debugName="Layout"})().Get()
local cfg=luau.load(fs.readFile("src/ReplicatedStorage/Config/StudGardenConfig.luau"),{environment=env})()
local moduleEnv=table.clone(env)
moduleEnv.script={Parent={Kit="Kit"}}
moduleEnv.require=function() return kit end
local environment=luau.load(fs.readFile("tools/stud-garden/env01/Environment.luau"),{environment=moduleEnv,debugName="Environment"})()
local native=fs.readFile("docs/artifacts/stud-garden/milestones/stud-garden-final-sg01-layout04-art03.rbxm")
local function atom(value)
 local kind=typeof(value)
 if kind=="Vector3" then return {type=kind,value={value.X,value.Y,value.Z}}
 elseif kind=="CFrame" then return {type=kind,value={value:GetComponents()}}
 elseif kind=="Color3" then return {type=kind,value={value.R,value.G,value.B}}
 elseif kind=="EnumItem" then return tostring(value)
 elseif kind=="number" or kind=="string" or kind=="boolean" then return value
 else return tostring(value) end
end
local fields={"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","TopSurface","BottomSurface","Reflectance","CastShadow"}
local function snapshot(root)
 local result={}
 local function visit(object,path,inArt)
  local entry={class=object.ClassName,name=object.Name,attributes={},inArt=inArt}
  for key,value in object:GetAttributes() do entry.attributes[key]=atom(value) end
  if object:IsA("BasePart") then
   entry.fields={}
   for _,field in fields do entry.fields[field]=atom(object[field]) end
   if object:IsA("Part") then entry.fields.Shape=atom(object.Shape) end
  end
  result[path]=entry
  local counts={}
  for _,child in object:GetChildren() do
   counts[child.Name]=(counts[child.Name] or 0)+1
   visit(child,if path=="" then child.Name.."["..counts[child.Name].."]" else path.."/"..child.Name.."["..counts[child.Name].."]",inArt or child.Name=="Art" and object==root)
  end
 end
 visit(root,"",false)
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
local origin=roblox.CFrame.new(cfg.Origin)
local function bounds(part)
 local frame=origin:ToObjectSpace(part.CFrame)
 local half=roblox.Vector3.new(
  math.abs(frame.RightVector.X)*part.Size.X/2+math.abs(frame.UpVector.X)*part.Size.Y/2+math.abs(frame.LookVector.X)*part.Size.Z/2,
  math.abs(frame.RightVector.Y)*part.Size.X/2+math.abs(frame.UpVector.Y)*part.Size.Y/2+math.abs(frame.LookVector.Y)*part.Size.Z/2,
  math.abs(frame.RightVector.Z)*part.Size.X/2+math.abs(frame.UpVector.Z)*part.Size.Y/2+math.abs(frame.LookVector.Z)*part.Size.Z/2
 )
 return frame.Position,half
end
local function readable(course,changed)
 local protected={}
 for _,part in course:GetDescendants() do
  if part:IsA("BasePart") and part:GetAttribute("CoreFloor")==true then
   local p,h=bounds(part)
   table.insert(protected,{name=part.Name,p=p,h=h})
  end
 end
 for _,hazard in layout.hazards do
  table.insert(protected,{name=hazard.id.." volume",p=hazard.volume.position,h=hazard.volume.size/2})
 end
 local conflicts={}
 for _,part in course.Art:GetDescendants() do
  if part:IsA("BasePart") and changed[part] then
   local p,h=bounds(part)
   for _,floor in protected do
    if math.abs(p.X-floor.p.X)<h.X+floor.h.X+0.75 and math.abs(p.Z-floor.p.Z)<h.Z+floor.h.Z+0.75
     and p.Y+h.Y>floor.p.Y+floor.h.Y+0.1 and p.Y-h.Y<floor.p.Y+floor.h.Y+7 then
      table.insert(conflicts,{part=part:GetFullName(),protected=floor.name})
    end
   end
  end
 end
 return conflicts
end
local report={task="SG_ENV_01",stage="local_preparation",nativeReview="pending Edit and actual native captures",hardware={cpu="unverified: Win32_Processor access denied",gpu="unverified: Win32_VideoController access denied"},options={}}
for _,option in {"TerracedRows","CourtyardPockets"} do
 local roots=roblox.deserializeModel(native)
 local course=roots[1]
 local before=snapshot(course)
 if option=="TerracedRows" then
  local protected={} for path,entry in before do if not entry.inArt then protected[path]=entry end end
  fs.writeFile(folder.."/baseline-protected-properties.json",serde.encode("json",protected,true))
 end
 local result=environment.Representative(course,cfg,layout,option)
 local after=snapshot(course)
 local modified,protectedCount,newCount={},0,0
 for path,entry in before do
  assert(after[path],"An existing instance was removed: "..path)
  if not entry.inArt then assert(equal(entry,after[path]),"Protected instance changed: "..path);protectedCount+=1
  elseif path:find("Art[1]/HazardVisuals[1]",1,true)==1 then assert(equal(entry,after[path]),"Hazard visuals changed: "..path)
  elseif not equal(entry,after[path]) then table.insert(modified,{path=path,before=entry,after=after[path]}) end
 end
 for path,entry in after do if not before[path] then newCount+=1 end end
 local changed={}
 local function visit(object,path)
  if object:IsA("BasePart") and (not before[path] or not equal(before[path],after[path])) then changed[object]=true end
  local counts={}
  for _,child in object:GetChildren() do
   counts[child.Name]=(counts[child.Name] or 0)+1
   visit(child,if path=="" then child.Name.."["..counts[child.Name].."]" else path.."/"..child.Name.."["..counts[child.Name].."]")
  end
 end
 visit(course,"")
 result.clearanceConflicts=readable(course,changed)
 assert(#result.clearanceConflicts==0,"Changed scenery enters a floor or hazard bounding volume")
 for _,part in course.Art:GetDescendants() do if part:IsA("BasePart") then assert(not part.CanCollide and not part.CanTouch and not part.CanQuery,"Scenery became physical") end end
 result.originalInstancesPreserved=0
 for _ in before do result.originalInstancesPreserved+=1 end
 result.protectedInstancesUnchanged=protectedCount
 result.newInstances=newCount
 result.modifiedExistingArtInstances=#modified
 result.originalPartCount=3805
 result.triangleCount="Engine primitive triangles unmeasured; no meshes were added"
 result.nativeReview="unverified; these are local serialized candidates"
 local filename=folder.."/s02-"..option..".rbxm"
 fs.writeFile(filename,roblox.serializeModel(roots))
 local roundtrip=snapshot(roblox.deserializeModel(fs.readFile(filename))[1])
 assert(equal(after,roundtrip),"Candidate file differs after serialization")
 result.serializedReadback=true
 fs.writeFile(folder.."/s02-"..option.."-changes.json",serde.encode("json",modified,true))
 table.insert(report.options,result)
 print(serde.encode("json",result))
end
fs.writeFile(folder.."/preparation-report.json",serde.encode("json",report,true))

