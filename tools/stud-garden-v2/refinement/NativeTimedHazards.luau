local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
assert(RunService:IsClient() and RunService:IsRunning())
local player=Players.LocalPlayer
local state=assert(player.PlayerGui:FindFirstChild("SGV2R01TestState"))
assert(state:GetAttribute("SGV2TestOwned") and not state:GetAttribute("Running"))
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_Refinement_R01")
local character=player.Character
local humanoid=character.Humanoid
local root=character.HumanoidRootPart
local origin=course:GetPivot().Position
local height=humanoid.HipHeight+root.Size.Y/2
local direction=Vector3.zero
local report={candidate="SGV2_Refinement_R01",scope="Setup teleport to refuge, then ordinary Humanoid movement through an actual clear phase; separate deliberate active contact",hazards={}}
local function localPosition()
    local p=root.Position-origin
    return {p.X,p.Y,p.Z}
end
local function place(p)
    character:PivotTo(CFrame.new(origin+p+Vector3.new(0,height+.08,0)))
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
end
local function save() state:SetAttribute("TimedResults",Http:JSONEncode(report)) end
local function waitFor(predicate,timeout)
    local started=os.clock()
    repeat RunService.Heartbeat:Wait() until predicate() or os.clock()-started>timeout
    assert(predicate(),"Timed out waiting for real hazard phase")
end
state:SetAttribute("Running",true)
state:SetAttribute("Job","timedHazards")
RunService:BindToRenderStep("SGV2R01Movement",Enum.RenderPriority.Input.Value+1,function()humanoid:Move(direction,false)end)
task.spawn(function()
    local ok,err=xpcall(function()
        for _,row in {
            {name="H1_Sprinkler",wait=Vector3.new(-56,7.24,-52),exit=Vector3.new(-56,7.24,-94)},
            {name="H2_Fruit",wait=Vector3.new(83,8.24,-141),exit=Vector3.new(125,8.24,-141)},
        } do
            local hazard=course[row.name]
            local result={name=row.name,phases={}}
            table.insert(report.hazards,result)
            place(row.wait)
            task.wait(.7)
            local recoveryBefore=character:GetAttribute("RecoveryUntil") or 0
            local last
            local connection=RunService.Heartbeat:Connect(function()
                local phase=hazard:GetAttribute("Phase")
                if phase~=last then
                    last=phase
                    table.insert(result.phases,{phase=phase,entryOpen=hazard:GetAttribute("EntryOpen"),at=os.clock()})
                end
            end)
            waitFor(function()return hazard:GetAttribute("Phase")=="Active"end,16)
            waitFor(function()return hazard:GetAttribute("Phase")=="Clear" and hazard:GetAttribute("EntryOpen")==true end,8)
            result.safeWait=(character:GetAttribute("RecoveryUntil") or 0)==recoveryBefore
            assert(result.safeWait,"Refuge contact caused recovery")
            result.crossStart=localPosition()
            result.clearRemaining=hazard:GetAttribute("ClearRemaining")
            local target=origin+row.exit
            local started=os.clock()
            repeat
                local delta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
                direction=if delta.Magnitude>.35 then delta.Unit else Vector3.zero
                RunService.Heartbeat:Wait()
            until (Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)).Magnitude<.7 or os.clock()-started>5 or (character:GetAttribute("RecoveryUntil") or 0)>recoveryBefore
            direction=Vector3.zero
            task.wait(.25)
            result.crossSeconds=os.clock()-started
            result.crossEnd=localPosition()
            result.crossPassed=(Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)).Magnitude<1.4 and (character:GetAttribute("RecoveryUntil") or 0)==recoveryBefore and humanoid.FloorMaterial~=Enum.Material.Air
            assert(result.crossPassed,"Clear-phase crossing failed: "..row.name)
            waitFor(function()return hazard:GetAttribute("Phase")=="Active" and (hazard:GetAttribute("PhaseAlpha") or 1)<.15 end,16)
            local hit=hazard:GetPivot().Position
            local foot=Vector3.new(hit.X-origin.X,if row.name=="H1_Sprinkler" then 7.4 else 8.4,hit.Z-origin.Z)
            place(foot)
            local prior=character:GetAttribute("RecoveryUntil") or 0
            local contactStarted=os.clock()
            repeat RunService.Heartbeat:Wait() until (character:GetAttribute("RecoveryUntil") or 0)>prior or os.clock()-contactStarted>2.8
            result.activeRecovery=(character:GetAttribute("RecoveryUntil") or 0)>prior
            result.contactSeconds=os.clock()-contactStarted
            result.afterRecovery=localPosition()
            connection:Disconnect()
            save()
            assert(result.activeRecovery,"No recovery on active contact: "..row.name)
            task.wait(1.7)
        end
    end,debug.traceback)
    RunService:UnbindFromRenderStep("SGV2R01Movement")
    humanoid:Move(Vector3.zero)
    report.ok=ok
    if not ok then report.error=tostring(err)end
    save()
    state:SetAttribute("Running",false)
end)
return {started=true}
