assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player=assert(game.Players:GetPlayers()[1])
local character=assert(player.Character)
local root=character.HumanoidRootPart
local original=character:GetPivot()
local fixture=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:Clone()
fixture.Name="__SCWaterStallFixture"
fixture:PivotTo(fixture:GetPivot()+Vector3.new(1000,0,0))
fixture.Parent=workspace
local origin=fixture.Bounds.CourseOrigin.CFrame
local water=fixture.Decoration.H02.SurgeWater
local initialSize,initialFrame=water.Size,water.CFrame
local hits={}
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
    function(_,source)table.insert(hits,source)end,function(p)return p==player end)
local records={}
local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
end
for _,x in {-108,-97} do
    check("Stalled cannon frame is harmless at x="..x,function()
        character:PivotTo(origin*CFrame.new(x,16.1,-7))
        root.AssemblyLinearVelocity=Vector3.zero
        task.wait(.15)
        controller.Reset();hits={}
        controller.Step(1.5,0,false)
        controller.Step(3,1.5,true)
        assert(#hits==0,"Stale interval caused a hit")
    end)
end
check("Tide volume stays attached to the water bed in every phase",function()
    for _,t in {2,6,8,9,10.8,11.9} do
        controller.Reset();controller.Step(t,0,false)
        assert(math.abs(water.Position.Y-water.Size.Y/2-(origin.Position.Y-4))<.001,"Floating water bed")
    end
end)
controller.Stop()
check("Stopping restores the authored water geometry",function()
    assert(water.Size==initialSize and water.CFrame==initialFrame,"Water geometry did not restore")
end)
fixture:Destroy()
character:PivotTo(original)
root.AssemblyLinearVelocity=Vector3.zero
script:SetAttribute("Result",game.HttpService:JSONEncode({build="SC_MAP_16",records=records,
    method="Controlled production runtime states on the installed16 fixture; explicit stale-frame guard and water-volume correction. Not a full race or device benchmark."}))
