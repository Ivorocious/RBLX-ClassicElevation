local c=workspace.KeyboardCircuit_P2_C01
local player=game.Players.LocalPlayer
local p=assert(shared.KCP2TraversalProbe)
local u
for _,v in c.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")=="H08" then u=v end end
local state={active=true,cases={}}
shared.KCP2H08Variants=state
local function waitFresh(actor)
	local began=os.clock()
	local closed=actor:GetAttribute("AdmissionOpen")~=true
	repeat
		if actor:GetAttribute("AdmissionOpen")~=true then closed=true end
		if closed and actor:GetAttribute("AdmissionOpen")==true then return true end
		task.wait(.03)
	until os.clock()-began>18
	return false
end
task.spawn(function()
	local ok,err=xpcall(function()
		for _,delay in {0,.17,.33} do
			local row={delay=delay,steps={}}
			table.insert(state.cases,row)
			row.setup=p.Place(u.EntryBank.BankContact)
			row.beforeRecoveries=player:GetAttribute("KCPhase2Recoveries")
			local previous=u.EntryBank.BankContact
			for index=1,4 do
				if index>1 then assert(waitFresh(u["DominoPanel"..(index-1)])) end
				local target=u["PassageBank"..index].BankContact
				local passed=p.Cross("H08 variant"..delay.." passage"..index,previous,target)
				table.insert(row.steps,{index=index,passed=passed,at=workspace:GetServerTimeNow()})
				assert(passed,"H08 variant passage failed")
				previous=target
			end
			task.wait(delay)
			row.exit=p.Cross("H08 variant"..delay.." exit",previous,u.ExitBank.BankContact)
			row.afterRecoveries=player:GetAttribute("KCPhase2Recoveries")
			row.passed=row.exit and row.beforeRecoveries==row.afterRecoveries
			if not row.passed then break end
		end
	end,debug.traceback)
	state.error=if ok then nil else tostring(err)
	state.active=false
	state.passed=ok and #state.cases==3
	for _,row in state.cases do if not row.passed then state.passed=false end end
	state.boundary="Three bounded actual-avatar arrivals vary the exit-step animation phase; staged entry per case, ordinary continuous path inside each encounter."
end)
return {started=true,variants=3}
