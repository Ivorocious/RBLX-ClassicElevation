local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
assert(RunService:IsClient() and RunService:IsRunning())
local player=Players.LocalPlayer
local state=assert(player.PlayerGui:FindFirstChild("SGV2F01TestState"))
assert(state:GetAttribute("SGV2TestOwned") and not state:GetAttribute("Running"))
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_FinalPass_F01")
local character=player.Character
local humanoid=character.Humanoid
local root=character.HumanoidRootPart
local origin=course:GetPivot().Position
local height=humanoid.HipHeight+root.Size.Y/2
local direction=Vector3.zero
local report={candidate="SGV2_FinalPass_F01",scope="Real player crossings at first GO and last GO; declared setup teleports; full-cycle refuge wait and separate deliberate contact",hazards={}}
local function position()local p=root.Position-origin;return {p.X,p.Y,p.Z}end
local function place(v)
    humanoid:Move(Vector3.zero);character:PivotTo(CFrame.new(origin+v+Vector3.new(0,height+.12,0)))
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
end
local function save()state:SetAttribute("TimedResults",Http:JSONEncode(report))end
local function waitFor(predicate,timeout)
    local started=os.clock()
    repeat RunService.Heartbeat:Wait() until predicate() or os.clock()-started>timeout
    assert(predicate(),"Timed out waiting for phase")
end
state:SetAttribute("Running",true)
state:SetAttribute("Job","timed-crossings")
RunService:BindToRenderStep("SGV2F01Movement",Enum.RenderPriority.Input.Value+1,function()humanoid:Move(direction,false)end)
task.spawn(function()
    local ok,err=xpcall(function()
        assert(humanoid.WalkSpeed==16 and math.abs(humanoid.JumpHeight-7.2)<.001 and not humanoid.UseJumpPower)
        for _,row in {
            {name="H1_Sprinkler",checkpoint=2,wait=Vector3.new(-56,7.24,-52),exit=Vector3.new(-56,7.24,-94)},
            {name="H2_Fruit",checkpoint=5,wait=Vector3.new(83,8.24,-141),exit=Vector3.new(125,8.24,-141)},
        } do
            local h=course[row.name]
            local result={name=row.name,crossings={},phases={}}
            table.insert(report.hazards,result)
            local response=game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=row.checkpoint})
            assert(response.ok);task.wait(.5);place(row.wait);task.wait(.7)
            local before=character:GetAttribute("RecoveryUntil") or 0
            local seen={}
            local duration=h:GetAttribute("ClearSeconds")+h:GetAttribute("WarningSeconds")+h:GetAttribute("ActiveSeconds")+.3
            local started=os.clock()
            repeat
                RunService.Heartbeat:Wait()
                local phase=h:GetAttribute("Phase")
                if phase and not seen[phase] then
                    seen[phase]=true
                    local text=h.StatusBoard:FindFirstChildWhichIsA("TextLabel",true)
                    table.insert(result.phases,{phase=phase,entryOpen=h:GetAttribute("EntryOpen"),text=text and text.Text})
                end
            until os.clock()-started>=duration
            result.safeWait=(character:GetAttribute("RecoveryUntil") or 0)==before
            assert(result.safeWait and seen.Clear and seen.Warning and seen.Active,"Full-cycle refuge wait failed")
            for _,mode in {"firstGO","lastGO"} do
                place(row.wait);task.wait(.5)
                waitFor(function()return h:GetAttribute("Phase")=="Active"end,15)
                waitFor(function()return h:GetAttribute("EntryOpen")==true end,8)
                if mode=="lastGO" then waitFor(function()return (h:GetAttribute("ClearRemaining") or 999)<=h:GetAttribute("MinimumEntrySeconds")+.14 end,8) end
                assert(h:GetAttribute("EntryOpen")==true,"Entry closed before launch")
                local cross={mode=mode,clearRemaining=h:GetAttribute("ClearRemaining"),before=position()}
                table.insert(result.crossings,cross)
                local recovery=character:GetAttribute("RecoveryUntil") or 0
                local target=origin+row.exit
                local begin=os.clock()
                repeat
                    local delta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
                    direction=if delta.Magnitude>.35 then delta.Unit else Vector3.zero
                    RunService.Heartbeat:Wait()
                until (Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)).Magnitude<.7 or os.clock()-begin>5 or (character:GetAttribute("RecoveryUntil") or 0)>recovery
                direction=Vector3.zero;task.wait(.15)
                cross.seconds=os.clock()-begin;cross.after=position()
                cross.passed=(Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)).Magnitude<1.4 and (character:GetAttribute("RecoveryUntil") or 0)==recovery and humanoid.FloorMaterial~=Enum.Material.Air
                save();assert(cross.passed,"Crossing failed "..row.name.." "..mode)
            end
            task.wait(1.7)
            waitFor(function()return h:GetAttribute("Phase")=="Active" and (h:GetAttribute("PhaseAlpha") or 1)<.15 end,15)
            local p=h:GetPivot().Position-origin
            place(Vector3.new(p.X,if row.name=="H1_Sprinkler" then 7.4 else 8.4,p.Z))
            local prior=character:GetAttribute("RecoveryUntil") or 0
            local contactStart=os.clock()
            repeat RunService.Heartbeat:Wait() until (character:GetAttribute("RecoveryUntil") or 0)>prior or os.clock()-contactStart>3
            result.activeRecovery=(character:GetAttribute("RecoveryUntil") or 0)>prior
            result.contactSeconds=os.clock()-contactStart;result.afterRecovery=position()
            save();assert(result.activeRecovery,"Active contact did not recover")
            task.wait(1.7)
        end
    end,debug.traceback)
    RunService:UnbindFromRenderStep("SGV2F01Movement");humanoid:Move(Vector3.zero)
    report.ok=ok;if not ok then report.error=tostring(err)end
    save();state:SetAttribute("Running",false)
end)
return {started=true}
