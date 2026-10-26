local RunService = game:GetService("RunService")
local ForwardGate = require(game.ReplicatedStorage.Shared.ForwardGate)
local Probe = {}
local function xyz(value) return value and {value.X,value.Y,value.Z} end

-- Services must be the running server's existing service instances.
function Probe.Start(player, course, services, seconds)
    assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer())
    assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
    assert(course:IsDescendantOf(workspace) and course:GetAttribute("CourseId") == "moonlit_citadel")
    local finish = assert(course:FindFirstChild("Finish"))
    assert(finish:IsA("BasePart") and finish:GetAttribute("RequireForwardCrossing") == true)
    assert(services.CheckpointService and services.PlayerRaceService and services.RaceService)
    local duration, started = math.clamp(seconds or 45,1,90), workspace:GetServerTimeNow()
    local rows, previous, oldCharacter, oldRace, elapsed, frames = {}, nil, nil, nil, 0, 0
    local stopped, connection = false, nil
    local function state()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local active = services.RaceService.IsRaceActive() == true
        local official = services.PlayerRaceService.IsOfficialRacer(player) == true
        local status = services.PlayerRaceService.GetPlayerStatus(player)
        local raceId = services.RaceService.GetCurrentRaceId()
        local recoveryUntil = character and character:GetAttribute("RecoveryUntil") or 0
        local alive = root and root:IsA("BasePart") and humanoid and humanoid.Health > 0
        local eligible = alive and active and official and status == "Racing" and recoveryUntil <= workspace:GetServerTimeNow()
        return character, root, humanoid, raceId, eligible,
            {active=active,official=official,status=status,raceId=raceId,alive=alive==true,
                recoveryUntil=recoveryUntil,checkpoint=services.CheckpointService.GetLatestCheckpointIndex(player)}
    end
    local function result()
        return {scope="Passive native server heartbeat; no movement, progress, gate or race mutation",rows=rows,frames=frames,
            source=course:GetAttribute("SourceRevision"),build=course:GetAttribute("BuildRevision"),
            finishCF={finish.CFrame:GetComponents()},finishSize=xyz(finish.Size),duration=elapsed,stopped=stopped}
    end
    local function stop()
        if not stopped then stopped=true;connection:Disconnect() end
        return result()
    end
    connection=RunService.Heartbeat:Connect(function(dt)
        frames+=1;elapsed=workspace:GetServerTimeNow()-started
        local character,root,humanoid,raceId,eligible,progress=state()
        local current=root and root.Position
        local a=previous and finish.CFrame:PointToObjectSpace(previous)
        local b=current and finish.CFrame:PointToObjectSpace(current)
        local continuous=previous and current and oldCharacter==character and oldRace==raceId
        local directionCross=continuous and a.Z>0 and b.Z<=0
        local crossing=directionCross and a:Lerp(b,a.Z/(a.Z-b.Z))
        local gateAccepted=continuous and ForwardGate.Crossed(finish.CFrame,finish.Size,previous,current,dt) or false
        local near=b and math.abs(b.X)<22 and math.abs(b.Y)<18 and math.abs(b.Z)<24
        if #rows<900 and (directionCross or (near and frames%6==0) or progress.status=="Finished") then
            table.insert(rows,{elapsed=elapsed,dt=dt,previous=xyz(previous),current=xyz(current),
                rootGateLocal=xyz(b),planePointLocal=xyz(crossing),directionCross=directionCross==true,
                forwardGateAccepted=gateAccepted,serviceEligible=eligible==true,progress=progress,
                ground=humanoid and tostring(humanoid.FloorMaterial),rootVelocity=root and xyz(root.AssemblyLinearVelocity),
                sampleContinuous=continuous==true})
        end
        if eligible then previous,oldCharacter,oldRace=current,character,raceId else previous,oldCharacter,oldRace=nil,nil,nil end
        if elapsed>=duration or progress.status=="Finished" then stop() end
    end)
    return {Stop=stop,Result=result}
end
return Probe
