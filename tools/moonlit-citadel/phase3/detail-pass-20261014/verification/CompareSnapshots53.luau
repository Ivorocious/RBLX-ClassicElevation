--!nonstrict
local Compare = {}
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for key,value in a do if not equal(value,b[key]) then return false end end
    for key in b do if a[key]==nil then return false end end
    return true
end
local function additionPaths(plan)
    local units,folders={},{}
    for _,data in plan do
        if data.library~="DT01" then continue end
        assert(type(data.name)=="string" and type(data.district)=="string" and data.asset,"Bind each exact DT01 addition")
        assert(not data.name:find("/",1,true) and not data.district:find("/",1,true),"Detail names must be single path segments")
        local parent="Decoration/Phase3World/"..data.district
        local path=parent.."/"..data.name
        assert(not units[path],"Duplicate exact detail unit path")
        units[path]=data;folders[parent]=true
    end
    return units,folders
end

function Compare.Run(before,after,context)
    assert(before and after and context and context.expected and context.plan,"Bind fresh baseline, actual after snapshot and final plan")
    local units,folders=additionPaths(context.plan.units or context.plan)
    local expected=context.expected
    local allowed={
        [""]={SourceRevision=expected.source,BuildRevision=expected.build,SourcePacketHash=expected.packet,CandidateId=expected.candidate},
        ["Decoration/Phase3World"]={PlanUnits=expected.units,MeshParts=expected.meshes,PlacedTriangles=expected.triangles},
    }
    for path,attrs in context.detailAttributes or {} do
        assert(path=="" or path=="Decoration/Phase3World","Additional candidate attrs belong only on the course/world roots")
        for key,value in attrs do
            assert(key:match("^Detail") or key=="Phase3DetailsApplied","Only explicitly bound new detail attrs are allowed")
            allowed[path][key]=value
        end
    end
    local report={pass=true,models={},failures={},failureCount=0,ownerContext={lightingExact=false,cameraExact=false},
        additiveOnly=true,allExistingArtCompared=true,nativeTemporalJudgment=false,detailsExpected=0}
    for _ in units do report.detailsExpected+=1 end
    assert(report.detailsExpected>0 and report.detailsExpected<=90,"Bind the bounded actual detail plan")
    local function fail(model,path,field)
        report.pass=false;report.failureCount+=1
        if #report.failures<100 then table.insert(report.failures,{model=model,path=path,field=field}) end
    end
    for _,name in {"editable","stored"} do
        local a,b=assert(before[name]),assert(after[name])
        local row={name=name,existingRecords=0,exactExistingRecords=0,newRecords=0,newUnits=0,newMeshes=0,allowedAttributeChanges=0}
        local found={}
        for path,old in a.records do
            row.existingRecords+=1
            local actual=b.records[path]
            if not actual then fail(name,path,"Missing existing object");continue end
            local beforeFailures=report.failureCount
            for _,field in {"class","name","props","unavailable","tags"} do
                if not equal(old[field],actual[field]) then fail(name,path,field) end
            end
            local keys={};for key in old.attrs do keys[key]=true end;for key in actual.attrs do keys[key]=true end
            for key in keys do
                local approved=allowed[path] and allowed[path][key]
                if approved~=nil then
                    if not equal(actual.attrs[key],approved) then fail(name,path,"Bound candidate attr "..key)
                    elseif not equal(old.attrs[key],actual.attrs[key]) then row.allowedAttributeChanges+=1 end
                elseif not equal(old.attrs[key],actual.attrs[key]) then fail(name,path,"Existing attr "..key) end
            end
            if beforeFailures==report.failureCount then row.exactExistingRecords+=1 end
        end
        for path,actual in b.records do
            if a.records[path] then continue end
            row.newRecords+=1
            local owner,unitPath
            for prefix,data in units do
                if path==prefix or path:sub(1,#prefix+1)==prefix.."/" then owner,unitPath=data,prefix;break end
            end
            if owner then
                if path==unitPath then
                    if actual.class~="Model" or actual.attrs.MCEditUnit~=owner.asset or actual.attrs.District~=owner.district
                        or actual.attrs.MaterialRole~=(owner.materialRole or "WorldArt") then fail(name,path,"Added unit identity") end
                    found[unitPath]=true;row.newUnits+=1
                elseif actual.class=="MeshPart" then
                    row.newMeshes+=1
                    if actual.props.Anchored~=true or actual.props.CanCollide~=false or actual.props.CanQuery~=false or actual.props.CanTouch~=false then
                        fail(name,path,"New detail mesh contact flags")
                    end
                elseif actual.class~="Folder" then fail(name,path,"Unexpected added detail descendant class") end
            elseif folders[path] and actual.class=="Folder" then
                if next(actual.attrs)~=nil then fail(name,path,"Unbound new district attrs") end
            else fail(name,path,"Unexpected added object") end
        end
        for path in units do
            if a.records[path] then fail(name,path,"DT01 path collides with existing art") end
            if not found[path] then fail(name,path,"Missing exact new detail unit") end
        end
        for _,key in {"colliders","walkables","hazards","arrows"} do
            if a.counts[key]~=b.counts[key] then fail(name,"counts",key) end
        end
        if b.counts.artUnits~=expected.units or b.counts.artMeshes~=expected.meshes then fail(name,"counts","Final world ledger") end
        if row.newUnits~=report.detailsExpected or row.newMeshes~=(expected.meshes-a.counts.artMeshes) then fail(name,"counts","Additive detail ledger") end
        row.before=a.counts;row.after=b.counts
        table.insert(report.models,row)
    end
    if before.lighting or after.lighting then
        report.ownerContext.lightingExact=equal(before.lighting,after.lighting)
        if not report.ownerContext.lightingExact then fail("owner","Lighting","Owner lighting changed") end
    else report.ownerContext.lightingExact="Not captured in saved-model comparison" end
    if before.camera or after.camera then
        report.ownerContext.cameraExact=equal(before.camera,after.camera)
        if not report.ownerContext.cameraExact then fail("owner","CurrentCamera","Owner camera changed") end
    else report.ownerContext.cameraExact="Not captured in saved-model comparison" end
    if not equal(before.propertySchema,after.propertySchema) then fail("snapshot","schema","Property schema changed") end
    report.failureDetailsCapped=report.failureCount>#report.failures
    return report
end
return Compare
