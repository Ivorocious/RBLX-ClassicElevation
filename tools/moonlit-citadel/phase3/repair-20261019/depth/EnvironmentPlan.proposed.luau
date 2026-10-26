--!nonstrict
local Geometry=require(script.Parent.EnclosureGeometry)
local Woods=require(script.Parent.WoodlandPlacements)
local Depth=require(script.Parent.DepthPlan)
local Environment={
	LibraryName="MoonlitCitadel_Enclosure_ER01Library",Limits={units=90,meshParts=230,triangles=90000}}
local v=Vector3.new
local Colors = {Shared = Color3.fromRGB(246, 240, 214), Normal = Color3.fromRGB(242, 225, 155),
	Expert = Color3.fromRGB(205, 167, 244), Return = Color3.fromRGB(224, 225, 231)}

Environment.Profile = table.freeze({
	CourseId = "moonlit_citadel", ActivationDistance = 750, UseCourseBounds = true,
	HideWorkspaceRoots = {"MoonlitCitadelPhase1_C01", "MoonlitCitadelPhase1_BL01", "MoonlitCitadelPhase1_BL02"}, RequiredCourseAttribute = "MoonlitNightAmbience",
	Lighting = {ClockTime = 19.2, GeographicLatitude = 20, Brightness = 2.2, ExposureCompensation = .65,
		GlobalShadows = true, ShadowSoftness = .3, EnvironmentDiffuseScale = .85, EnvironmentSpecularScale = .4,
		Ambient = Color3.fromRGB(145, 153, 171), OutdoorAmbient = Color3.fromRGB(132, 146, 169)},
	ColorCorrection = {Brightness = .035, Contrast = .015, Saturation = -.045, TintColor = Color3.fromRGB(232, 240, 255)},
		Atmosphere = {Density = .025, Offset = .10, Haze = .55, Glare = 0,
		Color = Color3.fromRGB(107, 123, 148), Decay = Color3.fromRGB(65, 78, 101)},
	Sky = {SkyboxBk = "rbxassetid://119591637361429", SkyboxDn = "rbxassetid://81233894808962",
		SkyboxFt = "rbxassetid://136920684348219", SkyboxLf = "rbxassetid://99622089516191",
		SkyboxRt = "rbxassetid://95853984087799", SkyboxUp = "rbxassetid://126102685877031",
		CelestialBodiesShown = true, StarCount = 1000, SunAngularSize = 0, MoonAngularSize = 11,
		MoonTextureId = "rbxasset://sky/moon.jpg"},
	Effects = {BloomEffect = {Enabled = true, Intensity = .10, Size = 20, Threshold = 1.4}, SunRaysEffect = {Enabled = false}},
})
local Existing={
	MC_P3_Rural_BroadleafClump={parts=2,triangles=684,center=v(-.5,14,1.024758),size=v(32.548702,32,25.158234)},
	MC_P3_Rural_EvergreenGrove={parts=2,triangles=1044,center=v(.15,16,1),size=v(30.300001,36,27.412678)},
	MC_P3_Rural_HeatherFern={parts=2,triangles=360,center=v(0,1.275,.75),size=v(18,3.05,10.5)},
	MC_P3_PlantPocket={parts=5,triangles=824,center=v(0,1.55,0),size=v(8,3.1,5.01)},
	MC_P3_Rework_FernCluster={parts=2,triangles=934,center=v(0,.88,0),size=v(2.658286,1.76,2.658286)},
}
local function frame(point,yaw) return CFrame.new(point)*CFrame.Angles(0,yaw or 0,0) end

local function triangleHeight(x,z,a,b,c)
	local denominator=(b.Z-c.Z)*(a.X-c.X)+(c.X-b.X)*(a.Z-c.Z)
	local u=((b.Z-c.Z)*(x-c.X)+(c.X-b.X)*(z-c.Z))/denominator
	local w=((c.Z-a.Z)*(x-c.X)+(a.X-c.X)*(z-c.Z))/denominator
	local t=1-u-w
	if math.min(u,w,t)>=-.00001 then return u*a.Y+w*b.Y+t*c.Y end
	return nil
end

function Environment.SurfaceHeight(asset,x,z)
	local meta=assert(Geometry[asset]);local column,row
	for i=1,#meta.xs-1 do if x>=meta.xs[i] and x<=meta.xs[i+1] then column=i;break end end
	for i=1,#meta.zs-1 do if z>=meta.zs[i] and z<=meta.zs[i+1] then row=i;break end end
	assert(column and row,"Plant root is outside the authored terrain sector")
	local a=v(meta.xs[column],meta.heights[row][column],meta.zs[row])
	local b=v(meta.xs[column+1],meta.heights[row][column+1],meta.zs[row])
	local c=v(meta.xs[column],meta.heights[row+1][column],meta.zs[row+1])
	local d=v(meta.xs[column+1],meta.heights[row+1][column+1],meta.zs[row+1])
	return assert(if (row+column)%2==0 then triangleHeight(x,z,a,c,d) or triangleHeight(x,z,a,d,b)
		else triangleHeight(x,z,a,c,b) or triangleHeight(x,z,b,c,d),"Root missed actual terrain triangles")
