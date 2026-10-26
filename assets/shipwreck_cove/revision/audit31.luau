local course=game.ServerStorage.CourseLibrary.Course_ShipwreckCove
local counts={parts=0,meshes=0,colliders=0,scripts=0,unanchored=0,solidGround=0}
local duplicates,keys={},{}
local visible={}
for _,p in course:GetDescendants() do
    if p:IsA('LuaSourceContainer') then counts.scripts+=1 end
    if not p:IsA('BasePart') then continue end
    counts.parts+=1
    if p:IsA('MeshPart') then counts.meshes+=1 end
    if p.CanCollide then counts.colliders+=1 end
    if not p.Anchored then counts.unanchored+=1 end
    if p:GetAttribute('SolidGround') then counts.solidGround+=1 end
    if p.Transparency<.99 then
        table.insert(visible,p)
        local key=tostring(p.CFrame)..'|'..tostring(p.Size)..'|'..(if p:IsA('MeshPart') then p.MeshId else p.ClassName)
        if keys[key] then table.insert(duplicates,{keys[key]:GetFullName(),p:GetFullName()}) else keys[key]=p end
    end
end
local walking=course.Obstacles.WalkingSurfaces
local missingVisuals,legacyActive={},{}
for _,p in walking:GetChildren() do
    if p:GetAttribute('RouteReferenceOnly') and (p.CanCollide or p.CanQuery) then table.insert(legacyActive,p.Name) end
    if p:IsA('BasePart') and p.CanCollide and not course.Decoration:FindFirstChild(p.Name,true)
        and not p.Name:match('Barrier') then table.insert(missingVisuals,p.Name) end
end
local hazards={}
for _,p in course.Decoration.Obstacles:GetChildren() do
    if p:IsA('BasePart') then table.insert(hazards,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},visible=p.Transparency<1,collide=p.CanCollide}) end
end
return {build=course:GetAttribute('ReviewBuild'),counts=counts,exactVisibleDuplicates=duplicates,missingWalkingVisuals=missingVisuals,legacyStripsStillActive=legacyActive,hazards=hazards,limits='Exact-duplicate scan cannot establish absence of every clipping or Z-fighting case; visual review is separate.'}
