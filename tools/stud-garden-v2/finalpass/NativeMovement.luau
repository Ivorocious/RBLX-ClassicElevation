local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
assert(RunService:IsClient() and RunService:IsRunning())
local player=Players.LocalPlayer
local state=assert(player.PlayerGui:FindFirstChild("SGV2F01TestState"))
assert(state:GetAttribute("SGV2TestOwned") and not state:GetAttribute("Running"))
local job=Http:JSONDecode(assert(state:GetAttribute("MovementJob")))
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_FinalPass_F01")
local character=player.Character
local humanoid=character.Humanoid
local root=character.HumanoidRootPart
local height=humanoid.HipHeight+root.Size.Y/2
local origin=course:GetPivot().Position
local direction=Vector3.zero
local jumpRequested=false
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={course}
params.RespectCanCollide=true
local report={id=job.id,candidate=course:GetAttribute("CandidateId"),method="Real client Humanoid Move/Jump, unchanged movement settings; setup teleport only before each declared case",steps={}}
local function point(v)return Vector3.new(v[1],v[2],v[3])end
local function relative()
    local p=root.Position-origin-Vector3.new(0,height,0)
    return {p.X,p.Y,p.Z}
end
local function ground()
    local hit=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),params)
    if not hit or math.abs(hit.Distance-height)>=.95 then
        for _,offset in {Vector3.new(.55,0,0),Vector3.new(-.55,0,0),Vector3.new(0,0,.55),Vector3.new(0,0,-.55)} do
            local probe=workspace:Raycast(root.Position+offset,Vector3.new(0,-height-1,0),params)
            if probe and math.abs(probe.Distance-height)<.95 then hit=probe;break end
        end
    end
    local stable=hit and math.abs(hit.Distance-height)<.95 and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<3
    return stable,hit and hit.Instance:GetFullName(),hit and hit.Position
end
local function save()state:SetAttribute("MovementResults",Http:JSONEncode(report))end
state:SetAttribute("Running",true)
state:SetAttribute("Job",job.id)
RunService:BindToRenderStep("SGV2F01Movement",Enum.RenderPriority.Input.Value+1,function()
    humanoid:Move(direction,false)
    humanoid.Jump=jumpRequested
end)
task.spawn(function()
    local started=os.clock()
    local ok,err=xpcall(function()
        assert(humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.001,"Movement settings changed")
        if job.from then
            character:PivotTo(CFrame.new(origin+point(job.from)+Vector3.new(0,height+.12,0)))
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            task.wait(.8)
        end
        local grounded,support=ground()
        report.start=relative()
        report.startSupport=support
        assert(grounded,"Initial position lacks honest support")
        if job.startExpected then
            local actual=point(report.start)
            local expected=point(job.startExpected)
            assert((Vector3.new(actual.X,0,actual.Z)-Vector3.new(expected.X,0,expected.Z)).Magnitude<1.5 and math.abs(actual.Y-expected.Y)<1.5,"SETUP: avatar did not remain at declared start")
        end
        local recovery=character:GetAttribute("RecoveryUntil") or 0
        if job.gate then
            local bar=course.ClosingRoute[job.gate].RedThornCrossbar
            local previousX=bar.Position.X-origin.X
            local began=os.clock()
            local ready=false
            repeat
                RunService.Heartbeat:Wait()
                local x=bar.Position.X-origin.X
                ready=if job.gate=="G1_SeedBenchThorns" then x< -91.8 and x> -92.4 and x<previousX else math.abs(bar.CFrame.RightVector.Z)>.995
                previousX=x
            until ready or os.clock()-began>14
            assert(ready,"Moving-bar launch window unavailable")
            report.launchWait=os.clock()-began
        end
        for index,step in job.steps do
            local target=origin+point(step.to)
            local stepReport={index=index,action=step.action,target=step.to,before=relative(),trace={}}
            table.insert(report.steps,stepReport)
            local start=os.clock()
            local jumped=false
            local airborne=false
            local success=false
            local peak=root.Position.Y-height-origin.Y
            local lastSample=-1
            local settleAt
            while os.clock()-start<(step.timeout or 6) do
                local delta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
                local distance=delta.Magnitude
                direction=if distance>(step.tolerance or .42) then delta.Unit*math.min(1,distance/1.5) else Vector3.zero
                if step.action=="jump" and not jumped then
                    jumpRequested=true
                    jumped=true
                end
                RunService.Heartbeat:Wait()
                local elapsed=os.clock()-start
                peak=math.max(peak,root.Position.Y-height-origin.Y)
                if humanoid.FloorMaterial==Enum.Material.Air then airborne=true;jumpRequested=false end
                if elapsed>.18 then jumpRequested=false end
                local landed,path,hit=ground()
                if elapsed-lastSample>=.08 and #stepReport.trace<80 then
                    table.insert(stepReport.trace,{t=elapsed,p=relative(),state=humanoid:GetState().Name,floor=humanoid.FloorMaterial.Name})
                    lastSample=elapsed
                end
                assert((character:GetAttribute("RecoveryUntil") or 0)==recovery,"Server recovery during step "..index)
                local horizontal=(Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)).Magnitude
                local correctSupport=not step.expectedSupportMembers
                if step.expectedSupportMembers and path then
                    for _,member in step.expectedSupportMembers do
                        if path:sub(-#member)==member then correctSupport=true;break end
                    end
                end
                if step.expectedSupportModel and path then
                    correctSupport=path:find("."..step.expectedSupportModel..".",1,true)~=nil
                end
                local vertical=math.abs(root.Position.Y-height-target.Y)
                local velocity=root.AssemblyLinearVelocity
                local settledHorizontal=Vector3.new(velocity.X,0,velocity.Z).Magnitude<2
                if horizontal<(step.arrival or .85) and vertical<1.2 and correctSupport and landed and settledHorizontal and (step.action~="jump" or airborne) then
                    if not settleAt then settleAt=elapsed end
                    if elapsed-settleAt>=.10 then
                        stepReport.support=path
                        stepReport.supportPoint=hit and {hit.X-origin.X,hit.Y-origin.Y,hit.Z-origin.Z}
                        success=true
                        break
                    end
                else settleAt=nil end
                assert(root.Position.Y>target.Y-12,"Fell below landing")
            end
            direction=Vector3.zero
            jumpRequested=false
            stepReport.after=relative()
            stepReport.elapsed=os.clock()-start
            stepReport.peakFootY=peak
            stepReport.airborne=airborne
            stepReport.passed=success
            if success then stepReport.trace=nil end
            save()
            assert(success,"Did not reach supported target at step "..index)
        end
    end,debug.traceback)
    RunService:UnbindFromRenderStep("SGV2F01Movement")
    humanoid:Move(Vector3.zero)
    report.ok=ok
    report.elapsed=os.clock()-started
    report.after=relative()
    if not ok then report.error=tostring(err)end
    save()
    state:SetAttribute("Running",false)
end)
return {started=true,id=job.id}