end

function Environment.Get(layout,architectureMounts,architectureBodies,options)
	options=options or {}
	local plan,names={},{}
	local counts={units=0,meshParts=0,triangles=0,lamps={},maxNewLights=0,groundBaseY=-700,
		groundedPockets={},omittedPlanting={},plantingMountsMissing=architectureMounts==nil,
		proposalRows={},terrainSolids={},groves={},mounds={},artCanCollide=false,artCanQuery=false,artCanTouch=false,
		site={low=v(-390,-700,-355),high=v(390,327.263136,350)},profilePreserved=true,retirePreviousLandscape=true}
	local function add(district,name,asset,cf,scale,role)
		assert(not names[name],"Duplicate enclosure edit unit");names[name]=true
		scale=scale or Vector3.one
		local meta=assert(Geometry[asset] or Existing[asset] or Depth.AssetGeometry[asset],"Missing measured landscape geometry")
		local library=if Depth.AssetGeometry[asset] then "DP01" elseif Geometry[asset] then "ER01" elseif asset=="MC_P3_PlantPocket" or asset=="MC_P3_Rework_FernCluster" then "P3" else "TL01"
		table.insert(plan,{district=district,name=name,asset=asset,localCF=cf,scale=scale,library=library,materialRole=role or "WoodedFortressLandscape"})
		counts.units+=1;counts.meshParts+=meta.parts;counts.triangles+=meta.triangles
		for index,solid in meta.occupied or {{low=meta.center-meta.size/2,high=meta.center+meta.size/2}} do
			local occupiedFrame=cf*CFrame.new((solid.low+solid.high)/2*scale)
			local size=(solid.high-solid.low)*scale
			table.insert(counts.proposalRows,{path="Landscape/"..name.."/Solid"..index,frame={occupiedFrame:GetComponents()},
				size={size.X,size.Y,size.Z},anchored=true,collide=false,query=false,touch=false,transparency=0})
		end
		if meta.xs then table.insert(counts.terrainSolids,{name=name,asset=asset,baseY=-130,trianglePrisms=meta.occupied}) end
	end
	for _,asset in {"MC_EC_InnerRavine","MC_EC_WestWoodedCliff","MC_EC_EastPanoramaSlope","MC_EC_NorthHighRidge","MC_EC_SouthValleyRidge"} do
		local visual=if asset==Depth.OriginalAsset then Depth.Asset else asset
		add("JoinedRavineRidges",asset,visual,CFrame.identity,Vector3.one,"RidgeRockSoilGrass")
	end
	for _,wood in Woods do
		local cf=frame(wood.point,wood.yaw)
		add("RidgeWoodland",wood.name,wood.asset,cf,Vector3.one*wood.scale)
		local height=Environment.SurfaceHeight(wood.sector,wood.point.X,wood.point.Z)
		table.insert(counts.groves,{name=wood.name,sector=wood.sector,point=wood.point,actualCenterSurfaceY=height,
			rootBurial=wood.rootBurial,trees=if wood.asset:find("Rural",1,true) then 3 else 1})
	end
	counts.ruralTreeCount=0
	for _,grove in counts.groves do counts.ruralTreeCount+=grove.trees end
	for index,site in {{"MC_EC_WestWoodedCliff",-308,-132},{"MC_EC_NorthHighRidge",-82,-274},
		{"MC_EC_NorthHighRidge",150,-282},{"MC_EC_EastPanoramaSlope",300,44},{"MC_EC_SouthValleyRidge",12,280},{"MC_EC_SouthValleyRidge",-236,276}} do
		local point=v(site[2],Environment.SurfaceHeight(site[1],site[2],site[3])-.5,site[3])
		add("WoodlandUnderstory","WoodlandHeather"..index,"MC_P3_Rural_HeatherFern",frame(point,index*.71),Vector3.one*1.3)
	end
	for index,mount in architectureMounts or {} do
		assert(index<=10 and mount.supportName and typeof(mount.frame)=="CFrame","Only plant on a real authored ledge")
		add("RoutePlanting",mount.name.."CarvedBasin","MC_P3_PlantPocket",mount.frame,Vector3.one*.65)
		add("RoutePlanting",mount.name.."Fern","MC_P3_Rework_FernCluster",mount.frame*CFrame.new(0,.624,0),Vector3.one*.8)
		table.insert(counts.groundedPockets,{name=mount.name,frame=mount.frame,supportName=mount.supportName})
	end
	counts.foundationBeds=Geometry.MC_EC_InnerRavine
	counts.depthChasm={asset=Depth.Asset,retainedSupportTopTriangles=Depth.RetainedOriginalTopTriangles,removedBedTriangles=Depth.RemovedUnsupportedBedTriangles,fallYLocalUnchanged=-23}
	counts.terrainPalette={Rock={100,112,116},RockA={100,112,116},RockB={100,112,116},Earth={100,86,68},Grass={91,119,75}}
	counts.clearance="Per-triangle column boxes plus exact top triangles; nearby banks must pass accepted route, camera and mechanism screens"
	if options.clearance and options.config then counts.clearanceReport=options.clearance.CheckParts(counts.proposalRows,options.clearance.Prepare(layout,options.config)) end
	assert(counts.units<=Environment.Limits.units and counts.meshParts<Environment.Limits.meshParts and counts.triangles<=Environment.Limits.triangles,"Enclosure landscape exceeds reserved budget")
	return plan,counts
