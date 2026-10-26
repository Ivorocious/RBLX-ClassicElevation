local player=game.Players.LocalPlayer
local state=player.PlayerGui.SGV2R01TestState
local course=workspace.RaceCourse
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient() and not state:GetAttribute("Running"))
local character=player.Character
local humanoid=character.Humanoid
local root=character.HumanoidRootPart
local height=humanoid.HipHeight+root.Size.Y/2
local origin=course:GetPivot().Position
local direction=Vector3.zero
local jump=false
local function a(p)return {p.X,p.Y,p.Z}end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={course};params.RespectCanCollide=true
local results={candidate=course:GetAttribute("CandidateId"),method="Existing Studio checkpoint selector establishes recovery target; one setup onto expert support, then ordinary missed jump and real server recovery",cases={}}
state:SetAttribute("Running",true)
RunService:BindToRenderStep("SGV2R01Movement",Enum.RenderPriority.Input.Value+1,function()humanoid:Move(direction,false);humanoid.Jump=jump end)
task.spawn(function()
    local ok,err=xpcall(function()
        for _,row in {{name="Crop",checkpoint=3,from=Vector3.new(-121.5,11.1,-116.5)},{name="Vine",checkpoint=7,from=Vector3.new(89.5,11.25,15)}} do
            local setup=game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=row.checkpoint})
            assert(setup.ok,"Checkpoint setup failed")
            task.wait(2)
            character:PivotTo(CFrame.new(origin+row.from+Vector3.new(0,height+.12,0)))
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
            task.wait(.9)
            local before=character:GetAttribute("RecoveryUntil") or 0
            local support=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),params)
            assert(support and humanoid.FloorMaterial~=Enum.Material.Air and (root.Position-origin-row.from-Vector3.new(0,height,0)).Magnitude<1.5,"Expert setup unsupported")
            local result={name=row.name,checkpoint=row.checkpoint,start=a(root.Position-origin),support=support.Instance:GetFullName(),trace={}}
            table.insert(results.cases,result)
            direction=Vector3.zAxis;jump=true
            local started=os.clock();local last=-1
            repeat
                RunService.Heartbeat:Wait()
                if humanoid.FloorMaterial==Enum.Material.Air then result.airborne=true;jump=false end
                if os.clock()-started>.18 then jump=false end
                if os.clock()-started-last>.1 then table.insert(result.trace,{t=os.clock()-started,p=a(root.Position-origin),floor=humanoid.FloorMaterial.Name});last=os.clock()-started end
            until (character:GetAttribute("RecoveryUntil") or 0)>before or os.clock()-started>5
            direction=Vector3.zero;jump=false
            task.wait(.5)
            result.recovered=(character:GetAttribute("RecoveryUntil") or 0)>before
            local checkpoint=course.Checkpoints:FindFirstChild(string.format("Checkpoint_%03d",row.checkpoint))
            local relative=checkpoint:GetAttribute("RespawnCFrame"):PointToObjectSpace(root.Position)
            local area=checkpoint:GetAttribute("RespawnAreaSize")
            result.after=a(root.Position-origin)
            result.withinArea=math.abs(relative.X)<=area.X/2 and math.abs(relative.Z)<=area.Z/2 and math.abs(relative.Y)<6
            local floor=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),params)
            result.recoverySupport=floor and floor.Instance:GetFullName()
            result.grounded=humanoid.FloorMaterial~=Enum.Material.Air and floor~=nil
            state:SetAttribute("ExpertRecoveryResults",Http:JSONEncode(results))
            assert(result.airborne and result.recovered and result.withinArea and result.grounded,"Expert miss recovery failed")
            task.wait(1.8)
        end
    end,debug.traceback)
    direction=Vector3.zero;jump=false;RunService:UnbindFromRenderStep("SGV2R01Movement");humanoid:Move(Vector3.zero)
    results.ok=ok;results.error=if ok then nil else tostring(err)
    state:SetAttribute("ExpertRecoveryResults",Http:JSONEncode(results));state:SetAttribute("Running",false)
end)
return {started=true}
