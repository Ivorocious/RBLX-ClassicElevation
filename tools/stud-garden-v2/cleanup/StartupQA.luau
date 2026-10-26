local services=game.ServerScriptService.Services
local courses=require(services.CourseService)
local race=require(services.RaceService)
local garden=require(services.StudGardenService)
local seen={sprinkler={},fruit={}}
local started=os.clock()
local lastDiagnostics,course,parts,kills
local function complete()
    for _,hazard in seen do
        for _,phase in {"Clear","Warning","Active"} do
            if not hazard[phase] then return false end
        end
    end
    return lastDiagnostics~=nil
end
repeat
    local active=courses.GetActiveCourse()
    if active and active:GetAttribute("CourseId")=="stud_garden_v2" and race.IsRaceActive() then
        if active~=course then
            course=active;parts=0;kills=0
            for _,part in course:GetDescendants() do
                if part:IsA("BasePart") then
                    parts+=1
                    if part:GetAttribute("HazardType")=="Kill" then kills+=1 end
                end
            end
            assert(parts==8015 and kills==16)
            assert(course:FindFirstChild("OwnerScenery"))
            assert(#courses.GetOrderedCheckpoints()==9)
        end
        seen.sprinkler[tostring(course.H1_Sprinkler:GetAttribute("Phase"))]=true
        seen.fruit[tostring(course.H2_Fruit:GetAttribute("Phase"))]=true
        local diagnostics=garden.GetDiagnostics()
        if diagnostics.sprinkler and diagnostics.fruit then lastDiagnostics=diagnostics end
    end
    if complete() then break end
    task.wait(.05)
until os.clock()-started>=35
assert(complete(),"Timed hazards did not complete the observed startup cycle")
assert(lastDiagnostics.sprinkler.steps>0 and lastDiagnostics.fruit.steps>0)
for _,name in {"StudGardenV2Assets_M01","StudGardenV2Assets_M02","SGV2OwnerAvatarSource","SGV2_R02_Recovery_20261006"} do
    assert(not game.ServerStorage:FindFirstChild(name))
end
assert(not game.ServerStorage.CourseBuilders:FindFirstChild("StudGarden"))
assert(not workspace:FindFirstChild("ForkRosemaryClump") and not workspace:FindFirstChild("Earth") and not workspace:FindFirstChild("GrassCap"))
return game.HttpService:JSONEncode({
    ok=true,parts=parts,killBars=kills,checkpoints=9,observedPhases=seen,
    diagnostics=lastDiagnostics,seconds=os.clock()-started,
    ownerSceneryIncluded=true,obsoleteStorageAbsent=true,
    scope="Actual Studio map selection and live hazard cycle; diagnostics sampled while the round is active"
})
