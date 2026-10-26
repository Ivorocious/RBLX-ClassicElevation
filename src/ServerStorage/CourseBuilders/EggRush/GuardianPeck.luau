--!nonstrict
local GuardianPeck = {}
local UP = Vector3.yAxis
local AMBER = Color3.fromRGB(255, 190, 40)
local CHARCOAL = Color3.fromRGB(62, 66, 72)
local STATE_ATTRIBUTES = { "ERState", "ERPeckTarget", "ERStrike" }

local function smooth(value)
	return value * value * (3 - 2 * value)
end

function GuardianPeck.Sample(settings, elapsed, targetCount)
	local duration = settings.rest + settings.warning + settings.strike + settings.impact + settings.recover
	local time = elapsed + (settings.phase or 0)
	local target = math.floor(time / duration) % targetCount + 1
	time %= duration
	for _, segment in {
		{ settings.rest, "Rest" }, { settings.warning, "Warning" },
		{ settings.strike, "Pecking" }, { settings.impact, "Impact" }, { settings.recover, "Recovering" },
	} do
		if time < segment[1] then
			return {
				target = target, state = segment[2], alpha = time / segment[1],
				lethal = segment[2] == "Pecking" or segment[2] == "Impact",
			}
		end
		time -= segment[1]
	end
	return { target = target, state = "Rest", alpha = 0, lethal = false }
end

function GuardianPeck.StrikeFrame(anchor, target, beakTip)
	local horizontal = (target - anchor) * Vector3.new(1, 0, 1)
	local direction = horizontal.Unit * math.cos(math.rad(55)) - UP * math.sin(math.rad(55))
	local rotation = CFrame.lookAt(Vector3.zero, direction).Rotation
	return CFrame.new(target - rotation:VectorToWorldSpace(beakTip)) * rotation
end

function GuardianPeck.Elbow(anchor, endPoint, length, bendSide)
	-- Both neck links keep their authored length as the joint bends toward the target.
	local span = endPoint - anchor
	local direction = span.Unit
	local bend = bendSide - direction * bendSide:Dot(direction)
	assert(span.Magnitude < length * 2 and bend.Magnitude > .01, "Peck neck needs reachable authored poses")
	return (anchor + endPoint) / 2 + bend.Unit * math.sqrt(length * length - span.Magnitude ^ 2 / 4)
end

local function attribute(model, name, fallback)
	local value = model:GetAttribute(name)
	if value == nil then value = fallback end
	assert(typeof(value) == "number" and value > 0, "Peck needs positive " .. name)
	return value
end

