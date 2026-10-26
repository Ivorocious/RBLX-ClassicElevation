--!nonstrict
assert(game.PlaceId==0 and game.GameId==0 and game.RunService:IsStudio() and game.RunService:IsServer())
local H=game.HttpService
local Control=require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local services=Control.Services()
local player=assert(game.Players:GetPlayers()[1])
local report={candidate="MC_P2_C01_R05",kind="Actual shared race; controlled single R15 visible-red placement",actualClients=1,samples={}}
local function waitFor(test,seconds,label)
 local deadline=os.clock()+seconds
 repeat if test() then return end task.wait(.05) until os.clock()>=deadline
 error(label)
end
local function state()
 local raw=player:GetAttribute("MCPhase2Progress")
 return raw and H:JSONDecode(raw)
end
local function pose(v) return {v.X,v.Y,v.Z} end
local function snapshot()
 local q=state()
 local char=player.Character
 return {at=workspace:GetServerTimeNow(),progress=q,root=pose(char.HumanoidRootPart.Position),recoveryUntil=char:GetAttribute("RecoveryUntil"),diagnostics=services.MoonlitCitadelService.GetDiagnostics()}
end
local ok,err=xpcall(function()
 local q=assert(state())
 assert(q.candidate==report.candidate and q.status=="Racing" and q.raceState=="Racing" and q.staged and q.official and q.checkpoint==0 and q.falls==0,"Clean actual shared race required")
 report.entry=q
 report.priorCompletedRouteNativeSha256="a511d10a33ea9e3a546e4e243142c507e60265350967ad48e7918fc6ae4441e7"
 local course=services.CourseService.GetActiveCourse()
 assert(course:GetAttribute("CandidateId")==report.candidate)
 local target=course.Obstacles.ArchResets.OpeningGapReset.NeonRedContact
 assert(target:GetAttribute("MoonlitHazard")==true and target:GetAttribute("Role")=="VisibleResetContact" and target.Material==Enum.Material.Neon and target.Transparency<1)
 local mesh=target.RedVisualInset
 assert(mesh:IsA("BlockMesh") and (mesh.Scale-Vector3.new(.96,.96,.96)).Magnitude<.00001)
 local char=assert(player.Character)
 local humanoid=char:FindFirstChildOfClass("Humanoid")
 local root=char.HumanoidRootPart
 waitFor(function() return (char:GetAttribute("RecoveryUntil") or 0)<=workspace:GetServerTimeNow() end,8,"Recovery immunity expired")
 report.before=snapshot()
 report.target={path=target:GetFullName(),frame={target.CFrame:GetComponents()},size=pose(target.Size),renderScale=pose(mesh.Scale)}
 root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
 char:PivotTo(target.CFrame*CFrame.new(0,humanoid.HipHeight+root.Size.Y/2,0))
 local params=OverlapParams.new()
 params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Include,{char}
 report.initialBodyOverlaps={}
 for _,part in ipairs(workspace:GetPartsInPart(target,params)) do
  if part.Parent==char and part.Name~="HumanoidRootPart" and part.Transparency<1 then table.insert(report.initialBodyOverlaps,part.Name) end
 end
 assert(#report.initialBodyOverlaps>0,"Actual visible R15 body contact absent")
 waitFor(function() local q=state() return q and q.falls==1 and q.checkpoint==0 and q.official end,6,"Actual shared red recovery")
 for _=1,50 do table.insert(report.samples,snapshot()) task.wait(.1) end
 report.after=snapshot()
 assert(report.after.progress.falls==1 and report.after.progress.checkpoint==0)
 assert(report.after.diagnostics.stats.hazardHits>report.before.diagnostics.stats.hazardHits and report.after.diagnostics.stats.recoveries>report.before.diagnostics.stats.recoveries)
 local expected=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
 report.recoveryTarget=pose(expected.Position)
 local d=root.Position-expected.Position
 report.recoveryHorizontalError=Vector3.new(d.X,0,d.Z).Magnitude
 report.recoveryVerticalError=math.abs(d.Y)
 assert(report.recoveryHorizontalError<1.5 and report.recoveryVerticalError<6,"Actual recovery target mismatch")
 report.passed=true
end,debug.traceback)
if not ok then report.failure=tostring(err) report.passed=false end
report.completedAt=workspace:GetServerTimeNow()
Control.SaveReport("MC_P2_C01_R05_RedBody02",report)
game.ReplicatedStorage.MoonlitPhase2Tools:SetAttribute("R05RedBodyStatus02",H:JSONEncode({passed=report.passed,failure=report.failure,at=report.completedAt}))
