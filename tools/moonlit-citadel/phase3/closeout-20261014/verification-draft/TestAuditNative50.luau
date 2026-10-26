local fs,roblox,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local own='tools/moonlit-citadel/phase3/closeout-20261014/verification-draft/'
local cache={};local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name} end})
local function load(name)
	if cache[name] then return cache[name] end
	local source=fs.readFile(own..name..'.luau');luau.compile(source)
	local result=luau.load(source,{environment={CFrame=roblox.CFrame,Vector3=roblox.Vector3,Color3=roblox.Color3,Enum=roblox.Enum,
		script={Parent=parent},require=function(value)return load(value.moduleName) end}})()
	cache[name]=result;return result
end
local Audit,Appearance=load('AuditNative50'),load('ExpectedAppearance50')
local planPath='docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json'
local planText=fs.readFile(planPath);local exported=serde.decode('json',planText)
local approved=serde.decode('json',fs.readFile(own..'approved-templates50.json'))
local saved='docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/'
local libraries={}
for _,file in {saved..'enclosure_before_source48_kits.rbxm',saved..'enclosure_er01_library_verified.rbxm'} do
	for _,lib in roblox.deserializeModel(fs.readFile(file)) do for key,name in Audit.LibraryNames do if lib.Name==name then libraries[key]=lib end end end
end
local fixturePacket=Audit.Expected.packetSHA256
local courses={}
for courseIndex=1,2 do
	local course=roblox.Instance.new('Model');course.Name='Course_MoonlitCitadel'
	course:SetAttribute('CourseId','moonlit_citadel');course:SetAttribute('Origin',roblox.Vector3.new(4000,300,2600))
	course:SetAttribute('SourceRevision',50);course:SetAttribute('BuildRevision',44);course:SetAttribute('CandidateId','MC_P3_CLOSEOUT_FC01');course:SetAttribute('SourcePacketHash',fixturePacket)
	local d=roblox.Instance.new('Folder');d.Name,d.Parent='Decoration',course
	local world=roblox.Instance.new('Folder');world.Name,world.Parent='Phase3World',d
	local districts={}
	for _,data in exported.units do
		local template=assert(libraries[data.library or 'BL02']:FindFirstChild(data.asset))
		local parent=districts[data.district]
		if not parent then parent=roblox.Instance.new('Folder');parent.Name,parent.Parent=data.district,world;districts[data.district]=parent end
		local unit=template:Clone();unit.Name=data.name
		local localCF=roblox.CFrame.new(table.unpack(data.localCF));local scale=roblox.Vector3.new(table.unpack(data.scale))
		local pose=roblox.CFrame.new(course:GetAttribute('Origin'))*localCF
		for _,p in unit:GetDescendants() do if p:IsA('BasePart') then
			local original=p.CFrame;p.Size*=scale;p.CFrame=pose*roblox.CFrame.new(original.Position*scale)*original.Rotation
			p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,false,false,false
			local values=Appearance.Expected(p,data)
			p.Color,p.Material,p.CastShadow=values.Color,values.Material,values.CastShadow
		end end
		unit.WorldPivot=pose;unit:SetAttribute('MCEditUnit',data.asset);unit:SetAttribute('District',data.district)
		unit:SetAttribute('CourseLocalFrame',localCF);unit:SetAttribute('AuthorScale',scale);unit:SetAttribute('MaterialRole',data.materialRole or 'WorldArt')
		unit.Parent=parent
	end
	world:SetAttribute('PlanUnits',233);world:SetAttribute('MeshParts',609);world:SetAttribute('PlacedTriangles',197402);world:SetAttribute('ArtRepairCandidate','ER01')
	table.insert(courses,course)
