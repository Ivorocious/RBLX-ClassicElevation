local Audit={}
local properties={"CFrame","Size","Color","Material","Transparency","Reflectance","Anchored","CanCollide","CanQuery","CanTouch","CastShadow","CollisionGroup","PivotOffset"}
local function path(root,item)
 local names={} while item~=root do table.insert(names,1,item.Name);item=item.Parent;assert(item) end return table.concat(names,"/")
end
local function resolve(root,relative) for name in relative:gmatch("[^/]+") do root=assert(root:FindFirstChild(name),relative) end return root end
local function equal(a,b)
 if type(a)~="table" then return a==b end
 if type(b)~="table" then return false end
 for k,v in a do if not equal(v,b[k]) then return false end end
 for k in b do if a[k]==nil then return false end end return true
end
local function near(a,b)
 if typeof(a)=="Vector3" then return (a-b).Magnitude<.003 end
 if typeof(a)=="CFrame" then local x,y={a:GetComponents()},{b:GetComponents()};for i,v in x do if math.abs(v-y[i])>.003 then return false end end return true end
 return a==b
end
function Audit.Check(before,after,manifest,layout)
 local exceptions={} for _,op in manifest.operations do exceptions[op.path]=op end
 local result={pass=true,stableParts=0,floorCorrections=0,routeCorrections=0,finishCorrections=0,worldMeshes=0,worldUnits=0,colliders=0,walkables=0,hazards=0,arrows=0}
 for _,part in before:GetDescendants() do
  if not part:IsA("BasePart") then continue end
  local p=path(before,part)
  if p:sub(1,23)=="Decoration/Phase3World/" then continue end
  local final=resolve(after,p)
  local expectedAttrs=part:GetAttributes()
  if after.Parent==workspace and type(expectedAttrs.SourceContact)=="string" then
   expectedAttrs.SourceContact=expectedAttrs.SourceContact:gsub("^ServerStorage%.CourseLibrary%.Course_MoonlitCitadel%.","Workspace.Course_MoonlitCitadel.")
  end
  assert(part.ClassName==final.ClassName and equal(expectedAttrs,final:GetAttributes()),"Part identity/attributes changed: "..p)
  local op=exceptions[p]
  for _,key in properties do
   local expected=part[key]
   if p=="Finish" and key=="Size" then expected=layout.FinishGate.size
   elseif p=="Finish" and key=="CFrame" then expected=CFrame.new(before:GetAttribute("Origin")+layout.FinishGate.point+Vector3.new(0,layout.FinishGate.size.Y/2,0))*CFrame.Angles(0,layout.FinishGate.yaw,0)
   elseif op and key=="Size" then expected=Vector3.new(table.unpack(op.afterSize))
   elseif op and key=="CFrame" then expected=CFrame.new(table.unpack(op.afterCFrame)) end
   assert(if op then near(expected,final[key]) else expected==final[key],"Unexpected "..key..": "..p)
  end
  if part:IsA("MeshPart") then assert(part.MeshId==final.MeshId and part.MeshSize==final.MeshSize and part.TextureID==final.TextureID and part.DoubleSided==final.DoubleSided,"Mesh identity changed: "..p) end
  if p=="Finish" then result.finishCorrections+=1
  elseif op then if p:find("StoneSkin/MC_FloorStone__Floor",1,true) then result.floorCorrections+=1 else result.routeCorrections+=1 end
  else result.stableParts+=1 end
 end
 local world=assert(after.Decoration:FindFirstChild("Phase3World"))
 for _,item in after:GetDescendants() do
  if item:IsA("BasePart") then
   if item.CanCollide then result.colliders+=1 end
   if item:GetAttribute("MCWalkable") then result.walkables+=1 end
   if item:GetAttribute("MoonlitHazard") then result.hazards+=1 end
   if item:GetAttribute("GuidanceKind")=="SolidMeshArrow" then result.arrows+=1 end
  end
 end
 for _,item in world:GetDescendants() do
  if item:IsA("Model") and item:GetAttribute("MCEditUnit") then result.worldUnits+=1 end
  if item:IsA("BasePart") then assert(item:IsA("MeshPart") and item.Anchored and not item.CanCollide and not item.CanQuery and not item.CanTouch,"World changed physics");result.worldMeshes+=1 end
 end
 assert(result.worldUnits==315 and result.worldMeshes==868 and result.colliders==147 and result.walkables==135 and result.hazards==55 and result.arrows==19)
 assert(result.floorCorrections==135 and result.routeCorrections==14 and result.finishCorrections==1)
 assert(world:GetAttribute("PlacedTriangles")==259002)
 return result
end
return Audit