--!nonstrict
local Baseline = require(script.Parent.BaselineWorldPlan)
local Geometry = require(script.Parent.FortressGeometry)
local Finishing = {}
local v = Vector3.new
local windowAssets = {"MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"}
local function frame(point, yaw)
	return CFrame.new(point) * CFrame.Angles(0, yaw or 0, 0)
end
local function metadata(asset)
	if Geometry[asset] then return Geometry[asset] end
	local old = assert(Baseline.Assets[asset], "Unknown finishing asset " .. asset)
	return {parts=old[1], triangles=old[2], center=old[3], size=old[4]}
end

function Finishing.Apply(plan, layout)
	local rows, additions, replacements, assemblies = {}, {}, {}, {}
	local counts = {units=0, meshParts=0, triangles=0, replaced={}, proposalRows=rows,
		windowAssemblies=assemblies, nativeVisibilityVerified=false, plannedOnly=true}
	local function occupied(data)
		local meta=metadata(data.asset)
		for i, box in meta.occupied or {{low=meta.center-meta.size/2,high=meta.center+meta.size/2}} do
			local cf=data.localCF*CFrame.new((box.low+box.high)/2*data.scale)
			local size=(box.high-box.low)*data.scale
			table.insert(rows,{path=data.name.."/Occupied"..i,frame={cf:GetComponents()},size={size.X,size.Y,size.Z},
				anchored=true,collide=false,query=false,touch=false,transparency=0})
		end
	end
	local function add(district,name,asset,point,yaw,scale,role)
		local data={district=district,name=name,asset=asset,localCF=frame(point,yaw),scale=scale,
			library=if asset=="MC_AR_MasonryMass" then "ER01" elseif string.sub(asset,1,6)=="MC_P3_" then "P3" else "BL02",
			materialRole=role or "FortressStone"}
		local meta=metadata(asset)
		table.insert(additions,data)
		counts.units+=1;counts.meshParts+=meta.parts;counts.triangles+=meta.triangles
		occupied(data)
		return data
	end
	local function windows(district,name,point,yaw,scale,role,support)
		for _,asset in windowAssets do add(district,name..asset,asset,point,yaw,Vector3.one*scale,role) end
		table.insert(assemblies,{name=name,district=district,base=point,yaw=yaw,scale=scale,support=support,
			width=24*scale,fullPointedTopY=point.Y+57.981651306152344*scale,front=-frame(Vector3.zero,yaw).LookVector,
			materialRole=role})
	end
	local function mass(district,name,low,high)
		return add(district,name,"MC_AR_MasonryMass",v((low.X+high.X)/2,low.Y,(low.Z+high.Z)/2),0,
			(high-low)/v(25,24,13))
	end
	local function cap(district,name,point,yaw,width,depth)
		add(district,name,"MC_P3_SlateGable",point,yaw,v(width/24.4,3.2/10.53,depth/18.3),"SlateRoof")
	end
	-- Project the complete existing windows ahead of both hall and gallery eaves.
	for band=1,3 do
		local prefix="GalleryInteriorQuietLancet"..band
		local found=0
		local base
		for index,data in plan do
			if data.name==prefix.."MC_WindowFrame" or data.name==prefix.."MC_WindowTracery" or data.name==prefix.."MC_WindowGlass" then
				local copy=table.clone(data)
				base=v(data.localCF.Position.X,data.localCF.Position.Y,72.9)
				copy.localCF=frame(base,math.pi)
				plan[index]=copy;replacements[copy.name]=copy;table.insert(counts.replaced,copy.name);occupied(copy);found+=1
			end
		end
		assert(found==3,"Reseat the complete original gallery window "..band)
		local top=base.Y+57.981651306152344*.34
		mass("LanternPendulums","GalleryExposedWindowBay"..band,v(base.X-5,base.Y-.3,73.0),v(base.X+5,top+1.1,79.8))
		cap("LanternPendulums","GalleryExposedWindowCap"..band,v(base.X,top+1.0,76.4),0,11.2,8.2)
		table.insert(assemblies,{name=prefix,district="LanternPendulums",base=base,yaw=math.pi,scale=.34,support="GalleryExposedWindowBay"..band,
			width=8.16,fullPointedTopY=top,front=v(0,0,-1),materialRole="SecondaryWindow",existing=true})
	end

	windows("StoneArchClimb","WestHighWarmLancet",v(-231.15,15,-147.1),math.pi/2,.50,"SecondaryWarmWindow","WestArchHighWing solid eastern jamb")
	windows("StoneArchClimb","WestMiddleWarmLancet",v(-231.15,-4,-18),math.pi/2,.50,"SecondaryWarmWindow","WestMiddleWindowStoneSeat")
	mass("StoneArchClimb","WestMiddleWindowStoneSeat",v(-238.4,-4.3,-24.7),v(-231.6,26.1,-11.3))

	-- These two bays finish the broad route-facing machinery roof rather than hidden rear faces.
	for index,z in {-125,-75} do
		local base=v(192.9,111,z)
		windows("MachineryHouse","UpperMachineWarmLancet"..index,base,-math.pi/2,.46,"SecondaryWarmWindow","UpperMachineWindowBay"..index)
		local top=base.Y+57.981651306152344*.46
		mass("MachineryHouse","UpperMachineWindowBay"..index,v(193.2,base.Y-.3,z-6.2),v(202.3,top+1.1,z+6.2))
		cap("MachineryHouse","UpperMachineWindowCap"..index,v(197.75,top+1.0,z),math.pi/2,13.4,10.6)
	end

	for index,x in {-14,-2} do
		windows("GrandKeep","UpperKeepWarmLancet"..index,v(x,151,-50.5),0,.28,"SecondaryWarmWindow","GrandRearCentralPinnacle south face")
	end

	for _,edge in {
		{"WestHighEaveCornice",v(-229.8,45.4,-103),-math.pi/2,109.2,.15},
		{"WestMiddleEaveCornice",v(-229.8,29,-18),-math.pi/2,109.2},
		{"UpperMachineEaveCornice",v(193.3,109.6,-100),math.pi/2,150.8},
	} do
		add("FacadeFinishing",edge[1],"MC_P3_TerraceFascia",edge[2],edge[3],v(edge[4]/24,edge[5] or .27,.65),"FortressStone")
	end
	for _,data in additions do table.insert(plan,data) end
	counts.additions=additions;counts.replacements=replacements
	return counts
end

Finishing.AssetGeometry=metadata
return Finishing
