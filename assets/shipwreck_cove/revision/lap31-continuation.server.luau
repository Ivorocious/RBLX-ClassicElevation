local RunService=game:GetService("RunService")
local services=game.ServerScriptService.Services
local race=require(services.RaceService)
local checkpoint=require(services.CheckpointService)
local results=require(services.ResultsService)
local playerRace=require(services.PlayerRaceService)
local Layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local player=assert(game.Players:GetPlayers()[1],"Need one Studio test player")
local map=assert(workspace:FindFirstChild("RaceCourse"),"No active RaceCourse")
assert(RunService:IsStudio(),"Studio only")
assert(map:GetAttribute("ShipwreckBuild")==Layout.build,
    "Installed course and source layout differ")
assert(map.CourseInfo:GetAttribute("LapCount")==3,"Expected three laps")
assert(race.IsRaceActive() and playerRace.IsOfficialRacer(player)
    and playerRace.GetPlayerStatus(player)=="Racing","Start an official Studio race first")

local records={}
local visits={}
local gates={}
local origin=map.Bounds.CourseOrigin.CFrame

local function result()
    local current=assert(results.GetCurrentRaceResult(),"No current race result")
    for _,list in {current.activeRacers,current.placements} do
        for _,entry in list or {} do
            if entry.userId==player.UserId then return entry end
        end
    end
    error("No result for test player")
end
assert(result().currentLap==3 and checkpoint.GetLatestCheckpointIndex(player)==2,'Resume after CP2 diagnostic')

local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute("Progress",#records)
end

local function waitFor(fn,seconds)
    local deadline=os.clock()+seconds
    repeat task.wait(.05) until fn() or os.clock()>deadline
    return fn()
end

local function place(cf)
    local character=assert(player.Character,"Character unavailable")
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"Humanoid unavailable")
    local root=assert(character:FindFirstChild("HumanoidRootPart"),"Root unavailable")
    root:SetNetworkOwner(nil)
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    humanoid:Move(Vector3.zero,false)
    humanoid.Jump=false
    character:PivotTo(cf)
    return character,root
end

local function walkIntoR2()
    local character,root=place(origin*CFrame.new(-108,16.1,-50))
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local previousImmunity=character:GetAttribute("RecoveryUntil") or 0
    character:SetAttribute("RecoveryUntil",workspace:GetServerTimeNow()+3)
    task.wait(.2)
    local binding=RunService.PreSimulation:Connect(function()
        humanoid:Move(-Vector3.zAxis,false)
    end)
    local accepted=waitFor(function()return checkpoint.GetLatestCheckpointIndex(player)>=2 end,1.5)
    binding:Disconnect()
    humanoid:Move(Vector3.zero,false)
    root.AssemblyLinearVelocity=Vector3.zero
    character:SetAttribute("RecoveryUntil",previousImmunity)
    return accepted
end

local function visit(index,expectTouch)
    local target=assert(map.Checkpoints[string.format("Checkpoint_%03d",index)],"Missing checkpoint")
    local character=place(target.CFrame+Vector3.new(0,10,0))
    local priorImmunity=character:GetAttribute("RecoveryUntil") or 0
    character:SetAttribute("RecoveryUntil",workspace:GetServerTimeNow()+5)
    local method="drop"
    if expectTouch==false then
        task.wait(.6)
    else
        local accepted=waitFor(function()return checkpoint.GetLatestCheckpointIndex(player)>=index end,2.5)
        if not accepted and index==2 and checkpoint.GetLatestCheckpointIndex(player)==1 then
            accepted=walkIntoR2()
            method="normal-speed re-entry after missed drop touch"
        end
        assert(accepted,"Checkpoint touch timed out: "..index)
    end
    character:SetAttribute("RecoveryUntil",priorImmunity)
    task.wait(.3)
    table.insert(visits,{requested=index,actual=checkpoint.GetLatestCheckpointIndex(player),method=method,
        lap=result().currentLap,position=tostring(character.HumanoidRootPart.Position)})
end

local function gate(reverse,expectedCompletedLaps)
    local character=assert(player.Character)
    local root=assert(character:FindFirstChild("HumanoidRootPart"))
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"))
    place(map.Finish.CFrame*CFrame.new(0,-2.9,if reverse then -1.1 else 8))
    task.wait(.18)
    local direction=if reverse then Vector3.zAxis else -Vector3.zAxis
    local binding=RunService.PreSimulation:Connect(function()humanoid:Move(direction,false)end)
    local acceptedOrCrossed=waitFor(function()
        if expectedCompletedLaps then return #result().lapTimes>=expectedCompletedLaps end
        local z=map.Finish.CFrame:PointToObjectSpace(root.Position).Z
        return if reverse then z>4 else z<-.4
    end,1.5)
    binding:Disconnect()
    humanoid:Move(Vector3.zero,false)
    root.AssemblyLinearVelocity=Vector3.zero
    task.wait(.3)
    local current=result()
    table.insert(gates,{reverse=reverse,expectedCompletedLaps=expectedCompletedLaps or 0,
        gateZ=map.Finish.CFrame:PointToObjectSpace(root.Position).Z,
        completedLaps=#current.lapTimes,status=current.status,acceptedOrCrossed=acceptedOrCrossed})
    assert(acceptedOrCrossed,if expectedCompletedLaps then "Server did not record expected lap at gate"
        else "Normal-speed gate walk did not cross")
end

local function recovery(name,p,expectedCheckpoint,seconds)
    task.wait(1.65)
    local beforeFalls=result().falls
    local character,root=place(origin*CFrame.new(p))
    character:SetAttribute("RecoveryUntil",0)
    assert(waitFor(function()
        return (character:GetAttribute("RecoveryUntil") or 0)>workspace:GetServerTimeNow()
    end,seconds),name.." did not recover")
    assert(result().falls>beforeFalls,name.." did not record a fall")
    assert(checkpoint.GetLatestCheckpointIndex(player)==expectedCheckpoint,
        name.." changed checkpoint progress")
    local target=map.Checkpoints[string.format("Checkpoint_%03d",expectedCheckpoint)]
    assert((root.Position-target.Position).Magnitude<12,name.." returned to wrong checkpoint")
end

check("Complete third lap after checkpoint re-entry",function() for i=3,5 do visit(i) end;gate(false,3);assert(#result().lapTimes==3 and result().status=="Finished") end)
script:SetAttribute("Result",game.HttpService:JSONEncode({build=map:GetAttribute("ReviewBuild"),records=records,visits=visits,gates=gates,method="Continuation after successful CP2 diagnostic re-entry; original rapid checkpoint probe missed CP2 on third lap. Teleported setup; not continuous traversal."}))
