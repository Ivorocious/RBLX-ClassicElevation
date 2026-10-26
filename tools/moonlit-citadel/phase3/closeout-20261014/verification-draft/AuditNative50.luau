--!nonstrict
local Geometry=require(script.Parent.GeometryAudit49)
local Appearance=require(script.Parent.ExpectedAppearance50)
local Audit={LibraryNames=Geometry.LibraryNames,Expected={source=50,build=44,candidate="MC_P3_CLOSEOUT_FC01",units=233,meshes=609,triangles=197402,
	planSHA256="74c77a93fd4a4c3e477f54333edc67d21b5d0bcc92b39084c49c21891cf59eb4",
	packetSHA256="2aca31596c1264413a10c554ae81ee7c42630a8732567c98fb7c276ecd4fe2c1"}}
local function vector(value)return if typeof(value)=="Vector3" then value else Vector3.new(table.unpack(value)) end
local function frame(value)return if typeof(value)=="CFrame" then value else CFrame.new(table.unpack(value)) end
local function relative(root,item)
	local names={};while item~=root do assert(item,"Part escaped planned unit");table.insert(names,1,item.Name);item=item.Parent end
	return table.concat(names,"/")
end
local function content(part,key,fallback)
	local ok,value=pcall(function()return part[key] end)
	if not ok and fallback then ok,value=pcall(function()return part[fallback] end) end
	assert(ok,"Content identity unreadable "..key)
	local raw=tostring(value)
	if raw=="nil" or raw=="Content(None)" then return "" end
	local id=raw:match("rbxassetid://(%d+)") or raw:match("[?&]id=(%d+)")
	return if id then "rbxassetid://"..id else raw
end
local function scalar(value)return if typeof(value)=="EnumItem" then tostring(value) else value end
local function cfDifference(a,b)
	local x,y={a:GetComponents()},{b:GetComponents()};local p,r=0,0
	for i=1,12 do if i<=3 then p=math.max(p,math.abs(x[i]-y[i])) else r=math.max(r,math.abs(x[i]-y[i])) end end
	return p,r
end
local function vectorDifference(a,b)return math.max(math.abs(a.X-b.X),math.abs(a.Y-b.Y),math.abs(a.Z-b.Z)) end
local function colorDifference(a,b)return math.max(math.abs(a.R-b.R),math.abs(a.G-b.G),math.abs(a.B-b.B)) end
local function partMap(root)
	local result={}
	for _,item in root:GetDescendants() do if item:IsA("BasePart") then
		local key=relative(root,item);assert(not result[key],"Ambiguous template/native part "..key);result[key]=item
	end end
	return result
end
local function changes(a,b,path,result)
	if type(a)~=type(b) then result.count+=1;if #result.paths<200 then table.insert(result.paths,path) end;return end
	if type(a)~="table" then
		if a~=b then result.count+=1;if #result.paths<200 then table.insert(result.paths,path) end end;return
	end
	local keys={};for k in a do keys[k]=true end;for k in b do keys[k]=true end
	for k in keys do changes(a[k],b[k],path.."/"..tostring(k),result) end
end
local function lightMap(snapshot)
	local result={};for _,row in snapshot.worldLights or {} do
		local key=row.path.."|"..row.class;assert(not result[key],"Duplicate protected world-light path");result[key]=row
	end;return result
end

