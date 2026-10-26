local c = workspace.KeyboardCircuit_P2_C01
local p = assert(shared.KCP2TraversalProbe)
local player = game.Players.LocalPlayer
local Fixture = {active = false, records = {}}
function Fixture.Board(id)
 assert(not Fixture.active and (id == "H05" or id == "H06"))
 local unit
 for _, item in c.Districts:GetDescendants() do
  if item:IsA("Model") and item:GetAttribute("MechanismId") == id then unit = item; break end
 end
 assert(unit)
 local record = {id = id, case = "board-before-live-transition", nativeExecuted = true}
 table.insert(Fixture.records, record)
 Fixture.active = true
 task.spawn(function()
  local ok, err = xpcall(function()
   local entry, ride = unit.EntryBank.BankContact, unit.RideableBank.BankContact
   record.setup = p.Place(entry)
   local began = os.clock()
   repeat task.wait(.03) until unit:GetAttribute("BoardingWindow") or os.clock()-began > 18
   assert(unit:GetAttribute("BoardingWindow"), "Boarding window did not arrive")
   record.boarded = p.Cross(id .. " transition boarding", entry, ride)
   assert(record.boarded, "Actual boarding failed")
   local root = player.Character.HumanoidRootPart
   local original = root.Position
   began = os.clock()
   repeat task.wait(.03) until (root.Position-original).Magnitude > 1.5 or os.clock()-began > 8
   record.carriedDistance = (root.Position-original).Magnitude
   record.root = {root.Position.X,root.Position.Y,root.Position.Z}
   record.slider = unit.Slider.CurrentPosition
   record.cycle = unit:GetAttribute("CycleState")
   record.passed = record.carriedDistance > 1.5
   record.boundary = "Staged entry; actual boarding and physical carrying before server Stop/Restart. No teleport while riding."
  end, debug.traceback)
  record.error = if ok then nil else tostring(err)
  record.passed = ok and record.passed == true
  Fixture.active = false
 end)
 return {started=true,id=id}
end
shared.KCP2RideTransitions = Fixture
return {installed=true}

