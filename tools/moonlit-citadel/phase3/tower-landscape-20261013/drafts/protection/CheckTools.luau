local fs,luau,roblox,serde=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde')
local base='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local own='tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/'
local parent={}
local config=luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'),{environment={Vector3=roblox.Vector3}})()
local gameMock={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}},GetService=function(_,name)
	if name=='RunService' then return {IsRunning=function()return false end} end
	if name=='CollectionService' then return {GetTags=function()return {} end} end
	error('Unexpected service '..name)
end}
local function load(file)
	luau.compile(fs.readFile(file))
	return luau.load(fs.readFile(file),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,script={Parent=parent},game=gameMock,require=function(x)return x end}})()
end
for _,name in {'ExpertRoutes','RouteHazardGoals','SupportingObstacles','RouteHazardLayout'} do parent[name]=load(base..name..'.luau') end
local layout=load(base..'Layout.luau')
local clearance=load(own..'ArchitectureClearance.luau')
local protected=load(own..'ProtectedCourse.luau')
local volumes=clearance.Prepare(layout,config)
local kinds={};for _,volume in volumes do kinds[volume.kind]=(kinds[volume.kind] or 0)+1 end
local floor=layout.Surfaces[1]
local p=floor.position+config.Origin+roblox.Vector3.new(0,3,0)
local bad={path='SyntheticOnly/InsideStandingSpace',frame={roblox.CFrame.new(p):GetComponents()},size={2,2,2},collide=false,query=false,touch=false,anchored=true,transparency=0}
local far={path='SyntheticOnly/FarOutside',frame={roblox.CFrame.new(config.Origin+roblox.Vector3.new(1000,1000,1000)):GetComponents()},size={2,2,2},collide=false,query=false,touch=false,anchored=true,transparency=0}
assert(#clearance.CheckParts({bad},volumes,config.Origin).blocking>0,'Standing obstruction was not detected')
assert(clearance.CheckParts({far},volumes,config.Origin).physicalAndStandingScreenPass,'Separated art was incorrectly blocked')
local baseline={schema=2,kind='Course',identity={},records={['Obstacles/Contact']={class='Part',props={size=1},attrs={}}},arrowIds={}}
for i=1,19 do table.insert(baseline.arrowIds,'Arrow'..i) end
assert(protected.Compare(baseline,baseline).pass,'Exact synthetic native self-comparison failed')
local changed=table.clone(baseline);changed.records={['Obstacles/Contact']={class='Part',props={size=2},attrs={}}}
assert(not protected.Compare(baseline,changed).pass,'Changed protected property was accepted')
local function folder(name,parent,slot)
	local item={Name=name,ClassName='Folder',Parent=parent,children={},slot=slot}
	function item:IsA(class) return class=='Folder' end
	function item:GetAttribute(key)return if key=='Slot' then self.slot else nil end
	function item:GetAttributes()return if self.slot then {Slot=self.slot} else {} end
	function item:GetChildren()return self.children end
	function item:GetDescendants()
		local result={};for _,child in self.children do table.insert(result,child);for _,nested in child:GetDescendants() do table.insert(result,nested) end end
		return result
	end
	function item:GetFullName()return self.Name end
	return item
end
local fakeKit=folder('MoonlitCitadel_BL02Library')
fakeKit.children={folder('SideRailContact',fakeKit,1),folder('SideRailContact',fakeKit,2)}
local duplicates=protected.CaptureAcceptedKit(fakeKit)
assert(duplicates.records['SideRailContact[1]'] and duplicates.records['SideRailContact[2]'],'Duplicate siblings were lost or unsuffixed')
assert(protected.Compare(duplicates,duplicates).pass,'Duplicate-preserving kit self-comparison failed')
fakeKit.children={fakeKit.children[2],fakeKit.children[1]}
assert(protected.Compare(duplicates,protected.CaptureAcceptedKit(fakeKit)).pass,'Reload sibling reordering caused a false mutation')
fakeKit.children[1].slot=3
assert(not protected.Compare(duplicates,protected.CaptureAcceptedKit(fakeKit)).pass,'Changed meaningful duplicate attribute was hidden')
fakeKit.children[1].slot=1
assert(not protected.Compare(duplicates,protected.CaptureAcceptedKit(fakeKit)).pass,'Ambiguous identical duplicate group passed without review')
local report={volumes=#volumes,volumeKinds=kinds,compiledModules=2,syntheticStandingDetected=true,syntheticFarArtClear=true,
	syntheticExactSelfComparison=true,syntheticProtectedMutationDetected=true,syntheticDuplicateSiblingsPreserved=true,
	syntheticSiblingReorderingPreserved=true,syntheticDuplicateMutationDetected=true,syntheticAmbiguousDuplicateBlocked=true,
	nativeBaselineCaptured=false,gameplayReplayed=false}
fs.writeFile(own..'tool-checks.json',serde.encode('json',report,true))
print(serde.encode('json',report))
