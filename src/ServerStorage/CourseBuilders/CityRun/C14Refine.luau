--!strict
local Refine = {}
function Refine.Apply()
    assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
    local course=workspace.Course_CityRun
    assert(course:GetAttribute("ReviewBuildId")=="C14_01")
    local source=script.Parent.C14Manifest:Clone()
    local data=require(source)
    source:Destroy()
    assert(data.revision=="C14_02")
    local count=0
    for name,definition in data.components do
        if definition.section=="CheckerExit" and definition.role=="Hazard" then
            local part=course.Obstacles.C14Routes.CheckerExit[name]:FindFirstChildWhichIsA("MeshPart")
            local pos,size=definition.position,definition.size
            part.CFrame=CFrame.new(pos[1],pos[2],pos[3])
            part.Size=Vector3.new(size[1],size[2],size[3])
            part.Parent.WorldPivot=part.CFrame
            count+=1
        end
    end
    assert(count==15)
    course:SetAttribute("ReviewBuildId",data.revision)
    return {build=data.revision,checkerTraps=count}
end
return Refine
