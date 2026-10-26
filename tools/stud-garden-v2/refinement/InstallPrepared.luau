assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning(),"Requires intended Edit place")
local fingerprint=(function()
__CONTENT_FINGERPRINT__
end)()
local old=assert(workspace:FindFirstChild("SGV2_Phase3_F04"))
local before=fingerprint(old)
assert(before.geometry.hash=="4b2f6d3d" and before.contentHash=="5266719a","Owner course changed; preserve and inspect")
local http=game:GetService("HttpService")
local serializer=game:GetService("SerializationService")
local priorHttp=http.HttpEnabled
local candidate
local committed=false
local ok,result=xpcall(function()
    http.HttpEnabled=true
    local bytes=http:GetAsync("http://127.0.0.1:8768/sgv2-refinement-r01.rbxm",true)
    assert(#bytes==1022312,"Prepared candidate differs")
    local roots=serializer:DeserializeInstancesAsync(buffer.fromstring(bytes))
    assert(#roots==1 and roots[1]:IsA("Model"))
    candidate=roots[1]
    assert(candidate.Name==old.Name and candidate:GetAttribute("CandidateId")=="SGV2_Refinement_R01")
    assert(candidate:GetPivot()==old:GetPivot() and candidate:GetPivot().Position==Vector3.new(1563,257,-1053))
    assert(candidate.CourseInfo:GetAttribute("Enabled")==false and not candidate:GetAttribute("DraftWithoutAsset"))
    local checked=fingerprint(candidate)
    assert(checked.geometry.hash=="3b36ec9d" and checked.contentHash=="21951232" and checked.scripts==0)
    local sources={} local retained=0 local neon=0
    for _,part in old:GetDescendants() do
        if part:IsA("MeshPart") then sources[part:GetFullName():sub(#old:GetFullName()+2)]=part end
    end
    for _,part in candidate:GetDescendants() do
        if part:IsA("BasePart") then assert(part.Anchored and not part:GetAttribute("DraftWithoutAsset")) end
        if part:IsA("MeshPart") then
            local source=sources[part:GetFullName():sub(#candidate:GetFullName()+2)]
            if source then retained+=1;assert(part.MeshContent==source.MeshContent and part.MeshId==source.MeshId,"Retained mesh source changed") end
        end
        if part:GetAttribute("HazardType")=="Kill" then assert(part.Material==Enum.Material.Neon and part.CanTouch);neon+=1 end
    end
    assert(retained==230 and neon==10)
    local backup=buffer.tostring(serializer:SerializeInstancesAsync({old}))
    local url="http://127.0.0.1:8768/sgv2-owner-before-r01-apply.rbxm"
    local response=http:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=backup})
    assert(response.Success,response.Body)
    assert(http:GetAsync(url,true)==backup,"Backup readback failed")
    local restored=serializer:DeserializeInstancesAsync(buffer.fromstring(backup))
    local recovery=fingerprint(restored[1]);restored[1]:Destroy()
    assert(recovery.geometry.hash==before.geometry.hash and recovery.contentHash==before.contentHash,"Recovery differs")
    local unchanged=fingerprint(old)
    assert(unchanged.geometry.hash==before.geometry.hash and unchanged.contentHash==before.contentHash,"Owner course changed during preparation")
    old.Parent=nil
    candidate.Parent=workspace
    local installed=fingerprint(candidate)
    assert(installed.geometry.hash==checked.geometry.hash and installed.contentHash==checked.contentHash)
    old:Destroy()
    committed=true
    return {before=before,installed=installed,recovery=http:JSONDecode(response.Body),retainedMeshes=retained,neonBars=neon,published=false}
end,debug.traceback)
if not committed then
    if candidate then candidate:Destroy() end
    if old.Parent==nil then old.Parent=workspace end
end
http.HttpEnabled=priorHttp
assert(ok,result)
return result
