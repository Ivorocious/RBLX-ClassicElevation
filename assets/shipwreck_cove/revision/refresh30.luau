assert(game.PlaceId==85558151074819 and game.CreatorId==86069177,'Wrong experience')
assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
local ss=game.ServerStorage
local owner=ss.__SC30OwnerOriginal
local baseline=require(ss.__SC30BaselineSources.Layout)
local source=ss.CourseBuilders.ShipwreckCove:Clone()
source.Name='__SC30CandidateSources';source.Parent=ss
local data=require(source.Layout)
assert(data.build=='SC_MAP_30')
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in a do if not equal(v,b[k]) then return false end end
    for k in b do if a[k]==nil then return false end end
    return true
end
local previous=workspace.Course_ShipwreckCove
previous.Name='__SC30Before_'..tostring(os.time());previous.Parent=ss
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
local oldBraces={}
for _,p in baseline.braces or {} do oldBraces[p.name]=p end
for _,p in data.braces or {} do
    if equal(oldBraces[p.name],p) then
        local old=owner.Decoration.WreckSupports28:FindFirstChild(p.name)
        local generated=candidate.Decoration.WreckSupports28:FindFirstChild(p.name)
        if generated then generated:Destroy() end
        if old then old:Clone().Parent=candidate.Decoration.WreckSupports28 end
    end
end
local knownSections={}
for _,p in baseline.placements do knownSections[p.section]=true end
for _,group in owner.Decoration:GetChildren() do
    if not knownSections[group.Name] and not candidate.Decoration:FindFirstChild(group.Name) then
        group:Clone().Parent=candidate.Decoration
    end
end
local changedSurfaces={}
for _,p in data.surfaces do if not equal(oldSurfaces[p.name],p) then changedSurfaces[p.name]=true end end
local currentSurfaces={}
for _,p in data.surfaces do currentSurfaces[p.name]=true end
for name in oldSurfaces do if not currentSurfaces[name] then changedSurfaces[name]=true end end
local function changedMarker(name)
    for surface in changedSurfaces do
        if name=='RouteArrow_'..surface or name=='ExpertLanding_'..surface or name=='CliffLanding_'..surface then return true end
    end
    return false
end
local generatedMarkers=candidate.RouteMarkers
generatedMarkers.Parent=nil
local keptMarkers=owner.RouteMarkers:Clone();keptMarkers.Parent=candidate
for _,marker in keptMarkers:GetChildren() do
    if changedMarker(marker.Name) then marker:Destroy() end
end
for _,marker in generatedMarkers:GetChildren() do
    if changedMarker(marker.Name) then
        marker.Parent=keptMarkers
    end
end
generatedMarkers:Destroy()
for _,name in {'Checkpoints','Bounds','FallZones','CourseInfo','Start','Finish','StartPen'} do
    local old=owner:FindFirstChild(name)
    if old then local fresh=candidate:FindFirstChild(name);if fresh then fresh:Destroy() end;old:Clone().Parent=candidate end
end
candidate:SetAttribute('ReviewBuild','SC30_CANDIDATE_04')
candidate:SetAttribute('PreservedOwnerVisuals',preserved)
candidate:SetAttribute('PreservedOwnerRemovals',removed)
candidate=require(source.Authoring).ToEditable(candidate)
return {build=candidate:GetAttribute('ReviewBuild'),preserved=preserved,ownerRemovals=removed,class=candidate.ClassName,platforms=#candidate.EditablePlatforms:GetChildren()}
