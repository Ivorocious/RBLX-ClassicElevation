--!strict
assert(game:GetService("RunService"):IsServer())
local c=workspace.KeyboardCircuit_P3_M03_01
local signs=c.MapEnvironment.HazardIndicators:GetChildren()
assert(#signs==17)
local rows,failures={},{}
for _,sign in signs do rows[sign.Name]={phases={},samples=0} end
local deadline=os.clock()+28
repeat
	for _,sign in signs do
		local phase=sign:GetAttribute("DisplayedPhase")
		local source=sign.SourceMechanism.Value
		local actorLink=sign:FindFirstChild("SourceActor")
		local actor=actorLink and actorLink.Value
		local row=rows[sign.Name]
		row.samples+=1
		row.phases[phase or "MISSING"]=true
		local gui=sign.PrimaryPart.HazardDisplay
		local valid=gui.Phase.Text==phase and gui.Action.Text==sign:GetAttribute("DisplayedAction")
		if phase=="BOARD NOW" or phase=="LIFT LEAVES SOON" then valid=valid and source:GetAttribute("BoardingWindow")==true end
		if phase=="EXIT NOW" then valid=valid and source:GetAttribute("ExitWindow")==true end
		if phase=="KEY FALLING" then valid=valid and actor and actor:GetAttribute("CycleState")=="Drop" end
		if phase=="PANEL FALLS NEXT" then valid=valid and actor and actor:GetAttribute("CycleState")=="Warning" end
		if phase=="PANEL FALLING" then valid=valid and actor and actor:GetAttribute("CycleState")=="Tip" end
		if not valid then table.insert(failures,{sign=sign.Name,phase=phase,state=actor and actor:GetAttribute("CycleState"),unitState=source:GetAttribute("CycleState")}) end
	end
	task.wait(.15)
until os.clock()>=deadline
local activeSigns=0
for _,row in rows do if not row.phases.STOPPED and not row.phases.MISSING then activeSigns+=1 end end
local diagnostics=game.HttpService:JSONDecode(c:GetAttribute("KCPhase2ServerDiagnostics"))
local result={passed=#failures==0 and activeSigns==17,candidate=c.Name,revision=c:GetAttribute("CandidateRevision"),seconds=28,signs=#signs,activeSigns=activeSigns,rows=rows,failures=failures,serverDiagnostics=diagnostics,
	boundary="Native server samples of actual source states and dock windows; all 17 displayed states/actions checked across live cycles. Does not certify human or mobile readability."}
shared.KCP3M03Warning01=result
return game.HttpService:JSONEncode(result)
