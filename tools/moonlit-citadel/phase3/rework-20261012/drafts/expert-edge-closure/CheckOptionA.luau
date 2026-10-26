local fs,luau,roblox,serde = require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde')
local base='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local draft='tools/moonlit-citadel/phase3/rework-20261012/drafts/expert-edge-closure/'
local parent={}
local config=luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'),{environment={Vector3=roblox.Vector3}})()
local function load(name)
	local file=if name=='ExpertRoutes' then draft..'ExpertRoutes_OPTION_A.luau' else base..name..'.luau'
	local text=fs.readFile(file)
	if name=='Layout' then
		text=string.gsub(text,'v%(%-114, 51, 30%), v%(3%.6, 1, 10%)','v(-114, 51, 31), v(3.6, 1, 8)')
	end
	return luau.load(text,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,script={Parent=parent},require=function(x)return x end,
		game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}}}})()
end
for _,name in {'ExpertRoutes','RouteHazardGoals','SupportingObstacles','RouteHazardLayout'} do parent[name]=load(name) end
local layout=load('Layout')
local report={scope='Static Option A only; production modules read but not changed',transfers={},footMargins={},routeChecks={}}
for _,tr in layout.Transfers do
	if string.find(tr.from or '', '/ArchExpert/',1,true) or string.find(tr.to or '', '/ArchExpert/',1,true) then
		table.insert(report.transfers,{from=tr.from,to=tr.to,fromPoint={tr.fromPoint.X,tr.fromPoint.Y,tr.fromPoint.Z},toPoint={tr.toPoint.X,tr.toPoint.Y,tr.toPoint.Z},
			flightStuds=tr.flightStuds,riseStuds=tr.riseStuds,idealReachMargin=tr.idealReachMargin})
	end
end
for mask=0,7 do
	local route=layout.GetRoute({bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0},{1,2})
	local minimum=math.huge
	for _,margin in parent.SupportingObstacles.SupportMargins(layout,route) do
		if not string.find(margin.path,'/ArchExpert/',1,true) then continue end
		minimum=math.min(minimum,margin.xMargin,margin.zMargin)
		assert(margin.xMargin>=-.001 and margin.zMargin>=-.001,'Expert foot margin escape '..margin.path)
	end
	table.insert(report.routeChecks,{mask=mask,nodes=#route,minimumExpertFootSpare=if minimum==math.huge then nil else minimum})
end
fs.writeFile(draft..'option-a-static.json',serde.encode('json',report,true))
print('Option A loads against current Layout; all eight choices retain supported Arch Expert foot goals')
for _,tr in report.transfers do
	if string.find(tr.from,'OffsetCorbel',1,true) or string.find(tr.from,'ReturnTurn',1,true) or string.find(tr.from,'ReturnBeam',1,true)
		or string.find(tr.from,'MergeTurn',1,true) or string.find(tr.from,'FinalRiseRail',1,true) then
		print(tr.from,tr.to,'flight',tr.flightStuds,'rise',tr.riseStuds,'idealspare',tr.idealReachMargin)
	end
end
