--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CourseService = require(script.Parent.CourseService)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

local Service = {}
local services: { [string]: any } = {}
local sources: Folder? = nil
local activeVariant = ""
local activeCourse: Model? = nil
local activeContext: Model? = nil
local enabled = false
local lastRequestAt: { [number]: number } = {}
local variantOrder = { "Original", "Optimized", "Rebuilt" }
local availableVariants: { string } = {}

local function isKnownVariant(variant: string): boolean
    return table.find(variantOrder, variant) ~= nil
end

local function isAvailableVariant(variant: string): boolean
    return table.find(availableVariants, variant) ~= nil
end

local function getTemplate(variant: string): Model?
    if sources == nil or not isKnownVariant(variant) then return nil end
    local template = sources:FindFirstChild(variant)
    return if template ~= nil and template:IsA("Model") then template else nil
end

local function getParts(template: Model): (Model?, Model?)
    local course = template:FindFirstChild("RaceCourse")
    local context = template:FindFirstChild("Context")
    return if course ~= nil and course:IsA("Model") then course else nil,
        if context ~= nil and context:IsA("Model") then context else nil
end

local function broadcast(remote: RemoteEvent, message: string?, checkpointIndex: number?)
    remote:FireAllClients({ enabled = enabled, variant = activeVariant, message = message, checkpointIndex = checkpointIndex,
        availableVariants = table.clone(availableVariants),
        checkpointCount = #CourseService.GetOrderedCheckpoints(),
        unlimitedTime = if services.RaceService ~= nil then services.RaceService.IsInspectionUnlimitedTime() else false })
end

local function bindCourse()
    for _, name in ipairs({ "CheckpointService", "RespawnService", "CourseHazardService" }) do
        local service = services[name]
        if service ~= nil and service.BindActiveCourse ~= nil then service.BindActiveCourse() end
    end
end

local function loadVariant(variant: string): (boolean, string)
    local template = getTemplate(variant)
    if template == nil then return false, "Missing " .. variant .. " source" end
    local courseTemplate, contextTemplate = getParts(template)
    if courseTemplate == nil or contextTemplate == nil then return false, "Source needs RaceCourse and Context models" end
    local warnings = CourseService.ValidateCourseModel(courseTemplate, false)
    if #warnings > 0 then return false, table.concat(warnings, "; ") end

    local candidateCourse = courseTemplate:Clone()
    local candidateContext = contextTemplate:Clone()
    candidateContext.Name = "CityRunInspectionContext"
    candidateCourse.Name = "RaceCourse"
    candidateCourse:SetAttribute("RuntimeActiveCourse", true)
    candidateCourse:SetAttribute("CityRunInspectionVariant", variant)
    candidateContext:SetAttribute("CityRunInspectionVariant", variant)

    local oldCourse, oldContext = activeCourse, activeContext
    if oldCourse ~= nil then oldCourse.Parent = nil end
    if oldContext ~= nil then oldContext.Parent = nil end
    candidateCourse.Parent = Workspace
    candidateContext.Parent = Workspace
    activeCourse, activeContext, activeVariant = candidateCourse, candidateContext, variant
    local bound, bindError = pcall(bindCourse)
    if not bound then
        candidateCourse.Parent = nil; candidateContext.Parent = nil
        activeCourse, activeContext, activeVariant = oldCourse, oldContext, if oldCourse ~= nil then tostring(oldCourse:GetAttribute("CityRunInspectionVariant") or "") else ""
        if oldCourse ~= nil then oldCourse.Parent = Workspace end
        if oldContext ~= nil then oldContext.Parent = Workspace end
        local restored, restoreError = pcall(bindCourse)
        candidateCourse:Destroy(); candidateContext:Destroy()
        if not restored then
            return false, tostring(bindError) .. "; previous course rebind also failed: " .. tostring(restoreError)
        end
        return false, tostring(bindError)
    end
    if oldCourse ~= nil then oldCourse:Destroy() end
    if oldContext ~= nil then oldContext:Destroy() end
    return true, variant .. " loaded"
end

local function jump(player: Player, checkpointIndex: number): boolean
    local character = player.Character
    local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
    local checkpointService = services.CheckpointService
    if character == nil or root == nil or not root:IsA("BasePart") or checkpointService == nil or checkpointService.SetInspectionCheckpointForStudio == nil then return false end
    local destination = checkpointService.SetInspectionCheckpointForStudio(player, checkpointIndex)
    if destination == nil then return false end
    character:PivotTo(destination.CFrame + Vector3.new(0, math.max(5, destination.Size.Y / 2 + 3), 0))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

function Service.Init(context: { Services: { [string]: any } }?)
    if context ~= nil then services = context.Services end
end

