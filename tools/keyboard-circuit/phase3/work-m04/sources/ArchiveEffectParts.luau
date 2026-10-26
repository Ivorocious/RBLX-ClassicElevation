--!strict
local Art = require(script.Parent.EnvironmentParts)
local Parts = require(script.Parent.Parts)
local EffectParts = {}

local colors = {
	Creamy = Parts.Palette.Creamy[3], Thocky = Parts.Palette.Thocky[2],
	Clacky = Parts.Palette.Clacky[2], Clicky = Parts.Palette.Clicky[2],
}

local function familyOf(item: Instance, course: Model): string
	local current: Instance? = item
	while current and current ~= course do
		local family = current:GetAttribute("KeyFamily")
		if typeof(family) == "string" and colors[family] then return family end
		current = current.Parent
	end
	return "Creamy"
end

local function anchor(parent: Instance, name: string, size: Vector3, frame: CFrame, family: string, kind: string, transparency: number): Part
	local part = Art.Block(parent, name, size, frame, colors[family] or Art.Trace)
	part.Material, part.Transparency, part.CastShadow = Enum.Material.Neon, 1, false
	part:SetAttribute("ArchiveEffectKind", kind)
	part:SetAttribute("ArchiveEffectFamily", family)
	part:SetAttribute("ActiveTransparency", transparency)
	return part
end

local function resolve(course: Model, path: string): Instance?
	local cursor: Instance? = course
	for token in string.gmatch(path, "[^%.]+") do
		cursor = if cursor then cursor:FindFirstChild(token) else nil
	end
	return cursor
end

