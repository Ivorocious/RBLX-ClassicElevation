local fs, luau, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local path = "src/ServerScriptService/Services/StudioDevService.luau"
local source = fs.readFile(path)
for _, file in {path, "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau", "tools/keyboard-circuit/phase2/work-i06/CreateCompactEdit.luau"} do
    luau.load(fs.readFile(file), {debugName = file})
end
local function node(class, name)
    local item = {ClassName = class, Name = name, children = {}, attributes = {}}
    function item:IsA(wanted) return wanted == self.ClassName end
    function item:FindFirstChild(wanted) return self.children[wanted] end
    function item:FindFirstChildOfClass(wanted)
        for _, child in self.children do if child:IsA(wanted) then return child end end
    end
    function item:GetChildren() local list = {}; for _, child in self.children do table.insert(list, child) end; return list end
    function item:GetAttribute(wanted) return self.attributes[wanted] end
    return item
end
local function fixture(options)
    options = options or {}
    local now, holds, begins, leaves, lobbyReturns = 0, 0, {}, {}, 0
    local players = node("Players", "Players")
    local player = node("Player", "Tester")
    player.Parent, player.UserId, player.attributes.OnboardingReady = players, 42, options.ready ~= false
    local character = node("Model", "Character")
    character.children.Root = node("BasePart", "HumanoidRootPart")
    character.children.HumanoidRootPart, character.children.Root = character.children.Root, nil
    character.children.Humanoid = node("Humanoid", "Humanoid")
    character.children.Humanoid.Health = options.dead and 0 or 100
    character.children.HumanoidRootPart.Anchored = options.anchored == true
    player.Character = options.noCharacter and nil or character
    local workspace = node("Workspace", "Workspace")
    local course = node("Model", "KeyboardCircuit_P2_PacingI06_01")
    course.attributes = {Phase2Only = true, PrototypeRevision = options.wrongRevision and "OTHER" or "KC_P2_I06_COMPACT_01"}
    local controls = node("Folder", "StudioProbeControls")
    local begin = node("BindableEvent", "Begin")
    function begin:Fire(id)
        table.insert(begins, id)
        if not options.rejectBegin then player.attributes.KCPhase2Candidate = course.Name end
    end
    local state = node("BindableFunction", "State")
    function state:Invoke() return {active = options.stopped ~= true} end
    controls.children, course.children.StudioProbeControls = {Begin = begin, State = state}, controls
    local old = node("Model", "OriginalCourse")
    old.attributes.Phase2Only = true
    local leave = node("BindableEvent", "Leave")
    function leave:Fire(id) table.insert(leaves, id); player.attributes.KCPhase2Candidate = nil end
    local oldControls = node("Folder", "StudioProbeControls")
    oldControls.children.Leave, old.children.StudioProbeControls = leave, oldControls
    workspace.children.OriginalCourse = old
    if not options.missingCourse then workspace.children[course.Name] = course end
    local held, raceState = not options.runningRound, options.runningRound and "Racing" or "WaitingForPlayers"
    local race = {
        IsStudioHoldingLobby = function() return held end,
        GetRaceState = function() return raceState end,
        ApplyStudioAction = function(action) assert(action == "HoldLobby"); holds += 1; held = true end,
        IsInspectionUnlimitedTime = function() return false end,
    }
    local context = {Services = {
        RaceService = race,
        CourseService = {GetDiscoveredCourseIds = function() return {} end, GetOrderedCheckpoints = function() return {} end,
            GetSelectedCourseId = function() return "original" end, GetActiveCourse = function() return nil end},
        PlayerRaceService = {SetPlayerStatus = function(who, status) assert(who == player and status == "Lobby") end},
        StagingService = {ReturnPlayersToLobby = function(list) assert(list[1] == player); lobbyReturns += 1 end},
    }}
    local environment = {
        workspace = workspace,
        game = {GetService = function(_, name)
            if name == "Players" then return players end
            if name == "RunService" then return {IsStudio = function() return options.outsideStudio ~= true end} end
            return {}
        end},
        typeof = function(value) return if type(value) == "table" and value.ClassName then "Instance" else type(value) end,
        os = {clock = function() return now end},
        task = {wait = function(seconds)
            now += seconds or .05
            if holds > 0 and not options.stuckRound then raceState = "WaitingForPlayers" end
        end},
    }
    local service = luau.load(source, {environment = environment})()
    service.Init(context)
    return {service = service, player = player, begins = begins, leaves = leaves,
        advance = function() now += 1 end, holds = function() return holds end, lobbyReturns = function() return lobbyReturns end}
end
local cases = {}
for _, case in {
    {name = "Avatar setup required", options = {ready = false}},
    {name = "Missing course rejected", options = {missingCourse = true}},
    {name = "Wrong revision rejected", options = {wrongRevision = true}},
    {name = "Stopped session rejected", options = {stopped = true}},
    {name = "Anchored character rejected", options = {anchored = true}},
    {name = "Dead character rejected", options = {dead = true}},
    {name = "Published game rejected", options = {outsideStudio = true}},
    {name = "Unsettled round rejected", options = {runningRound = true, stuckRound = true}},
} do
    local f = fixture(case.options)
    assert(f.service.HandleRequest(f.player, {action = "KeyboardCircuitTest"}).ok == false, case.name)
    assert(#f.begins == 0, case.name .. " enrolled a player")
    table.insert(cases, case.name)
end
local f = fixture({runningRound = true})
assert(f.service.HandleRequest(f.player, {action = "KeyboardCircuitTest", userId = 999, courseId = "other"}).ok)
assert(f.holds() == 1 and f.begins[1] == 42 and f.leaves[1] == 42)
table.insert(cases, "Round settles and only invoking player enters fixed prototype")
local duplicate = fixture()
assert(duplicate.service.HandleRequest(duplicate.player, {action = "KeyboardCircuitTest"}).ok)
assert(duplicate.service.HandleRequest(duplicate.player, {action = "KeyboardCircuitTest"}).ok == false)
table.insert(cases, "Rapid duplicate request rejected")
f.advance()
assert(f.service.HandleRequest(f.player, {action = "Teleport", destination = "Lobby"}).ok)
assert(f.player:GetAttribute("KCPhase2Candidate") == nil and f.lobbyReturns() == 1 and #f.leaves == 2)
table.insert(cases, "Lobby detaches session before returning player")
local rejected = fixture({rejectBegin = true})
assert(rejected.service.HandleRequest(rejected.player, {action = "KeyboardCircuitTest"}).ok == false)
table.insert(cases, "Failed enrollment is reported")
local report = {compiled = 3, cases = cases, status = "passed", boundary = "Mocked Dev Tools routing and guards; owner Play button and native enrollment remain to be tested."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/P2-C01-dev-control-checks-13.json", serde.encode("json", report, true))
print(serde.encode("json", report))
