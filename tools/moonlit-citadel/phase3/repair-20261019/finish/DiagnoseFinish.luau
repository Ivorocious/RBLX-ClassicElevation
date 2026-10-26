local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local own = "tools/moonlit-citadel/phase3/repair-20261019/finish/"
local base = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local V, C = roblox.Vector3, roblox.CFrame
local inputs = {}
local function source(path)
    local raw = fs.readFile(path)
    inputs[path] = serde.hash("sha256", raw)
    return raw
end
local function load(path, environment)
    environment.Vector3, environment.CFrame = V, C
    environment.require = function(value) return value end
    return luau.load(source(path), {environment = environment})()
end
local config = load("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau", {})
local gate = load("src/ReplicatedStorage/Shared/ForwardGate.luau", {})
local parent = {}
local gameLayout = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = config}}}
for _, name in {"ExpertRoutes", "RouteHazardLayout", "RouteHazardGoals", "SupportingObstacles"} do
    parent[name] = load(base .. name .. ".luau", {script = {Parent = parent}, game = gameLayout})
end
local layout = load(base .. "Layout.luau", {script = {Parent = parent}, game = gameLayout})
local checkpointConfig = load("src/ReplicatedStorage/Config/CheckpointConfig.luau", {})
local constants = load("src/ReplicatedStorage/Shared/RaceConstants.luau", {script = {Parent = {RaceTypes = {}}}})
local servicePath = "src/ServerScriptService/Services/CheckpointService.luau"
local serviceRaw = source(servicePath)
source(base .. "RouteBuilder.luau")
source(base .. "Coverage.luau")
source("src/ServerScriptService/Services/RespawnService.luau")
local function xyz(value) return {value.X, value.Y, value.Z} end
local function recipe(height, width)
    local data = layout.FinishGate
    local size = V.new(width or data.size.X, height or data.size.Y, data.size.Z)
    return {point = data.point, size = size,
        frame = C.new(config.Origin + data.point + V.new(0, size.Y / 2, 0)) * C.Angles(0, data.yaw, 0)}
end
local current, proposed = recipe(), recipe(12, 28)
local function crosses(data, a, b, dt)
    return gate.Crossed(data.frame, data.size, a and config.Origin + a, config.Origin + b, dt)
end
local cases = {
    {name = "standing_centre_forward", a = V.new(-4.8,153.181,-30), b = V.new(-5.1,153.181,-30), old = true, new = true},
    {name = "ordinary_jump_across_plane", a = V.new(-4.8,159.5,-30), b = V.new(-5.1,159.6,-30), old = false, new = true},
    {name = "standing_north_supported_lane", a = V.new(-4.8,153.181,-42), b = V.new(-5.1,153.181,-42), old = false, new = true},
    {name = "standing_south_supported_lane", a = V.new(-4.8,153.181,-18), b = V.new(-5.1,153.181,-18), old = false, new = true},
    {name = "backward", a = V.new(-5.1,153.181,-30), b = V.new(-4.8,153.181,-30), old = false, new = false},
    {name = "already_past_plane", a = V.new(-5.1,153.181,-30), b = V.new(-5.4,153.181,-30), old = false, new = false},
    {name = "land_after_missed_air_crossing", a = V.new(-6,156.2,-30), b = V.new(-6.1,155.8,-30), old = false, new = false},
    {name = "teleport", a = V.new(25,153.181,-30), b = V.new(-5.1,153.181,-30), old = false, new = false},
    {name = "one_frame_jump_over_speed_cap", a = V.new(-3,153.181,-30), b = V.new(-6,153.181,-30), old = false, new = false},
    {name = "stale_sample", a = V.new(-4.8,153.181,-30), b = V.new(-5.1,153.181,-30), dt = 1.01, old = false, new = false},
    {name = "first_sample", b = V.new(-5.1,153.181,-30), old = false, new = false},
    {name = "under_floor", a = V.new(-4.8,149,-30), b = V.new(-5.1,149,-30), old = false, new = false},
    {name = "outside_crown_width", a = V.new(-4.8,153.181,-45), b = V.new(-5.1,153.181,-45), old = false, new = false},
    {name = "above_ordinary_jump_envelope", a = V.new(-4.8,163,-30), b = V.new(-5.1,163,-30), old = false, new = false},
}
local direct = {}
for _, case in cases do
    local old, new = crosses(current, case.a, case.b, case.dt or 1/60), crosses(proposed, case.a, case.b, case.dt or 1/60)
    assert(old == case.old and new == case.new, "Unexpected direct result: " .. case.name)
    table.insert(direct, {name = case.name, current = old, proposed = new, expectedCurrent = case.old, expectedProposed = case.new})
