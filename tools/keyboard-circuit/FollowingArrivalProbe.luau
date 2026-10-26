local candidate = workspace.KeyboardCircuit_P1_C06
local player = game.Players.LocalPlayer
local character = player.Character
local root = character.HumanoidRootPart
local humanoid = character:FindFirstChildOfClass("Humanoid")
local lift = candidate.S02_ThockySwitchworks.H05_SpringLift
local function point(v) return {x=v.X,y=v.Y,z=v.Z} end
local function state()
 return {elapsed=candidate:GetAttribute("KCElapsed"), cycle=lift:GetAttribute("CycleState"), boarding=lift:GetAttribute("BoardingWindow"), exit=lift:GetAttribute("ExitWindow"), position=lift.Slider.CurrentPosition, deckY=lift.RideableBank.PrimaryPart.Position.Y, relativeY=root.Position.Y-lift.RideableBank.PrimaryPart.Position.Y, root=point(root.Position), floor=humanoid.FloorMaterial.Name}
end
local function stage(position)
 character:PivotTo(character:GetPivot() + (position-root.Position))
 root.AssemblyLinearVelocity = Vector3.zero
 humanoid:Move(Vector3.zero,false)
end
shared.KCFollowingC06 = {revision="KC_P1_C06",active=true,records={},ride={},limit="One actual avatar represents prior pressure and later following roles in a controlled fixture. No simultaneous followers or multiplayer result."}
task.spawn(function()
 local result = shared.KCFollowingC06
 local ok,err = pcall(function()
  result.initial = state()
  assert(lift:GetAttribute("CycleState") == "Waiting", "Fixture requires idle lift")
  stage(Vector3.new(2455.5,339.2,-1300))
  local began = os.clock()
  while lift:GetAttribute("CycleState") ~= "Boarding" and os.clock()-began < 2 do task.wait(.01) end
  assert(lift:GetAttribute("CycleState") == "Boarding", "Actual pressure did not open boarding")
  result.priorPressure = state()
  stage(Vector3.new(2450.5,339.2,-1300))
  task.wait(.2)
  result.followingLaunch = state()
  assert(lift:GetAttribute("BoardingWindow"), "Already-triggered window closed before launch")
  assert(shared.KCProbe.Move("Following arrival actual boarding jump",Vector3.new(2455.5,336,-1300),true,2,.35), "Following jump failed")
  result.followingArrival = state()
  result.followingWindowAge = result.followingArrival.elapsed-result.priorPressure.elapsed
  assert(result.followingArrival.boarding, "Following arrival missed shared boarding window")
  task.wait(.12)
  result.settled = state()
  local riderStart,deckStart = root.Position.Y,lift.RideableBank.PrimaryPart.Position.Y
  began = os.clock()
  while lift:GetAttribute("CycleState") ~= "HighDwell" and os.clock()-began < 6 do
   table.insert(result.ride,state())
   task.wait(.05)
  end
  assert(lift:GetAttribute("ExitWindow"), "Following rider did not reach high exit")
  task.wait(.12)
  result.high = state()
  result.riderRise,result.platformRise = root.Position.Y-riderStart,lift.RideableBank.PrimaryPart.Position.Y-deckStart
  assert(shared.KCProbe.Move("Following rider supported high takeoff",Vector3.new(2465.8,root.Position.Y,-1300),false,2,.35))
  assert(shared.KCProbe.Move("Following rider actual receiver jump",Vector3.new(2473,344,-1300),true,2,.5))
  result.finish = state()
  result.ok = true
 end)
 if not ok then result.ok,result.error = false,tostring(err) end
 result.records = shared.KCProbe.Records()
 result.active = false
 shared.KCProbe.Stop()
end)
return {started=true}
