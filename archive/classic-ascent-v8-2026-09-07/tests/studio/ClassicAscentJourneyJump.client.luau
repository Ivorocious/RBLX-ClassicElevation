--!strict

-- Uses copies of authored collision surfaces and a real, client-owned character in an isolated Studio area.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local character = player.Character :: Model
local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
local controls = require(player.PlayerScripts.PlayerModule):GetControls()
local fixtures = game.ReplicatedStorage:WaitForChild("JourneyJumpFixtures")
local results = {}
local initial=character:GetPivot()
local jumpingEnabled=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
controls:Disable()
player:SetAttribute("JourneyJumpStatus","Running")
player:SetAttribute("JourneyJumpCompleted",0)
player:SetAttribute("JourneyJumpTotal",#fixtures:GetChildren())
player:SetAttribute("JourneyJumpLastFailure",nil)

local function edge(p: BasePart, d: Vector3, anchor: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {p}
	local radius = p.Size.Magnitude+5
	local origin = anchor-Vector3.new(0,.08,0)+d*radius
	local hit = workspace:Raycast(origin,-d*radius*2,params)
	assert(hit,"No launch edge")
	return (hit.Position-anchor):Dot(d)
end

for _,fixture in ipairs(fixtures:GetChildren()) do
	local trial = fixture:Clone()
	local a,b = trial.From :: BasePart,trial.To :: BasePart
	local displacement = Vector3.new(0,600,0)-a.Position
	a.CFrame += displacement
	b.CFrame += displacement
	trial.Parent = workspace
	local walkingRejected: boolean? = nil
	local ok,err = pcall(function()
		local sourceAnchor=trial:GetAttribute("SourceAnchor")
		local targetAnchor=trial:GetAttribute("TargetAnchor")
		local anchor=if typeof(sourceAnchor)=="Vector3" then sourceAnchor+displacement else a.Position+Vector3.new(0,a.Size.Y/2,0)
		if typeof(sourceAnchor)~="Vector3" and a:GetAttribute("SharedCheckpoint") then
			local relative = a.CFrame:PointToObjectSpace(b.Position)
			anchor = (a.CFrame*CFrame.new(math.clamp(relative.X,-a.Size.X/2+2,a.Size.X/2-2),a.Size.Y/2,0)).Position
		end
		local target=if typeof(targetAnchor)=="Vector3" then targetAnchor+displacement else b.Position+Vector3.new(0,b.Size.Y/2,0)
		local d = ((target-anchor)*Vector3.new(1,0,1)).Unit
		local measuredEdge=trial:GetAttribute("TakeoffEdge")
		local launch=if typeof(measuredEdge)=="number" then measuredEdge else edge(a,d,anchor)
		local back=edge(a,-d,anchor)
		local startPoint=anchor-d*math.max(0,back-1.25)
		local function placeAtStart()
			character:PivotTo(CFrame.new(startPoint.X,anchor.Y+humanoid.HipHeight+root.Size.Y/2+.5,startPoint.Z))
			root.AssemblyLinearVelocity = Vector3.zero
			humanoid:Move(Vector3.zero)
			local deadline = os.clock()+3
			repeat task.wait() until (humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<1) or os.clock()>deadline
			assert(humanoid.FloorMaterial~=Enum.Material.Air,"Source not grounded")
		end
		placeAtStart()
		if trial:GetAttribute("RequireJump") then
			humanoid.Jump=false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
			local deadline=os.clock()+3
			local walkParams=RaycastParams.new()
			walkParams.FilterType=Enum.RaycastFilterType.Include
			walkParams.FilterDescendantsInstances={b}
			local reached=false
			repeat
				humanoid:Move(d)
				task.wait()
				local hit=workspace:Raycast(root.Position,Vector3.new(0,-humanoid.HipHeight-root.Size.Y/2-.3,0),walkParams)
				reached=hit~=nil and humanoid.FloorMaterial~=Enum.Material.Air
			until reached or root.Position.Y<math.min(anchor.Y,target.Y)-4 or os.clock()>deadline
			walkingRejected=not reached and (root.Position-startPoint):Dot(d)>1
			assert(walkingRejected,string.format("Walking check failed: reached=%s, travel=%.2f, height=%.2f, floor=%s",tostring(reached),(root.Position-startPoint):Dot(d),root.Position.Y-anchor.Y,humanoid.FloorMaterial.Name))
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,jumpingEnabled)
			placeAtStart()
		end
		local deadline = os.clock()+2
		repeat humanoid:Move(d);task.wait() until (root.Position-anchor):Dot(d)>=launch-.6 or os.clock()>deadline
		assert(humanoid.FloorMaterial~=Enum.Material.Air,"Approach ran off edge")
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local left = false
		deadline = os.clock()+2
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {b}
		repeat
			local remaining=(target-root.Position)*Vector3.new(1,0,1)
			humanoid:Move(if remaining.Magnitude>1 then remaining.Unit else Vector3.zero)
			task.wait()
			if humanoid.FloorMaterial==Enum.Material.Air then left=true end
			local hit = workspace:Raycast(root.Position,Vector3.new(0,-humanoid.HipHeight-root.Size.Y/2-.3,0),params)
			if left and hit and humanoid.FloorMaterial~=Enum.Material.Air then
				humanoid:Move(Vector3.zero)
				return
			end
		until os.clock()>deadline
		error("No grounded target landing; floor="..humanoid.FloorMaterial.Name)
	end)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,jumpingEnabled)
	humanoid:Move(Vector3.zero)
	table.insert(results,{case=fixture.Name,passed=ok,error=if ok then nil else tostring(err),walkSpeed=humanoid.WalkSpeed,jumpPower=humanoid.JumpPower,jumpHeight=humanoid.JumpHeight,useJumpPower=humanoid.UseJumpPower,aimsAtLanding=true,walkingRejected=walkingRejected})
	player:SetAttribute("JourneyJumpCompleted",#results)
	if not ok then player:SetAttribute("JourneyJumpLastFailure",fixture.Name..": "..tostring(err)) end
	trial:Destroy()
end

character:PivotTo(initial)
root.AssemblyLinearVelocity=Vector3.zero
controls:Enable()
player:SetAttribute("JourneyJumpResults",game.HttpService:JSONEncode(results))
local passed = true
for _,r in ipairs(results) do if not r.passed then passed=false end end
player:SetAttribute("JourneyJumpStatus",if passed then "Passed" else "Failed")
