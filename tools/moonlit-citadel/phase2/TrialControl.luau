--!nonstrict
local HttpService = game:GetService('HttpService')
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Layout = require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Layout)
local Control = {}

function Control.Services()
    assert(game:GetService('RunService'):IsStudio() and game.PlaceId == 0 and game.GameId == 0, 'Owned native fixture only')
    local services = {}
    for _, name in {'CourseService','RaceService','PlayerRaceService','CheckpointService','ResultsService','RespawnService','StagingService','OnboardingService','MoonlitCitadelService'} do
        services[name] = require(game.ServerScriptService.Services[name])
    end
    return services
end

local function serialize(value)
    if typeof(value) == 'Vector3' then return {_t='v', value={value.X,value.Y,value.Z}} end
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, child in value do result[key] = serialize(child) end
    return result
end

function Control.PrepareRoutes()
    local tools = game.ReplicatedStorage.MoonlitPhase2Tools
    local trials = {
        {'NNN',{false,false,false},{1,1}}, {'NNE',{false,false,true},{2,2}},
        {'NEN',{false,true,false},{1,2}}, {'NEE',{false,true,true},{2,1}},
        {'ENN',{true,false,false},{2,2}}, {'ENE',{true,false,true},{1,1}},
        {'EEN',{true,true,false},{2,1}}, {'EEE',{true,true,true},{1,2}},
    }
    local report = {}
    for _, trial in trials do
        local nodes = Layout.GetRoute(trial[2], trial[3])
        local value = Instance.new('StringValue')
        value.Name = 'Routes_'..trial[1]
        assert(not tools:FindFirstChild(value.Name), 'Keep prior route payloads')
        value.Value = HttpService:JSONEncode(serialize({candidate=Config.CandidateId,choices=trial[2],bays=trial[3],nodes=nodes,
            catchArch=Layout.GetCatchRoute('Arch'),catchUpper=Layout.GetCatchRoute('Upper')}))
        value.Parent = tools
        table.insert(report, {name=trial[1], nodes=#nodes, bytes=#value.Value})
    end
    return report
end

function Control.Restart()
    local services = Control.Services()
    assert(services.CourseService.SelectCourseForStudio(Config.CourseId), 'Shared course selection rejected')
    assert(services.RaceService.ApplyStudioAction('RestartRace'), 'Shared restart rejected')
    return {raceId=services.RaceService.GetCurrentRaceId(),courseId=services.CourseService.GetActiveCourseId()}
end

function Control.SaveReport(name, report)
    assert(name:match('^MC_P2_[%w_]+$'), 'Scoped evidence name required')
    local parent = game.ServerStorage:FindFirstChild('MoonlitPhase2Evidence')
    if not parent then parent=Instance.new('Folder');parent.Name='MoonlitPhase2Evidence';parent.Parent=game.ServerStorage end
    assert(not parent:FindFirstChild(name), 'Preserve previous report')
    local folder=Instance.new('Folder');folder.Name=name;folder.Parent=parent
    local encoded=HttpService:JSONEncode(report)
    for offset=1,#encoded,140000 do
        local part=Instance.new('StringValue');part.Name=string.format('JSON_%03d',math.ceil(offset/140000));part.Value=encoded:sub(offset,offset+139999);part.Parent=folder
    end
    folder:SetAttribute('JSONBytes',#encoded)
    return folder:GetFullName()
end

return Control
