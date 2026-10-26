--!strict

-- Walks copies of each physical shoulder along its authored node curve.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local player=game.Players.LocalPlayer
local character=player.Character :: Model
local humanoid=character:FindFirstChildOfClass("Humanoid") :: Humanoid
local root=character:FindFirstChild("HumanoidRootPart") :: BasePart
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local fixtures=game.ReplicatedStorage:WaitForChild("JourneyWalkFixtures")
local initial=character:GetPivot()
local results={}
controls:Disable()
player:SetAttribute("JourneyWalkStatus","Running")
for _,fixture in ipairs(fixtures:GetChildren()) do
	local trial=fixture:Clone()
	local points=game.HttpService:JSONDecode(trial:GetAttribute("Waypoints"))
	local start=Vector3.new(points[1].x,points[1].y,points[1].z)
	local displacement=Vector3.new(0,600,0)-start
	for _,p in ipairs(trial:GetDescendants()) do
		if p:IsA("BasePart") then p.CFrame+=displacement end
	end
	trial.Parent=workspace
	local ok,err=pcall(function()
		character:PivotTo(CFrame.new(start+displacement+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.5,0)))
		root.AssemblyLinearVelocity=Vector3.zero
		humanoid:Move(Vector3.zero)
		local deadline=os.clock()+3
		repeat task.wait() until humanoid.FloorMaterial~=Enum.Material.Air or os.clock()>deadline
		assert(humanoid.FloorMaterial~=Enum.Material.Air,"Start lacks ground")
		for index=2,#points do
			local p=points[index]
			local target=Vector3.new(p.x,p.y,p.z)+displacement
			local from=root.Position
			deadline=os.clock()+5
			repeat
				local delta=(target-root.Position)*Vector3.new(1,0,1)
				if delta.Magnitude<1 then break end
				humanoid:Move(delta.Unit)
				task.wait()
				assert(root.Position.Y>math.min(from.Y,target.Y)-4,"Fell below the walking curve at node "..index)
			until os.clock()>deadline
			assert(((root.Position-target)*Vector3.new(1,0,1)).Magnitude<1.2,"Could not reach curve node "..index)
		end
		humanoid:Move(Vector3.zero)
	end)
	humanoid:Move(Vector3.zero)
	table.insert(results,{case=fixture.Name,passed=ok,error=if ok then nil else tostring(err),nodes=#points,walkSpeed=humanoid.WalkSpeed})
	trial:Destroy()
end
character:PivotTo(initial)
root.AssemblyLinearVelocity=Vector3.zero
controls:Enable()
player:SetAttribute("JourneyWalkResults",game.HttpService:JSONEncode(results))
local passed=true
for _,r in ipairs(results) do if not r.passed then passed=false end end
player:SetAttribute("JourneyWalkStatus",if passed then "Passed" else "Failed")
