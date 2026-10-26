local fs,roblox,serde,luau=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/luau")
local own="tools/moonlit-citadel/phase3/final-surfaces-20261020/internal/"
local sourceRoot="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local repair="docs/artifacts/moonlit-citadel/phase3/repair-20261019/"
local manifestRaw=fs.readFile("tools/moonlit-citadel/phase3/final-surfaces-20261020/neighbors/FINAL_POSE136.json")
local manifest=serde.decode("json",manifestRaw)
local V,C=roblox.Vector3,roblox.CFrame
local raw=fs.readFile(sourceRoot.."SurfaceFinishingPlan.luau")
local finishing=luau.load(raw,{environment={Vector3=V,CFrame=C,Color3=roblox.Color3,Enum=roblox.Enum}})()
assert(finishing.ManifestSHA256==serde.hash("sha256",manifestRaw))
local capture=luau.load(fs.readFile("tools/moonlit-citadel/phase3/detail-pass-20261014/verification/CaptureSnapshot53.luau"),{environment={Vector3=V,CFrame=C}})()
local function resolve(parent,path) for name in path:gmatch("[^/]+")do parent=assert(parent:FindFirstChild(name),path)end;return parent end
local function v(a)return V.new(a[1],a[2],a[3])end
local function cf(a)return C.new(table.unpack(a))end
local function closeVector(a,b)return(a-b).Magnitude<.003 end
local function closeFrame(a,b)
 local x,y={a:GetComponents()},{b:GetComponents()}
 for i=1,12 do assert(math.abs(x[i]-y[i])<.003,"Pose differs")end
end
local allowed={}
for _,op in manifest.operations do
 allowed[op.path]={size=not capture.Equal(op.beforeSize,op.afterSize),frame=not capture.Equal(op.beforeCFrame,op.afterCFrame)}
