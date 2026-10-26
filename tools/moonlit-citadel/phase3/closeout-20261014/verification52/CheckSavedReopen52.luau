--!nonstrict
local fs,roblox,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde")
local artifacts="docs/artifacts/moonlit-citadel/phase3/closeout-20261014/"
local final=artifacts.."final/"
local bindings=serde.decode("json",fs.readFile("tools/moonlit-citadel/phase3/closeout-20261014/verification52/bindings52.json"))
assert(bindings.ready,"Bind final Source52 inputs first")
local expected=bindings.expected
local report={pass=false,expected=expected,savedFiles={},models={},sourceParity={},
 savedFileReadOnly=true,studioTouched=false,productionEdited=false,nativeAppearanceVerified=false}
local function read(name)
 local bytes=fs.readFile(final..name)
 report.savedFiles[name]={bytes=#bytes,sha256=serde.hash("sha256",bytes),readable=true}
 return bytes
end
local packetRaw=fs.readFile(artifacts.."before/closeout_source52_packet.json")
assert(serde.hash("sha256",packetRaw)==expected.packet,"Source52 packet binding changed")
local packet=serde.decode("json",packetRaw)
assert(packet.sourceRevision==expected.source and packet.buildRevision==expected.build and packet.candidate==expected.candidate and #packet.records==30)
local baseline=serde.decode("json",fs.readFile(artifacts.."before/closeout_protected_baseline49.json"))
local planRaw=fs.readFile(artifacts.."combined-plan52.json")
assert(serde.hash("sha256",planRaw)=="3b0e592a6695e70a881d30daaa7bfb27915a60bec6acce75e685358b7a7266c2","Final unit-plan binding changed")
local planned={};for _,unit in serde.decode("json",planRaw).units do assert(not planned[unit.name]);planned[unit.name]=unit end
local costs={BL02={},P3={},AR01={},TL01={},ER01={}}
local manifests={
 {"BL02","assets/moonlit_citadel/bl02/manifest.json"},
 {"P3","assets/moonlit_citadel/phase3/candidate01/manifest.json"},
 {"P3","assets/moonlit_citadel/phase3/rework-20261012/rw01/manifest.json"},
 {"AR01","assets/moonlit_citadel/phase3/art-repair-20261013/ar01/manifest.json"},
 {"TL01","assets/moonlit_citadel/phase3/tower-landscape-20261013/tl01/manifest.json"},
 {"ER01","assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/manifest.json"},
}
report.manifestHashes={}
for _,spec in manifests do
 local raw=fs.readFile(spec[2]);report.manifestHashes[spec[2]]=serde.hash("sha256",raw)
 for _,part in serde.decode("json",raw).export_parts do
  assert(not costs[spec[1]][part.name],"Ambiguous measured part cost")
  costs[spec[1]][part.name]={asset=part.asset,triangles=part.triangles}
 end
end
local models=roblox.deserializeModel(read("source52-models.rbxm"))
assert(#models==2,"Exactly two course models must reopen")
local function cfDelta(a,b)
 local left,right={a:GetComponents()},{b:GetComponents()};local difference=0
 for index=1,12 do difference=math.max(difference,math.abs(left[index]-right[index])) end
 return difference
end
for index,model in models do
 assert(model:IsA("Model") and model.Name=="Course_MoonlitCitadel","Unexpected exported course root")
 assert(model:GetAttribute("SourceRevision")==expected.source and model:GetAttribute("BuildRevision")==expected.build)
 assert(model:GetAttribute("SourcePacketHash")==expected.packet and model:GetAttribute("CandidateId")==expected.candidate)
 local old=if index==1 then baseline.editable else baseline.stored
 local expectedPivot=roblox.CFrame.new(table.unpack(old.records[""].props.Pivot.value))
 local pivotReadable,pivot=pcall(function()return model:GetPivot()end)
 local pivotMethod="GetPivot"
 if not pivotReadable then pivotReadable,pivot=pcall(function()return model.WorldPivot end);pivotMethod="WorldPivot" end
 if not pivotReadable or typeof(pivot)~="CFrame" then
  pivotReadable,pivot=pcall(function()return model.WorldPivotData end);pivotMethod="SerializedWorldPivotData"
 end
 assert(pivotReadable and typeof(pivot)=="CFrame","Saved root pivot is unreadable")
 local pivotDifference=cfDelta(pivot,expectedPivot)
 assert(pivotDifference<=.00001,"Saved model pivot differs from fresh recovery")
 local row={index=index,name=model.Name,serializedRootCount=2,source=model:GetAttribute("SourceRevision"),build=model:GetAttribute("BuildRevision"),
  candidate=model:GetAttribute("CandidateId"),packet=model:GetAttribute("SourcePacketHash"),descendants=#model:GetDescendants(),parts=0,meshes=0,
  colliders=0,walkables=0,redContacts=0,arrows=0,pivot={pivot:GetComponents()},expectedPivot={expectedPivot:GetComponents()},
  pivotDifference=pivotDifference,pivotReadMethod=pivotMethod}
 for _,item in model:GetDescendants() do
  if not item:IsA("BasePart") then continue end
  row.parts+=1
  if item:IsA("MeshPart") then row.meshes+=1 end
  if item.CanCollide then row.colliders+=1 end
  if item:GetAttribute("MCWalkable")==true then row.walkables+=1 end
  if item:GetAttribute("MoonlitHazard")==true then row.redContacts+=1 end
  if item:GetAttribute("GuidanceKind")=="SolidMeshArrow" then row.arrows+=1 end
 end
 assert(row.colliders==expected.colliders and row.walkables==expected.walkables and row.redContacts==expected.red and row.arrows==expected.arrows,"Saved protected contact/arrow count changed")
 local world=assert(assert(model:FindFirstChild("Decoration")):FindFirstChild("Phase3World"),"Saved final world is missing")
 local worldCounts={units=0,meshParts=0,triangles=0,nativeTriangleTaggedParts=0,manifestTriangleFallbackParts=0,triangleBasis="Per saved material mesh bound to final plan and measured export manifest",declaredUnits=world:GetAttribute("PlanUnits"),declaredMeshes=world:GetAttribute("MeshParts"),declaredTriangles=world:GetAttribute("PlacedTriangles")}
 for _,item in world:GetDescendants() do
  if item:IsA("Model") and typeof(item:GetAttribute("MCEditUnit"))=="string" then worldCounts.units+=1 end
  if item:IsA("MeshPart") then
   worldCounts.meshParts+=1
   local unit=item.Parent
   while unit and typeof(unit:GetAttribute("MCEditUnit"))~="string" do unit=unit.Parent end
   assert(unit and unit~=world,"Saved art part escaped an authored unit")
   local plan=assert(planned[unit.Name],"Saved art unit is outside the final plan")
   assert(unit:GetAttribute("MCEditUnit")==plan.asset,"Saved edit-unit asset differs")
   local measured=assert(costs[plan.library][item.Name],"Saved art part is absent from measured manifest: "..item.Name)
   assert(measured.asset==plan.asset,"Saved mesh and unit asset mismatch")
   local triangles=item:GetAttribute("SourceTriangles")
   if triangles~=nil then assert(triangles==measured.triangles,"Saved triangle tag differs from measured export");worldCounts.nativeTriangleTaggedParts+=1
   else worldCounts.manifestTriangleFallbackParts+=1 end
   worldCounts.triangles+=measured.triangles
   assert(item.Anchored and not item.CanCollide and not item.CanQuery and not item.CanTouch,"Saved art contact flags changed")
  end
 end
 assert(worldCounts.units==expected.units and worldCounts.meshParts==expected.meshes and worldCounts.triangles==expected.triangles,"Actual saved world ledger differs from final candidate")
 assert(worldCounts.declaredUnits==expected.units and worldCounts.declaredMeshes==expected.meshes and worldCounts.declaredTriangles==expected.triangles,"Declared saved world ledger differs from final candidate")
 row.world=worldCounts
 table.insert(report.models,row)
end
local moduleRoots=roblox.deserializeModel(read("source52-modules.rbxm"))
local scripts={}
local function inspect(item)
 if not item:IsA("LuaSourceContainer") then return end
 assert(not scripts[item.Name],"Ambiguous saved final source name: "..item.Name)
 scripts[item.Name]=item
end
for _,root in moduleRoots do inspect(root);for _,item in root:GetDescendants()do inspect(item)end end
local count=0;for _ in scripts do count+=1 end
assert(count==30,"Exactly30 saved final source modules required")
for _,record in packet.records do
 assert(serde.hash("sha256",record.source)==record.sha256,"Source52 packet record hash changed")
 local module=assert(scripts[record.name],"Saved source missing: "..record.name)
 assert(module:IsA("ModuleScript"),"Final exported source must be a ModuleScript")
 local actual=module.Source:gsub("\r\n","\n")
 local actualSHA=serde.hash("sha256",actual)
 assert(actualSHA==record.sha256 and actual==record.source,"Saved module differs from exact packet: "..record.name)
 local file=if record.name=="MoonlitCitadelAmbienceConfig" then "src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau" else "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"..record.name..".luau"
 local durable=fs.readFile(file):gsub("\r\n","\n")
 local durableSHA=serde.hash("sha256",durable)
 assert(durableSHA==record.sha256 and durable==record.source,"Durable final source differs: "..record.name)
 table.insert(report.sourceParity,{name=record.name,exportedSHA256=actualSHA,packetSHA256=record.sha256,durableSHA256=durableSHA,pass=true,durableFile=file})
end

local luau=require("@lune/luau")
local own="tools/moonlit-citadel/phase3/closeout-20261014/verification52/"
local Geometry=luau.load(fs.readFile(own.."GeometryAudit52.luau"),{environment={CFrame=roblox.CFrame,Vector3=roblox.Vector3}})()
local Override=luau.load(fs.readFile(own.."PartAdjustmentOracle52.luau"),{environment={Vector3=roblox.Vector3}})()
local decodedPlan=serde.decode("json",planRaw)
assert(Override.ValidatePlan(decodedPlan.units).pass,"Saved geometry must bind the one exact approved depth adjustment")
local libraries={}
for _,library in roblox.deserializeModel(fs.readFile(artifacts.."../enclosure-repair-20261013/before/enclosure_before_source48_kits.rbxm")) do
 for key,name in Geometry.LibraryNames do if library.Name==name then libraries[key]=library end end
end
local er=roblox.deserializeModel(fs.readFile(artifacts.."../enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm"))[1]
libraries.ER01=er
local geometry=Geometry.Run(models,libraries,decodedPlan,{expectedIdentity={source=expected.source,build=expected.build,packet=expected.packet},
 expectedUnits=expected.units,expectedMeshes=expected.meshes,expectedCourses=2,requireSourceGuard=false,adjustmentOracle=Override,
 approvedTemplateMetadata=serde.decode("json",fs.readFile("tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json"))})
report.savedGeometryOracle=geometry
assert(geometry.geometryPass,"Saved material-part geometry differs from the explicit final plan")
report.fullProtectedNativeRecordsComparedHere=false
report.protectionBoundary="Saved contact/arrow counts and root pivots pass here; root's fresh native52 exact nonworld/Phase1/arrow comparison remains a separate required proof."

report.moduleExportRoots=#moduleRoots;report.moduleExportCount=count;report.modelExportCount=#models
report.exactPacketParity=true;report.exactDurableParity=true;report.allSavedFilesReopened=true;report.pass=true
fs.writeFile(final.."source52-reopen-report.json",serde.encode("json",report,true))
print(serde.encode("json",{pass=report.pass,models=#models,modules=count,pivotMaxDelta=math.max(report.models[1].pivotDifference,report.models[2].pivotDifference),world=report.models[1].world,savedFiles=report.savedFiles}))