end
local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback)
            local item = {callback = callback, connected = true}
            table.insert(callbacks, item)
            return {Disconnect = function() item.connected = false end}
        end,
        Fire = function(_, ...)
            for _, item in callbacks do if item.connected then item.callback(...) end end
        end,
    }
end
local function harness(data, options)
    options = options or {}
    local heartbeat, removal = signal(), signal()
    local root = {Name = "HumanoidRootPart", Position = config.Origin + V.new(-4.8,153.181,-30)}
    function root:IsA(class) return class == "BasePart" end
    local humanoid = {Health = 100}
    local charAttrs, character = {}, {}
    function character:FindFirstChild(name) return if name == "HumanoidRootPart" then root else nil end
    function character:FindFirstChildOfClass(name) return if name == "Humanoid" then humanoid else nil end
    function character:GetAttribute(name) return charAttrs[name] end
    function root:FindFirstAncestorWhichIsA(name) return if name == "Model" then character else nil end
    local player = {UserId = 12345, Name = "OfflineOfficialRacer", Character = character}
    local players = {PlayerRemoving = removal}
    function players:GetPlayers() return {player} end
    function players:GetPlayerFromCharacter(value) return if value == player.Character then player else nil end
    local raceId, status, official, active, elapsed = "offline-1", "Racing", true, true, 100
    local now, finishes, splits = 100, 0, {}
    local function part(name, attrs)
        local item = {Name = name, CFrame = data.frame, Size = data.size, Touched = signal()}
        function item:GetAttribute(key) return (attrs or {})[key] end
        function item:FindFirstChild() return nil end
        return item
    end
    local finish = part("Finish", {RequireForwardCrossing = true})
    local start = part("Start")
    local checkpoints = {}
    for index = 1, 4 do
        table.insert(checkpoints, {index = index, name = "Checkpoint" .. index, part = part("Checkpoint" .. index)})
    end
    local services = {
        RaceService = {IsRaceActive = function() return active end, GetCurrentRaceId = function() return raceId end, GetElapsedRaceTime = function() return elapsed end},
        CourseService = {GetActiveCourseModel = function() return {Name = "OfflineMoonlit"} end,
            GetStartPart = function() return start end, GetFinishPart = function() return finish end,
            GetOrderedCheckpoints = function() return checkpoints end, GetRaceFormat = function() return "PointToPoint" end},
        PlayerRaceService = {GetPlayerStatus = function() return status end, IsOfficialRacer = function() return official end,
            SetPlayerStatus = function(_, value) status = value end},
        ResultsService = {RecordCheckpointSplit = function(_, index) table.insert(splits, index) end,
            UpdateCheckpointProgress = function() end,
            RecordFinish = function() if options.recordRejected then return nil end; finishes += 1; return {} end},
    }
    local rep = {Shared = {ForwardGate = gate, RaceConstants = constants, RaceTypes = {}}, Config = {CheckpointConfig = checkpointConfig}}
    local mockGame = {}
    function mockGame:GetService(name)
        return assert(({Players = players, ReplicatedStorage = rep, RunService = {Heartbeat = heartbeat}})[name])
    end
    local service = luau.load(serviceRaw, {environment = {game = mockGame,
        workspace = {GetServerTimeNow = function() return now end}, require = function(value) return value end,
        print = function() end, warn = function(message) error(message) end, Vector3 = V, CFrame = C}})()
    service.Init({Services = services}); service.Start()
    local result = {player = player, root = root, humanoid = humanoid, attrs = charAttrs}
    function result:checkpoints(count)
        for index = 1, count do checkpoints[index].part.Touched:Fire(root) end
    end
    function result:step(point, dt)
        root.Position = config.Origin + point
        heartbeat:Fire(dt or 1/60)
    end
    function result:count() return finishes end
    function result:status() return status end
    function result:checkpointIndex() return service.GetLatestCheckpointIndex(player) end
    function result:set(key, value)
        if key == "active" then active = value elseif key == "official" then official = value
        elseif key == "status" then status = value elseif key == "raceId" then raceId = value
        elseif key == "elapsed" then elapsed = value elseif key == "now" then now = value end
    end
    function result:outOfOrder() checkpoints[4].part.Touched:Fire(root) end
    return result
