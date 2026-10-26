--!strict
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config.OnboardingConfig)
local View = require(script.Parent.ArrivalView)
local Stage = {}
-- Roblox-owned R15 wave from the default Animate script.
local WAVE_ANIMATION = "rbxassetid://507770239"
local WAVE_SECONDS, WAVE_FADE = 2.2, 0.3
local RIM_DIM, RIM_BRIGHT = Color3.fromRGB(52, 196, 232), Color3.fromRGB(160, 240, 255)

local function part(parent, name, size, frame, color)
	return View.Make("Part", name, parent, {Size = size, CFrame = frame, Color = color,
		Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
		Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth})
end

local function cylinder(parent, name, radius, thickness, frame, color)
	local item = part(parent, name, Vector3.new(thickness, radius * 2, radius * 2),
		frame * CFrame.Angles(0, 0, math.pi / 2), color)
	item.Shape = Enum.PartType.Cylinder
	return item
end

local function capsule(parent, name, y, thickness, inset, color)
	local radius = 2.65 - inset
	local parts = {part(parent, name, Vector3.new(8, thickness, radius * 2), CFrame.new(0, y, 0), color)}
	for _, x in {-4, 4} do table.insert(parts, cylinder(parent, name .. "End", radius, thickness, CFrame.new(x, y, 0), color)) end
	return parts
end

-- Soft light cone (assets/ui/arrival/make_spotlight.py), drawn in 2D behind the stage viewport
-- because viewports cannot render light beams.
local SPOTLIGHT = "rbxassetid://124386135480378"
local SPOTLIGHT_TINT = Color3.fromRGB(196, 238, 255)

local function floorRing(parent, name, x)
	local model = View.Make("Model", name, parent)
	local items = {}
	for index = 1, 18 do
		local angle = index * math.pi / 9
		local arc = part(model, "Arc", Vector3.new(0.68, 0.02, 0.07), CFrame.new(x + math.sin(angle) * 1.95, 0.066, math.cos(angle) * 1.95) * CFrame.Angles(0, angle, 0), View.Cyan)
		arc.Material = Enum.Material.Neon
		table.insert(items, arc)
	end
	return items
end

-- Block racer in the creator's starting colours, shown until the real model loads (or if it cannot).
local function blankRacer()
	local model = View.Dummy()
	local function color(rgb) return Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end
	local skin, top, legs = color(Config.Skin[Config.DefaultLook.skin]), color(Config.Colors[Config.DefaultLook.top]), color(Config.Colors[Config.DefaultLook.legs])
	for _, limb in model:GetChildren() do
		if limb:IsA("BasePart") then limb.Color = if limb.Name == "Torso" then top elseif limb.Name == "Leg" then legs else skin end
	end
	local torso = model.Torso
	for _, limb in model:GetChildren() do
		if limb:IsA("BasePart") and limb ~= torso then
			local name, anchor = "Neck", Vector3.new(0, 4, 0)
			if limb.Name == "Arm" then
				local right = limb.Position.X > 0
				-- Straight arms pivoting on their own centre line: idle poses stay below the shoulders and a raised wave clears the head.
				limb.CFrame = CFrame.new(if right then 1.5 else -1.5, 3, 0)
				name, anchor = if right then "RightShoulder" else "LeftShoulder", Vector3.new(if right then 1.5 else -1.5, 3.5, 0)
				limb.Name = if right then "RightArm" else "LeftArm"
			elseif limb.Name == "Leg" then
				local right = limb.Position.X > 0
				name, anchor = if right then "RightHip" else "LeftHip", Vector3.new(if right then 0.52 else -0.52, 2, 0)
				limb.Name = if right then "RightLeg" else "LeftLeg"
			end
			View.Make("Motor6D", name, torso, {Part0 = torso, Part1 = limb,
				C0 = torso.CFrame:ToObjectSpace(CFrame.new(anchor)), C1 = limb.CFrame:ToObjectSpace(CFrame.new(anchor))})
		end
	end
	model:ScaleTo(1.06)
	return model
end

