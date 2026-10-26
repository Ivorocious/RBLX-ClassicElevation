local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local RunService=game:GetService("RunService")
assert(RunService:IsClient() and RunService:IsRunning(),"Client Play test required")
local player=Players.LocalPlayer
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_Closing_C05")
local state=assert(player.PlayerGui:FindFirstChild("SGV2C05TestState"))
assert(state:GetAttribute("SGV2TestOwned") and not state:GetAttribute("Running"))
local character=assert(player.Character)
local humanoid=character:FindFirstChildOfClass("Humanoid")
local root=character:FindFirstChild("HumanoidRootPart")
local results={candidate=course:GetAttribute("CandidateId"),scope="Setup teleports followed by actual engine contact and server recovery; not traversal proof",kill={},checkpoints={}}
local function position()
    local p=root.Position
    return {p.X,p.Y,p.Z}
end
local function place(frame)
    humanoid:Move(Vector3.zero)
    character:PivotTo(frame)
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
end
local function save()
    state:SetAttribute("ContactResults",Http:JSONEncode(results))
end
state:SetAttribute("Running",true)
state:SetAttribute("Job","contacts")
task.spawn(function()
    local ok,err=xpcall(function()
        local parts={}
        for _,p in course:GetDescendants() do
            if p:IsA("BasePart") and p:GetAttribute("HazardType")=="Kill" then table.insert(parts,p) end
        end
        table.sort(parts,function(a,b)return a:GetFullName()<b:GetFullName()end)
        for _,p in parts do
            task.wait(1.65)
            local before=character:GetAttribute("RecoveryUntil") or 0
            place(p.CFrame+Vector3.new(0,1.2,0))
            local started=os.clock()
            local recovered=false
            repeat
                RunService.Heartbeat:Wait()
                recovered=(character:GetAttribute("RecoveryUntil") or 0)>before
            until recovered or os.clock()-started>2
            task.wait(.12)
            table.insert(results.kill,{path=p:GetFullName(),recovered=recovered,seconds=os.clock()-started,after=position(),health=humanoid.Health})
            save()
            assert(recovered,"No recovery from "..p:GetFullName())
        end
        local checkpoints={}
        for _,p in course.Checkpoints:GetChildren() do if p:IsA("BasePart") then table.insert(checkpoints,p) end end
        table.sort(checkpoints,function(a,b)return a.Name<b.Name end)
        for _,p in checkpoints do
            place(p.CFrame+Vector3.new(0,6,0))
            task.wait(.9)
            local expected=p:GetAttribute("RespawnCFrame")
            local settled=position()
            task.wait(.8)
            local before=character:GetAttribute("RecoveryUntil") or 0
            place(parts[1].CFrame+Vector3.new(0,1.2,0))
            local started=os.clock()
            repeat RunService.Heartbeat:Wait() until (character:GetAttribute("RecoveryUntil") or 0)>before or os.clock()-started>2
            task.wait(.3)
            local relative=expected:PointToObjectSpace(root.Position)
            local area=p:GetAttribute("RespawnAreaSize")
            local within=math.abs(relative.X)<=area.X/2 and math.abs(relative.Z)<=area.Z/2 and math.abs(relative.Y)<6
            table.insert(results.checkpoints,{name=p.Name,settled=settled,recovered=(character:GetAttribute("RecoveryUntil") or 0)>before,withinAuthoredArea=within,relative={relative.X,relative.Y,relative.Z},after=position()})
            save()
            assert(within,"Recovery missed "..p.Name)
        end
        results.finished=true
    end,debug.traceback)
    humanoid:Move(Vector3.zero)
    results.ok=ok
    if not ok then results.error=tostring(err) end
    results.lastPosition=position()
    save()
    state:SetAttribute("Running",false)
end)
return {started=true,scope=results.scope}
