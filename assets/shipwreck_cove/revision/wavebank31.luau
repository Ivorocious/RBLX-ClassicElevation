assert(game:GetService('RunService'):IsStudio())
local map=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:Clone()
map.Name='__SC31WaveBankFixture';map:PivotTo(map:GetPivot()+Vector3.new(0,0,700));map.Parent=workspace
local origin=map.Bounds.CourseOrigin.CFrame
local Geometry=require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.WaveHazards).Create(map,layout.surges)
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={map};rp.RespectCanCollide=true
local probes={}
for x=15,31,4 do for z=51,65,3.5 do
    local hit=workspace:Raycast(origin:PointToWorldSpace(Vector3.new(x,40,z)),Vector3.new(0,-50,0),rp)
    if hit then table.insert(probes,{x=x,z=z,top=hit.Position.Y-origin.Position.Y,cf=CFrame.new(hit.Position+Vector3.new(0,2.75,0)),hits=0}) end
end end
local refuges={}
for _,name in {'SurgeEastRefuge','SurgeMiddleRefuge','SurgeWestRefuge'} do
    local p=map.Obstacles.WalkingSurfaces[name]
    table.insert(refuges,{name=name,cf=p.CFrame*CFrame.new(0,p.Size.Y/2+2.75,0),hits=0})
end
local hiddenBeforeArrival=true
for step=0,400 do
    local t=step*.05
    controller.Step(t,.05,true,true,function(cf,size,reason,previous)
        for _,list in {probes,refuges} do for _,p in list do
            if Geometry.SweptBoxesIntersect(previous or cf,cf,size,p.cf,Vector3.new(2,5.5,2)) then p.hits+=1 end
        end end
    end)
    for _,d in layout.surges do
        local phase=map.Obstacles.ShipwreckHazards[d.name..'Bounds']:GetAttribute('Phase')
        if phase=='Dry' or phase=='Warning' then hiddenBeforeArrival=hiddenBeforeArrival and map.Decoration[d.name].SurgeWave.Transparency==1 end
    end
end
for _,list in {probes,refuges} do for _,p in list do p.cf=nil end end
controller.Stop();map:Destroy()
return {build='SC31_CANDIDATE_06',method='Production wave controller in Studio, 20 seconds controlled clock. Stationary avatar-sized boxes on raycast ground; no human crossing.',bankProbes=probes,refugeCenters=refuges,hiddenBeforeArrival=hiddenBeforeArrival}
