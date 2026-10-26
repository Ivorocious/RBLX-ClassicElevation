local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
assert(RunService:IsClient() and RunService:IsRunning())
local player=game.Players.LocalPlayer
local state=assert(player.PlayerGui.SGV2F01TestState)
assert(not state:GetAttribute("Running"))
local course=workspace.RaceCourse
local origin=course:GetPivot().Position
local character=player.Character
local hum,root=character.Humanoid,character.HumanoidRootPart
local height=hum.HipHeight+root.Size.Y/2
local report={method="Three actual full-cycle supported near misses followed by deliberate moving-bar contact and authoritative checkpoint recovery",jobs={}}
local function pos()local p=root.Position-origin;return {p.X,p.Y,p.Z}end
local function place(p)
    hum:Move(Vector3.zero);character:PivotTo(CFrame.new(p));root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
end
local function save()state:SetAttribute("MovingContactResults",Http:JSONEncode(report))end
state:SetAttribute("Running",true)
task.spawn(function()
    local ok,err=xpcall(function()
        for _,row in {
            {"G1_SeedBenchThorns",1,Vector3.new(-97,7.4,51.5)},
            {"G3_SporeRoot_4",6,Vector3.new(94.5,11.4,-103)},
            {"G5_FirstWagonThorns",9,Vector3.new(56.5,8.24,111.5)},
        } do
            if state:GetAttribute("MovingOnly") and state:GetAttribute("MovingOnly")~=row[1] then continue end
            local m=course.ClosingRoute[row[1]];local bar=m.RedThornCrossbar
            local setup=game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=row[2]})
            assert(setup.ok);task.wait(.8)
            place(origin+row[3]+Vector3.new(0,height+.1,0));task.wait(.8)
            local record={name=row[1],checkpoint=row[2],nearStart=pos(),floor=hum.FloorMaterial.Name}
            table.insert(report.jobs,record)
            assert(hum.FloorMaterial~=Enum.Material.Air and (root.Position-origin-row[3]-Vector3.new(0,height,0)).Magnitude<1.6,"Unsupported near-miss setup")
            local prior=character:GetAttribute("RecoveryUntil") or 0
            local start=os.clock();local first=bar.CFrame;local movement=0
            repeat
                RunService.Heartbeat:Wait()
                movement=math.max(movement,(bar.Position-first.Position).Magnitude+(bar.CFrame.RightVector-first.RightVector).Magnitude)
            until os.clock()-start>bar:GetAttribute("MotionPeriod")+.4
            record.safe=(character:GetAttribute("RecoveryUntil") or 0)==prior and hum.FloorMaterial~=Enum.Material.Air
            record.motion=movement;record.nearAfter=pos();record.waitSeconds=os.clock()-start
            save();assert(record.safe and movement>.2,"Moving near miss failed")
            local cp=course.Checkpoints[string.format("Checkpoint_%03d",row[2])]
            local area=cp:GetAttribute("RespawnAreaSize");local cols=1+math.floor((area.X-3)/4.5);local rows=1+math.floor((area.Z-3)/4.5)
            local expected=(cp:GetAttribute("RespawnCFrame")*CFrame.new(-(cols-1)*2.25,0,-(rows-1)*2.25)).Position
            place(bar.Position+Vector3.new(0,1,0))
            local began=os.clock()
            repeat RunService.Heartbeat:Wait() until (character:GetAttribute("RecoveryUntil") or 0)>prior or os.clock()-began>2
            record.recovered=(character:GetAttribute("RecoveryUntil") or 0)>prior;record.contactSeconds=os.clock()-began
            task.wait(.65)
            record.afterRecovery=pos();record.destinationError=(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(expected.X,0,expected.Z)).Magnitude
            save();assert(record.recovered and record.destinationError<1.5,"Moving contact recovery failed")
            task.wait(1.7)
        end
    end,debug.traceback)
    report.ok=ok;if not ok then report.error=tostring(err)end
    save();state:SetAttribute("Running",false)
end)
return {started=true}
