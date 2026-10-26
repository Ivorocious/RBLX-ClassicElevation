-- Prepared only; requires explicit approval in this Creator chat.
assert(game.PlaceId==85558151074819,"Wrong experience")
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local fingerprint=(function()
__CONTENT_FINGERPRINT__
end)()
local old=assert(workspace:FindFirstChild("SGV2_Phase3_F04"),"Current course missing")
local before=fingerprint(old)
assert(before.geometry.hash=="1ca5e82d" and before.contentHash=="924cb616","Current course changed; preserve owner edits and inspect")
assert(old:GetAttribute("CandidateId")=="SGV2_Closing_C01_Sample","Unexpected installed candidate")
assert(old:GetPivot().Position==Vector3.new(1563,257,-1053),"Current placement changed")

local http=game:GetService("HttpService")
local serializer=game:GetService("SerializationService")
local priorHttp=http.HttpEnabled
local candidate
local restored
local committed=false
local ok,result=xpcall(function()
    http.HttpEnabled=true
    local bytes=http:GetAsync("http://127.0.0.1:8768/sgv2-closing-c05.rbxm",true)
    assert(#bytes==1700986,"Candidate file differs")
    local roots=serializer:DeserializeInstancesAsync(buffer.fromstring(bytes))
    assert(#roots==1 and roots[1]:IsA("Model"),"Expected exactly one course model")
    candidate=roots[1]
    assert(candidate.Name==old.Name and candidate:GetAttribute("CandidateId")=="SGV2_Closing_C05","Wrong candidate identity")
    assert(candidate:GetPivot().Position==old:GetPivot().Position,"Candidate would change owner placement")
    assert(candidate:GetAttribute("CourseOrigin")==old:GetPivot().Position,"Candidate origin differs")
    assert(candidate.CourseInfo:GetAttribute("Enabled")==false,"Course must remain disabled outside Studio development selection")
    local check=fingerprint(candidate)
    assert(check.geometry.hash=="1bdc7368" and check.parts==7200 and check.scripts==0,"Candidate geometry or scripts differ")
    local hazards=0
    for _,part in candidate:GetDescendants() do
        if part:IsA("BasePart") then
            assert(part.Anchored,"Unexpected moving course geometry")
            if part:GetAttribute("HazardType")=="Kill" then hazards+=1 end
        end
    end
    assert(hazards==10,"Hazard inventory differs")

    local backup=buffer.tostring(serializer:SerializeInstancesAsync({old}))
    local url="http://127.0.0.1:8768/sgv2-c01-before-c05-apply.rbxm"
    local response=http:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=backup})
    assert(response.Success,"Fresh backup save failed")
    local backupReceipt=http:JSONDecode(response.Body)
    local saved=http:GetAsync(url,true)
    assert(saved==backup,"Fresh backup readback differs")
    restored=serializer:DeserializeInstancesAsync(buffer.fromstring(saved))
    assert(#restored==1,"Unexpected recovery roots")
    local recovery=fingerprint(restored[1])
    assert(recovery.geometry.hash==before.geometry.hash and recovery.contentHash==before.contentHash,"Recovery verification failed")
    for _,root in restored do root:Destroy() end
    restored=nil

    local unchanged=fingerprint(old)
    assert(unchanged.geometry.hash==before.geometry.hash and unchanged.contentHash==before.contentHash,"Current course changed during preparation")
    old.Parent=nil
    candidate.Parent=workspace
    local installed=fingerprint(candidate)
    assert(installed.geometry.hash=="1bdc7368" and installed.parts==7200 and installed.scripts==0,"Installed readback differs")
    old:Destroy()
    committed=true
    return {candidate="SGV2_Closing_C05",installed=installed,recovery=backupReceipt,runtimeApplied=false,published=false}
end,debug.traceback)

if not committed then
    if candidate then candidate:Destroy() end
    if old.Parent==nil then old.Parent=workspace end
end
if restored then for _,root in restored do root:Destroy() end end
http.HttpEnabled=priorHttp
assert(ok,result)
return result
