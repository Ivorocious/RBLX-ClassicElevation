--!strict
local RunService, Http = game:GetService("RunService"), game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning() and game.PlaceId == 85558151074819)
local candidate = workspace.KeyboardCircuit_P2_I09_Experience03
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P2_I09_03")
local contact = candidate.CheckpointBays.F00.BankContact
local expected = candidate.CheckpointBays.F00:GetAttribute("TopPosition") - Vector3.new(0, .575, 0)
local delta = expected - contact.Position
if delta.Magnitude > .005 then candidate:PivotTo(candidate:GetPivot() + delta) end
assert((contact.Position - expected).Magnitude < .005)
local entry = candidate.Districts.S01_CreamyCloudbank.O01.Entry.BankContact
assert((entry.Position - (candidate.Districts.S01_CreamyCloudbank.O01:GetAttribute("EntryPosition") - Vector3.new(0, .575, 0))).Magnitude < .005)
return Http:JSONEncode({passed = true, delta = {delta.X, delta.Y, delta.Z}, origin = tostring(candidate:GetAttribute("Origin")), boundary = "Run in a separate native call after construction to detect and correct post-call automatic placement. Only the current candidate moves."})
