local RunService=game:GetService("RunService")
local services=game.ServerScriptService.Services
local race=require(services.RaceService)
local checkpoint=require(services.CheckpointService)
local results=require(services.ResultsService)
local playerRace=require(services.PlayerRaceService)
local player=assert(game.Players:GetPlayers()[1],"Need the same Studio player")
local map=assert(workspace:FindFirstChild("RaceCourse"),"No active course")
assert(RunService:IsStudio() and map:GetAttribute("ShipwreckBuild")=="SC_MAP_10",
    "Original SC_MAP_10 course required")
assert(race.IsRaceActive() and playerRace.IsOfficialRacer(player)
    and playerRace.GetPlayerStatus(player)=="Racing","Original race is no longer active")

local function result()
    local current=assert(results.GetCurrentRaceResult())
    for _,entry in current.activeRacers or {} do
        if entry.userId==player.UserId then return entry end
    end
    for _,entry in current.placements or {} do
        if entry.userId==player.UserId then return entry end
    end
    error("Player result missing")
end

assert(result().currentLap==3 and #result().lapTimes==2
    and checkpoint.GetLatestCheckpointIndex(player)==1,
    "Expected failed probe state: lap 3 with R1 as latest checkpoint")

local function waitFor(fn,seconds)
    local deadline=os.clock()+seconds
    repeat task.wait(.05) until fn() or os.clock()>deadline
    return fn()
end

local function place(cf)
    local character=assert(player.Character)
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"))
    local root=assert(character:FindFirstChild("HumanoidRootPart"))
    root:SetNetworkOwner(nil)
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    humanoid:Move(Vector3.zero,false)
    humanoid.Jump=false
    character:PivotTo(cf)
    return character,humanoid,root
end

local records={}
local finalGateZ=nil
local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err),
        checkpoint=checkpoint.GetLatestCheckpointIndex(player),lap=result().currentLap})
    script:SetAttribute("Progress",#records)
    return ok
end

local canContinue=check("Normal-speed R2 entry after missed drop touch",function()
    local character,humanoid,root=place(map.Bounds.CourseOrigin.CFrame*CFrame.new(-108,16.1,-50))
    local previousImmunity=character:GetAttribute("RecoveryUntil") or 0
    character:SetAttribute("RecoveryUntil",workspace:GetServerTimeNow()+3)
    task.wait(.2)
    local binding=RunService.PreSimulation:Connect(function()
        humanoid:Move(-Vector3.zAxis,false)
    end)
    local accepted=waitFor(function()return checkpoint.GetLatestCheckpointIndex(player)==2 end,1.5)
    binding:Disconnect()
    humanoid:Move(Vector3.zero,false)
    root.AssemblyLinearVelocity=Vector3.zero
    character:SetAttribute("RecoveryUntil",previousImmunity)
    assert(accepted,"R2 did not accept a physical entry")
end)

if canContinue then
    canContinue=check("R3 and R4 ordered touches",function()
        for index=3,4 do
            local target=map.Checkpoints[string.format("Checkpoint_%03d",index)]
            place(target.CFrame+Vector3.new(0,10,0))
            assert(waitFor(function()return checkpoint.GetLatestCheckpointIndex(player)==index end,2.5),
                "Checkpoint "..index.." did not register")
            task.wait(.3)
        end
    end)
end

if canContinue then
    check("Third forward gate finishes race",function()
        local _,humanoid,root=place(map.Finish.CFrame*CFrame.new(0,-2.9,8))
        task.wait(.18)
        local binding=RunService.PreSimulation:Connect(function()
            humanoid:Move(-Vector3.zAxis,false)
        end)
        local accepted=waitFor(function()
            return #result().lapTimes==3 and result().status=="Finished"
        end,1.5)
        binding:Disconnect()
        humanoid:Move(Vector3.zero,false)
        root.AssemblyLinearVelocity=Vector3.zero
        task.wait(.3)
        finalGateZ=map.Finish.CFrame:PointToObjectSpace(root.Position).Z
        assert(accepted,"Server did not record third-lap finish")
    end)
end

script:SetAttribute("Result",game.HttpService:JSONEncode({build=map:GetAttribute("ShipwreckBuild"),records=records,finalGateZ=finalGateZ,
    method="Continuation of the failed third lap: physical R2 entry, ordered R3/R4 touches, forward gate; only valid while the same race is active"}))
