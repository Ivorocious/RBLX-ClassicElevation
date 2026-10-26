--!nonstrict
local Details = require(script.Parent.DetailPlan)
local DetailGeometry = require(script.Parent.DetailGeometry)
local Previous = require(script.Parent.Source49WorldPlan)
local Windows = require(script.Parent.WindowFinishingPlan)
local Crown = require(script.Parent.SceneryRevisions)
local Cliffs = require(script.Parent.CliffFinishingPlan)
local Baseline = require(script.Parent.BaselineWorldPlan)
local Geometry = {}
for asset, row in Baseline.Assets do
	Geometry[asset] = {parts=row[1], triangles=row[2], center=row[3], size=row[4]}
end
for _, module in {require(script.Parent.AssetGeometry), require(script.Parent.TowerGeometry), Previous.AssetGeometry} do
	for asset, row in module do Geometry[asset] = row end
end
for asset, row in Cliffs.AssetGeometry do
	Geometry[asset] = {parts=row.parts, triangles=row.triangles, center=(row.low+row.high)/2,
		size=row.high-row.low, occupied={{low=row.low, high=row.high}}}
end
for asset, row in DetailGeometry do
	local occupied = {}
	for _, box in row.boxes do table.insert(occupied, {low=box.center-box.size/2, high=box.center+box.size/2}) end
	Geometry[asset] = {parts=row.meshParts, triangles=row.triangles, occupied=occupied}
end
local World = {Limits=Previous.Limits, BaseY=Previous.BaseY, LibraryName=Previous.LibraryName,
	AssetGeometry=Geometry, Candidate="MC_P3_DETAILS_DT02"}

function World.Get(layout, options)
	options = options or {}
	local originalOptions = table.clone(options)
	originalOptions.clearance = nil
	local plan, counts = Previous.Get(layout, originalOptions)
	for index, data in plan do plan[index] = Crown.Revise(data) end
	for _, data in Crown.Additions() do table.insert(plan, data) end
	local windows = Windows.Apply(plan, layout)
	local cliffs, cliffCounts = Cliffs.Get()
	for _, data in cliffs do table.insert(plan, data) end
	local details, detailCounts = Details.Get()
	for _, data in details do table.insert(plan, data) end
	counts.detail = detailCounts
	counts.units, counts.meshParts, counts.triangles = 0, 0, 0
	counts.districts, counts.proposalRows = {}, {}
	local names = {}
	for _, data in plan do
		assert(not names[data.name], "Duplicate closeout edit unit " .. data.name)
		names[data.name] = true
		local meta = assert(Geometry[data.asset], "Unknown closeout asset " .. data.asset)
		counts.units += 1
		counts.meshParts += meta.parts
		counts.triangles += meta.triangles
		counts.districts[data.district] = (counts.districts[data.district] or 0) + 1
		for index, box in meta.occupied or {{low=meta.center-meta.size/2, high=meta.center+meta.size/2}} do
			local frame = data.localCF * CFrame.new((box.low+box.high)/2 * data.scale)
			local size = (box.high-box.low) * data.scale
			table.insert(counts.proposalRows, {path=data.name.."/Occupied"..index,
				frame={frame:GetComponents()}, size={size.X,size.Y,size.Z},
				anchored=true, collide=false, query=false, touch=false, transparency=0})
		end
	end
	counts.closeout = {candidate=World.Candidate, windows=windows, cliffs=cliffCounts,
		crownEditedNames=Crown.EditedNames, crownViews=Crown.Views, nativeCompositionVerified=false}
	if options.clearance and options.config then
		counts.clearance = options.clearance.CheckParts(counts.proposalRows, options.clearance.Prepare(layout, options.config))
	end
	assert(counts.units <= 260 and counts.meshParts <= 800 and counts.triangles <= 320000,
		"Detailed architecture budget exceeded")
	return plan, counts
end

return World