end

Environment.AssetGeometry=table.clone(Geometry)
for asset,meta in Depth.AssetGeometry do Environment.AssetGeometry[asset]=meta end
local function placeTemplate(folder, library, asset, name, cf, scale)
	local source = assert(library:FindFirstChild(asset), "Import verified new art " .. asset)
	local model = source:Clone()
	assert(model:IsA("Model"), "Art library requires an asset Model")
	model.Name = name
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local localFrame = part.CFrame
		part.Size *= scale
		part.CFrame = cf * CFrame.new(localFrame.Position * scale) * localFrame.Rotation
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow = false
	end
	model.WorldPivot, model.Parent = cf, folder
	return model
end

function Environment.PlaceSolidArrow(folder, library, name, contact, point, target, mode)
 assert(library:GetAttribute("ReworkImportVerified") == true, "Verify RW01 upload/geometry before wayfinding")
 local up = contact.CFrame.UpVector
 local localPoint = contact.CFrame:PointToObjectSpace(point)
 local halfX, halfZ = contact.Size.X / 2 - .16, contact.Size.Z / 2 - .16
 local direction, cf, s
 for _ = 1, 8 do
  point = contact.CFrame:PointToWorldSpace(localPoint)
  direction = target - point
  direction -= up * direction:Dot(up)
  assert(direction.Magnitude > .1, "Arrow needs a real onward landing")
  direction = direction.Unit
  cf = CFrame.fromMatrix(point + up * .025, -direction:Cross(up).Unit, up, direction)
  local right = contact.CFrame:VectorToObjectSpace(cf.RightVector)
  local forward = contact.CFrame:VectorToObjectSpace(cf.LookVector)
  local rx = math.abs(right.X) * 2.1 + math.abs(forward.X) * 2.7
  local rz = math.abs(right.Z) * 2.1 + math.abs(forward.Z) * 2.7
  s = math.min(1.3, halfX / math.max(.01, rx), halfZ / math.max(.01, rz))
  assert(s >= .24, "Arrow requires a supported floor")
  local travelX, travelZ = math.max(0, halfX - rx * s), math.max(0, halfZ - rz * s)
  localPoint = Vector3.new(math.clamp(localPoint.X, -travelX, travelX), localPoint.Y,
   math.clamp(localPoint.Z, -travelZ, travelZ))
 end
 point = contact.CFrame:PointToWorldSpace(localPoint)
 direction = target - point
 direction -= up * direction:Dot(up)
 direction = direction.Unit
 cf = CFrame.fromMatrix(point + up * .025, -direction:Cross(up).Unit, up, direction)
 local scale = Vector3.one * s
 local mount = placeTemplate(folder, library, "MC_P3_Rework_ArrowMount", name .. "Mount", cf, scale)
 local arrow = placeTemplate(folder, library, "MC_P3_Rework_SolidArrow", name, cf + up * (.17 * s), scale)
 local arrowColors = {
  Shared = Color3.fromRGB(255, 246, 214),
  Normal = Color3.fromRGB(255, 226, 128),
  Expert = Color3.fromRGB(213, 162, 255),
  Return = Color3.fromRGB(179, 221, 255),
 }
 local count = 0
 for _, part in mount:GetDescendants() do
  if part:IsA("BasePart") then part.Color = Color3.fromRGB(12, 17, 27) end
 end
 for _, part in arrow:GetDescendants() do
  if not part:IsA("BasePart") then continue end
  count += 1
  part.Color, part.Material = assert(arrowColors[mode], "Unknown route mode"), Enum.Material.Neon
  part:SetAttribute("GuidanceKind", "SolidMeshArrow")
  part:SetAttribute("SourceContact", contact:GetFullName())
  part:SetAttribute("ArrowForward", direction)
  part:SetAttribute("ArrowTarget", target)
 end
 assert(count == 1, "A route arrow must be a single solid mesh")
 for _, model in {mount, arrow} do
  model:SetAttribute("ArrowId", name)
  model:SetAttribute("RouteMode", mode)
  model:SetAttribute("SourceContact", contact:GetFullName())
  model:SetAttribute("ArrowStyleVersion", 2)
 end
 return arrow, mount
end

return Environment
