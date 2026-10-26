--!nonstrict
-- Read-only module. The lead supplies actual models, libraries, exported plan and frozen sources.
local Audit = {}
local Names = {ER01="MoonlitCitadel_Enclosure_ER01Library",P3="MoonlitCitadel_P3Rework_RW01Library",
 AR01="MoonlitCitadel_P3ArtRepair_AR01Library",TL01="MoonlitCitadel_TowerLandscape_TL01Library",BL02="MoonlitCitadel_BL02Library"}
Audit.LibraryNames = Names

local function vector(value)
 if typeof(value)=="Vector3" then return value end
 assert(type(value)=="table" and #value==3,"Expected XYZ vector")
 return Vector3.new(value[1],value[2],value[3])
end
local function frame(value)
 if typeof(value)=="CFrame" then return value end
 assert(type(value)=="table" and #value==12,"Expected12-component CFrame")
 return CFrame.new(table.unpack(value))
end
local function relative(root,item)
 local pieces={}
 while item~=root do assert(item,"Part escaped edit unit");table.insert(pieces,1,item.Name);item=item.Parent end
 return table.concat(pieces,"/")
end
local function parts(root)
 local groups,count={},0
 for _,item in root:GetDescendants() do if item:IsA("BasePart") then
  local key=relative(root,item).."|"..item.ClassName
  groups[key]=groups[key] or {};table.insert(groups[key],item);count+=1
 end end
 return groups,count
end
local function difference(a,b)
 local x,y={a:GetComponents()},{b:GetComponents()};local position,rotation=0,0
 for i=1,12 do if i<=3 then position=math.max(position,math.abs(x[i]-y[i])) else rotation=math.max(rotation,math.abs(x[i]-y[i])) end end
 return position,rotation
end
local function sizeDifference(a,b)
 return math.max(math.abs(a.X-b.X),math.abs(a.Y-b.Y),math.abs(a.Z-b.Z))
end
local function readMesh(part)
 if not part:IsA("MeshPart") then return "" end
 local ok,value=pcall(function()return part.MeshId end)
 if not ok then ok,value=pcall(function()return part.MeshContent end) end
 assert(ok,"Mesh identity is unavailable; do not skip this comparison")
 local raw=tostring(value)
 local id=raw:match("rbxassetid://(%d+)") or raw:match("[?&]id=(%d+)")
 return if id then "rbxassetid://"..id else raw
end
local function arrowTail(text)
 local marker="local function placeTemplate("
 local first=text:find(marker,1,true)
 assert(first and not text:find(marker,first+#marker,true),"Accepted arrow boundary missing/duplicated")
 assert(text:find("function Environment.PlaceSolidArrow(",first,true),"Accepted arrow function missing")
 return text:sub(first)
end

function Audit.CheckSources(checks,required)
 local report={pass=false,checked=0,required=required or 38,differences={},kind="Exact nativeSource text; expected must come from frozen baseline"}
 local names={}
 for index,row in checks or {} do
  local ok,err=pcall(function()
   assert(row.actual and row.actual:IsA("LuaSourceContainer"),"Missing actual source")
   local name=row.name or row.actual:GetFullName()
   assert(not names[name],"Duplicate source guard name");names[name]=true
   local expected=row.expectedSource
   if expected==nil then assert(row.before and row.before:IsA("LuaSourceContainer"),"Missing frozen expected source");expected=row.before.Source end
   local actual=row.actual.Source
   if row.mode=="arrow-tail-only" then expected,actual=arrowTail(expected),arrowTail(actual) end
   assert(actual==expected,"Protected source text differs")
  end)
  report.checked+=1
  if not ok then table.insert(report.differences,{name=row.name or tostring(index),error=tostring(err)}) end
 end
 report.pass=report.checked==report.required and #report.differences==0
 return report
end

function Audit.Run(courses,libraries,exported,options)
 options=options or {}
 local plan=exported.plan or exported.units or exported
 assert(type(plan)=="table","Decoded combined plan required")
 local posTolerance,sizeTolerance,rotationTolerance=options.positionTolerance or .001,options.sizeTolerance or .001,options.rotationTolerance or .00002
 local report={pass=false,expectedUnits=options.expectedUnits or 178,expectedMeshes=options.expectedMeshes or 487,
  tolerance={position=posTolerance,size=sizeTolerance,rotation=rotationTolerance},failures={},models={},libraries={},
  sourceGuard=Audit.CheckSources(options.sourceChecks,options.requiredSources or 38),readOnly=true}
 local function fail(kind,path,detail)table.insert(report.failures,{kind=kind,path=path,detail=detail}) end
 local er=libraries.ER01
 if not er then fail("MissingLibrary",Names.ER01,"Approved import required") else
  local erMeshes=0;for _,item in er:GetDescendants() do if item:IsA("MeshPart") then erMeshes+=1 end end
  report.libraries.ER01={name=er.Name,assetId=tostring(er:GetAttribute("AssetId")),axisVerified=er:GetAttribute("AxisVerified"),
   importVerified=er:GetAttribute("ImportVerified"),enclosureImportVerified=er:GetAttribute("EnclosureImportVerified"),meshParts=erMeshes}
  if er.Name~=Names.ER01 or tostring(er:GetAttribute("AssetId"))~="83390081804897" or er:GetAttribute("AxisVerified")~=true
   or er:GetAttribute("ImportVerified")~=true or er:GetAttribute("EnclosureImportVerified")~=true or erMeshes~=53
   or er:GetAttribute("SourceSHA256")~="8910e3e6ef3a7d8287376fc1b21e3262820c6ae165ae99211fb703e7c762eb04"
   or er:GetAttribute("ManifestSHA256")~="408808da502372c0bc911febbe269d5aa47eec45d46fefe474fedab30067f7d6" then
   fail("LibraryBinding",er.Name,report.libraries.ER01)
  end
  report.libraries.approvedTemplateMetadataProvided=options.approvedTemplateMetadata~=nil
  if options.approvedTemplateMetadata then
   local metadata=options.approvedTemplateMetadata
   if metadata.approvedAssetId~="83390081804897" or metadata.nativeSnapshotSHA256~="10da46e53127ed4b8ce8bf8a851145f0118a8ca570463643b6338e5ec0d94e0f"
    or #metadata.parts~=53 then fail("TemplateMetadataBinding","ER01","Wrong proven native snapshot") end
   local actualParts={}
   for _,item in er:GetDescendants() do if item:IsA("MeshPart") then
    if actualParts[item.Name] then fail("DuplicateTemplatePart",item.Name,"Approved imported names must be unique") end
    actualParts[item.Name]=item
   end end
   for _,row in metadata.parts do
    local actual=actualParts[row.name]
    if not actual then fail("MissingApprovedTemplatePart",row.name,"Absent from current library");continue end
    local p,r=difference(actual.CFrame,frame(row.cf));local s=sizeDifference(actual.Size,vector(row.size))
    if readMesh(actual)~=row.meshId or p>posTolerance or r>rotationTolerance or s>sizeTolerance then
     fail("ApprovedTemplatePart",row.name,{meshId=readMesh(actual),expectedMeshId=row.meshId,position=p,rotation=r,size=s})
    end
   end
  end
 end
 if #plan~=report.expectedUnits then fail("PlanUnitCount","plan",{expected=report.expectedUnits,actual=#plan}) end
 local plannedNames={}
 for _,data in plan do
  local key=data.district.."/"..data.name
  if plannedNames[key] then fail("DuplicatePlanUnit",key,data.asset) end
  plannedNames[key]=true
 end
 for _,course in courses do
  local modelReport={index=#report.models+1,name=course.Name,path=course:GetFullName(),identity={source=course:GetAttribute("SourceRevision"),build=course:GetAttribute("BuildRevision"),
   packet=course:GetAttribute("SourcePacketHash")},units=0,meshes=0,baseParts=0,checkedParts=0,maxPositionError=0,maxSizeError=0,maxRotationError=0}
  table.insert(report.models,modelReport)
  local expectedIdentity=options.expectedIdentity or {source=49,build=43,packet="7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca"}
  for key,expected in expectedIdentity do if modelReport.identity[key]~=expected then fail("Identity",course.Name.."/"..key,{expected=expected,actual=modelReport.identity[key]}) end end
  local decoration=course:FindFirstChild("Decoration")
  if course:GetAttribute("CourseId")~="moonlit_citadel" then fail("CourseId",course.Name,course:GetAttribute("CourseId")) end
  local world=decoration and decoration:FindFirstChild("Phase3World")
  if not world then fail("MissingWorld",course.Name,"Decoration/Phase3World required");continue end
  local origin=course:GetAttribute("Origin")
  if typeof(origin)~="Vector3" then fail("MissingOrigin",course.Name,"Course Origin Vector3 required");continue end
  local units={}
  for _,district in world:GetChildren() do
   for _,unit in district:GetChildren() do
    if unit:IsA("Model") then
     local key=district.Name.."/"..unit.Name
     if units[key] then fail("DuplicateNativeUnit",course.Name.."/"..key,"Duplicate name") end
     units[key]=unit;modelReport.units+=1
     if not plannedNames[key] then fail("UnexpectedUnit",course.Name.."/"..key,"Not in combined plan") end
    elseif unit:IsA("BasePart") then fail("UncontainedPart",course.Name.."/"..district.Name.."/"..unit.Name,"Expected edit-unit Model") end
   end
  end
  for _,item in world:GetDescendants() do if item:IsA("BasePart") then
   modelReport.baseParts+=1;if item:IsA("MeshPart") then modelReport.meshes+=1 end
   if not item.Anchored or item.CanCollide or item.CanQuery or item.CanTouch then
    fail("SceneryContactFlags",course.Name.."/"..relative(world,item),{anchored=item.Anchored,collide=item.CanCollide,query=item.CanQuery,touch=item.CanTouch})
   end
  end end
  for _,data in plan do
   local key=data.district.."/"..data.name;local path=course.Name.."/"..key
   local unit=units[key]
   if not unit then fail("MissingUnit",path,data.asset);continue end
   local library=libraries[data.library or "BL02"]
   if not library then fail("MissingTemplateLibrary",path,data.library or "BL02");continue end
   if library:GetAttribute("ImportVerified")~=true then fail("UnverifiedTemplateLibrary",path,library.Name) end
   local template=library:FindFirstChild(data.asset)
   if not template or not template:IsA("Model") then fail("MissingTemplate",path,data.asset);continue end
   local localFrame=frame(data.localCF or data.frame or data.cf)
   local scale=vector(data.scale)
   local placement=CFrame.new(origin)*localFrame
   if unit:GetAttribute("MCEditUnit")~=data.asset or unit:GetAttribute("District")~=data.district then
    fail("UnitBinding",path,{asset=unit:GetAttribute("MCEditUnit"),district=unit:GetAttribute("District")})
   end
   local actualFrame,actualScale=unit:GetAttribute("CourseLocalFrame"),unit:GetAttribute("AuthorScale")
   if typeof(actualFrame)~="CFrame" then fail("MissingFrameAttribute",path,"CourseLocalFrame") else
    local p,r=difference(actualFrame,localFrame);if p>posTolerance or r>rotationTolerance then fail("FrameAttribute",path,{position=p,rotation=r}) end
   end
   if typeof(actualScale)~="Vector3" or sizeDifference(actualScale,scale)>sizeTolerance then fail("ScaleAttribute",path,"AuthorScale differs") end
   local expectedGroups=parts(template);local actualGroups=parts(unit)
   for relativePath in actualGroups do if not expectedGroups[relativePath] then fail("UnexpectedPart",path.."/"..relativePath,"Absent from template") end end
   for relativePath,expectedParts in expectedGroups do
    local actualParts=actualGroups[relativePath] or {}
    if #actualParts~=#expectedParts then fail("PartMultiplicity",path.."/"..relativePath,{expected=#expectedParts,actual=#actualParts}) end
    local used={}
    for _,original in expectedParts do
     local expectedFrame=placement*CFrame.new(original.CFrame.Position*scale)*original.CFrame.Rotation
     local expectedSize=original.Size*scale
     local selected,best=nil,math.huge
     for index,candidate in actualParts do if not used[index] then
      local p,r=difference(candidate.CFrame,expectedFrame);local s=sizeDifference(candidate.Size,expectedSize)
      local score=p+s+r+(if readMesh(candidate)==readMesh(original) then 0 else 1000000)
      if score<best then selected,best=index,score end
     end end
     if not selected then fail("MissingPart",path.."/"..relativePath,original.Name);continue end
     used[selected]=true;local actual=actualParts[selected]
     local p,r=difference(actual.CFrame,expectedFrame);local s=sizeDifference(actual.Size,expectedSize)
     modelReport.checkedParts+=1;modelReport.maxPositionError=math.max(modelReport.maxPositionError,p)
     modelReport.maxSizeError=math.max(modelReport.maxSizeError,s);modelReport.maxRotationError=math.max(modelReport.maxRotationError,r)
     if readMesh(actual)~=readMesh(original) then fail("MeshId",path.."/"..relativePath,{expected=readMesh(original),actual=readMesh(actual)}) end
     if p>posTolerance or r>rotationTolerance then fail("PartFrame",path.."/"..relativePath,{position=p,rotation=r}) end
     if s>sizeTolerance then fail("PartSize",path.."/"..relativePath,{error=s}) end
    end
   end
  end
  if modelReport.units~=report.expectedUnits or modelReport.meshes~=report.expectedMeshes or modelReport.checkedParts~=modelReport.baseParts then
   fail("NativeCounts",course.Name,{units=modelReport.units,meshes=modelReport.meshes,baseParts=modelReport.baseParts,checkedParts=modelReport.checkedParts})
  end
  if world:GetAttribute("PlanUnits")~=report.expectedUnits or world:GetAttribute("MeshParts")~=report.expectedMeshes then
   fail("WorldLedger",course.Name,{units=world:GetAttribute("PlanUnits"),meshes=world:GetAttribute("MeshParts")})
  end
  if world:GetAttribute("ArtRepairCandidate")~="ER01" then fail("WorldCandidate",course.Name,world:GetAttribute("ArtRepairCandidate")) end
 end
 if #courses~=(options.expectedCourses or 2) then fail("CourseCount","courses",{expected=options.expectedCourses or 2,actual=#courses}) end
 report.geometryPass=#report.failures==0
 report.nativeSourceGuardRequired=options.requireSourceGuard~=false
 report.pass=report.geometryPass and (not report.nativeSourceGuardRequired or report.sourceGuard.pass)
 return report
end
return Audit
