--!strict
local PresentationBudget = {}

PresentationBudget.Limits = table.freeze({
	OrdinaryKeyLegend = 120,
	SpecialKeyLegend = 180,
	DisplayKeyLegend = 64,
	WarningKeyLegend = 170,
})

type Report = {
	surfaceGuis: number,
	distancesBefore: {[string]: number},
	distancesAfter: {[string]: number},
	legendClasses: {[string]: number},
	boundedGuis: number,
	artShadowsBefore: number,
	artShadowsAfter: number,
	disabledArtShadows: number,
}

local function legendLimit(gui: SurfaceGui): (number?, string)
	local part = gui.Adornee or gui.Parent
	if not part or not part:IsA("BasePart") or gui.Name ~= "Legend" then return nil, "Preserved" end
	if typeof(part:GetAttribute("KeyLegend")) ~= "string" then return nil, "Preserved" end
	if part:GetAttribute("Role") == "WalkableSkin" then
		if gui:FindFirstChild("DropWarning") then return PresentationBudget.Limits.WarningKeyLegend, "WarningKey" end
		if part.Name == "KeyTop" or math.max(part.Size.X, part.Size.Z) > 3.2 then
			return PresentationBudget.Limits.SpecialKeyLegend, "SpecialKey"
		end
		return PresentationBudget.Limits.OrdinaryKeyLegend, "OrdinaryKey"
	end
	if part:GetAttribute("MapArtwork") == true and not part:GetAttribute("Pressable") then
		return PresentationBudget.Limits.DisplayKeyLegend, "DisplayKey"
	end
	return nil, "Preserved"
end

local function optionalDetail(part: BasePart): boolean
	if part:GetAttribute("MapArtwork") ~= true or part:GetAttribute("Pressable") or part:GetAttribute("KCPress") then return false end
	if part.CanCollide or part.CanQuery or part.CanTouch then return false end
	local size = part.Size
	local longest, shortest = math.max(size.X, size.Y, size.Z), math.min(size.X, size.Y, size.Z)
	local volume = size.X * size.Y * size.Z
	return (longest <= 6 and volume <= 128) or (shortest <= .4 and longest <= 24)
end

local function count(totals: {[string]: number}, key: string)
	totals[key] = (totals[key] or 0) + 1
end

function PresentationBudget.Apply(course: Model): Report
	local report: Report = {
		surfaceGuis = 0,
		distancesBefore = {},
		distancesAfter = {},
		legendClasses = {},
		boundedGuis = 0,
		artShadowsBefore = 0,
		artShadowsAfter = 0,
		disabledArtShadows = 0,
	}
	for _, item in course:GetDescendants() do
		if item:IsA("SurfaceGui") then
			report.surfaceGuis += 1
			count(report.distancesBefore, tostring(item.MaxDistance))
			local limit, class = legendLimit(item)
			count(report.legendClasses, class)
			if limit and (item.MaxDistance == 0 or item.MaxDistance > limit) then
				item.MaxDistance = limit
				report.boundedGuis += 1
			end
			count(report.distancesAfter, tostring(item.MaxDistance))
		elseif item:IsA("BasePart") and item:GetAttribute("MapArtwork") == true then
			if item.CastShadow then report.artShadowsBefore += 1 end
			if item.CastShadow and optionalDetail(item) then
				item.CastShadow = false
				report.disabledArtShadows += 1
			end
			if item.CastShadow then report.artShadowsAfter += 1 end
		end
	end
	course:SetAttribute("PresentationBudgetRevision", "KC_PRESENTATION_M03_01")
	course:SetAttribute("OrdinaryLegendDistance", PresentationBudget.Limits.OrdinaryKeyLegend)
	course:SetAttribute("SpecialLegendDistance", PresentationBudget.Limits.SpecialKeyLegend)
	course:SetAttribute("DisplayLegendDistance", PresentationBudget.Limits.DisplayKeyLegend)
	course:SetAttribute("WarningKeyLegendDistance", PresentationBudget.Limits.WarningKeyLegend)
	return report
end

return PresentationBudget
