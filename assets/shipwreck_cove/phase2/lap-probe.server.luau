local services=game.ServerScriptService.Services
local checkpoint=require(services.CheckpointService)
local results=require(services.ResultsService)
local respawn=require(services.RespawnService)
local player=game.Players:GetPlayers()[1]
local map=workspace.RaceCourse
local records={}
local visits={}
local function result()
    local race=results.GetCurrentRaceResult()
    for _,list in {race.activeRacers,race.placements} do
        for _,r in list or {} do if r.userId==player.UserId then return r end end
    end
    error('No racer result')
end
local function check(name,fn)
    local ok,err=pcall(fn);table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute('Progress',#records)
end
local function place(cf)
    local c=player.Character;local root=c.HumanoidRootPart
    root:SetNetworkOwner(nil);root.AssemblyLinearVelocity=Vector3.zero;c:PivotTo(cf)
end
local function visit(index)
    local c=player.Character
    c.Humanoid:Move(Vector3.zero,false)
    c.Humanoid.Jump=false
    place(map.Checkpoints[string.format('Checkpoint_%03d',index)].CFrame+Vector3.new(0,10,0))
    local deadline=os.clock()+2
    repeat task.wait(.05)until checkpoint.GetLatestCheckpointIndex(player)>=index or os.clock()>deadline
    task.wait(.3)
    table.insert(visits,{requested=index,actual=checkpoint.GetLatestCheckpointIndex(player),position=tostring(c.HumanoidRootPart.Position),state=c.Humanoid:GetState().Name,health=c.Humanoid.Health})
end
assert(require(services.RaceService).IsRaceActive())
local function gate(reverse,immune)
    local c=player.Character;local root=c.HumanoidRootPart;local h=c.Humanoid
    if immune then c:SetAttribute('RecoveryUntil',workspace:GetServerTimeNow()+2)end
    local localZ=if reverse then -1.1 else 8
    place(map.Finish.CFrame*CFrame.new(0,-2.9,localZ))
    task.wait(.18)
    local direction=if reverse then Vector3.zAxis else -Vector3.zAxis
    local binding=game:GetService('RunService').PreSimulation:Connect(function()h:Move(direction,false)end)
    local deadline=os.clock()+1.5
    repeat task.wait(.02)until (if reverse then map.Finish.CFrame:PointToObjectSpace(root.Position).Z>4 else map.Finish.CFrame:PointToObjectSpace(root.Position).Z<-.4) or os.clock()>deadline
    binding:Disconnect();h:Move(Vector3.zero,false);root.AssemblyLinearVelocity=Vector3.zero;task.wait(.3)
end
check('Missing checkpoints cannot complete a lap',function()
    visit(4);assert(checkpoint.GetLatestCheckpointIndex(player)==0)
    gate(false);assert(result().currentLap==1 and #result().lapTimes==0)
end)
for lap=1,3 do
    check('Ordered checkpoints lap '..lap,function()
        for i=1,4 do
            visit(i);assert(checkpoint.GetLatestCheckpointIndex(player)==i,'checkpoint '..i)
            if lap==2 and i==2 then
                local prior=player.Character;prior.Humanoid.Health=0
                local deadline=os.clock()+12
                repeat task.wait(.1)until player.Character~=prior or os.clock()>deadline
                assert(player.Character~=prior,'death respawn timeout');task.wait(1.2)
                assert(result().currentLap==2 and checkpoint.GetLatestCheckpointIndex(player)==2,'death lost progress')
                local fresh=player.Character
                fresh.HumanoidRootPart:SetNetworkOwner(nil)
                local walk=game:GetService('RunService').PreSimulation:Connect(function()fresh.Humanoid:Move(-Vector3.zAxis,false)end)
                task.wait(1.1)
                walk:Disconnect();fresh.Humanoid:Move(Vector3.zero,false)
                task.wait(.2)
            end
        end
    end)
    if lap==1 then
        check('Backwards crossing rejected after all checkpoints',function()
            gate(true);assert(#result().lapTimes==0)
        end)
        check('Recovery-protected crossing rejected',function()
            assert(respawn.RecoverPlayer(player,'Lap boundary probe',true))
            gate(false,true);assert(#result().lapTimes==0);task.wait(2)
        end)
    end
    check('Forward shared gate completes lap '..lap,function()
        gate(false)
        assert(#result().lapTimes==lap,'wrong completed lap count')
        if lap<3 then assert(result().currentLap==lap+1 and checkpoint.GetLatestCheckpointIndex(player)==0)
        else assert(result().status=='Finished') end
    end)
end
script:SetAttribute('Result',game.HttpService:JSONEncode({build=map:GetAttribute('ShipwreckBuild'),records=records,visits=visits,method='Actual checkpoint touches and normal-speed gate walks; teleport setup between checkpoints, not full-race timing'}))