end
local input=fs.readFile(repair.."repair_final55_models.rbxm")
local models=roblox.deserializeModel(input)
local old=roblox.deserializeModel(fs.readFile(repair.."repair_before_models.rbxm"))
local snapshot=serde.decode("json",fs.readFile(repair.."final/native-snapshot55.json"))
local oldSnapshot=serde.decode("json",fs.readFile(repair.."before/native-snapshot54.json"))
assert(#models==2 and #old==2)
local results={}
for index,model in models do
 local ridge=model.Decoration.Phase3World.JoinedRavineRidges
 ridge.MC_EC_InnerRavine:Destroy()
 old[index].Decoration.Phase3World.JoinedRavineRidges.MC_EC_InnerRavine:Clone().Parent=ridge
 local native=snapshot[if index==1 then"editable"else"stored"]
 local oldNative=oldSnapshot[if index==1 then"editable"else"stored"]
 for path,record in native.records do
  if record.class=="Model" and record.props.WorldPivot and not path:find("/MC_EC_InnerRavine",1,true)then
   resolve(model,path).WorldPivot=cf(record.props.WorldPivot.value)
  end
 end
 local floor=resolve(model,"Decoration/Phase3World/JoinedRavineRidges/MC_EC_InnerRavine")
 floor.WorldPivot=cf(oldNative.records["Decoration/Phase3World/JoinedRavineRidges/MC_EC_InnerRavine"].props.WorldPivot.value)
 local meshIdSupplemented=0
 for _,op in manifest.operations do
  local part=resolve(model,op.path)
  local readable,value=pcall(function()return part.MeshId end)
  if not readable then
   assert(native.records[op.path].props.MeshId==op.meshId)
   part.MeshId=op.meshId
   meshIdSupplemented+=1
  else assert(value==op.meshId) end
 end
 local before=capture.CaptureModel(model)
 assert(before.counts.parts==1763 and before.counts.meshes==1469)
 local finalTarget=resolve(model,manifest.operations[#manifest.operations].path)
 assert(not finalTarget.CanQuery)
 finalTarget.CanQuery=true
 local firstRoute=resolve(model,"Obstacles/ArchCatchReturn/Ramp_2/StoneSkin/MC_FloorStone__Floor")
 local untouchedFrame=firstRoute.CFrame
 local preflightOK=pcall(finishing.ApplyRoute,model)
 assert(not preflightOK and firstRoute.CFrame==untouchedFrame,"Route must preflight all targets before any write")
 finalTarget.CanQuery=false
 local routeCount=finishing.ApplyRoute(model)
 assert(routeCount==107)
 local worldCount=0
 local firstWorld,firstData
 for _,district in model.Decoration.Phase3World:GetChildren()do
  for _,unit in district:GetChildren()do
   if not unit:IsA("Model")then continue end
   local data={district=district.Name,name=unit.Name,asset=unit:GetAttribute("MCEditUnit")}
   local count=finishing.ApplyWorldUnit(model,unit,data)
   if count>0 then firstWorld,firstData=unit,data end
   worldCount+=count
  end
 end
 assert(worldCount==29)
 for _,op in manifest.operations do
  local part=resolve(model,op.path)
  assert(closeVector(part.Size,v(op.afterSize)),op.path)
  closeFrame(part.CFrame,cf(op.afterCFrame))
 end
 local after=capture.CaptureModel(model)
 assert(before.counts.instances==after.counts.instances)
 local changes,unexpected={},{}
 local sizeKeys={Size=true,size=true,ExtentsSize=true}
 local frameKeys={CFrame=true,CoordinateFrame=true,Position=true,position=true}
 for path,record in before.records do
  local current=assert(after.records[path],"Existing instance disappeared")
  for key,value in record do if key~="props"then assert(capture.Equal(value,current[key]),"Identity,flags,attrs,tags changed:"..path.."/"..key)end end
  for key,value in record.props do
   if capture.Equal(value,current.props[key])then continue end
   local op=allowed[path]
   local permitted=op and(op.size and sizeKeys[key]or op.frame and frameKeys[key])
   table.insert(if permitted then changes else unexpected,{path=path,property=key})
  end
 end
 assert(#unexpected==0,serde.encode("json",unexpected))
 assert(not pcall(finishing.ApplyRoute,model),"Repeated route finishing must reject")
 assert(not pcall(finishing.ApplyWorldUnit,model,firstWorld,firstData),"Repeated world finishing must reject")
 table.insert(results,{model=index,parts=after.counts.parts,meshes=after.counts.meshes,instances=after.counts.instances,
  worldTargets=worldCount,routeTargets=routeCount,changedProperties=#changes,unexpectedChanges=unexpected,
  guardPreflight=true,repeatRejected=true,nativeMeshIdSupplementedForLune=meshIdSupplemented,pass=true})
end
local compiled=0
for _,name in fs.readDir(sourceRoot)do if name:sub(-5)==".luau"then luau.compile(fs.readFile(sourceRoot..name));compiled+=1 end end
assert(compiled>=35)
local worldRaw,visualRaw=fs.readFile(sourceRoot.."WorldAssembly.luau"),fs.readFile(sourceRoot.."VisualAssembly.luau")
assert(visualRaw:find("Separation.ApplyFloorSkins(course)",1,true)<visualRaw:find("flatFloorLayers(course)",visualRaw:find("function Assembly.Apply",1,true),true))
local layer=assert(visualRaw:find("local layered, maximum = flatFloorLayers(course)",1,true))
local finish=assert(visualRaw:find("Finishing.ApplyRoute(course)",1,true))
local top=assert(visualRaw:find("if contact:GetAttribute(\"MCWalkable\") == true then visualTop(contact) end",1,true))
assert(layer<finish and finish<top)
local report={pass=true,manifestSHA256=finishing.ManifestSHA256,sourceSHA256=serde.hash("sha256",raw),models=results,
 compiledBuilderModules=compiled,sourceRevision=finishing.SourceRevision,buildRevision=finishing.BuildRevision,
 source55SavedModelsSHA256=serde.hash("sha256",input),originalFloorRestoredFrom54=true,
 scope="Both actual saved Source55 models with the exact original54 floor restored to Source56; twelve transparent veil anchors are unchanged and omitted from fixture; source-only136-part finishing; no native edits",studioTouched=false}
fs.writeFile(own.."surface-finishing-unit-tests.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
