local fs,roblox,serde,luau,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/luau"),require("@lune/process")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/"
local frozen="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local bindingPath=process.args[1] or own.."bindings54.json"
local bindings=serde.decode("json",fs.readFile(bindingPath));assert(bindings.ready,"Bind the actual final detail inputs")
local expected=bindings.expected
local hashes={}
local function bound(key)
    local entry=assert(bindings.inputs[key],"Missing exact input "..key)
    local raw=fs.readFile(entry.path)
    local hash=serde.hash("sha256",raw);assert(hash==entry.sha256,"Input binding differs: "..key)
    hashes[entry.path]=hash;return raw
end
local function module(path,environment)
    local raw=fs.readFile(path);hashes[path]=serde.hash("sha256",raw)
    return luau.load(raw,{environment=environment or {Vector3=roblox.Vector3,CFrame=roblox.CFrame}})()
end
local Capture=module(frozen.."CaptureSnapshot53.luau")
local Compare=module(frozen.."CompareSnapshots53.luau")
local oldModels=roblox.deserializeModel(bound("baselineModels"))
local newModels=roblox.deserializeModel(bound("candidateModels"))
assert(#oldModels==2 and #newModels==2,"Both actual course roots must reopen")
local function state(models) return {schema=1,editable=Capture.CaptureModel(models[1]),stored=Capture.CaptureModel(models[2]),propertySchema=Capture.Schema} end
local before,after=state(oldModels),state(newModels)
local plan=serde.decode("json",bound("plan"))
local preservation=Compare.Run(before,after,{plan=plan,expected=expected,detailAttributes=bindings.detailAttributes})
local manifest=serde.decode("json",bound("dtManifest"))
local costs={};for _,part in manifest.export_parts do assert(not costs[part.name]);costs[part.name]=part end
local oldTriangleCount=oldModels[1].Decoration.Phase3World:GetAttribute("PlacedTriangles")
local planned={};for _,unit in plan.units do planned[unit.district.."/"..unit.name]=unit end
local counts={}
for index,model in newModels do
    local world=model.Decoration.Phase3World
    local row={index=index,addedUnits=0,addedMeshes=0,addedTriangles=0}
    for _,district in world:GetChildren() do for _,unit in district:GetChildren() do
        if not unit:IsA("Model") then continue end
        local data=assert(planned[district.Name.."/"..unit.Name],"Native unit must belong to final plan")
        if data.library~="DT01" then continue end
        row.addedUnits+=1
        for _,part in unit:GetDescendants() do if part:IsA("BasePart") then
            assert(part:IsA("MeshPart") and part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,"Detail parts are visual-only meshes")
            local measured=assert(costs[part.Name],"New part must belong to measured DT01 manifest")
            assert(measured.asset==data.asset and part:GetAttribute("SourceMaterial")~=nil,"DT01 asset/material binding")
            local tag=part:GetAttribute("SourceTriangles");assert(tag==nil or tag==measured.triangles,"Measured triangle tag differs")
            row.addedMeshes+=1;row.addedTriangles+=measured.triangles
        end end
    end end
    assert(row.addedUnits+243==expected.units and row.addedMeshes+639==expected.meshes,"Actual additive world counts differ")
    assert(row.addedTriangles+oldTriangleCount==expected.triangles and world:GetAttribute("PlacedTriangles")==expected.triangles,"Measured additive triangle ledger differs")
    table.insert(counts,row)
end
assert(expected.units<=350 and expected.meshes<=900 and expected.triangles<=420000 and expected.architecture<=260,"Approved resource limits exceeded")
local packetRaw=bound("packet")
assert(serde.hash("sha256",packetRaw)==expected.packet,"Final exact source packet binding required")
local packet=serde.decode("json",packetRaw)
assert(packet.sourceRevision==expected.source and packet.buildRevision==expected.build and packet.candidate==expected.candidate,"Packet identity differs")
local function scriptMap(raw)
    local result={};local function add(item)
        if not item:IsA("LuaSourceContainer") then return end
        assert(not result[item.Name],"Unique packet module names required")
        result[item.Name]={source=item.Source:gsub("\r\n","\n"),class=item.ClassName}
    end
    for _,root in roblox.deserializeModel(raw) do add(root);for _,item in root:GetDescendants() do add(item) end end
    return result
end
local oldScripts,newScripts=scriptMap(bound("baselineModules")),scriptMap(bound("candidateModules"))
local baselinePacketRaw=bound("baselinePacket52")
local baselinePacket=serde.decode("json",baselinePacketRaw)
assert(baselinePacket.sourceRevision==52 and serde.hash("sha256",baselinePacketRaw)==oldModels[1]:GetAttribute("SourcePacketHash"),"The omitted external config must bind to the actual baseline identity")
local priorConfig
for _,record in baselinePacket.records do if record.name=="MoonlitCitadelAmbienceConfig" then assert(not priorConfig);priorConfig=record end end
assert(priorConfig and serde.hash("sha256",priorConfig.source)==priorConfig.sha256,"Exact existing config source record required")
local freshInventory=serde.decode("json",bound("baselineDurableInventory"))
local freshConfig
for _,record in freshInventory do if record.path=="src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau" then assert(not freshConfig);freshConfig=record end end
assert(freshConfig and freshConfig.sha256==priorConfig.sha256,"Existing config must also match the fresh pass baseline")
assert(not oldScripts.MoonlitCitadelAmbienceConfig and newScripts.MoonlitCitadelAmbienceConfig,"Only the specifically omitted external baseline config is supplemented")
local oldBuilderCount=0;for _ in oldScripts do oldBuilderCount+=1 end
assert(oldBuilderCount==29,"Fresh baseline exported the29 builders without external config")
oldScripts.MoonlitCitadelAmbienceConfig={source=priorConfig.source,class="ModuleScript"}
local expectedSources={};local sourceParity={}
for _,record in packet.records do
    assert(not expectedSources[record.name]);expectedSources[record.name]=true
    assert(serde.hash("sha256",record.source)==record.sha256)
    local actual=assert(newScripts[record.name],"Saved final module missing: "..record.name)
    assert(actual.class=="ModuleScript" and actual.source==record.source,"Saved module text differs from exact packet")
    local durable=assert(bindings.durableFiles[record.name],"Bind durable file per packet module")
    local durableRaw=fs.readFile(durable):gsub("\r\n","\n")
    assert(durableRaw==record.source,"Durable source parity differs: "..record.name)
    table.insert(sourceParity,{name=record.name,sha256=record.sha256,durableFile=durable,pass=true})
end
for name in newScripts do assert(expectedSources[name],"Unexpected saved final source module "..name) end
for name,old in oldScripts do
    local actual=assert(newScripts[name],"Existing saved source module removed")
    if name~="WorldPlan" and name~="WorldAssembly" then assert(old.source==actual.source and old.class==actual.class,"Unapproved existing source edit: "..name) end
end
for name in newScripts do if not oldScripts[name] then assert(name=="DetailPlan" or name=="DetailGeometry","Only the two authorized new detail modules may be added") end end
local geometry=module("tools/moonlit-citadel/phase3/closeout-20261014/verification52/GeometryAudit52.luau")
local override=module("tools/moonlit-citadel/phase3/closeout-20261014/verification52/PartAdjustmentOracle52.luau",{Vector3=roblox.Vector3})
assert(override.ValidatePlan(plan.units).pass,"Accepted existing part override must remain exact")
local libraries={}
for _,library in roblox.deserializeModel(bound("baseLibraries")) do for key,name in geometry.LibraryNames do if library.Name==name then libraries[key]=library end end end
libraries.ER01=roblox.deserializeModel(bound("verifiedER01"))[1]
local dt=roblox.deserializeModel(bound("verifiedDT01"));assert(#dt==1 and dt[1].Name==bindings.dtLibraryName)
libraries.DT01=dt[1]
local geometryResult=geometry.Run(newModels,libraries,plan,{expectedIdentity={source=expected.source,build=expected.build,packet=expected.packet},
    expectedUnits=expected.units,expectedMeshes=expected.meshes,expectedCourses=2,requireSourceGuard=false,adjustmentOracle=override,
    approvedTemplateMetadata=serde.decode("json",bound("approvedER01Metadata"))})
local report={pass=preservation.pass and geometryResult.geometryPass,expected=expected,preservation=preservation,geometry=geometryResult,
    additiveMeasuredCounts=counts,sourceParity=sourceParity,inputHashes=hashes,savedModelOnly=true,studioTouched=false,
    fullNativeBaselineComparedHere=false,nativeAppearanceVerified=false,
    savedBaselineExternalConfig={name="MoonlitCitadelAmbienceConfig",builderModules=oldBuilderCount,source52PacketSHA256=serde.hash("sha256",baselinePacketRaw),freshSourceSHA256=freshConfig.sha256,scope="Fresh before export is builder Folder only; external config is bound independently to source52 packet and fresh durable inventory"},
    boundary="Saved models, arrays, measured counts and exact packet/module parity reopen here. Fresh native snapshot, all other maps/common sources and rendered quality require the lead's separate native proof."}
local output=bindings.output or own.."saved-correction-reopen.json"
fs.writeFile(output,serde.encode("json",report,true).."\n")
print(serde.encode("json",{pass=report.pass,counts=counts,sourceModules=#sourceParity,preservationFailures=preservation.failureCount,geometryFailures=#geometryResult.failures,output=output}))
assert(report.pass,"Saved additive detail candidate differs from exact intended changes")