end
local serviceTests = {}
local function test(name, body)
    body()
    table.insert(serviceTests, {name = name, pass = true})
end
for _, data in {current, proposed} do
    local label = if data == current then "current" else "proposed"
    test(label .. "_air_cross_then_landing_then_restep", function()
        local h = harness(data); h:checkpoints(4)
        h:step(V.new(-4.8,159.5,-30)); h:step(V.new(-5.1,159.6,-30))
        local expected = if data == current then 0 else 1
        assert(h:count() == expected)
        h:step(V.new(-6,156.2,-30)); h:step(V.new(-6.1,155.8,-30)); h:step(V.new(-7,153.181,-30))
        assert(h:count() == expected, "Landing must not invent another forward crossing")
        if data == current then
            h:step(V.new(-6,153.181,-30)); h:step(V.new(-5.1,153.181,-30)); h:step(V.new(-4.8,153.181,-30))
            assert(h:count() == 0, "Backward re-entry must not finish")
            h:step(V.new(-5.1,153.181,-30)); assert(h:count() == 1)
        end
    end)
end
local negatives = {
    {name = "no_checkpoints", before = function() end, cp = 0},
    {name = "out_of_order_checkpoint", before = function(h) h:outOfOrder() end, cp = 0},
    {name = "missing_last_checkpoint", before = function(h) h:checkpoints(3) end, cp = 3},
    {name = "not_official", before = function(h) h:checkpoints(4); h:set("official", false) end},
    {name = "not_racing", before = function(h) h:checkpoints(4); h:set("status", "GhostRacing") end},
    {name = "race_inactive", before = function(h) h:checkpoints(4); h:set("active", false) end},
    {name = "dead_character", before = function(h) h:checkpoints(4); h.humanoid.Health = 0 end},
    {name = "recovery_immunity", before = function(h) h:checkpoints(4); h.attrs.RecoveryUntil = 102 end},
    {name = "result_refused", before = function(h) h:checkpoints(4) end, options = {recordRejected = true}},
}
for _, case in negatives do
    test("proposed_rejects_" .. case.name, function()
        local h = harness(proposed, case.options); case.before(h)
        h:step(V.new(-4.8,153.181,-30)); h:step(V.new(-5.1,153.181,-30))
        assert(h:count() == 0)
        if case.cp then assert(h:checkpointIndex() == case.cp) end
    end)