function Audit.CompareProtected(before,after,expectedIdentity)
	local report={pass=false,checks={},readOnly=true,scope="Exact captured nonworld records,19 arrows,Phase1,accepted BL02 kit and arrow templates"}
	for _,name in {"editable","stored","phase1","kit"} do
		local a,b=before and before[name],after and after[name]
		local item={pass=false,changes={count=0,paths={}}};report.checks[name]=item
		if not a or not b or a.schema~=2 or b.schema~=2 then item.error="Both schema2 native captures required";continue end
		changes(a.records,b.records,name.."/records",item.changes)
		changes(a.arrowIds,b.arrowIds,name.."/arrowIds",item.changes)
		changes(lightMap(a),lightMap(b),name.."/worldLights",item.changes)
		item.records=0;for _ in b.records do item.records+=1 end
		item.arrows=#b.arrowIds;item.beforeIdentity=a.identity;item.afterIdentity=b.identity
		if #(a.ambiguousDuplicateGroups or {})>0 or #(b.ambiguousDuplicateGroups or {})>0 then item.error="Ambiguous protected duplicate groups" end
		if name=="editable" or name=="stored" then
			if item.arrows~=19 then item.error="Exactly19 accepted arrows required" end
			for key,value in expectedIdentity do if b.identity[key]~=value then item.error="Protected capture identity differs at "..key end end
		end
		item.pass=item.changes.count==0 and item.error==nil;table.sort(item.changes.paths)
	end
	for _,name in {"MC_P3_Rework_SolidArrow","MC_P3_Rework_ArrowMount"} do
		local a=before and before.arrows and before.arrows[name]
		local b=after and after.arrows and after.arrows[name]
		local item={pass=false,changes={count=0,paths={}}};report.checks[name]=item
		if not a or not b or a.schema~=2 or b.schema~=2 then item.error="Both exact arrow-template captures required";continue end
		changes(a.records,b.records,name.."/records",item.changes)
		if #(a.ambiguousDuplicateGroups or {})>0 or #(b.ambiguousDuplicateGroups or {})>0 then item.error="Ambiguous arrow-template duplicate groups" end
		item.pass=item.changes.count==0 and item.error==nil;table.sort(item.changes.paths)
	end
	report.pass=true;for _,item in report.checks do if not item.pass then report.pass=false end end
	return report
end

function Audit.CheckSources(checks,required,computeSHA256)
	local report={pass=false,checked=0,required=required,differences={},scope="Fresh post-Race-Flow expected sources/final packet"}
	local seen={}
	for index,row in checks or {} do
		local ok,err=pcall(function()
			assert(row.actual and row.actual:IsA("LuaSourceContainer"),"Actual native source required")
			local name=row.name or row.actual:GetFullName();assert(not seen[name],"Duplicate source expectation");seen[name]=true
			if row.expectedSHA256 then
				assert(computeSHA256,"Pass native SHA256 helper for fresh hash-only records")
				local text=row.actual.Source
				if row.normalization=="lf" then text=text:gsub("\r\n","\n")
				elseif row.normalization and row.normalization~="raw" then error("Unknown source normalization") end
				assert(computeSHA256(text)==row.expectedSHA256,"Fresh current source hash differs")
			else
				assert(Geometry.CheckSources({row},1).pass,"Fresh current source text differs")
			end
		end)
		report.checked+=1
		if not ok then table.insert(report.differences,{name=row.name or tostring(index),error=tostring(err)}) end
	end
	report.pass=type(required)=="number" and required>0 and report.checked==required and #report.differences==0
	return report
end

