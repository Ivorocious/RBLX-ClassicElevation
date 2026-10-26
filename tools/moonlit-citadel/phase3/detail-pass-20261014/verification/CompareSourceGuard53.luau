--!nonstrict
local Guard = {}
local owned="ServerStorage.MoonlitP3ReworkRecovery.DetailPass20261014"
local prefix="ServerStorage.CourseBuilders.MoonlitCitadelCourse."
local allowedNames={WorldPlan=true,WorldAssembly=true,DetailPlan=true,DetailGeometry=true}
local function ownedPath(path) return path==owned or path:sub(1,#owned+1)==owned.."." end
local function index(rows)
    local result={}
    for _,row in rows do
        assert(type(row.path)=="string" and type(row.sha256)=="string","Use actual native full source paths and SHA256")
        if ownedPath(row.path) then continue end
        assert(not result[row.path],"Ambiguous native source path "..row.path)
        result[row.path]=row
    end
    return result
end
function Guard.Compare(beforeRows,afterRows,expectedSources)
    local before,after=index(beforeRows),index(afterRows)
    local report={pass=true,existing=0,exact=0,changed=0,added=0,failures={},ownedRecoveryExemption=owned,
        boundary="Exact fresh native Lua source hashes outside this pass's owned recovery; only the two existing builder changes and two new detail modules are allowed."}
    local expected={}
    for path,sha in expectedSources do
        local name=path:sub(#prefix+1)
        assert(path:sub(1,#prefix)==prefix and allowedNames[name],"Only exact authorized builder source paths may change")
        expected[path]=sha
    end
    for _,name in {"WorldPlan","WorldAssembly","DetailPlan","DetailGeometry"} do assert(expected[prefix..name],"Bind all four authorized source hashes") end
    local function fail(path,reason) report.pass=false;table.insert(report.failures,{path=path,reason=reason}) end
    for path,old in before do
        report.existing+=1
        local actual=after[path]
        if not actual then fail(path,"Existing source removed")
        elseif expected[path] then
            if actual.sha256~=expected[path] then fail(path,"Changed source differs from final packet") else report.changed+=1 end
        elseif actual.sha256~=old.sha256 or actual.class~=old.class then fail(path,"Protected source changed")
        else report.exact+=1 end
    end
    for path,actual in after do
        if before[path] then continue end
        if expected[path] and (path==prefix.."DetailPlan" or path==prefix.."DetailGeometry") and actual.sha256==expected[path] then report.added+=1
        else fail(path,"Unexpected new source outside owned recovery") end
    end
    if report.changed~=2 or report.added~=2 then fail("counts","Exactly two changed and two new builder modules required") end
    return report
end
function Guard.CompareOtherMaps(beforeRows,afterRows)
    local before,after={},{}
    for _,row in beforeRows do assert(not before[row.path]);before[row.path]=row end
    for _,row in afterRows do assert(not after[row.path]);after[row.path]=row end
    local result={pass=true,checked=0,failures={}}
    for path,row in before do
        result.checked+=1
        if not after[path] or after[path].sha256~=row.sha256 then result.pass=false;table.insert(result.failures,path) end
    end
    for path in after do if not before[path] then result.pass=false;table.insert(result.failures,"Unexpected other map "..path) end end
    return result
end
return Guard
