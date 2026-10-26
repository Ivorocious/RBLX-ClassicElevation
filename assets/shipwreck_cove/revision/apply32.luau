assert(game.PlaceId==85558151074819 and game.CreatorId==86069177)
assert(not game:GetService('RunService'):IsRunning())
local ss=game.ServerStorage
local current=workspace.Course_ShipwreckCove
local baseline=ss.__SC32Before
assert(baseline:GetAttribute('ReviewBuild')=='SC31_CANDIDATE_11')
local serial=(ss:GetAttribute('SC32ApplySerial') or 0)+1
ss:SetAttribute('SC32ApplySerial',serial)
local source=ss.CourseBuilders.ShipwreckCove:Clone();source.Name='__SC32Sources'..serial;source.Parent=ss
local data=require(source.Layout);assert(data.build=='SC_MAP_32')
current.Parent=ss
local ok,fresh=pcall(function()return require(source.Installer).Install()end)
current.Parent=workspace
assert(ok,fresh)
fresh.Name='__SC32Generated'..serial;fresh.Parent=ss
fresh=require(source.Authoring).ToEditable(fresh)
local candidate=baseline:Clone();candidate.Name='__SC32Candidate'
for _,p in candidate.EditablePlatforms:GetChildren() do if p.Name:match('^Spar%d+$') then p:Destroy() end end
for _,p in fresh.EditablePlatforms:GetChildren() do if p.Name:match('^Spar%d+$') then p:Clone().Parent=candidate.EditablePlatforms end end
candidate.Decoration.X02:Destroy()
fresh.Decoration.X02:Clone().Parent=candidate.Decoration
for _,p in fresh.Decoration.Obstacles:GetChildren() do
    if p.Name:match('^ExpertCrossbar32_') then p:Clone().Parent=candidate.Decoration.Obstacles end
end
local mountains=0
for _,p in candidate.Decoration:GetDescendants() do
    if p:IsA('MeshPart') and p.Name:match('^Horizon28_') then
        local updated=fresh.Decoration:FindFirstChild(p.Name,true)
        assert(updated)
        p.CFrame=updated.CFrame
        mountains+=1
    end
end
candidate:SetAttribute('ShipwreckBuild','SC_MAP_32')
candidate:SetAttribute('ReviewBuild','SC32_CANDIDATE_01')
candidate:SetAttribute('PlacedVisualTriangles',data.resource.visualTriangles)
current.Name='__SC32Previous'..serial;current.Parent=ss
candidate.Name='Course_ShipwreckCove';candidate.Parent=workspace
return {build=candidate:GetAttribute('ReviewBuild'),mountains=mountains,expert=#data.testRoutes.expert_spars-2,crumble=table.find(data.crumble,'Spar00')~=nil}
