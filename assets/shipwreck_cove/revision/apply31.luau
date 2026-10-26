assert(game.PlaceId==85558151074819 and game.CreatorId==86069177)
assert(not game:GetService('RunService'):IsRunning())
local ss=game.ServerStorage
local current=workspace.Course_ShipwreckCove
assert(current:GetAttribute('ReviewBuild')=='SC30_CANDIDATE_04')
local owner=current:Clone();owner.Name='__SC31OwnerOriginal';owner.Parent=ss
local source=ss.CourseBuilders.ShipwreckCove:Clone();source.Name='__SC31Sources01';source.Parent=ss
current.Parent=ss
local ok,fresh=pcall(function()return require(source.Installer).Install()end)
current.Parent=workspace
if not ok then error(fresh) end
fresh.Name='__SC31Generated';fresh.Parent=ss
fresh=require(source.Authoring).ToEditable(fresh)
local candidate=current:Clone();candidate.Name='__SC31Candidate'
for _,p in candidate.EditablePlatforms:GetChildren() do
    if p.Name:match('^Spar%d+$') then p:Destroy() end
end
for _,p in fresh.EditablePlatforms:GetChildren() do
    if p.Name:match('^Spar%d+$') then p:Clone().Parent=candidate.EditablePlatforms end
end
local oldSection=candidate.Decoration.X02
for _,p in oldSection:GetChildren() do if p.Name:match('^SparSupport') then p:Destroy() end end
for _,p in fresh.Decoration.X02:GetChildren() do if p.Name:match('^SparSupport') then p:Clone().Parent=oldSection end end
for _,p in candidate.Decoration.Falling:GetChildren() do
    if p.Name:match('^FallingCoconut') then
        local updated=fresh.Decoration.Falling:FindFirstChild(p.Name)
        if updated then p.CFrame=updated.CFrame end
    end
end
local solid=require(source.SolidGround).Apply(candidate)
for _,p in candidate.Decoration.WreckSupports28:GetChildren() do p:Destroy() end
for _,n in {'MastYard_083','MastYard_085'} do candidate.Decoration.S02[n].CFrame+=Vector3.new(0,3,-17) end
for _,n in {'TornSail_084','TornSail_086'} do
    local p=candidate.Decoration.S02[n];p.Size=Vector3.new(p.Size.X,p.Size.Y*.6,p.Size.Z);p.CFrame+=Vector3.new(0,7.5,-17)
end
for _,p in candidate:GetDescendants() do
    if p:IsA('MeshPart') then
        if p.Name:match('^DistantPeak') then p.TextureID='';p.Color=Color3.fromRGB(151,185,193);p.CastShadow=false end
        if p.Name:match('^Horizon28') then p.CastShadow=false end
        local colors={CaveMouth26={220,213,198},CaveVault26={185,201,196},CaveSurge26={162,181,191},R_HullBow_179={172,169,164},R_HullMid_180={172,169,164},R_HullStern_181={172,169,164}}
        if colors[p.Name] then
            p.Color=Color3.fromRGB(unpack(colors[p.Name]))
            local appearance=Instance.new("SurfaceAppearance")
            appearance.Name="PaletteTint";appearance.ColorMap=p.TextureID
            appearance.Color=p.Color;appearance.Parent=p
        end
    end
end
for name,asset in {R_HullBow_179='SC_HullClear31Bow',R_HullMid_180='SC_HullClear31Mid',R_HullStern_181='SC_HullClear31Stern'} do
    local p=candidate.Decoration.S02[name]
    local cf,size,texture=p.CFrame,p.Size,p.TextureID
    p:ApplyMesh(ss.__ShipwreckCove_Kit31[asset])
    p.CFrame=cf;p.Size=size;p.TextureID=texture;p.CanCollide=false
    p:SetAttribute('Asset',asset)
    p:SetAttribute('Triangles',require(source.Kit)[asset].triangles)
end
candidate:SetAttribute('ShipwreckBuild','SC_MAP_31')
candidate:SetAttribute('ReviewBuild','SC31_CANDIDATE_11')
candidate:SetAttribute('PlacedVisualTriangles',165116)
current.Name='__SC31BeforeApply';current.Parent=ss
candidate.Name='Course_ShipwreckCove';candidate.Parent=workspace
return {build=candidate:GetAttribute('ReviewBuild'),solid=solid,platforms=#candidate.EditablePlatforms:GetChildren()}
