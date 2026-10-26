local fs,roblox,serde,luau=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/luau")
local own="tools/moonlit-citadel/phase3/repair-20261019/overlap/"
local root="docs/artifacts/moonlit-citadel/phase3/repair-20261019/"
local V,C=roblox.Vector3,roblox.CFrame
local helperRaw=fs.readFile(own.."SurfaceSeparation.proposed.luau")
local helper=luau.load(helperRaw,{environment={Vector3=V,CFrame=C}})()
local Capture=luau.load(fs.readFile("tools/moonlit-citadel/phase3/detail-pass-20261014/verification/CaptureSnapshot53.luau"),{environment={Vector3=V,CFrame=C}})()
local expected=serde.decode("json",fs.readFile(own.."remaining-family-closure.proposed.json"))
local artRaw=fs.readFile("tools/moonlit-citadel/phase3/repair-20261019/art/proposal03/art-plan.json")
local art=serde.decode("json",artRaw)
assert(serde.hash("sha256",artRaw)==expected.artPlanSHA256 and expected.pass)
local input=fs.readFile(root.."repair_before_models.rbxm")
local models=roblox.deserializeModel(input)
assert(#models==2)
local nativeRaw=fs.readFile(root.."before/native-snapshot54.json")
local native=serde.decode("json",nativeRaw)
local function v(a)return V.new(a[1],a[2],a[3])end
local function cf(a)return C.new(table.unpack(a))end
local function resolve(parent,path)for name in path:gmatch("[^/]+")do parent=assert(parent:FindFirstChild(name),path)end;return parent end
local function close(a,b)return(a-b).Magnitude<.003 end
local function equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~="table"then return a==b end
 for key,value in a do if not equal(value,b[key])then return false end end
 for key in b do if a[key]==nil then return false end end
 return true
end
local function modelData(unit)
 return{name=unit.Name,asset=unit:GetAttribute("MCEditUnit"),scale=unit:GetAttribute("AuthorScale"),localCF=unit:GetAttribute("CourseLocalFrame")}
end
local results,patches={},{}
for index,model in models do
 assert(model:GetAttribute("CourseId")=="moonlit_citadel")
 local nativeModel=native[if index==1 then "editable"else"stored"]
 local supplemented=0
 for path,record in nativeModel.records do
  if record.class=="Model" and record.props.WorldPivot then
   resolve(model,path).WorldPivot=cf(record.props.WorldPivot.value);supplemented+=1
  end
 end
 local world=model.Decoration.Phase3World
 local units={}
 for _,district in world:GetChildren()do for _,unit in district:GetChildren()do if unit:IsA("Model")then units[unit.Name]=unit end end end
 local sameAssetEdits=0
 for _,edit in art.replacements do
  if edit.before.asset~=edit.after.asset then continue end
  local old,new=edit.before,edit.after;local unit=assert(units[old.name])
  local oldFrame=C.new(model:GetAttribute("Origin"))*cf(old.localCF)
  local newFrame=C.new(model:GetAttribute("Origin"))*cf(new.localCF)
  for _,part in unit:GetDescendants()do if part:IsA("BasePart")then
   local localFrame=oldFrame:ToObjectSpace(part.CFrame)
   part.CFrame=newFrame*C.new(localFrame.Position/v(old.scale)*v(new.scale))*localFrame.Rotation
   part.Size=part.Size/v(old.scale)*v(new.scale)
  end end
  unit.WorldPivot=newFrame
  unit:SetAttribute("AuthorScale",v(new.scale));unit:SetAttribute("CourseLocalFrame",cf(new.localCF))
  sameAssetEdits+=1
 end
 local before=Capture.CaptureModel(model)
 local floorCount=helper.ApplyFloorSkins(model)
 local worldCount=0
 for _,unit in units do worldCount+=helper.ApplyWorldUnit(unit,modelData(unit))end
 local cosmeticCount=helper.ApplyRouteCosmetics(model)
 assert(floorCount==135 and worldCount==51 and cosmeticCount==14)
 local allowed={}
 for _,row in expected.operations do
  local part=resolve(model,row.nativePath)
  assert(close(part.Size,v(row.nativeSizeAfter)),"Expected final Size differs: "..row.nativePath)
  assert(close(part.CFrame.Position-model:GetAttribute("Origin"),v(row.art03PositionAfter)),"Expected final position differs: "..row.nativePath)
  local rotation=C.new(0,0,0,table.unpack(row.nativeRotation))
  local actual={part.CFrame.Rotation:GetComponents()};local target={rotation:GetComponents()}
  for component=4,12 do assert(math.abs(actual[component]-target[component])<.00001,"Part rotation changed")end
  allowed[row.nativePath]={size=not close(v(row.art03SizeBefore),v(row.nativeSizeAfter)),frame=v(row.courseLocalPositionDelta).Magnitude>0}
  if index==1 then table.insert(patches,{path=row.nativePath,beforeSize=row.art03SizeBefore,afterSize={part.Size.X,part.Size.Y,part.Size.Z},
   beforeCoursePosition=row.art03PositionBefore,afterCFrame={part.CFrame:GetComponents()},rules=row.rules})end
 end
 local after=Capture.CaptureModel(model)
 local changes,unexpected={},{}
 local sizeKeys={Size=true,size=true,ExtentsSize=true}
 local frameKeys={CFrame=true,CoordinateFrame=true,Position=true,position=true}
 for path,old in before.records do
  local current=assert(after.records[path],"No instance may disappear")
  for key,value in old do if key~="props"then assert(equal(value,current[key]),"Instance identity/attrs/tags/presence changed:"..path.."/"..key)end end
  for key,value in old.props do if not equal(value,current.props[key])then
   local target=allowed[path]
   local permitted=target and(target.size and sizeKeys[key]or target.frame and frameKeys[key])
   local row={path=path,property=key}
   table.insert(if permitted then changes else unexpected,row)
  end end
 end
 assert(#unexpected==0,serde.encode("json",unexpected))
 local again=pcall(helper.ApplyFloorSkins,model);assert(not again,"Duplicate floor pass must refuse")
 local againWindow=pcall(helper.ApplyWorldUnit,units.UpperKeepWarmLancet1MC_WindowFrame,modelData(units.UpperKeepWarmLancet1MC_WindowFrame));assert(not againWindow)
 local againRoute=pcall(helper.ApplyRouteCosmetics,model);assert(not againRoute)
 table.insert(results,{model=index,existingRecords=before.counts.instances,retainedRecords=after.counts.instances,
   floorMeshes=floorCount,worldMeshes=worldCount,routeCosmeticMeshes=cosmeticCount,changedProperties=#changes,
   sameAssetArtPosesSimulated=sameAssetEdits,unexpectedChanges=unexpected,pass=true})
 results[#results].nativeWorldPivotsSupplemented=supplemented
end
local report={pass=true,models=results,inputModelsSHA256=serde.hash("sha256",input),helperSHA256=serde.hash("sha256",helperRaw),
 artPlanSHA256=expected.artPlanSHA256,nativeSnapshotSHA256=serde.hash("sha256",nativeRaw),existingVisiblePairsSeparated=#expected.checks,
 scope="Actual saved model copies with50 same-asset art03 poses and200 explicit visual-only adjustments; six banner asset replacements/five retirements remain the art author's independent assembly",studioTouched=false,productionChanged=false}
fs.writeFile(own.."surface-separation-unit-tests.json",serde.encode("json",report,true).."\n")
fs.writeFile(own.."expected-native-patch-manifest.json",serde.encode("json",{source=54,artPlanSHA256=expected.artPlanSHA256,helperSHA256=report.helperSHA256,
 existingVisiblePairProof="remaining-family-closure.proposed.json",operations=patches},true).."\n")
print(serde.encode("json",report))
