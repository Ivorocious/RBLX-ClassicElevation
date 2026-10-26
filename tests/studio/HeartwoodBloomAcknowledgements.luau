--!strict
-- Edit-mode simulation of the actual runtime callback; this does not render cues or test networking.
local Simulation = {}

function Simulation.Run(context)
    assert(game:GetService("RunService"):IsStudio(), "Studio only")
    assert(not game:GetService("RunService"):IsRunning(), "Run this recipe in Edit mode")
    assert(typeof(context.runtimeSource) == "string", "Supply current Runtime.Source")
    local config = context.config
    if not config then
        assert(typeof(context.configSource) == "string", "Supply Config or current Config.Source")
        local configChunk, configError = loadstring(context.configSource); assert(configChunk, configError)
        config = configChunk()
    end
    local state = context.state
    if not state then
        assert(typeof(context.stateSource) == "string", "Supply State or current State.Source")
        local declaration = 'local Config = require(game.ReplicatedStorage.Config.HeartwoodConfig)'
        local first, last = string.find(context.stateSource, declaration, 1, true)
        assert(first and last, "State dependency declaration changed")
        local stateSource = string.sub(context.stateSource, 1, first - 1) .. string.sub(context.stateSource, last + 1)
        local stateChunk, stateError = loadstring("return function(Config)\n" .. stateSource .. "\nend")
        assert(stateChunk, stateError); state = stateChunk()(config)
    end
    local source = context.runtimeSource
    for _, declaration in {
        'local Players = game:GetService("Players")',
        'local Config = require(game.ReplicatedStorage.Config.HeartwoodConfig)',
        'local State = require(game.ReplicatedStorage.Shared.HeartwoodState)',
    } do
        local first, last = string.find(source, declaration, 1, true)
        assert(first and last, "Runtime dependency declaration changed: " .. declaration)
        assert(not string.find(source, declaration, last + 1, true), "Ambiguous runtime dependency")
        source = string.sub(source, 1, first - 1) .. string.sub(source, last + 1)
    end
    local compile, compileError = loadstring("return function(Players, Config, State)\n" .. source .. "\nend")
    assert(compile, compileError)
    local rows, messages, racers = {}, {}, {}
    local function signal()
        local connection
        return {Connect = function(_, callback)
            connection = callback
            return {Disconnect = function() connection = nil end}
        end, Emit = function(_, ...) if connection then connection(...) end end}
    end
    local fakePlayers = {PlayerRemoving = signal(), GetPlayers = function() return racers end}
    local cue = {OnServerEvent = signal()}
    function cue:FireClient(racer, action, suppliedToken, third, fourth)
        table.insert(messages, {player = racer.Name, action = action, token = suppliedToken,
            time = workspace:GetServerTimeNow(), releaseAt = if action == "schedule" then third else fourth})
    end
    local runtime = compile()(fakePlayers, config, state)
    local fixture = Instance.new("Model"); fixture.Name = "HeartwoodAcknowledgementSimulation"
    local function folder(parent, name)
        local result = Instance.new("Model"); result.Name = name; result.Parent = parent; return result
    end
    local function part(parent, name, position, size, collide)
        local result = Instance.new("Part"); result.Name = name; result.Anchored = true
        result.Size = size; result.Position = position; result.CanCollide = collide
        result.CanQuery = collide; result.CanTouch = false; result.Parent = parent; return result
    end
    local decoration = folder(fixture, "Decoration")
    local hazards = folder(decoration, "HeartwoodHazards")
    for i = 1, 2 do
        local pod = folder(hazards, "Pod_" .. i); local base = config.Origin + Vector3.new(200 + i * 20, 112, 200)
        pod:SetAttribute("Offset", i * 3); pod:SetAttribute("Base", base)
        part(pod, "Pod", base, Vector3.new(6, 8, 6), false)
        part(pod, "WarningPatch", base, Vector3.new(8, .1, 8), false)
    end
    part(hazards, "PulseRibbon", config.Origin, Vector3.new(12, 1.5, 1.2), false)
    part(hazards, "HeartKnot", config.Origin, Vector3.new(6, 8, 4), false)
    local gardens = folder(decoration, "S03_HangingGardens"); folder(gardens, "Leaves")
    local sanctuary = folder(decoration, "S04_SanctuaryBough"); local blooms = folder(sanctuary, "Blooms")
    local flower = folder(blooms, "B0"); flower:SetAttribute("Receiver", "J3")
    local top = config.Origin + Vector3.new(0, 112, 0)
    local center = part(flower, "Center", top - Vector3.new(0, .5, 0), Vector3.new(20, 1, 20), true)
    center:SetAttribute("BloomRadius", 10)
    part(sanctuary, "Outside", top + Vector3.new(0, -.5, 18), Vector3.new(30, 1, 12), true)
    local receiver = folder(sanctuary, "J3")
    part(receiver, "Top", top + Vector3.new(0, 9.5, -28), Vector3.new(30, 1, 22), true)
    fixture.Parent = workspace
    local function racer(name)
        local character = folder(fixture, name)
        local humanoid = Instance.new("Humanoid"); humanoid.HipHeight = 2; humanoid.Parent = character
        local root = part(character, "HumanoidRootPart", top + Vector3.new(0, 3, 18), Vector3.new(2, 2, 1), false)
        character.PrimaryPart = root
        local result = {Name = name, Character = character, Parent = fakePlayers}
        table.insert(racers, result); return result, root
    end
    local a, rootA = racer("Simulated_A"); local b, rootB = racer("Simulated_B")
    local controller; local epoch = workspace:GetServerTimeNow()
    local function step(active)
        controller.Step(workspace:GetServerTimeNow() - epoch, 1 / 60, active ~= false)
    end
    local function pump(seconds)
        local began = workspace:GetServerTimeNow()
        repeat step(true); task.wait(1 / 60) until workspace:GetServerTimeNow() - began >= seconds
    end
    local function move(root, inside)
        root.Position = top + Vector3.new(0, 3, if inside then 0 else 18)
        root.AssemblyLinearVelocity = Vector3.zero; step(true)
    end
    local function latest(racerName, action)
        for i = #messages, 1, -1 do local message = messages[i]
            if message.player == racerName and message.action == action then return message end
        end
        error("Missing cue " .. racerName .. ":" .. action)
    end
    local function record(id, passed, details)
        table.insert(rows, {id = id, passed = passed, details = details})
        assert(passed, "Simulation failed: " .. id)
    end
    local ok, result = xpcall(function()
        controller = runtime.Create(fixture, function() error("Unexpected recovery in acknowledgement simulation") end,
            function() return true end, function() return 3 end, cue)
        move(rootA, true); local beginA = latest(a.Name, "begin")
        pump(.1); move(rootB, true); local beginB = latest(b.Name, "begin")
        record("separate-arm", beginA.token ~= beginB.token and beginB.time > beginA.time, {a = beginA, b = beginB})
        cue.OnServerEvent:Emit(a, "visible", beginB.token); cue.OnServerEvent:Emit(a, "arbitrary", beginA.token)
        record("wrong-token-and-action", controller.Diagnostics().acknowledgements == 0, controller.Diagnostics())
        pump(.2); local ackA = workspace:GetServerTimeNow(); cue.OnServerEvent:Emit(a, "visible", beginA.token)
        local scheduleA = latest(a.Name, "schedule")
        cue.OnServerEvent:Emit(a, "visible", beginA.token)
        record("delayed-ack", controller.Diagnostics().acknowledgements == 1
            and scheduleA.releaseAt >= ackA + config.BloomVisibleCue - .005
            and scheduleA.releaseAt >= beginA.time + config.BloomArmTime - .005,
            {arm = beginA.time, acknowledged = ackA, schedule = scheduleA})
        pump(.3); local ackB = workspace:GetServerTimeNow(); cue.OnServerEvent:Emit(b, "visible", beginB.token)
        local scheduleB = latest(b.Name, "schedule")
        while workspace:GetServerTimeNow() < scheduleA.releaseAt + .025 do step(true); task.wait(1 / 60) end
        record("independent-first-release", controller.Diagnostics().releases == 1
            and rootA.AssemblyLinearVelocity.Y == config.BloomSpeed and rootB.AssemblyLinearVelocity.Y == 0,
            {a = latest(a.Name, "release"), bSchedule = scheduleB, diagnostics = controller.Diagnostics()})
        while workspace:GetServerTimeNow() < scheduleB.releaseAt + .025 do step(true); task.wait(1 / 60) end
        local releaseA, releaseB = latest(a.Name, "release"), latest(b.Name, "release")
        record("full-personal-cue", controller.Diagnostics().releases == 2
            and releaseA.time - ackA >= config.BloomVisibleCue - .005
            and releaseB.time - ackB >= config.BloomVisibleCue - .005,
            {aVisibleSeconds = releaseA.time - ackA, bVisibleSeconds = releaseB.time - ackB, a = releaseA, b = releaseB})
        move(rootA, true); move(rootB, true); pump(config.BloomRearmDelay + .05)
        record("landed-without-exit-lock", latest(a.Name, "begin").token == beginA.token
            and latest(b.Name, "begin").token == beginB.token and controller.Diagnostics().releases == 2, controller.Diagnostics())
        move(rootA, false); move(rootA, true); local reentry = latest(a.Name, "begin")
        record("fresh-grounded-reentry", reentry.token ~= beginA.token, {previousToken = beginA.token, next = reentry})
        cue.OnServerEvent:Emit(a, "visible", reentry.token); move(rootA, false); pump(.1)
        record("leave-cancels", latest(a.Name, "cancel").token == reentry.token and controller.Diagnostics().releases == 2, controller.Diagnostics())
        move(rootB, false); move(rootB, true); local endArm = latest(b.Name, "begin")
        cue.OnServerEvent:Emit(b, "visible", endArm.token); step(false)
        record("race-end-cancels", latest(b.Name, "cancel").token == endArm.token and controller.Diagnostics().releases == 2, controller.Diagnostics())
        move(rootB, false); move(rootA, true); local noAck = latest(a.Name, "begin")
        pump(config.CueTimeout + .1)
        record("missing-ack-never-releases", latest(a.Name, "cancel").token == noAck.token
            and controller.Diagnostics().releases == 2, controller.Diagnostics())
        return {passed = true, cases = rows, messages = messages, diagnostics = controller.Diagnostics(),
            scope = "Edit-mode simulation; actual Runtime source and OnServerEvent callback; fake Player tables, real anchored models; no rendered-client, latency, network or multiplayer proof"}
    end, debug.traceback)
    if controller then controller.Stop() end
    local history = game.ServerStorage:FindFirstChild("HeartwoodBuildHistory")
    if not history then history = Instance.new("Folder"); history.Name = "HeartwoodBuildHistory"; history.Parent = game.ServerStorage end
    fixture.Name = "HA03AcknowledgementSimulation_" .. game:GetService("HttpService"):GenerateGUID(false)
    fixture.Parent = history
    if not ok then return {passed = false, error = result, cases = rows, messages = messages, scope = "Edit-mode simulation only"} end
    return result
end

return Simulation
