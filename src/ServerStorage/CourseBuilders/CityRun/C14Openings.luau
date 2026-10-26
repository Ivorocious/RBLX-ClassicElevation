--!strict
local Refine={}
function Refine.Apply()
    assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
    local course=workspace.Course_CityRun
    assert(course:GetAttribute("ReviewBuildId")=="C14_04")
    local source=script.Parent.C14Manifest:Clone()
    local data=require(source)
    source:Destroy()
    assert(data.revision=="C14_05")
    local changed=0
    for name,d in data.components do
        if d.role=="Hazard" and (d.section=="DistrictWeaves" or d.section=="DepotSlalom") then
            local unit=course.Obstacles.C14Routes[d.section][name]
            local p=unit:FindFirstChildWhichIsA("MeshPart")
            p.CFrame=CFrame.new(unpack(d.position))
            p.Size=Vector3.new(unpack(d.size))
            for key,value in d.attrs do p:SetAttribute(key,value) end
            if d.attrs.WorldMotionAxis then p:SetAttribute("MotionAxis",d.attrs.WorldMotionAxis) end
            unit.WorldPivot=p.CFrame
            changed+=1
        end
    end
    course:SetAttribute("ReviewBuildId",data.revision)
    return {build=data.revision,widenedGates=changed,peakSlidingOpening=7.0}
end
return Refine
