local Test = {}

function Test.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local lower = workspace.Lobby.Editable["01_Lower"]
	local records = {}
	for _, name in {"Lower_Board_Wins", "Bench_0_-29", "Gardens_Tree_07", "Stairs_Stair_01", "Lower_Slab_01"} do
		local source = lower:FindFirstChild(name)
		assert(source and source:IsA("Model"), "Missing editable object "..name)
		local clone = source:Clone()
		clone.Name, clone.Parent = "EditingTestFixture", game.ServerStorage
		local pivot = clone:GetPivot()
		local parts, collisionCount, seatCount = {}, 0, 0
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(parts, {part=part, frame=pivot:ToObjectSpace(part.CFrame), size=part.Size})
				if part:GetAttribute("LobbyCollision") then collisionCount+=1 end
				if part:IsA("Seat") then seatCount+=1 end
			end
		end
		local target = pivot * CFrame.new(8,3,-6) * CFrame.Angles(0,math.rad(25),0)
		clone:PivotTo(target)
		clone:ScaleTo(clone:GetScale()*1.1)
		local maxError = 0
		for _, entry in parts do
			local frame=entry.frame
			local expected=target*(frame.Rotation+CFrame.new(frame.Position*1.1).Position)
			maxError=math.max(maxError,(entry.part.Position-expected.Position).Magnitude,(entry.part.Size-entry.size*1.1).Magnitude)
		end
		table.insert(records,{name=name,parts=#parts,colliders=collisionCount,seats=seatCount,maxError=maxError,passed=#parts>0 and collisionCount>0 and maxError<.001})
		clone:Destroy()
	end
	return {revision=workspace.Lobby:GetAttribute("BlenderRevision"),records=records}
end

return Test
