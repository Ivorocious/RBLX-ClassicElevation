--!nonstrict
local Audit=require(script.Parent.AuditNative50)
local Run={}
local Bindings={
	plan="74c77a93fd4a4c3e477f54333edc67d21b5d0bcc92b39084c49c21891cf59eb4",
	templates="039621c8a12f5623931c9b70379de15660d06d06cc95d837f059a3231ecb4569",
	sources="fe27f35671380974550f9320ceb7856cd3459b235f2b3f0de0fb6b2c55fa0ca1",
	protected="2a0cd5a394f1b042311a9b137a97b612cacf5eddcaaafc9e5c2f7dd2e929479d",
	erMetadata="e3c10a2ccb037eca569b2377634056eeb1a11524e1ebbcbb9efa37efed898dde",
}
local function hashBytes(bytes)
	local digest=game:GetService("EncodingService"):ComputeBufferHash(bytes,Enum.HashAlgorithm.Sha256)
	local pieces={};for index=0,buffer.len(digest)-1 do table.insert(pieces,string.format("%02x",buffer.readu8(digest,index))) end
	return table.concat(pieces)
end
local function hash(text)return hashBytes(buffer.fromstring(text)) end
local function decode(raw,key)
	assert(type(raw)=="string" and hash(raw)==Bindings[key],"Exact bound input required: "..key)
	return game:GetService("HttpService"):JSONDecode(raw)
end

function Run.Check(context)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Audit only in restored Edit state")
	assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177,"Verify intended Obby Tournament instance")
	assert(context and context.protector,"Pass the verified protected-capture module")
	local plan=decode(context.planRaw,"plan")
	local approved=decode(context.templatesRaw,"templates")
	local sourceSpecs=decode(context.sourcesRaw,"sources")
	local before=decode(context.protectedBeforeRaw,"protected")
	local erMetadata=decode(context.erMetadataRaw,"erMetadata")
	local nativeSources={};local wanted={}
	for _,spec in sourceSpecs.specs do wanted[spec.name]=true end
	for _,item in game:GetDescendants() do if item:IsA("LuaSourceContainer") then
		local path=item:GetFullName()
		if wanted[path] then assert(not nativeSources[path],"Ambiguous actual native source path: "..path);nativeSources[path]=item end
	end end
	local sourceChecks={}
	for _,spec in sourceSpecs.specs do
		table.insert(sourceChecks,{name=spec.name,actual=nativeSources[spec.name],expectedSHA256=spec.expectedSHA256,normalization=spec.normalization})
	end
	local editable=assert(workspace:FindFirstChild("Course_MoonlitCitadel"))
	local stored=assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_MoonlitCitadel"))
	local kits=game.ServerStorage.CourseAssetKits;local libraries={}
	for key,name in Audit.LibraryNames do libraries[key]=assert(kits:FindFirstChild(name),"Missing verified library "..name) end
	local P=context.protector
	local after={editable=P.Capture(editable),stored=P.Capture(stored),
		phase1=P.CaptureFrozenPhase1Model(assert(workspace:FindFirstChild("MoonlitCitadelPhase1_BL02"))),
		kit=P.CaptureAcceptedKit(libraries.BL02),arrows={}}
	for _,name in {"MC_P3_Rework_SolidArrow","MC_P3_Rework_ArrowMount"} do
		after.arrows[name]=P.CaptureArrowTemplate(assert(libraries.P3:FindFirstChild(name)))
	end
	local report=Audit.Run({editable,stored},libraries,plan,{packetSHA256=Audit.Expected.packetSHA256,
		planSHA256=Bindings.plan,worldAssemblySHA256=hash(assert(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse:FindFirstChild("WorldAssembly")).Source:gsub("\r\n","\n")),
		approvedTemplates=approved,approvedER01Metadata=erMetadata,requiredSources=sourceSpecs.requiredSources,sourceChecks=sourceChecks,
		computeSHA256=hash,protectedBefore=before,protectedAfter=after,nativeLiveCompared=true})
	local maps={pass=true,baseline="Fresh post-Race-Flow native recovery",models={}}
	for _,row in before.otherMaps do
		local model=game.ServerStorage.CourseLibrary:FindFirstChild(row.name)
		local item={name=row.name,pass=false,expectedSHA256=row.sha256,expectedBytes=row.bytes}
		if model then
			local bytes=game:GetService("SerializationService"):SerializeInstancesAsync({model})
			item.actualSHA256=hashBytes(bytes);item.actualBytes=buffer.len(bytes);item.descendants=#model:GetDescendants()
			item.pass=item.actualSHA256==row.sha256 and item.actualBytes==row.bytes and item.descendants==row.descendants
		else item.error="Missing current saved other map" end
		if not item.pass then maps.pass=false end;table.insert(maps.models,item)
		task.wait()
	end
	report.otherMaps=maps;report.pass=report.pass and maps.pass
	report.protectedAfter=after;report.inputHashes=table.clone(Bindings)
	report.studio={place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,edit=not game:GetService("RunService"):IsRunning()}
	return report
end
return Run