-- All preview parts stay anchored. Solve the joint tree explicitly so accessories follow poses too.
-- An Animator only writes joint Transforms here, so the solver reads them back while a wave plays.
local function bind(model, x, yaw)
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
	assert(root and root:IsA("BasePart"), "Preview needs a character root")
	local bottom = math.huge
	local joints, ordered = {}, {}
	local probe = nil
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
			if item.Parent == model and item.Name ~= "HumanoidRootPart" and item.Name ~= "CollisionPart" then
				bottom = math.min(bottom, item.Position.Y - item.Size.Y / 2)
			end
		elseif (item:IsA("Motor6D") or item:IsA("Weld")) and item.Part0 and item.Part1 then
			local motor = if item:IsA("Motor6D") then item else nil
			if motor and item.Name == "RightShoulder" then probe = motor end
			table.insert(joints, {Name = item.Name, Part0 = item.Part0, Part1 = item.Part1,
				C0 = item.C0, C1 = item.C1, animated = motor ~= nil, motor = motor})
		elseif item:IsA("AnimationConstraint") and item.Attachment0 and item.Attachment1 then
			local a, b = item.Attachment0, item.Attachment1
			local p0, p1 = a:FindFirstAncestorWhichIsA("BasePart"), b:FindFirstAncestorWhichIsA("BasePart")
			if p0 and p1 then
				if item.Name == "RightShoulder" then probe = item end
				table.insert(joints, {Name = item.Name, Part0 = p0, Part1 = p1,
					C0 = p0.CFrame:ToObjectSpace(a.WorldCFrame), C1 = p1.CFrame:ToObjectSpace(b.WorldCFrame), animated = true, motor = item})
			end
		elseif item:IsA("Script") or item:IsA("LocalScript") then item:Destroy() end
	end
	local found = {[root] = true}
	for _ = 1, #joints do
		local advanced = false
		for _, joint in joints do
			if found[joint.Part0] ~= found[joint.Part1] then
				local forward = found[joint.Part0] == true
				local child = if forward then joint.Part1 else joint.Part0
				found[child] = true
				table.insert(ordered, {joint = joint, forward = forward})
				advanced = true
			end
		end
		if not advanced then break end
	end
	return {model = model, root = root, joints = ordered, x = x, yaw = yaw,
		base = CFrame.new(0, 0.12 - bottom, 0) * root.CFrame, probe = probe,
		track = nil :: AnimationTrack?, waveStarted = nil :: number?, animationWorks = false}
end

local function pose(rig, time, phase, motion, focus)
	local breathe = if motion then math.sin(time * 1.25 + phase) else 0
	local shift = if motion then math.sin(time * 0.62 + phase) else 0
	local glance = if motion then math.sin(time * 0.38 + phase) else 0
	local age = time - (rig.waveStarted or -100)
	-- Once the Animator is known to drive this rig, its wave replaces the hand-made one.
	local animated = motion and rig.animationWorks and rig.track ~= nil and age < WAVE_SECONDS + WAVE_FADE + 0.1
	local wave = if motion and not animated and age < 2.5 then math.sin(math.pi * math.clamp(age / 2.5, 0, 1)) ^ 0.65 else 0
	local bounce = if motion and age < 2.5 then math.abs(math.sin(age * math.pi * 2)) * math.exp(-age * 1.25) * 0.65 else 0
	local rock = math.sin(age * 7) * wave
	local energy = if motion then focus else 0
	rig.root.CFrame = CFrame.new(rig.x + shift * 0.025 + rock * 0.10, breathe * 0.008 + bounce + energy * (1 + math.sin(time * 3)) * 0.025, -energy * 0.6)
		* CFrame.Angles(math.rad(-wave * 3), rig.yaw + focus * 0.12 + rock * 0.07, math.rad(rock * 4)) * rig.base
	for _, record in rig.joints do
		local joint, delta = record.joint, CFrame.identity
		if joint.animated then
			if joint.Name == "Neck" then
				delta = CFrame.Angles(math.rad(breathe * 0.8 - wave * 6), math.rad(glance * 2.2 + rock * 5), math.rad(shift * 0.8 - rock * 4))
			elseif joint.Name == "Waist" then
				delta = CFrame.Angles(math.rad(breathe * 0.65), 0, math.rad(shift * 0.6))
			elseif joint.Name == "RightShoulder" or joint.Name == "LeftShoulder" then
				local side = if joint.Name == "RightShoulder" then 1 else -1
				delta = CFrame.Angles(math.rad(breathe * 1.8), 0, math.rad(side * (4 + shift * 1.4)))
				if side == 1 then delta *= CFrame.Angles(math.rad(-20 * wave), math.rad(rock * 12), math.rad((150 + math.sin(age * 17) * 20) * wave))
				else delta *= CFrame.Angles(math.rad(rock * 5), 0, math.rad(-6 * wave)) end
			elseif joint.Name == "RightElbow" then
				delta = CFrame.Angles(math.rad(-30 * wave), 0, 0)
			elseif joint.Name == "RightHip" or joint.Name == "LeftHip" then
				local side = if joint.Name == "RightHip" then 1 else -1
				delta = CFrame.Angles(math.rad(side * bounce * 16), 0, math.rad(side * bounce * 9))
			end
			if animated and joint.motor then delta = joint.motor.Transform * delta end
		end
		if record.forward then
			joint.Part1.CFrame = joint.Part0.CFrame * joint.C0 * delta * joint.C1:Inverse()
		else
			joint.Part0.CFrame = joint.Part1.CFrame * joint.C1 * delta:Inverse() * joint.C0:Inverse()
		end
	end