end
local baselinePath='docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before/closeout_protected_baseline49.json'
local before=serde.decode('json',fs.readFile(baselinePath));local after=serde.decode('json',fs.readFile(baselinePath))
for _,name in {'editable','stored'} do after[name].identity.source=50;after[name].identity.build=44;after[name].identity.packet=fixturePacket end
local source=roblox.Instance.new('ModuleScript');source.Name='FreshSourceFixture';source.Source='return {accepted=true}'
local options={packetSHA256=fixturePacket,planSHA256=serde.hash('sha256',planText),worldAssemblySHA256=Appearance.WorldAssemblySHA256,
	approvedTemplates=approved,approvedER01Metadata=serde.decode('json',fs.readFile('tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json')),
	requiredSources=1,sourceChecks={{name=source.Name,actual=source,expectedSource='return {accepted=true}'}},protectedBefore=before,protectedAfter=after,
	nativeLiveCompared=false}
local function run()return Audit.Run(courses,libraries,exported,options)end
local good=run()
if not good.pass then fs.writeFile(own..'fixture-failure50.json',serde.encode('json',good,true));error('Valid saved-template fixture rejected; inspect own fixture-failure50.json') end
local fixtures={validClone=true}
local part=courses[1].Decoration.Phase3World:FindFirstChildWhichIsA('MeshPart',true)
local original={cf=part.CFrame,size=part.Size,color=part.Color,material=part.Material,shadow=part.CastShadow,sourceMaterial=part:GetAttribute('SourceMaterial')}
part.CFrame+=roblox.Vector3.new(.02,0,0);fixtures.pose=not run().pass;part.CFrame=original.cf
part.Size+=roblox.Vector3.new(.02,0,0);fixtures.size=not run().pass;part.Size=original.size
part.Color=roblox.Color3.new(1,0,0);fixtures.color=not run().pass;part.Color=original.color
part.Material=roblox.Enum.Material.Neon;fixtures.material=not run().pass;part.Material=original.material
part:SetAttribute('SourceMaterial','Incorrect');fixtures.materialIdentity=not run().pass;part:SetAttribute('SourceMaterial',original.sourceMaterial)
part.CanQuery=true;fixtures.contactFlag=not run().pass;part.CanQuery=false
local arrow=after.editable.arrowIds[1];after.editable.arrowIds[1]='WrongArrow';fixtures.arrowId=not run().pass;after.editable.arrowIds[1]=arrow
local key=next(after.phase1.records);local class=after.phase1.records[key].class;after.phase1.records[key].class='WrongClass';fixtures.phase1=not run().pass;after.phase1.records[key].class=class
source.Source='return {accepted=false}';fixtures.freshProtectedSource=not run().pass;source.Source='return {accepted=true}'
options.planSHA256=string.rep('b',64);fixtures.planBinding=not run().pass;options.planSHA256=serde.hash('sha256',planText)
local digest=serde.hash('sha256',source.Source)
local hashSpec={{name='FreshHashFixture',actual=source,expectedSHA256=digest,normalization='lf'}}
fixtures.freshHashSource=Audit.CheckSources(hashSpec,1,function(text)return serde.hash('sha256',text) end).pass
source.Source='return {accepted=false}'
fixtures.freshHashChange=not Audit.CheckSources(hashSpec,1,function(text)return serde.hash('sha256',text) end).pass
source.Source='return {accepted=true}'
for name,pass in fixtures do assert(pass,'Negative fixture failed '..name) end
local report={pass=true,fixtures=fixtures,geometry=good.models,appearance=good.appearance,protectedRecordCounts={},offlineOnly=true,
	fixtureConstruction='Synthetic Source50 clone placements from approved saved native templates; never native installation proof',
	inputHashes={[planPath]=serde.hash('sha256',planText),[baselinePath]=serde.hash('sha256',fs.readFile(baselinePath))}}
for name,item in good.protected.checks do report.protectedRecordCounts[name]=item.records end
for _,file in {'AuditNative50.luau','GeometryAudit49.luau','ExpectedAppearance50.luau','approved-templates50.json','TestAuditNative50.luau'} do
	report.inputHashes[own..file]=serde.hash('sha256',fs.readFile(own..file))
end
fs.writeFile(own..'audit-fixtures50.json',serde.encode('json',report,true))
print(serde.encode('json',{pass=true,fixtures=fixtures,models=good.models,appearance=good.appearance}))
