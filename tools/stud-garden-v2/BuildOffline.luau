-- Offline geometry construction only; this does not simulate Roblox physics.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local process=require("@lune/process")
local V,C=roblox.Vector3,roblox.CFrame
local sourceCFrame=table.clone(C)
function sourceCFrame.lookAt(position,target,up)
 local forward=(target-position).Unit
 local side=forward:Cross(up or V.yAxis)
 if side.Magnitude<1e-6 then side=forward:Cross(V.zAxis) end
 local right=side.Unit
 return C.fromMatrix(position,right,right:Cross(forward),-forward)
end
local stage=process.args[1] or "docs/artifacts/stud-garden-v2/phase2/round3/staged-source"
local output=process.args[2] or "docs/artifacts/stud-garden-v2/phase2/round3/offline"
local archive="docs/artifacts/stud-garden-v2/phase2/round2/native/sgv2-r207-course-libraries-source.rbxm"
local function modelPivot(m)
 if m.PrimaryPart then return m.PrimaryPart.CFrame*m.PrimaryPart.PivotOffset end
 local ok,pivot=pcall(function() return m.WorldPivot end)
 return if ok then pivot else m.WorldPivotData or C.identity
end
roblox.implementMethod("Model","GetPivot",modelPivot)
roblox.implementMethod("Model","GetScale",function(m) return m.Scale end)
roblox.implementMethod("Model","PivotTo",function(m,target)
 local delta=target*m:GetPivot():Inverse()
 for _,v in m:GetDescendants() do
  if v:IsA("BasePart") then v.CFrame=delta*v.CFrame
  elseif v:IsA("Model") then v.WorldPivot=delta*modelPivot(v) end
 end
 m.WorldPivot=target
end)
roblox.implementMethod("Model","ScaleTo",function(m,scale)
 local ratio=scale/m:GetScale()
 local origin=m:GetPivot()
 local function scaleFrame(frame)
  local relative=origin:ToObjectSpace(frame)
  return origin*(C.new(relative.Position*ratio)*relative.Rotation)
 end
 for _,v in m:GetDescendants() do
  if v:IsA("BasePart") then
   v.CFrame=scaleFrame(v.CFrame);v.Size*=ratio
   v.PivotOffset=C.new(v.PivotOffset.Position*ratio)*v.PivotOffset.Rotation
  elseif v:IsA("Model") then v.WorldPivot=scaleFrame(modelPivot(v));v.Scale*=ratio end
 end
 m.Scale=scale
end)
local function folder(name,parent)
 local f=roblox.Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
local storage=folder("ServerStorage")
local world=folder("Workspace")
local saved=roblox.deserializeModel(fs.readFile(archive))
local baseline
for _,root in saved do
 if root.Name=="Course_StudGardenV2" then baseline=root
 elseif root.Name=="StudGardenV2Assets_M01" or root.Name=="StudGardenV2Assets_M02" then root.Parent=storage end
end
local source=folder("StagedSource")
for _,file in fs.readDir(stage) do
 if file:sub(-5)==".luau" then
  local s=roblox.Instance.new("ModuleScript");s.Name=file:sub(1,-6);s.Source=fs.readFile(stage.."/"..file);s.Parent=source
 end
end
local game={ServerStorage=storage,Workspace=world}
function game:GetService(name) return self[name] end
local cache={}
local function loadModule(s)
 if cache[s] then return cache[s] end
 local env={game=game,workspace=world,script=s,require=loadModule}
 for _,key in {"Instance","CFrame","Vector3","Vector2","Color3","UDim2","UDim","Enum","NumberSequence","NumberSequenceKeypoint","ColorSequence"} do env[key]=roblox[key] end
 env.CFrame=sourceCFrame
 local result=luau.load(s.Source,{environment=env,debugName=s.Name})()
 cache[s]=result;return result
end
local course=loadModule(source.CourseBuild).Create(world)
local function export(root)
 local data={candidate=root:GetAttribute("CandidateId"),origin={9200,80,3500},parts={},models={},paths={},checkpoints={}}
 local prefix=#root:GetFullName()+2
 for _,p in root:GetDescendants() do
  local path=p:GetFullName():sub(prefix)
  if p:IsA("BasePart") then
   local r={path=path,name=p.Name,class=p.ClassName,cf={p.CFrame:GetComponents()},size={p.Size.X,p.Size.Y,p.Size.Z},
    color={p.Color.R,p.Color.G,p.Color.B},collide=p.CanCollide,query=p.CanQuery,transparency=p.Transparency,role=p:GetAttribute("Role"),
    shape=if p:IsA("Part") then p.Shape.Name else p.ClassName,attributes={}}
   for key,value in p:GetAttributes() do if typeof(value)=="number" or typeof(value)=="string" or typeof(value)=="boolean" then r.attributes[key]=value end end
   if p:IsA("MeshPart") then
    local ok,id=pcall(function() return p.MeshId end)
    if not ok then ok,id=pcall(function() return tostring(p.MeshContent) end) end
    if ok then r.mesh=id end
   end
   local labels={}
   for _,v in p:GetDescendants() do if v:IsA("TextLabel") then table.insert(labels,{text=v.Text,color={v.TextColor3.R,v.TextColor3.G,v.TextColor3.B},face=v.Parent.Face.Name}) end end
   if #labels>0 then r.labels=labels end
   table.insert(data.parts,r)
  elseif p:IsA("Model") then table.insert(data.models,{path=path,pivot={p:GetPivot():GetComponents()},family=p:GetAttribute("AssetFamily")}) end
 end
 for _,path in root.RouteMarkers:GetChildren() do
  local row={name=path.Name,kind=path:GetAttribute("RouteKind"),points={}}
  local points=path:GetChildren();table.sort(points,function(a,b) return a.Name<b.Name end)
  for _,p in points do local pos=p.CFrame.Position-V.new(9200,80,3500);table.insert(row.points,{pos.X,pos.Y,pos.Z}) end
  table.insert(data.paths,row)
 end
 for _,p in root.Checkpoints:GetChildren() do table.insert(data.checkpoints,{name=p.Name,cf={p.CFrame:GetComponents()},size={p.Size.X,p.Size.Y,p.Size.Z},
  spawn={p:GetAttribute("RespawnCFrame"):GetComponents()},area={p:GetAttribute("RespawnAreaSize").X,p:GetAttribute("RespawnAreaSize").Z}}) end
 return data
end
fs.writeDir(output)
local data=export(course)
fs.writeFile(output.."/geometry.json",serde.encode("json",data,true))
if data.candidate=="SGV2_R207" then fs.writeFile(output.."/native-baseline.json",serde.encode("json",export(baseline),true)) end
local sources=source:Clone();sources.Name="Source_"..data.candidate
course.WorldPivotData=course:GetPivot()
for _,v in course:GetDescendants() do if v:IsA("Model") then v.WorldPivotData=v:GetPivot() end end
local font
for _,v in baseline:GetDescendants() do if v:IsA("TextLabel") then font=v.FontFace;break end end
for _,v in course:GetDescendants() do if v:IsA("TextLabel") then v.FontFace=font end end
fs.writeFile(output.."/candidate.rbxm",roblox.serializeModel({course,storage.StudGardenV2Assets_M01,storage.StudGardenV2Assets_M02,sources}))
print(serde.encode("json",{candidate=data.candidate,parts=#data.parts,models=#data.models,sourceModules=#sources:GetChildren(),offline=true}))
