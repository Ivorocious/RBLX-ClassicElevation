local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local player=game.Players.LocalPlayer
assert(RunService:IsClient() and RunService:IsRunning())
local state=assert(player.PlayerGui:FindFirstChild("SGV2S05TestState"))
assert(state:GetAttribute("SGV2TestOwned") and not state:GetAttribute("Running"))
local jobs=Http:JSONDecode(state:GetAttribute("ProbeJobs"))
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_StudStyle_S05")
local character=player.Character
local humanoid=character.Humanoid
local root=character.HumanoidRootPart
local height=humanoid.HipHeight+root.Size.Y/2
local origin=course:GetPivot().Position
local direction=Vector3.zero
local jumping=false
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={course};params.RespectCanCollide=true
local report={candidate=course:GetAttribute("CandidateId"),origin={origin.X,origin.Y,origin.Z},method="One supported setup then normal Humanoid Move and Jump; actual active RaceCourse and existing recovery services",jobs={}}
local function v(a)return Vector3.new(unpack(a))end
local function arr(p)return {p.X,p.Y,p.Z}end
local function foot()return root.Position-origin-Vector3.new(0,height,0)end
local function horizontal(p)return Vector3.new(p.X,0,p.Z)end
local function ground()
    local hit=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),params)
    return hit and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(hit.Distance-height)<.95,hit
end
state:SetAttribute("Running",true)
RunService:BindToRenderStep("SGV2S05ProbeMovement",Enum.RenderPriority.Input.Value+1,function()humanoid:Move(direction,false);humanoid.Jump=jumping end)
task.spawn(function()
    local ok,err=xpcall(function()
        assert(humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.001 and math.abs(workspace.Gravity-196.2)<.001)
        for _,job in jobs do
            state:SetAttribute("Job",job.id)
            direction=Vector3.zero;jumping=false
            local cp=if job.id:find("grove-fold",1,true) then 5 elseif job.id:find("opening-to",1,true) then 7 elseif job.id:find("market-fold",1,true) then 9 elseif job.id:find("expert-to-stored",1,true) then 3 elseif job.id:find("rhubarb",1,true) or job.id:find("leaf6",1,true) then 8 else 1
            local teleport=game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=cp})
            assert(teleport.ok,"Checkpoint setup rejected")
            task.wait(.9)
            character:PivotTo(CFrame.new(origin+v(job.from)+Vector3.new(0,height+.12,0)))
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
            task.wait(.8)
            local grounded,hit=ground();local start=foot()
            local row={id=job.id,checkpoint=cp,from=job.from,target=job.steps[1].to,start=arr(start),startSupport=hit and hit.Instance:GetFullName(),trace={},bodyTouches={},nearBarrierRays={},landings={}}
            table.insert(report.jobs,row)
            row.setupPassed=grounded and (horizontal(start-v(job.from))).Magnitude<1.5 and math.abs(start.Y-job.from[2])<1.5
            if row.setupPassed then
                local wall=job.expectedBarrierModel and course.CreativeGardenBoundaries:FindFirstChild(job.expectedBarrierModel)
                local wallParams=RaycastParams.new();wallParams.FilterType=Enum.RaycastFilterType.Include;wallParams.FilterDescendantsInstances=if wall then {wall} else {};wallParams.RespectCanCollide=true
                local target=v(job.steps[1].to);local recovery=character:GetAttribute("RecoveryUntil") or 0
                local touches,rays,landings={},{},{}
                local began=os.clock();local lastSample=-1;local lastJump=-1
                row.peakFootY=start.Y;row.closestTarget=horizontal(start-target).Magnitude
                while os.clock()-began<3.5 do
                    local elapsed=os.clock()-began
                    local delta=horizontal(origin+target-root.Position)
                    direction=if delta.Magnitude>.2 then delta.Unit else Vector3.zero
                    if humanoid.FloorMaterial~=Enum.Material.Air and elapsed-lastJump>.7 then lastJump=elapsed end
                    jumping=elapsed-lastJump<.18 and humanoid.FloorMaterial~=Enum.Material.Air
                    RunService.Heartbeat:Wait()
                    local actual=foot();local landed,support=ground()
                    if humanoid.FloorMaterial==Enum.Material.Air then row.airborne=true end
                    row.peakFootY=math.max(row.peakFootY,actual.Y)
                    row.closestTarget=math.min(row.closestTarget,horizontal(actual-target).Magnitude)
                    if wall then
                        for _,body in character:GetChildren() do if body:IsA("BasePart") then
                            for _,part in body:GetTouchingParts() do if part:IsDescendantOf(wall) then touches[part:GetFullName()]=true end end
                        end end
                    end
                    if elapsed-lastSample>=.10 then
                        local near={}
                        if wall then for _,dy in {-1.4,0,1.4} do
                            local contact=workspace:Raycast(root.Position+Vector3.new(0,dy,0),direction*2.3,wallParams)
                            if contact then rays[contact.Instance:GetFullName()]=true;table.insert(near,{path=contact.Instance.Name,distance=contact.Distance}) end
                        end end
                        table.insert(row.trace,{t=elapsed,p=arr(actual),floor=humanoid.FloorMaterial.Name,support=support and support.Instance:GetFullName(),near=near})
                        lastSample=elapsed
                    end
                    if (character:GetAttribute("RecoveryUntil") or 0)>recovery then row.recovered=true;break end
                    if row.airborne and landed and support then
                        local path=support.Instance:GetFullName();landings[path]=true
                        if job.steps[1].expectedSupportModel and path:find("."..job.steps[1].expectedSupportModel..".",1,true) then row.reachedForbiddenSupport=true;row.forbiddenSupport=path;break end
                        if support.Instance:IsDescendantOf(course.CreativeGardenBoundaries) or support.Instance:IsDescendantOf(course.StudGardenCompositions) then row.newSceneryLanding=path end
                    end
                end
                for path in touches do table.insert(row.bodyTouches,path) end
                for path in rays do table.insert(row.nearBarrierRays,path) end
                for path in landings do table.insert(row.landings,path) end
                direction=Vector3.zero;jumping=false
                task.wait(.5)
                row.after=arr(foot());local _,lastHit=ground();row.afterSupport=lastHit and lastHit.Instance:GetFullName()
                row.elapsed=os.clock()-began
            end
            direction=Vector3.zero;jumping=false
            state:SetAttribute("ProbeResults",Http:JSONEncode(report))
        end
    end,debug.traceback)
    direction=Vector3.zero;jumping=false;RunService:UnbindFromRenderStep("SGV2S05ProbeMovement");humanoid:Move(Vector3.zero)
    report.ok=ok;report.error=if ok then nil else tostring(err)
    state:SetAttribute("ProbeResults",Http:JSONEncode(report));state:SetAttribute("Running",false)
end)
return {started=#jobs}
