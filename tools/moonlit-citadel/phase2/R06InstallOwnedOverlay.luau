local function install(port, mapName, mapHash, nativeName, nativeHash, overlayName, overlayHash, label)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId == 0 and game.GameId == 0)
	local H, E, S = game:GetService("HttpService"), game:GetService("EncodingService"), game:GetService("SerializationService")
	local beforeHttp, beforeLight = H.HttpEnabled, game.Lighting.ClockTime
	local report = {candidate = "MC_P2_C01_R06", sourceMapHash = mapHash, nativeHash = nativeHash, overlayHash = overlayHash}
	local function hash(raw)
		local b, h = E:ComputeBufferHash(buffer.fromstring(raw), Enum.HashAlgorithm.Sha256), {}
		for i=0,buffer.len(b)-1 do h[#h+1]=string.format("%02x",buffer.readu8(b,i)) end
		return table.concat(h)
	end
	local function at(path)
		local item = game
		for name in path:gmatch("[^/]+") do item = item and item:FindFirstChild(name) end
		return item
	end
	local function get(name, sha)
		local r = H:RequestAsync({Url="http://127.0.0.1:"..port.."/"..name,Method="GET"})
		assert(r.Success and hash(r.Body)==sha,"Input binding failed "..name)
		return r.Body
	end
	local ok, reason = xpcall(function()
		H.HttpEnabled = true
		local map = H:JSONDecode(get(mapName,mapHash))
		local native = get(nativeName,nativeHash)
		local overlay = H:JSONDecode(get(overlayName,overlayHash))
		assert(#map.sources>=238 and overlay.candidate==report.candidate)
		local library = game.ServerStorage.CourseLibrary
		assert(#library:GetChildren()==7 and library.Course_MoonlitCitadel:GetAttribute("CandidateId")==report.candidate)
		assert(not game.ServerStorage:FindFirstChild("MoonlitR06OwnedOverlay_"..label),"Preserve prior overlay archive")
		for _,row in map.sources do
			local item=at(row.instancePath)
			if not item then
				assert(row.instancePath=="ServerStorage/CourseBuilders/ManualObstaclePhases" or row.instancePath=="ServerStorage/CourseBuilders/ManualObstacleInventive",row.instancePath)
				local parent,name=row.instancePath:match("^(.*)/([^/]+)$")
				item=Instance.new("ModuleScript");item.Name=name;item.Parent=assert(at(parent))
			end
			assert(item:IsA("LuaSourceContainer"),row.instancePath)
		end
		for _,row in overlay.sources do
			assert(hash(row.source)==row.sha256)
			local item=at(row.instancePath)
			assert(not item or item.ClassName==row.class,"Overlay class mismatch")
		end
		local roots = S:DeserializeInstancesAsync(buffer.fromstring(native))
		assert(#roots==1 and roots[1].Name=="Course_MoonlitCitadel" and roots[1]:GetAttribute("CandidateId")==report.candidate)
		local course=roots[1]
		local archive=Instance.new("Folder");archive.Name="MoonlitR06OwnedOverlay_"..label;archive.Parent=game.ServerStorage
		local previous = library.Course_MoonlitCitadel;previous.Parent=archive
		local view = workspace:FindFirstChild("RaceCourse")
		if view then view.Parent=archive end
		for i,row in map.sources do
			local item=at(row.instancePath)
			if item.Source:gsub("^\239\187\191",""):gsub("\r\n","\n")~=row.source then item.Source=row.source end
			if i%100==0 then task.wait() end
		end
		report.frozenSourceMatches=0
		for _,row in map.sources do
			local actual=at(row.instancePath).Source:gsub("^\239\187\191",""):gsub("\r\n","\n")
			assert(hash(actual)==row.normalizedSha256,"Core agreement failed "..row.instancePath)
			report.frozenSourceMatches+=1
		end
		course.Parent=library
		local clone=course:Clone();clone.Name="RaceCourse";clone.Parent=workspace
		report.overlaySources={}
		for _,row in overlay.sources do
			local item=at(row.instancePath)
			if not item then
				local parent,name=row.instancePath:match("^(.*)/([^/]+)$")
				item=Instance.new(row.class);item.Name=name;item.Source=row.source
				if item:IsA("BaseScript")then item.Disabled=true end
				item.Parent=assert(at(parent))
			else item.Source=row.source end
			assert(hash(item.Source:gsub("\r\n","\n"))==row.sha256)
			report.overlaySources[#report.overlaySources+1]={path=row.instancePath,sha256=row.sha256}
		end
		game.ServerScriptService.R06SuiteServer.Disabled=true
		game.StarterPlayer.StarterPlayerScripts.R06SuiteClient.Disabled=true
		game.ServerScriptService.MoonlitPhase2Probe.Disabled=false
		game.ServerScriptService.R06RuntimeBootstrap.Disabled=false
		game.StarterPlayer.StarterPlayerScripts.R06RuntimeBootstrap.Disabled=false
		report.libraryEntries=#library:GetChildren();report.nativeDescendants=#course:GetDescendants()
		local raw=H:JSONEncode(report)
		local r=H:RequestAsync({Url="http://127.0.0.1:"..port.."/MC_P2_R06_runtime_overlay_"..label..".json",Method="POST",Headers={["Content-Type"]="application/json"},Body=raw})
		assert(r.Success,r.StatusCode)
		report.receipt=H:JSONDecode(r.Body)
	end,debug.traceback)
	H.HttpEnabled=beforeHttp
	report.ok,report.failure,report.httpRestored,report.lightPreserved=ok,if ok then nil else tostring(reason),H.HttpEnabled==beforeHttp,game.Lighting.ClockTime==beforeLight
	return H:JSONEncode(report)
end
return install
