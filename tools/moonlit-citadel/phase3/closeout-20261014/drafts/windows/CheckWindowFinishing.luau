local fs,luau,roblox,serde=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde')
local source='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local own='tools/moonlit-citadel/phase3/closeout-20261014/drafts/windows/'
local config=luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'),{environment={Vector3=roblox.Vector3}})()
local cache,loading,inputHashes={},{},{}
local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name} end})
local function load(name)
	if cache[name] then return cache[name] end
	assert(not loading[name],'Source module cycle '..name);loading[name]=true
	local file=if name=='WindowFinishingPlan' then own..name..'.luau' else source..name..'.luau'
	local text=fs.readFile(file);luau.compile(text)
	inputHashes[name]={path=file,sha256=serde.hash('sha256',text)}
	local result=luau.load(text,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
		script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},
		require=function(value)return if type(value)=='table' and value.moduleName then load(value.moduleName) else value end}})()
	cache[name],loading[name]=result,nil;return result
end
local layout,world,finishing=load('Layout'),load('WorldPlan'),load('WindowFinishingPlan')
local clearancePath='tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/ArchitectureClearance.luau'
local clearanceText=fs.readFile(clearancePath)
local clearance=luau.load(clearanceText,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame}})()
inputHashes.Clearance={path=clearancePath,sha256=serde.hash('sha256',clearanceText)}
local plan,before=world.Get(layout)
local result=finishing.Apply(plan,layout)
local volumes,seen={},{}
for mask=0,7 do
	for lower=1,2 do for upper=1,2 do
		local chosen=table.clone(layout)
		chosen.GetRoute=function()return layout.GetRoute({bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0},{lower,upper}) end
		for _,space in clearance.Prepare(chosen,config) do
			local key=space.reason..'|'..tostring(space.frame)..'|'..tostring(space.size)
			if not seen[key] then seen[key]=true;table.insert(volumes,space) end
		end
	end end
end
local screen=clearance.CheckParts(result.proposalRows,volumes)
local failures={}
for _,key in {'blocking','headroom','camera','visibility','invalidContactFlags'} do
	if #screen[key]>0 then table.insert(failures,key..' '..#screen[key]) end
end

local function encode(value)
	if typeof(value)=='Vector3' then return {value.X,value.Y,value.Z} end
	if typeof(value)=='CFrame' then return {value:GetComponents()} end
	if type(value)~='table' then return value end
	local copy={};for k,item in value do if type(item)~='function' then copy[k]=encode(item) end end;return copy
end
local candidates={}
for _,unit in plan do
	local meta=world.AssetGeometry[unit.asset] or load('TowerGeometry')[unit.asset] or load('AssetGeometry')[unit.asset]
	if not meta then local old=load('BaselineWorldPlan').Assets[unit.asset];meta={center=old[3],size=old[4]} end
	for _,b in meta.occupied or {{low=meta.center-meta.size/2,high=meta.center+meta.size/2}} do
		table.insert(candidates,{name=unit.name,cf=unit.localCF,scale=unit.scale,low=b.low,high=b.high})
	end
end
for _,floor in layout.Surfaces do
	table.insert(candidates,{name='Obstacles/'..floor.group..'/'..floor.name..'/Contact',
		cf=(floor.frame or roblox.CFrame.new(floor.position))*roblox.CFrame.new(0,-floor.size.Y/2,0),scale=roblox.Vector3.one,
		low=-floor.size/2,high=floor.size/2})
end
for _,part in candidates do
	local center=part.cf:PointToWorldSpace((part.low+part.high)/2*part.scale)
	local h=(part.high-part.low)/2*part.scale
	local r,u,l=part.cf.RightVector,part.cf.UpVector,part.cf.LookVector
	local radius=roblox.Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,
		math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)
	part.worldLow,part.worldHigh=center-radius,center+radius
end
local function hit(a,b,part)
	local from=part.cf:PointToObjectSpace(a)/part.scale
	local to=part.cf:PointToObjectSpace(b)/part.scale
	local delta=to-from;local t0,t1=0,1
	for _,axis in {'X','Y','Z'} do
		if math.abs(delta[axis])<1e-8 then if from[axis]<part.low[axis] or from[axis]>part.high[axis] then return false end
		else
			local p=(part.low[axis]-from[axis])/delta[axis];local q=(part.high[axis]-from[axis])/delta[axis]
			if p>q then p,q=q,p end;t0=math.max(t0,p);t1=math.min(t1,q)
			if t0>t1 then return false end
		end
	end
	return t1>0 and t0<.9999
