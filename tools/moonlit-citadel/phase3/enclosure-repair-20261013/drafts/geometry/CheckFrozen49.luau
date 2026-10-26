--!nonstrict
local fs,roblox,serde,luau,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/luau"),require("@lune/process")
local own="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/"
local root="docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/"
local modelFile=process.args[1] or root.."final/enclosure_source49_models.rbxm"
local kitFile=process.args[2] or root.."before/enclosure_before_source48_kits.rbxm"
local planFile=process.args[3] or root.."combined-plan49.json"
local erFile=process.args[4] or root.."before/enclosure_er01_library_verified.rbxm"
local beforeFile=root.."before/enclosure_before_source48_models.rbxm"
local baselineFile=own.."source48-protected-sources.json"
local auditFile=own.."AuditNative49.luau"
local models=roblox.deserializeModel(fs.readFile(modelFile));assert(#models==2,"Exactly two frozen courses required")
local export=serde.decode("json",fs.readFile(planFile));assert(export.schema==1 and #export.units==178)
local Audit=luau.load(fs.readFile(auditFile),{environment={CFrame=roblox.CFrame,Vector3=roblox.Vector3}})()
local libraries={}
for _,library in roblox.deserializeModel(fs.readFile(kitFile)) do
 for key,name in Audit.LibraryNames do if library.Name==name then libraries[key]=library end end
end
local erBytes=fs.readFile(erFile)
assert(serde.hash("sha256",erBytes)=="b07d422330ee003a3b1030438b5f8d227dc6f9d42720da02843cc654226da407","Approved verified library recovery differs")
local er=roblox.deserializeModel(erBytes);assert(#er==1 and er[1].Name==Audit.LibraryNames.ER01);libraries.ER01=er[1]
local templateFile=own.."approved-template-metadata49.json"
local report=Audit.Run(models,libraries,export,{requireSourceGuard=false,approvedTemplateMetadata=serde.decode("json",fs.readFile(templateFile))})
report.sourceGuardMode="Saved courses do not contain all38external source files; native guard must be captured separately by lead"
local baseline=serde.decode("json",fs.readFile(baselineFile))
local sourceGuard={pass=true,checked=0,changed={},kind="Current filesystem38protected source entries compared with original Source48 baseline"}
for name,row in baseline.files do
 local path=name:gsub("#accepted%-arrow%-tail$","")
 local text=fs.readFile(path)
 if row.mode=="arrow-tail-only" then
  text=text:gsub("\r\n","\n");if text:sub(1,3)=="\239\187\191" then text=text:sub(4) end
  local marker="local function placeTemplate(";local index=text:find(marker,1,true)
  assert(index and not text:find(marker,index+#marker,true),"Accepted arrow boundary changed")
  assert(text:find("function Environment.PlaceSolidArrow(",index,true));text=text:sub(index)
 end
 sourceGuard.checked+=1
 if serde.hash("sha256",text)~=row.sha256 then sourceGuard.pass=false;table.insert(sourceGuard.changed,name) end
end
sourceGuard.pass=sourceGuard.pass and sourceGuard.checked==38;table.sort(sourceGuard.changed);report.filesystemSourceGuard=sourceGuard
local function counts(model)
 local row={descendants=#model:GetDescendants(),parts=0,meshes=0,colliders=0,floors=0,redContacts=0,worldParts=0,arrows=0}
 local arrowIds={};local world=model.Decoration.Phase3World
 for _,item in model:GetDescendants() do
  if item:IsA("BasePart") then
   row.parts+=1;if item:IsA("MeshPart") then row.meshes+=1 end
   if item.CanCollide then row.colliders+=1 end
   if item:GetAttribute("MCWalkable")==true then row.floors+=1 end
   if item:GetAttribute("MoonlitHazard")==true then row.redContacts+=1 end
   if item:IsDescendantOf(world) then row.worldParts+=1 end
  end
  local id=item:GetAttribute("ArrowId");if id then arrowIds[id]=true end
 end
 for _ in arrowIds do row.arrows+=1 end
 return row
end
local originals=roblox.deserializeModel(fs.readFile(beforeFile));assert(#originals==2)
report.reopenedCounts={}
for index,model in models do
 local current,before=counts(model),counts(originals[index])
 local expectedParts=before.parts-before.worldParts+487
 local expectedMeshes=before.meshes-before.worldParts+487
 assert(current.parts==expectedParts and current.meshes==expectedMeshes,"Reopened complete model counts differ from preserved non-art plus487mesh scenery")
 assert(current.worldParts==487 and current.colliders==147 and current.floors==135 and current.redContacts==55 and current.arrows==19)
 table.insert(report.reopenedCounts,{index=index,name=model.Name,current=current,baseline=before,expectedParts=expectedParts,expectedMeshes=expectedMeshes})
end
report.inputHashes={}
for _,file in {modelFile,kitFile,erFile,planFile,beforeFile,baselineFile,auditFile,templateFile} do report.inputHashes[file]=serde.hash("sha256",fs.readFile(file)) end
report.pass=report.geometryPass and sourceGuard.pass
report.savedModelReopen=true;report.nativeLiveCompared=false;report.finalVisualJudgment=false
fs.writeFile(own.."frozen49-reopen-report.json",serde.encode("json",report,true))
print(serde.encode("json",{pass=report.pass,geometryPass=report.geometryPass,failures=report.failures,models=report.models,filesystemSourceGuard=sourceGuard}))
assert(report.pass,"Frozen scenery differs; see owned reopen report")
