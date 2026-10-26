--!strict
local player=game.Players.LocalPlayer
local reply=game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="KeyboardCircuitTest"})
assert(reply.ok,reply.message)
local deadline=os.clock()+15
repeat task.wait(.1) until player.PlayerGui:FindFirstChild("KeyboardCircuitPhase2Lap") or os.clock()>deadline
local gui=assert(player.PlayerGui:FindFirstChild("KeyboardCircuitPhase2Lap"))
local label=gui.Progress
local cases={"Lap 1 / 2\nCheckpoints 0 / 7","Lap 2 / 2\nCheckpoints 7 / 7","Lap 1 / 2\nReturn to start","Course complete\n2 laps finished"}
local clones,rows={},{}
for _,width in {205,320} do for _,value in cases do
	local clone=label:Clone()
	clone.AnchorPoint=Vector2.zero
	clone.Position=UDim2.fromOffset(-1000,-1000)
	clone.Size=UDim2.fromOffset(width,58)
	clone.Text=value
	clone.Parent=gui
	table.insert(clones,clone)
end end
task.wait(.15)
local failures={}
for _,clone in clones do
	table.insert(rows,{text=clone.Text,width=clone.AbsoluteSize.X,height=clone.AbsoluteSize.Y,bounds=tostring(clone.TextBounds),fits=clone.TextFits})
	if not clone.TextFits then table.insert(failures,clone.Text) end
	clone:Destroy()
end
local result={passed=#failures==0,candidate=player:GetAttribute("KCPhase2Candidate"),text=label.Text,textFits=label.TextFits,ascii=label.Text:find("[^\1-\127]")==nil,narrowCases=rows,failures=failures,reply=reply}
assert(result.candidate=="KeyboardCircuit_P3_M02_01" and result.ascii and result.textFits)
shared.KCP3M02Hud01=result
return game.HttpService:JSONEncode(result)
