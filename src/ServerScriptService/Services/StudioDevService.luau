--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}
local services: any
local lastRequest: {[Player]: number} = {}

local function snapshot(ok: boolean, message: string?)
    local course = services.CourseService
    local maps = {}
    for _, id in course.GetDiscoveredCourseIds() do
        local info = course.GetCourseInfo(id)
        if info and course.CanSelectCourseForStudio(id) then table.insert(maps, {id=id, name=info.displayName}) end
    end
    local checkpoints = {}
    for _, item in course.GetOrderedCheckpoints() do
        table.insert(checkpoints, {index=item.index, name=item.name})
    end
    return {
        ok=ok, message=message, maps=maps, checkpoints=checkpoints,
        state=services.RaceService.GetRaceState(), selectedMap=course.GetSelectedCourseId(),
        mapLoaded=course.GetActiveCourse() ~= nil,
        unlimitedTime=services.RaceService.IsInspectionUnlimitedTime(),
        holdInLobby=services.RaceService.IsStudioHoldingLobby(),
    }
end

local function teleport(player: Player, payload): (boolean, string)
    local course = services.CourseService
    if payload.destination == "Lobby" then
        services.PlayerRaceService.SetPlayerStatus(player, "Lobby", "Studio teleport")
        services.StagingService.ReturnPlayersToLobby({player}, "Studio teleport")
        return true, "Returned to lobby; Restart race to rejoin."
    end
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if not character or not root or not root:IsA("BasePart") then return false, "Character is not ready." end
    local destination: BasePart? = nil
    if payload.destination == "Start" then destination = course.GetStartPart()
    elseif payload.destination == "Finish" then destination = course.GetFinishPart()
    elseif payload.destination == "Checkpoint" then
        local index = payload.checkpointIndex
        if typeof(index) ~= "number" or index ~= index or index % 1 ~= 0 then return false, "Invalid checkpoint." end
        for _, checkpoint in course.GetOrderedCheckpoints() do
            if checkpoint.index == index then destination = checkpoint.part; break end
        end
        if destination then
            services.CheckpointService.SetInspectionCheckpointForStudio(player, index)
        end
    else return false, "Unknown destination." end
    if not destination then return false, "No active map/destination. Start a race first." end
    if services.RaceService.GetRaceState() == "Countdown" or services.RaceService.GetRaceState() == "Intermission" then
        return false, "Start the race first so staging does not move you back."
    end
    if payload.destination == "Start" then services.CheckpointService.SetInspectionCheckpointForStudio(player, 0) end
    character:PivotTo(destination.CFrame + Vector3.new(0, destination.Size.Y / 2 + 5, 0))
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    return true, "Teleported to " .. payload.destination .. "."
end

function Service.Init(context)
    services = context.Services
end

function Service.HandleRequest(player: Player, payload)
    if not RunService:IsStudio() then return {ok=false, message="Studio only."} end
    if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return {ok=false, message="Invalid player."} end
    if typeof(payload) ~= "table" or typeof(payload.action) ~= "string" then return snapshot(false, "Invalid request.") end
    if payload.action == "State" then return snapshot(true) end
    local now = os.clock()
    if now - (lastRequest[player] or -math.huge) < 0.15 then return snapshot(false, "Please wait a moment.") end
    lastRequest[player] = now
    local ok, message = false, "Unknown developer action."
    if payload.action == "OnboardingPreset" then
        ok, message = services.OnboardingService.SetStudioPreset(player, payload.preset)
    elseif payload.action == "Map" then
        if player:GetAttribute("OnboardingReady") ~= true then
            return snapshot(false, "Finish choosing your avatar and enter the lobby first, then select a race map.")
        end
        if typeof(payload.courseId) == "string" and services.CourseService.SelectCourseForStudio(payload.courseId) then
            services.RaceService.ApplyStudioAction("RestartRace")
            ok, message = true, "Switching map and restarting the round..."
        else message = "That map is unavailable." end
    elseif payload.action == "Teleport" then
        ok, message = teleport(player, payload)
    elseif payload.action == "UnlimitedTime" and typeof(payload.enabled) == "boolean" then
        services.RaceService.SetInspectionUnlimitedTime(payload.enabled)
        ok, message = true, if payload.enabled then "Race timer is unlimited." else "Race timer restored."
    elseif payload.action == "Respawn" then
        player:LoadCharacterAsync()
        ok, message = true, "Character respawned."
    elseif table.find({"StartEvent", "StartRace", "RestartRace", "NextState", "EndRace", "HoldLobby"}, payload.action) then
        ok = services.RaceService.ApplyStudioAction(payload.action)
        message = if ok then "Requested " .. payload.action .. "." else "Action unavailable in this state."
    end
    return snapshot(ok, message)
end

function Service.Start()
    if not RunService:IsStudio() then return end
    local remote = Instance.new("RemoteFunction")
    remote.Name = "StudioDevControl"
    remote.OnServerInvoke = function(player, payload)
        local ok, result = pcall(Service.HandleRequest, player, payload)
        if ok then return result end
        warn("[StudioDev] " .. tostring(result))
        return snapshot(false, "Developer action failed. Check Output.")
    end
    remote.Parent = ReplicatedStorage:WaitForChild("Remotes")
    Players.PlayerRemoving:Connect(function(player)
        lastRequest[player] = nil
    end)
end

return Service
