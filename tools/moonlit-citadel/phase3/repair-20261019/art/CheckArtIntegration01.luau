local fs,serde,luau,rbx=require("@lune/fs"),require("@lune/serde"),require("@lune/luau"),require("@lune/roblox")
local own="tools/moonlit-citadel/phase3/repair-20261019/art/"
local raw=fs.readFile(own.."integration01/ArtRepairPlan.luau")
luau.compile(raw)
local environment={CFrame=rbx.CFrame,Vector3=rbx.Vector3,Color3=rbx.Color3}
local Art=luau.load(raw,{environment=environment})()
local proposal=serde.decode("json",fs.readFile(own.."proposal03/art-plan.json"))
local baseline=serde.decode("json",fs.readFile(proposal.basePlanPath))
local input,architecture,outer,mounts,expected={},{},{},{},{}
for _,row in baseline.units do
 local unit=table.clone(row);unit.localCF=rbx.CFrame.new(table.unpack(row.localCF));unit.scale=rbx.Vector3.new(table.unpack(row.scale))
 table.insert(input,unit)
 if row.district=="RoutePlanting" then
  table.insert(outer,unit)
  if string.sub(row.name,-#"CarvedBasin")=="CarvedBasin" then
   local name=string.sub(row.name,1,#row.name-#"CarvedBasin")
   local support="Gallery"..string.sub(name,8,8)..(if string.sub(name,-4)=="Left" then "PlanterShelf-1" else "PlanterShelf1")
   table.insert(mounts,{name=name,frame=unit.localCF,supportName=support,district="LanternPendulums"})
  end
 else table.insert(architecture,unit) end
end
for _,row in proposal.units do expected[row.name]=row end
local whole=Art.Apply(input)
local a,e=Art.Apply(architecture,"Architecture"),Art.Apply(outer,"Environment")
assert(#whole==315 and #a==303 and #e==12)
local function check(unit)
 local row=assert(expected[unit.name])
 assert(unit.asset==row.asset and unit.library==row.library)
 assert((unit.localCF.Position-rbx.Vector3.new(table.unpack(row.localCF,1,3))).Magnitude<.00004)
 assert((unit.scale-rbx.Vector3.new(table.unpack(row.scale))).Magnitude<.000001)
 local components={unit.localCF:GetComponents()}
 for index=4,12 do assert(math.abs(components[index]-row.localCF[index])<.000001) end
end
for _,unit in a do check(unit) end
for _,unit in e do check(unit) end
local revised=Art.RevisePlantingMounts(mounts)
assert(#revised==6 and revised~=mounts)
for index,mount in revised do assert(mount~=mounts[index] and mount.name==mounts[index].name and mount.supportName==mounts[index].supportName) end
local extra={name="UnrelatedPlanting",supportName="ExistingElsewhere",frame=rbx.CFrame.new(50,10,10)}
local withExtra=table.clone(mounts);table.insert(withExtra,extra)
assert(Art.RevisePlantingMounts(withExtra)[7]==extra)
local cache={};local archive="docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/archive/packet-source/"
local nodes=setmetatable({},{__index=function(_,name)return {name=name}end})
local inputHashes={}
local function load(name)
 if cache[name] then return cache[name] end
 local source=fs.readFile(archive..name..".luau");inputHashes[name]=serde.hash("sha256",source)
 local env=table.clone(environment);env.script={Parent=nodes};env.require=function(node)return load(node.name)end
 local result=luau.load(source,{environment=env})();cache[name]=result;return result
end
local actualEnvironment=load("EnvironmentPlan")
local generated,counts=actualEnvironment.Get({},revised,nil)
local applied=Art.Apply(generated,"Environment")
local generatedByName={};for _,unit in applied do generatedByName[unit.name]=unit end
local checked=0
for index,mount in revised do
 local basin=assert(generatedByName[mount.name.."CarvedBasin"])
 local fern=assert(generatedByName[mount.name.."Fern"])
 check(basin);check(fern);checked+=2
 assert(basin.localCF==mount.frame and counts.groundedPockets[index].frame==mount.frame)
 assert(counts.groundedPockets[index].supportName==mount.supportName)
end
assert(checked==12 and #counts.groundedPockets==6)
local occupiedChecked=0
for _,row in counts.proposalRows do
 local name=string.match(row.path,"^Landscape/(Gallery%d+[LR]%a+)/Solid1$")
 if not name then continue end
 local unit=assert(generatedByName[name])
 local centre=if unit.asset=="MC_P3_PlantPocket" then rbx.Vector3.new(0,1.55,0) else rbx.Vector3.new(0,.88,0)
 local wanted=unit.localCF*rbx.CFrame.new(centre*unit.scale)
 local actual=rbx.CFrame.new(table.unpack(row.frame))
 assert((actual.Position-wanted.Position).Magnitude<.00004,"Occupied planting row uses an old mount")
 occupiedChecked+=1
end
assert(occupiedChecked==12)
local guards={}
for _,scope in {"Architecture","Environment"} do
 local source=if scope=="Architecture" then architecture else outer
 local missing=table.clone(source)
 local target=if scope=="Architecture" then "LanternWallBracket1" else "Gallery1LeftFern"
 for index,unit in missing do if unit.name==target then table.remove(missing,index);break end end
 guards[scope.."MissingRejected"]=not pcall(function()Art.Apply(missing,scope)end)
 assert(guards[scope.."MissingRejected"])
end
local missingMount=table.clone(mounts);table.remove(missingMount,1)
guards.missingMountRejected=not pcall(function()Art.RevisePlantingMounts(missingMount)end)
guards.invalidScopeRejected=not pcall(function()Art.Apply(input,"Anything")end)
guards.fullMissingRejected=not pcall(function()Art.Apply(architecture)end)
assert(guards.missingMountRejected and guards.invalidScopeRejected and guards.fullMissingRejected)
local report={pass=true,geometryAndPosesUnchangedFromProposal03=true,fullResultUnits=#whole,splitResultUnits=#a+#e,
 architectureReplacements=44,architectureRetirements=5,environmentReplacements=12,revisedMounts=6,
 actualEnvironmentGeneratedUnits=#generated,actualEnvironmentGroundedPockets=#counts.groundedPockets,
 generatedPlantsMatchFinalPlan=checked,generatedPlantOccupiedRowsMatchFinalMounts=occupiedChecked,unrelatedMountSameTable=true,strictGuards=guards,
 source54EnvironmentInputHashes=inputHashes,stagedModuleSHA256=serde.hash("sha256",raw),
 proposal03PlanSHA256=serde.hash("sha256",fs.readFile(own.."proposal03/art-plan.json")),
 productionEdited=false,studioTouched=false,boundary="Scoped integration only. Actual Environment.Get uses revised mounts before generating counts and occupied rows; the strict Environment Apply verifies/reapplies the same twelve final plant poses."}
fs.writeFile(own.."integration01/integration-check.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
