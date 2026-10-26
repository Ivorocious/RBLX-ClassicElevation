local candidate = workspace.KeyboardCircuit_P2_C01
local player = game.Players.LocalPlayer
local Probe = assert(shared.KCP2TraversalProbe)
local unit
for _, item in candidate.Districts:GetDescendants() do if item:IsA("Model") and item:GetAttribute("MechanismId") == "H08" then unit = item end end
assert(unit)
local state = {active = true, steps = {}, waits = {}}
shared.KCP2H08Focused = state
local function waitFresh(actor)
	local began = os.clock()
	local closed = actor:GetAttribute("AdmissionOpen") ~= true
	while os.clock() - began < 18 do
		if actor:GetAttribute("AdmissionOpen") ~= true then closed = true end
		if closed and actor:GetAttribute("AdmissionOpen") == true then table.insert(state.waits, {at = workspace:GetServerTimeNow(), actor = actor.Name, seconds = os.clock() - began}); return end
		task.wait(.03)
	end
	error("Admission timeout")
end
task.spawn(function()
	local ok, err = xpcall(function()
		state.setup = Probe.Place(unit.EntryBank.BankContact)
		state.beforeRecoveries = player:GetAttribute("KCPhase2Recoveries")
		local previous = unit.EntryBank.BankContact
		for index = 1, 4 do
			if index > 1 then waitFresh(unit["DominoPanel" .. (index - 1)]) end
			local target = unit["PassageBank" .. index].BankContact
			local passed = Probe.Cross("H08 focused passage" .. index, previous, target)
			table.insert(state.steps, {index = index, passed = passed, at = workspace:GetServerTimeNow()})
			assert(passed, "Passage failed")
			previous = target
		end
		state.exit = Probe.Cross("H08 focused permanent exit", previous, unit.ExitBank.BankContact)
		state.afterRecoveries = player:GetAttribute("KCPhase2Recoveries")
		state.passed = state.exit and state.afterRecoveries == state.beforeRecoveries
	end, debug.traceback)
	state.error = if ok then nil else tostring(err)
	if not ok then state.passed = false end
	state.active = false
end)
return {started = true, boundary = "Focused reproduction uses the same fresh admissions and normal path as the continuous fixture; one staged entry"}