function GuardianPeck.Bind(model, course)
	if model:GetAttribute("ChickenRevision") == "R04" or model:GetAttribute("ChickenRevision") == "R05" then
		return require(script.Parent.ChickenPeck).Bind(model,course,GuardianPeck.Sample)
	end
	local head = assert(model:FindFirstChild("Head"), "Peck needs Head")
	local lower, upper = model:FindFirstChild("NeckLower"), model:FindFirstChild("NeckUpper")
	assert(head:IsA("Model") and lower and lower:IsA("BasePart") and upper and upper:IsA("BasePart"), "Peck needs two neck links")
	local frame = model:GetPivot()
	local localAnchor, tip, headNeck = model:GetAttribute("NeckAnchor"), head:GetAttribute("BeakTip"), head:GetAttribute("HeadNeck")
	assert(typeof(localAnchor) == "Vector3" and typeof(tip) == "Vector3" and typeof(headNeck) == "Vector3", "Peck needs authored neck and beak attachments")
	local anchor = frame:PointToWorldSpace(localAnchor)
	local bendSide = frame:VectorToWorldSpace(model:GetAttribute("BendSide") or UP)
	local length = model:GetAttribute("NeckLinkLength") or lower.Size.Y
	assert(math.abs(lower.Size.Y-length) < .01 and math.abs(upper.Size.Y-length) < .01, "Peck neck links must match authored length")
	local settings = {
		rest = attribute(model, "RestSeconds", 2.2), warning = attribute(model, "WarningSeconds", 1.8),
		strike = attribute(model, "StrikeSeconds", .55), impact = attribute(model, "ImpactSeconds", .3),
		recover = attribute(model, "RecoverSeconds", .9), phase = model:GetAttribute("PhaseSeconds") or 0,
	}
	local home = head:GetPivot()
	local targets, poses = {}, {}
	local refs = assert(model:FindFirstChild("Targets"), "Peck needs ordered targets"):GetChildren()
	table.sort(refs, function(a,b) return a.Name < b.Name end)
	local parts, contacts, attributes = {}, {}, {}
	for _, name in STATE_ATTRIBUTES do attributes[name] = { value = model:GetAttribute(name) } end
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		assert(part.Anchored and not part.CanCollide, "Peck art must be anchored and cannot fling players")
		table.insert(parts, { part = part, frame = part.CFrame })
		if part:GetAttribute("ERLethal") == true then
			assert(part:IsDescendantOf(head) and part.CanQuery and part.Transparency < 1, "Only visible head beak geometry may be lethal")
			table.insert(contacts, part)
		end
	end
	assert(#contacts > 0 and #refs >= 1, "Peck needs a visible beak and targets")
	local homeEnd = home:PointToWorldSpace(headNeck)
	GuardianPeck.Elbow(anchor, homeEnd, length, bendSide)
	local speed = 0
	for _, ref in refs do
		assert(ref:IsA("ObjectValue") and ref.Value and ref.Value:IsA("BasePart"), "Peck target must reference a fixed plate")
		local plate = ref.Value
		assert(plate:IsDescendantOf(course) and not plate:IsDescendantOf(model) and plate.Transparency < 1
			and plate:GetAttribute("ERLethal") ~= true, "Peck warning plate must stay visible, fixed and nonlethal")
		local point = plate.Position + UP * (plate.Size.Y / 2 + .25)
		local strike = GuardianPeck.StrikeFrame(anchor, point, tip)
		local aim = strike + UP * 12
		local sound = plate:FindFirstChild("WarningSound")
		if sound then assert(sound:IsA("Sound") and not sound.IsPlaying, "Peck cue needs an idle Sound") end
		table.insert(targets, { plate = plate, color = plate.Color, sound = sound,
			looped = sound and sound.Looped, soundTime = sound and sound.TimePosition })
		table.insert(poses, { aim = aim, strike = strike })
		for index = 0, 20 do
			local alpha = index / 20
			GuardianPeck.Elbow(anchor, home:Lerp(aim,alpha):PointToWorldSpace(headNeck),length,bendSide)
			GuardianPeck.Elbow(anchor, aim:Lerp(strike,alpha):PointToWorldSpace(headNeck),length,bendSide)
			GuardianPeck.Elbow(anchor, strike:Lerp(home,alpha):PointToWorldSpace(headNeck),length,bendSide)
		end
		speed = math.max(speed, 12 * 2 / settings.strike,
			((home.Position-aim.Position).Magnitude + 30) * 2 / settings.warning,
			((strike.Position-home.Position).Magnitude + 30) * 2 / settings.recover)
	end
	local controller = { model = model, state = nil, target = nil, contacts = contacts, parts = parts }
	local function stopSounds()
		for _, target in targets do if target.sound then target.sound:Stop() end end
	end
	function controller.Hold()
		stopSounds()
	end
	function controller.Resume()
		if controller.state == "Warning" then
			local sound = targets[controller.target].sound
			if sound then sound:Play() end
		end
	end
	function controller.Stop()
		stopSounds()
		if head.Parent then head:PivotTo(home) end
		for _, saved in parts do if saved.part.Parent then saved.part.CFrame = saved.frame end end
		if model.Parent then for name, saved in attributes do model:SetAttribute(name,saved.value) end end
		for _, target in targets do
			if target.plate.Parent then target.plate.Color = target.color end
			if target.sound and target.sound.Parent then
				target.sound.Looped, target.sound.TimePosition = target.looped, target.soundTime
			end
		end
	end
	function controller.Advance(oldElapsed, dt, contact, hasBodies)
		assert(model:IsDescendantOf(course), "Peck rig left its course")
		local steps = if hasBodies then math.max(1,math.ceil(speed*dt/.4),math.ceil(dt*30)) else 1
		local final
		for step = 1, steps do
			local sample = GuardianPeck.Sample(settings,oldElapsed+dt*step/steps,#targets)
			local pose = poses[sample.target]
			local nextFrame = home
			if sample.state == "Warning" then nextFrame = home:Lerp(pose.aim,smooth(sample.alpha))
			elseif sample.state == "Pecking" then nextFrame = pose.aim:Lerp(pose.strike,sample.alpha*sample.alpha)
			elseif sample.state == "Impact" then nextFrame = pose.strike
			elseif sample.state == "Recovering" then nextFrame = pose.strike:Lerp(home,smooth(sample.alpha)) end
			head:PivotTo(nextFrame)
			local endPoint = nextFrame:PointToWorldSpace(headNeck)
			local elbow = GuardianPeck.Elbow(anchor,endPoint,length,bendSide)
			lower.CFrame = CFrame.lookAt((anchor+elbow)/2,elbow) * CFrame.Angles(-math.pi/2,0,0)
			upper.CFrame = CFrame.lookAt((elbow+endPoint)/2,endPoint) * CFrame.Angles(-math.pi/2,0,0)
			if sample.lethal then for _, part in contacts do contact(part,"EggRush:ChickenPeck") end end
			final = sample
		end
		if final.state ~= controller.state or final.target ~= controller.target then
			controller.state, controller.target = final.state, final.target
			model:SetAttribute("ERState",final.state)
			model:SetAttribute("ERPeckTarget",final.target)
			model:SetAttribute("ERStrike",final.lethal)
			stopSounds()
			for index, target in targets do
				target.plate.Color = if index == final.target and (final.state == "Warning" or final.lethal) then AMBER else CHARCOAL
			end
			if final.state == "Warning" then
				local sound = targets[final.target].sound
				if sound then sound.Looped = true; sound:Play() end
			end
		end
		return steps
	end
	return controller
end

return GuardianPeck
