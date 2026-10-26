--!strict
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local c = workspace.KeyboardCircuit_P3_M02_01
local Art, Mechanisms, Motion = require(c.SourceSnapshot.EnvironmentParts), require(c.SourceSnapshot.Mechanisms), require(c.SourceSnapshot.Motion)
local artwork = {}
for _, item in c.MapEnvironment:GetDescendants() do if item:IsA("BasePart") and item.Transparency < .9 then table.insert(artwork, item) end end
local failures, records = {}, {}
for _, unit in c.Districts:GetDescendants() do
	if not unit:IsA("Model") or not unit:GetAttribute("MechanismKind") then continue end
	local kind, frame = unit:GetAttribute("MechanismKind"), Mechanisms.GetFrame(unit)
	local overrides = {}
	for name, value in unit:GetAttributes() do if name:sub(1,7) == "Timing_" then overrides[name:sub(8)] = value end end
	local tuning = Motion.Tuning(kind, overrides)
	for _, actor in unit:GetDescendants() do
		if not actor:IsA("Model") or not actor:GetAttribute("KCMover") then continue end
		local rest, pivot = actor:GetPivot(), actor:GetAttribute("MotionPivot")
		local localPose = actor:GetAttribute("MotionLocal")
		local function destination(alpha: number): CFrame
			if kind == "Seesaws" then return rest * CFrame.Angles(0,0,math.rad(tuning.MaxAngle)*(alpha*2-1)) end
			if kind == "Fallaway" or kind == "Foundry" then return rest + frame:VectorToWorldSpace(Vector3.new(0,-tuning.DropDistance*alpha,0)) end
			if kind == "Lift" then return rest + frame:VectorToWorldSpace(Vector3.new(0,tuning.Travel*alpha,0)) end
			if kind == "Shuttle" then return rest + frame:VectorToWorldSpace(Vector3.new(tuning.Travel*alpha,0,0)) end
			if kind == "Sweep" then return pivot * CFrame.Angles(0,math.rad(tuning.Angle)*alpha,0) * localPose end
			if kind == "Domino" then return pivot * CFrame.Angles(0,0,-math.rad(tuning.Angle)*alpha) * localPose end
			return rest + frame:VectorToWorldSpace(Vector3.new(0,0,actor:GetAttribute("RetractDirection")*tuning.Travel*alpha))
		end
		local physical = {}
		for _, part in actor:GetDescendants() do
			if part:IsA("BasePart") and (part.CanCollide or part:GetAttribute("Role")=="Lethal") then table.insert(physical,part) end
		end
		local steps = 100
		local checked = 0
		for _, part in physical do
			local relative = rest:ToObjectSpace(part.CFrame)
			local radius = part.Size.Magnitude/2 + (part.Position-(pivot or rest).Position).Magnitude
			local speed = if kind=="Sweep" or kind=="Domino" then radius*math.rad(tuning.Angle)
				elseif kind=="Seesaws" then radius*math.rad(tuning.MaxAngle*2)
				elseif kind=="Foundry" or kind=="Fallaway" then tuning.DropDistance else tuning.Travel
			local padding = speed/(steps*2) + (if kind=="Fallaway" then .045 else .02)
			for index=0,steps do
				local pose = destination(index/steps)*relative
				local size = part.Size + Vector3.one*(padding*2)
				for _, art in artwork do
					if (art.Position-pose.Position).Magnitude > art.Size.Magnitude/2+size.Magnitude/2 then continue end
					checked += 1
					if Art.Overlaps(pose,size,art.CFrame,art.Size) then
						if #failures < 25 then table.insert(failures,{mechanism=unit:GetAttribute("MechanismId"),actor=actor.Name,part=part.Name,alpha=index/steps,art=art:GetFullName(),padding=padding}) end
					end
				end
			end
		end
		table.insert(records,{mechanism=unit:GetAttribute("MechanismId"),actor=actor.Name,physicalParts=#physical,samples=steps+1,narrowChecks=checked})
	end
end
local result={passed=#failures==0,failures=failures,actors=records,candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),
	boundary="Native Edit geometric inspection, no actor moved. Complete alpha range for all eight mechanisms. Each sample box is enlarged by the maximum intervening translation or rotation travel, plus Fallaway shake. OBB comparisons cover continuous authored swept volumes conservatively, not engine performance or crowd tests."}
shared.KCP3M02MotionClearance01=result
return game.HttpService:JSONEncode(result)