function Service.Start()
    local source = ServerStorage:FindFirstChild("CityRunInspectionSources")
    enabled = RunService:IsStudio() and source ~= nil and source:IsA("Folder") and source:GetAttribute("Enabled") == true
        and CourseService.IsInspectionMode()
    if not enabled then return end
    sources = source :: Folder
    local original = getTemplate("Original")
    local optimized = getTemplate("Optimized")
    local originalCourse: Model? = nil
    local originalContext: Model? = nil
    local optimizedCourse: Model? = nil
    local optimizedContext: Model? = nil
    if original ~= nil then originalCourse, originalContext = getParts(original) end
    if optimized ~= nil then optimizedCourse, optimizedContext = getParts(optimized) end
    if originalCourse == nil or originalContext == nil or optimizedCourse == nil or optimizedContext == nil then
        enabled = false
        warn("[CityRunInspection] Incomplete Original/Optimized templates; inspection unavailable.")
        return
    end
    availableVariants = { "Original", "Optimized" }
    local rebuilt = getTemplate("Rebuilt")
    if rebuilt ~= nil then
        local rebuiltCourse, rebuiltContext = getParts(rebuilt)
        if rebuiltCourse ~= nil and rebuiltContext ~= nil then
            local rebuiltWarnings = CourseService.ValidateCourseModel(rebuiltCourse, false)
            if #rebuiltWarnings == 0 then
                table.insert(availableVariants, "Rebuilt")
            else
                warn("[CityRunInspection] Rebuilt template unavailable: " .. table.concat(rebuiltWarnings, "; "))
            end
        else
            warn("[CityRunInspection] Rebuilt template unavailable: source needs RaceCourse and Context models.")
        end
    end
    local roots = sources:FindFirstChild("OriginalWorkspaceRoots")
    local parked = Instance.new("Folder")
    parked.Name = "CityRunInspectionParkedLiveRoots"
    parked.Parent = ServerStorage
    if roots ~= nil and roots:IsA("Folder") then
        for _, reference in ipairs(roots:GetChildren()) do
            if reference:IsA("ObjectValue") and reference.Value ~= nil and reference.Value.Parent == Workspace then
                reference.Value.Parent = parked
            end
        end
    end
    for _, rootName in ipairs({ "CityRunV3Stage2Preview", "CityRunV3AssetReview" }) do
        local root = Workspace:FindFirstChild(rootName)
        if root ~= nil then root.Parent = parked end
    end
    local oldCourse = Workspace:FindFirstChild("RaceCourse")
    if oldCourse ~= nil then oldCourse.Parent = nil end
    local ok, message = loadVariant("Original")
    if not ok then
        if oldCourse ~= nil then oldCourse.Parent = Workspace end
        for _, root in ipairs(parked:GetChildren()) do root.Parent = Workspace end
        local restored, restoreError = pcall(bindCourse)
        parked:Destroy()
        enabled = false
        if not restored then message ..= "; previous course rebind also failed: " .. tostring(restoreError) end
        warn("[CityRunInspection] " .. message)
        return
    end
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local request = remotes:WaitForChild("RequestCityRunInspection") :: RemoteEvent
    local state = remotes:WaitForChild("CityRunInspectionState") :: RemoteEvent
    Players.PlayerAdded:Connect(function(player)
        task.defer(function() if player.Parent ~= nil then state:FireClient(player, { enabled = true, variant = activeVariant,
            availableVariants = table.clone(availableVariants),
            unlimitedTime = if services.RaceService ~= nil then services.RaceService.IsInspectionUnlimitedTime() else false }) end end)
    end)
    request.OnServerEvent:Connect(function(player, payload)
        if not enabled or not RunService:IsStudio() or typeof(payload) ~= "table" then return end
        local now = os.clock()
        if now - (lastRequestAt[player.UserId] or 0) < 0.3 then return end
        lastRequestAt[player.UserId] = now
        local action = payload.action
        if action == "State" then
            broadcast(state)
            return
        end
        local message = ""
        local jumpedCheckpointIndex: number? = nil
        if action == "Switch" and typeof(payload.variant) == "string" and isAvailableVariant(payload.variant) then
            if payload.variant ~= activeVariant then
                local ok, result = loadVariant(payload.variant)
                message = result
                if ok and services.RaceService ~= nil then
                    services.RaceService.RestartInspectionRound()
                    message ..= "; race restarting"
                end
            end
        elseif action == "Jump" and typeof(payload.checkpointIndex) == "number" and payload.checkpointIndex % 1 == 0 then
            if jump(player, payload.checkpointIndex) then
                jumpedCheckpointIndex = payload.checkpointIndex
                message = if jumpedCheckpointIndex == 0 then "Jumped to start" else "Jumped to checkpoint " .. tostring(jumpedCheckpointIndex)
            else
                message = "Checkpoint unavailable"
            end
        elseif action == "UnlimitedTime" and typeof(payload.enabled) == "boolean" and services.RaceService ~= nil then
            services.RaceService.SetInspectionUnlimitedTime(payload.enabled)
            message = if payload.enabled then "Race time unlimited" else "Race timer restored"
        end
        broadcast(state, message, jumpedCheckpointIndex)
    end)
    broadcast(state, "Original loaded")
    if oldCourse ~= nil then oldCourse:Destroy() end
end

function Service.IsEnabled(): boolean return enabled end
function Service.GetVariant(): string return activeVariant end

return Service
