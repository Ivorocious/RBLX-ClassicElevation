assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning(),"Intended Edit place required")
local fingerprint=(function()
__FINGERPRINT__
end)()
local Kit=(function()
__KIT__
end)()
local build=(function()
__SCENES__
end)()
local old=assert(workspace:FindFirstChild("SGV2_Phase3_F04"))
local before=fingerprint(old)
assert(before.geometry.hash=="3b36ec9d" and before.contentHash=="e6789f4c","Owner course changed")
assert(not game.ServerStorage:FindFirstChild("SGV2_StudStyle_S01_Staged"),"Candidate already staged")
local candidate=old:Clone()
local ok,result=xpcall(function()
    local ledger=build(candidate,Kit)
    assert(candidate:GetPivot()==old:GetPivot())
    local byPath={}
    for _,p in old:GetDescendants() do if p:IsA("MeshPart") then byPath[p:GetFullName():sub(#old:GetFullName()+2)]=p end end
    local retained=0
    for _,p in candidate:GetDescendants() do
        if p:IsA("BasePart") then assert(p.Anchored) end
        assert(not p:IsA("LuaSourceContainer"))
        if p:IsA("MeshPart") then
            local source=assert(byPath[p:GetFullName():sub(#candidate:GetFullName()+2)])
            assert(p.MeshContent==source.MeshContent and p.MeshId==source.MeshId)
            retained+=1
        end
    end
    assert(retained==377 and not candidate.CourseInfo:GetAttribute("Enabled"))
    local check=fingerprint(candidate)
    candidate.Name="SGV2_StudStyle_S01_Staged"
    candidate.Parent=game.ServerStorage
    return {candidate=check,retainedMeshSources=retained,ledger=ledger}
end,debug.traceback)
if not ok then candidate:Destroy() end
assert(ok,result)
return result
