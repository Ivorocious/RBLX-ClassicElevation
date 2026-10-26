assert(game.PlaceId==85558151074819 and game.CreatorId==86069177,"Wrong experience")
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local ss=game.ServerStorage
local owner=workspace.Course_ShipwreckCove
assert(owner:GetAttribute("ShipwreckBuild")=="SC_MAP_27","Expected owner baseline")
assert(ss:FindFirstChild("__ShipwreckOwnerBefore28"),"Owner recovery copy required")
local baseline=require(ss.__SC28BaselineSources.Layout)
local source=ss.CourseBuilders.ShipwreckCove:Clone();source.Name="__SC28CandidateSources";source.Parent=ss
local data=require(source.Layout)
assert(data.build=="SC_MAP_28")
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in a do if not equal(v,b[k]) then return false end end
    for k in b do if a[k]==nil then return false end end
    return true
end
owner.Name="__SC28OwnerArchived";owner.Parent=ss
local ok,result=pcall(function()return require(source.Installer).Install()end)
if not ok then owner.Name="Course_ShipwreckCove";owner.Parent=workspace;error(result) end
local candidate=result
local oldDefs={}
for _,p in baseline.placements do oldDefs[p.section.."/"..p.name]=p end
local preserved,removed=0,0
for _,p in data.placements do
    local key=p.section.."/"..p.name
    if not equal(oldDefs[key],p) then continue end
    local oldGroup=owner.Decoration:FindFirstChild(p.section)
    local old=oldGroup and oldGroup:FindFirstChild(p.name)
    local newGroup=candidate.Decoration:FindFirstChild(p.section)
    local generated=newGroup and newGroup:FindFirstChild(p.name)
    if generated then generated:Destroy() end
    if old then local copy=old:Clone();copy.Parent=newGroup;preserved+=1 else removed+=1 end
end
local oldSurfaces={}
for _,p in baseline.surfaces do oldSurfaces[p.name]=p end
for _,p in data.surfaces do
    if equal(oldSurfaces[p.name],p) then
        local old=owner.Obstacles.WalkingSurfaces:FindFirstChild(p.name)
        local generated=candidate.Obstacles.WalkingSurfaces:FindFirstChild(p.name)
        if old and generated then generated:Destroy();old:Clone().Parent=candidate.Obstacles.WalkingSurfaces end
    end
end
-- Carry unrelated owner additions without restoring obsolete hazards or wayfinding.
local generatedNames={}
for _,p in baseline.placements do generatedNames[p.name]=true end
for _,p in baseline.hazards do generatedNames[p.name]=true end
for _,p in baseline.falling do generatedNames[p.name]=true end
for _,group in owner.Decoration:GetChildren() do
    if group.Name=="H02" or group.Name=="Falling" or group.Name=="Obstacles" then continue end
    for _,child in group:GetChildren() do
        if child:IsA("BasePart") and not generatedNames[child.Name] then
            local destination=candidate.Decoration:FindFirstChild(group.Name)
            if destination then child:Clone().Parent=destination;preserved+=1 end
        end
    end
end
candidate:SetAttribute("ReviewBuild","SC28_CANDIDATE_01")
candidate:SetAttribute("PreservedOwnerVisuals",preserved)
candidate:SetAttribute("PreservedOwnerRemovals",removed)
return {build="SC28_CANDIDATE_01",preserved=preserved,ownerRemovals=removed,archive=owner:GetFullName()}
