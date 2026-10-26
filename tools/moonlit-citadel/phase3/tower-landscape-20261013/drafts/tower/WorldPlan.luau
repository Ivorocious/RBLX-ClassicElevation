--!nonstrict
local Source43 = require(script.Parent.Source43WorldPlan)
local Geometry = require(script.Parent.TowerGeometry)
local AR = require(script.Parent.AssetGeometry)
local Baseline = require(script.Parent.BaselineWorldPlan)
local World = {Limits=Source43.Limits, BaseY=Source43.BaseY, LibraryName=Source43.LibraryName}
local v = Vector3.new
local function cf(point, yaw) return CFrame.new(point) * CFrame.Angles(0,yaw or 0,0) end

function World.Get(layout, options)
	options = options or {}
	local baseline, previous = Source43.Get(layout)
	local plan, rows = {}, {}
	local counts = {units=0, meshParts=0, triangles=0, districts={}, plantingMounts=previous.plantingMounts,
		assemblies=previous.assemblies, retired={}, proposalRows=rows, fullMapPending=false,
		newLibrary="MoonlitCitadel_TowerLandscape_TL01Library", occupiedGeometryRequired=true}
	local function metadata(data)
		if data.library == "TL01" then return Geometry[data.asset] end
		if AR[data.asset] then return AR[data.asset] end
		local old = Baseline.Assets[data.asset]
		return {parts=old[1], triangles=old[2], center=old[3], size=old[4]}
	end
	local function add(data, new)
		local meta = metadata(data)
		table.insert(plan,data)
		counts.units+=1; counts.meshParts+=meta.parts; counts.triangles+=meta.triangles
		counts.districts[data.district]=(counts.districts[data.district] or 0)+1
		if not new then return end
		local boxes=meta.occupied or {{low=meta.center-meta.size/2,high=meta.center+meta.size/2}}
		for index,box in boxes do
			local frame=data.localCF*CFrame.new((box.low+box.high)/2*data.scale)
			local size=(box.high-box.low)*data.scale
			table.insert(rows,{path=data.name.."/Occupied"..index,frame={frame:GetComponents()},size={size.X,size.Y,size.Z},
				anchored=true,collide=false,query=false,touch=false,transparency=0})
		end
	end
	for _,data in baseline do
		local retire = data.name:match("^KeepTier") or data.name:match("^CrownCorner")
			or data.name:match("^KeepQuietSide") or data.name:match("^KeepQuietRear")
			or data.name:match("QuietFoundationLancet2")
		if retire then table.insert(counts.retired,data.name) else add(data,false) end
	end
	local function unit(name,asset,frame,scale,role)
		add({district="GrandKeep",name=name,asset=asset,localCF=frame,scale=scale or Vector3.one,
			library=if Geometry[asset] then "TL01" else "AR01",materialRole=role or "GrandStone"},true)
	end
	local function mass(name,low,high,role)
		unit(name,"MC_AR_MasonryMass",CFrame.new((low.X+high.X)/2,low.Y,(low.Z+high.Z)/2),
			(high-low)/AR.MC_AR_MasonryMass.size,role)
	end
	local finish=layout.FinishPoint
	local x,z=finish.X,finish.Z
	local bottom,top=World.BaseY,125.8
	-- Four full-height walls replace the two repeated striped shell storeys.
	mass("GrandKeepSouthWall",v(x-38,bottom,z+10),v(x+38,top,z+18))
	mass("GrandKeepWestWall",v(x-38,bottom,z-18),v(x-30,top,z+10))
	mass("GrandKeepNorthWall",v(x-30,bottom,z-18),v(x+38,top,z-10))
	mass("GrandKeepEastWall",v(x+30,bottom,z-10),v(x+38,top,z+10))
	for side=-1,1,2 do
		unit("SouthGrandButtress"..side,"MC_TL_SteppedButtress",cf(v(x+side*31,bottom,z+16)))
		unit("NorthGrandButtress"..side,"MC_TL_SteppedButtress",cf(v(x+side*31,bottom,z-16),math.pi))
	end
	-- The northern apse leaves the gallery court and the east crown approach open.
	mass("GrandRearApseFoundation",v(x-15,bottom,z-43),v(x+15,125.8,z-16))
	unit("GrandRearCentralPinnacle","MC_TL_GrandPinnacle",cf(v(x,125.8,z-30)),v(1.25,1,1.15))
	for side=-1,1,2 do
		unit("GrandFlankPinnacle"..side,"MC_TL_FlankPinnacle",cf(v(x+side*29,125.8,z+16)))
	end
	counts.mainPeakY=237.8
	counts.keepBaseWalls={low=v(x-38,bottom,z-18),high=v(x+38,top,z+18)}
	counts.additionalGroundRoots={{name="GrandRearApseFoundation",low=v(x-15,bottom,z-43),high=v(x+15,125.8,z-16)}}
	counts.joinedGroups={{name="GrandKeepBody",members={"GrandKeepSouthWall","GrandKeepWestWall","GrandKeepNorthWall","GrandKeepEastWall",
		"SouthGrandButtress-1","SouthGrandButtress1","NorthGrandButtress-1","NorthGrandButtress1"}},
		{name="GrandKeepRearPinnacle",members={"GrandRearApseFoundation","GrandRearCentralPinnacle"}},
		{name="GrandKeepCrownFlanks",members={"GrandFlankPinnacle-1","GrandFlankPinnacle1"}}}
	counts.approachPortal=previous.approachPortal
	counts.materialPolicy={GrandStone={Stone={124,134,149},StoneLight={185,190,193},StoneDark={80,96,116}},
		PinnacleSlate={Slate={43,60,86},SlateBand={64,83,110}},sideWindow="Remove repetitive small side/rear lancets; preserve the accepted focal main window"}
	if options.clearance and options.config then counts.clearance=options.clearance.CheckParts(rows,options.clearance.Prepare(layout,options.config)) end
	assert(counts.units<=World.Limits.units and counts.meshParts<=World.Limits.meshParts and counts.triangles<=World.Limits.triangles,"Grand keep replacement exceeds world budget")
	return plan,counts
end

World.AssetGeometry=Geometry
return World
