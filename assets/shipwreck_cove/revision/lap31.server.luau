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
assert(result().currentLap==1 and #result().lapTimes==0
    and checkpoint.GetLatestCheckpointIndex(player)==0,"Restart with fresh lap progress before probing")

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
    task.wait(.3)
    character:SetAttribute("RecoveryUntil",priorImmunity)
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

check("Missing and out-of-order checkpoints reject lap",function()
    visit(4,false)
    assert(checkpoint.GetLatestCheckpointIndex(player)==0,"Out-of-order checkpoint accepted")
    gate(false)
    assert(result().currentLap==1 and #result().lapTimes==0,"Missing checkpoints completed a lap")
end)

check("Ordered R1 and cannon recovery",function()
    visit(1)
    assert(checkpoint.GetLatestCheckpointIndex(player)==1)
    recovery("H01 cannon",Vector3.new(-108,16.1,-7),1,10)
end)

check("Ordered R2 and rib shortcut miss recovery",function()
    visit(2)
    assert(checkpoint.GetLatestCheckpointIndex(player)==2)
    recovery("X01 rib miss",Vector3.new(-60,4,-50),2,4)
end)

check("Broken hull bilge gaps return to R2 before decorative reef",function()
    recovery("Bow bilge",Vector3.new(-110,15,-96),2,5)
    recovery("Midship bilge",Vector3.new(-65,25,-101),2,5)
    recovery("Stern bilge",Vector3.new(-25,35,-106),2,5)
end)

check("Ordered R3 and spar shortcut miss recovery",function()
    visit(3)
    assert(checkpoint.GetLatestCheckpointIndex(player)==3)
    recovery("X02 spar miss",Vector3.new(55,4,-43),3,4)
end)

check("Ordered R4 and cave wave recovery",function()
    visit(4)
    assert(checkpoint.GetLatestCheckpointIndex(player)==4)
    recovery("H02 tide",Vector3.new(69,8.1,58),4,13)
end)

check("Ordered R5 final wave checkpoint",function() visit(5); assert(checkpoint.GetLatestCheckpointIndex(player)==5) end)

check("Reverse finish crossing rejects lap",function()
    gate(true)
    assert(#result().lapTimes==0 and result().currentLap==1,"Reverse crossing counted")
end)

check("Forward gate completes lap one",function()
    gate(false,1)
    assert(#result().lapTimes==1 and result().currentLap==2,"First lap missing")
    assert(checkpoint.GetLatestCheckpointIndex(player)==0,"Checkpoint sequence did not reset")
end)

check("Death during lap two preserves completed lap and checkpoint",function()
    visit(1)
    visit(2)
    local prior=assert(player.Character)
    prior.Humanoid.Health=0
    assert(waitFor(function()
        return player.Character~=prior and player.Character~=nil
            and player.Character:FindFirstChild("HumanoidRootPart")~=nil
    end,12),"Death respawn timed out")
    task.wait(1.2)
    assert(#result().lapTimes==1 and result().currentLap==2,"Death erased completed lap")
    assert(checkpoint.GetLatestCheckpointIndex(player)==2,"Death erased checkpoint")
    local target=map.Checkpoints.Checkpoint_002
    assert((player.Character.HumanoidRootPart.Position-target.Position).Magnitude<14,
        "Death respawn missed checkpoint")
end)

check("Ordered lap two completes only after remaining checkpoints",function()
    visit(3)
    visit(4)
    visit(5)
    gate(false,2)
    assert(#result().lapTimes==2 and result().currentLap==3,"Second lap missing")
    assert(checkpoint.GetLatestCheckpointIndex(player)==0,"Third-lap checkpoint sequence did not reset")
end)

check("Third ordered lap finishes race",function()
    for index=1,5 do
        visit(index)
        assert(checkpoint.GetLatestCheckpointIndex(player)==index,"Wrong checkpoint order")
    end
    gate(false,3)
    assert(#result().lapTimes==3 and result().status=="Finished","Third lap did not finish")
end)

script:SetAttribute("Result",game.HttpService:JSONEncode({build=map:GetAttribute("ReviewBuild"),records=records,visits=visits,gates=gates,
    method="Actual official-race checkpoint touches, live recoveries and normal-speed gate walks with teleported setup; not continuous traversal or human lap timing"}))
