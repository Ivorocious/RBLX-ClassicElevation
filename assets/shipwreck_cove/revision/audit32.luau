local current=workspace.Course_ShipwreckCove
local baseline=game.ServerStorage.__SC32Before
assert(current:GetAttribute('ReviewBuild')=='SC32_CANDIDATE_01')
assert(baseline:GetAttribute('ReviewBuild')=='SC31_CANDIDATE_11')
local function path(instance,root)
    local names={}
    while instance~=root do table.insert(names,1,instance.Name);instance=instance.Parent end
    return table.concat(names,'.')
end
local function scoped(key)
    return key:match('^EditablePlatforms.Spar') or key:match('^Decoration.X02') or key:find('ExpertCrossbar32_') or key:find('Horizon28_')
end
local function signature(part,key)
    local transform={part.CFrame:GetComponents()}
    for index,value in transform do transform[index]=math.round(value*10000)/10000 end
    return game.HttpService:JSONEncode({key,part.ClassName,transform,tostring(part.Size),tostring(part.Color),part.CanCollide,part.CanQuery,part.CanTouch,part.CollisionGroup,part.Transparency,part.Anchored,part.Material.Name,part.CastShadow,if part:IsA('MeshPart') then part.MeshId else '',if part:IsA('MeshPart') then part.TextureID else ''})
end
local counts={}
local function inspect(root,delta)
    local census={parts=0,meshes=0,collidable=0,scripts=0,unanchored=0,scopedParts=0,comparedParts=0}
    for _,instance in root:GetDescendants() do
        if instance:IsA('BaseScript')then census.scripts+=1 end
        if instance:IsA('BasePart')then
            census.parts+=1
            if instance:IsA('MeshPart')then census.meshes+=1 end
            if instance.CanCollide then census.collidable+=1 end
            if not instance.Anchored then census.unanchored+=1 end
            local key=path(instance,root)
            if scoped(key)then census.scopedParts+=1 else
                census.comparedParts+=1
                local value=signature(instance,key)
                counts[value]=(counts[value]or 0)+delta
            end
        end
    end
    return census
end
local before=inspect(baseline,1)
local after=inspect(current,-1)
local differences={}
for value,delta in counts do if delta~=0 then table.insert(differences,{signature=value,delta=delta})end end
return game.HttpService:JSONEncode({build=current:GetAttribute('ReviewBuild'),baseline=baseline:GetAttribute('ReviewBuild'),before=before,after=after,unexpected=differences,method='Duplicate-safe part signature multisets outside named Spar/X02/crossbar/Horizon28 scope. Transform precision 0.0001; size, color, collision/query/touch/group, transparency, anchoring, material, shadow, mesh and texture IDs compared.',placedVisualTriangles=current:GetAttribute('PlacedVisualTriangles')})
