local rs=game:GetService('RunService')
local h=game:GetService('HttpService')
local template=game.ServerStorage.CourseLibrary.Course_ShipwreckCove
local map=template:Clone();map.Name='__SC31CoconutFixture';map:PivotTo(map:GetPivot()+Vector3.new(0,0,600));map.Parent=workspace
local layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.FallingHazards).Create(map,layout.falling)
local geometry=require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local harbor=map.Obstacles.WalkingSurfaces.HarborAssembly
local unsafe,states,drops,seen=0,{},0,{}
local started=os.clock()
for step=0,6000 do
    local t=step*.05
    controller.Step(t,.05,true,true,{},function()error('No test racers')end)
    for _,p in map.Decoration.Falling:GetChildren() do
        if p:IsA('MeshPart') and p.Name:match('^FallingCoconut') then
            local state=p:GetAttribute('State')
            if state=='Falling' and states[p]~='Falling' then drops+=1;seen[p.Name]=true end
            states[p]=state
            if p.Transparency<1 and (state=='Falling' or state=='Hold') then
                if geometry.BoxesIntersect(p.CFrame,p.Size,harbor.CFrame,harbor.Size+Vector3.new(4,200,4)) then unsafe+=1 end
            end
        end
    end
    if step%200==0 then rs.Heartbeat:Wait() end
end
controller.Stop()
script:SetAttribute('Result',h:JSONEncode({build=template:GetAttribute('ReviewBuild'),simulatedSeconds=300,step=.05,drops=drops,emitters=seen,unsafeStartSamples=unsafe,wallSeconds=os.clock()-started,method='Production falling controller in Studio, controlled clock, visible full coconut bounds checked against the start deck with two-stud margin. No human race.'}))
map:Destroy()
