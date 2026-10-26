--!strict
local RunService=game:GetService("RunService")
local Service={}
local services: any
local started=false
function Service.Init(context) services=context.Services end
function Service.Start()
    if started then return end
    started=true
    local bound,controller,epoch=nil,nil,0
    local wasActive=false
    RunService.Heartbeat:Connect(function(dt)
        local course=services.CourseService.GetActiveCourse()
        if course~=bound then
            if controller then controller.Stop() end
            controller=nil;bound=course
            if course and course:GetAttribute("ShipwreckBuild") then
                controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(course,
                    services.RespawnService.RecoverPlayer,function(player)
                        return services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player)
                            and services.PlayerRaceService.GetPlayerStatus(player)=="Racing"
                    end)
                epoch=workspace:GetServerTimeNow()
                controller.Step(0,0,false)
            end
        end
        local active=services.RaceService.IsRaceActive()
        if controller then
            if active and not wasActive then epoch=workspace:GetServerTimeNow();controller.Reset() end
            if active then controller.Step(workspace:GetServerTimeNow()-epoch,dt,true) end
        end
        wasActive=active
    end)
end
return Service
