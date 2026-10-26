local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local player=game.Players.LocalPlayer
assert(RunService:IsClient() and RunService:IsRunning())
local state=assert(player.PlayerGui:FindFirstChild("SGV2R01TestState"))
assert(state:GetAttribute("SGV2TestOwned") and not state:GetAttribute("Running"))
local jobs=Http:JSONDecode(assert(state:GetAttribute("BarrierJobs")))
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_Refinement_R01")
local character=player.Character
local humanoid=character.Humanoid
local root=character.HumanoidRootPart
local height=humanoid.HipHeight+root.Size.Y/2
local origin=course:GetPivot().Position
local direction=Vector3.zero
local jumpRequested=false
local function v(a)return Vector3.new(a[1],a[2],a[3])end
local function array(p)return {p.X,p.Y,p.Z}end
local function foot()return root.Position-origin-Vector3.new(0,height,0)end
local function horizontal(p)return Vector3.new(p.X,0,p.Z)end
local groundParams=RaycastParams.new()
groundParams.FilterType=Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances={course}
groundParams.RespectCanCollide=true
local report={candidate=course:GetAttribute("CandidateId"),scope="One supported setup per case, then ordinary walk and repeated Jump input. Actual body contacts, nearby wall rays and trajectories are recorded separately; timeout alone is not a pass.",jobs={}}
state:SetAttribute("Running",true)
RunService:BindToRenderStep("SGV2R01Movement",Enum.RenderPriority.Input.Value+1,function()
    humanoid:Move(direction,false)
    humanoid.Jump=jumpRequested
end)
task.spawn(function()
    local ok,err=xpcall(function()
        assert(humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.001)
        for _,job in jobs do
            state:SetAttribute("Job",job.id)
            direction=Vector3.zero;jumpRequested=false
            character:PivotTo(CFrame.new(origin+v(job.from)+Vector3.new(0,height+.12,0)))
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
            task.wait(.9)
            local row={id=job.id,from=job.from,target=job.targetCandidate,wall=job.wallModel,claimScope=job.claimScope,trace={},touches={},nearWallRays={}}
            table.insert(report.jobs,row)
            local actual=foot()
            local hit=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),groundParams)
            row.start=array(actual)
            row.startSupport=hit and hit.Instance:GetFullName()
            row.setupPassed=humanoid.FloorMaterial~=Enum.Material.Air and (horizontal(actual-v(job.from))).Magnitude<1.5 and math.abs(actual.Y-job.from[2])<1.5
            if row.setupPassed then
                local target=origin+v(job.targetCandidate)
                local wall=assert(course.RefinedGardenBoundaries:FindFirstChild(job.wallModel))
                local wallParams=RaycastParams.new();wallParams.FilterType=Enum.RaycastFilterType.Include;wallParams.FilterDescendantsInstances={wall};wallParams.RespectCanCollide=true
                local recovery=character:GetAttribute("RecoveryUntil") or 0
                local seenTouches,seenRays={},{}
                local began=os.clock();local lastSample=-1;local lastJump=-1
                row.peakFootY=actual.Y;row.closestTarget=(horizontal(actual-v(job.targetCandidate))).Magnitude
                while os.clock()-began<3.2 do
                    local elapsed=os.clock()-began
                    local delta=horizontal(target-root.Position)
                    direction=if delta.Magnitude>.15 then delta.Unit else Vector3.zero
                    if humanoid.FloorMaterial~=Enum.Material.Air and elapsed-lastJump>.65 then lastJump=elapsed end
                    jumpRequested=elapsed-lastJump<.18 and humanoid.FloorMaterial~=Enum.Material.Air
                    RunService.Heartbeat:Wait()
                    actual=foot()
                    if humanoid.FloorMaterial==Enum.Material.Air then row.airborne=true end
                    row.peakFootY=math.max(row.peakFootY,actual.Y)
                    row.closestTarget=math.min(row.closestTarget,horizontal(actual-v(job.targetCandidate)).Magnitude)
                    for _,body in character:GetChildren() do
                        if body:IsA("BasePart") then
                            for _,part in body:GetTouchingParts() do
                                if part:IsDescendantOf(wall) then seenTouches[part:GetFullName()]=true end
                            end
                        end
                    end
                    if elapsed-lastSample>=.08 then
                        local near={}
                        for _,dy in {-1.4,0,1.4} do
                            local contact=workspace:Raycast(root.Position+Vector3.new(0,dy,0),direction*2.3,wallParams)
                            if contact then
                                seenRays[contact.Instance:GetFullName()]=true
                                table.insert(near,{path=contact.Instance.Name,distance=contact.Distance})
                            end
                        end
                        table.insert(row.trace,{t=elapsed,p=array(actual),velocity=array(root.AssemblyLinearVelocity),floor=humanoid.FloorMaterial.Name,nearWallRays=near})
                        lastSample=elapsed
                    end
                    local support=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),groundParams)
                    if support and humanoid.FloorMaterial~=Enum.Material.Air and horizontal(actual-v(job.targetCandidate)).Magnitude<.7 and math.abs(actual.Y-job.targetCandidate[2])<1.2 then
                        row.reachedTarget=true;row.targetSupport=support.Instance:GetFullName();break
                    end
                    if (character:GetAttribute("RecoveryUntil") or 0)>recovery then row.recovered=true;break end
                end
                for path in seenTouches do table.insert(row.touches,path) end
                for path in seenRays do table.insert(row.nearWallRays,path) end
                row.after=array(foot())
                row.elapsed=os.clock()-began
            end
            direction=Vector3.zero;jumpRequested=false
            state:SetAttribute("BarrierResults",Http:JSONEncode(report))
            task.wait(1.7)
        end
    end,debug.traceback)
    direction=Vector3.zero;jumpRequested=false
    RunService:UnbindFromRenderStep("SGV2R01Movement")
    humanoid:Move(Vector3.zero)
    report.ok=ok;report.error=if ok then nil else tostring(err)
    state:SetAttribute("BarrierResults",Http:JSONEncode(report))
    state:SetAttribute("Running",false)
end)
return {started=#jobs}
