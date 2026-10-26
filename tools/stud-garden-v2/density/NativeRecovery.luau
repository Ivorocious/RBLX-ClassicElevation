local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient() and RunService:IsRunning())
local player=game.Players.LocalPlayer
local state=assert(player.PlayerGui:FindFirstChild("SGV2D03TestState"))
assert(not state:GetAttribute("Running"))
local course=assert(workspace:FindFirstChild("RaceCourse"))
assert(course:GetAttribute("CandidateId")=="SGV2_Density_D03")
local jobs=Http:JSONDecode(state:GetAttribute("RecoveryJobs"))
local report={candidate=course:GetAttribute("CandidateId"),method="Declared airborne drop above new low scenery; unchanged server recovery; no supported-jump claim",jobs={}}
local origin=course:GetPivot().Position
local function arr(p)return {p.X,p.Y,p.Z}end
local function v(t)return Vector3.new(t[1],t[2],t[3])end
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={course}
params.RespectCanCollide=true
state:SetAttribute("Running",true)
task.spawn(function()
    local ok,err=xpcall(function()
        for _,job in jobs do
            local setup=game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=job.expectedCheckpoint})
            assert(setup.ok,setup.message)
            task.wait(1.1)
            local character=player.Character
            local root=character.HumanoidRootPart
            local humanoid=character.Humanoid
            local height=humanoid.HipHeight+root.Size.Y/2
            local checkpoint=course.Checkpoints:FindFirstChild(string.format("Checkpoint_%03d",job.expectedCheckpoint))
            assert(checkpoint,"Checkpoint missing")
            local authored=assert(checkpoint:GetAttribute("RespawnCFrame"))
            local area=assert(checkpoint:GetAttribute("RespawnAreaSize"))
            assert(#game.Players:GetPlayers()==1,"This recovery check assumes the first unoccupied slot")
            local columns=math.max(1,1+math.floor((area.X-3)/4.5))
            local rows=math.max(1,1+math.floor((area.Z-3)/4.5))
            local expected=(authored*CFrame.new(-(columns-1)*2.25,0,-(rows-1)*2.25)).Position
            local before=character:GetAttribute("RecoveryUntil") or 0
            local row={id=job.id,checkpoint=job.expectedCheckpoint,setupMode=job.setupMode,from=job.fromLocalFeet,expectedRoot=arr(expected-origin),trace={},contacts={}}
            table.insert(report.jobs,row)
            humanoid:Move(Vector3.zero)
            character:PivotTo(CFrame.new(origin+v(job.fromLocalFeet)+Vector3.new(0,height,0)))
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            local began=os.clock()
            local contacts={}
            while os.clock()-began<4 do
                RunService.Heartbeat:Wait()
                local hit=workspace:Raycast(root.Position,Vector3.new(0,-height-.6,0),params)
                if hit and hit.Instance:IsDescendantOf(course.GardenUnderstory) and humanoid.FloorMaterial~=Enum.Material.Air then contacts[hit.Instance:GetFullName()]=true end
                if #row.trace<60 then table.insert(row.trace,{t=os.clock()-began,p=arr(root.Position-origin),floor=humanoid.FloorMaterial.Name,support=hit and hit.Instance:GetFullName()}) end
                if (character:GetAttribute("RecoveryUntil") or 0)>before then row.recovered=true;row.recoverySeconds=os.clock()-began;break end
            end
            for name in contacts do table.insert(row.contacts,name) end
            task.wait(.65)
            row.afterRoot=arr(root.Position-origin)
            row.horizontalError=(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(expected.X,0,expected.Z)).Magnitude
            local hit=workspace:Raycast(root.Position,Vector3.new(0,-height-1,0),params)
            row.afterSupport=hit and hit.Instance:GetFullName()
            row.passed=row.recovered==true and row.horizontalError<1.5 and hit~=nil and not hit.Instance:IsDescendantOf(course.GardenUnderstory)
            state:SetAttribute("RecoveryResults",Http:JSONEncode(report))
            assert(row.passed,"Recovery failed: "..job.id)
        end
    end,debug.traceback)
    report.ok=ok
    if not ok then report.error=tostring(err) end
    state:SetAttribute("RecoveryResults",Http:JSONEncode(report))
    state:SetAttribute("Running",false)
end)
return {started=#jobs}