end
test("proposed_recovery_clear_does_not_reuse_immune_sample", function()
    local h = harness(proposed); h:checkpoints(4); h.attrs.RecoveryUntil = 102
    h:step(V.new(-4.8,153.181,-30)); h.attrs.RecoveryUntil = 0
    h:step(V.new(-5.1,153.181,-30)); assert(h:count() == 0)
end)
test("proposed_new_race_does_not_reuse_old_sample", function()
    local h = harness(proposed); h:checkpoints(4); h:step(V.new(-4.8,153.181,-30))
    h:set("raceId", "offline-2"); h:step(V.new(-5.1,153.181,-30)); assert(h:count() == 0)
end)
test("proposed_new_character_does_not_reuse_old_sample", function()
    local h = harness(proposed); h:checkpoints(4); h:step(V.new(-4.8,153.181,-30))
    h.player.Character = setmetatable({}, {__index = h.player.Character})
    h:step(V.new(-5.1,153.181,-30)); assert(h:count() == 0)
end)
test("proposed_duplicate_finish_is_idempotent", function()
    local h = harness(proposed); h:checkpoints(4)
    h:step(V.new(-4.8,153.181,-30)); h:step(V.new(-5.1,153.181,-30))
    h:step(V.new(-4.8,153.181,-30)); h:step(V.new(-5.1,153.181,-30)); assert(h:count() == 1)
end)
local naturalApproaches = {}
local lastFloor
for _, floor in layout.Surfaces do
    if floor.group == "CrownApproach" and floor.name == "Causeway_3_2" then lastFloor = floor end
end
assert(lastFloor and (lastFloor.position - V.new(18.7705078,148.666687,-42.429199)).Magnitude < .001,
    "Current source last stone must match the lead's fresh native geometry")
local westLocal = lastFloor.frame:VectorToObjectSpace(-V.xAxis)
local takeoffRun = math.min((lastFloor.size.X/2-1.05)/math.abs(westLocal.X), (lastFloor.size.Z/2-1.05)/math.abs(westLocal.Z))
local lastStoneTakeoff = lastFloor.position - V.xAxis * takeoffRun
local jumpVelocity = math.sqrt(2*config.Gravity*config.Movement.JumpHeight)
local function approach(name, launch, duration, destinationFloor)
    local rise = destinationFloor - launch.Y
    local landAt = (jumpVelocity + math.sqrt(jumpVelocity*jumpVelocity-2*config.Gravity*rise))/config.Gravity
    local crossesAt = (launch.X-layout.FinishGate.point.X)/config.Movement.WalkSpeed
    local crossingFootY = if crossesAt <= landAt then launch.Y+jumpVelocity*crossesAt-config.Gravity*crossesAt*crossesAt/2 else destinationFloor
    local oldCount, newCount
    for _, data in {current, proposed} do
        local h = harness(data); h:checkpoints(4)
        local time = 0
        while time <= duration do
            local footY = if time <= landAt then launch.Y+jumpVelocity*time-config.Gravity*time*time/2 else destinationFloor
            h:step(V.new(launch.X-config.Movement.WalkSpeed*time,footY+3.181,launch.Z))
            time += 1/60
        end
        if data == current then oldCount = h:count() else newCount = h:count() end
    end
    assert(oldCount == 0 and newCount == 1, name .. " must reproduce the old miss and proposed finish")
    table.insert(naturalApproaches, {name = name, takeoff = xyz(launch), speed = config.Movement.WalkSpeed,
        gravity = config.Gravity, jumpHeight = config.Movement.JumpHeight, standingRootAboveFloor = 3.181,
        ballisticLandingTime = landAt, ballisticLandingFoot = {launch.X-config.Movement.WalkSpeed*landAt,destinationFloor,launch.Z},
        planeCrossingTime = crossesAt, rootAtPlane = {layout.FinishGate.point.X,crossingFootY+3.181,launch.Z},
        currentFinishCount = oldCount, proposedFinishCount = newCount, syntheticBallisticSourceGeometry = true})
end
approach("straight_west_last_stone_then_inward_walk", lastStoneTakeoff, 1.5, 150)
approach("ordinary_hop_across_finish_on_terrace", V.new(-2,150,-30), .8, 150)
local floors, crownNodes = {}, {}
for _, floor in layout.Surfaces do floors["Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact"] = floor end
for _, node in layout.GetRoute({false,false,false}, {1,2}) do
    if node.path:find("/Crown", 1, true) then
        local floor = floors[node.path]
        local point = (floor.frame or C.new(floor.position)):PointToWorldSpace(node.offset or V.zero)
        table.insert(crownNodes, {path = node.path, kind = node.kind, point = xyz(point)})
    end
