--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId==0 and game.GameId==0 and script:GetAttribute("OwnedMoonlitTest"))
local player=Players.LocalPlayer
assert(player.UserId==-1)
local course=workspace.RaceCourse
assert(course:GetAttribute("CandidateId")=="MC_P2_C01_R04")
local character=player.Character
local human,root=character.Humanoid,character.HumanoidRootPart
local params=RaycastParams.new()
params.RespectCanCollide=true
params.FilterType=Enum.RaycastFilterType.Exclude
local excluded={}
for _,p in Players:GetPlayers() do if p.Character then table.insert(excluded,p.Character) end end
params.FilterDescendantsInstances=excluded
local folder=Instance.new("Folder");folder.Name=script.Name.."_Evidence";folder.Parent=player.PlayerScripts
local status=Instance.new("StringValue");status.Name="StatusJSON";status.Parent=folder
local report={candidate="MC_P2_C01_R04",nativeSha256="322ad87987028e029bd66105b78d00cd04d27a1d9db2c8548f27187d5927879b",
    source="Controlled placement above each of four weights, then real native gravity and body support",cases={},profile={speed=human.WalkSpeed,jumpHeight=human.JumpHeight,slope=human.MaxSlopeAngle}}
local function xyz(v) return {v.X,v.Y,v.Z} end
local function park(part)
    local target=part.CFrame*CFrame.new(0,part.Size.Y/2+human.HipHeight+root.Size.Y/2+.08,0)
    character:PivotTo(target*root.CFrame:Inverse()*character:GetPivot())
    root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
end
local bind=script.Name.."_Idle"
RunService:BindToRenderStep(bind,Enum.RenderPriority.Input.Value+1,function() human:Move(Vector3.zero) end)
local ok,err=xpcall(function()
    for _,stage in {"Lower","Upper"} do for bay=1,2 do
        local model=course.Obstacles[stage.."Mechanism"]["OutboardWeight"..bay]
        local weight=model.WeightContact
        local row={stage=stage,bay=bay,path=weight:GetFullName(),parts={},samples={}}
        table.insert(report.cases,row)
        for _,part in model:GetDescendants() do if part:IsA("BasePart") then
            table.insert(row.parts,{name=part.Name,canCollide=part.CanCollide,role=part:GetAttribute("Role")})
            assert(not part.CanCollide,"Counterweight contains a colliding support")
        end end
        assert(weight:GetAttribute("Role")=="CounterweightVisual" and not weight.CanCollide)
        row.beforeProgress=player:GetAttribute("MCPhase2Progress")
        park(weight)
        row.startedAt=workspace:GetServerTimeNow();row.initialRoot=xyz(root.Position)
        local began=os.clock();local maximumDrop,airSamples=0,0
        repeat
            assert(player.Character==character and human.Health>0 and workspace.RaceCourse==course)
            local ray=workspace:Raycast(root.Position,Vector3.new(0,-(human.HipHeight+root.Size.Y/2+2),0),params)
            assert(not ray or not ray.Instance:IsDescendantOf(model),"Native weight supported body")
            local drop=row.initialRoot[2]-root.Position.Y
            maximumDrop=math.max(maximumDrop,drop)
            if human.FloorMaterial==Enum.Material.Air then airSamples+=1 end
            table.insert(row.samples,{at=workspace:GetServerTimeNow(),root=xyz(root.Position),weight=xyz(weight.Position),drop=drop,
                state=human:GetState().Name,floor=human.FloorMaterial.Name,support=ray and ray.Instance:GetFullName(),progress=player:GetAttribute("MCPhase2Progress")})
            status.Value=HttpService:JSONEncode({state="Running",stage=stage,bay=bay,samples=#row.samples})
            task.wait(.05)
        until os.clock()-began>=1
        row.maximumDrop,row.airSamples=maximumDrop,airSamples
        assert(maximumDrop>=5 and airSamples>=3,"Native body did not fall through the noncolliding weight")
        row.passed=true;row.endedAt=workspace:GetServerTimeNow()
        park(course.Obstacles.Gate.GateCourt.Contact);task.wait(.3)
    end end
end,debug.traceback)
RunService:UnbindFromRenderStep(bind)
human:Move(Vector3.zero)
park(course.Obstacles.Gate.GateCourt.Contact)
report.state=if ok then "Complete" else "Failed";report.failure=if not ok then tostring(err) else nil
local raw=HttpService:JSONEncode(report)
folder:SetAttribute("JSONBytes",#raw);folder:SetAttribute("JSONChunks",math.ceil(#raw/60000))
for offset=1,#raw,60000 do local s=Instance.new("StringValue");s.Name=string.format("JSON_%03d",math.ceil(offset/60000));s.Value=raw:sub(offset,offset+59999);s.Parent=folder end
status.Value=HttpService:JSONEncode({state=report.state,cases=#report.cases,failure=report.failure})
