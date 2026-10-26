assert(game.PlaceId==85558151074819 and game.CreatorId==86069177,'Wrong experience')
assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
local ss=game.ServerStorage
local owner=ss.__SC29OwnerOriginal
local baseline=require(ss.__SC29BaselineSources.Layout)
local source=ss.CourseBuilders.ShipwreckCove:Clone()
source.Name='__SC29CandidateSources';source.Parent=ss
local data=require(source.Layout)
assert(data.build=='SC_MAP_29')
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in a do if not equal(v,b[k]) then return false end end
    for k in b do if a[k]==nil then return false end end
    return true
end
local previous=workspace.Course_ShipwreckCove
previous.Name='__SC29Before_'..tostring(os.time());previous.Parent=ss
local ok,result=pcall(function() return require(source.Installer).Install() end)
if not ok then previous.Name='Course_ShipwreckCove';previous.Parent=workspace;error(result) end
local candidate=result
local oldDefs={}
for _,p in baseline.placements do oldDefs[p.section..'/'..p.name]=p end
local preserved,removed=0,0
for _,p in data.placements do
    local key=p.section..'/'..p.name
    if not equal(oldDefs[key],p) or p.name=='SurgeWave' or p.name=='SurgeWater' then continue end
    local oldGroup=owner.Decoration:FindFirstChild(p.section)
    local old=oldGroup and oldGroup:FindFirstChild(p.name)
    local group=candidate.Decoration:FindFirstChild(p.section)
    local generated=group and group:FindFirstChild(p.name)
    if generated then generated:Destroy() end
    if old then old:Clone().Parent=group;preserved+=1 else removed+=1 end
end
local oldSurfaces={}
for _,p in baseline.surfaces do oldSurfaces[p.name]=p end
for _,p in data.surfaces do
    if equal(oldSurfaces[p.name],p) then
        local old=owner.Obstacles.WalkingSurfaces:FindFirstChild(p.name)
        local generated=candidate.Obstacles.WalkingSurfaces:FindFirstChild(p.name)
        if generated then generated:Destroy() end
        if old then old:Clone().Parent=candidate.Obstacles.WalkingSurfaces end
    end
end
local known={}
for _,p in baseline.placements do known[p.section..'/'..p.name]=true end
for _,group in owner.Decoration:GetChildren() do
    if group.Name=='Falling' or group.Name=='Obstacles' then continue end
    for _,child in group:GetChildren() do
        if child:IsA('BasePart') and not known[group.Name..'/'..child.Name] then
            local destination=candidate.Decoration:FindFirstChild(group.Name)
            if destination and not destination:FindFirstChild(child.Name) then child:Clone().Parent=destination;preserved+=1 end
        end
    end
end
candidate:SetAttribute('ReviewBuild','SC29_CANDIDATE_01')
candidate:SetAttribute('PreservedOwnerVisuals',preserved)
candidate:SetAttribute('PreservedOwnerRemovals',removed)
candidate=require(source.Authoring).ToEditable(candidate)
return {build=candidate:GetAttribute('ReviewBuild'),preserved=preserved,ownerRemovals=removed,class=candidate.ClassName,platforms=#candidate.EditablePlatforms:GetChildren()}
