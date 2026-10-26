--!nonstrict
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 85558151074819)
local lease = script:GetAttribute("LeaseAttribute") or "ERP2AutomatedMovementLease"
local maximumSeconds = script:GetAttribute("MaximumSeconds") or 660
assert(maximumSeconds > 0 and maximumSeconds <= 660)
local controlName = script:GetAttribute("ControlName")
local control = controlName and game.ReplicatedStorage:WaitForChild(controlName, 15)
local maximumLeases = if control then 2 else 1
local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local flow = require(player.PlayerScripts.Controllers.RaceFlowController)
local report = Instance.new("StringValue")
report.Name, report.Parent = "ERP2InputIsolationReport", script
local receipt = {
 method = "Temporarily disable default player movement while the unchanged canonical server test driver controls the avatar",
 geometryWrites = 0, movementProfileWrites = 0,
 cameraWrites = 0, sourceReplacements = 0, started = workspace:GetServerTimeNow(), runs = {},
}
local current, completed, closed = nil, 0, false
local function publish(state)
 report.Value = game.HttpService:JSONEncode(receipt)
 report:SetAttribute("State", state)
end
local function restore(reason)
 if not current then return end
 controls:Enable(current.originalEnabled)
 current.restored, current.restoreReason = controls.controlsEnabled == current.originalEnabled, reason
 current.restoredAt = workspace:GetServerTimeNow()
 receipt.allRestored = current.restored and (receipt.allRestored ~= false)
 current, completed = nil, completed + 1
 publish("Restored")
end
script.Destroying:Connect(function() closed = true; restore("Test script ended") end)
local function requested()
 if control then
  local phase = control:GetAttribute("Phase")
  return if phase == "NormalRunning" or phase == "ExpertRunning" then phase else nil
 end
 return if player:GetAttribute(lease) == true then "Probe" else nil
end
publish("Waiting")
local deadline = os.clock() + maximumSeconds
repeat
 local key = requested()
 if current and current.key ~= key then restore("Server movement phase ended") end
 if completed >= maximumLeases then break end
 if control and table.find({"Complete", "Failed"}, control:GetAttribute("Phase")) then break end
 local state = flow.GetState()
 if key and not current and player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalOpen") ~= true
  and player:GetAttribute("TournamentCourseReady") == true and player:GetAttribute("TournamentPresentation") ~= true
  and state and state.state == "Racing" and state.status == "Racing" then
  assert(controls.controlsEnabled == true, "Finish the ordinary control handoff before starting isolation")
  current = {key = key, originalEnabled = controls.controlsEnabled, isolatedAt = workspace:GetServerTimeNow()}
  table.insert(receipt.runs, current)
  controls:Disable()
  current.controlsDisabled = controls.controlsEnabled == false
  assert(current.controlsDisabled, "Default control isolation failed")
  publish("Isolated")
 end
 if current and controls.controlsEnabled ~= false then
  receipt.interference = "Default controls were enabled during server driving"
  break
 end
 RunService.Heartbeat:Wait()
until closed or os.clock() >= deadline
restore(if closed then "Test script ended" else "Bounded test finished")
receipt.completedLeases, receipt.finishedAt = completed, workspace:GetServerTimeNow()
publish(if receipt.interference then "Failed" else "Restored")
