--!strict
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818, "Intended experience required")
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer(), "Actual Studio server required")
local expectedOld = assert(shared.KCP2I05OldMechanismsSource)
local expectedNew = assert(shared.KCP2I05NewMechanismsSource)
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local storage = game:GetService("ServerStorage")
local kit = assert(storage.CourseAssetKits:FindFirstChild("KeyboardCircuit_Phase2EditableKit_K02"))
assert(candidate:GetAttribute("Phase2Only") and candidate:GetAttribute("ConstructionIteration") == 4)
assert(kit:GetAttribute("Phase2Only") and candidate.SourceSnapshot.Mechanisms.Source == expectedOld and kit.SourceSnapshot.Mechanisms.Source == expectedOld)
assert(not storage:FindFirstChild("KeyboardCircuitP2PlayI04H08Recovery"), "Inspect existing play proof before retry")
local builders = storage.CourseBuilders.KeyboardCircuitPhase2
assert(builders.Mechanisms.Source == expectedOld or builders.Mechanisms.Source == expectedNew)
local function getUnit(model: Model): Model
 local found
 for _, item in model:GetDescendants() do
  if item:IsA("Model") and item:GetAttribute("MechanismId") == "H08" then assert(not found); found = item end
 end
 return assert(found)
end
local unit, kitUnit = getUnit(candidate), getUnit(kit)
local function frameOf(model: Model): CFrame
 return (model.PrimaryPart :: BasePart).CFrame * (model:GetAttribute("FrameFromPrimary") :: CFrame)
end
local function verifyRest(model: Model)
 local frame = frameOf(model)
 for index, x in {-10, 0, 10} do
  local panel = model["DominoPanel" .. index] :: Model
  local localPivot = panel:GetAttribute("MotionPivotLocal") :: CFrame
  assert((localPivot.Position - Vector3.new(x, -2, 0)).Magnitude < .001)
  assert((frame:PointToObjectSpace(panel:GetPivot().Position) - Vector3.new(x, 4, 0)).Magnitude < .001)
 end
end
local controls = candidate.StudioProbeControls
local before = controls.State:Invoke()
assert(before.active, "Expected active test session")
for _, player in game:GetService("Players"):GetPlayers() do
 assert(player:GetAttribute("OnboardingReady") and player.Character and not player.Character.HumanoidRootPart.Anchored, "Foreign readiness lock")
end
controls.Stop:Fire()
task.wait(.2)
local stopped = controls.State:Invoke()
assert(not stopped.active and not stopped.runtime.active, "Real session must stop before rest changes")
verifyRest(unit); verifyRest(kitUnit)
local proof = Instance.new("Folder")
proof.Name, proof.Parent = "KeyboardCircuitP2PlayI04H08Recovery", storage
proof:SetAttribute("KCOwnedPhase2Preparation", true)
for _, item in {unit, kitUnit} do
 local copy = item:Clone()
 copy.Name = if item == unit then "PreviousCourseH08" else "PreviousKitH08"
 copy.Parent = proof
end
local oldSource = candidate.SourceSnapshot.Mechanisms:Clone()
oldSource.Name, oldSource.Parent = "PreviousMechanismsSource", proof
local checks = {}
local function lower(model: Model, label: string)
 local frame = frameOf(model)
 local delta = frame:VectorToWorldSpace(Vector3.new(0, -1.25, 0))
 local banks = {}
 for _, item in model:GetChildren() do if item:IsA("Model") and item.Name:find("Bank") then banks[item] = item:GetPivot() end end
 for index, x in {-10, 0, 10} do
  local panel = model["DominoPanel" .. index] :: Model
  local pivot = frame * CFrame.new(x, -3.25, 0)
  panel:PivotTo(panel:GetPivot() + delta)
  panel:SetAttribute("MotionPivot", pivot)
  panel:SetAttribute("MotionPivotLocal", frame:ToObjectSpace(pivot))
  panel:SetAttribute("RestPivot", panel:GetPivot())
  model["HingeAxle" .. index].CFrame += delta
  assert((frame:PointToObjectSpace(panel:GetPivot().Position) - Vector3.new(x, 2.75, 0)).Magnitude < .001)
  assert(panel.Contact.CanQuery and not panel.Contact.CanCollide and panel.Contact:GetAttribute("Role") == "Lethal")
  assert((panel.Contact.Size - Vector3.new(1.5, 12, 10)).Magnitude < .001)
 end
 for bank, pivot in banks do assert((bank:GetPivot().Position - pivot.Position).Magnitude < .001) end
 table.insert(checks, {model = label, panels = 3, flatPanelTop = -2.5, supportTop = -.45, gap = 2.05, banksPreserved = true})
end
lower(unit, "ActualServerCourse"); lower(kitUnit, "ActualServerKit")
candidate.SourceSnapshot.Mechanisms.Source = expectedNew
kit.SourceSnapshot.Mechanisms.Source = expectedNew
builders.Mechanisms.Source = expectedNew
candidate:SetAttribute("ConstructionIteration", 5)
controls.Restart:Fire()
task.wait(.3)
local after = controls.State:Invoke()
assert(after.active and after.runtime.active and after.runtime.errors == 0)
local receipt = {candidate = "KC_P2_C01-I05-UI01", checks = checks, before = before, stopped = stopped, after = after, recovery = proof:GetFullName(),
 boundary = "Temporary actual two-client server geometry mirror of the durable I05 builder. Only three H08 panels/hinges and matching source text change; actual Session Stop/Restart recaptures mover rest geometry. Existing participants and other Studio work are preserved. This does not save the place."}
shared.KCP2PlayMirrorReceipt05 = receipt
return game:GetService("HttpService"):JSONEncode(receipt)

