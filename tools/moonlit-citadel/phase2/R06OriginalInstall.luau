local function install(port)
	assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177 and not game.RunService:IsRunning())
	local H,E,S=game.HttpService,game.EncodingService,game.SerializationService
	local function hash(bytes)
		local b,h=E:ComputeBufferHash(bytes,Enum.HashAlgorithm.Sha256),{}
		for i=0,buffer.len(b)-1 do h[#h+1]=string.format("%02x",buffer.readu8(b,i)) end
		return table.concat(h)
	end
	local function at(path)
		local item=game;for name in path:gmatch("[^/]+")do item=item and item:FindFirstChild(name)end;return item
	end
	local beforeHttp,beforeClock=H.HttpEnabled,game.Lighting.ClockTime
	local camera=workspace.CurrentCamera
	local beforeCamera,beforeFocus,beforeType=camera.CFrame,camera.Focus,camera.CameraType
	local report={candidate="MC_P2_C01_R06",place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,files={},sources={}}
	local base="http://127.0.0.1:"..port.."/"
	local function get(name,sha)
		local r=H:RequestAsync({Url=base..name,Method="GET"})
		assert(r.Success and hash(buffer.fromstring(r.Body))==sha,"Input binding failed "..name)
		return r.Body
	end
	local function save(name,items)
		local b=S:SerializeInstancesAsync(items)
		local r=H:RequestAsync({Url=base.."MC_P2_R06_original07_"..name..".rbxm",Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(b)})
		assert(r.Success,r.StatusCode)
		local receipt=H:JSONDecode(r.Body)
		assert(receipt.sha256==hash(b));report.files[#report.files+1]=receipt
		return receipt.sha256
	end
	local library=game.ServerStorage.CourseLibrary
	local previous=library:FindFirstChild("Course_MoonlitCitadel") or workspace:FindFirstChild("Course_MoonlitCitadel")
	assert(previous and previous:GetAttribute("CandidateId")=="MC_P2_C01_R05","Preserve current owner course")
	assert(not game.ServerStorage:FindFirstChild("MoonlitR06OriginalRecovery"))
	local previousParent=previous.Parent
	local six={}
	for _,item in library:GetChildren()do if item~=previous then six[#six+1]=item end end
	assert(#six==6)
	table.sort(six,function(a,b)return a.Name<b.Name end)
	local p1={workspace.MoonlitCitadelPhase1_BL02,game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library}
	local archive,newCourse,editable
	local ok,reason=xpcall(function()
		H.HttpEnabled=true
		local map=H:JSONDecode(get("MC_P2_R06_frozen_source_map06.json","f55ed9114c69f0d8f6302ab3d2b42312a38f1a0e957d1d837b021f64bffa49ec"))
		local critical={
			["ServerStorage/CourseBuilders/MoonlitCitadelCourse/Layout"]=true,
			["ServerStorage/CourseBuilders/MoonlitCitadelCourse/RouteBuilder"]=true,
			["ServerStorage/CourseBuilders/MoonlitCitadelCourse/Runtime"]=true,
			["ServerStorage/CourseBuilders/MoonlitCitadelCourse/VisualAssembly"]=true,
			["ServerStorage/CourseBuilders/MoonlitCitadelCourse/Wayfinding"]=true,
			["ServerStorage/CourseBuilders/MoonlitCitadelCourse/DecorativeClearance"]=true,
			["ReplicatedStorage/Config/MoonlitCitadelCourseConfig"]=true,
			["ReplicatedStorage/Config/MoonlitCitadelAssemblyConfig"]=true,
			["ServerScriptService/Services/MoonlitCitadelService"]=true,
			["ServerScriptService/Services/RespawnService"]=true,
			["ServerScriptService/Main"]=true,
			["StarterPlayer/StarterPlayerScripts/Onboarding"]=true,
			["StarterPlayer/StarterPlayerScripts/Tournament"]=true,
			["StarterPlayer/StarterPlayerScripts/StudioFlight"]=true,
		}
		for _,row in map.sources do
			if not critical[row.instancePath]then continue end
			local item=assert(at(row.instancePath),row.instancePath)
			local actual=item.Source:gsub("^\239\187\191",""):gsub("\r\n","\n")
			assert(hash(buffer.fromstring(actual))==row.normalizedSha256,"Production source drift "..row.instancePath)
			report.sources[#report.sources+1]={path=row.instancePath,sha256=row.normalizedSha256}
			critical[row.instancePath]=nil
		end
		assert(next(critical)==nil,"Missing critical source binding")
		report.previousPath=previous:GetFullName()
		report.sixBefore=save("before_six",six)
		report.previousBefore=save("before_R05",{previous})
		report.p1Before=save("before_P1",p1)
		save("before_library",{library})
		local native=get("MC_P2_C01_R06_native_draft07.rbxm","d625975c2eb6c4f442ff80ebc215955f3fa32599046005592df94ced1e8ac8b3")
		local roots=S:DeserializeInstancesAsync(buffer.fromstring(native))
		assert(#roots==1 and roots[1].Name=="Course_MoonlitCitadel" and roots[1]:GetAttribute("CandidateId")==report.candidate and #roots[1]:GetDescendants()==2812)
		newCourse=roots[1]
		archive=Instance.new("Folder");archive.Name="MoonlitR06OriginalRecovery";archive.Parent=game.ServerStorage
		local ownerCopy=Instance.new("Folder");ownerCopy.Name="PreservedOwnerR05";ownerCopy.Parent=archive
		previous.Parent=ownerCopy
		newCourse.Parent=library
		assert(#library:GetChildren()==7)
		editable=newCourse:Clone();editable:SetAttribute("ManualEditing",true);editable.Parent=workspace
		report.sixAfter=save("after_six",six)
		report.previousAfter=save("archived_R05",{previous})
		report.p1After=save("after_P1",p1)
		assert(report.sixBefore==report.sixAfter and report.previousBefore==report.previousAfter and report.p1Before==report.p1After,"Preserved geometry changed")
		save("installed_course",{newCourse});save("editable_course",{editable});save("after_library",{library})
		report.coursePath=newCourse:GetFullName();report.editablePath=editable:GetFullName();report.archivePath=previous:GetFullName()
		report.libraryEntries=#library:GetChildren();report.phase1Preview=workspace.MoonlitCitadelPhase1_BL02:GetAttribute("PreviewEnabled")
	end,debug.traceback)
	if not ok and archive then
		if newCourse and newCourse.Parent then newCourse.Parent=archive end
		if editable and editable.Parent then editable.Parent=archive end
		previous.Parent=previousParent
		report.rollback=true
	end
	H.HttpEnabled=beforeHttp
	report.ok,report.failure=ok,if ok then nil else tostring(reason)
	report.httpRestored=H.HttpEnabled==beforeHttp
	report.cameraPreserved=camera.CFrame==beforeCamera and camera.Focus==beforeFocus and camera.CameraType==beforeType
	report.daylightPreserved=game.Lighting.ClockTime==beforeClock
	report.originalSaved=false;report.published=false
	return H:JSONEncode(report)
end
return install