end

function Stage.Create(parent)
	local viewport = View.Make("ViewportFrame", "SharedStage", parent, {BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 160, 182), LightColor = Color3.fromRGB(255, 247, 228),
		LightDirection = Vector3.new(-0.6, -1, 2)})
	local world = View.Make("WorldModel", "StageWorld", viewport)
	local camera = View.Make("Camera", "StageCamera", viewport, {FieldOfView = 32})
	viewport.CurrentCamera = camera
	local platform = View.Make("Model", "SharedPlatform", world)
	capsule(platform, "Base", -0.34, 0.5, 0, Color3.fromRGB(14, 19, 31))
	local rim = capsule(platform, "LightSeam", -0.10, 0.085, -0.03, RIM_DIM)
	for _, item in rim do item.Material = Enum.Material.Neon end
	capsule(platform, "StudSurface", -0.035, 0.075, 0.025, Color3.fromRGB(35, 44, 64))
	for x = -6, 6, 0.75 do
		for z = -1.8, 1.8, 0.75 do
			local edge = math.max(0, math.abs(x) - 4)
			if edge * edge + z * z < 2.35 ^ 2 then
				cylinder(platform, "Stud", 0.115, 0.035, CFrame.new(x, 0.025, z), Color3.fromRGB(62, 71, 94))
			end
		end
	end
	local floorLights, beams, rings = {}, {}, {}
	local lights = View.Make("Model", "Spotlights", world)
	-- Cones sit just behind the viewport (same parent, lower ZIndex) so racers stand in front of the light.
	viewport.ZIndex = 2
	for index, x in {3.1, -3.1} do
		local light = cylinder(platform, "SelectionLight" .. index, 1.85, 0.012, CFrame.new(x,0.049,0), View.Cyan)
		light.Transparency = 1
		floorLights[index] = light
		beams[index] = View.Make("ImageLabel", "Spotlight" .. index, parent, {Image = SPOTLIGHT, ImageColor3 = SPOTLIGHT_TINT,
			BackgroundTransparency = 1, ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), ScaleType = Enum.ScaleType.Stretch, ZIndex = 1})
		rings[index] = floorRing(lights, "FloorRing" .. index, x)
	end
	local rigs = {}
	for index, x in {3.1, -3.1} do
		local model = blankRacer()
		model.Name = if index == 1 then "BlankRacer" else "AvatarPlaceholder"
		model.Parent = world
		rigs[index] = bind(model, x, if index == 1 then -0.24 else 0.24)
		pose(rigs[index], 0, index * 2.1, false, 0)
	end
	local waveAnimation = View.Make("Animation", "Wave", nil, {AnimationId = WAVE_ANIMATION})
	task.spawn(pcall, ContentProvider.PreloadAsync, ContentProvider, {waveAnimation})
	-- Screen-space shades dim the racer that is not chosen without touching avatar materials.
	-- The canvas group fades the sides and the inner fill fades top and bottom, so no edge shows.
	local shades = {}
	local function fade(rotation)
		return {Rotation = rotation, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.22, 0), NumberSequenceKeypoint.new(0.78, 0), NumberSequenceKeypoint.new(1, 1)})}
	end
	for index = 1, 2 do
		local shade = View.Make("CanvasGroup", "Dim" .. index, viewport, {BackgroundTransparency = 1, GroupTransparency = 1, Visible = false})
		View.Make("UIGradient", "SideFade", shade, fade(0))
		local fill = View.Make("Frame", "Fill", shade, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(1, 3, 9), BorderSizePixel = 0})
		View.Make("UIGradient", "Fade", fill, fade(90))
		shades[index] = shade
	end
	-- The creation bonus badge floats just above the left racer's head.
	local bonusPoint = Vector3.new(3.1, 5.95, 0)
	local bonusAnchor = Vector2.zero
	local time, accumulated, focused = 0, 0, 0
	local generations = {0, 0}
	local motion = true
	local level, dim, applied = {0, 0}, {0, 0}, {-1, -1}
	local hitTargets = {}
	for index = 1, 2 do
		hitTargets[index] = View.Make("TextButton", "CharacterTarget" .. index, viewport, {Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Selectable = false})
	end
	local function project(point)
		local localPoint = camera.CFrame:PointToObjectSpace(point)
		local height = viewport.AbsoluteSize.Y
		local scale = height / (2 * math.tan(math.rad(camera.FieldOfView / 2)) * -localPoint.Z)
		return Vector2.new(viewport.AbsoluteSize.X/2 + localPoint.X*scale, height/2 - localPoint.Y*scale)
	end
	local function positionTargets()
		for index, rig in rigs do
			-- A stable envelope prevents the moving hands from repeatedly losing hover.
			local min, max = Vector2.new(math.huge,math.huge), Vector2.new(-math.huge,-math.huge)
			for _, x in {-1.9,1.9} do for _, y in {0.1,6.1} do for _, z in {-0.7,0.7} do
				local p = project(Vector3.new(rig.x+x,y,z))
				min = Vector2.new(math.min(min.X,p.X),math.min(min.Y,p.Y))
				max = Vector2.new(math.max(max.X,p.X),math.max(max.Y,p.Y))
			end end end
			hitTargets[index].Position, hitTargets[index].Size = UDim2.fromOffset(min.X,min.Y), UDim2.fromOffset(max.X-min.X,max.Y-min.Y)
			local floor = project(Vector3.new(rig.x, 0, 0))
			local crown = project(Vector3.new(rig.x, 8.5, 0))
			local offset = viewport.AbsolutePosition - (viewport.Parent :: GuiObject).AbsolutePosition
			local tall = floor.Y - crown.Y
			beams[index].Size = UDim2.fromOffset(tall * 0.9, tall * 1.08)
			beams[index].Position = UDim2.fromOffset(offset.X + floor.X, offset.Y + floor.Y + tall * 0.14)
			local pad, side = (max.Y - min.Y) * 0.08, (max.X - min.X) * 0.25
			shades[index].Position, shades[index].Size = UDim2.fromOffset(min.X - side, min.Y - pad), UDim2.fromOffset(max.X - min.X + side * 2, max.Y - min.Y + pad * 2)
		end
		bonusAnchor = project(bonusPoint)
	end
	local function light(index, on, off)
		local intensity = 0.55 + 0.45 * on - 0.4 * off
		if math.abs(intensity - applied[index]) < 0.004 then return end
		applied[index] = intensity
		beams[index].ImageTransparency = 1 - math.clamp(intensity, 0, 1) * 0.92
		for _, arc in rings[index] do arc.Transparency = 1 - 0.82 * intensity end
		shades[index].GroupTransparency, shades[index].Visible = 1 - 0.6 * off, off > 0.01
	end
	local function draw()
		for index, rig in rigs do pose(rig, time, index * 2.1, motion, if motion then level[index] else 0) end
		local pulse = if motion then 0.5 + 0.5 * math.sin(time * math.pi * 2 / 3.2) else 0.5
		local rimColor = RIM_DIM:Lerp(RIM_BRIGHT, pulse)
		for _, item in rim do item.Color = rimColor end
		for index in rigs do light(index, level[index], dim[index]) end
	end
	local function frameCamera()
		local aspect = math.max(0.4, viewport.AbsoluteSize.X / math.max(1, viewport.AbsoluteSize.Y))
		local distance = math.max(8.1, 15.1 / aspect) / (2 * math.tan(math.rad(16)))
		local target = Vector3.new(0, 2.8, 0)
		camera.CFrame = CFrame.lookAt(target + Vector3.new(0, distance * 0.21, -distance), target)
		positionTargets()
	end
	local function stopWaves()
		for _, rig in rigs do
			if rig.track and rig.track.IsPlaying then rig.track:Stop(0) end
		end
	end
	viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(frameCamera)
	viewport.Destroying:Connect(function() for index in generations do generations[index] += 1 end end)
	frameCamera()
	draw()
	return {
		frame = viewport,
		HitTargets = hitTargets,
		SetFocus = function(index)
			local rig = rigs[index]
			if index ~= focused and rig and time - (rig.waveStarted or -100) > 2.7 then
				rig.waveStarted = time
				if motion and rig.track then pcall(function() rig.track:Play(0.15) end) end
			end
			focused = index
			viewport:SetAttribute("FocusedChoice", index)
			for i, item in floorLights do item.Transparency = if i == index then 0.45 else 1 end
			if not motion then
				for i in level do level[i], dim[i] = if i == index then 1 else 0, if index ~= 0 and i ~= index then 1 else 0 end
				draw()
			end
		end,
		-- Bottom centre of the bonus badge above the left racer, in viewport pixels, with a gentle bob.
		BonusPosition = function()
			return Vector2.new(bonusAnchor.X, bonusAnchor.Y + (if motion then math.sin(time * 2.6) * 4 else 0))
		end,
		SetMotion = function(enabled)
			motion = enabled
			if not enabled then
				stopWaves()
				for i in level do level[i], dim[i] = if i == focused then 1 else 0, if focused ~= 0 and i ~= focused then 1 else 0 end
				draw()
			end
		end,
		Update = function(dt)
			if not motion then return end
			accumulated += math.min(dt, 0.1)
			if accumulated < 1/30 then return end
			local elapsed = accumulated
			accumulated = 0
			time += elapsed
			for index, rig in rigs do
				local rate = math.min(1, elapsed * 5)
				level[index] += ((if focused == index then 1 else 0) - level[index]) * rate
				dim[index] += ((if focused ~= 0 and focused ~= index then 1 else 0) - dim[index]) * rate
				local track = rig.track
				if track and track.IsPlaying then
					if time - (rig.waveStarted or -100) > WAVE_SECONDS then track:Stop(WAVE_FADE) end
					if not rig.animationWorks and rig.probe and rig.probe.Transform ~= CFrame.identity then rig.animationWorks = true end
				end
			end
			draw()
		end,
		-- index 1 is the Create racer side, 2 (default) your avatar.
		SetDescription = function(description, index: number?)
			local slot = index or 2
			generations[slot] += 1
			local token = generations[slot]
			description.UseAvatarSettings = true
			task.spawn(function()
				local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15) end)
				description:Destroy()
				if not ok then return end
				if token ~= generations[slot] or not viewport.Parent then model:Destroy(); return end
				local bound, rig = pcall(bind, model, if slot == 1 then 3.1 else -3.1, if slot == 1 then -0.24 else 0.24)
				if not bound then model:Destroy(); return end
				rigs[slot].model:Destroy()
				model.Name, model.Parent = if slot == 1 then "CreateRacer" else "YourAvatar", world
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local loaded, track = pcall(function()
						local animator = humanoid:FindFirstChildOfClass("Animator") or View.Make("Animator", "Animator", humanoid)
						return animator:LoadAnimation(waveAnimation)
					end)
					if loaded and track then
						track.Looped, track.Priority = false, Enum.AnimationPriority.Action
						rig.track = track
					end
				end
				rigs[slot] = rig
				draw()
			end)
		end,
	}
end

return Stage
