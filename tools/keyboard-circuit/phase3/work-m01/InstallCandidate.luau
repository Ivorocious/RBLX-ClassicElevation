--!strict
assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and not game:GetService("RunService"):IsRunning())
local storage, http = game.ServerStorage, game.HttpService
local holder = storage.KCP3M01Sources01
local candidate = holder.KeyboardCircuit_P3_M01_01
local old = workspace.KeyboardCircuit_P2_I09_Experience03
assert(candidate:GetAttribute("PrototypeRevision")=="KC_P3_M01_01" and old:GetAttribute("PrototypeRevision")=="KC_P2_I09_03")
assert(shared.KCP3M01Integration01.geometryPassed and shared.KCP3M01Integration01.bodyClearancePassed)
assert(shared.KCP3M01MotionClearance01.passed and shared.KCP3OwnerPoseExport01)
local archive = storage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses
assert(not archive:FindFirstChild(old.Name) and not workspace:FindFirstChild(candidate.Name), "Inspect any partial handoff")
local preservedSources = {}
for _, item in old.SourceSnapshot:GetChildren() do preservedSources[item.Name]=item.Source end
for _, item in old:GetDescendants() do if item:IsA("BaseScript") then item.Disabled=true end end
old.Parent=archive
for name, source in preservedSources do assert(old.SourceSnapshot[name].Source==source) end
candidate.Parent=workspace
candidate.SourceSnapshot.Session.Disabled=false
local expected = candidate:GetAttribute("Origin")+Vector3.new(-81,-.575,-81)
local contact = candidate.CheckpointBays.F00.BankContact
assert((contact.Position-expected).Magnitude < .001)
for name, count in shared.KCP3M01PreflightCounts do
 assert(workspace:FindFirstChild(name) and #workspace[name]:GetDescendants()==count, "Unrelated map changed "..name)
end
return http:JSONEncode({installed=candidate:GetFullName(),revision=candidate:GetAttribute("PrototypeRevision"),archived=old:GetFullName(),sources=#candidate.SourceSnapshot:GetChildren(),origin={2222,330,-1158},unrelated=shared.KCP3M01PreflightCounts,boundary="Scoped recoverable replacement, no deletion, whole-place save or publication. Owner placement retained; legacy shared course flag retained for existing F6 and session compatibility."})
