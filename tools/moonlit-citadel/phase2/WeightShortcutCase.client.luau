--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 0 and game.GameId == 0)
local player = Players.LocalPlayer
assert(player.UserId == -1 and script:GetAttribute("OwnedMoonlitTest") == true)
local course = workspace.RaceCourse
assert(course:GetAttribute("CandidateId") == "MC_P2_C01_R04")
local character, human, root = player.Character, player.Character.Humanoid, player.Character.HumanoidRootPart
local brace = course.Obstacles.UpperBrace.BraceStep3.Contact
local car = course.Obstacles.MovingCars.Upper_Bay2
local weight = course.Obstacles.UpperMechanism.OutboardWeight2.WeightContact
local params = RaycastParams.new()
params.RespectCanCollide = true
params.FilterType = Enum.RaycastFilterType.Exclude
local excluded = {}
for _, p in Players:GetPlayers() do if p.Character then table.insert(excluded, p.Character) end end
params.FilterDescendantsInstances = excluded
local report = {candidate="MC_P2_C01_R04",source="Controlled brace start, then ordinary native Humanoid Move/Jump only",controlledStart=true,
    weightCollidable=weight.CanCollide,profile={speed=human.WalkSpeed,jumpHeight=human.JumpHeight,slope=human.MaxSlopeAngle},attempts={}}
local folder = Instance.new("Folder")
folder.Name = script.Name .. "_Evidence"
folder.Parent = player.PlayerScripts
local status = Instance.new("StringValue")
status.Name, status.Parent = "StatusJSON", folder
local function xyz(v) return {v.X,v.Y,v.Z} end
local function update(state, attempt) status.Value=HttpService:JSONEncode({state=state,attempt=attempt,weightSupported=report.weightSupported or false}) end
local ok, err = xpcall(function()
    for attempt=1,3 do
        local deadline = os.clock()+18
        repeat task.wait(.03); assert(os.clock()<deadline,"Upper Bay2 high dwell unavailable") until car:GetAttribute("MoonlitPhase")=="HighDwell"
        -- Only the diagnostic start is placed; no transforms or velocities are assigned after movement begins.
        local target = brace.CFrame * CFrame.new(0,brace.Size.Y/2+human.HipHeight+root.Size.Y/2+.08,0)
        character:PivotTo(target*root.CFrame:Inverse()*character:GetPivot())
        root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        human:Move(Vector3.zero)
        task.wait(.2)
        local row={index=attempt,startedAt=workspace:GetServerTimeNow(),initialRoot=xyz(root.Position),initialWeight=xyz(weight.Position),samples={}}
        table.insert(report.attempts,row)
        local jumped, touchedWeight = false,false
        local began=os.clock()
        repeat
            assert(player.Character==character and human.Health>0 and workspace.RaceCourse==course,"Actual character/course changed")
            local ray=workspace:Raycast(root.Position,Vector3.new(0,-(human.HipHeight+root.Size.Y/2+2),0),params)
            local delta=weight.Position-root.Position
            local direction=Vector3.new(delta.X,0,delta.Z)
            if direction.Magnitude>.05 then direction=direction.Unit end
            if not jumped and ray and ray.Instance==brace and human.FloorMaterial~=Enum.Material.Air and root.Position.Z<=2577.3 then human.Jump=true;jumped=true;row.jumpAt=workspace:GetServerTimeNow();row.actualGroundedJumpRequest=true end
            if ray and ray.Instance==weight and human.FloorMaterial~=Enum.Material.Air then touchedWeight=true;human:Move(Vector3.zero) else human:Move(direction) end
            table.insert(row.samples,{at=workspace:GetServerTimeNow(),root=xyz(root.Position),weight=xyz(weight.Position),phase=car:GetAttribute("MoonlitPhase"),
                support=ray and ray.Instance:GetFullName(),gap=ray and root.Position.Y-human.HipHeight-root.Size.Y/2-ray.Position.Y,state=human:GetState().Name,
                floor=human.FloorMaterial.Name,jumped=jumped,progress=player:GetAttribute("MCPhase2Progress")})
            if touchedWeight then report.weightSupported=true end
            update("Running",attempt)
            if os.clock()-began>1.5 and root.Position.Y<409 then break end
            task.wait(.05)
        until os.clock()-began>=8
        row.weightSupported=touchedWeight;row.endedAt=workspace:GetServerTimeNow()
        human:Move(Vector3.zero)
        if touchedWeight then break end
    end
end,debug.traceback)
human:Move(Vector3.zero)
report.state=if ok then "Complete" else "Failed"
report.failure=if not ok then tostring(err) else nil
local encoded=HttpService:JSONEncode(report)
folder:SetAttribute("JSONBytes",#encoded);folder:SetAttribute("JSONChunks",math.ceil(#encoded/60000))
for offset=1,#encoded,60000 do local chunk=Instance.new("StringValue");chunk.Name=string.format("JSON_%03d",math.ceil(offset/60000));chunk.Value=encoded:sub(offset,offset+59999);chunk.Parent=folder end
update(report.state,#report.attempts)