function EffectParts.Build(course: Model, origin: Vector3, _template: MeshPart): Model
	local environment = assert(course:FindFirstChild("MapEnvironment"))
	local root = Art.Model(environment, "ArchiveEffectParts")
	root:SetAttribute("Purpose", "Invisible inert anchors; local effects exist only during the selected course session")
	local underlights = Art.Model(root, "Underlights")
	local paths = Instance.new("Folder")
	paths.Name, paths.Parent = "TracePaths", root
	local plates = environment:FindFirstChild("IslandCircuitPlates")
	local strips, traces = 0, 0
	local families = {"Creamy", "Thocky", "Clacky", "Clicky"}
	local familyCounts = {}
	if plates then
		local ordered = plates:GetChildren()
		table.sort(ordered, function(a, b) return a.Name < b.Name end)
		local byFamily = {Creamy = {}, Thocky = {}, Clacky = {}, Clicky = {}}
		for _, plate in ordered do
			if not plate:IsA("Model") then continue end
			local base = plate:FindFirstChild("CircuitPlate")
			if not base or not base:IsA("BasePart") then continue end
			local hostPath = plate:GetAttribute("HostBank")
			local host = if typeof(hostPath) == "string" then resolve(course, hostPath) else nil
			local family = familyOf(host or plate, course)
			table.insert(byFamily[family], plate)
		end
		ordered = {}
		for index = 1, 8 do
			for _, family in families do
				local plate = byFamily[family][index]
				if plate then table.insert(ordered, plate) end
			end
		end
		for _, family in families do familyCounts[family] = {strips = 0, traces = 0} end
		for _, plate in ordered do
			if strips >= 64 then break end
			local base = plate.CircuitPlate
			local hostPath = plate:GetAttribute("HostBank")
			local host = if typeof(hostPath) == "string" then resolve(course, hostPath) else nil
			local family = familyOf(host or plate, course)
			for _, side in {-1, 1} do
				anchor(underlights, "Strip" .. (strips + 1), Vector3.new(base.Size.X * .72, .13, .22),
					base.CFrame * CFrame.new(0, -base.Size.Y / 2 - .10, side * base.Size.Z * .39), family, "Underlight", .24)
				strips += 1
				familyCounts[family].strips += 1
			end
			local trace = plate:FindFirstChild("LongTrace")
			if trace and trace:IsA("BasePart") and familyCounts[family].traces < 4 then
				local link = Instance.new("ObjectValue")
				link.Name, link.Value, link.Parent = "Trace" .. (traces + 1), trace, paths
				link:SetAttribute("MaxEffectFrame", trace.CFrame * CFrame.new(0, .025, 0))
				link:SetAttribute("MaxEffectSize", Vector3.new(trace.Size.X, .13, .7))
				traces += 1
				familyCounts[family].traces += 1
			end
		end
	end
	for _, family in families do
		local count = assert(familyCounts[family], "Archive effects require circuit plates")
		assert(count.strips > 0 and count.traces > 0, "Archive effects must cover " .. family)
		root:SetAttribute("Underlight" .. family .. "Count", count.strips)
		root:SetAttribute("Trace" .. family .. "Count", count.traces)
	end
	local waves = Art.Model(root, "LandmarkWaves")
	local landmarks = assert(environment:FindFirstChild("HardwareLandmarks"))
	local names = {Creamy = "CreamyTrayRack", Thocky = "ThockyCapMagazine", Clacky = "ClackySplitFins", Clicky = "ClickyRotaryDial"}
	local offsets = {Creamy = Vector3.new(0, 5, 10), Thocky = Vector3.new(0, 17, 9), Clacky = Vector3.new(0, 5, 10), Clicky = Vector3.new(0, 7, 17)}
	for _, family in {"Creamy", "Thocky", "Clacky", "Clicky"} do
		local landmark = landmarks:FindFirstChild(names[family])
		assert(landmark and landmark:IsA("Model") and landmark.PrimaryPart, "Effect landmark missing: " .. family)
		local group = Art.Model(waves, family)
		group:SetAttribute("KeyFamily", family)
		group:SetAttribute("ReceiveRadius", 135)
		local frame = landmark.PrimaryPart.CFrame * CFrame.new(offsets[family])
		for index = 1, 7 do
			local part = anchor(group, "Bar" .. index, Vector3.new(.65, .8, .32), frame * CFrame.new((index - 4) * 1.22, 0, 0), family, "WaveBar", .14)
			part:SetAttribute("BarIndex", index)
			local maximumHeight = .8 + (if family == "Thocky" then 1.2 + 1 / 60 else 1 + 1 / 60) * (if family == "Thocky" then 4.2 else 3.1)
			part:SetAttribute("MaxEffectFrame", part.CFrame * CFrame.new(0, (maximumHeight - part.Size.Y) / 2, 0))
			part:SetAttribute("MaxEffectSize", Vector3.new(part.Size.X, maximumHeight, part.Size.Z))
		end
		group.PrimaryPart = group.Bar4
	end
	local usb = Art.Model(root, "USBContacts")
	local arch = assert(landmarks:FindFirstChild("USBStartArch"))
	for index = 1, 4 do
		local contact = arch:FindFirstChild("GoldContact" .. index)
		assert(contact and contact:IsA("BasePart"), "USB effect contact missing")
		local part = anchor(usb, "Contact" .. index, Vector3.new(.12, contact.Size.Y - .15, contact.Size.Z - .2),
			contact.CFrame * CFrame.new(contact.Size.X / 2 + .07, 0, 0), "Creamy", "USBContact", .22)
		part:SetAttribute("ContactIndex", index)
	end
	local depth = Art.Model(root, "InteriorDepth")
	local layer = anchor(depth, "LowLayer", Vector3.new(576, .05, 576), CFrame.new(origin + Vector3.new(0, -129, 0)), "Thocky", "Depth", .965)
	layer.Material, layer.Color = Enum.Material.SmoothPlastic, Color3.fromRGB(89, 116, 120)
	root:SetAttribute("UnderlightCount", strips)
	root:SetAttribute("TracePathCount", traces)
	root:SetAttribute("WaveBarCount", 28)
	root:SetAttribute("USBContactCount", 4)
	root:SetAttribute("DepthLayerCount", 1)
	root:SetAttribute("DynamicLightCount", 0)
	root:SetAttribute("ParticleEmitterCount", 0)
	return root
end

return EffectParts
