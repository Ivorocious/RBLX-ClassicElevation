local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local map=game.ServerStorage.CourseLibrary.Course_ShipwreckCove
local rows={};local byName={}
for _,p in layout.placements do byName[p.name]=p end
local fixture=Instance.new('Folder');fixture.Name='SC33_ContactFixture';fixture.Parent=workspace
local shift=Vector3.new(1000,0,500)
local tested={}
for _,part in map:GetDescendants() do
    if part:IsA('MeshPart') and (part:GetAttribute('Asset')=='SC_R_PalmTrunk29' or part.Name:match('^LampShelf26_')) then
        local clone=part:Clone();clone.CFrame+=shift;clone.Parent=fixture
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances={clone};params.RespectCanCollide=true
        local source=byName[part.Name]
        local point=Vector3.new(unpack(source.p))+Vector3.new(unpack(layout.origin))+shift
        local hits=0
        for _,height in {2,4,6} do
            for _,axis in {Vector3.xAxis,Vector3.zAxis} do
                local hit=workspace:Raycast(point+Vector3.yAxis*height-axis*10,axis*20,params)
                if hit and hit.Instance==clone then hits+=1 end
            end
        end
        local top=workspace:Raycast(clone.Position+Vector3.yAxis*(clone.Size.Y+5),-Vector3.yAxis*(clone.Size.Y*2+10),params)
        table.insert(rows,{name=part.Name,collidable=part.CanCollide,bodyHeightHits=hits,topContact=top~=nil})
        if part.Name=='GrovePalm28_6_Trunk' or part.Name=='GrovePalm29_4_Trunk' then table.insert(tested,{mesh=clone,point=point}) end
    end
end
local player=game.Players:GetPlayers()[1];local original=player.Character
local contacts={}
for _,test in tested do
    local mesh,point=test.mesh,test.point
    local floor=Instance.new('Part');floor.Size=Vector3.new(30,1,20);floor.CFrame=CFrame.new(point+Vector3.new(0,-.5,0));floor.Anchored=true;floor.Parent=fixture
    for _,solid in {true,false} do
        mesh.CanCollide=solid
        original.Archivable=true;local char=original:Clone();char.Name='ContactR15';char.Parent=fixture
        for _,d in char:GetDescendants() do if d:IsA('BaseScript') then d.Enabled=false end end
        local h=char:FindFirstChildOfClass('Humanoid');local root=char.HumanoidRootPart
        root:SetNetworkOwner(nil);h.WalkSpeed=16
        char:PivotTo(CFrame.new(point+Vector3.new(-7,3.1,0)))
        local start=os.clock();local grounded=false
        repeat RunService.Heartbeat:Wait();grounded=h.FloorMaterial~=Enum.Material.Air until grounded or os.clock()-start>1.5
        local walk=RunService.PreSimulation:Connect(function()h:Move(Vector3.new(1,0,math.clamp((point.Z-root.Position.Z)*3,-1,1)).Unit,false)end)
        task.wait(1.05);walk:Disconnect();h:Move(Vector3.zero,false)
        table.insert(contacts,{name=mesh.Name,solid=solid,grounded=grounded,xFromCenter=root.Position.X-point.X,zFromCenter=root.Position.Z-point.Z,
            passed=grounded and (if solid then root.Position.X<point.X+1 else root.Position.X>point.X+5)})
        char:Destroy()
    end
    mesh.CanCollide=true;floor:Destroy()
end
fixture:Destroy()
script:SetAttribute('Result',game.HttpService:JSONEncode({build=map:GetAttribute('ReviewBuild'),rays=rows,humanoidContactAndNegativeControls=contacts}))
