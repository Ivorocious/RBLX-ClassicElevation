--!strict
local Patch={}
local function folder(parent,name)
 local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
function Patch.Apply(imported,data)
 assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
 local c=workspace.Course_CityRun
 assert(c:GetAttribute("ReviewBuildId")=="C14_05" and game.ServerStorage:FindFirstChild("CityRun_C15_Before"))
 assert(not c.Obstacles:FindFirstChild("C15Routes"))
 local markers,seen,count={},{},0
 local function meshName(p) return if data.meshes[p.Name] then p.Name else string.gsub(p.Name,"%.%d%d%d$","") end
 for _,p in imported:GetDescendants() do
  assert(not p:IsA("LuaSourceContainer"))
  if p:IsA("BasePart") then
   local name=meshName(p);assert(data.meshes[name] and not seen[name],p.Name);seen[name]=true;count+=1
   for _,key in {"Origin","Right","Up","Forward"} do if string.find(p.Name,"Marker"..key.."__",1,true) then markers[key]=p end end
  end
 end
 local expected=0;for _ in data.meshes do expected+=1 end;assert(expected==count)
 imported:ScaleTo(imported:GetScale()*10/(markers.Right.Position-markers.Origin.Position).Magnitude)
 local frame=CFrame.fromMatrix(markers.Origin.Position,(markers.Right.Position-markers.Origin.Position).Unit,(markers.Up.Position-markers.Origin.Position).Unit,(markers.Origin.Position-markers.Forward.Position).Unit)
 local archive=folder(game.ServerStorage,"CityRun_C15_Archive")
 local function keep(p)
  p:SetAttribute("C15OriginalPath",p:GetFullName());p.Parent=archive
 end
 local old=c.Obstacles.C14Routes
 keep(old.ExpertOffsets)
 for _,p in old.CornerLedges:GetChildren() do if string.match(p.Name,"^C14_Corner_[WNE]%d") then keep(p) end end
 local function replacing(name)
  return string.match(name,"^X03_")~=nil or (string.match(name,"^StationMain_00_0[1-5]$")~=nil) or (string.match(name,"^StationMain_01_0[1-7]$")~=nil)
 end
 for _,p in c.Obstacles.WalkingSurfaces:GetChildren() do if replacing(p.Name) then keep(p) end end
 for _,p in c.Obstacles.C10Obstacles:GetChildren() do
  if string.find(p.Name,"X03",1,true) or string.match(p.Name,"^StationCrumble_") or string.find(p.Name,"StationMain_",1,true) then keep(p) end
 end
 for _,p in c.Decoration.C10Streets:GetChildren() do if string.find(p.Name,"StationMain",1,true) then keep(p) end end
 local terminal=c.Decoration.C13Terminal
 for _,p in terminal:GetChildren() do
  local name=string.match(p.Name,"^C13_Surface_(.+)")
  if name and replacing(name) then keep(p) end
 end
 for _,p in terminal.C13_RouteSupport:GetChildren() do if string.find(p.Name,"X03",1,true) or p.Name=="C13_ExpertStringer" or string.match(p.Name,"^C13_ExpertPier_") then keep(p) end end
 for i=0,2 do keep(c.Obstacles.Moving["ActiveTrain"..i]) end
 local root=folder(c.Obstacles,"C15Routes");local sections,units={},{}
 for name,d in data.components do
  if d.section=="Calibration" then continue end
  local parent
  if d.role=="Train" then parent=c.Obstacles.Moving
  else
   if not sections[d.section] then sections[d.section]=folder(root,d.section) end
   parent=sections[d.section]
  end
  local m=Instance.new("Model");m.Name=name;m.Parent=parent;m:SetAttribute("EditableUnit",true);units[name]=m
  if d.role=="Surface" or d.role=="Crumble" then
   local p=Instance.new("Part");p.Name="Collider";p.Size=Vector3.new(unpack(d.size));p.CFrame=CFrame.new(unpack(d.position))*CFrame.Angles(0,d.yaw or 0,0)
   p.Anchored=true;p.CanCollide=true;p.CanQuery=true;p.CanTouch=d.role=="Crumble";p.Transparency=1;p.CastShadow=false;p.Parent=m
   if d.role=="Crumble" then for k,v in d.attrs do p:SetAttribute(k,v) end end
  end
 end
 for _,p in imported:GetDescendants() do
  if not p:IsA("BasePart") then continue end
  p.Name=meshName(p)
  local meta=data.meshes[p.Name];local d=data.components[meta.component];local col=data.colors[meta.material]
  p.CFrame=CFrame.new(3500,0,0)*frame:ToObjectSpace(p.CFrame)
  p.Color=Color3.new(unpack(col));p.Material=if meta.material=="Danger" then Enum.Material.Neon elseif meta.material=="Stone" or meta.material=="Pale" then Enum.Material.Concrete else Enum.Material.Metal
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p:SetAttribute("SourceTriangles",meta.triangles)
  if p:IsA("MeshPart") then p.TextureID="";p.DoubleSided=false end
  local m=units[meta.component]
  p.Parent=if m then (if d.role=="Crumble" then m.Collider else m) else archive
  if d.role=="Hazard" then
   p.CFrame=CFrame.new(unpack(d.position));p.Size=Vector3.new(unpack(d.size));p.CanTouch=true;p.CanQuery=true
   for k,v in d.attrs do if k~="WorldMotionAxis" then p:SetAttribute(k,v) end end
   if d.attrs.KitMotion then p:SetAttribute("MotionAxis",d.attrs.WorldMotionAxis) end
  end
 end
 for name,m in units do
  local d=data.components[name]
  m.WorldPivot=if d.pivot then CFrame.new(unpack(d.pivot)) elseif d.top then CFrame.new(unpack(d.top)) else m:GetBoundingBox()
 end
 imported.Parent=archive
 c:SetAttribute("ReviewBuildId",data.revision);c:SetAttribute("CityRunRevision","C15");c:SetAttribute("VisualReviewPassed",false)
 return {build=data.revision,meshes=count-4,archived=#archive:GetChildren(),descendants=#c:GetDescendants()}
end
return Patch
