local RunService=game:GetService("RunService")
assert(RunService:IsClient() and RunService:IsStudio() and RunService:IsRunning())
local Http=game.HttpService
local player=game.Players.LocalPlayer
local state=player.PlayerGui.SGV2C01TestState
assert(not state:GetAttribute("Running") and not state:GetAttribute("BatchRunning"))
local course=workspace.RaceCourse
assert(course:GetAttribute("CandidateId")=="SGV2_Challenge_C01")
local character=player.Character
local humanoid,root=character.Humanoid,character.HumanoidRootPart
local height=humanoid.HipHeight+root.Size.Y/2
local origin=course:GetPivot().Position
local report={method="Supported waits through each new moving hazard's full cycle; separate deliberate body contacts with server checkpoint recovery. Setup teleports are declared.",jobs={}}
local function position() local p=root.Position-origin;return {p.X,p.Y,p.Z} end
local function place(p)
    humanoid:Move(Vector3.zero);character:PivotTo(CFrame.new(p))
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
end
local function save() state:SetAttribute("ContactResults",Http:JSONEncode(report)) end
state:SetAttribute("Running",true)
task.spawn(function()
    local ok,err=xpcall(function()
        for _,row in {
            {"EntryHurdle_Left",1,Vector3.new(-69,6.4,57.4)},
            {"EntryHurdle_Right",1,Vector3.new(-69,6.4,44)},
            {"ToolBenchSlider",4,Vector3.new(-154,8.4,-153)},
            {"SecondWagonSpinner",9,Vector3.new(114,8.24,98)},
            {"LongWagonSwing",9,Vector3.new(149,8.24,139)},
            {"FestivalRiser",9,Vector3.new(145,8.24,116)},
        } do
            if state:GetAttribute("ContactOnly") and state:GetAttribute("ContactOnly")~=row[1] then continue end
            local bar=course.ChallengeHazards[row[1]].RedThornCrossbar
            assert(game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=row[2]}).ok)
            task.wait(1.8)
            place(origin+row[3]+Vector3.new(0,height+.1,0));task.wait(.8)
            local record={name=row[1],checkpoint=row[2],nearStart=position()}
            table.insert(report.jobs,record)
            assert(humanoid.FloorMaterial~=Enum.Material.Air and (root.Position-origin-row[3]-Vector3.new(0,height,0)).Magnitude<1.6,"Unsupported near-miss setup")
            local prior=character:GetAttribute("RecoveryUntil") or 0
            local began=os.clock();local first=bar.CFrame;local movement=0
            local duration=(bar:GetAttribute("MotionPeriod") or 2)+.4
            repeat
                RunService.Heartbeat:Wait()
                movement=math.max(movement,(bar.Position-first.Position).Magnitude+(bar.CFrame.RightVector-first.RightVector).Magnitude)
            until os.clock()-began>=duration
            record.safe=(character:GetAttribute("RecoveryUntil") or 0)==prior and humanoid.FloorMaterial~=Enum.Material.Air
            record.movement=movement;record.waitSeconds=os.clock()-began
            save();assert(record.safe and (not bar:GetAttribute("KitMotion") or movement>.2),"Near miss or movement failed")
            local cp=course.Checkpoints[string.format("Checkpoint_%03d",row[2])]
            local area=cp:GetAttribute("RespawnAreaSize")
            local cols,rows=1+math.floor((area.X-3)/4.5),1+math.floor((area.Z-3)/4.5)
            local expected=(cp:GetAttribute("RespawnCFrame")*CFrame.new(-(cols-1)*2.25,0,-(rows-1)*2.25)).Position
            place(bar.Position+Vector3.new(0,1,0))
            began=os.clock()
            repeat RunService.Heartbeat:Wait() until (character:GetAttribute("RecoveryUntil") or 0)>prior or os.clock()-began>2
            record.recovered=(character:GetAttribute("RecoveryUntil") or 0)>prior
            record.contactSeconds=os.clock()-began
            task.wait(.65)
            record.destinationError=(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(expected.X,0,expected.Z)).Magnitude
            save();assert(record.recovered and record.destinationError<1.5,"Contact recovery failed")
            task.wait(1.8)
        end
    end,debug.traceback)
    report.ok=ok;if not ok then report.error=tostring(err) end
    save();state:SetAttribute("Running",false)
end)
return {started=true}
