local current=workspace.Course_ShipwreckCove
local before=game.ServerStorage.Archive.ShipwreckCove.Before_SC33_OwnerEdits
local counts={}
local function scoped(p)
    return p.Name:match('^Rib') or p.Name:match('^WreckPile33_') or p.Name:match('^ExpertLanding_Rib')
        or p.Name:match('^Horizon28_') or p.Name:match('^LampShelf26_')
        or p:GetAttribute('Asset')=='SC_R_PalmTrunk29' or p:GetAttribute('OwnerPlaced')
end
local function inspect(root,delta)
    local r={parts=0,meshes=0,collidable=0,unanchored=0,scripts=0,compared=0}
    for _,p in root:GetDescendants() do
        if p:IsA('BaseScript') then r.scripts+=1 end
        if not p:IsA('BasePart') then continue end
        r.parts+=1;if p:IsA('MeshPart') then r.meshes+=1 end
        if p.CanCollide then r.collidable+=1 end;if not p.Anchored then r.unanchored+=1 end
        if scoped(p) then continue end
        r.compared+=1
        local cf={p.CFrame:GetComponents()};for i,v in cf do cf[i]=math.round(v*10000)/10000 end
        local signature=game.HttpService:JSONEncode({p.Name,p.ClassName,cf,tostring(p.Size),tostring(p.Color),p.CanCollide,p.CanQuery,p.CanTouch,p.CollisionGroup,p.Transparency,p.Anchored,p.Material.Name,p.CastShadow,if p:IsA('MeshPart') then p.MeshId else '',if p:IsA('MeshPart') then p.TextureID else ''})
        counts[signature]=(counts[signature] or 0)+delta
    end
    return r
end
local a,b=inspect(before,1),inspect(current,-1)
local differences={};for s,delta in counts do if delta~=0 then table.insert(differences,{signature=s,delta=delta}) end end
return {build=current:GetAttribute('ReviewBuild'),before=a,after=b,unscopedDifferences=differences,
    camera=tostring(workspace.CurrentCamera.CameraType),storageRoots=#game.ServerStorage:GetChildren(),
    limitations='Mountain yaw corrected; replacement mesh with corrected normals awaits permission to upload. Current mesh remains the original asset.'}