end
local finishTransfer
for _, transfer in layout.Transfers do
    if transfer.to == "Obstacles/Crown/CrownTerrace/Contact" then
        finishTransfer = {from = transfer.from, to = transfer.to, takeoff = xyz(transfer.fromPoint),
            arrival = xyz(transfer.toPoint), gap = transfer.gapStuds, rise = transfer.riseStuds}
    end
end
local report = {pass = true, evidence = "Offline exact source modules with synthetic positions and service dependencies; no native physics or owner-path reproduction",
    productionChanged = false, inputs = inputs,
    current = {point = xyz(current.point), size = xyz(current.size), center = xyz(current.frame.Position - config.Origin),
        look = xyz(current.frame.LookVector), height = {150,156}, widthWorldZ = {-41,-19}},
    proposed = {point = xyz(proposed.point), size = xyz(proposed.size), center = xyz(proposed.frame.Position - config.Origin),
        look = xyz(proposed.frame.LookVector), height = {150,162}, widthWorldZ = {-44,-16}},
    crownFloor = {position = xyz(floors["Obstacles/Crown/CrownTerrace/Contact"].position), size = xyz(floors["Obstacles/Crown/CrownTerrace/Contact"].size)},
    ordinaryJump = {jumpHeight = config.Movement.JumpHeight, speed = config.Movement.WalkSpeed,
        standingRootAboveFloor = 3.181, maximumRootY = 150+3.181+config.Movement.JumpHeight,
        exampleTime = .18, exampleRootY = 153.181 + math.sqrt(2*config.Gravity*config.Movement.JumpHeight)*.18-config.Gravity*.18*.18/2},
    directGateCases = direct, actualServiceCases = serviceTests, syntheticBallisticApproaches = naturalApproaches,
    nativeGeometryBinding = {source = "Lead read-only native inspection reported October19; source positions independently matched within.001",
        sourceRevision = 54, buildRevision = 48, finishCenter = {-5,153,-30}, finishSize = {22,6,24}, crownContactCenter = {-8,149,-30},
        crownContactSize = {36,2,28}, lastCausewayContactCenter = {18.7705078,148.166687,-42.429199}},
    finalTransfer = finishTransfer, crownRouteTail = crownNodes,
    liveConfirmationRequired = {"Capture actual Finish CFrame/Size and crown floor", "Record natural HRP crossing position, checkpoint4, active race/official status, alive character and RecoveryUntil", "Test ordinary last jump then supported inward walk, optional hop across plane, both supported side lanes and backward rejection"}}
if fs.isFile(own .. "Layout.proposed.luau") then
    local draft = load(own .. "Layout.proposed.luau", {script = {Parent = parent}, game = gameLayout})
    local function compare(a,b,path)
        assert(type(a)==type(b), "Draft type changed: " .. path)
        if type(a)=="function" then return end
        if type(a)=="table" then
            for key,value in a do compare(value,b[key],path.."/"..tostring(key)) end
            for key in b do assert(a[key]~=nil, "Unexpected draft key: "..path.."/"..tostring(key)) end
        else assert(a==b, "Unexpected draft change: "..path) end
    end
    for key,value in layout do if key~="FinishGate" then compare(value,draft[key],key) end end
    assert(draft.FinishGate.point==layout.FinishGate.point and draft.FinishGate.yaw==layout.FinishGate.yaw
        and draft.FinishGate.size==proposed.size, "Only the proposed gate Size may change")
    local compiled=luau.compile(source(own .. "FinishProbe.luau"))
    report.proposedDraftCheck={pass=true,allOtherLayoutDataExact=true,surfaces=#draft.Surfaces,
        probeSyntaxPass=type(compiled)=="string",nativeProbeExecuted=false}
end
fs.writeFile(own .. "finish-diagnostic.json", serde.encode("json", report, true) .. "\n")
print(serde.encode("json", {pass = true, directCases = #direct, actualServiceCases = #serviceTests,
    currentGate = report.current, proposedGate = report.proposed, finalTransfer = finishTransfer,
    report = own .. "finish-diagnostic.json"}))