function Audit.Run(courses,libraries,exported,options)
	options=options or {}
	assert(type(options.packetSHA256)=="string" and #options.packetSHA256==64,"Pass exact final Source50 packet SHA256")
	local expected=Audit.Expected
	assert(options.packetSHA256==expected.packetSHA256,"Audit is bound to the prepared exact Source50 packet")
	local identity={source=expected.source,build=expected.build,packet=options.packetSHA256}
	local inherited=table.clone(options)
	inherited.expectedIdentity=identity;inherited.expectedUnits=expected.units;inherited.expectedMeshes=expected.meshes;inherited.expectedCourses=2
	inherited.requireSourceGuard=false;inherited.approvedTemplateMetadata=options.approvedER01Metadata
	local report=Geometry.Run(courses,libraries,exported,inherited)
	local function fail(kind,path,detail)table.insert(report.failures,{kind=kind,path=path,detail=detail}) end
	report.appearance={checkedParts=0,maxColorError=0,fieldChecks={"Color","Material","CastShadow","Transparency","MaterialVariant","SourceMaterial","SourceAsset","SourceTriangles","TextureID","DoubleSided","RenderFidelity"}}
	report.candidate=expected.candidate;report.planSHA256=options.planSHA256;report.expectedTriangles=expected.triangles
	report.expectedAppearanceSourceSHA256=Appearance.WorldAssemblySHA256
	if options.planSHA256~=expected.planSHA256 then fail("PlanBinding","combined-plan50",options.planSHA256) end
	if options.worldAssemblySHA256~=Appearance.WorldAssemblySHA256 then fail("AppearanceSourceBinding","WorldAssembly",options.worldAssemblySHA256) end
	local approved=options.approvedTemplates
	local approvedMap={}
	if not approved or approved.sourcePlanSHA256~=expected.planSHA256 then fail("TemplateMetadataBinding","all libraries","Approved templates must match final plan")
	else for _,row in approved.templates do approvedMap[row.library.."/"..row.asset]=row end end
	local checkedTemplates={}
	local plan=exported.units or exported.plan or exported
	local plannedParts=0
	for _,data in plan do
		local key=(data.library or "BL02").."/"..data.asset
		local frozen=approvedMap[key]
		if frozen then plannedParts+=#frozen.parts end
		if checkedTemplates[key] then continue end;checkedTemplates[key]=true
		if not frozen then fail("MissingFrozenTemplate",key,"Every planned asset needs approved saved identity");continue end
		local library=libraries[data.library or "BL02"]
		local template=library and library:FindFirstChild(data.asset)
		if not template then continue end
		if library.Name~=frozen.libraryName then fail("LibraryName",key,library.Name) end
		local live=partMap(template);local expectedPaths={}
		for _,row in frozen.parts do
			expectedPaths[row.path]=true;local p=live[row.path]
			if not p then fail("FrozenTemplatePart",key.."/"..row.path,"Missing");continue end
			local d,r=cfDifference(p.CFrame,frame(row.cf));local s=vectorDifference(p.Size,vector(row.size))
			if p.ClassName~=row.class or content(p,"MeshId","MeshContent")~=row.meshId or d>.001 or s>.001 or r>.00002 then
				fail("FrozenTemplateGeometry",key.."/"..row.path,{position=d,size=s,rotation=r})
			end
			local fields={Material=tostring(p.Material),MaterialVariant=p.MaterialVariant,CastShadow=p.CastShadow,Transparency=p.Transparency,
				SourceMaterial=p:GetAttribute("SourceMaterial"),SourceAsset=p:GetAttribute("SourceAsset"),SourceTriangles=p:GetAttribute("SourceTriangles"),
				TextureID=content(p,"TextureID","TextureContent"),DoubleSided=p.DoubleSided,RenderFidelity=tostring(p.RenderFidelity)}
			for _,field in {"Material","MaterialVariant","CastShadow","Transparency","SourceMaterial","SourceAsset","SourceTriangles","TextureID","DoubleSided","RenderFidelity"} do
				local value=fields[field]
				local expectedValue=if field=="Material" then row.material elseif field=="MaterialVariant" then row.materialVariant elseif field=="CastShadow" then row.castShadow
					elseif field=="Transparency" then row.transparency elseif field=="SourceMaterial" then row.sourceMaterial elseif field=="SourceAsset" then row.sourceAsset
					elseif field=="SourceTriangles" then row.sourceTriangles else row[field]
				if value~=expectedValue then fail("FrozenTemplateAppearance",key.."/"..row.path.."/"..field,{expected=expectedValue,actual=value}) end
			end
			if colorDifference(p.Color,Color3.new(table.unpack(row.color)))>1e-6 then fail("FrozenTemplateColor",key.."/"..row.path,"Saved template color differs") end
		end
		for path in live do if not expectedPaths[path] then fail("UnexpectedTemplatePart",key.."/"..path,"Not in approved metadata") end end
	end
	if plannedParts~=expected.meshes then fail("ApprovedPlanMeshLedger","plan",{actual=plannedParts,expected=expected.meshes}) end
	for _,course in courses do
		if course:GetAttribute("CandidateId")~=expected.candidate then fail("CourseCandidate",course.Name,course:GetAttribute("CandidateId")) end
		local world=course:FindFirstChild("Decoration") and course.Decoration:FindFirstChild("Phase3World")
		if not world then continue end
		if world:GetAttribute("PlacedTriangles")~=expected.triangles then fail("TriangleLedger",course.Name,world:GetAttribute("PlacedTriangles")) end
		for _,item in world:GetDescendants() do
			if item:IsA("LuaSourceContainer") or item:IsA("Light") then fail("UnexpectedSceneryBehavior",course.Name.."/"..relative(world,item),item.ClassName) end
		end
		local origin=course:GetAttribute("Origin")
		for _,data in plan do
			local district=world:FindFirstChild(data.district);local unit=district and district:FindFirstChild(data.name)
			local library=libraries[data.library or "BL02"];local template=library and library:FindFirstChild(data.asset)
			if not unit or not template then continue end
			local localCF=frame(data.localCF);local pose=CFrame.new(origin)*localCF
			local pivotReadable,pivot=pcall(function()return unit:GetPivot() end)
			if not pivotReadable then pivot=unit.WorldPivot end
			local p,r=cfDifference(pivot,pose)
			if p>.001 or r>.00002 then fail("UnitPivot",course.Name.."/"..data.name,{position=p,rotation=r}) end
			if unit:GetAttribute("MaterialRole")~=(data.materialRole or "WorldArt") then fail("MaterialRole",course.Name.."/"..data.name,unit:GetAttribute("MaterialRole")) end
			local originals,clones=partMap(template),partMap(unit)
			for path,original in originals do
				local actual=clones[path];if not actual then continue end
				local wanted=Appearance.Expected(original,data)
				local delta=colorDifference(actual.Color,wanted.Color)
				report.appearance.checkedParts+=1;report.appearance.maxColorError=math.max(report.appearance.maxColorError,delta)
				if delta>1e-6 then fail("CloneColor",course.Name.."/"..data.name.."/"..path,{error=delta}) end
				for _,field in {"Material","CastShadow"} do
					if actual[field]~=wanted[field] then fail("CloneAppearance",course.Name.."/"..data.name.."/"..path.."/"..field,{expected=scalar(wanted[field]),actual=scalar(actual[field])}) end
				end
				for _,field in {"Transparency","MaterialVariant","DoubleSided","RenderFidelity"} do
					if actual[field]~=original[field] then fail("CloneInheritedProperty",course.Name.."/"..data.name.."/"..path.."/"..field,{expected=scalar(original[field]),actual=scalar(actual[field])}) end
				end
				if content(actual,"TextureID","TextureContent")~=content(original,"TextureID","TextureContent") then fail("CloneTexture",course.Name.."/"..data.name.."/"..path,"Texture identity differs") end
				for _,attribute in {"SourceMaterial","SourceAsset","SourceTriangles"} do
					if actual:GetAttribute(attribute)~=original:GetAttribute(attribute) then fail("CloneMaterialIdentity",course.Name.."/"..data.name.."/"..path.."/"..attribute,"Source attribute differs") end
				end
				local gotA,a=pcall(function()return actual.CollisionFidelity end)
				local gotB,b=pcall(function()return original.CollisionFidelity end)
				if gotA~=gotB or gotA and a~=b then fail("CloneCollisionFidelity",course.Name.."/"..data.name.."/"..path,"Readable template property differs") end
			end
		end
	end
	if report.appearance.checkedParts~=expected.meshes*2 then fail("AppearanceCoverage","parts",report.appearance.checkedParts) end
	if options.requiredSources and options.requiredSources>0 then report.sourceGuard=Audit.CheckSources(options.sourceChecks,options.requiredSources,options.computeSHA256)
	else report.sourceGuard={pass=false,error="Explicit fresh post-Race-Flow source count and actual/expected native records required"} end
	report.sourceGuardScope="Fresh authorized current source baseline/final packet; no Source48 common-file comparison"
	report.protected=Audit.CompareProtected(options.protectedBefore,options.protectedAfter,identity)
	report.geometryPass=#report.failures==0
	report.pass=report.geometryPass and report.sourceGuard.pass and report.protected.pass
	report.nativeLiveCompared=options.nativeLiveCompared==true
	report.readOnly=true;report.finalVisualJudgment=false;report.gameplayReplayed=false
	return report
end
return Audit
