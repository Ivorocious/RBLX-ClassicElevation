--!strict

local Phases = {}
local warningColor = Color3.fromRGB(255, 190, 65)
local ghostColor = Color3.fromRGB(167, 133, 235)

local function number(part: BasePart, name: string, default: number, low: number, high: number): number
	local value = part:GetAttribute(name)
	return math.clamp(if typeof(value) == "number" and value == value then value else default, low, high)
end

function Phases.Create(course: Model)
	local records = {}
	for _, part in course:GetDescendants() do
		if not part:IsA("BasePart") or part:GetAttribute("KitPhase") ~= "Pulse" then continue end
		assert(part.Anchored and part.CanCollide, "Phase platforms must start anchored and solid")
		assert(part:GetAttribute("HazardType") == nil, "Do not combine phase and touch hazards on one part")
		local period = number(part, "PhasePeriod", 8, 2, 120)
		local solid = number(part, "PhaseSolidTime", period * .6, .5, period - .75)
		local warning = number(part, "PhaseWarningTime", 1.2, .25, period - solid - .25)
		table.insert(records, {
			part = part, period = period, solid = solid, warning = warning,
			offset = number(part, "PhaseOffset", 0, 0, 360) / 360 * period,
			color = part.Color, material = part.Material, transparency = part.Transparency,
			collide = part.CanCollide, touch = part.CanTouch, query = part.CanQuery,
			authoredState = part:GetAttribute("KitPhaseState"), state = "",
		})
	end
	if #records == 0 then return nil end
	local controller = {}
	local function restore(record)
		local part = record.part
		part.Color, part.Material, part.Transparency = record.color, record.material, record.transparency
		part.CanCollide, part.CanTouch, part.CanQuery = record.collide, record.touch, record.query
	end
	function controller.Step(elapsed: number)
		for _, record in records do
			local part = record.part
			if not part.Parent then continue end
			local time = (elapsed + record.offset) % record.period
			local state = if time < record.solid then "Solid" elseif time < record.solid + record.warning then "Warning" else "Ghost"
			if state == record.state then continue end
			record.state = state
			restore(record)
			if state == "Warning" then
				part.Color, part.Material = warningColor, Enum.Material.Neon
				part.Transparency = math.max(record.transparency, .15)
			elseif state == "Ghost" then
				part.Color, part.Material, part.Transparency = ghostColor, Enum.Material.SmoothPlastic, .88
				part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			end
			part:SetAttribute("KitPhaseState", state)
		end
	end
	function controller.Reset()
		for _, record in records do
			if record.part.Parent then
				restore(record)
				record.part:SetAttribute("KitPhaseState", record.authoredState)
			end
			record.state = ""
		end
	end
	return controller
end

return Phases