end
local viewCameras={
	GalleryInteriorQuietLancet1=roblox.Vector3.new(-52,59.5,54),GalleryInteriorQuietLancet2=roblox.Vector3.new(2,63.5,54),GalleryInteriorQuietLancet3=roblox.Vector3.new(56,67.5,54),
	WestHighWarmLancet=roblox.Vector3.new(-188,37.5,-112),
	WestMiddleWarmLancet=roblox.Vector3.new(-128,25.5,0),
	UpperMachineWarmLancet1=layout.CP04.point+roblox.Vector3.yAxis*5.5,UpperMachineWarmLancet2=layout.CP04.point+roblox.Vector3.yAxis*5.5,
	UpperKeepWarmLancet1=layout.FinishPoint+roblox.Vector3.yAxis*5.5,UpperKeepWarmLancet2=layout.FinishPoint+roblox.Vector3.yAxis*5.5,
}
local visible={}
for _,window in result.windowAssemblies do
	local camera=assert(viewCameras[window.name]);local cf=roblox.CFrame.new(window.base)*roblox.CFrame.Angles(0,window.yaw,0)
	local blockers,samples,blockerSeen={},{},{}
	local low,high=camera,camera
	for _,x in {-12,12} do for _,y in {0,58} do
		local p=cf:PointToWorldSpace(roblox.Vector3.new(x,y,1.42)*window.scale)
		low=roblox.Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
		high=roblox.Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
	end end
	local nearby={}
	for _,part in candidates do
		if part.worldLow.X<=high.X and part.worldHigh.X>=low.X and part.worldLow.Y<=high.Y and part.worldHigh.Y>=low.Y
			and part.worldLow.Z<=high.Z and part.worldHigh.Z>=low.Z then table.insert(nearby,part) end
	end
	for _,p in {
		roblox.Vector3.new(0,.2,1.42),roblox.Vector3.new(-12,12,1.42),roblox.Vector3.new(12,12,1.42),
		roblox.Vector3.new(-10,37,1.42),roblox.Vector3.new(10,37,1.42),roblox.Vector3.new(0,57.981651306152344,1.42),
	} do table.insert(samples,p) end
	for y=0,58 do
		local half=12
		if y>58*.64 then
			local theta=math.asin((y-58*.64)/(58*.36)*math.sin(math.pi/3))
			half=-12+24*math.cos(theta)
		end
		for i=0,math.ceil(half*2) do
			local x=if half<1e-8 then 0 else -half+2*half*i/math.ceil(half*2)
			table.insert(samples,roblox.Vector3.new(x,y,1.42))
		end
	end
	for index,p in samples do
		local target=cf:PointToWorldSpace(p*window.scale)
		for _,part in nearby do
			if string.sub(part.name,1,#window.name)==window.name then continue end
			if hit(camera,target,part) and not blockerSeen[part.name] then
				blockerSeen[part.name]=true;table.insert(blockers,{sample=index,part=part.name})
			end
		end
	end
	table.insert(visible,{name=window.name,camera=camera,lookAt=cf:PointToWorldSpace(roblox.Vector3.new(0,28.99,1.42)*window.scale),
		frameSamples=#samples,maximumGridSpacingAssetStuds=1,blockers=blockers,visible=#blockers==0,
		geometryScope='Current49 architecture occupied boxes, proposed finishing, accepted static contacts; before root crown/cliff integration'})
	if #blockers>0 then table.insert(failures,'Window bound-ray obstruction '..window.name) end
end
local report={pass=#failures==0,failures=failures,clearance=screen,routeCombinations=32,uniqueVolumes=#volumes,
	resourceDelta={units=result.units,meshParts=result.meshParts,triangles=result.triangles},
	replacements=result.replaced,windowAssemblies=result.windowAssemblies,visibleFaceChecks=visible,inputHashes=inputHashes,
	nativeVisualVerified=false,geometryOnly=true,gameplayReplayed=false}
fs.writeFile(own..'focused-window-check.json',serde.encode('json',encode(report),true))
fs.writeFile(own..'placements.json',serde.encode('json',encode({additions=result.additions,replacements=result.replacements,proposalRows=result.proposalRows}),true))
print(serde.encode('json',{pass=report.pass,failures=failures,delta=report.resourceDelta,screen=screen,visible=encode(visible)}))
