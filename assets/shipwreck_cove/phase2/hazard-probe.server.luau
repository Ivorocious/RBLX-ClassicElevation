local RunService=game:GetService('RunService')
local player=game.Players:GetPlayers()[1]
local character=player.Character
local root=character.HumanoidRootPart
local humanoid=character.Humanoid
local original=character:GetPivot()
local fixture=workspace.RaceCourse:Clone()
fixture.Name='__ShipwreckHazardFixture'
fixture:PivotTo(fixture:GetPivot()+Vector3.new(1000,0,0))
fixture.Parent=workspace
local origin=fixture.Bounds.CourseOrigin.CFrame
local hits={}
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,function(_,source)table.insert(hits,source)end,function(p)return p==player end)
local records={}
local function place(p)
    root:SetNetworkOwner(nil)
    character:PivotTo(origin*CFrame.new(p+Vector3.new(0,3.1,0)))
    root.AssemblyLinearVelocity=Vector3.zero
    humanoid:Move(Vector3.zero,false)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    character:SetAttribute('RecoveryUntil',0)
    task.wait(.35)
end
local function simulate(t,duration,jumpAt)
    controller.Reset();controller.Step(t,0,false);hits={}
    local finish=t+duration
    while t<finish do
        local dt=RunService.Heartbeat:Wait()
        t+=dt
        if jumpAt and t>=jumpAt then humanoid.Jump=true;humanoid:Move(-Vector3.zAxis,false);jumpAt=nil end
        controller.Step(t,dt,true)
    end
    humanoid:Move(Vector3.zero,false)
end
local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute('Progress',#records)
end
check('Standing in first shot lane is hit',function()
    place(Vector3.new(-100,10,-6));simulate(1.5,1)
    assert(table.find(hits,'H01 Cannon'))
end)
check('Normal jump clears low cannonball',function()
    place(Vector3.new(-100,10,-2.8));simulate(1.5,1,2)
    assert(not table.find(hits,'H01 Cannon'),'jump hit')
end)
check('Dry middle waiting pocket survives both volleys',function()
    place(Vector3.new(-100,10,-18));simulate(0,4)
    assert(#hits==0)
end)
check('Low passage remains dry during dry window',function()
    place(Vector3.new(69,5,58));simulate(1,1)
    assert(#hits==0)
end)
check('Low passage is hit during surge',function()
    place(Vector3.new(69,5,58));simulate(8,1)
    assert(table.find(hits,'H02 Tide surge'))
end)
for _,x in {81.5,56.5} do
    check('Raised refuge edge safe through surge and drainage '..x,function()
        place(Vector3.new(x,8,58));simulate(7.5,4.5)
        assert(#hits==0)
    end)
end
controller.Stop();fixture:Destroy()
character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero
script:SetAttribute('Result',game.HttpService:JSONEncode({build=workspace.RaceCourse:GetAttribute('ShipwreckBuild'),records=records,method='Production hazard controller on translated map fixture, actual R15 and physics; controlled clock and teleport setup. Not a full race.'}))
