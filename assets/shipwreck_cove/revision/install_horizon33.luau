assert(game.PlaceId==85558151074819 and game.CreatorId==86069177)
assert(not game:GetService('RunService'):IsRunning())
local archive=game.ServerStorage.Archive.ShipwreckCove
local map=workspace.Course_ShipwreckCove
assert(map:GetAttribute('ReviewBuild')=='SC33_CANDIDATE_02')
local raw=archive.ImportHistory.Horizon33_CorrectedImport:FindFirstChild('SC_R_Horizon28',true)
assert(raw and raw:IsA('MeshPart') and raw.MeshId=='rbxassetid://98382757877530')
local backup=map:Clone();backup.Name='Before_SC33_MountainMesh';backup.Parent=archive.Milestones
local template=game.ServerStorage.AssetLibraries.ShipwreckCove.Kit28.SC_R_Horizon28
local previous=template:Clone();previous.Name='Horizon28_BeforeNormalRepair';previous.Parent=archive.ImportHistory
local function apply(target)
    local size,cf,texture,color,material=target.Size,target.CFrame,target.TextureID,target.Color,target.Material
    target:ApplyMesh(raw)
    target.Size=size;target.CFrame=cf;target.TextureID=texture;target.Color=color;target.Material=material
    target.DoubleSided=false;target.CanCollide=false;target.CanTouch=false;target.CanQuery=false
    target:SetAttribute('NormalRepair','SC33');target:SetAttribute('SourceModelId',124749649922892)
    assert(target.Size==size and target.CFrame==cf,'Mesh repair changed placement')
end
apply(template)
local changed={}
for _,p in map:GetDescendants() do
    if p:IsA('MeshPart') and p:GetAttribute('Asset')=='SC_R_Horizon28' then
        local old=p.MeshId;apply(p)
        table.insert(changed,{name=p.Name,before=old,after=p.MeshId,size=tostring(p.Size)})
    end
end
assert(#changed==38,'Unexpected mountain count')
local loaded={}
game:GetService('ContentProvider'):PreloadAsync({template},function(asset,status)
    table.insert(loaded,{asset=asset,status=status.Name})
end)
map:SetAttribute('ReviewBuild','SC33_CANDIDATE_03')
return {build=map:GetAttribute('ReviewBuild'),changed=changed,loaded=loaded,camera=tostring(workspace.CurrentCamera.CameraType)}
