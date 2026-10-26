from pathlib import Path
import json
root=Path('assets/city_run/v3')
plan=json.loads((root/'stage2-layout.json').read_text())
code=r'''local Http=game:GetService("HttpService")
local SS=game:GetService("ServerStorage")
assert(game.PlaceId==85558151074819,"Wrong place")
local sources=assert(SS:FindFirstChild("CityRunInspectionSources"))
local original=assert(sources:FindFirstChild("Original"))
local optimized=assert(sources:FindFirstChild("Optimized"))
local plan=Http:JSONDecode([==[PLAN_JSON]==])
local gallery=workspace:FindFirstChild("CityRunV3AssetReview") or SS:FindFirstChild("CityRunV3AssetReview",true)
assert(gallery,"Canonical kit missing")
local library={}
for _,name in {"CityRunV3PaintedAssetKit05","CityRunV3DistrictAddon01"} do
 for _,p in assert(gallery:FindFirstChild(name)):GetDescendants() do
  if p:IsA("MeshPart") then library[p.Name]=p end
 end
end
for _,v in plan.placements do assert(library[v.asset],"Missing asset "..v.asset) end
local candidate=optimized:Clone()
candidate.Name="Rebuilt"
local course=candidate.RaceCourse
local pivot=course:GetPivot()
local function resolve(path)
 local node=candidate
 for name in string.gmatch(path,"[^.]+") do node=node and node:FindFirstChild(name) end
 return node
end
-- Validate the full replacement set before changing even the detached candidate.
for _,path in plan.replacePaths do assert(resolve(path),"Required source missing: "..path) end
local removedParts=0
local missing={}
for _,path in plan.replacePaths do
 local node=resolve(path)
 if node then
  assert(not node:IsA("BasePart") or not node.CanCollide,"Protected collision root: "..path)
  for _,p in node:GetDescendants() do
   if p:IsA("BasePart") then assert(not p.CanCollide,"Protected collision: "..p:GetFullName());removedParts+=1 end
  end
  node:Destroy()
 else table.insert(missing,path) end
end
local scenery=Instance.new("Folder")
scenery.Name="V3Scenery";scenery.Parent=course.Decoration
for i,v in plan.placements do
 local p=library[v.asset]:Clone()
 local size=Vector3.new(unpack(v.size))
 local scale=size/p.Size
 local old=p.PivotOffset
 p.Size=size
 p.PivotOffset=CFrame.new(old.Position*scale)*old.Rotation
 p.Name=string.format("%03d_%s",i,v.label~="" and v.label or v.asset)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.CastShadow=not string.find(v.asset,"Skyline")
 p:SetAttribute("V3AssetId",v.asset);p:SetAttribute("V3Build",plan.build)
 p:PivotTo(CFrame.new(unpack(v.pos))*CFrame.Angles(0,math.rad(v.yaw),0))
 p.Parent=scenery
end
course.WorldPivot=pivot
course:SetAttribute("CityRunV3Build",plan.build)
candidate:SetAttribute("CityRunV3Build",plan.build)
local archive=SS:FindFirstChild("CityRunV3Stage2Archive") or Instance.new("Folder")
archive.Name="CityRunV3Stage2Archive";archive.Parent=SS
local old=sources:FindFirstChild("Rebuilt")
if old then old.Name="Rebuilt_"..tostring(old:GetAttribute("CityRunV3Build")).."_"..tostring(os.time());old.Parent=archive end
candidate.Parent=sources
local previous=workspace:FindFirstChild("CityRunV3Stage2Preview")
if previous then previous.Name="Preview_"..tostring(os.time());previous.Parent=archive end
local preview=candidate:Clone();preview.Name="CityRunV3Stage2Preview"
preview:PivotTo(preview:GetPivot()+Vector3.new(8000,0,0));preview.Parent=workspace
local function metric(m)
 local out={instances=#m:GetDescendants(),parts=0,meshes=0,colliders=0,touch=0,query=0};local ids={}
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then
  out.parts+=1;if p.CanCollide then out.colliders+=1 end;if p.CanTouch then out.touch+=1 end;if p.CanQuery then out.query+=1 end
  if p:IsA("MeshPart") then out.meshes+=1;ids[p.MeshId]=true end
 end end
 local n=0;for _ in ids do n+=1 end;out.uniqueMeshes=n;return out
end
return Http:JSONEncode({build=plan.build,removedParts=removedParts,added=#plan.placements,missing=missing,original=metric(original),optimized=metric(optimized),rebuilt=metric(candidate)})'''
(root/'assemble_stage2.luau').write_text(code.replace('PLAN_JSON',json.dumps(plan,separators=(',',':'))))
print('Installer written',len(code)+len(json.dumps(plan)))
